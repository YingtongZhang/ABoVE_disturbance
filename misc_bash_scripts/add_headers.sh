#! /bin/bash 
#$ -pe omp 1

out_dir="./"

uly_map=10007554.677
ulx_map=-20015109.354
lry_map=-10007554.677
lrx_map=20015109.354
pix=463.312716525
dim=2400
input="file_name"

## get list of tiles
for t in `cat tiles.txt`;
do

	for (( y=2001 ; y<2005 ; y++ ))
	do

		for (( d=1 ; d<=46 ; d++ ))
		do
			# add a esri header to each binary file
			temp_name=${input}.${t}.${y}.${d}.hdr
			echo $temp_name
			## for geographic info - might not need this part
			h=`echo $t | cut -c2-3`
			v=`echo $t | cut -c5-6`
			ulx=`echo "scale=9; $ulx_map + ($h * $pix * $dim)" | bc`
			uly=`echo "scale=9; $uly_map - ($v * $pix * $dim)" | bc`
## doesnt like indents or comments inside the cat statement
cat -v > $temp_name << finish
ENVI description = { tile $t date ${y}-${d} }
samples = $dim
lines = $dim
bands = 1
header offset = 0
file type = ENVI Standard
data type = 3
interleave = bsq
byte order = 0
map info = {Sinusoidal, 1, 1, $ulx, $uly, $pix, $pix}
coordinate system string = {PROJCS["Sinusoidal",GEOGCS["GCS_unnamed ellipse",DATUM["D_unknown",SPHEROID["Unknown",6371007.181,0]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Sinusoidal"],PARAMETER["central_meridian",0],PARAMETER["false_easting",0],PARAMETER["false_northing",0],UNIT["Meter",1]]}
band names = { EVI2 }
finish

		done
	done
done

