# This script reorganize the csv data sheets. 
rm(list=ls())

library(rgdal)
library(raster)

# read the path
# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
# args <- commandArgs(trailingOnly=TRUE)
# tile_name <- args[1]
tile_name <- "Bh11v12"
tc_csv_path = "/projectnb/landsat/users/zhangyt/above/training_data/0731/ply/0731_training_"%+%tile_name%+%"_NN.csv"
out_csv_path = "/projectnb/landsat/users/zhangyt/above/training_data/0731/ply/"%+%tile_name%+%"_NN.csv"
shp_loc = "/projectnb/landsat/users/zhangyt/above/training_data/0731/ply/NN/" # can also be a directory
shp_name = tile_name%+%"_ply_NN" # no .shp

# read the shapefile
polygon_df = readOGR(shp_loc, shp_name)
polygon_data = as.matrix(polygon_df@data)

tc_df <- read.csv(file = tc_csv_path, header=TRUE, sep=",",stringsAsFactors=FALSE)
#interpt_df <- read.csv(file = tc_csv_path, header=TRUE, sep=",",stringsAsFactors=FALSE)

n_pix = nrow(tc_df)

out_tab = array(NA,dim = c(n_pix, 10))
colnames(out_tab) = c("shp_id","dis_year","agent","ag_label","db","dg","dw","bb","bg","bw")

# reorder by Pix_ID
# tc_df <- tc_df[order(tc_df[,'pix']),]
out_tab[,'shp_id'] <- tc_df[,'pix']

# get disturbance year
for(i in 1:n_pix){
  index <- which(out_tab[i,1] == polygon_data[,'shp_id'])
  if(!is.na(polygon_data[index, "agent"])){
    out_tab[i,"agent"] <- polygon_data[index, "agent"]
    out_tab[i,"ag_label"] <- polygon_data[index, "ag_label"]
    out_tab[i,'dis_year'] <- polygon_data[index, "year"]
    #out_tab[i,'dis_year'] = substr(dis_time, start=4, stop=7)
    
    dist_year <- as.numeric(polygon_data[index, "year"])
    n <- dist_year - 1985
    
    #if(!is.na(tc_df[i,6*j-4])){
    #dis_time <- colnames(tc_df[6*j-4])
    out_tab[i,'db'] = tc_df[i, 6*n-4]
    out_tab[i,'dg'] = tc_df[i, 6*n-3]
    out_tab[i,'dw'] = tc_df[i, 6*n-2]
    out_tab[i,'bb'] = tc_df[i, 6*n-1]
    out_tab[i,'bg'] = tc_df[i, 6*n]
    out_tab[i,'bw'] = tc_df[i, 6*n+1]   
  }
  else{
    next
  }

}

# get db, dg, dw
# tc_colname = colnames(tc_df)
# num_col = length(tc_df[1,])
# for(j in 1:n_pix){
#   for(k in 1:num_col){
#     tc_year = substr(tc_colname[k],start=4, stop=7)
#     if(identical(toString(out_tab[j,'dis_year']), tc_year)){
#       #print(tc_colname[k])
#       dtc = substr(tc_colname[k],start=1, stop=2)
#       if(dtc=='db'){
#         out_tab[j,'db'] = tc_df[j,tc_colname[k]]
#         out_tab[j,'bb'] = tc_df[j,tc_colname[k+3]]
#       }
#       if(dtc=='dg'){
#         out_tab[j,'dg'] = tc_df[j,tc_colname[k]]
#         out_tab[j,'bg'] = tc_df[j,tc_colname[k+3]]
#       }
#       if(dtc=='dw'){
#         out_tab[j,'dw'] = tc_df[j,tc_colname[k]]
#         out_tab[j,'bw'] = tc_df[j,tc_colname[k+3]]
#       }
#     }
#   }
# }
write.table(out_tab,file=out_csv_path,sep=",",col.names=T,row.names=F,quote=F)
