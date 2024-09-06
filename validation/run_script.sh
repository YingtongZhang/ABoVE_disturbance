#!/bin/bash -l
#$ -pe omp 1
#$ -l mem_total=98G
#$ -l h_rt=24:00:00
#$ -N create_shp
#$ -V
#$ -j y

module purge

## changed to a newer version of R that supports rgeos
module load R/3.4.0
module load rgdal/1.1.9

Rscript ./create_valid_shp.R $1


