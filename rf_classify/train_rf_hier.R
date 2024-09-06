rm(list=ls())

require(randomForest)
source("./reclass_fun.R")

###############################################
# read in the data
# read in the arguments
args = commandArgs(trailingOnly=T)

debug_flag = 0
if(debug_flag==0) {
## the step extract should be path/step_out.csv
	step_extract = args[1]
## data loc refers to where the spline outputs exist
	data_loc = args[2]
## in stem is the prefix of the spline output file
	in_stem = args[3]
## these are the years to extract spline results - should be setup in the train_rf_hier.sh file
	start_year = as.numeric(args[4])
	end_year = as.numeric(args[5])
} else {
  step_extract = "./step_out.csv"
	data_loc = "/projectnb/modislc/users/dsm/spline_codes/spline_one_v3/outputs_global"
	in_stem = "c6_str5"
	start_year = 2001
	end_year = 2003
}

#### function definitions:
## this function reads an integer image stack
read_int_file <- function(in_file, dsize, nbands, s_flag,bsq_flag) {
  
  ## get the total dimensions of file = nrow*ncol*dsize*nbands
  f_size <- file.info(in_file)$size
  ## open the file
  f <- file(in_file,"rb")
  ## dsize should be an int() 2 bytes
  tot_size <- (f_size/dsize)
  ## can deal with signed or unsigned integers

  temp <- readBin(f,integer(),n=tot_size,endian= "little",size=dsize,signed=s_flag)
  ## fill missing data
  temp[temp==32767 | temp==-32767] = NA

  close(f)
  
  ## if bsq_flag is 1 then we read by row
  ## else we read by column
   ## re-order the temp array into a matrix
   if(bsq_flag==1) { byr_flag = FALSE } else { byr_flag = TRUE }
      temp <- matrix(temp, ncol=nbands, byrow=byr_flag)
 
  return(temp)
}

## function to extract out the quantile data for the appropriate years and average them for each site/year
extract_metrics <- function(tile_ind,cur_tile) {
  
    ## for reading in quantiles
    npix=2400*2400
    ## info about the files we will read in
    ## 2 byte integers
    dsize <- 2
    ## signed integers
    s_flag <- T
    ## there are 11 bands (6 spectral and 5 indices) and 6 metrics for each year/band + one snow flag
    nbands <- (11*6) + 1
  
    ## these locations are fortunately already 0 indexed
    pix_x = step_dat[tile_ind,3]  
    pix_y = step_dat[tile_ind,4]
    ## these will be the 1-d locations of the pixels we want to extract from
    pix_loc = (pix_y*2400) + pix_x + 1
          
    ## this will have all the attributes we want for the pix we want to extract from for that tile
    temp_step = step_dat[tile_ind,]
      
    ## this will be the output from the function
    out_dat = NULL
    ### need to remove sites based on year 
    for(year in start_year:end_year) {  
        ## years that those sites are valid for
    	  year_ind = temp_step[,22] <= year & temp_step[,23] >= year
    		    
        # open the quantile file for each year and pull out the values of interest
	## for sanjeeb - this will need to be changed to find the MCD12I1 files of interest
        in_file <- paste(data_loc,"/",in_stem,".",cur_tile,".",year,".quant.bip",sep="")
        if(file.exists(in_file)) {
			        time_process = system.time( quant_dat <-  
              read_int_file(in_file, dsize, nbands, s_flag, bsq_flag = 0) )
			        print(time_process)
	      } else {
			        print(paste(in_file," not found. Filled!",sep=""))
			        quant_dat = matrix(NA,nrow=npix,ncol=nbands)
		   }
                
      ## this will have all the class_values we want for the pix we want to extract from for that tile
      ## use the NVEG scheme because it will have all of the data we need for the other schemes as well
      temp_class = class_list[["nveg"]][tile_ind]
       
      ## select pixels with a non-zero class in that scheme
      class_ind = temp_class > 0
                  
			## select the siteids for those sites
      cur_ids = temp_step[year_ind & class_ind,6]
      un_ids = unique(cur_ids)
      ## select the pixel locations for those sites
      cur_pix_loc = pix_loc[year_ind & class_ind]
                  
      ## only process this tile/year/scheme if there are some pixels
      if(length(cur_pix_loc)>1) {
              ### temp_dat is the subset of quant for those pixels of interest
              temp_dat = quant_dat[cur_pix_loc,]    	
              len_out = length(un_ids)
              num_feats = dim(quant_dat)[[2]]
              year_dat = array(NA,dim=c(len_out,num_feats))
            	for(n in 1:len_out) {
                    temp_ind = cur_ids == un_ids[n]
			if(length(cur_ids[temp_ind])>1) {
                      		year_dat[n,] = apply(temp_dat[temp_ind,],2,mean,na.rm=T)
			} else {
				 year_dat[n,] = temp_dat[temp_ind,]
			}
            	}
              ## append the current year's values to a single matrix 
            	out_dat = rbind(out_dat,year_dat)
                      
              rm(year_dat)
              rm(temp_dat)         
        }  ## if length cur_pix_loc > 0
        rm(quant_dat)
    }  ## end year loop

	return(out_dat)
}

