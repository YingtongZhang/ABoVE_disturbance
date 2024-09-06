## R script to read in the CCDC results and extract out the GLAS data for training RF

library("rgdal")
library("raster")
library("randomForest")
library("snow")
#v214_lib_loc = "/usr2/faculty/dsm/R/x86_64-unknown-linux-gnu-library/2.14"
#library(randomForest,lib.loc=v214_lib_loc)
#library(snow,lib.loc=v214_lib_loc)

make_ras <- function(cur_dat,tile) {
  ulx=-1403190
  uly=1177680
  pix=30
  dim=6000
  
  cur_tile_x = as.numeric(substr(tile,2,3))
  cur_tile_y = as.numeric(substr(tile,5,6))
  
  ulx_map= ulx + (cur_tile_x * pix * dim)
  uly_map= uly - (cur_tile_y * pix * dim)
  
  lrx_map= ulx + ((cur_tile_x+1) * pix * dim)
  lry_map= uly - ((cur_tile_y+1) * pix * dim)
  
  xy = matrix(cur_dat,nrow=dim,ncol=dim,byrow=T)
  # Turn the matrix into a raster
  rast <- raster(xy)
  # Give it x/y coords
  extent(rast) <- c(ulx_map,lrx_map,lry_map,uly_map)
  out_proj =  '+proj=aea +lat_1=14.5 +lat_2=32.5 +lat_0=24 +lon_0=-105 +x_0=0 +y_0=0 +ellps=GRS80 +units=m'
  
  # ... and assign a projection
  projection(rast) <- CRS(out_proj)
  
  return(rast)
}


get_clim_dat <- function(clim_loc,cur_pix) {
  
  npix = length(cur_pix)
  clim_mets = 21
  clim_dat = array(NA,dim=c(npix,clim_mets))
  
  #  print(paste("Reading in",clim_file))
    for(i in 1:clim_mets)
    {
        clim_file = paste(clim_loc,"/",tile,".clim.",i,".tif",sep="")
        if(file.exists(clim_file)) {
            clim_dat[,i] = as.vector(raster(clim_file,band=1))[cur_pix]
        } else {
            print(paste("No climate file found. Expecting:",clim_file))
        }
    }

  na_ind = clim_dat == 32767
  clim_dat[na_ind]=NA
      
  return(clim_dat)
}

## actually use the monthly data as metrics
get_mon_dat <- function(in_loc, cur_pix, y) {
  
  num_pix = length(cur_pix)

  ## ignore the last two metrics
  nmon = 4
  nband = 7
  out_mets = nmon*nband
  out_dat = array(NA,dim=c(num_pix,out_mets))
  out_mons = c(3,6,9,12)
  ## these are the months we will extract
  for(n in 1:nmon) {
      in_file = paste(in_loc,"/pred_mon_",y,"_",out_mons[n],".tif",sep="")
      if(file.exists(in_file)) {
            print(paste("reading in ",in_file))
            for(b in 1:nband) {
                cur_dat = as.vector(raster(in_file,band=b))
                i = ((n-1)*nband) + b
                out_dat[,i] = cur_dat[cur_pix]
            }
        } else {
            print(paste("file not found ",in_file))
        }
    } 

  return(out_dat)
}


## when we have texture measures
get_text_dat <- function(text_loc,in_tile,year,cur_pix) {
  cur_stems = c("b3.m4","b3.m9","b4.m4","b4.m9","b5.m4","b5.m9")
  num_files = length(cur_stems)

  npix = length(cur_pix)
  text_dat = array(NA,dim=c(npix,num_files))
  ## each input has 4 layers 
  ## we are only going to take the 4th but for each band and two dates
  year = as.numeric(year)
  colnames(text_dat) = cur_stems
  for(i in 1:num_files) 
  {
    in_file = paste(text_loc,"/text.",in_tile,".",cur_stems[i],".tif",sep="")
 #   print(paste("Reading in",in_file))
    if(file.exists(in_file)) {
        ## could have another loop to read additional bands
         text_dat[,i] = as.vector(raster(in_file,band=4))[cur_pix]
    } else {
      print(paste("File",in_file,"does not exist."))
    }
  }  ## end i
  
  return(text_dat)
} ## end function


