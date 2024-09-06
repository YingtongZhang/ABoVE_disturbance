/******************************
  Author: Damien Sulla-Menashe  
  Date modified: 3/07/12       
				
  Code does the following:
     ID the scenes that need clipping	
     ID the scenes need pansharpening 
     ID the scenes need mosaicking    
     perform appropriate operations in IDL
     output image as bsq in a new preprocess directory
     output image extent as shapefile in utm
*********************************/

#include <mpi.h>

#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <malloc.h>
#include <string.h>
#include <time.h>
#include <sys/param.h>
#include <sys/types.h>
#include <ctype.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <errno.h>
#include <unistd.h>
#include <gdal.h>
#include <cpl_conv.h>
#include "ogr_api.h"
#include <dirent.h>
#include <assert.h> // assert()
#include <libgen.h>

#define  NUM_BANDS 8
#define CHUNK_SIZE 10
#define DIM_X 6000
#define DIM_Y 6000

#define MAXPROCS 1200
// begin declaring functions
// count files with a specific extension
int count_files(char* in_path, char* tok_str);
void list_files(char* in_path,char* tok_str, char** in_list);

void parse_header(char **in_list,int numFiles, int *header_dat);

void read_vrt(char* in, int* out);

// handles errors
void error_message(int code, char* err);

void write_to_file(FILE* f_out, int* data, int row_num, int t, int tot_t);

int print_prj_info(OGRSpatialReferenceH spat_ref);

float wallclock_timer(int);                                                
float timeval_subtract (struct timeval, struct timeval);
// ## function i found online to create substrings easily
char *substring(char *string, int position, int length);

// end function declare

