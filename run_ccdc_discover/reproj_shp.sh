#! /bin/csh 
#$ -pe omp 1
#$ -l h_rt=12:00:00

# last modified 2/21/13 by Damien Sulla-Menashe  #
# purpose of code is to reproject a shapefile into avhrr proj

set in_shp = "/projectnb/modislc/users/dsm/avhrr_landsat_compare/canada_fire/NFDB_poly_20130322.shp"
set out_shp = "./NFDB_above.shp"


# the source projection should already be set. otherwise this will produce an error
# note the output is listed before the input
ogr2ogr -overwrite -preserve_fid -t_srs '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs' -progress $out_shp $in_shp 
