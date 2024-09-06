#### R code to plot the correlation between Tasseled Cap (basically g&w) and dnbr

setwd("/Volumes/Autumn/Phd Daily/Projects/ABoVE/h13v15")

## load raster packages - make sure have loaded R/3.4
library(rgdal)
library(raster)
library(ggplot2)
library(ggpmisc)

# get Landsat data
MultiSptr <- brick('tc_nbr/Bh13v15_dTC_1995.tif')
## band1: brightness  -- useless for now
## band2: greenness
## band3: wetness
## band4: dnbr

# nf <- layout(matrix(c(1,0,2), 1, 3, byrow = TRUE), width = c(1,0.2,1), respect = TRUE)
plotRGB(MultiSptr, r = 1, g = 2, b = 3, axes = TRUE, stretch = "lin",
        main = "Tasseled Cap values of each break")

Image <- as.data.frame(MultiSptr[[2:4]])
G <- Image[1]  # 2nd band  -- same to use the subset function (subset(MultiSptr,1:3))
W <- Image[2]  # 3rd band
dnbr <- Image[3]

# using the subset of the data to plot
ID <- sample(1:36000000, 100000)
Image_sub <- Image [ID, ]
G_sub <- G[ID, ]
W_sub <- W[ID, ]
dnbr_sub <- dnbr[ID, ]



#if (abs(G_sub) < 10000 & abs(W_sub) < 10000 & abs(dnbr_sub) < 10000){
ggplot(data = Image_sub, aes(x = W_sub, y = G_sub, color = dnbr_sub)) +   
  geom_point(na.rm=TRUE, alpha = 0.4) +
  geom_smooth(method="lm", se=FALSE, formula = G_sub ~ W_sub) +
  stat_poly_eq(formula = G_sub ~ W_sub,
               eq.with.lhs = "italic(hat(y))~`=`~",
               aes(label = paste(..eq.label.., ..rr.label.., sep = "~~~")), 
               parse = TRUE) +
  scale_color_gradient(low = "#0091ff", high = "#f0650e")
#}
 