int main(int argc, char *argv[])
{

	char *in_dir,*out_dir;
	char **in_list;
	FILE *f_input;
	int count,i,j;
	int num_out;
	int *dat_int;
	int *dat_out, *datTemp;
    int rec, ncid, varid;
    char FILE_NAME[50];

    // ## to get some extra attributes about the files for each NETCDF file
    int *header_dat;

// ==============================================
    int i1, i2, root;
      int iy, n;  // file number local to each process
     int numFiles, YPARTS;
    int numRows,file_num;
    int isProcSending[MAXPROCS];
    char buffer3[60];
     int LOC_YRANGE;
    // Initialize the MPI environment
    MPI_Init(NULL, NULL);

    // Get the number of processes
    int world_size;
    MPI_Comm_size(MPI_COMM_WORLD, &world_size);

    // Get the rank of the process
    int world_rank;
    MPI_Comm_rank(MPI_COMM_WORLD, &world_rank);

    // Get the name of the processor
    char processor_name[MPI_MAX_PROCESSOR_NAME];
    int name_len;
    MPI_Get_processor_name(processor_name, &name_len);

   // if world_size > MAXPROCS abort  
// ==============================================
    int NUM_MPI_PROCS;
    NUM_MPI_PROCS = world_size;

	in_dir = (char*)malloc(MAXPATHLEN*sizeof(char));
	out_dir = (char*)malloc(MAXPATHLEN*sizeof(char));

	num_out = DIM_Y/CHUNK_SIZE;

//	printf("here! %d\n", __LINE__);
	// ## input list is a text file listing all the VRT files 
	// ## could change this later to skip that step
	assert(argc > 1);
	sprintf(in_dir,"%s",argv[1]);
	sprintf(out_dir,"%s",argv[2]);
//	printf("here! %d\n", __LINE__);

	file_num = count_files(in_dir,"vrt");

	in_list = (char**)malloc(file_num*sizeof(char*));
	for(i=0;i<file_num;i++)
	{
		in_list[i] = (char*)malloc(MAXPATHLEN*sizeof(char));
	}
	list_files(in_dir,"vrt",in_list);


    // ## parse info from the file names
    header_dat = (int *) CPLMalloc(sizeof(int)*file_num*3);
    parse_header(in_list,file_num,header_dat);

    if(world_rank == 0) { printf("File count is %d.\n",file_num); }

// =================================================================

    // ## num_files - if you want to run it on a subset change here
    numFiles = file_num;
   // numFiles = 5;

// decompose DIM_Y into YPARTS :  
// for each part, all time files will be read, 
// this means, all time file will be read YPARTS times
     YPARTS = 5;                                        // change this appropriately 

// since DIM_Y=6000, each LOC_YRANGE=DIM_Y/YPARTS=1200
     LOC_YRANGE = DIM_Y / YPARTS;
// LOC_YRANGE will be decomposed by each MPI process.
// numRows is num rows per MPI process, outputs data for numRows
// should be integer
     numRows=LOC_YRANGE / NUM_MPI_PROCS; 

    dat_int = (int *) CPLMalloc(sizeof(int)*DIM_X*DIM_Y*NUM_BANDS);
    datTemp = (int *) CPLMalloc(sizeof(int)*DIM_X*numRows*NUM_BANDS);
    dat_out = (int *) CPLMalloc(sizeof(int)*DIM_X*numRows*NUM_BANDS*numFiles);
// read numFiles and write out netcdf

    for(iy=0; iy < YPARTS; iy++) {
    
    // ## for some reason the wallclock timer function was giving a seg fault
    //    wallclock_timer(1);		

        // create names of netcdf output files for the part, each process write 1 netcdf output file
        // ## note that world rank links it to a specific processor
	    i1 = iy * LOC_YRANGE +world_rank*numRows;    i2=i1+numRows-1;
        sprintf(buffer3, "%s/%d-%d.nc", out_dir, i1, i2);
  

	// ## each process makes a netcdf file with the same dimensions but different names
//        if(iy == 0) init_netcdf(buffer3, DIM_X, numRows ,NUM_BANDS, numFiles, &ncid, &varid);
        init_netcdf(buffer3, DIM_X, numRows ,NUM_BANDS, numFiles, header_dat, &ncid, &varid);

//  ## debugging to print out values and quit      
//  printf("[%d] %d [%s] \n", iy, world_rank, buffer3);
// close_netcdf(ncid);
//  MPI_Finalize();
//  return 0;
     //  ## read and gather data from all files, in dat_out array
	// ## only read the number of processors at a time
	for(n=0;n<numFiles; n = n + world_size) 
	{
           // ## makes sure you dont exceed the total number of all files
	  // ## this isProcSending[i] will give you the file number the processor will be reading 
	    for(i=0; i<world_size; i++){
             isProcSending[i] = -9999 ;
             if ( (n + i) < numFiles ) { isProcSending[i] = n + i ;}
           }
           if ( isProcSending[world_rank] >= 0 ) {  // check to see if all files have been read
              read_vrt(in_list[isProcSending[world_rank]],dat_int);
              printf("read # [%d] [%s] on rank [%d] \n", isProcSending[world_rank], in_list[isProcSending[world_rank]], world_rank);
           }

              // ## Every processor that reads data, is a send processsor
              // ## in following i is the send processor
              // ## organize sends and receives such that processes do not get blocked
              for(i=0; i<world_size; i++){
		 // ## start at 0 rank - check if it will send the data - will send to all the processes
                 if (world_rank == i && isProcSending[i] >= 0 ) {
                    for(j=0; j < world_size; j++) {
			// ## sending will only happen if have already read in the data
                       if (j != i) {  // send to processor j
                          sendDataToProc_j(iy, j, LOC_YRANGE, numRows, DIM_X, DIM_Y, NUM_BANDS, world_rank,  dat_int);
                       } else {   // processor itself
                       // populate array with its own data
                           datIntToDatOut(iy, isProcSending[i], LOC_YRANGE, numRows, DIM_X, DIM_Y, numFiles, NUM_BANDS, world_rank,  dat_int, dat_out);
                       }
                    }
                 }
                 // receive on all processes except i
                 if (isProcSending[i] >= 0 ) {
                    for(j=0; j < world_size; j++) { //  receive on proc j, data sent from proc i
                       if ( j ==  world_rank && j != i ) recDataFromProc_i(isProcSending[i], i, numRows, DIM_X, numFiles, NUM_BANDS, datTemp, dat_out);
                    }
                 }
              }  // ## end for i
        }  // ### end for n

          if(world_rank == 0) printf("start writing to netcdf files, part=[%d] \n", iy);

//        if(iy == 0) out_netcdf(DIM_X, numRows, NUM_BANDS, numFiles, ncid, varid, dat_out);
        out_netcdf(DIM_X, numRows, NUM_BANDS, numFiles, ncid, varid, dat_out);

//        if(iy == 0) close_netcdf(ncid);
        close_netcdf(ncid);


       /*     if(world_rank==0) { 
			printf("image %d %s on rank %d ... %f seconds\n",i, in_list[i], world_rank,wallclock_timer(0));
		    } else {
			wallclock_timer(0);
		    }  // ## world_rank
*/
        if(world_rank==0)
        {
            printf("Looping through %d of %d\n",(iy+1),YPARTS);
          }
	}  // ## end for iy

	CPLFree(dat_int);
	CPLFree(datTemp);
	CPLFree(dat_out);

    CPLFree(header_dat);
	for(i=0;i<file_num;i++)
	{
		free(in_list[i]);
	}
	free(in_list);

        MPI_Finalize();
	
return 0;

}



