rm(list=ls())

require(randomForest)

# read in the arguments
args = commandArgs(trailingOnly=T)
debug=0

if(debug==0) {
   ## location of the splined quantile data
  comp_dir = args[1]
   ## in stem of that data
  in_stem = args[2]
  ## tile and year of interest
  tile = args[3]
  year = args[4]
## where the output classifications will be stored
  out_dir = args[5]
## where the rf_hier files are stored for the current year
  train_dir = args[6]
} else {
  comp_dir = "/projectnb/modislc/users/dsm/spline_codes/spline_one_v3/outputs2"
  in_stem = "c6_str5"
  tile = "h12v04"
  year = "2006"
  out_dir = "./outputs_hier"
  train_dir = "../train"
}

write.float <- function(out_file,in_dat,tile_h,tile_v,nbands) {

  uly_map = 10007554.677
  ulx_map = -20015109.354
  lry_map = -10007554.677
  lrx_map = 20015109.354
  pix = 463.312716525
  dim = 2400
  
  ulx = ulx_map + (tile_h * pix * dim)
  uly = uly_map - (tile_v * pix * dim)

  f <- file(out_file,"wb")
  writeBin(in_dat,f,endian="little",size=4)
  close(f)
  
  temp_txt = paste("ENVI description = { after prior file }\nlines = ",dim,"\nsamples = ",dim,
  "\nbands = ",nbands,"\nheader offset = 0\nfile type = ENVI Standard\ndata type = 4\ninterleave = bsq\nbyte order = 0\nmap info = {Sinusoidal, 1, 1,",ulx,", ",uly,", ",pix,", ",pix,"}",
  "\ncoordinate system string = {PROJCS[\"Sinusoidal\",GEOGCS[\"GCS_unnamed ellipse\",DATUM[\"D_unknown\",SPHEROID[\"Unknown\",6371007.181,0]],PRIMEM[\"Greenwich\",0],UNIT[\"Degree\",0.017453292519943295]],PROJECTION[\"Sinusoidal\"],PARAMETER[\"central_meridian\",0],PARAMETER[\"false_easting\",0],PARAMETER[\"false_northing\",0],UNIT[\"Meter\",1]]}",sep="")
  out_hdr = paste(out_file,".hdr",sep="")
  sink(out_hdr)
  cat(temp_txt)
  sink()
}


#### function definitions:
## this function reads an integer image stack
read_int_file <- function(in_file, dsize, nbands, s_flag=T, bsq_flag=0) {
  
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

###############################################
# open the composited Rdata files

## for sanjeeb - this name will need to be modified to find the MCD12I1 data
# open the quantile file for each year and pull out the values of interest
in_file <- paste(comp_dir,"/",in_stem,".",tile,".",year,".quant.bip",sep="")

if(file.exists(in_file)) {
  dsize = 2
  ## there are 11 bands (6 spectral and 5 indices) and 6 metrics for each year/band plus one snow flag
  nbands = 67
  quant_dat <-  read_int_file(in_file = in_file, dsize = dsize, nbands = nbands)
  ## load the input training data file
  train_name = paste(train_dir,"/rf_hier.",year,".RData",sep="")
  load(train_name)

  num_schemes = length(rf_list)
  scheme_names = names(rf_list)
  
  # get the data as an data.frame
  all_feats.df <- data.frame(quant_dat)
  names(all_feats.df) <- all_names
  
  rf_out = paste(scheme_names,"pred",sep=".")
  ## start processing each scheme
  start <- Sys.time()
  for(s in 1:num_schemes) {
    print(paste("Classifying for scheme ",scheme_names[s],sep="") )	
    if(!is.null(rf_list[[s]])) {
	## here is where the classification of that scheme takes place
      assign(rf_out[s], try(predict(rf_list[[s]], newdata=all_feats.df, type="prob")))
   
      # check for predict error
      if(inherits(eval(as.name(rf_out[s])), "try-error")){
        print(paste("Failure in predict.randomForest for scheme ",scheme_names[s]))
        return(NA)
      }
      ## get the class conditional posterior probabilities at each pixel
      in_class = eval(as.name(rf_out[s]))
      in_class_names = as.numeric(colnames(in_class))
       ## get the number of classes
      num_in_class = length(in_class_names)
      num_out_class = max(in_class_names)
      npix = 2400*2400
      ## we need to make sure the output has the right num classes that we expect
      ## we assume the last class is usually present
      if(num_in_class != num_out_class) {
        out_class = array(0,dim=c(npix,num_out_class))
        for(i in 1:num_out_class) {
          temp_col = in_class_names==i
          if(length(temp_col[temp_col])>0) { out_class[,i] = in_class[,temp_col] }
        }
      } else {
	out_class = in_class
      }
      
      out_dat = as.vector(out_class)
      ## get the tile h and v for making a header file
      tile_h = as.numeric(substring(tile,2,3))
      tile_v = as.numeric(substring(tile,5,6))
     ## make sure output exists
	## writing output to file 
	## for sanjeeb - this might need to be changed to fix the output names
      new_out_dir = paste(out_dir,"/",scheme_names[s],sep="")
      if(!file.exists(new_out_dir)) {
  	dir.create(new_out_dir)
      }
      out_file = paste(new_out_dir,"/",rf_out[s],".",tile,".",year,".bsq",sep="")
      write.float(out_file,out_dat,tile_h,tile_v,num_out_class)
    }
  }
  end <- Sys.time()
  print(end - start)
  
} else {
  print(paste("Input file ",in_file," does not exist. Classification aborted!",sep=""))
}
