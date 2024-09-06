#!/bin/csh
#$ -pe omp 1
#$ -l h_rt=96:00:00

gzip -r composite_data/*
