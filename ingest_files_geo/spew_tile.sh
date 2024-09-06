#!/bin/bash -l
#$ -pe omp 4
#$ -l mem_total=98G
#$ -N make_vrts
#$ -j y

module purge
module load gdal

## We check to make sure there is an argument to the script - should be one argument for the tile name
if [ -z "$1" ]
then
echo Usage:  "./spew_tile.sh in_name"
## exit script if it doesnt find the arguments
exit
else
in_name=$1
fi

tile_h=`echo $in_name | cut -c3-4`
tile_v=`echo $in_name | cut -c6-7`

## setup output directory
out_dir="./VRTs/$in_name"

if [ ! -d $out_dir ]; then
	mkdir $out_dir
fi

cur_tile=`sqlite3 tilezilla.db "select t.id from tile t where t.vertical=${tile_v} and t.horizontal=${tile_h};"`
## to get all the path/row ids for that tile
sqlite3 tilezilla.db "select p.timeseries_id from tile t, product p where p.tile_id = t.id and t.id=${cur_tile};" > tile_list_${cur_tile}.txt

echo "Now spewing data for tile $in_name with tile db id $cur_tile"

for pr in `cat tile_list_${cur_tile}.txt`;
do
	## first we count the number of bands if they equal 8 then we make a vrt from the return of the next query
	nbands=`sqlite3 tilezilla.db "select count(path) from tile t, product p, band b where b.product_id=p.id and p.tile_id=t.id and t.id=${cur_tile} and p.timeseries_id='$pr';"`
	if [ $nbands -eq 8 ]; then
		## select the paths for that tile - copy to a temporary text file that has the name of the tile so we can run multiple processes at once
		sqlite3 tilezilla.db "select path from tile t, product p, band b where b.product_id=p.id and p.tile_id=t.id and t.id=${cur_tile} and p.timeseries_id='$pr';" > temp_${cur_tile}_${pr}.txt

		## run the query - we reorder bands 7 and 8 since band 7 is listed as the cfmask
		gdalbuildvrt -separate -b "1 2 3 4 5 6 7 8" ${out_dir}/${pr}.vrt -input_file_list temp_${cur_tile}_${pr}.txt
	
		rm -f temp_${cur_tile}_${pr}.txt
	fi

## now we just need a way to pipe values into the database and similarly to extract data out into a list of variables
done

echo "Done with all files"
