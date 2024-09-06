#!/bin/bash -l

## add discover commands to run on discover

## these are GEO directives
#$ -pe omp 4
#$ -l h_rt=24:00:00
#$ -l mem_total=98G
#$ -N tif_make
#$ -V
#$ -j y

code_loc="/usr2/faculty/dsm/codes/above/read_nc_R"
module purge

module load R/3.4.0
module load rgdal/1.1.9

if [ -z "$1" ]; then
    echo Usage is ./make_tiffs.sh in_tile out_met
    echo "out_met has to be one of etm, tm5, phen"
    echo No argument 1 provided!
    exit
fi
    

echo Rscript ${code_loc}/make_tiffs.R $1 $2 $3 $4 $5
Rscript ${code_loc}/make_tiffs.R $1 $2 $3 $4 $5