// this lists some standard error messages and exits out the program
void error_message(int code, char* err)
{
	switch(code)
	{
	
		case 1:
			printf("Cannot open the file %s for read. ",err);
			break;
		case 2:
			printf("Cannot open the file %s for write. ",err);
			break;
		case 3:
			printf("Problem listing files at %s. Check path name.\n",err);
			break;
		case 4:
			printf("Can't make directory %s. Check path name.\n",err);
			break;
		case 10:
			printf("Failed to get path. Abort!\n");
			break;	
		default:
			printf("Unknown error. ");
			break;	
		
	}   // end switch

	printf("Abort!\n");
	exit(0);
}

int count_files(char* in_path,char* tok_str)
{
	struct dirent *entry,*entry2;
	DIR *dp,*dp2;
	int count;
	char *tok,*cmp_str;
	char *file_name,*temp_name,*temp_name2,*copy_name;
	
	// define the token that will break up the file names for counting
	tok = (char*)malloc(10*sizeof(char));
	sprintf(tok,".");
	
	// open the directory path for reading
  	dp = opendir(in_path);
  	if (dp == NULL) 
    		error_message(10,in_path);
		
	// loop through each name at the path	
	count = 0;
  	while(entry = readdir(dp))
	{
		// assign a temp name to keep the current item
		temp_name = (char*)malloc(1000*sizeof(char));
		sprintf(temp_name,"%s/%s",in_path,entry->d_name);

        // ## move down another level of the tree
        // open the directory path for reading
        
  	    dp2 = opendir(temp_name);
  	    if (dp2 == NULL) 
    		error_message(10,temp_name);
		
  	    while(entry2 = readdir(dp2))
	    {
            // assign a temp name to keep the current item
		    temp_name2 = (char*)malloc(1000*sizeof(char));
		    sprintf(temp_name2,"%s",entry2->d_name);

		    // copy the location of the current name to another temp name
		    copy_name = (char*)malloc(1000*sizeof(char));
		    sprintf(copy_name,"%s",temp_name2);
			
		    // begin to search through the file name for the tok symbol
		    // if there is name seg then break out of loop
		    // could check if its a directory versus file but currently dont do this
		    cmp_str = strtok(copy_name,tok);
		    while((cmp_str=strtok(NULL,tok))!=NULL)
		    {
			    // compare the str segment with our tok_str
			    // if found then we increment our count
			    if(strcmp(cmp_str,tok_str)==0)
			    {
			    	//printf("%s/%s\n",temp_name,temp_name2);
				    count++;
				    break;
			    }
		    }
            free(copy_name);
            free(temp_name2);
        } // ## end second while loop
				
		free(temp_name);

	}  // end of looping through directories
  	closedir(dp);

	return(count);
}

void list_files(char* in_path,char* tok_str,char** in_list)
{

    struct dirent *entry,*entry2;
	DIR *dp,*dp2;
	int count;
	char *tok,*cmp_str;
	char *file_name,*temp_name,*temp_name2,*copy_name;
	
	
	// define the token that will break up the file names for counting
	tok = (char*)malloc(10*sizeof(char));
	sprintf(tok,".");

	dp = opendir(in_path);
  	if (dp == NULL) 
    		error_message(10,in_path);
	
    // loop through each name at the path	
	count = 0;
  	while(entry = readdir(dp))
	{
		// assign a temp name to keep the current item
		temp_name = (char*)malloc(1000*sizeof(char));
		sprintf(temp_name,"%s/%s",in_path,entry->d_name);

        // ## move down another level of the tree
        // open the directory path for reading
        
  	    dp2 = opendir(temp_name);
  	    if (dp2 == NULL) 
    		error_message(10,temp_name);
		
  	    while(entry2 = readdir(dp2))
	    {
            // assign a temp name to keep the current item
		    temp_name2 = (char*)malloc(1000*sizeof(char));
		    sprintf(temp_name2,"%s",entry2->d_name);

		    // copy the location of the current name to another temp name
		    copy_name = (char*)malloc(1000*sizeof(char));
		    sprintf(copy_name,"%s",temp_name2);
			
		    // begin to search through the file name for the tok symbol
		    // if there is name seg then break out of loop
		    // could check if its a directory versus file but currently dont do this
		    cmp_str = strtok(copy_name,tok);
		    while((cmp_str=strtok(NULL,tok))!=NULL)
		    {
			    // compare the str segment with our tok_str
			    // if found then we increment our count
			    if(strcmp(cmp_str,tok_str)==0)
			    {
			    	sprintf(in_list[count],"%s/%s",temp_name,temp_name2);
				    count++;
				    break;
			    }
		    }
            free(copy_name);
            free(temp_name2);
        } // ## end second while loop
				
		free(temp_name);

	}  // end of looping through directories
  	closedir(dp);

	return;
}

