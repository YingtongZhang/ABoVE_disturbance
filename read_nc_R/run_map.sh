#!/bin/bash -l

#SBATCH -o comb_chunk.%j
#SBATCH -J COMB_CHUNK
#SBATCH --ntasks=8

### wrapper script to run the R script make_map.R

module load other/R-3.2.2

echo Rscript ./make_map.R 
Rscript ./make_map.R 


