#### R code to extract data for interpreted points from rasters

rm(list=ls())

## set relative path
setwd("/projectnb/landsat/projects/ABOVE/CCDC/Bh07v06/out_tc/")

## load raster packages - make sure have loaded R/3.4
library(rgdal)
library(raster)
#library(RcppCNPy)  # read NumPy File

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
  tile = "h07v06"
}

## destination of inputs/outputs
### these directories are relative to /projectnb/landsat/projects/ABOVE/validation/read_val_121617
out_dir = "./out_tc_csv/"
dist_loc = "./"
shp_loc = "../../../validation/make_sample_110517/val_out_110517"

## location of the shapefile
cur_stem = "val_B"%+%tile
cur_shp = shp_loc%+%"/"%+%cur_stem%+%".shp"

## read the shapefile
pts_df = readOGR(cur_shp,cur_stem) 
## shapefile point ids
all_ids = pts_df[["id"]]

######## extract TC and nbr ############
### setting up params like the number of layers and metrics 
#extract_names = c("db","dg","dw")
# num_mets = 3 
# num_layers = num_mets + 4
num_layers = 3
tile_h = as.numeric(substr(tile,2,3))
tile_v = as.numeric(substr(tile,5,6))

## sets up a table to hold the values we are going to extract from each layer for each year
# year from 1985 to 2013, 29 years in total
num_years = 29
npix = length(pts_df[[1]])
ncol = 4 + num_layers * num_years * 2          # write both the break numbers and years
out_tab_tc = array(NA,dim = c(npix,ncol))
## first two columns have a pixel id and 1-npix
out_tab_tc[,c(1:2)] = c(pts_df[["pix"]],pts_df[["id"]])
out_tab_tc[,c(3:4)] = c(rep(tile_h,npix),rep(tile_v,npix))


## read in the year of dist layer
file_list <- dir(path=dist_loc, pattern='.tif')
file_len <- length(file_list)
for (n in 1:file_len) {
  #cur_file = dist_loc%+%"/B"%+%tile%+%".tc_dates.tif"
  cur_file = file_list[n]
  for (i in 1:3) {                   # read the db, dg, dw
    out_tab_tc[,c(4*n+1)] <- 
    if(file.exists(cur_file)) {
      ## load file as raster
      cur_ras = raster(cur_file,band=i)
      ## extract the raster for those points
      out_tab_tc[,c(i*n+4)] <- extract(cur_ras,pts_df)
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
    out_tab_tc[,(i+7)] <- extract(cur_ras,pts_df)
  } else {
    print("No in file found "%+%cur_file)
  }
}

}






#############
### write the nbr results
## write out the colummn names
colnames(out_tab) = c("id","pix","tile_h","tile_v","date","num_dist",
                      "dnbr","pnbr","devi2","pevi2","p_swir1","rmse","num_brks")
#save out to file - format as a csv
out_file = out_dir%+%"val_"%+%tile%+%".csv"
write.table(out_tab,file=out_file,sep=",",col.names=T,row.names=F,quote=F)

### write the TC results
colnames(out_tab_tc) = c("id","pix","tile_h","tile_v","date_b","date_g","date_w",
                         "db","pb","dg","pg","dw","pw")
#save out to file - format as a csv
out_file_tc = out_dir%+%"val_tc_"%+%tile%+%".csv"
write.table(out_tab_tc,file=out_file_tc,sep=",",col.names=T,row.names=F,quote=F)



