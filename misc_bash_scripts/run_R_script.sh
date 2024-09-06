#!/bin/csh
#$ -pe omp 1
#$ -l h_rt=5:00:00
#time ./extract_data.exe
R --vanilla < "read_dat.R"

