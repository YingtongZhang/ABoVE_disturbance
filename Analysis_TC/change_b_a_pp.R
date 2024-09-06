# making the matrix to see the pixels changed before and after the post-processing
## 1.FN fire  2.FN insects  3.FN logging  19.FN others
## 4.FF growth  5.FF decline 
## 6.NF growth  
## 7-15.NN dw&dg 20.NN fire 21. NN - to be classified(not fire)

rm(list=ls())

library(rgdal)
library(raster)
#library(caret)

#function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
'%ni%' <- Negate('%in%')
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
#tile_name <- "Bh13v15"

clmap_dir_b = "/projectnb/landsat/users/zhangyt/above/out_class_sample/"%+%tile_name%+%"/out_classes/"
#clmap_dir_b = "/projectnb/landsat/users/shijuan/above/out_class_hold/"%+%tile_name%+%"/"
clmap_dir_a = "/projectnb/landsat/users/zhangyt/above/out_class_sample/"%+%tile_name%+%"/out_classes/clean_v6.0/"
#clmap_dir_a = "/projectnb/landsat/users/shijuan/above/post_process/smooth_v4/"%+%tile_name%+%"/"
out_dir = "/projectnb/landsat/users/zhangyt/above/out_class_sample/Bh13v15/out_classes/results/pixel_change_pp/"


#initialize the matrix
conf_mat = matrix(0, nrow=6, ncol=6)

for (n in 1:26){
  year = n + 1985
  
  map_before <- paste0(clmap_dir_b%+%tile_name%+%"_FF_FN_NF_NN_", as.character(year), "_cl.tif")
  map_after <- paste0(clmap_dir_a%+%tile_name%+%"_FF_FN_NF_NN_", as.character(year), "_cl_11_sm_v4.tif")
  
  pix_b <- as.matrix(raster(map_before))
  pix_a <- as.matrix(raster(map_after))
  
  pix_b[is.na(pix_b)] <- 0
  pix_b[pix_b %in% c(7:15)] <- 21
  pix_b[pix_b %ni% c(1,2,3,19,20,21)] <- 0
  pix_a[is.na(pix_a)] <- 0
  pix_a[pix_a %in% c(7:15)] <- 21
  pix_a[pix_a %ni% c(1,2,3,19,20,21)] <- 0
  
  #confusion matrix for each year
  dif_table <- table(pix_b, pix_a)
  #results <- confusionMatrix(pix_b, pix_a)
  new_table <- dif_table[2:nrow(dif_table), 2:ncol(dif_table)]    #remove the no change statistics
  new_table_pct <- round(new_table/sum(new_table) * 100, 2)       #calculate the percentage of changed pixels
  
  output_table1 = paste0(out_dir, "cmatrix_", as.character(year), "_ppchg.csv")
  write.table(new_table, output_table1, sep= " ")
  output_table2 = paste0(out_dir, "cmatrix_", as.character(year), "_ppchg_pct.csv")
  write.table(new_table_pct, output_table2, sep= " ")
  
  #add matrices across 30 years
  conf_mat <- conf_mat + new_table

  print(n)
}

#percentage of changed and stable pixels across 30 years
conf_mat_pct <- round(conf_mat/sum(conf_mat) * 100, 2)

output_table = paste0(out_dir, "cmatrix_all_year_ppchg.csv")
write.table(conf_mat, output_table, sep= " ")
output_table_ = paste0(out_dir, "cmatrix_all_year_ppchg_pc.csv")
write.table(conf_mat_pct, output_table_, sep= " ")






