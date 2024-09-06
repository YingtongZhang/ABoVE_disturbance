#!/bin/csh
#$ -l h_rt=96:00:00


wget -r -A "MCD43A4*" -nd "ftp://crsftp.bu.edu/modis/zhuosen/forDamien/h12v04_v6_wholeyear/" ;
