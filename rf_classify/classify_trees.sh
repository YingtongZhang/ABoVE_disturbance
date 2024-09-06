#!/bin/bash -l
#$ -pe omp 8
#$ -l h_rt=24:00:00
#$-l mem_per_core=8G
#$ -N glas_class
#$ -V
#$ -j y

module purge
## need this for the raster package
#module load rgdal/0.8-10

## changed to a newer version of R that supports rgeos
module load R/3.4.0
module load rgdal/1.1.9

## arguments should go year and then tile
Rscript ./classify_glas_chunk.R $1 $2 $3 $4 $5
