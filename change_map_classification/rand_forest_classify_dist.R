# Random forest classification for forest to non-forest
# most recent training data version -- 0731

rm(list=ls())

library(randomForest)
library(rgdal)
library(raster)
"%+%" <- function(x,y) paste(x,y,sep="")
#tile_name = 'Bh04v04'
args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
train_csv_path_FN = "/projectnb/landsat/users/zhangyt/above/training_data/0731/0731_training_all_FN.csv"
train_csv_path_NN = "/projectnb/landsat/users/zhangyt/above/training_data/0731/0731_training_all_NN.csv"
#img_dir = "/projectnb/landsat/users/shijuan/above/bh09v15/rand_forest_v4/FN/"
#output_dir = "/projectnb/landsat/users/zhangyt/above/out_class_sample/"%+%tile_name%+%"/out_category/"
img_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_tc_4type"
output_dir = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map/out_category/"
#dir.create(output_dir)

agent_train_FN <- read.csv(file=train_csv_path_FN,header=T,colClasses=c(agent="character"))
agent_train_FN <- agent_train_FN[complete.cases(agent_train_FN),]
agent_rf_FN <- randomForest(factor(agent) ~ db + dg + dw + pb + pg + pw, data=agent_train_FN)

agent_train_NN <- read.csv(file=train_csv_path_NN,header=T,colClasses=c(agent="character"))
agent_train_NN <- agent_train_NN[complete.cases(agent_train_NN),]
agent_rf_NN <- randomForest(factor(agent) ~ db + dg + dw + pb + pg + pw, data=agent_train_NN)


img_files <- list.files(path=img_dir,pattern="*.tif$",all.files=T,full.names=T)

for(file in img_files){
  type = strsplit(file,'[_]')[[1]][6]
  if(type=='FN'){
    print(file)
    img <- brick(file)
    names(img) <- c('db', 'dg', 'dw','pb', 'pg', 'pw')
    preds_rf <- predict(img, model=agent_rf_FN, na.rm=T)
    file_name = strsplit(basename(file),'[.]')[[1]]
    new_name = paste0(file_name[1],'_rf.tif')
    output_path = paste0(output_dir,new_name)
    print(output_path)
    writeRaster(preds_rf, filename=output_path,format='GTiff',overwrite=TRUE)
  }
  if(type=='NN'){
    print(file)
    img <- brick(file)
    names(img) <- c('db', 'dg', 'dw','pb', 'pg', 'pw')
    preds_rf <- predict(img, model=agent_rf_NN, na.rm=T)
    file_name = strsplit(basename(file),'[.]')[[1]]
    new_name = paste0(file_name[1],'_rf.tif')
    output_path = paste0(output_dir,new_name)
    print(output_path)
    writeRaster(preds_rf, filename=output_path,format='GTiff',overwrite=TRUE)
  }
}

