rm(list=ls())

#install.packages("gdalUtils", repos = 'http://cran.us.r-project.org')
library(gdalUtils)
library(rgdal)
library(raster)

"%+%" <- function(x,y) paste(x,y,sep="")
out_dir = "/projectnb/landsat/users/zhangyt/above/merge_5c_0206_clip/"

#get tile list, 164 in total
csv_file = "/usr3/graduate/zhangyt/Desktop/ABoVE/bash/tiles_all.txt"
tile_list <-  read.csv(csv_file, header=F, sep=",")
tile_name = as.character(tile_list[,1])
pp_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp_5c/remap/"
    
st_id = 8
end_id = 26
# pp.files <- list()
# 
# for(i in st_id:end_id){
#   year = 1985 + i
#   for (j in seq_along(pp_dir)){
#     pp.files[[j]] <- dir(pp_dir[j],"\\.tif$")
#     pp.files[[j]] <- grep(as.character(year), pp.files[[j]], value = T)
#     pp.files[[j]] <- paste0(pp_dir[j], pp.files[[j]])
#     print(j)
#   }
#   out_merge <- paste0(out_dir, "above_out_pp_5c_merge_"%+%year%+%".tif")
#   #out_merge <- paste0(out_dir, "s2_"%+%year%+%"_cl_5c.tif")
# 
#   mosaic_rasters(gdalfile = unlist(pp.files),
#                  dst_dataset = out_merge,
#                  srcnodata = "-32767",
#                  dstnodata = "0",
#                  force_ot = "Int16",co = list("COMPRESS=LZW","TILED=YES"),
#                  verbose=T
#                  )
# }
  
# clip to the boarder
shp_dir <- "/projectnb/landsat/users/zhangyt/above/data/shapefile/ABoVE_reference_grid_v2_1527/data/ABoVE_Study_Domain/ABoVE_Core_Domain.shp"
ori_dir <- "/projectnb/landsat/users/zhangyt/above/merge_5c_0206/"


crop_extent <- readOGR(dsn=shp_dir, layer="ABoVE_Core_Domain")

for(i in st_id:end_id){
  year = 1986 + i
  ori_file <- paste0(ori_dir, "above_out_pp_5c_merge_"%+%year%+%".tif")
  out_clip <- paste0(out_dir, "above_out_pp_5c_clip_"%+%year%+%".tif")
  
  gdalwarp(srcfile = ori_file,
           dstfile = out_clip,
           dstnodata = "0",
           cutline = shp_dir, crop_to_cutline = T,
           of = "GTiff",
           ot = "Byte", co = list("COMPRESS=LZW","TILED=YES"),
           verbose=T,
           overwrite = T
           )
}


#rm(list=ls())
#
##install.packages("gdalUtils", repos = 'http://cran.us.r-project.org')
#library(gdalUtils)
#library(rgdal)
#library(raster)
#
#"%+%" <- function(x,y) paste(x,y,sep="")
#out_dir = "/projectnb/landsat/users/zhangyt/above/merge_all_year/"
#
#csv_file = "/usr3/graduate/zhangyt/Desktop/ABoVE/bash/tiles_all.txt"
#tile_list <-  read.csv(csv_file, header=F, sep=",")
#tile_name = as.character(tile_list[,1])
#pp_dir = "/projectnb/landsat/users/zhangyt/above/CCDC/"%+%tile_name%+%"/out_map_year/"
#
#pp.files <- list()
#
#for (j in seq_along(pp_dir)){
#  pp.files[[j]] <- dir(pp_dir[j],"_FNinsect.tif$")
#  pp.files[[j]] <- paste0(pp_dir[j], pp.files[[j]])
#  print(j)
#}
#
#out_merge <- paste0(out_dir, "merge_FNinsect_allyears.tif")
#
#mosaic_rasters(gdalfile = unlist(pp.files),
#               dst_dataset = out_merge,
#               srcnodata = "-32767",
#               dstnodata = "0",
#               force_ot = "UInt16",co = list("COMPRESS=LZW","TILED=YES"),
#               verbose=T
#)





