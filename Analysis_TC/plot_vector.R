#### R code to plot the vetor between delta tesseled cap
rm(list=ls())

setwd("/projectnb/landsat/projects/ABOVE/CCDC/Bh13v15/out_tc_Forest")

## load raster packages
library(rgdal)
library(raster)
library(shape)

# get Landsat data
# MultiSptr <- brick('Bh13v15_dTC_1995.tif')


# read all years change map (delta Tasseled Cap)
## band1: brightness  -- useless for now
## band2: greenness
## band3: wetness
ras_list <- list.files("/projectnb/landsat/projects/ABOVE/CCDC/Bh13v15/out_tc_Forest",pattern="*.tif$", full.names=T) # 29 files in total
all_layers = stack(ras_list)   # 29*3 layers, arranged by b,g,w across the year
all_layers_b = subset(all_layers, c(seq(1, 87, by = 3)))
all_layers_g = subset(all_layers, c(seq(2, 87, by = 3)))
all_layers_w = subset(all_layers, c(seq(3, 87, by = 3)))
#for (i in 1:29){
#  all_layers_b = all_layers(3*i-2)
#  all_layers_g = all_layers(3*i-1)
#  all_layers_w = all_layers(3*i)
#}

# remove the outlier but not N/A
all_layers_b[abs(all_layers_b) > 10000] <- NA
all_layers_g[abs(all_layers_g) > 10000] <- NA
all_layers_w[abs(all_layers_w) > 10000] <- NA

# sample the raster, in case the processing time will be too long
all_b <- as.matrix(all_layers_b[[1:27]])
all_g <- as.matrix(all_layers_g[[1:27]])
all_w <- as.matrix(all_layers_w[[1:27]])
rows <- nrow(all_b)
cols <- ncol(all_b)

# calculate the max and min value across the layers(years), return the raster layer and year ID
# using the max&min value of wetness, considering wetness is most related to disturbances
# max
layer_ID_max <- apply(all_w,1,function(x) which.max(x)[1])
max_w <- apply(all_w, 1, max, na.rm = TRUE)
# max_w_sub <- sample(max_w, 1000)
max_w_sub <- sample(max_w, 100)
sample_ID = match(max_w_sub, max_w) # sample_ID has 200 in total
# min
layer_ID_min <- apply(all_w,1,function(x) which.min(x)[1])
min_w <- apply(all_w, 1, min, na.rm = TRUE)
# min_w_sub <- sample(min_w, 1000)
# min_w_sub <- sample(min_w, 200)
min_w_sub <- min_w[sample_ID]
# sample_ID_min = match(min_w_sub, min_w)

max_b_sub = matrix(NA, nrow = 100, ncol = 1)
max_g_sub = matrix(NA, nrow = 100, ncol = 1)
min_b_sub = matrix(NA, nrow = 100, ncol = 1)
min_g_sub = matrix(NA, nrow = 100, ncol = 1)

bottom_b = matrix(NA, nrow = 100, ncol = 1)
head_b = matrix(NA, nrow = 100, ncol = 1)
bottom_g = matrix(NA, nrow = 100, ncol = 1)
head_g = matrix(NA, nrow = 100, ncol = 1)
bottom_w = matrix(NA, nrow = 100, ncol = 1)
head_w = matrix(NA, nrow = 100, ncol = 1)

ilayer = matrix(NA, nrow = 100, ncol = 1)
jlayer = matrix(NA, nrow = 100, ncol = 1)

for (i in 1:100){
  # max
  ipixel = sample_ID[i]
  ilayer[i] = layer_ID_max[ipixel]
  # if (ipixel != 1){
  max_b_sub[i] = all_b[ipixel, ilayer[i]]
  max_g_sub[i] = all_g[ipixel, ilayer[i]]
  # }
  # min
  jlayer[i] = layer_ID_min[ipixel]
  min_b_sub[i] = all_b[ipixel, jlayer[i]]
  min_g_sub[i] = all_g[ipixel, jlayer[i]]
  
  # use the later year to minus former year
  # dif_ID > 0 means max late; dif_ID < 0 means min late
  dif_ID = ilayer[i] - jlayer[i]
  if (is.na(dif_ID)){
    next
  }
  if (dif_ID >= 0){
    bottom_b[i] = min_b_sub[i]
    head_b[i] = max_b_sub[i]
    
    bottom_g[i] = min_g_sub[i]
    head_g[i] = max_g_sub[i]
    
    bottom_w[i] = min_w_sub[i]
    head_w[i] = max_w_sub[i]
  }
  else{
    bottom_b[i] = max_b_sub[i]
    head_b[i] = min_b_sub[i]
    
    bottom_g[i] = max_g_sub[i]
    head_g[i] = min_g_sub[i]
    
    bottom_w[i] = max_w_sub[i]
    head_w[i] = min_w_sub[i]
   }  
}


