#### R code to mask the non-forest area according to LC map for H13V15

setwd("/projectnb/landsat/projects/ABOVE/CCDC/Bh09v15/out_tc")

## load raster packages
library(rgdal)
library(raster)

# get Landsat data
# MultiSptr <- brick('Bh13v15_dTC_1995.tif')


# read all years change map (delta Tasseled Cap)
## band1: brightness  -- useless for now
## band2: greenness
## band3: wetness
ras_list <- list.files("/projectnb/landsat/projects/ABOVE/CCDC/Bh09v15/out_tc",pattern="*.tif$", full.names=T) # 29 files in total
all_layers = stack(ras_list)   # 29*3 layers, arranged by b,g,w across the year

# read 1985 LC map
LC <- stack('/projectnb/landsat/users/shijuan/above/bh09v15/LCmap/Bh09v15_1985_tc_20180219_k25_mn_sub_pam_rf_remap.tif')

LC[LC > 3] <- NA

TC_forest <- mask(all_layers, LC)

year = 1984
for (i in 1:29){
  year = year + 1
  filename = paste("/projectnb/landsat/projects/ABOVE/CCDC/Bh09v15/out_tc_Forest/","Bh09v15_dTC_F_",as.character(year),".tif",sep="")
  current_stack = subset(TC_forest,(3*i-2):(3*i))
  writeRaster(current_stack,filename,format="GTiff", overwrite=TRUE)  
} 