## this function gets the class attributes to match the quantile data
get_class_dat <- function(tile_ind) {
  out_class_dat = NULL
  
  ## this will have all the attributes we want for the pix we want to extract from for that tile
  temp_step = step_dat[tile_ind,]
  ### need to remove sites based on year 
  for(year in start_year:end_year) {  
    ## years that those sites are valid for
    year_ind = temp_step[,22] <= year & temp_step[,23] >= year
    ## this will have all the class_values we want for the pix we want to extract from for that tile
    ## use the NVEG scheme because it will have all of the data we need for the other schemes as well
    temp_class = class_list[["nveg"]][tile_ind]
  
    ## select pixels with a non-zero class in that scheme
    class_ind = temp_class > 0
  
    ## select the siteids for those sites
    cur_ids = temp_step[year_ind & class_ind,6]
    un_ids = unique(cur_ids)
    len_out = length(un_ids)
    cur_class_dat = array(0,dim=c(len_out,num_schemes))
    ## only process this tile/year/scheme if there are some pixels
    if(length(cur_ids)>0) {
      for(s in 1:num_schemes) {
        temp_class = class_list[[s]][tile_ind]
        temp_class = temp_class[year_ind & class_ind]
        for(n in 1:len_out) {
          temp_ind = cur_ids == un_ids[n]
          cur_class_dat[n,s] = min(temp_class[temp_ind])
        }
      }
    }
    out_class_dat = rbind(out_class_dat,cur_class_dat)
  }  ## end year loop
    return(out_class_dat)
}

## this function gets the class attributes for urban needed to be treated specially
get_class_dat_urb <- function(tile_ind,biome_dat,num_urb) {
  out_class_dat = NULL
  
  ## this will have all the attributes we want for the pix we want to extract from for that tile
  temp_step = step_dat[tile_ind,]
  ### need to remove sites based on year 
  for(year in start_year:end_year) {  
    ## years that those sites are valid for
    year_ind = temp_step[,22] <= year & temp_step[,23] >= year
    ## this will have all the class_values we want for the pix we want to extract from for that tile
    ## use the NVEG scheme because it will have all of the data we need for the other schemes as well
    nveg_class = class_list[["nveg"]][tile_ind]
    temp_biome = biome_dat[tile_ind]
    
    ## select pixels with a non-zero class in that scheme
    class_ind = nveg_class > 0
    
    cur_class = urb_class[tile_ind]
    ## select the siteids for those sites
    cur_ids = temp_step[year_ind & class_ind,6]
    new_class = cur_class[year_ind & class_ind]
    un_ids = unique(cur_ids)
    len_out = length(un_ids)
    cur_class_dat = array(0,dim=c(len_out,num_urb))
    ## only process this tile/year/scheme if there are some pixels
    if(length(cur_ids)>0) {
      for(s in 1:num_urb) {
        urb_ind = temp_biome == s
        for(n in 1:len_out) {
          temp_ind = cur_ids == un_ids[n] & urb_ind
          if(length(new_class[temp_ind])>0) { cur_class_dat[n,s] = min(new_class[temp_ind]) }
        }
      }
    }
    out_class_dat = rbind(out_class_dat,cur_class_dat)
  }  ## end year loop
  return(out_class_dat)
}

