# This script extracts delta tc metrics of polygon shp from the raster to the csv (through whole time series)
rm(list=ls())

# load raster packages
library(rgdal)
library(raster)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
out_dir = "/projectnb/landsat/users/zhangyt/above/training_data/0731/ply/"
tc_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/out_tc_pre/"
shp_loc = "/projectnb/landsat/users/zhangyt/above/training_data/0731/ply/NN/" # can also be a directory
shp_name = tile_name%+%"_ply_NN"

# read the shapefile
ploygon_df = readOGR(shp_loc, shp_name,stringsAsFactors = F)
# set an array to save the values
npl = length(ploygon_df[1])
print(npl)
n_mets = 6
col_names = array(NA, dim = c(n_mets * 28 + 1))
# out_tab = array(NA, dim = c(1, 1))

for(year in 1986:2013){
  tc_year = tc_dir%+%tile_name%+%"_dTC_"%+%toString(year)%+%".tif"
  n = year - 1985
  
  for (ipls in 1:npl){
    current_poly = ploygon_df[ipls,]
    
    if (year==1986){
      # extract delta brightness
      db_ras = raster(tc_year, band=1)
      temp_tab <- extract(db_ras, current_poly)
      # define the output table
      current_len <- length(temp_tab[[1]])
      out_tab = array(NA, dim = c(current_len, n_mets+1))
      out_tab[, 1] = c(ploygon_df[['shp_id']][ipls])
      
      # write to the matrix
      out_tab[, 2] <- unlist(temp_tab)
      col_names[6*n-4] = "db_"%+%toString(year)
      
      
      # extract delta greenness
      dg_ras = raster(tc_year, band=2)
      temp_tab <- extract(dg_ras, current_poly)
      # write to the matrix
      out_tab[, 3] <- unlist(temp_tab)
      col_names[6*n-3] = "dg_"%+%toString(year)
      
      
      # extract delta wetness
      dw_ras = raster(tc_year, band=3)
      temp_tab <- extract(dw_ras, current_poly)
      # write to the matrix
      out_tab[, 4] <- unlist(temp_tab)
      col_names[6*n-2] = "dw_"%+%toString(year)
      
      
      # extract pre brightness
      bb_ras = raster(tc_year, band=4)
      temp_tab <- extract(bb_ras, current_poly)    
      # write to the matrix
      out_tab[, 5] <- unlist(temp_tab)
      col_names[6*n-1] = "bb_"%+%toString(year)
      
      
      # extract pre greenness
      bg_ras = raster(tc_year, band=5)
      temp_tab <- extract(bg_ras, current_poly)    
      # write to the matrix
      out_tab[, 6] <- unlist(temp_tab)
      col_names[6*n] = "bg_"%+%toString(year)
      
      
      # extract pre wetness
      bw_ras = raster(tc_year, band=6)
      temp_tab <- extract(bw_ras, current_poly)    
      # write to the matrix
      out_tab[, 7] <- unlist(temp_tab)
      col_names[6*n+1] = "bw_"%+%toString(year)
      
      if (ipls==1){
        out_tab_csv <- out_tab
      }
      else{
         out_tab_csv <- rbind(out_tab_csv, out_tab)
      } 
      
    }
    
    else{
      # extract delta brightness
      db_ras = raster(tc_year, band=1)
      temp_tab <- extract(db_ras, current_poly)
      current_len <- length(temp_tab[[1]])
      out_tab_add = array(NA, dim = c(current_len, n_mets))
      # write to the matrix
      out_tab_add[,1] <- unlist(temp_tab)
      col_names[6*n-4] = "db_"%+%toString(year)
      
      
      # extract delta greenness
      dg_ras = raster(tc_year, band=2)
      temp_tab <- extract(dg_ras, current_poly)
      # write to the matrix
      out_tab_add[,2] <- unlist(temp_tab)
      col_names[6*n-3] = "dg_"%+%toString(year)
      
      
      # extract delta wetness
      dw_ras = raster(tc_year, band=3)
      temp_tab <- extract(dw_ras, current_poly)
      # write to the matrix
      out_tab_add[,3] <- unlist(temp_tab)
      col_names[6*n-2] = "dw_"%+%toString(year)
      
      
      # extract pre brightness
      bb_ras = raster(tc_year, band=4)
      temp_tab <- extract(bb_ras, current_poly)    
      # write to the matrix
      out_tab_add[,4] <- unlist(temp_tab)
      col_names[6*n-1] = "bb_"%+%toString(year)
      
      
      # extract pre greenness
      bg_ras = raster(tc_year, band=5)
      temp_tab <- extract(bg_ras, current_poly)    
      # write to the matrix
      out_tab_add[,5] <- unlist(temp_tab)
      col_names[6*n] = "bg_"%+%toString(year)
      
      
      # extract pre wetness
      bw_ras = raster(tc_year, band=6)
      temp_tab <- extract(bw_ras, current_poly)    
      # write to the matrix
      out_tab_add[,6] <- unlist(temp_tab)
      col_names[6*n+1] = "bw_"%+%toString(year)
  
      
      if (ipls==1){
        out_tab_csv_ <- out_tab_add
      }
      else{
        out_tab_csv_ <- rbind(out_tab_csv_, out_tab_add)
      }     
    
  }
  }
print(year)
if (year==1986){
  num_row <- nrow(out_tab_csv)
  out_csv_tmp <- array(NA, dim = c(num_row, n_mets+1))
}
else{
  print(nrow(out_csv_tmp))
  print(nrow(out_tab_csv_))
  out_csv_tmp <- cbind(out_csv_tmp, out_tab_csv_)
}
  
}

num_col <- ncol(out_csv_tmp)
print(num_col)
print(nrow(out_tab_csv))
print(nrow(out_csv_tmp))

out_csv <- out_tab_csv
out_csv <- cbind(out_csv, out_csv_tmp[,8:num_col])

col_names[1] = "pix"
colnames(out_csv) = col_names
out_file = out_dir%+%"0731_training_"%+%tile_name%+%"_NN.csv"
write.table(out_csv, file=out_file,sep=",",col.names=T,row.names=F, quote=F)
