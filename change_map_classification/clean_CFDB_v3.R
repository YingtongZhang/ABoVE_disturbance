## this script is to do the post-classification according to discussion with Curtis
## the most different part from "clean_s1/2" is we're going to use Canadian fire database here
#  should process without changing the land cover types
## 1.FN fire  2.FN insects  3.FN logging  19.FN others
## 4.FF growth  5.FF decline 
## 6.NF growth  
## 7-15.NN dw&dg 20.NN fire
## WHAT IS NEW HERE: 1)using landcover maps, specifically wetland class to deal with the NN fire commission
## 2)the exact number may raise concern, so change them right away
## 3)change the fire database as four year window

rm(list=ls())

library(rgdal)
library(raster)
library(spatial.tools)

# function to abbrevaite paste
"%+%" <- function(x,y) paste(x,y,sep="")
'%ni%' <- Negate('%in%')
# args <- commandArgs(trailingOnly=TRUE)
# tile_name <- args[1]
tile_name <- "Bh13v15"

# Canadian Fire Database is used first to two branches
CFDB_dir = "/projectnb/modislc/projects/above/tiles/CAN_LFDB/"
map_dir = "/projectnb/landsat/users/shijuan/above/out_class_sample/"%+%tile_name%+%"/out_classes/"
out_dir = "/projectnb/landsat/users/shijuan/above/out_class_sample/"%+%tile_name%+%"/out_classes/clean_v5.1/"
lc_dir = "/projectnb/modislc/users/jonwang/data/rf/rast/tc_20180416_noGeo_k55_pam_rf/"%+%tile_name%+%"/old_remap/"

map_name <- paste0(map_dir, "Bh13v15_FF_FN_NF_NN_2002_cl.tif")
fire_map_name <- paste0(CFDB_dir, "CAN_LFDB."%+%tile_name%+%".tif")
x <- raster(map_name)
fire <- raster(fire_map_name)

## the year number
map_year <- as.numeric(substr(map_name, 97, 100))
fireyear <- map_year - 1792
fire_beg <- fireyear - 2
fire_end <- fireyear + 1


#################### ADD part ######################
#### change the NN fire to NN others on wetland ####
#################### ADD part ######################
fire_temp <- fire
fire_temp[fire_temp %ni% c(fire_beg:fire_end)] <- NA
 
x_temp <- x
x_firein <- x_temp
x_fireout <- x_temp
##fire in the fire map or not
fire_test <- mask(fire_temp, x_temp, maskvalue=NA, inverse=F)
x_firein <- mask(x_temp, fire_test, maskvalue=NA, inverse=F)      #fire for sure
x_fireout <- mask(x_temp, x_firein, maskvalue=NA, inverse=T)

# land cover
LC <- stack(paste(lc_dir, tile_name, '_', as.character(map_year-1), '_tc_20180416_noGeo_k55_pam_rf_remap.tif', sep=""))
LC[LC < 11] <- NA
LC[LC > 13] <- NA  

# the breaks on the wetlands, then need to change NN fires to others
# but should keep the NNfire in fire database ********
x_change <- mask(x_fireout, LC)
x_keep <- mask(x_fireout, LC, inverse=T)
x_change[x_change == 20] <- 21

x_change[is.na(x_change)] <- 0
x_keep[is.na(x_keep)] <- 0
x_firein[is.na(x_firein)] <- 0
x_ori <- overlay(x_change, x_keep, x_firein, fun=function(x,y,z){return(x+y+z)})
x_ori[x_ori == 0] <- NA

##save the files
output_ori = paste(out_dir, tile_name, '_', as.character(map_year), '_', "x_ori_new", ".tif", sep="")
writeRaster(x_ori, output_ori, format="GTiff", overwrite=TRUE)
############################################# Add part end ################################################






#### PART1: split to four classes ####
x_FN <- x_ori
x_FN[x_FN %ni% c(1,2,3,19,20)] <- NA
x_FF <- x_ori
x_FF[x_FF %ni% c(4,5)] <- NA
x_NF <- x_ori
x_NF[x_NF %ni% c(6)] <- NA
x_NN <- x_ori
x_NN[x_NN %ni% c(7:15)] <- NA


#### PART2: processing each class ####
#####################################################
# step1: seperate the FIRE events from the database #
#####################################################

######## FN ############
####### FIRE ###########
x_temp <- x_FN
x_temp[x_temp %ni% c(1, 20)] <- NA

