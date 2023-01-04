# the script stacks annual 5/17 classes map to one two-value map, preparing for the stratification map
# new update is aiming to get the class number of the disturbance map
rm(list=ls())

library(rgdal)
library(raster)
library(stringi)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
'%ni%' <- Negate('%in%')
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
#tile_name <- "Bh04v04"

pp_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp_5c/remap/"
output_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/remap/"
#pp_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp_5c/"
#output_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/"

pp_list <- list.files(pp_dir, pattern="*.tif$", full.names=T) #29

#pp_ras <- stack(pp_list[14:26])
pp_ras <- stack(pp_list[1:26])  # ak -- 2000-2012 / can -- 1987-2012
min_pp_ras <- calc(pp_ras, min, na.rm=T)

# pp_mat <- as.matrix(pp_ras)
# #5c
# class_enum <- c(1,2,3,4,5)
# #17c
# #class_enum <- c(1:17)
# pp_mat[pp_mat %ni% class_enum] <- 0
# pp_mat[pp_mat %in% class_enum] <- 1
# pp_mat[is.na(pp_mat)] <- 0
# 
# sum_mat <- as.matrix(rowSums(pp_mat, dims=1))
# sum_mat[sum_mat != 0] <- 1
# sum_mat[sum_mat == 0] <- NA
# sum_mat <- matrix(sum_mat, nrow = 6000, byrow = TRUE)

# output_map = raster(sum_mat)
# extent(output_map) <- extent(pp_ras)
# crs(output_map) <- crs(pp_ras)

output_map = min_pp_ras

output_path = paste0(output_dir, tile_name,"_stacked_5c.tif", sep="")
writeRaster(output_map, filename=output_path, format='GTiff', overwrite=TRUE, NAflag = -127, datatype = "INT2S",options=c("COMPRESS=LZW","NUM_THREADS=ALL_CPUS"))
