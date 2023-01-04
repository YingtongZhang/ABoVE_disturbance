
rm(list=ls())
if(!require(rgdal)) {install.packages('rgdal',repos = "http://cran.us.r-project.org")}
library(rgdal)
library(raster)
"%+%" <- function(x,y) paste(x,y,sep="")

args <- commandArgs(trailingOnly=TRUE)
tile_name <- args[1]
#tile_name = "Bh13v15"

root = "/projectnb/landsat/projects/ABOVE/CCDC/"%+%tile_name%+%"/new_map"
disturance_dir = file.path(root, "out_agents")
output_dir = root

file_list <- list.files(disturance_dir, pattern="*.tif$", full.names=T)
file_name <- list.files(disturance_dir, pattern="*.tif$")[1]

stack_years <- stack(file_list)
names(stack_years) <- tile_name%+%"_"%+%(as.character(seq(1987,2012)))

output_file <- file.path(output_dir, substr(file_name,1,32)%+%".tif")
writeRaster(stack_years, 
            output_file,
            format="GTiff", 
            datatype='INT1U',
            NAflag=255,
            options=c("COMPRESS=LZW", "TILED=YES", "NUM_THREADS=ALL_CPUS"),
            overwrite=TRUE)

