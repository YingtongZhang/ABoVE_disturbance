
library("rgdal")
library("raster")
library("randomForest")
## for correlation
library("Hmisc")
library("stringr")

check_na <- function(all_mets) {
  ## return index with missing data
  
  num_mets = dim(all_mets)[[2]]
  npix = dim(all_mets)[[1]]
  bool_out = array(F,npix)
  for(i in 1:npix)
  {
    temp_ind = is.na(all_mets[i,])  
    if(length(all_mets[i,temp_ind])>0) {
      bool_out[i]=T
    }
      
    
  }
  return(bool_out)
}

make_shp_glas <- function(pix_mets,out_name,preds,na_ind) {

    layer_name = strsplit(out_name,".",TRUE)[[1]][1]
    print(paste("Layer name will be ",layer_name))

    ## set the projection of the data
    out_proj =  '+proj=aea +lat_1=14.5 +lat_2=32.5 +lat_0=24 +lon_0=-105 +x_0=0 +y_0=0 +ellps=GRS80 +units=m'

    ## we convert the xy values to actual pixel coordinates - need to know ulx of entire grid
    ulx=-1403190
    uly=1177680
    pix=30
    ncols=6000
    nrows = 6000

    tile_v = pix_mets[!na_ind,"tile_v"]
    tile_h = pix_mets[!na_ind,"tile_h"]
    pix_id = pix_mets[!na_ind,"pix_id"]

    ## now we can compute the center of each pixel relative to the corners
    ulx_tile = ulx + (tile_h * pix * ncols)
    uly_tile = uly - (tile_v * pix * nrows)

    ## pix id is 1 indexed - make the pix_y and pix_x 0 indexed
    pix_y = floor((pix_id -1)/nrows)
    pix_x = (pix_id - 1) %% ncols
    ## add half a pixel to get the corner of the correct pixel
    x_coords = ulx_tile + (pix * pix_x) + pix/2
    y_coords = uly_tile - (pix * pix_y) - pix/2

    xy_points=SpatialPoints(cbind(x_coords,y_coords), proj4string=CRS(out_proj))
    ## the na_ind has already been applied to preds
    all_out = data.frame(cbind(pix_mets[!na_ind,],preds))
    rownames(all_out) = seq(1,length(all_out[,1]))
    ## save out as a shapefile
    x = SpatialPointsDataFrame(xy_points, all_out)
    writeOGR(x,dsn=out_name,layer=layer_name,
             driver="ESRI Shapefile",overwrite_layer=T)
}

# x is a matrix containing the data
# method : correlation method. "pearson"" or "spearman"" is supported
# removeTriangle : remove upper or lower triangle
# results :  if "html" or "latex"
# the results will be displayed in html or latex format
corstars <-function(x, method=c("pearson", "spearman"), removeTriangle=c("upper", "lower"),
                    result=c("none", "html", "latex")){
  #Compute correlation matrix
  x <- as.matrix(x)
  correlation_matrix<-rcorr(x, type=method[1])
  R <- correlation_matrix$r # Matrix of correlation coeficients
  p <- correlation_matrix$P # Matrix of p-value 
  
  ## Define notions for significance levels; spacing is important.
  mystars <- ifelse(p < .0001, "****", ifelse(p < .001, "*** ", ifelse(p < .01, "**  ", ifelse(p < .05, "*   ", "    "))))
  
  ## trunctuate the correlation matrix to two decimal
  R <- format(round(cbind(rep(-1.11, ncol(x)), R), 2))[,-1]
  
  ## build a new matrix that includes the correlations with their apropriate stars
  Rnew <- matrix(paste(R, mystars, sep=""), ncol=ncol(x))
  diag(Rnew) <- paste(diag(R), " ", sep="")
  rownames(Rnew) <- colnames(x)
  colnames(Rnew) <- paste(colnames(x), "", sep="")
  
  ## remove upper triangle of correlation matrix
  if(removeTriangle[1]=="upper"){
    Rnew <- as.matrix(Rnew)
    Rnew[upper.tri(Rnew, diag = TRUE)] <- ""
    Rnew <- as.data.frame(Rnew)
  }
  
  ## remove lower triangle of correlation matrix
  else if(removeTriangle[1]=="lower"){
    Rnew <- as.matrix(Rnew)
    Rnew[lower.tri(Rnew, diag = TRUE)] <- ""
    Rnew <- as.data.frame(Rnew)
  }
  
  ## remove last column and return the correlation matrix
  Rnew <- cbind(Rnew[1:length(Rnew)-1])
  if (result[1]=="none") return(Rnew)
  else{
    #if(result[1]=="html") print(xtable(Rnew), type="html")
    #else print(xtable(Rnew), type="latex") 
    print("don't support other types without xtable.")
  }
} 