x_firein <- x_temp
x_fireout <- x_temp
##fire in the fire map or not
fire_test = mask(fire_temp,x_temp,maskvalue=NA,inverse=F)
x_firein = mask(x_temp,fire_test,maskvalue=NA,inverse=F)      ###### fire for sure -- include FN&NN fire ####
x_fireout = mask(x_temp,x_firein,maskvalue=NA,inverse=T)
##save the files
output_fire1 = paste(out_dir, "2002_firein",".tif", sep="")
writeRaster(x_firein, output_fire1, format="GTiff", overwrite=TRUE)
output_fire2 = paste(out_dir, "2002_fireout",".tif", sep="")
writeRaster(x_fireout, output_fire2, format="GTiff", overwrite=TRUE)

###################################################
# step2: process the filter for different changes #
###################################################
###########  1. remove isolated pixels  ###########
x_rest <- mask(x_FN, x_firein, maskvalue=NA, inverse=T)  #except in-database fire
x_rest[x_rest == 20] <- NA
d <- 3
c <- 1
fun.remiso.out <- function(x){
  i <- ceiling(d*d/2)
  if (is.na(x[i]) == T){
    return(NA)
  } 
  ## change the isolated fire pixels
  else if (x[i] == c){
    len_1 <- sum(x%in%x[i])
    len_2 <- sum(x%in%20)
    if ((len_1 == 1) & (len_2 == 0)){
      return(19)
    }
    else{
      return(x[i])
    }
  }
  else {
    return(x[i])
  }
}
# deal with the isolated fire at first
y_r1 <- focal(x_rest, matrix(1,d,d), fun.remiso.out, pad = TRUE, padValue = NA)

########### 2. the majority of changes ###########
# fire, insects, logging and others out of database
d <- 9
fun.majr <- function(x){
  i <- ceiling(d*d/2)
  ## NA
  if (is.na(x[i]) == T){
    return(NA)
  }
  ## not NA
  else{
    maj_class_1 <- as.numeric(names(which.max(table(x)))) #find the majority 
    len_1 <- sum(x%in%maj_class_1)     #count the number
    x[x == maj_class_1] <- NA
    maj_class_2 <- as.numeric(names(which.max(table(x)))) #find the majority 
    len_2 <- sum(x%in%maj_class_2)     #count the number
    bigger_class <- max(maj_class_1, maj_class_2)
    if (len_1 != len_2){
      return(maj_class_1)
    }
    else{
      if (maj_class_1 == 1){
        return(maj_class_1)
      }
      else if (maj_class_2 == 1){
        return(maj_class_2)
      }
      else{
        return(bigger_class)
      }
    }
  }
  
}
y_r2 <- focal(y_r1, matrix(1,d,d), fun.majr, pad = TRUE, padValue = NA)

# add firein and fireout after processing
y_r2_temp <- y_r2
x_firein[x_firein == 20] <- NA
x_o1_temp <- x_firein
y_r2_temp[is.na(y_r2_temp)] <- 0
x_o1_temp[is.na(x_o1_temp)] <- 0
x_comb_FN <- overlay(y_r2_temp, x_o1_temp, fun=function(x,y){return(x+y)})
x_comb_FN[x_comb_FN == 0] <- NA

output_fire = paste(out_dir, "2002_FN_F",".tif", sep="")
writeRaster(x_comb_FN, output_fire, format="GTiff", overwrite=TRUE)







########### FN ############
######### insect ##########
# temp_dir = "/projectnb/landsat/users/zhangyt/above/out_class_sample/"%+%tile_name%+%"/out_classes/clean_v5/"
# temp_name <- paste0(temp_dir, "2002_FN_F.tif")
# x_comb_FN <- raster(temp_name)
x_temp <- x_comb_FN

x_FNin <- x_temp
x_FNout <- x_temp
##FN in the fire map or not
fire_test = mask(fire_temp,x_temp,maskvalue=NA,inverse=F)
x_FNin = mask(x_temp,fire_test,maskvalue=NA,inverse=F)      #fire for sure
x_FNout = mask(x_temp,x_FNin,maskvalue=NA,inverse=T)
##save the files
output_fire1 = paste(out_dir, "2002_FNin",".tif", sep="")
writeRaster(x_FNin, output_fire1, format="GTiff", overwrite=TRUE)
output_fire2 = paste(out_dir, "2002_FNout",".tif", sep="")
writeRaster(x_FNout, output_fire2, format="GTiff", overwrite=TRUE)

###################################################
# step2: process the filter for different changes #
###################################################
###########  1. remove isolated pixels  ###########
d <- 3
c <- 2

