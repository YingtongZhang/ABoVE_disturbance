#!/bin/bash

echo "Job starting on $HOSTNAME"

## setup output directory

work_dir="/att/nobackup/dsullame/tilez_all_above"
in_dir="/att/nobackup/dsullame/test_mirror"

code_dir="$NOBACKUP/tilez_all_above"
global_tiles="$NOBACKUP/setup_global_runs/global_scene.txt"
num_scenes=$(more $global_tiles | wc -l)

echo Processing total of $num_scenes scenes. 

out_count="./all_counts.txt"
out_list="./all_scenes.txt"

if [ ! -z $out_count ]; then
rm -f $out_count
fi
if [ ! -z $out_list ]; then
rm -f $out_list
fi

## initialize the two files for later
cat -v > $out_count << EOF
EOF

cat -v > $out_list << EOF
EOF

for in_sens in 'LT5' 'LE7' ; do

count=1
for p in `cat $global_tiles`; do

echo $p $count $in_sens

## a much easier way to search through dirs
all_landsat_dir="/att/pubrepo/LANDSAT/EDC-ESPA/${in_sens}/${p}"

echo "Processing $in_sens $p files in $in_dir"

temp_name="${in_sens}${p}"
echo $temp_name
n=$(find $all_landsat_dir -maxdepth 2 -name ${temp_name}\*.xml | wc -l)
i=1
echo "Found $n images to process"

## go into the run directory
cd $work_dir

tot_count=0
good_count=0
bad_count=0
for xml_file in $(find $all_landsat_dir -maxdepth 2 -name ${temp_name}\*.xml); do

    # Use AWK to remove .xml
    id=$(basename $xml_file | awk -F '.' '{ print $1 }')
    echo "<----- $i / $n: $id"
    
    ## to get other files
    cur_in_dir=${in_dir}/${id}

    ## new bash routine written by dsm 12/19/16
    ### this will fix the problem with the database locked
    cur_tiles=`sqlite3 -init <(echo .timeout 20000) tilezilla.db "select distinct t.id from product p, band b, tile t where b.product_id=p.id and p.timeseries_id='$id' and t.id=p.tile_id;"`
    
    process_flag=0   
    tile_count=0
    ## will loop through the list of tiles for this id to see if the number of files makes sense
    for t in `echo $cur_tiles`; do
        let "tile_count = $tile_count + 1"
        ## this will be the "friendly names" that exist for that tile and that id
        cur_bands=`sqlite3 -init <(echo .timeout 20000) tilezilla.db "select b.friendly_name from product p, band b, tile t where b.product_id=p.id and p.timeseries_id='$id' and t.id='$t' and t.id=p.tile_id;"`
	
	band_count=0
	toa_flag=0
	cfmask_flag=0
	## now we loop through the bands that exist and check to make sure that one of them is toa_band6
	for b in `echo $cur_bands`; do
	    let "band_count = $band_count + 1"
	    if [ "$b" = "toa_band6" ]; then
	        toa_flag=1
	    fi
	    if [ "$b" = "cfmask" ]; then
		cfmask_flag=1
	    fi
	done
	## we have counted the bands that exist for this tile - toa flag is 1 if it exists
	echo "TileID $t for $id has $band_count bands. TOA_flag is $toa_flag and cfmask_flag is $cfmask_flag"

	## now we check whether we need to process this tile - if the number of bands is less than 8
	if [ ! -n "$band_count" ]; then
	    # the band count is null  so it will need to be processed
	    process_flag=1
	elif [ "$band_count" -ne "8" ]; then
	    ## a caveat exists if the number of bands is 1 and it is the toa band - sometimes the toa band is larger in extent than the other files
	    if [ "$toa_flag" -eq "1" -a "$band_count" -eq "1" ]; then
	        :
	    ## a second caveat exists if there are 6 bands and they are missing the toa band and the cfmask band
	    ## this happens if the toa band and cfmask have a smaller extent than the other 6 bands
	    elif [ "$band_count" -eq "6" -a "$toa_flag" -eq "0" -a "$cfmask_flag" -eq "0" ]; then
		:
	    else
		process_flag=1
	    fi
	fi

	(( tot_count++ ))
    done  ## finished whole tile search
	
    if [ "$process_flag" -eq "1" ]; then

cat -v >> $out_list << EOF
${id}
EOF

    	(( bad_count++ ))
    else
	(( good_count++ ))
    fi

    (( i++ ))
done ## finished id loop

cat >> $out_count << EOF
${p},${in_sens},${n},${good_count},${bad_count},${tot_count}
EOF

	(( count++ ))
done  ## finished p loop
done  ## finished in_sens


echo "Done with all $count scenes"