make_smoothScatter <- function(val_in,rf_in,val_md,in_stem) {
  ## prepare val for classification
  val_na = check_na(val_in)
  
  val = val_in[!val_na,]
  rownames(val) = seq(1,(length(val[,1])))
  
  nmets= dim(val)[[2]]
  
  ## predict on valid set
  preds_v = predict(rf_in,val[,-nmets])
  cur_pal = colorRampPalette(c("purple","blue","green","yellow","orange","red"))
  
  library(KernSmooth)
  ## the data range is approximately 0,512 so it needs to bin the data over 520x520
  ## estimate the point density at 10x10 pixels
  ## this is the function at the base of smoothScatter
  cur_dens = bkde2D(cbind(val_md[!val_na,"bio"],preds_v),
                    bandwidth=c(10,10),gridsize=c(520,520))
  total_val = sum(hist_val)
  ## this gives the maximum density of points
  cur_range = range(cur_dens[[3]]*total_val)
  
  out_name = paste("rf_",in_stem,".png",sep="")
  png(out_name,width=5,height=5.5,units="in",res=150)
  par(mar=c(4,4,1.8,0.7),mgp=c(2.5,1,0),cex.main=1.4,cex.axis=1.4,cex.lab=1.4)
  
  ## plot the truth vs predictions on the validation subset
  smoothScatter(val_md[!val_na,"bio"],preds_v,xlim=c(0,300),
                bandwidth=c(10,10),ylim=c(0,300),colramp=cur_pal,nrpoints=0,
                ylab="Landsat Predicted (Mg C/ha)",xlab="GLAS Biomass (Mg C/ha)",
                main=paste("Biomass Estimates with",in_stem))
  abline(0,1,lwd=2.5)
  
  text(100,250,paste("R-squared = ",round(mean(rf_in$rsq),2),"\nRMSE = ",
                     round(sqrt(mean(rf_in$mse)),1),"\nN = ",length(preds_v),sep=""),
       col="white",cex=1.4)
  
  ## make a nice gradient legend
  xl = 270
  yb = 0
  xr = 285
  yt = 200
  rect(
    xl,
    head(seq(yb,yt,(yt-yb)/7),-1),
    xr,
    tail(seq(yb,yt,(yt-yb)/7),-1),
    col=cur_pal(7)
  )
  text(300,tail(seq(yb,yt,(yt-yb)/7),-1)-15,
       format(seq(cur_range[1],cur_range[2],cur_range[2]/6),
              digits=1),las=2,cex=1,col="white")
  dev.off()

  return(val)
} ## end function

##### END FUNCTIONS
######################
######## Begin main

load(file="./rf_gla_st_012218.RData")
load(file="./rf_gla_mon_012218.RData")

in_file = "all_train_mets_012118.RData"

load(file=in_file)

colnames(all_out[["md"]]) = c("bio","glas_id","num_pix","year","pix_id","tile_h","tile_v","lc")

## make histograms of biomass distribution

all_bio = all_out[["md"]][,"bio"]
train_bio = train_md[,"bio"]
val_bio = val_md[,"bio"]

bio_breaks = c(0,1,50,100,150,200,250,300,1000)

hist_all = hist(all_bio,breaks=bio_breaks,plot=F)$counts
hist_all_full = hist_all
hist_train = hist(train_bio,breaks=bio_breaks,plot=F)$counts
hist_val = hist(val_bio,breaks=bio_breaks,plot=F)$counts

act_len = hist_all[1]
hist_all[1] = 35000

png("train_hist.png",width=6,height=5,units="in",res=150)
par(mar=c(4,4,1.8,0.7),mgp=c(2.5,1,0),cex.main=1.2,cex.axis=1.4,cex.lab=1.4)

barplot(hist_all,border=F,col="gray85",
        ylim=c(0,35000),axes=F,names.arg=c("0","1","50","100","150","200","250","300"))
