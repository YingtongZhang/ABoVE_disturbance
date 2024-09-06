#include <stdlib.h>
#include <stdio.h>

#include <mpi.h>

int sendDataToProc_j(iy, destRank, LOC_YRANGE, numRows, DIM_X, DIM_Y, NUM_BANDS, sendProcRank,  dat_int)
int iy, destRank, LOC_YRANGE, numRows, DIM_X, DIM_Y, NUM_BANDS, sendProcRank;
int dat_int[DIM_Y][DIM_X][NUM_BANDS];

{
   int yIndex, count, tag;
   
   yIndex = iy * LOC_YRANGE + destRank * numRows;
   count=numRows*DIM_X*NUM_BANDS;
   tag=sendProcRank;
   MPI_Send(&dat_int[yIndex][0][0], count, MPI_INT, destRank, tag, MPI_COMM_WORLD);
}

// ## receives the data from the processors
int recDataFromProc_i(n, sourceRank, numRows, DIM_X, numFiles, NUM_BANDS, datTemp, dat_out)
// n is the file number
int n, sourceRank, numRows, DIM_X, numFiles, NUM_BANDS;
int datTemp[numRows][DIM_X][NUM_BANDS];
int dat_out[numRows][DIM_X][numFiles][NUM_BANDS];

{
   int count, sourceTag;
   
   count=numRows*DIM_X*NUM_BANDS;
   sourceTag=sourceRank;
   MPI_Recv(&datTemp[0][0][0], count, MPI_INT, sourceRank, sourceTag, MPI_COMM_WORLD, MPI_STATUS_IGNORE);

   // copy data from temp array to out array
   int row, x, bands;
   for(row=0; row < numRows ; row++ ) {
     for(x=0; x < DIM_X; x++) {
       for(bands=0; bands < NUM_BANDS; bands++) {
          dat_out[row][x][n][bands]=datTemp[row][x][bands];
       }
     }
   }
}

// ## rearranges the data for writing out to netcdf
int datIntToDatOut(iy, n, LOC_YRANGE, numRows, DIM_X, DIM_Y, numFiles, NUM_BANDS, procRank,  dat_int, dat_out)
int iy, n, LOC_YRANGE, numRows, DIM_X, DIM_Y, numFiles, NUM_BANDS, procRank;
int dat_int[DIM_Y][DIM_X][NUM_BANDS];
int dat_out[numRows][DIM_X][numFiles][NUM_BANDS];

{
   int gyIndex, row, x, bands, gRow; 
	
   gyIndex = iy * LOC_YRANGE + procRank * numRows;
   for(row=0; row < numRows ; row++ ) {
     gRow = gyIndex + row ;
     for(x=0; x < DIM_X; x++) {
       for(bands=0; bands < NUM_BANDS; bands++) {
          dat_out[row][x][n][bands]=dat_int[gRow][x][bands];
       }
     }
   }
}
