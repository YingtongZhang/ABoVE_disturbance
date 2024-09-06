#!/bin/bash -l

#$ -N reproj_ras
#$ -pe omp 1
#$ -j y
#$ -V

in_dir="../VRTs"
declare -a $in_names=("C2C_change_nochange" "C2C_change_type" "C2C_change_year")
in_tile="Bh11v11"

cur_dir="${in_dir}/${in_tile}"

for i in `find $cur_dir -name *.vrt`; do
    temp_file=$i
#    echo $i
done

for in_name in ${in_names[@]}; do 

#echo $i
#done
echo "Reading in $temp_file for projection info"
UL=$(gdalinfo ${temp_file} | grep "Upper Left")
LR=$(gdalinfo ${temp_file} | grep "Lower Right")
UL=$(echo $UL | cut -f2 -d"(" | cut -f1 -d")")
LR=$(echo $LR | cut -f2 -d"(" | cut -f1 -d")")
ulx=$(echo $UL | cut -f1 -d",")
lrx=$(echo $LR | cut -f1 -d",")
uly=$(echo $UL | cut -f2 -d",")
lry=$(echo $LR | cut -f2 -d",")


in_file="${in_name}.tif" 
out_file="${in_name}/${in_name}.$in_tile.tif"
## crop to cutline screws up the edge pixels - so we use -te instead
echo gdalwarp -of \"GTiff\" -te $ulx $lry $lrx $uly -t_srs \'+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs\' -tr 30 -30 -overwrite $in_file $out_file
gdalwarp -of "GTiff" -te $ulx $lry $lrx $uly -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs' -tr 30 -30 -overwrite $in_file $out_file

done