barplot(rbind(hist_train,hist_val),col=c("firebrick","dodgerblue"),border=NA,add=T,axes=F,ylab="Count",xlab="Above-Ground Biomass (Mg C/ha)")
text(0.75,32000,format(act_len,big.mark=","),cex=1.2)
axis(side=2,pos=0,at=seq(0,35000,5000),seq(0,35000,5000))
legend("topright",fill=c("gray85","firebrick","dodgerblue"),legend=c("All GLAS","Training sites","Validation sites"))
dev.off()

val = make_smoothScatter(val_mul,rf_mul,val_md,"MUL")
val = make_smoothScatter(val_2,rf_2,val_md,"JUN_DEC")
val = make_smoothScatter(val_st,rf_st,val_md,"ST")
val = make_smoothScatter(val_sep,rf_sep,val_md,"SEP")
val = make_smoothScatter(val_stclim,rf_stclim,val_md,"ST_CLIM")
val_na = check_na(val_stclim)
nmets = dim(val)[[2]]
preds_v = predict(rf_stclim,val[,-nmets])


## make a table to hold several rf results in it
rf_res_tab = array(0,dim=c(8,3))
rf_res_tab[,1] = c("Mar","Jun","Sep","Dec","Jun_Dec","MUL","ST","ST_CLIM")
rf_res_tab[1,2] = round(mean(rf_mar$rsq),2)
rf_res_tab[1,3] = round(sqrt(mean(rf_mar$mse)),1)
rf_res_tab[2,2] = round(mean(rf_jun$rsq),2)
rf_res_tab[2,3] = round(sqrt(mean(rf_jun$mse)),1)
rf_res_tab[3,2] = round(mean(rf_sep$rsq),2)
rf_res_tab[3,3] = round(sqrt(mean(rf_sep$mse)),1)
rf_res_tab[4,2] = round(mean(rf_dec$rsq),2)
rf_res_tab[4,3] = round(sqrt(mean(rf_dec$mse)),1)
rf_res_tab[5,2] = round(mean(rf_2$rsq),2)
rf_res_tab[5,3] = round(sqrt(mean(rf_2$mse)),1)
rf_res_tab[6,2] = round(mean(rf_mul$rsq),2)
rf_res_tab[6,3] = round(sqrt(mean(rf_mul$mse)),1)
rf_res_tab[7,2] = round(mean(rf_st$rsq),2)
rf_res_tab[7,3] = round(sqrt(mean(rf_st$mse)),1)
rf_res_tab[8,2] = round(mean(rf_stclim$rsq),2)
rf_res_tab[8,3] = round(sqrt(mean(rf_stclim$mse)),1)
write.table(rf_res_tab,file="rf_out_tab.csv",quote=F,sep = " & ",
            eol = " \\\\ \\hline \n",row.names=F,col.names=F)

tile_count = read.csv("../../run_tilez/tile_count.csv")

pr_count_all = read.csv("../../run_tilez/all_vrt_file_list_111017.csv")
un_pr = unique(pr_count_all[,1])
un_pr = un_pr[!is.na(un_pr)]
sens = substr(un_pr,1,3)
pr = substr(un_pr,4,9)
all_year = as.numeric(substr(un_pr,10,13))

years = seq(1984,2015)
sens_count = array(0,dim=c(length(years),4))
sens_count[,1] = years
in_names = c("LT4","LT5","LE7")
for(y in years) {
  cur_ind = all_year==y & !is.na(all_year)
  for(s in 1:3) {
    cur_ind2 = cur_ind & sens==in_names[s]
    sens_count[y-1983,(s+1)] = length(unique(un_pr[cur_ind2]))
    
  }
}

sens_cols = c("goldenrod2","magenta","forestgreen")
sens_names = c("LT4","LT5","ETM")
png("sens_count.png",width=7,height=4.5,units="in",res=150)
par(mar=c(4,4,1.2,0.5),mgp=c(3,1,0),cex.main=1.1,cex.axis=1.1,cex.lab=1.1)

temp=barplot(t(sens_count[,2:4]),border=F,col=sens_cols,
             ylim=c(0,4000),axes=F,ylab="Frequency",xlab="Year")
axis(side=2,pos=-1.3,at=seq(0,4000,1000),seq(0,4000,1000))
axis(side=1,pos=0,at=temp[c(1,6,11,16,21,26,31)],seq(years[1],years[31],5))
box()
legend(x=3,y=3700,fill=sens_cols,legend=sens_names,cex=1.2)
dev.off()



lit_rev_full = read.csv("mex_rev_full.csv")
nrows_lit = dim(lit_rev_full)[[1]] - 1
lit_rev_full = lit_rev_full[1:nrows_lit,]
sort_row = lit_rev_full[,1]

