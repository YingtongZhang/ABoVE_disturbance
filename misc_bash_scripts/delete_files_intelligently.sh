#!/bin/csh
#$ -pe omp 1
#$ -l h_rt=50:00:00

find . -maxdepth 4 -name '*lndcal*' -delete
find . -maxdepth 4 -name '*lndcsm*' -delete
find . -maxdepth 4 -name '*lndth*' -delete


