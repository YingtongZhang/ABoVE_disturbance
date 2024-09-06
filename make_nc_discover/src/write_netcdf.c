#include <stdlib.h>
#include <stdio.h>
#include <netcdf.h>

/* Handle errors by printing an error message and exiting with a
 * non-zero status. */
#define ERRCODE 2
#define ERR(e) {printf("Error: %s\n", nc_strerror(e)); exit(ERRCODE);}

#define NDIMS 4

// ## local definitions
int out_netcdf(int DIM_X, int numRows, int NUM_BANDS, int numFiles, int ncid, int varid, int dat_out[numRows][DIM_X][numFiles][NUM_BANDS]);
int init_netcdf(char *FILE_NAME, int NX, int NY, int NUM_BANDS, int numFiles, int *header_dat, int *ncid1, int *varid1);
int write_data_unlimited(int ncid, int varid, size_t start[], size_t count[], int *data_out);

int out_netcdf(int DIM_X, int numRows, int NUM_BANDS, int numFiles, int ncid, int varid, int dat_out[numRows][DIM_X][numFiles][NUM_BANDS])
{

   size_t start[NDIMS], count[NDIMS];
   int rec, x, y;

   start[0]=0; start[1]=0; start[2]=0; start[3]=0;
   count[0]=numRows; count[1]=DIM_X; count[2]=numFiles; count[3]=NUM_BANDS;

   write_data_unlimited(ncid, varid, start, count, &dat_out[0][0][0][0]);

}

int init_netcdf(char *FILE_NAME, int NX, int NY, int NUM_BANDS, int numFiles, int *header_dat, int *ncid1, int *varid1) 
{

   int ncid, varid;
   int bands_dimid, time_dimid, x_dimid, y_dimid, head_dimid;
   int dimids[NDIMS],dimids_head[2];
   int retval;
   int shuffle, deflate, deflate_level;
   int varid_head;
   size_t start[2], count[2];


   shuffle = NC_SHUFFLE;
   deflate = 1;
   deflate_level = 9;
     
   // ## Create the file. The NC_NETCDF4 parameter tells netCDF to create
   // ## a file in netCDF-4/HDF5 standard. 
   if ((retval = nc_create(FILE_NAME, NC_NETCDF4, &ncid))) ERR(retval);

   // ## Define the dimensions of the data array
   if ((retval = nc_def_dim(ncid, "bands", NUM_BANDS, &bands_dimid))) ERR(retval);
   if ((retval = nc_def_dim(ncid, "time", numFiles, &time_dimid))) ERR(retval);
   if ((retval = nc_def_dim(ncid, "x", NX, &x_dimid))) ERR(retval);
   if ((retval = nc_def_dim(ncid, "y", NY, &y_dimid))) ERR(retval);
  

   // ##  Set up the dimensions of the data variable
   dimids[0] = y_dimid;
   dimids[1] = x_dimid;
   dimids[2] = time_dimid;
   dimids[3] = bands_dimid;

   // ## Define the main variable. - will contain 4 dimensional TS data
   if ((retval = nc_def_var(ncid, "data", NC_INT, NDIMS, dimids, &varid))) ERR(retval);
   if ((retval = nc_def_var_deflate(ncid, varid, shuffle, deflate, deflate_level))) ERR(retval);

    // ## put the header variables in the file - only needs to be done one time
    
     if ((retval = nc_def_dim(ncid, "head", 3, &head_dimid))) ERR(retval); 
     // ## setup the dimensions of the second header variable
   dimids_head[0] = time_dimid;
   dimids_head[1] = head_dimid;
    start[0]=0;
    start[1]=0;
    count[0]=numFiles;
    count[1]=3;
    if ((retval = nc_def_var(ncid, "head", NC_INT, 2, dimids_head, &varid_head))) ERR(retval);
    // ## debug statement
   //  printf("%d,%d,%d\n",header_dat[0][0],header_dat[0][1],header_dat[0][2]);
    if ((retval = nc_put_vara_int(ncid, varid_head, start, count,  &header_dat[0]))) ERR(retval);

   *ncid1=ncid; *varid1=varid;

}

int write_data_unlimited(int ncid, int varid, size_t start[], size_t count[], int *data_out) 
{
   int retval;
   if ((retval = nc_put_vara_int(ncid, varid, start, count, data_out)))
      ERR(retval);
}

int close_netcdf(int ncid) 
{
   int retval;
   /* Close the file. */
   if ((retval = nc_close(ncid)))
      ERR(retval);

   return 0;
}
