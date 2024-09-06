#!/bin/bash
#$ -l h_rt=24:00:00
#$ -j y
#$ -N fire_maps
#$ -V
#$ -pe omp 4
#$ -l mem_total=98G

## We check to make sure there is an argument to the script - should be one argument for the tile name
if [ -z "$1" ]
then
echo Usage:  "./reproj_fire.sh in_name out_tile"
## exit script if it doesnt find the arguments
exit
else
in_name=$1
fi

if [ -z "$2" ]
then
echo Usage:  "./reproj_fire.sh in_name out_tile"
## exit script if it doesnt find the arguments
exit
else
tile=$2
fi

out_dir="./lfdb_$tile"
if [ ! -d $out_dir ] ; then 
mkdir $out_dir
fi

## find an exisiting vrt to use for the projection/extent
img_dir="/projectnb/modislc/users/dsm/above/test_vrts/${tile}"
for vrt_file in $(find $img_dir -maxdepth 2 -name '*.vrt'); do
    # Use AWK to remove .xml
    id=$(basename $vrt_file | awk -F '.' '{ print $1 }')
    echo $id
    break
done

echo $vrt_file

function gdal_extent() {
    if [ -z "$1" ]; then 
        echo "Missing arguments. Syntax:"
        echo "  gdal_extent <input_raster>"
        return
    fi
    EXTENT=$(gdalinfo $1 |\
        grep "Lower Left\|Upper Right" |\
        sed "s/Lower Left  //g;s/Upper Right //g;s/).*//g" |\
        tr "\n" " " |\
        sed 's/ *$//g' |\
        tr -d "[(,]")
    echo -n "$EXTENT"
}

extent=`gdal_extent $vrt_file`

## get this vrt into a 1 band tif with the right name
out_name="${out_dir}/LFDB.tif"
#gdal_translate $vrt_file -b 1 $out_name

short_name=`echo $in_name | cut -d"." -f1`

echo "gdal_rasterize -at -l temp_fire -a YEAR -init 0 -te $extent -tr 30 -30 $in_name $out_name"
gdal_rasterize -at -l $short_name -a YEAR -init 0 -te $extent -tr 30 -30 $in_name $out_name


