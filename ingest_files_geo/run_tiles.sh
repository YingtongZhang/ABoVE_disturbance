#!/bin/bash -l
#$ -pe omp 8
#$ -l mem_total=98G
#$ -N run_tilez
#$ -l h_rt=40:00:00
#$ -j y

echo $HOSTNAME

## We check to make sure there is an argument to the script - should be one argument for the current path/row
if [ -z "$1" ]
then
echo Usage:  "./run_tiles.sh pr_name in_sens out_tile"
## exit script if it doesnt find the arguments
exit
else
in_name=$1
fi

if [ -z "$2" ]
then
echo Usage:  "./run_tiles.sh pr_name in_sens out_tile"
## exit script if it doesnt find the arguments
exit
else
## in_sens needs to be either LT5 or LE7
in_sens=$2
fi

if [ -z "$3" ]
then
echo Usage:  "./run_tiles.sh pr_name in_sens out_tile"
## exit script if it doesnt find the arguments
exit
else
## in_sens needs to be either LT5 or LE7
out_tile=$3
fi

## setup output directory
cur_yaml="above_ingest.yaml"

work_dir="/projectnb/landsat/users/dsm/above"
in_dir="$work_dir/tile_in/${out_tile}"

echo "Processing $in_sens $in_name files in $in_dir"

temp_name="${in_sens}${in_name}"
echo $temp_name
n=$(find $in_dir -maxdepth 2 -name ${temp_name}\*.xml | wc -l)
i=1
echo "Found $n images to process"

tile_h=`echo $out_tile | cut -c3-4`
tile_v=`echo $out_tile | cut -c6-7`

cur_tile_id=`sqlite3 -init <(echo .timeout 2000) tilezilla.db "select id from tile where vertical=$tile_v and horizontal=$tile_h;"`

module purge
export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8
## this activates the virtual environment i need to run
source $HOME/miniconda3/bin/activate tilezilla
## go into the run directory

cd $work_dir
## export this directory as root
export root=$(readlink -f $(pwd))

for xml_file in $(find $in_dir -maxdepth 2 -name ${temp_name}\*.xml); do

    # Use AWK to remove _MTL.txt
    id=$(basename $xml_file | awk -F '.' '{ print $1 }')
    echo "<----- $i / $n: $id"
    
    ## to get other files
    cur_in_dir=$(dirname $xml_file)
    ## fake_id is the current dir/stack name
    id=$(basename $cur_in_dir)

    ## check if any of the bands have been processed already and if all the bands have been processed we dont do anything
    tot_bands=`sqlite3 -init <(echo .timeout 2000) tilezilla.db "select count(b.path) from product p, band b, tile t where b.product_id=p.id and p.timeseries_id='$id' and t.id=p.tile_id and t.id='$cur_tile_id';"`
    in_bands=`ls -l $cur_in_dir/*tif | wc -l`
    if [ "$tot_bands" -eq "$in_bands" ]; then
 	echo "$id has been processsed"
     else
	echo "tilez -C $cur_yaml ingest $cur_in_dir"
	tilez -C $cur_yaml ingest $cur_in_dir
	echo "Finished tiling ${id}"
    fi
    
    # Iterate count
    let i+=1
done

source deactivate
echo "Done with all files"