int print_prj_info(OGRSpatialReferenceH spat_ref)
{
	char *wkt = NULL;
	char *proj4 = NULL;
	OGRErr error;
	
	error = OSRExportToWkt(spat_ref,&wkt);
	if(error != OGRERR_NONE)
	{
		printf("problem exporting spatial reference to wkt. Abort!\n");
		return 1;
	}
	
	error = OSRExportToProj4(spat_ref,&proj4);
	if(error != OGRERR_NONE)
	{
		printf("problem exporting spatial reference to proj4. Abort!\n");
		return 1;
	}
	
	printf("\nproj4 def \n%s\n\nwkt def \n%s\n",proj4,wkt);

	return 0;
}

void read_vrt(char* in, int* out)
{
	GDALDatasetH hDataset;
	GDALDriverH   hDriver;
	GDALRasterBandH band;
	GDALDataType band_type;
	double adfGeoTransform[6];
	
	const char *wkt;
	int x_size,y_size,num_bands;
	int i,b,loc;

	int *dat_int;
	float *dat;
	// ## register ogr and gdal
	GDALAllRegister();

	// open up the input raster file
	hDataset = GDALOpen(in, GA_ReadOnly);
	if(hDataset == NULL)
		error_message(1,in);
		
//	printf("Now opening file %s.\n",in);

	// get the projection of the input raster
	//wkt = GDALGetProjectionRef(hDataset);
	//if(wkt==NULL)
	//	printf("no projection found\n");
	//else
	//	printf("WKT =\n%s\n",wkt);

	//hDriver = GDALGetDatasetDriver( hDataset );
	//printf( "Driver: %s/%s\n",GDALGetDriverShortName( hDriver ),GDALGetDriverLongName( hDriver ) );
	
	x_size = GDALGetRasterXSize( hDataset ); 
        y_size = GDALGetRasterYSize( hDataset );
	
	// ## some other info we dont actually need for this function
	num_bands = GDALGetRasterCount(hDataset);
	//printf("%d,%d,%d\n",x_size,y_size,num_bands);
	
	//if( GDALGetGeoTransform( hDataset, adfGeoTransform ) == CE_None )
	//{
    	//	printf( "Origin = (%.6f,%.6f)\n",adfGeoTransform[0], adfGeoTransform[3] );
    	//	printf( "Pixel Size = (%.6f,%.6f)\n",adfGeoTransform[1], adfGeoTransform[5] );
	//}

	for(b=1;b<(num_bands+1);b++)
	{
		band = GDALGetRasterBand(hDataset,b);
		dat = (float *) CPLMalloc(sizeof(float)*x_size*y_size);
		GDALRasterIO( band, GF_Read, 0, 0, x_size, y_size, dat, x_size, y_size, GDT_Float32, 0, 0 );
		
		for(i=0;i<(x_size*y_size);i++) 
		{ 
			loc = num_bands*i + b - 1;		
			out[loc] = (int)dat[i]; 
		}
		CPLFree(dat);
	}
	
	// ## now we can close the dataset
	GDALClose(hDataset);

	return;
}

