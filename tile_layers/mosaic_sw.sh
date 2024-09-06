#! /bin/csh 
#$ -pe omp 1
#$ -l h_rt=48:00:00

# last modified 1/24/12 by Damien Sulla-Menashe

# merge the data into one big mosaic
gdal_merge.py -of ENVI -o eosd_tot.bsq *.tif
# reproject to lat long
#gdalwarp -s_srs '+proj=sinu +a=6371007.181 +b=6371007.181 +units=m' -t_srs 'EPSG:4326' -r near -overwrite temp.bsq $outdir/2007-2010.IGBP1.15arc-second.tif

