#!/bin/bash -l
#$ -V
#$ -N run_ffmpeg
#$ -j y

module load ffmpeg
ffmpeg -r 1/2 -i "ndvi_etm_%03d.jpg" ./Bh11v11_mov.mp4