void write_to_file(FILE* f_out, int* data, int row_num, int t, int tot_t)
{
	size_t out_loc;
	size_t in_loc;
	int i,j,offset;	
	int start,end;

	start=row_num*CHUNK_SIZE;
	end = (row_num+1)*CHUNK_SIZE;
	
	for(i=start;i<end;i++)
	{
		offset = i-start;
		for(j=0;j<DIM_X;j++)
		{
			// ## the out file has the dimensions of CHUNK_SIZE*NUM_BANDS*NUM_FILES*DIM_X		
			out_loc = (NUM_BANDS*tot_t*DIM_X*offset) + (NUM_BANDS*tot_t*j) + (NUM_BANDS*t);
			fseek(f_out, (out_loc*sizeof(int)), SEEK_SET);
			in_loc = NUM_BANDS*DIM_X*i + j*NUM_BANDS;		
			fwrite(&data[in_loc],sizeof(int),NUM_BANDS,f_out);
		}		
	}
}

/***************************************************************************//**
 * @brief Wallclock timer with subsecond resolution, starts, stops, and prints                                                                               
 * @param [in] start_timer Logical flag, start timer (1) or stop timer (0)
 * @return Elapsed time if start==1, else 0
 *
 * This function is used to start and stop a wallclock timer. To start, call
 * wallclock_timer(1). To stop and get elapsed time, call t=wallclock_timer(0).
 * The program will fail with an assertion error if you attempt to start or stop
 * more than once in a row.
 ******************************************************************************/
float wallclock_timer(int start_timer) {
   
    static int on;
    static struct timeval t0;
    struct timeval t1;

    if (start_timer == 1) {
        // start timer and exit
        assert(on == 0);
        assert(gettimeofday(&t0, 0) != -1);
        on = 1;
        return 0.0;

    } else {
        // stop timer and return elapsed wallclock time
        assert(on == 1);
        assert(gettimeofday(&t1, 0) != -1);
        on = 0;
        return timeval_subtract(t1, t0);
    }
}

/***************************************************************************//**
 * @brief Subtract two timevals, x-y, returning elapsed time in seconds
 * @param x [in] 
 * @param y [in]
 * @return Elapsed time in seconds
 * 
 * Modified from http://www.gnu.org/software/libc/manual/html_node/Date-and-Time.html
 ******************************************************************************/
float timeval_subtract(struct timeval x, struct timeval y) {

    int nsec, usec, sec;

    // Perform the carry for the later subtraction by updating y 
    if (x.tv_usec < y.tv_usec) {
        nsec = (y.tv_usec - x.tv_usec) / 1000000 + 1;
        y.tv_usec -= 1000000 * nsec;
        y.tv_sec += nsec;
    }
    if (x.tv_usec - y.tv_usec > 1000000) {
        nsec = (y.tv_usec - x.tv_usec) / 1000000;
        y.tv_usec += 1000000 * nsec;
        y.tv_sec -= nsec;
    }

    // compute the time difference
    sec = x.tv_sec - y.tv_sec;
    usec = x.tv_usec - y.tv_usec;

    return (float)sec + (float)usec/1000000.0;
}

void parse_header(char **in_list,int numFiles, int *header_dat) 
{

    char *temp_str;
    char *substr;
    int cur_ind,i;

     for(i=0;i<numFiles;i++)
     {
            //   ## Get the basename of the file name
            temp_str = basename(in_list[i]);

            // ## three outputs per file
            cur_ind = i*3;         
            // ## parse the string
            substr = substring(temp_str,3, 1);
            header_dat[cur_ind]=atoi(substr);  


            cur_ind = (i*3) + 1;  
            substr = substring(temp_str, 4, 6);     
            header_dat[cur_ind]=atoi(substr);


            cur_ind = (i*3) + 2;            
            substr=substring(temp_str, 10, 7);
            header_dat[cur_ind]=atoi(substr);

            // ## debug statement
         //    printf("%s,%d,%d,%d,%d\n",temp_str,header_dat[i*3],header_dat[(i*3) + 1],header_dat[(i*3) + 1],i);
      }
    free(substr);

}

// ## C substring function: It returns a pointer to the substring 
char *substring(char *string, int position, int length) 
{
   char *pointer;
   int c;
 
   pointer = malloc(length+1);
 
   if (pointer == NULL)
   {
      printf("Unable to allocate memory.\n");
      exit(EXIT_FAILURE);
   }
 
   for (c = 0 ; c < position -1 ; c++) 
      string++; 
 
   for (c = 0 ; c < length ; c++)
   {
      *(pointer+c) = *string;      
      string++;   
   }
 
   *(pointer+c) = '\0';
 
   return pointer;
}

