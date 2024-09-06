## R script to read in the CCDC results and extract out the GLAS data for training RF
## doesnt need any gdal package - will read in a set of dataframes
library(randomForest)

source("train_fxns.R")

####################################
###  begin main
##################################

in_file = "all_train_mets_012118.RData"

all_out = filter_input(in_file)
all_bio = all_out[["md"]][,"bio"]

## sample across strata of GLAS biomass 
all_samp = make_bio_samp(all_bio)
samp_train = all_samp[[1]]
samp_val = all_samp[[2]]
train_mets = get_train_mets(all_out,samp_train)
val_mets = get_train_mets(all_out,samp_val)

train_all = as.data.frame(cbind(train_mets[["st"]],train_mets[["text"]],train_mets[["rmse"]],
                  train_mets[["clim"]],train_mets[["md"]][,"bio"]))
val_all = as.data.frame(cbind(val_mets[["st"]],val_mets[["text"]],val_mets[["rmse"]],
                 val_mets[["clim"]],val_mets[["md"]][,"bio"]))

rf_all = train_trees_glas(train_all,val_all,"all")

train_st = cbind(train_mets[["st"]],train_mets[["md"]][,"bio"])
val_st = cbind(val_mets[["st"]],val_mets[["md"]][,"bio"])

rf_st = train_trees_glas(train_st,val_st,"st")

train_mul = as.data.frame(cbind(train_mets[["mon"]],train_mets[["md"]][,"bio"]))
val_mul = as.data.frame(cbind(val_mets[["mon"]],val_mets[["md"]][,"bio"]))
rf_mul = train_trees_glas(train_mul,val_mul,"mul")

train_mclim = cbind(train_mets[["mon"]],train_mets[["clim"]],train_mets[["md"]][,"bio"])
val_mclim = cbind(val_mets[["mon"]],val_mets[["clim"]],val_mets[["md"]][,"bio"])
rf_mclim = train_trees_glas(train_mclim,val_mclim,"mclim")

start1 = 1
end1 = 7
start2 = 8
end2 = 14
start3 = 15
end3 = 21
start4 = 22
end4 = 28
train_2 = cbind(train_mets[["mon"]][,start2:end2],train_mets[["mon"]][,start4:end4],train_mets[["md"]][,"bio"])
val_2 = cbind(val_mets[["mon"]][,start2:end2],val_mets[["mon"]][,start4:end4],val_mets[["md"]][,"bio"])
rf_2 = train_trees_glas(train_2,val_2,"2")

train_mar = cbind(train_mets[["mon"]][,start1:end1],train_mets[["md"]][,"bio"])
val_mar = cbind(val_mets[["mon"]][,start1:end1],val_mets[["md"]][,"bio"])
rf_mar = train_trees_glas(train_mar,val_mar,"mar")

train_jun = cbind(train_mets[["mon"]][,start2:end2],train_mets[["md"]][,"bio"])
val_jun = cbind(val_mets[["mon"]][,start2:end2],val_mets[["md"]][,"bio"])
rf_jun = train_trees_glas(train_jun,val_jun,"jun")

train_sep = cbind(train_mets[["mon"]][,start3:end3],train_mets[["md"]][,"bio"])
val_sep = cbind(val_mets[["mon"]][,start3:end3],val_mets[["md"]][,"bio"])
rf_sep = train_trees_glas(train_sep,val_sep,"sep")

train_dec = cbind(train_mets[["mon"]][,start4:end4],train_mets[["md"]][,"bio"])
val_dec = cbind(val_mets[["mon"]][,start4:end4],val_mets[["md"]][,"bio"])
rf_dec = train_trees_glas(train_dec,val_dec,"dec")

train_stclim = cbind(train_mets[["st"]],train_mets[["clim"]],train_mets[["md"]][,"bio"])
val_stclim = cbind(val_mets[["st"]],val_mets[["clim"]],val_mets[["md"]][,"bio"])

rf_stclim = train_trees_glas(train_stclim,val_stclim,"stclim")

train_st_text_rmse = cbind(train_mets[["st"]],train_mets[["text"]],train_mets[["rmse"]],train_mets[["md"]][,"bio"])
val_st_text_rmse = cbind(val_mets[["st"]],val_mets[["text"]],val_mets[["rmse"]],val_mets[["md"]][,"bio"])

rf_st_text_rmse = train_trees_glas(train_st_text_rmse,val_st_text_rmse,"st_text_rmse")

train_st_rmse = cbind(train_mets[["st"]],train_mets[["rmse"]],train_mets[["md"]][,"bio"])
val_st_rmse = cbind(val_mets[["st"]],val_mets[["rmse"]],val_mets[["md"]][,"bio"])

rf_st_rmse = train_trees_glas(train_st_rmse,val_st_rmse,"st_rmse")

train_text_rmse_clim = cbind(train_mets[["text"]],train_mets[["rmse"]],train_mets[["clim"]],train_mets[["md"]][,"bio"])
val_text_rmse_clim = cbind(val_mets[["text"]],val_mets[["rmse"]],val_mets[["clim"]],val_mets[["md"]][,"bio"])

rf_text_rmse_clim = train_trees_glas(train_text_rmse_clim,val_text_rmse_clim,"text_rmse_clim")

train_text_rmse = cbind(train_mets[["text"]],train_mets[["rmse"]],train_mets[["md"]][,"bio"])
val_text_rmse = cbind(val_mets[["text"]],val_mets[["rmse"]],val_mets[["md"]][,"bio"])

rf_text_rmse = train_trees_glas(train_text_rmse,val_text_rmse,"text_rmse")

## where the output RF RData files are stored
out_name = "./rf_gla_st_012918.RData"
val_md = val_mets[["md"]]
train_md = train_mets[["md"]] 
save(file=out_name,rf_st,rf_stclim,
     rf_all,rf_text_rmse_clim,rf_st_rmse,rf_st_text_rmse,
     rf_text_rmse,val_md,train_md,val_st_text_rmse,
     val_st,val_stclim,train_stclim)

out_name = "./rf_gla_mon_012918.RData"
save(file=out_name,rf_mul,rf_2,rf_mar,
     rf_jun,rf_sep,rf_dec,val_mul,val_2,val_mar, 
     val_jun, val_sep, val_dec,train_mul,val_mclim,train_mclim,rf_mclim)

print("Done training and printing to files.")
