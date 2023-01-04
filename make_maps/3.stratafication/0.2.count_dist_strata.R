rm(list=ls())

library(rgdal)
library(raster)
library(stringi)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
#tile_name <- "Bh04v04"

stacked_5c_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/remap/"
#out_dir = "/projectnb/landsat/users/zhangyt/above/post_processing/validation/stratafication/buffer/iso_count/"
out_dir = stacked_5c_dir

stacked_file <- list.files(stacked_5c_dir, pattern="*5c.tif$", full.names=T) #1
stacked_raster <- raster(stacked_file)

d <- 11
fun.remove.iso <- function(x){
  i <- ceiling(d*d/2)
  if (is.na(x[i]) == T){
    return(NA)
  } 
  else{
    nna_count <- sum(!is.na(x))
    if (nna_count < 2){
      return(NA)
    }
    else{
      return(x[i])
    }
  }
}

stacked_rmiso <- focal(stacked_raster, matrix(1,d,d), fun.remove.iso, pad = TRUE, padValue = NA)

#iso_raster <- mask(stacked_raster, stacked_rmiso, maskvalue=NA)
#iso_count <- table(as.matrix(iso_raster))
#iso_pixel_count <- iso_count["1"]

output_path = paste0(stacked_5c_dir%+%tile_name%+%"_stacked_5c_rmiso.tif")
writeRaster(stacked_rmiso, output_path, format='GTiff', overwrite=TRUE)

#file_name <- paste(out_dir%+%tile_name%+%"_iso_count.csv")
#write.csv(iso_pixel_count, file = file_name, row.names = F)
