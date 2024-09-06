#!/bin/bash -l

## add discover commands instead
#$ -pe omp 16
#$ -l h_rt=24:00:00
#$ -l mem_total=98G
#$ -N jpg_make
#$ -V
#$ -j y

if [ -z "$1" ]; then
    echo Usage is ./make_jpgs.sh in_tile
    echo No argument 1 provided!
else
    in_tile=$1
fi

code_loc="/projectnb/landsat/users/dsm/above/make_phen/make_jpgs"
module purge

module load R/3.4.0
module load rgdal/1.1.9

in_dir="../${in_tile}_phen"
out_dir="./jpgs_${in_tile}"

echo Rscript ${code_loc}/make_jpgs.R $in_tile $in_dir $out_dir

Rscript ${code_loc}/make_jpgs.R $in_tile $in_dir $out_dir

