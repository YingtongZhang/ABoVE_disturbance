# This script extracts delta tc metrics of points shp from the raster to the csv
rm(list=ls())

# load raster packages
library(rgdal)
library(raster)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
out_dir = "/projectnb/landsat/users/zhangyt/above/post_processing/validation/stratafication/samples/"
shp_loc = out_dir%+%"samples_all_points_0nan.shp"
shp_name = "samples_all_points_0nan"

# read the shapefile
pts_df = readOGR(shp_loc, shp_name, stringsAsFactors = F)
# set an array to save the values
npix = length(pts_df[1])
print(npix)
out_tab = array(NA,dim=c(npix,4))
col_names = array(NA, dim=1)
out_tab[,1] = c(pts_df[['ID']])  

#get tile list, 164 in total; ak 52, ca 112
csv_file = "/usr3/graduate/zhangyt/Desktop/ABoVE/bash/tiles_ak.txt"
tile_list <-  read.csv(csv_file, header=F, sep=",")
tile_name = as.character(tile_list[,1])

year_s <- 2000
lc.files <- list()
strata.files <- list()
lc_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp_5c/remap/"
strata_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/remap/"
# strata_dir = "/projectnb/landsat/users/zhangyt/above/CCDC/"%+%tile_name%+%"/"

for (j in seq_along(strata_dir)){
  strata.files[[j]] <- dir(strata_dir[j],"strata_0nan.tif$")
  #strata.files[[j]] <- dir(strata_dir[j],"stacked_5c*")
  strata.files[[j]] <- paste0(strata_dir[j], strata.files[[j]])
  strata_ras <- raster(strata.files[[j]])
  extract_value <- extract(strata_ras, pts_df)

  for (i in 1:1900){
    if (is.na(extract_value[i]) == F){
      out_tab[i,4] = extract_value[i]
    }
  }
}

for(year in year_s:2012){
  for (j in seq_along(lc_dir)){
    lc.files[[j]] <- dir(lc_dir[j],"_cl_5c.tif$")
    lc.files[[j]] <- paste0(lc_dir[j], lc.files[[j]])
    lc.files[[j]] <- grep(as.character(year), lc.files[[j]], value = T)
    lc_ras <- raster(lc.files[[j]])
    extract_value <- extract(lc_ras, pts_df)
  
    for (i in 1:1900){
      if (is.na(extract_value[i]) == F){
        if (is.na(out_tab[i,2]) == T){
          #out_tab[i,2] = extract_value[i]
          out_tab[i, 2] = year
        }
        else{
          #out_tab[i,3] = extract_value[i]
          out_tab[i, 3] = year
        }
      }
    }
  }
  print(year)
}


#get tile list, 164 in total; ak 52, ca 112
csv_file = "/usr3/graduate/zhangyt/Desktop/ABoVE/bash/tiles_ca.txt"
tile_list <-  read.csv(csv_file, header=F, sep=",")
tile_name = as.character(tile_list[,1])

year_s <- 1987
lc.files <- list()
strata.files <- list()
lc_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_pp_5c/remap/"
strata_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/validation/remap/"
# strata_dir = "/projectnb/landsat/users/zhangyt/above/CCDC/"%+%tile_name%+%"/validation/"

for (j in seq_along(strata_dir)){
  strata.files[[j]] <- dir(strata_dir[j],"strata_0nan.tif$")
  #strata.files[[j]] <- dir(strata_dir[j],"stacked_5c*.")
  strata.files[[j]] <- paste0(strata_dir[j], strata.files[[j]])
  strata_ras <- raster(strata.files[[j]])
  extract_value <- extract(strata_ras, pts_df)
  
  for (i in 1:1900){
    if (is.na(extract_value[i]) == F){
      out_tab[i,4] = extract_value[i]
    }
  }
}


for(year in year_s:2012){
  for (j in seq_along(lc_dir)){
    lc.files[[j]] <- dir(lc_dir[j],"_cl_5c.tif$")
    lc.files[[j]] <- paste0(lc_dir[j], lc.files[[j]])
    lc.files[[j]] <- grep(as.character(year), lc.files[[j]], value = T)
    lc_ras <- raster(lc.files[[j]])
    extract_value <- extract(lc_ras, pts_df)
    
    for (i in 1:1900){
      if (is.na(extract_value[i]) == F){
        if (is.na(out_tab[i,2]) == T){
          out_tab[i,2] = year
        }
        else{
          out_tab[i,3] = year
        }
      }
    }
  }
  print(year)
}


out_tab_ = as.data.frame(out_tab, stringsAsFactors = F)
out_tab_ = out_tab_[order(as.numeric(out_tab_$V1)),]

out_dir_ <- '/projectnb/landsat/users/zhangyt/above/post_processing/validation/assessment/'
#strata_map <- paste0(out_dir_, 'samples_all_points_0nan.csv', sep="")
#strata <- read.csv(strata_map, header=T, sep=",")
#strata = strata[order(strata$ID),]

#out_tab_strata = cbind(out_tab_, strata$STRATUM)
colnames(out_tab_) = c('ID', 'YEAR1', 'YEAR2','STRATUM')

out_file <- paste(out_dir_%+%"map0206_new.csv")
write.csv(out_tab_, file = out_file, row.names=FALSE)