# deal with the isolated insect at first
fun.remiso.firein <- function(x){
  i <- ceiling(d*d/2)
  if (is.na(x[i]) == T){
    return(NA)
  } 
  ## change the isolated fire pixels
  else if (x[i] == c){
    len <- sum(x%in%x[i])
    if (len <= 1){
      return(1)
    }
    else{
      return(x[i])
    }
  }
  else {
    return(x[i])
  }
}
fun.remiso <- function(x){
  i <- ceiling(d*d/2)
  if (is.na(x[i]) == T){
    return(NA)
  } 
  ## change the isolated fire pixels
  else if (x[i] == c){
    len <- sum(x%in%x[i])
    if (len <= 1){
      return(19)
    }
    else{
      return(x[i])
    }
  }
  else {
    return(x[i])
  }
}
x_r1 <- focal(x_FNin, matrix(1,d,d), fun.remiso.firein, pad = TRUE, padValue = NA)
y_r1 <- focal(x_FNout, matrix(1,d,d), fun.remiso, pad = TRUE, padValue = NA)

########### 2. the majority of changes ###########
# just insects
d <- 11

fun.majr <- function(x){
  i <- ceiling(d*d/2)
  ## NA
  if (is.na(x[i]) == T){
    return(NA)
  }
  ## not NA
  else{
    maj_class_1 <- as.numeric(names(which.max(table(x)))) #find the majority 
    len_1 <- sum(x%in%maj_class_1)     #count the number
    x[x == maj_class_1] <- NA
    maj_class_2 <- as.numeric(names(which.max(table(x)))) #find the majority 
    len_2 <- sum(x%in%maj_class_2)     #count the number
    bigger_class <- max(maj_class_1, maj_class_2)
    if (len_1 != len_2){
      return(maj_class_1)
    }
    else{
      if (maj_class_1 == 1){
        return(maj_class_1)
      }
      else if (maj_class_2 == 1){
        return(maj_class_2)
      }
      else{
        return(bigger_class)
      }
    }
  }
  
}
fun.majr.insect <- function(x){
  i <- ceiling(d*d/2)
  ## NA
  if (is.na(x[i]) == T){
    return(NA)
  }
  ## not NA
  else if (x[i] == 2){
    len_na <- sum(is.na(x))
    maj_class_1 <- as.numeric(names(which.max(table(x)))) #find the majority 
    len_1 <- sum(x%in%maj_class_1)     #count the number
    if ((len_na > len_1)&(len_1 != 0)){
      return(19)
    }
    else{
      return(maj_class_1)
    }
  }
  else{
    return(x[i])
  }
}
x_r2 <- focal(x_r1, matrix(1,d,d), fun.majr, pad = TRUE, padValue = NA)
x_r3 <- focal(x_r2, matrix(1,d,d), fun.majr, pad = TRUE, padValue = NA)
d <- 5
y_r2 <- focal(y_r1, matrix(1,d,d), fun.majr.insect, pad = TRUE, padValue = NA)

# overlay firein and fireout after processing
x_r3_temp <- x_r3
y_r2_temp <- y_r2
x_r3_temp[is.na(x_r3_temp)] <- 0
y_r2_temp[is.na(y_r2_temp)] <- 0
x_comb_FN <- overlay(x_r3_temp, y_r2_temp, fun=function(x,y){return(x+y)})
x_comb_FN[x_comb_FN == 0] <- NA

output_fire = paste(out_dir, "2002_FN_FI",".tif", sep="")
writeRaster(x_comb_FN, output_fire, format="GTiff", overwrite=TRUE)







########### FN ############
######## logging ##########
x_temp <- x_comb_FN

x_FNin <- x_temp
x_FNout <- x_temp
##FN in the fire map or not
fire_test = mask(fire_temp,x_temp,maskvalue=NA,inverse=F)
x_FNin = mask(x_temp,fire_test,maskvalue=NA,inverse=F)      #fire for sure
x_FNout = mask(x_temp,x_FNin,maskvalue=NA,inverse=T)
##save the files
output_fire1 = paste(out_dir, "2002_FN_FIin",".tif", sep="")
writeRaster(x_FNin, output_fire1, format="GTiff", overwrite=TRUE)
output_fire2 = paste(out_dir, "2002_FN_FIout",".tif", sep="")
writeRaster(x_FNout, output_fire2, format="GTiff", overwrite=TRUE)

###################################################
# step2: process the filter for different changes #
###################################################
###########  1. remove isolated pixels  ###########
# x_r1 <- modify_raster_margins(x=x_FNin, extent_delta=c(2,2,2,2),value = NA)
# y_r1 <- modify_raster_margins(x=x_FNout, extent_delta=c(2,2,2,2),value = NA)
d <- 3
c <- 3

# deal with the isolated logging at first
x_r1 <- focal(x_FNin, matrix(1,d,d), fun.remiso.firein, pad = TRUE, padValue = NA)
y_r1 <- focal(x_FNout, matrix(1,d,d), fun.remiso, pad = TRUE, padValue = NA)

