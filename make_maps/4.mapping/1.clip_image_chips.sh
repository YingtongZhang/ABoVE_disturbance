#!/bin/bash -l

#$ -N crop_img_example
#$ -pe omp 1
#$ -j y
#$ -V

module purge
source /projectnb/landsat/users/zhangyt/miniconda3/bin/activate measures

#tile="Bh09v15"
#ulx=-1779600
#uly=1815000

#tile="Bh12v13"
#ulx=-1215476
#uly=2191041

#tile="Bh07v03"
#ulx=-2054460
#uly=4098490

#tile="Bh13v15"
#ulx=-1010086
#uly=1845536

#tile="Bh03v06"
#ulx=-2753535
#uly=3435000

tile="Bh13v09"
ulx=-1001363
uly=3007100

#pix=30
#dim=1000

pix=30
dim=550

ulx_map=`echo "scale=9; $ulx" | bc`
uly_map=`echo "scale=9; $uly" | bc`
lrx_map=`echo "scale=9; $ulx + $pix * $dim" | bc`
lry_map=`echo "scale=9; $uly - $pix * $dim" | bc`


# Set year and step info
first_yr=2005
last_yr=2008
step=1
fy=$(printf %02d $first_yr)
ly=$(printf %02d `expr $last_yr - $step`)


## clip annual change map
for year in $(seq -w $fy $step $ly);do

##suffix_filename="_ABoVE_disturbance_agents_$year.tif"
##in_file="/projectnb/landsat/projects/ABOVE/CCDC/$tile/new_map/out_agents/$tile$suffix_filename"
#ss="_cl_pp.tif"
#suffix_filename="_FF_FN_NF_NN_$year$ss"
#in_file="/projectnb/landsat/projects/ABOVE/CCDC/$tile/new_map/out_pp/$tile$suffix_filename"
#out_file="/projectnb/landsat/users/zhangyt/above/pngs/chips/$tile/tifs/$year.subset_$tile.tif"

## crop to cutline screws up the edge pixels - so we use -te instead
#echo gdalwarp -of \"GTiff\" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs \'+proj=aea +lat_1=50 +lat_2=70 +lat_0=40+lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs\' -tr ${pix} -${pix} -overwrite $in_file $out_file

#gdalwarp -of "GTiff" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs' -tr ${pix} -${pix} -overwrite $in_file $out_file



# clip the background sysnthetic image
# suffix="_ABoVE_disturbance_agents_$year.tif"
# suffix="_$year.tif"
suffix="_fireDB_$year.tif"
# img_file="/projectnb/landsat/projects/ABOVE/CCDC/$tile/out_tif/$tile$suffix"
# img_file="/projectnb/landsat/projects/ABOVE/CCDC/$tile/new_map/out_agents/$tile$suffix"
img_file="/projectnb/landsat/users/shijuan/above/ABOVE_fires_new/ABOVE_fireDB/$tile/$tile$suffix"
out_img="/projectnb/landsat/users/zhangyt/above/pngs/chips/$tile/FDB/$tile$suffix"

echo gdalwarp -of "GTiff" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs' -tr ${pix} -${pix} -overwrite $img_file $out_img

gdalwarp -of "GTiff" -te $ulx_map $lry_map $lrx_map $uly_map -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs' -tr ${pix} -${pix} -overwrite $img_file $out_img

done

conda deactivate