## this function is to extract out certain attributes from step file that will match the reflectance data
get_site_info <- function(tile_ind) {
  out_site_info = NULL
  
  ## this will have all the attributes we want for the pix we want to extract from for that tile
  temp_step = step_dat[tile_ind,]
  ### need to remove sites based on year 
  for(year in start_year:end_year) {  
    ## years that those sites are valid for
    year_ind = temp_step[,22] <= year & temp_step[,23] >= year
    ## this will have all the class_values we want for the pix we want to extract from for that tile
    ## use the NVEG scheme because it will have all of the data we need for the other schemes as well
    temp_class = class_list[["nveg"]][tile_ind]
    
    ## select pixels with a non-zero class in that scheme
    class_ind = temp_class > 0
    
    ## select the siteids for those sites
    cur_ids = temp_step[year_ind & class_ind,6]
    un_ids = unique(cur_ids)
    len_out = length(un_ids)
    
    cur_class_dat = array(0,dim=c(len_out,5))
    ## only process this tile/year/scheme if there are some pixels
    if(length(cur_ids)>0) { 
      temp_dat = temp_step[year_ind & class_ind,]
      for(n in 1:len_out) {
          temp_ind = cur_ids == un_ids[n]
	    ## get the necessary class labels for this site
          cur_class_dat[n,] = cbind(min(temp_dat[temp_ind,1]),min(temp_dat[temp_ind,2]),
                              min(temp_dat[temp_ind,5]),min(temp_dat[temp_ind,6]),min(temp_dat[temp_ind,20]))
      }
    }
    out_site_info = rbind(out_site_info,cur_class_dat)
  }  ## end year loop
  return(out_site_info)
}

plot_rf_imp <- function(rf_name,scheme_names,num_schemes) {
## create a variable importance plot for each scheme we are classifying
  out_name <- paste("./var_imp_plots.",end_year,".pdf",sep="")
  pdf(out_name)
  par(mfrow=c(1, 2), mar=c(1, 4, 1, 1), oma=c(3, 1, 1, 1))

  for(s in 1:num_schemes) {
    if(!is.null(get(rf_name[s]))) {
      varImpPlot(get(rf_name[s]),main=scheme_names[s])
    }
  }

  dev.off()
}
### end function definition
######################################################
### begin main
######################################################
scheme_names = c("NVEG","VEG","LF_TYPE","SH_D","SH_S","AG","AG_MOS","H_WET","W_WET","LF_TYPE2","AG_TYPE","IGBP")
## we want the lowercase version of the scheme names
scheme_short = tolower(scheme_names)
## get the number of schemes we will use - later this can be read in from parameter file
num_schemes = length(scheme_names)

## create a list to hold the class values
class_list = vector("list",num_schemes)
## read in the step extract csv file
step_dat = read.csv(step_extract,header=F,na.strings="")
## convert the matrix with all the classes to a 1-d array of classes for each scheme
class_vals = step_dat[,7:19]
for(i in 1:num_schemes) {
  class_list[[i]] = map_classes(class_vals,scheme_short[i]) 
}
names(class_list) = scheme_short

urb_class = map_classes(class_vals,"urb")

## for urban classes - special case
biome_dat = reclass_biome(step_dat[,20])
urb_ind = urb_class==1 & biome_dat > 0
un_biome = sort(unique(biome_dat[urb_ind]))

urb_names = paste("urb",un_biome,sep="")
num_urb = length(urb_names)

## get the list of all the tiles for each pixel in the array
all_tiles = paste("h",sprintf("%02d",step_dat[,1]),"v",sprintf("%02d",step_dat[,2]),sep="")
## make another list of only the unique tiles
list_tiles = sort(unique(all_tiles))

