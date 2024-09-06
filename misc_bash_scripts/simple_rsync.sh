#!/bin/csh
#$ -pe omp 1
#$ -l h_rt=50:00:00

rsync -av -r --progress /net/casrs1/volumes/cas/landsat25/reference_images/catalog /net/casrs1/volumes/cas/modisk/moscratch/dsm/
#gzip -r annual_vs_all2/*
