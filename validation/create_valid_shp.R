## R script to read in the CCDC results and extract out the raster data for interpretation

library("rgdal")
library("raster")

debug=0
if(debug==0) {
  args = commandArgs(trailingOnly=T)
  in_tile = args[1]
} else {
  in_tile = "Bh17v16"
}

in_loc = paste("../discover/alaska_mos_110217",sep="")
out_name = paste("./outputs/val_",in_tile,".shp",sep="")

in_name = paste(in_loc,"/",in_tile,".dates.tif",sep="")
date_ras = raster(in_name)
in_name = paste(in_loc,"/",in_tile,".num.tif",sep="")
num_ras = raster(in_name)
in_name = paste(in_loc,"/",in_tile,".pnbr.tif",sep="")
pnbr_ras = raster(in_name)
in_name = paste(in_loc,"/",in_tile,".dnbr.tif",sep="")
dnbr_ras = raster(in_name)

dist_vec = as.vector(num_ras)
dist_ind = dist_vec>0 & !is.na(dist_vec)
undist_ind = is.na(dist_vec)

all_pix = seq(1,length(dist_vec))
dist_pop = all_pix[dist_ind]
undist_pop = all_pix[undist_ind]

dist_samp = sample(length(dist_pop),60,replace=F)
undist_samp = sample(length(undist_pop),15,replace=F)

## convert to actual pixel coordinates
dist_pix = all_pix[dist_pop[dist_samp]]
undist_pix = all_pix[undist_pop[undist_samp]]

all_pix_out = sample(c(dist_pix,undist_pix))

    ## convert to the correct coordinates to make a shapefile
    ulx_grid = -3400020
    uly_grid = 4640000
    pix = 30
    npix_tile = 6000
    
    tile_x = as.numeric(substring(in_tile,3,4))
    tile_y = as.numeric(substring(in_tile,6,7))
    
    ## convert our single value to x,y coordinates relative to the origin 0,0
    y_loc = floor((all_pix_out-1)/npix_tile)
    x_loc = all_pix_out - (y_loc*npix_tile) - 1
     
    ## we accumulate x in the positive direction but y in the southward negative direction
    ## add half a pixel offset to be the middle of the pix
    cur_coord_x = ulx_grid + (tile_x*npix_tile*pix) + x_loc*pix + pix*0.5
    cur_coord_y = uly_grid - (tile_y*npix_tile*pix) - y_loc*pix - pix*0.5
    
    ## set the projection of the data
    out_proj =  '+proj=aea +lat_1=50 +lat_2=70 +lat_0=40 +lon_0=-96 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs'    ## in case we want to reproject to geog
    geog_proj = '+proj=longlat +datum=WGS84 +no_defs'
    
    cur_points=SpatialPoints(cbind(cur_coord_x,cur_coord_y), proj4string=CRS(out_proj))
    
    ## save out as a shapefile
    num_pix = seq(1,length(all_pix_out))
    out_met = data.frame(cbind(num_pix,all_pix_out,
                        as.vector(date_ras[all_pix_out]),as.vector(dnbr_ras[all_pix_out]),
                        as.vector(pnbr_ras[all_pix_out]),as.vector(num_ras[all_pix_out]) ))
    colnames(out_met) = c("pix","id","date","dnbr","pnbr","num")
    x = SpatialPointsDataFrame(cur_points, out_met)
    
    writeOGR(x,dsn=out_name,layer="val_pts",driver="ESRI Shapefile",overwrite_layer=T)
                               
