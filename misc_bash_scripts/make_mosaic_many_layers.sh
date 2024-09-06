#!/bin/bash -l
#$ -pe omp 4
#$ -N mos_layers
#$ -j Y
#$ -V


module purge
source ~/.module


uly_map=10007554.677
ulx_map=-20015109.354
lry_map=-10007554.677
lrx_map=20015109.354
pix=463.312716525
dim=2400

in_stem="$1"
if [ -z $in_stem ]; then
    in_stem="prior.ag"
fi

nbands="$2"
if [ -z $nbands ]; then
    nbands=3
fi

in_dir="$3"
if [ -z $in_dir ]; then
    in_dir="../../luge_cropland_map/smoothed_data/outputs"
fi

head_flag="$4"
if [ -z $head_flag ]; then
    head_flag=1
fi

out_dir="."

dtype=4
out_type="Float32"
if [ "$head_flag" -eq "1" ]; then
suff=".bin"
else
suff=".bip"
fi

if [ ! -d mosaics ]; then
    mkdir mosaics
else
    rm -rf mosaics
    mkdir mosaics
fi

declare -a all_in_names

    for t in `cat tiles.txt`; do 
        ## some of this stuff needs to be edited - j, f, datatype
        i=($(ls -f ${in_dir} | grep "${in_stem}.${t}" | grep $suff | grep -v .hdr)) 
        #echo $i

        ## option to add the header
        # add a esri header to each binary file
        if [ "$head_flag" -eq "1" ]; then
            j=`echo $i | cut -d"." -f2`
            k=`echo $i | cut -d"." -f3`
            h=`echo $k | cut -c2-3`
            v=`echo $k | cut -c5-6`
            ulx=`echo "scale=9; $ulx_map + ($h * $pix * $dim)" | bc`
            uly=`echo "scale=9; $uly_map - ($v * $pix * $dim)" | bc`

cat -v > $j.$k.hdr << finish
ENVI description = { prior tile $k }
samples = $dim
lines = $dim
bands = $nbands
header offset = 0
file type = ENVI Standard
data type = $dtype
interleave = bsq
byte order = 0
map info = {Sinusoidal, 1, 1, $ulx, $uly, $pix, $pix}
coordinate system string = {PROJCS["Sinusoidal",GEOGCS["GCS_unnamed ellipse",DATUM["D_unknown",SPHEROID["Unknown",6371007.181,0]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Sinusoidal"],PARAMETER["central_meridian",0],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["Meter",1]]}
band names = { Class Prob }
            
finish

            cp ${in_dir}/$i $j.$k.bsq
            all_in_names+=( "$j.${k}.bsq" )

    else
            all_in_names+=( "${in_dir}/$i" )

    fi  ## end if head flag

done  ## done all tiles


for(( b=0; b<$nbands; b++ )); do

    cur_band=$(( b+1 ))

    declare -a cur_names
    count=0
    for t in `cat tiles.txt`; do 
        j=${all_in_names[${count}]}
        count=$(( count+1 ))

        temp_out_file="./mosaics/${in_stem}.${t}.${cur_band}.tif"
        if [ ! -f $temp_out_file ]; then
            echo gdal_translate -a_srs '+proj=sinu +a=6371007.181 +b=6371007.181 +units=m' -b $cur_band $j $temp_out_file 
            gdal_translate -a_srs '+proj=sinu +a=6371007.181 +b=6371007.181 +units=m' -b $cur_band $j $temp_out_file 
        else
            echo $temp_out_file already exists
        fi

        if [ -f $temp_out_file ]; then
            cur_names+=( "$temp_out_file" )
        fi 
    done
    out_file="./${in_stem}.${cur_band}.tif"
    out_geog="./${in_stem}.${cur_band}.geog.bsq"
    # merge the data into one big mosaic
    echo gdal_merge.py -o $out_file -ot $out_type ${cur_names[@]}
    gdal_merge.py -o $out_file -ot $out_type ${cur_names[@]}

    ## reproject into geographic bsq
    echo gdalwarp -of "ENVI" -t_srs 'EPSG:4326' -tr 0.004166667 -0.004166667 $out_file $out_geog
    gdalwarp -of "ENVI" -t_srs 'EPSG:4326' -tr 0.004166667 -0.004166667 $out_file $out_geog

    unset cur_names
done  ## done bands

unset all_in_files

#if [ -d mosaics ]; then
#    rm -rf mosaics
#fi

