rm(list=ls())

## function to abbreviate paste
"%+%" <- function(x,y) paste(x,y,sep="")

## main function that merges the two csvs - ref and map
merge_val <- function(tile,in_dir,dist_dir) {
  ## useful function to search for file names or directory names
  search_str = paste("*",tile,"*csv",sep="")
  cur_file = list.files(path=in_dir,pattern=glob2rx(search_str),full.names=T,include.dirs=F)
  
  ## we open the disturbance data if it exists
  cur_dist = dist_dir%+%"/val_"%+%tile%+%".csv"
  if(file.exists(cur_dist)) {
    temp_dist_dat = read.table(cur_dist,sep=",",na.strings="NA",header=T)
  }

  ## we load the ref data
  ref_dat = read.table(cur_file,sep=",",na.strings="NA")
  colnames(ref_dat) = c("pix_id","id","init","date_int","corr","conf",
                        "date","mag","agent","lc","num_int","comm")
  
  ## merge the two by id
  merged = merge(ref_dat,temp_dist_dat,by.x="id",by.y="id")
  
  return(merged)
}

make_conf_mat <- function(in_list,inter_dist) {
  
  conf_mat = matrix(0,nrow=2,ncol=2)
  ## ref on the rows - disturbed in row 1 and undist in row 2
  conf_mat[1,1] = length(inter_dist[in_list[,1]])
  conf_mat[1,2] = length(inter_dist[in_list[,2]])
  conf_mat[2,1] = length(inter_dist[in_list[,3]])
  conf_mat[2,2] = length(inter_dist[in_list[,4]])
  return(conf_mat)
}
###############################################
# read in the data

## location of inputs/outputs and list of tiles to process
in_tiles = c("h09v12","h14v14","h06v04","h09v15","h04v06","h16v15","h05v04","h13v15","h07v06","h19v15")
out_dir = "./out_csv/"
dist_dir = "./map_csv"
in_dir = "../ref_sheets_120817/in_csv"

num_tiles = length(in_tiles)

## read each tile's ref and map csvs and merge them
## then append each merged array to the all_dat array
all_dat = NULL
for(i in 1:num_tiles) {
  print("Processing tile "%+%in_tiles[i])
  cur_tile = merge_val(in_tiles[i],in_dir,dist_dir)
  all_dat = rbind(all_dat,cur_tile)
}

## setup the correct and incorrect classes - always from perspective of producer
## incor undist means that the interpreter said it was undisturbed
inter_dist = as.numeric(all_dat[,"num_int"])
na_ind = is.na(inter_dist)
map_dist = as.numeric(all_dat[,"num_dist"])
## can change threshold
thres=2000
acc = array(NA,dim=c(6,3))
count = 0
for(thres in seq(1000,3500,500)) {
  map_dist_ind = as.numeric(all_dat[,"dnbr"]) > thres & !is.na(map_dist)
  corr_dist = inter_dist>0 & !na_ind & map_dist_ind
  corr_undist = inter_dist==0 & !na_ind & !map_dist_ind
  incor_undist = inter_dist==0 & !na_ind & map_dist_ind
  incor_dist = inter_dist>0 & !na_ind & !map_dist_ind
  all_list = cbind(corr_undist,incor_undist,incor_dist,corr_dist)
  
  conf_mat = make_conf_mat(all_list,inter_dist)
  count = count+1
  acc[count,1] = sum(diag(conf_mat))/sum(conf_mat)
  com = diag(conf_mat)/colSums(conf_mat)
  omm = diag(conf_mat)/rowSums(conf_mat)
  acc[count,2] = com[2]
  acc[count,3] = omm[2]
}

colnames(acc) = c("OV","UA","PA")
rownames(acc) = seq(1000,3500,500)

## for plotting
thres = 1000
map_dist_ind = as.numeric(all_dat[,"dnbr"]) > thres & !is.na(map_dist)
corr_dist = inter_dist>0 & !na_ind & map_dist_ind
corr_undist = inter_dist==0 & !na_ind & !map_dist_ind
incor_undist = inter_dist==0 & !na_ind & map_dist_ind
incor_dist = inter_dist>0 & !na_ind & !map_dist_ind
all_list = cbind(corr_undist,incor_undist,incor_dist,corr_dist)

conf_mat = make_conf_mat(all_list,inter_dist)


cur_dnbr = all_dat[,"dnbr"]
cur_pnbr = all_dat[,"pnbr"]
cur_evi2 = all_dat[,"pevi2"]
cur_devi2 = all_dat[,"devi2"]
cur_swir = all_dat[,"p_swir1"]
cur_rmse = all_dat[,"rmse"]
rmse_prop = cur_rmse/cur_swir

pdf("dnbr_vs_pnbr.pdf")
plot(cur_dnbr,cur_pnbr,type="n",ylim=c(0,10000),xlim=c(0,10000))
points(cur_dnbr[corr_dist],cur_pnbr[corr_dist],pch="*",col=2)
points(cur_dnbr[incor_undist],cur_pnbr[incor_undist],pch="+",col="dodgerblue")

plot(cur_dnbr,cur_evi2,type="n",ylim=c(0,10000),xlim=c(0,10000))
points(cur_dnbr[corr_dist],cur_evi2[corr_dist],pch="*",col=2)
points(cur_dnbr[incor_undist],cur_evi2[incor_undist],pch="+",col="dodgerblue")

plot(cur_dnbr,cur_swir,type="n",ylim=c(0,4000),xlim=c(0,10000))
points(cur_dnbr[corr_dist],cur_swir[corr_dist],pch="*",col=2)
points(cur_dnbr[incor_undist],cur_swir[incor_undist],pch="+",col="dodgerblue")

plot(cur_dnbr,rmse_prop,type="n",ylim=c(0,0.4),xlim=c(0,10000))
points(cur_dnbr[corr_dist],rmse_prop[corr_dist],pch="*",col=2)
points(cur_dnbr[incor_undist],rmse_prop[incor_undist],pch="+",col="dodgerblue")

all_lc = as.numeric(all_dat[,"lc"])
plot(cur_dnbr,rmse_prop,type="n",ylim=c(0,0.4),xlim=c(0,10000))
points(cur_dnbr[corr_dist],rmse_prop[corr_dist],pch="*",col=all_lc[corr_dist])
points(cur_dnbr[incor_undist],rmse_prop[incor_undist],pch="+",col=all_lc[incor_undist])

plot(rownames(acc),acc[,2],type="l",ylab="Accuracy",xlab="Threshold",col=2)
lines(rownames(acc),acc[,3],col=3)
lines(rownames(acc),acc[,1])
dev.off()

write.csv(acc,"acc_change.csv")