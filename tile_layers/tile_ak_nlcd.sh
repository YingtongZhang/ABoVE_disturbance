#!/bin/bash -l

#$ -N clip_ras
#$ -pe omp 1
#$ -j y
#$ -V


if [ -z $1 ]; then
echo "No argument given"
exit; fi

if [ -z $2 ]; then
echo "No 2nd argument given"
exit; fi

in_file=$1
out_stem=$2


ulx=-3400020
uly=4640000
pix=30
dim=6000

in_dir="/projectnb/landsat/projects/ABOVE/dsm_develop/tile_ak_nlcd/"

for in_tile in `cat ak_tiles.txt`; do

## in tile starts with B
    h=`echo $in_tile | cut -c3-4`
    v=`echo $in_tile | cut -c6-7`

    ulx_map=`echo "scale=9; $ulx + ($h * $pix * $dim)" | bc`
    uly_map=`echo "scale=9; $uly - ($v * $pix * $dim)" | bc`
    lrx_map=`echo "scale=9; $ulx + (($h+1) * $pix * $dim)" | bc`
    lry_map=`echo "scale=9; $uly - (($v+1) * $pix * $dim)" | bc`

    out_file="./tiled/AK_NLCD.$out_stem.$in_tile.tif"

    echo gdalwarp -of \"GTiff\" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs \'+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs\' -tr ${pix} -${pix} -overwrite $in_file $out_file
    gdalwarp -of "GTiff" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs' -tr ${pix} -${pix} -overwrite $in_file $out_file
done ## end scene list


