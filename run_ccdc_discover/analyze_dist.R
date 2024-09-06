rm(list=ls())
## requires the doParallel library for parallel processing
library(doParallel)
library(rgdal)
library(raster)

debug_flag=1

if(debug_flag==0) {
	## gets three arguments - the chunk of dates, the scene id, and the usa flag
	args = commandArgs(trailingOnly=T)
	interval = as.numeric(args[1])
	tile = args[2]
	in_dir = args[3]
} else {
  interval = 1
  tile="Bh17v16"
  in_dir="../test_vrts"
}


### several different parameter sets to test
par_sets = c("9_45","7_45","9_35","7_35","8_30","9_25","6_25")
in_dir = "/projectnb/modislc/users/dsm/above"
num_pars = length(par_sets)

### load the disturbance maps
dist_maps = vector("list",num_pars)
for( i in 1:num_pars) {
dist_name = paste(in_dir,"/run_ccdc_",par_sets[i],"/",tile,"_first.tif",sep="")
if(file.exists(dist_name)) {
dist_maps[[i]] = as.vector(raster(dist_name))
} else { print(paste("File",dist_name,"does not exist!")) }
}
### load the Canadaian LFDB
lfdb_ras = raster("./lfdb_Bh17v16/LFDB.tif")
lfdb = as.vector(lfdb_ras)

### round the maps so they are 1984 to 2015 instead of year-date
### also put them in an array
npix = length(dist_maps[[1]])
dates = array(NA,dim=c(npix,num_pars))
years = dates
for(i in 1:num_pars) {
  years[,i] = round(dist_maps[[i]]/1000,0)
  dates[,i] = dist_maps[[i]] %% 1000
}

undist_lfdb = lfdb < 1985

undist_ccdc = array(NA,dim=c(npix,num_pars))
prop_dist_lfdb = length(lfdb[!undist_lfdb])/npix
prop_dist_ccdc = array(0,num_pars)
for(i in 1:num_pars) {
  undist_ccdc[,i] = is.na(years[,i]) | years[,i] > 2012
  prop_dist_ccdc[i] = length(lfdb[!undist_ccdc[,i]])/npix
}

agree_dist = array(0,num_pars)
dist_ccdc = array(0,num_pars)
dist_lfdb = array(0,num_pars)
agree_undist = array(0,num_pars)
for(i in 1:num_pars) {
  agree_dist[i] = length(lfdb[!undist_ccdc[,i] & !undist_lfdb])
  dist_lfdb[i] = length(lfdb[undist_ccdc[,i]  & !undist_lfdb])
  dist_ccdc[i] = length(lfdb[!undist_ccdc[,i] & undist_lfdb])
  agree_undist[i] = length(lfdb[undist_ccdc[,i] & undist_lfdb])
}

sum_arr = round(rbind(agree_dist,dist_lfdb,dist_ccdc,agree_undist)/npix,3)
colnames(sum_arr) = par_sets


temp_ras = lfdb_ras
lfdb[undist_lfdb] = 0
new_lfdb_ras = setValues(temp_ras,lfdb)


for( i in 1:num_pars) {
  dist_maps[[i]][undist_ccdc[,i]] = 0
  dist_maps[[i]][!undist_ccdc[,i]] = years[!undist_ccdc[,i],i]
}
temp_ras = lfdb_ras
new_dist_ras = vector("list",num_pars)
for( i in 1:num_pars) {
  new_dist_ras[[i]] = setValues(temp_ras,dist_maps[[i]])
}
library(RColorBrewer)
my.cols = brewer.pal(6,"Spectral")

pdf("dist_comp_120116.pdf")
barplot(sum_arr)

par(mfrow=c(3,3),mar=c(0.2,0.2,0.2,0.2)+0.1)
image(new_lfdb_ras,col=my.cols,breaks=c(1,1980,1990,1995,2000,2005,2010),axes=F)
text(x=-250000,y=1750000,"LFDB",cex=1.8)
for( i in 1:num_pars) {
  image(new_dist_ras[[i]],col=my.cols,breaks=c(1,1980,1990,1995,2000,2005,2010),axes=F)
  text(x=-250000,y=1750000,par_sets[i],cex=1.8)
}


dev.off()