sort_row = as.numeric(str_replace(as.character(sort_row),"E","e"))
lit_order = order(sort_row,decreasing=F)
lit_rev_full = lit_rev_full[lit_order,]

rev_out_file = "./rev_out.tex"
write.table(lit_rev_full,file=rev_out_file,quote=F,sep = " & ",
            eol = " \\\\ \\hline \n",row.names=F,col.names=F)

lit_rev_all = read.csv("mex_review.csv")
colnames(lit_rev_all) = c("Extent","Resolution","RS Data","Mean","SD","RMSE","Rsq")

rmse_per = lit_rev_all[,"RMSE"]/lit_rev_all[,"Mean"]
na_ind = is.na(rmse_per)

lit_rev_rmse = lit_rev_all[!na_ind,]
rmse_per = lit_rev_rmse[,"RMSE"]/lit_rev_rmse[,"Mean"]

rs_types = sort(unique(lit_rev_rmse[,3]),decreasing=F)
num_types = length(rs_types)
## make 15 for lidar, 16 for radar, 17 for airborne spec, 18 for space spec
## for the mixtures - choose the highest num
rs_symbs = c(15,15,16,16,17,17,17,0,1,1,
             2,2,0,2,2,2,2,2)
col1 = "firebrick"
col2 = "dodgerblue"
## color indicates airborne vs spaceborne sensors
rs_cols = c(col1,col2,col1,col2,col1,col1,col2,col2,
            col1,col2,col1,col2,col1,col2,col2,col2,
            col2,col2)


temp_range = range(abs(rmse_per),na.rm=T)

scaling_fac = 0.7
new_width = ((1-rmse_per)*scaling_fac) + 0.6
leg_vals = quantile(new_width,c(0.1,0.5,0.9))
leg_names = rev(round(quantile(rmse_per,
                               c(0.1,0.5,0.9)),2))

cur_rsq = lit_rev_all[,"Rsq"]
na_rsq = is.na(cur_rsq)
lit_rev_rsq = lit_rev_all[!na_rsq,]
cur_rsq = lit_rev_rsq[,"Rsq"]

scaling_fac = 1
new_width2 = (cur_rsq*scaling_fac) + 0.4
leg_vals_rsq = quantile(new_width2,c(0.1,0.5,0.9))
leg_names_rsq = round(quantile(cur_rsq,
                               c(0.1,0.5,0.9)),2)

png("lit_rev.png",width=6,height=5,units="in",res=150)
par(mar=c(4,4,1.8,1.5),mgp=c(2.5,1,0),
    cex.main=1.4,cex.axis=1.2,cex.lab=1.4)

plot(log10(lit_rev_rmse[,2]),log10(lit_rev_rmse[,1]),cex=0.6,type="n",
     ylab="log10 of Spatial Extent (Mha)",xlab="log10 of Spatial Resolution (m)",
     xlim=c(0,3.5),ylim=c(-7,5))
for(i in 1:num_types) {
  cur_ind = lit_rev_rmse[,3]==rs_types[i]
  temp_width = as.numeric(new_width[cur_ind])
  points(log10(lit_rev_rmse[cur_ind,2]),
                 log10(lit_rev_rmse[cur_ind,1]),
                 col=rs_cols[i],pch=rs_symbs[i],cex=temp_width)
  
 }
legend("bottomleft",pch=c(15,16,17),
       legend=c("Lidar", "SAR", "Spectral"),cex=1)

legend("topleft",pch=c(15,0,15,15),
       legend=c("Single sensor","Combined","Airborne","Spaceborne"), 
       col=c(rep(1,2),"firebrick","dodgerblue"),cex=1)
legend("bottomright",pch=15,legend=leg_names,pt.cex=leg_vals,title="Relative RMSE (%)")
dev.off()

png("lit_rev_rsq.png",width=6,height=5,units="in",res=150)
par(mar=c(4,4,1.8,1.5),mgp=c(2.5,1,0),
    cex.main=1.4,cex.axis=1.2,cex.lab=1.4)

plot(log10(lit_rev_rsq[,2]),log10(lit_rev_rsq[,1]),cex=0.6,type="n",
     ylab="log10 of Spatial Extent (Mha)",xlab="log10 of Spatial Resolution (m)",
     xlim=c(0,3.5),ylim=c(-7,5))