# plot brightness and wetness
xlim <- c(-1800, 1800)
ylim <- c(-1800, 1800)
plot(0, type = "n", xlim = xlim, ylim = ylim, xlab = "delta_wetness", ylab = "delta_greenness",
     main = "Change direction of TC")
plot(0, type = "n", xlim = xlim, ylim = ylim, xlab = "delta_wetness", ylab = "delta_brightness",
     main = "Change direction of TC")
plot(0, type = "n", xlim = xlim, ylim = ylim, xlab = "delta_greenness", ylab = "delta_brightness",
     main = "Change direction of TC")
# angles_bw <- (head_w - head_b)/(bottom_w - bottom_b)

head_b_ <- na.omit(head_b)
head_g_ <- na.omit(head_g)
head_w_ <- na.omit(head_w)
bottom_b_ <- na.omit(bottom_b)
bottom_g_ <- na.omit(bottom_g)
bottom_w_ <- na.omit(bottom_w)

# length_bw <- sqrt((head_w - head_b)^2 + (bottom_w - bottom_b)^2)
Arrows(bottom_w_, bottom_g_, head_w_, head_g_, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 1:2)
Arrows(bottom_w_, bottom_b_, head_w_, head_b_, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 1:2)
Arrows(bottom_g_, bottom_b_, head_g_, head_b_, code = 2, arr.adj = 0.5, 
       arr.type = "curved", lcol = 1:2)
# Arrows(bottom_w, bottom_b, head_w, head_b, code = 2, arr.adj = 0.5, 
#        arr.type = "curved", arr.col = 1:600, lcol = 1:600)

# save the layer ID and head and bottom
ilayer_ <- na.omit(ilayer) 
jlayer_ <- na.omit(jlayer)
cols <- ncol(ilayer_)
rows <- nrow(ilayer_)

out_sample <- matrix(c(t(ilayer_), t(jlayer_), t(head_b_), t(head_g_), t(head_w_), 
                       t(bottom_b_), t(bottom_g_), t(bottom_w_)), nrow = length(t(ilayer_)))
colnames(out_sample) <- c("max_ID", "min_ID", "head_b", "head_g", "head_w", "bottom_b",
                          "bottom_g", "bottom_W")
write.csv(out_sample, file = "/projectnb/landsat/users/zhangyt/above/Bh13v15/Arrow_plot/after_arrow100_2.csv")


# max_w = calc(all_layers_w, max)
# max_ID = which.max(all_layers_w)

# max_b = raster(ncol=6000,nrow=6000)
# max_b[] <- NA
# max_g = raster(ncol=6000,nrow=6000)
# max_g[] <- NA
# for (i in 1:6000){
#   for (j in 1:6000) {
#     ID = max_ID[i,j]
#     if (!is.na(ID)) {
#     max_b[i,j] = all_layers_b[[ID]][i,j]
#     max_g[i,j] = all_layers_g[[ID]][i,j]  
#     }
#     
#   }
# }
# max_b = all_layers_b[max_ID]
# # max_ID_b = which.max(all_layers_b)
# max_g = all_layers_g[max_ID]
# # max_ID_g = which.max(all_layers_g)
# 
# min_w = calc(all_layers_w, min)
# min_ID = which.min(all_layers_w)
# 
# min_b = calc(all_layers_b(min_ID))
# # min_ID_b = which.min(all_layers_b)
# min_g = calc(all_layers_g(min_ID))
# # min_ID_g = which.min(all_layers_g)



# # using the subset of the data to plot
# ID <- sample(1:36000000, 100000)
# Image_sub <- Image [ID, ]
# G_sub <- G[ID, ]
# W_sub <- W[ID, ]
# dnbr_sub <- dnbr[ID, ]