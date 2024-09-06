#!/bin/bash

echo "Job starting on $HOSTNAME"

## We check to make sure there is an argument to the script - should be one argument for the tile name
if [ -z "$1" ]; then
	echo Usage:  "./run_tiles.sh in_name in_sens"
	## exit script if it doesnt find the arguments
	exit
else
	in_name=$1
fi

if [ -z "$2" ]; then
	echo Usage:  "./run_tiles.sh in_name in_sens"
	## exit script if it doesnt find the arguments
	exit
else
	## in_sens needs to be either LT5 or LE7
	in_sens=$2
fi

## setup output directory

work_dir="/att/nobackup/dsullame/tilez_all_above"
cur_yaml="$work_dir/above_ingest.yaml"
in_dir="/att/nobackup/dsullame/test_mirror"
## a much easier way to search through dirs
all_landsat_dir="/att/pubrepo/LANDSAT/EDC-ESPA/${in_sens}/${in_name}"

echo "Processing $in_sens $in_name files in $in_dir"

temp_name="${in_sens}${in_name}"
echo $temp_name
n=$(find $all_landsat_dir -maxdepth 2 -name ${temp_name}\*.xml | wc -l)
i=1
echo "Found $n images to process"

tot_bands=0

export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8
## this activates the virtual environment i need to run
source $HOME/miniconda3/bin/activate tilezilla

## when we start this environ we lost gdal_data
GDAL_DATA="/opt/gdal-static/share/gdal"

## go into the run directory

cd $work_dir

## export this directory as root
export root=$(readlink -f $(pwd))

for xml_file in $(find $all_landsat_dir -maxdepth 2 -name ${temp_name}\*.xml); do

    # Use AWK to remove .xml
    id=$(basename $xml_file | awk -F '.' '{ print $1 }')
    echo "<----- $i / $n: $id"
    
    ## to get other files
    cur_in_dir=${in_dir}/${id}

    tot_bands=`sqlite3 tilezilla.db "select count(b.path) from product p, band b where b.product_id=p.id and p.timeseries_id='$id';"`
    let "mod_bands = $tot_bands % 8"
    echo "$mod_bands $tot_bands"
    if [ $mod_bands -eq 0 ] && [ $tot_bands -gt 0 ]; then		
	echo "$id has been processsed"
	temp=3
     else
		echo "$id has $mod_bands bands processed"
		echo "tilez -C $cur_yaml ingest $cur_in_dir"
		tilez -C $cur_yaml ingest $cur_in_dir*
		echo "Finished tiling ${id}"
     fi
    
    # Iterate count
    let i+=1
done

source deactivate
echo "Done with all files"
