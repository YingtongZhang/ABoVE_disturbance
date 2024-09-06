## created to read in a chunk of cached data Landsat time series data in NetCDF
load("./out_map.RData")
all_years_etm = as.numeric(colnames(out_etm))
all_years_tm5 = as.numeric(colnames(out_tm5))
num_years_etm = length(all_years_etm)
num_years_tm5 = length(all_years_tm5)

library(raster)
library(RColorBrewer)

my_ramp <- colorRampPalette(rev(brewer.pal(11, "Spectral")))

out_img_dir = "./out_jpgs"

for(i in 1:num_years_tm5) {
  temp = rasterFromXYZ(cbind(xy,out_tm5[,i]))
  out_file <- file.path(out_img_dir, paste("ndvi_tm5_", formatC(i, width=3, flag="0"), ".jpg", sep=""))
  jpeg(file=out_file, width=5, height=5,units="in", res=200)
  #layout(matrix(c(1, 2, 3, 3), nrow=2, byrow=T))
  par(mar=rep(0.2, 4), oma=rep(0.1, 4))
  image(temp,col=my_ramp(255))
#  plot(red_r,axes=F,box=F)
#  plotRGB(x=cur_stack,r=3,g=2,b=1, scale=1500, maxpixels=1e10,colNA="white", stretch="lin")

  ## add a label with the year and date
  text(x=3000,y=500, labels=paste(all_years_tm5[i]), col=1, cex=4)
  # turn off device
  dev.off()
}  ## end for loop

for(i in 1:num_years_etm) {
  temp = rasterFromXYZ(cbind(xy,out_etm[,i]))
  out_file <- file.path(out_img_dir, paste("ndvi_etm_", formatC(i, width=3, flag="0"), ".jpg", sep=""))
  jpeg(file=out_file, width=5, height=5,units="in", res=200)
   # layout(matrix(c(1, 2, 3, 3), nrow=2, byrow=T))
  par(mar=rep(0.2, 4), oma=rep(0.1, 4))
  image(temp,col=my_ramp(255))
  #plot(red_r,axes=F,box=F)
  #  plotRGB(x=cur_stack,r=3,g=2,b=1, scale=1500, maxpixels=1e10,colNA="white", stretch="lin")
  
  ## add a label with the year and date
  text(x=3000,y=500, labels=paste(all_years_etm[i]), col=1, cex=4)
  # turn off device
  dev.off()
}  ## end for loop

for(i in 1:66) {

temp_pheno = rasterFromXYZ(cbind(xy,out_pheno[,i]))

out_file = paste("./pheno_out",i,".jpg",sep="")
jpeg(file=out_file,width=5,height=5,units="in",res=200)
par(mar=rep(0.2, 4), oma=rep(0.1, 4))
image(temp_pheno)
dev.off()
}
