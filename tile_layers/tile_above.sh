#!/bin/bash -l

#$ -N reproj_ras
#$ -pe omp 1
#$ -j y
#$ -V

ulx=-3400020
uly=4640000
pix=30
dim=6000

in_dir="../VRTs"
declare -a in_names=("C2C_change_nochange" "C2C_change_type" "C2C_change_year")
#in_tile="Bh11v11"

for in_tile in `cat scene_list.txt`;
do


h=`echo $in_tile | cut -c2-3`
v=`echo $in_tile | cut -c5-6`

ulx_map=`echo "scale=9; $ulx + ($h * $pix * $dim)" | bc`
uly_map=`echo "scale=9; $uly - ($v * $pix * $dim)" | bc`
lrx_map=`echo "scale=9; $ulx + (($h+1) * $pix * $dim)" | bc`
lry_map=`echo "scale=9; $uly - (($v+1) * $pix * $dim)" | bc`

for in_name in ${in_names[@]}; do 

in_file="${in_name}.tif" 
out_file="${in_name}/${in_name}.B$in_tile.tif"
## crop to cutline screws up the edge pixels - so we use -te instead
echo gdalwarp -of \"GTiff\" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs \'+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs\' -tr ${pix} -${pix} -overwrite $in_file $out_file
gdalwarp -of "GTiff" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs' -tr ${pix} -${pix} -overwrite $in_file $out_file

done  ## end in names

done ## end scene list