for(i in 1:num_types) {
  cur_ind = lit_rev_rsq[,3]==rs_types[i]
  temp_width = as.numeric(new_width2[cur_ind])
  points(log10(lit_rev_rsq[cur_ind,2]),
         log10(lit_rev_rsq[cur_ind,1]),
         col=rs_cols[i],pch=rs_symbs[i],cex=temp_width)
  
}
legend("bottomleft",pch=c(15,16,17),
       legend=c("Lidar", "SAR", "Spectral"),cex=1)

legend("topleft",pch=c(15,0,15,15),
       legend=c("Single sensor","Combined","Airborne","Spaceborne"), 
       col=c(rep(1,2),"firebrick","dodgerblue"),cex=1)
legend("bottomright",pch=15,legend=leg_names_rsq,pt.cex=leg_vals_rsq,title="Rsq")
dev.off()


stclim_imp = importance(rf_stclim)[,1]
st_imp = importance(rf_st)[,1]
mul_imp = importance(rf_2)[,1]

mul_imp_s = sort(mul_imp,decreasing=T)[1:10]
st_imp_s = sort(st_imp,decreasing=T)[1:10]
stclim_imp_s = sort(stclim_imp,decreasing=T)[1:10]

png("feat_imp_st.png",width=7,height=5,units="in",res=150)
par(mfrow=c(1,2),mar=c(4,7,1.8,1.5),mgp=c(2.5,1,0),
    cex.main=1.4,cex.axis=1.2,cex.lab=1.3)

## could make the bar names different colors with mtext and names.args=""
barplot(rev(st_imp_s),horiz=T,axes=F,las=2,
        main="ST Feats",xlab="Increase in MSE (%)",xlim=c(0,60))
axis(side=1,seq(0,60,10),at=seq(0,60,10),pos=0)
barplot(rev(stclim_imp_s),horiz=T,axes=F,las=2,
        main="ST+Clim Feats",xlab="Increase in MSE (%)",xlim=c(0,60))
axis(side=1,seq(0,60,10),at=seq(0,60,10),pos=0)
dev.off()

png("feat_imp_mul.png",width=7,height=5,units="in",res=150)
par(mfrow=c(1,2),mar=c(4,7,1.8,1.5),mgp=c(2.5,1,0),
    cex.main=1.4,cex.axis=1.2,cex.lab=1.3)

## could make the bar names different colors with mtext and names.args=""
barplot(rev(st_imp_s),horiz=T,axes=F,las=2,
        main="ST Feats",xlab="Increase in MSE (%)",xlim=c(0,60))
axis(side=1,seq(0,60,10),at=seq(0,60,10),pos=0)
barplot(rev(mul_imp_s),horiz=T,axes=F,las=2,
        main="Two Synthetic Images",xlab="Increase in MSE (%)",xlim=c(0,80))
axis(side=1,seq(0,80,20),at=seq(0,80,20),pos=0)
dev.off()

## sort feats by importance and take the top 15
cur_order = order(stclim_imp,decreasing=T)
all_feat = as.matrix(val[,-nmets])
all_feat = all_feat[,cur_order]
all_feat = all_feat[,1:10]

## compute correlation matrix and print out pretty latex table
cor_mat = corstars(all_feat, method="pearson", 
                   removeTriangle="upper",result="none")
corr_file = "./corr_mat.csv"
write.table(cor_mat,file=corr_file,quote=F,sep = " & ",
            eol = " \\\\ \\hline \n",row.names=T,col.names=T)

top_names = colnames(all_feat)
pdf("corr_plots.pdf")

for(i in 2:10) {
smoothScatter(all_feat[,top_names[1]],all_feat[,top_names[i]])
}
for(i in 3:10) {
  smoothScatter(all_feat[,top_names[2]],all_feat[,top_names[i]])
}
dev.off()

## predict on train set
preds_t = rf_stclim$y
ntrain = length(preds_t)

### save stats to file for paper
file_out = "train_stats.RData"
save(file=file_out,cor_mat,all_feat,mul_imp_s,st_imp_s,stclim_imp_s,lit_rev_all,rmse_per,all_bio,hist_all_full,
                        hist_train,hist_val,preds_v,sens_count,tile_count,rf_res_tab)

## check the training data for missing values
na_train = check_na(train_stclim)
out_name = "train_pts.shp"
make_shp_glas(train_md,out_name,preds_t,na_train)

out_name = "val_pts.shp"
make_shp_glas(val_md,out_name,preds_v,val_na)