## another optional step to read the tiles we want from another text file
## these are the tiles we are going to extract from
temp_tiles = as.character(unlist(read.csv("tiles.txt",header=F)))

## this is the output list that will be used for training the randomforests for each scheme
all_dat = NULL
class_dat = NULL
all_site_info = NULL
## now we read in the data we are interested in
for(tile in temp_tiles) {
  ## get our pixels of interest
  tile_ind = all_tiles == tile
  ## make sure there are pixels for this tile before processing
  if(length(all_tiles[tile_ind])>0) {
	  out_dat = extract_metrics(tile_ind,tile)
    all_dat = rbind(all_dat,out_dat)
    out_class = get_class_dat(tile_ind)
	  out_urb = get_class_dat_urb(tile_ind,biome_dat,num_urb)
    ## get some other site info we will use later for cross-validation
    temp_site_info = get_site_info(tile_ind)
    all_site_info = rbind(all_site_info,temp_site_info)
    class_dat = rbind(class_dat,cbind(out_class,out_urb))
  } ## end length > 0
}  ## end tile list

all_class_names = c(scheme_short,urb_names)
colnames(class_dat) = all_class_names
## create the names vectors
q_names = c("q10","q33","q50","q66","q90","sd")
b_names = c("b1","b2","b4","b5","b6","b7","evi2","ndsi","ndwi","ndii1","ndii2")

## there is an extra feature of a snow count after all the values
nfeat = dim(all_dat)[[2]]
all_names = NULL
for(b in 1:length(b_names)) {
  all_names = c(all_names,paste(b_names[b],q_names,sep="_"))
}
all_names[nfeat] = "snow_count"

all_dat = as.data.frame(all_dat)
colnames(all_dat) = all_names

print("Finished reading in all data. Now starting classifications.")

# ###############################################
# # fit the random forest models

rf_name = paste(all_class_names,"rf",sep=".")
num_out_schemes = length(all_class_names)
input_list = vector("list",num_out_schemes)
### here we pre-scribe all the features to the classification scheme
for(s in 1:num_out_schemes) 
{
  print(paste("Training scheme",all_class_names[s]))
  ## currently dont use the phenology metrics for any scheme
   temp_ind = class_dat[,s] > 0
## make the class column into a factor for classifications -add back in the site id info
   temp.data = cbind(all_site_info[temp_ind,],all_dat[temp_ind,],as.factor(class_dat[temp_ind,s]))
   colnames(temp.data) = c("tile_h","tile_v","db_id","site_id","biome",all_names,"class")

    ## special procedure for training data for NVEG scheme -sea ice problems
    if(all_class_names[s] == "nveg") {
        wat_ind = temp.data[,"class"]==3
        ## the minimum ndsi never drops below 0.1 and the median green band is 0.15 - likely permananent sea ice
        ndsi_ind = temp.data[,"ndsi_q10"] > 1000 & temp.data[,"b4_q50"]>1500 & wat_ind
        ## we take out those pixels from our training set
        temp.data = temp.data[!ndsi_ind,]
    }

   input_list[[s]] = temp.data
  ### here we can copy the output of randomForest to the rf_name for the current scheme
  result = try(randomForest(class ~ ., data=temp.data[,-c(1:5)],na.action=na.omit),silent=T)
  if(class(result)=="try-error") {
    assign(rf_name[s],NULL)
    print(result[1])
  } else {
    assign(rf_name[s], result)
  }
}

print("Finished training RFs.")

plot_rf_imp(rf_name,all_class_names,num_out_schemes)

## for sanjeeb - these lines setup the output files and might need to have a different naming convention 
## save the rf variables to a temporary file
## first delete it if already exists
out_name <- paste("rf_hier.",end_year,".RData",sep="")
unlink(out_name)

rf_list = vector("list",num_out_schemes)
for(s in 1:num_out_schemes) {
  temp =  eval(as.name(rf_name[s]))
  if(!is.null(temp)) {
    rf_list[[s]] = temp
  }
}
names(rf_list) = all_class_names
names(input_list) = all_class_names

save(rf_list,input_list,all_names,all_class_names,file=out_name)

