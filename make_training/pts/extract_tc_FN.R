# This script extracts delta tc metrics of points shp from the raster to the csv

rm(list=ls())

# load raster packages
library(rgdal)
library(raster)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")

#tile_name = "Bh12v10"
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
out_dir = "/projectnb/landsat/users/shijuan/above/training_data/0725_training/FN/"
tc_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/out_tc_4type/"
shp_loc = "/projectnb/landsat/users/shijuan/above/training_data/0725_training/FN/"%+%tile_name%+%"_pts_FN.shp"
shp_name = tile_name%+%"_pts_FN" # no .shp

#out_dir = "/projectnb/landsat/users/shijuan/above/bh09v15/rand_forest_v3/"
#tc_dir = "/projectnb/landsat/projects/ABOVE/CCDC/Bh09v15/out_tc_pre/"
#shp_loc = "/projectnb/landsat/users/shijuan/above/bh09v15/rand_forest_v3/training_sample.shp" # can also be a directory
#shp_name = "training_sample"
#tile_name = 'Bh09v15'
# read the shapefile
pts_df = readOGR(shp_loc, shp_name)
#print(pts_df)

# set an array to save the values
npix = length(pts_df[1])
print(npix)
n_mets = 6 # delta b,g,w pre-d,g,w, and agent
out_tab = array(NA,dim=c(npix,n_mets*29+1))
col_names = array(NA, dim=c(n_mets*29+1))
out_tab[,c(1:1)] = c(pts_df[['shp_id']])  # if polygon, cannot do it this way

for(year in 1986:2013){
  tc_year = tc_dir%+%tile_name%+%"_dTC_FN_"%+%toString(year)%+%".tif"
  print(tc_year)
  n = year - 1985
  # extract delta brightness
  col_names[6*n-4] = "db_"%+%toString(year)
  db_ras = raster(tc_year,band=1)
  out_tab[,c(6*n-4)] <- extract(db_ras,pts_df)
  
  # extract delta greenness
  col_names[6*n-3] = "dg_"%+%toString(year)
  dg_ras = raster(tc_year,band=2)
  out_tab[,c(6*n-3)] <- extract(dg_ras,pts_df)
  
  # extract delta wetness
  col_names[6*n-2] = "dw_"%+%toString(year)
  dw_ras = raster(tc_year,band=3)
  out_tab[,c(6*n-2)] <- extract(dw_ras,pts_df)
  
  # extract pre- brightness
  col_names[6*n-1] = "pb_"%+%toString(year)
  db_ras = raster(tc_year,band=4)
  out_tab[,c(6*n-1)] <- extract(db_ras,pts_df)
  
  # extract pre- greenness
  col_names[6*n] = "pg_"%+%toString(year)
  dg_ras = raster(tc_year,band=5)
  out_tab[,c(6*n)] <- extract(dg_ras,pts_df)
  
  # extract pre wetness
  col_names[6*n+1] = "pw_"%+%toString(year)
  dw_ras = raster(tc_year,band=6)
  out_tab[,c(6*n+1)] <- extract(dw_ras,pts_df)
}
col_names[1] = "shp_id"
colnames(out_tab) = col_names
out_file = out_dir%+%tile_name%+%"_tc_FN.csv"
write.table(out_tab, file=out_file,sep=",",col.names=T,row.names=F, quote=F)


