#!/bin/bash -l

## add discover commands instead
#$ -pe omp 16
#$ -l h_rt=24:00:00
#$ -l mem_total=98G
#$ -N nc_read
#$ -V
#$ -j y

### wrapper script to run the R script read_nc.R

if [ -z "$1" ]
then
echo Usage is ./read_nc.sh data_dir in_tile out_dir
echo No argument 1 provided! 
else
data_dir=$1
fi

in_tile=$2
out_dir=$3

code_loc="/projectnb/landsat/users/dsm/above/make_phen"
module purge

module load R/3.4.0
module load rgdal/1.1.9


echo Rscript $code_loc/read_nc.R $data_dir $in_tile $out_dir $4 $5

Rscript ${code_loc}/read_nc.R $data_dir $in_tile $out_dir $4 $5


