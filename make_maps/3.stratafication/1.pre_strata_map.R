##### prepare the map for the stratafication map #####
### step0: stacked 5c ready; buffer mask ready
### step1: 17 cl map stack (to one map)
### step2: FF decline mask
#### step3: NNfire to NNother
### step4: NNother in/near Fire mask
rm(list=ls())

library(rgdal)
library(raster)
library(stringi)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
'%ni%' <- Negate('%in%')
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
#tile_name <- "Bh10v06"

cl_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_classes/"
pp_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp/remap/"
pp_5c_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/remap/"
#pp_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp/"
#pp_5c_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/"
output_dir = pp_5c_dir

b_id <- 1    # ca -- 1987-2012
#b_id <- 16     # ak -- 2000-2012
##b_id <- 28 
e_id <- 26
num_year <- e_id - b_id + 1
total_layers <- num_year*6  


######################### step 1 #########################
pp_list <- list.files(pp_dir, pattern="*.tif$", full.names=T) #29
pp_ras <- stack(pp_list[b_id:e_id])
pp_mat <- as.matrix(pp_ras)

#5c
# class_enum <- c(1,2,3,4,5)
#17c
class_enum <- c(1:18)
pp_mat[pp_mat %ni% class_enum] <- 0
pp_mat[pp_mat %in% class_enum] <- 1
pp_mat[is.na(pp_mat)] <- 0

sum_mat <- as.matrix(rowSums(pp_mat, dims=1))
sum_mat[sum_mat != 0] <- 1
sum_mat[sum_mat == 0] <- NA
sum_mat <- matrix(sum_mat, nrow = 6000, byrow = TRUE)

output_map = raster(sum_mat)
extent(output_map) <- extent(pp_ras)
crs(output_map) <- crs(pp_ras)

output_path = paste0(output_dir, tile_name, "_stacked_17c.tif", sep="")
writeRaster(output_map, filename=output_path, format='GTiff', overwrite=TRUE, NAflag = -127, datatype = "INT2S",options=c("COMPRESS=LZW","NUM_THREADS=ALL_CPUS"))


######################### step 2&3 ########################
#before post-processing
cl_list <- list.files(cl_dir, pattern="*.tif$", full.names=T)
#after post-proccessing
pp_list <- list.files(pp_dir, pattern="*.tif$", full.names=T)

pp_5c_file = list.files(pp_5c_dir, pattern="*5c.tif$", full.names=T)
pp_5c_mask = raster(pp_5c_file)

# make FF decline mask
for (i in b_id:e_id){
  year <- i + 1986
  #s2 part
  dist_mask <- raster(pp_list[i])
  dist_mask[dist_mask > 1] <- NA   # extract FFdecline

  #s3 part
  #NNfire_bf <- raster(cl_list[i])
  NNfire_bf <- raster(cl_list[i+2])
  NNothr_af <- raster(pp_list[i])
  print(cl_list[i+2])
  print(pp_list[i])
  # get the map of NN fire before post-processing
  NNfire_bf[NNfire_bf != 8] <- NA
  # get the map of NN oters after post_processing
  NNothr_af[NNothr_af < 9] <- NA
  NNothr_af[NNothr_af > 9] <- 9
  # use the overlap zone as the mask
  change_mask <- NNfire_bf + NNothr_af
  change_mask[!is.na(change_mask)] <- 1

  if (i == b_id){
    #s2
    stacked_raster = dist_mask
    stacked_raster[is.na(stacked_raster)] <- 0

    #s3
    stacked_raster_ = change_mask
    stacked_raster_[is.na(stacked_raster_)] = 0
  }
  else{
    dist_mask[is.na(dist_mask)] <- 0
    stacked_raster = stacked_raster + dist_mask

    change_mask[is.na(change_mask)] <- 0
    stacked_raster_ = stacked_raster_ + change_mask
  }
  print(i)

}
FF_wo_dist <- mask(stacked_raster, pp_5c_mask, maskvalue=NA, inverse=T)
FF_wo_dist[FF_wo_dist == 0] <- NA
change_wo_dist <- mask(stacked_raster_, pp_5c_mask, maskvalue=NA, inverse=T)
change_wo_dist[change_wo_dist == 0] <- NA

output_path = paste0(output_dir, tile_name,"_FFdecline.tif", sep="")
writeRaster(FF_wo_dist, filename=output_path, format='GTiff', overwrite=TRUE, NAflag = -127, datatype = "INT2S",options=c("COMPRESS=LZW","NUM_THREADS=ALL_CPUS"))
output_path = paste0(output_dir, tile_name,"_NNf2o.tif", sep="")
writeRaster(change_wo_dist, filename=output_path, format='GTiff', overwrite=TRUE, NAflag = -127, datatype = "INT2S",options=c("COMPRESS=LZW","NUM_THREADS=ALL_CPUS"))

######################### step 4 #########################

#python code

