#!/bin/bash -l
#$ -l h_rt=12:00:00
#$ -j y
#$ -N raster_maps
#$ -V
#$ -pe omp 4
#$ -l mem_total=98G

out_dir="./outputs"
if [ ! -d $out_dir ] ; then 
mkdir $out_dir
fi

ulx=-3400020
uly=4640000
pix=30
dim=6000

in_dir="/projectnb/landsat/users/dsm/above/alaska_fire"
for tile in `cat tiles.txt`; do

h=`echo $tile | cut -c2-3`
v=`echo $tile | cut -c5-6`

ulx_map=`echo "scale=9; $ulx + ($h * $pix * $dim)" | bc`
uly_map=`echo "scale=9; $uly - ($v * $pix * $dim)" | bc`
lrx_map=`echo "scale=9; $ulx + (($h+1) * $pix * $dim)" | bc`
lry_map=`echo "scale=9; $uly - (($v+1) * $pix * $dim)" | bc`

for in_stem in FirePerim1979earlier FirePerim1980_1989 FirePerim1990_1999 FirePerim2000_2009 FirePerim2010_2012 FirePerim2013 FirePerim2014; do

in_file="${in_dir}/${in_stem}.shp"

out_file="$out_dir/$in_stem.B${tile}.tif"

gdal_rasterize -ot Byte -at -l $in_stem -a Fire_Year -init 0 -te $ulx_map $lry_map $lrx_map $uly_map -tr 30 -30 $in_file $out_file

done

done


