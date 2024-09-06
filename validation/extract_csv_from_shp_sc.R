#### R code to extract data for interpreted points from rasters

rm(list=ls())

## load raster packages - make sure have loaded R/3.4
library(rgdal)
library(raster)

## function to abbreviate paste
"%+%" <- function(x,y) paste(x,y,sep="")
###############################################
# read in the data
# read in the arguments
args = commandArgs(trailingOnly=T)

## check to debug
debug_flag = 1
if(debug_flag==0) {
  tile = args[1]
} else {
  ## takes tile id without the B in front of h##v##
  tile = "h04v06"
}

## destination of inputs/outputs
# set working directory for relative path
setwd("/projectnb/landsat/users/shijuan/above/bh04v06_tc")

### these directories are all relative to /projectnb/landsat/projects/ABOVE/validation/read_val_121617
out_dir = "./out_tc_csv/"
#dist_loc = "/projectnb/modislc/projects/C2C_change_year"
dist_loc = "./h04v06_val"
shp_loc = "./make_sample_110517"

## location of the shapefile
cur_stem = "val_B"%+%tile
cur_shp = shp_loc%+%"/"%+%cur_stem%+%".shp"

## read the shapefile
pts_df = readOGR(cur_shp,cur_stem) 
## shapefile point ids
all_ids = pts_df[["id"]]

### setting up params like the number of layers and metrics 
#extract_names = c("dates","num","num_brks","dnbr","pnbr")
num_mets = 9
num_layers = num_mets + 4
tile_h = as.numeric(substr(tile,2,3))
tile_v = as.numeric(substr(tile,5,6))

## sets up a table to hold the values we are going to extract from each layer
npix = length(pts_df[[1]])
out_tab = array(NA,dim=c(npix,num_layers))
## first two columns have a pixel id and 1-npix
out_tab[,c(1:2)] = c(pts_df[["pix"]],pts_df[["id"]])
out_tab[,c(3:4)] = c(rep(tile_h,npix),rep(tile_v,npix))

## read in the year of dist layer
cur_file = dist_loc%+%"/B"%+%tile%+%".dates.tif"
if(file.exists(cur_file)) {
  ## load file as raster
  cur_ras = raster(cur_file)
  ## extract the raster for those points
  out_tab[,5] <- extract(cur_ras,pts_df)
} else {
  print("No in file found "%+%cur_file)
}

## repeat process for each metric in the metric file
cur_file = dist_loc%+%"/B"%+%tile%+%".dist_mets.tif"
for(i in 1:8) {
  
  ## read in the dist mets 
  if(file.exists(cur_file)) {
    cur_ras = raster(cur_file,band=i)
    out_tab[,(i+5)] <- extract(cur_ras,pts_df)
  } else {
    print("No in file found "%+%cur_file)
  }
}
## write out the colummn names
colnames(out_tab) = c("id","pix","tile_h","tile_v","date","num_dist",
                      "dnbr","pnbr","devi2","pevi2","p_swir1","rmse","num_brks")
#save out to file - format as a csv
out_file = out_dir%+%"val_"%+%tile%+%".csv"
write.table(out_tab,file=out_file,sep=",",col.names=T,row.names=F,quote=F)

# --------------------- write TC results--------------------------------#

### setting up params like the number of layers and metrics 
#extract_names = c("dates","num","num_brks","dnbr","pnbr")
num_mets = 9
num_layers = num_mets + 4
tile_h = as.numeric(substr(tile,2,3))
tile_v = as.numeric(substr(tile,5,6))

## sets up a table to hold the values we are going to extract from each layer
npix = length(pts_df[[1]])
out_tab = array(NA,dim=c(npix,num_layers))
## first two columns have a pixel id and 1-npix
out_tab[,c(1:2)] = c(pts_df[["pix"]],pts_df[["id"]])
out_tab[,c(3:4)] = c(rep(tile_h,npix),rep(tile_v,npix))

## read in the year of dist layer
cur_file = dist_loc%+%"/B"%+%tile%+%".tc_dates.tif"
for(i in 1:3){
  if(file.exists(cur_file)) {
    ## load file as raster
    cur_ras = raster(cur_file,band=i)
    ## extract the raster for those points
    out_tab[,i+4] <- extract(cur_ras,pts_df)
  } else {
    print("No in file found "%+%cur_file)
  }
}

## repeat process for each metric in the metric file
cur_file = dist_loc%+%"/B"%+%tile%+%".tc_dist_mets.tif"
for(i in 1:6) {
  
  ## read in the dist mets 
  if(file.exists(cur_file)) {
    cur_ras = raster(cur_file,band=i)
    out_tab[,(i+7)] <- extract(cur_ras,pts_df)
  } else {
    print("No in file found "%+%cur_file)
  }
}
## write out the colummn names
colnames(out_tab) = c("id","pix","tile_h","tile_v","b_date","g_date","w_date",
                      "db","pb","dg","pg","dw","pw")
#save out to file - format as a csv
out_file = out_dir%+%"val_tc_"%+%tile%+%".csv"
write.table(out_tab,file=out_file,sep=",",col.names=T,row.names=F,quote=F)