########### 2. the majority of changes ###########
# logging
d <- 5
x_r2 <- focal(x_r1, matrix(1,d,d), fun.majr, pad = TRUE, padValue = NA)
d <- 11
fun.majr.logging <- function(x){
  i <- ceiling(d*d/2)
  ## NA
  if (is.na(x[i]) == T){
    return(NA)
  }
  ## not NA
  else if (x[i] == 1){
    len_na <- sum(is.na(x))
    len <- sum(x%in%3)
    if ((len_na > 60)&(len > 0)){
      return(3)
    }
    else{
      return(x[i])
    }
  }
  else{
    return(x[i])
  } 
}
y_r2 <- focal(y_r1, matrix(1,d,d), fun.majr.logging, pad = TRUE, padValue = NA)

# add firein and fireout after processing
# x_r3_temp <- modify_raster_margins(x=x_r3, extent_delta=c(-2,-2,-2,-2),value = NA)
# y_r3_temp <- modify_raster_margins(x=y_r3, extent_delta=c(-2,-2,-2,-2),value = NA)
x_r2_temp <- x_r2
y_r2_temp <- y_r2
x_r2_temp[is.na(x_r2_temp)] <- 0
y_r2_temp[is.na(y_r2_temp)] <- 0
x_comb_FN <- overlay(x_r2_temp, y_r2_temp, fun=function(x,y){return(x+y)})
x_comb_FN[x_comb_FN == 0] <- NA

output_fire = paste(out_dir, "2002_FN_FIL",".tif", sep="")
writeRaster(x_comb_FN, output_fire, format="GTiff", overwrite=TRUE)

x_FN_final <- x_comb_FN






######## NN ############
####### FIRE ###########

###################################################
# step2: process the filter for different changes #
###################################################
###########  1. remove isolated pixels  ###########
d <- 3
c <- 20

fun.remiso.NN <- function(x){
  i <- ceiling(d*d/2)
  if (is.na(x[i]) == T){
    return(NA)
  } 
  ## change the isolated fire pixels
  else if (x[i] == c){
    len_1 <- sum(x%in%x[i])
    len_2 <- sum(x%in%1)
    if ((len_1 == 1) & (len_2 == 0)){
      return(21)
    }
    else{
      return(x[i])
    }
  }
  else {
    return(x[i])
  }
}
# deal with the isolated fire at first
x_r1 <- focal(x_firein, matrix(1,d,d), fun.remiso.NN, pad = TRUE, padValue = NA)
y_r1 <- focal(x_fireout, matrix(1,d,d), fun.remiso.NN, pad = TRUE, padValue = NA)

########### 2. the majority of changes ###########
# fire
d <- 11
fun.majr.NN <- function(x){
  i <- ceiling(d*d/2)
  ## NA
  if (is.na(x[i]) == T){
    return(NA)
  }
  ## not NA
  else if (x[i] == 20){
    len_a <- sum(x%in%x[i])
    a <- 1
    len_b <- sum(x%in%a)
    len <- (len_a + len_b)
    if (len < 60){
      return(21)
    }
    else{
      return(x[i])
    }
  }
  else{
    return(x[i])
  } 
}
y_r2 <- focal(y_r1, matrix(1,d,d), fun.majr.NN, pad = TRUE, padValue = NA)

x_r1[x_r1 == 1] <- NA
y_r2[y_r2 == 1] <- NA
# add firein and fireout after processing
x_r1_temp <- x_r1
y_r2_temp <- y_r2
x_r1_temp[is.na(x_r1_temp)] <- 0
y_r2_temp[is.na(y_r2_temp)] <- 0
x_NN[is.na(x_NN)] <- 0

x_comb_NN <- overlay(x_r1_temp, y_r2_temp, x_NN, fun=function(x,y,z){return(x+y+z)})
x_comb_NN[x_comb_FN == 0] <- NA

output_fire = paste(out_dir, "2002_NN_FC",".tif", sep="")
writeRaster(x_comb_NN, output_fire, format="GTiff", overwrite=TRUE)

x_NN_final <- x_comb_NN


# write the final output
x_FN_final[is.na(x_FN_final)] <- 0
x_NN_final[is.na(x_NN_final)] <- 0
x_FF[is.na(x_FF)] <- 0
x_NF[is.na(x_NF)] <- 0
x_FF_FN_NF_NN <- overlay(x_FF, x_FN_final, x_NF, x_NN_final, fun=function(x,y,z,t){return(x+y+z+t)})
x_FF_FN_NF_NN[x_FF_FN_NF_NN == 0] <- NA

output_file = paste(out_dir, "2002_FF_FN_NF_NN_ppv2",".tif", sep="")
writeRaster(x_FF_FN_NF_NN, output_file, format="GTiff", overwrite=TRUE)

