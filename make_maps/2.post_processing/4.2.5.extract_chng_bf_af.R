# This script extracts delta tc metrics of points shp from the raster to the csv

rm(list=ls())

# load raster packages
library(rgdal)
library(raster)

"%+%" <- function(x,y) paste(x,y,sep="")
root = "/projectnb/landsat/users/zhangyt/above/post_processing/pp_validation"
# shp_file = file.path(root, "temp.shp")
# shp_name = "temp"
shp_file = file.path(root, "temp.shp")
shp_name = "temp"

pts_df = readOGR(shp_file, shp_name, stringsAsFactors = F)
pts_df_prj = spTransform(pts_df, CRS("+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs"))
npix = length(pts_df_prj[1])
print(npix)
out_tab = array(NA,dim=c(npix,4))
out_tab[,1] = c(pts_df_prj$ID)
out_tab[,2] = c(pts_df_prj$YEAR)
out_tab[(out_tab[,2] < 1987 | out_tab[,2] > 2012), 2] <- 0
pts_df_prj_sub = subset(pts_df_prj, YEAR > 1986)
out_tab <- out_tab[out_tab[,2] != 0, ]

TILE_ALL = "/usr3/graduate/zhangyt/Desktop/ABoVE/bash/tiles_all.txt"
tile_list <-  read.csv(TILE_ALL, header=F, sep=",")
tile_name = as.character(tile_list[,1])

cl.files <- list()
cl_dir <- "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_classes/"
pp.files <- list()
pp_dir <- "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp/remap/"

len <- nrow(out_tab)
for (i in 1:len){
  year = out_tab[i,2]
  
  for (j in seq_along(cl_dir)){
    cl.files[[j]] <- paste0(cl_dir[j], dir(cl_dir[j], "_FF_FN_NF_NN_"%+%year%+%"_cl.tif$"))
    #print(cl.files[[j]])
    cl_ras <- raster(cl.files[[j]])
    extract_cl <- extract(cl_ras, pts_df_prj_sub)
    
    if (!is.na(extract_cl[i])){
      pp.files[[j]] <- paste0(pp_dir[j], dir(pp_dir[j], "_FF_FN_NF_NN_"%+%year%+%"_cl_pp.tif$"))
      pp_ras <- raster(pp.files[[j]])
      extract_pp <- extract(pp_ras, pts_df_prj_sub)
      
      out_tab[i,3] = extract_cl[i]
      out_tab[i,4] = extract_pp[i]
      
      break
    }
    
  }
  print(i)
}



# for (j in seq_along(cl_dir)){
#   
#   cl.files[[j]] <- paste0(cl_dir[j], dir(cl_dir[j], "_FF_FN_NF_NN_"%+%year%+%"_cl.tif$"))
#   print(cl.files[[j]])
#   cl_ras <- raster(cl.files[[j]])
#   extract_cl <- extract(cl_ras, pts_df_prj_sub)
#   
#   pp.files[[j]] <- paste0(pp_dir[j], dir(pp_dir[j], "_FF_FN_NF_NN_"%+%year%+%"_cl_pp.tif$"))
#   pp_ras <- raster(pp.files[[j]])
#   extract_pp <- extract(pp_ras, pts_df_prj_sub)
#   
#   for (i in 1:nrow(out_tab)){
#     if (!is.na(extract_cl[i])){
#       out_tab[i,3] = extract_cl[i]
#       out_tab[i,4] = extract_pp[i]
#     }
#   }
#   
#   print(j)
# }




out_file <- file.path(root, "new_map", "output_add.csv")
write.csv(out_tab, file = out_file)

