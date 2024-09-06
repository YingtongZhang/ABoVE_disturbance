## created to read in a chunk of cached data Landsat time series data in NetCDF


tile = "Bh11v11"
in_dir = paste("./",tile,"_phen",sep="")
in_files <- list.files(path=in_dir,pattern=glob2rx("*.RData"),full.names=T,include.dirs=T)

num_files = length(in_files)
## setup to loop through files
i=1
nrows=6000
ncols=6000
nrows_per_chunk = 2
tot_pix_chunk = nrows_per_chunk*ncols

npix= nrows*ncols
xy = array(NA,dim=c(npix,2))
colnames(xy) = c("x","y")
for(i in 1:nrows) {
    start = (i-1)*ncols + 1
    end = i*ncols
    
    xy[start:end,"x"] = seq(1,ncols)
    xy[start:end,"y"] = nrows - i + 1
}

all_years_tm5 = seq(1984,2011)
all_years_etm = seq(1999,2014)
num_years_tm5 = length(all_years_tm5)
num_years_etm = length(all_years_etm)
## each chunk has 6000*3 pixels
out_etm = array(NA,dim=c(npix,num_years_etm))
out_tm5 = array(NA,dim=c(npix,num_years_tm5))

out_pheno = array(NA,dim=c(npix,66))

#for(i in 1:num_files) {
for(i in 1:(nrows/nrows_per_chunk)) {

  row_start = ((i-1)*tot_pix_chunk) + 1
  row_end = (i*tot_pix_chunk)
   print(paste("Processing value ",i,sep=""))
  in_file = paste(in_dir,"/",tile,"_",i,".RData",sep="")
  if(file.exists(in_file)) {
    load(in_file)
    out_etm[row_start:row_end,] = green_out[["etm"]]
    out_tm5[row_start:row_end,] = green_out[["tm5"]]
	out_pheno[row_start:row_end,] = pheno_out
    } else {
      print(paste("File",in_file,"doesnt exist."))
      out_etm[row_start:row_end,] = array(NA,dim=c(tot_pix_chunk,num_years_etm))
      out_tm5[row_start:row_end,] = array(NA,dim=c(tot_pix_chunk,num_years_tm5))
	out_pheno[row_start:row_end,] = array(NA,dim=c(tot_pix_chunk,66))
        
    }
  
  }  ## end for loop
colnames(out_etm) = all_years_etm
colnames(out_tm5) = all_years_tm5
save(out_etm,out_tm5,out_pheno,xy,file="./out_map.RData")
