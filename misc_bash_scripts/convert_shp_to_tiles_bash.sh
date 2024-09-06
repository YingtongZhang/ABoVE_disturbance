#! /bin/bash 
#$ -pe omp 1
#$ -l h_rt=48:00:00

# last modified 10/26/15 by Damien Sulla-Menashe

# sets the grid coordinates
uly_map=10007554.677
ulx_map=-20015109.354
lry_map=-10007554.677
lrx_map=20015109.354
pix=463.312716525
dim=2400

#ogr2ogr -s_srs 'EPSG:4326' -t_srs '+proj=sinu +a=6371007.181 +b=6371007.181 +units=m' wwf_terr_ecos_sin.shp wwf_terr_ecos.shp

## you will need to set this according to what the country code layer is called
layer_name="wwf_terr_ecos_sin"
fid="BIOME"
# this will be the filename of the input
in_shp="./${layer_name}.shp"
# this will be the filename of the output
out_stem="./modis_tiles/biome"

# add a esri header to each binary file
for t in `cat tiles.txt`;
do
h=`echo $t | cut -c2-3`
v=`echo $t | cut -c5-6`
ulx=`echo "scale=9; $ulx_map + ($h * $pix * $dim)" | bc`
uly=`echo "scale=9; $uly_map - ($v * $pix * $dim)" | bc`
lrx=`echo "scale=9; $ulx_map + (($h+1) * $pix * $dim)" | bc`
lry=`echo "scale=9; $uly_map - (($v+1) * $pix * $dim)" | bc`

# have the upper left corner for all corners - test this on a single $i before letting it loop
gdal_rasterize -l $layer_name -a $fid -a_nodata -9999 -of ENVI -ot Int16 -tr $pix $pix -ts $dim $dim -te $ulx $lry $lrx $uly $in_shp $out_stem.$t.bip

done

