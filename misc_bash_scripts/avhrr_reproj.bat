#!/bin/bash

for t in `ls -f outputs_envi | grep bsq`;
do
name=`echo $t | cut -c1-6`
gdal_translate -projwin -180 90 0 30 outputs_envi/$t clipped.tif
gdalwarp -t_srs '+proj=laea +lat_0=50 +lon_0=-100 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs' -tr 8000 -8000 -srcnodata -10000 -dstnodata -9999 -r bilinear -overwrite clipped.tif ../reproj_laea/$name.tif
echo Created file ../reproj_laea/$name.tif

done
