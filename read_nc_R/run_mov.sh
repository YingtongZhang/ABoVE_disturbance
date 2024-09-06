#!/bin/bash -l


#SBATCH -o make_jpg.%j
#SBATCH -J MAKE_JPG
#SBATCH --ntasks=8

### wrapper script to run the R script make_mov.R

module load other/R-3.2.2

echo Rscript ./make_mov.R 
Rscript ./make_mov.R 


