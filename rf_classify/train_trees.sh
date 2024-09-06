#!/bin/bash -l
#$ -pe omp 16
#$ -l h_rt=24:00:00
#$ -N glas_train
#$ -V
#$ -j y


START=$(date +%s.%N)
Rscript ./train_glas.R


END=$(date +%s.%N)
DIFF=$(echo "$END - $START" | bc)
echo "It took $DIFF seconds to execute this program."