## put rmse dat into the model - each file has 6 bands
get_rmse_dat <- function(rmse_file,cur_pix) {
  
  out_bands = 6
  rmse_dat = array(NA,dim=c(length(cur_pix),out_bands))
  if(file.exists(rmse_file)) {
    for(i in 1:out_bands) {
      
 #       print(paste("Reading in",rmse_file,"for band",i))
        rmse_dat[,i] = as.vector(raster(rmse_file,band=i))[cur_pix]
    }
  } else {
    print(paste("No RMSE file found. Expecting:",rmse_file))
  }
  
  return(rmse_dat)
}
#### START MAIN

args = commandArgs(trailingOnly=T)
year = args[1]
tile = args[2]
rf_file = args[3]
model_name = args[4]
out_stem = args[5]

in_loc = "../../all_ccdc_mets"
out_loc = "./outputs_pred"
rmse_loc = paste("../../run_tilez/ccdc_",tile,"/rmse_",tile,sep="")
mon_loc = paste("../../run_tilez/ccdc_",tile,"/mon_preds_",tile,sep="")
text_loc = paste("../../other_input_data/texture_tiled/tiled_2005",sep="")
clim_loc = "../../other_input_data/mex_clim/outputs_clim"

out_name = paste(out_loc,"/pred.",out_stem,".",tile,".",year,".tif",sep="")
dim_x=6000
dim_y=6000
num_mets = 36
npix = dim_x*dim_y

if(!file.exists(out_name)) {

    load(rf_file)
    ## this gives us a bio.rf object
    #cur_rf = rf_stclim
    ## read in the model name 
    cur_rf = eval(as.name(model_name))
    #cur_rf = rf_st_text_rmse

    nchunks=8
    interval = npix/nchunks
    all_preds = NULL
    ## loop through row chunks of the input/output
    for(n in 1:nchunks) {
        start_pix = ((n-1)*interval) + 1
        end_pix = n*interval
        cur_pix = seq(start_pix,end_pix)
        
        st_mets = array(NA,dim=c(interval,num_mets))
        for(i in 1:num_mets) {
          in_file = paste(in_loc,"/outputs_",tile,"/ann_mets.",year,".",i,".tif",sep="")
      #    print(paste("Reading in",in_file))
          if(file.exists(in_file)) {
              st_mets[,i] = as.vector(raster(in_file))[cur_pix]
          } else {
            print(paste("File",in_file,"does not exist."))
          }
        }
        
        ## order will go st, text, rmse, clim
        #cur_text = get_text_dat(text_loc,tile,2000,cur_pix)

        rmse_file = paste(rmse_loc,"/rmse_",year,".tif",sep="")
        #cur_rmse = get_rmse_dat(rmse_file,cur_pix)

        cur_clim = get_clim_dat(clim_loc,cur_pix)
        cur_mon = get_mon_dat(mon_loc,cur_pix,year)
        
       # all_dat = as.data.frame(cbind(st_mets,cur_text,cur_rmse))
        starts = c(1,8,15,22)
        ends = c(7,14,21,28)
     
        if(out_stem == "stclim") {
           
            all_dat = as.data.frame(cbind(st_mets,cur_clim))
        } 

        if(out_stem == "st") {
           
            all_dat = as.data.frame(st_mets)
        } 
        
        if(out_stem == "2date") {
                       
            all_dat = as.data.frame(cbind(cur_mon[,starts[2]:ends[2]],cur_mon[,starts[4]:ends[4]]))
        } 

        if(out_stem == "sep") {
           
            all_dat = as.data.frame(cur_mon[,starts[3]:ends[3]])
        }   

        if(out_stem == "mul") {
           
            all_dat = as.data.frame(cur_mon)
        }   
        
        ## get the names from the rf object
        all_names = unlist(attr(cur_rf$terms,"term.labels"))
        colnames(all_dat) = all_names
      
        preds_rf = predict(cur_rf, newdata=all_dat)

        all_preds = c(all_preds,preds_rf)
    }  ## end for loop

    all_preds[is.na(all_preds)] = -1
    #temp = predict(bio.rf, newdata=as.data.frame(ras_dat), type="response",filename=out_name,overwrite=T,format="GTiff",datatype='INT2S')
    cur_ras = make_ras(all_preds,tile)
    writeRaster(cur_ras,filename=out_name,NAflag=-1)
}
