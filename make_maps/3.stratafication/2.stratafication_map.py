
# coding: utf-8

from osgeo import gdal, gdal_array, osr, ogr
import numpy as np
import logging
import click
import pdb
from IPython.core.debugger import set_trace
from scipy import stats

logger = logging.getLogger('post_pro_agr')
fill = -32767



# In[9]:
def make_strata_map(root_dir, tile_name):
    breaks_map = root_dir + tile_name + '_stacked_17c.tif'
    distb_map = root_dir + tile_name + '_stacked_5c.tif'
    output_dir = root_dir
 
    NNf2o_file = root_dir + tile_name + '_NNf2o.tif'
    NNoInF_file = root_dir + tile_name + '_NNotherInFire.tif'
    FFdecline_file = root_dir + tile_name + '_FFdecline.tif'
    buffer_file = root_dir + tile_name + '_buffer_1pix.tif'

    
    fill_5c = -127
    nrows=6000
    ncols=6000

    # breaks map
    break_ds = gdal.Open(breaks_map)
    break_raster = break_ds.ReadAsArray()
    break_array = np.array(break_raster)

    # disturbance maps
    distb_ds = gdal.Open(distb_map)
    distb_raster = distb_ds.ReadAsArray()
    distb_array = np.array(distb_raster)
    
    #########
    #remap the disturbance map to 5classes, not just two value map

    ## break-1: NNfire to NNother
    NNf2o_ds = gdal.Open(NNf2o_file)
    NNf2o_raster = NNf2o_ds.ReadAsArray()
    NNf2o_array = np.array(NNf2o_raster)  
    # break-2: NNother near/in fire
    NNoInF_ds = gdal.Open(NNoInF_file)
    NNoInF_raster = NNoInF_ds.ReadAsArray()
    NNoInF_array = np.array(NNoInF_raster)  
    # break-3: FFdecline
    FFdecl_ds = gdal.Open(FFdecline_file)
    FFdecl_raster = FFdecl_ds.ReadAsArray()
    FFdecl_array = np.array(FFdecl_raster)
    # break-4: buffer
    buffer_ds = gdal.Open(buffer_file)
    buffer_raster = buffer_ds.ReadAsArray()
    buffer_array = np.array(buffer_raster)


    NoBreak_count = break_count = NNf2o_count = NNoInF_count = NNodcl_count = buffer_count = dist_count = 0

    # initialize the stratification map
    #map_array = np.ones((nrows, ncols, 1), dtype=np.int16) * fill 
    map_array = np.zeros((nrows, ncols, 1), dtype=np.int16)
        
    for i in np.arange(0, nrows):
        for j in np.arange(0, ncols):
            br, dist = int(break_array[i, j]), int(distb_array[i, j])

            NNf2o, NNoInF, FFdcl, buff = int(NNf2o_array[i, j]), int(NNoInF_array[i, j]), int(FFdecl_array[i, j]), int(buffer_array[i, j])
            #NNoInF, FFdcl, buff = int(NNoInF_array[i, j]), int(FFdecl_array[i, j]), int(buffer_array[i, j])
            
            # check if break
            # yes
            if br == 1:
		# check if disturbance
		# yes
                if dist != fill_5c:
                    dist_count += 1
                    
                    if dist == 1:
                        map_array[i, j, 0] = 7      # FNfire
                    if dist == 2: 
                        map_array[i, j, 0] = 8      # FNinsect
                    if dist == 3:
                        map_array[i, j, 0] = 9      # FNlogging
                    if dist == 4:
                        map_array[i, j, 0] = 10     # FNother
                    if dist == 5:
                        map_array[i, j, 0] = 11     # NNfire
                
                #no, it's just a break
                else:
                    # or not belong to any category
                    if (NNf2o == fill_5c) and (NNoInF == fill_5c) and (FFdcl == fill_5c) and (buff != 1):
                    #if (NNoInF == fill_5c) and (FFdcl == fill_5c) and (buff != 1):
                        map_array[i, j, 0] = 1
                        #break_count +=1
                    
                    else:
                        #set_trace()
                        #check if is break-4
                        if buff == 1:
                            map_array[i, j, 0] = 5
                
                        #check if is break-3
                        if FFdcl != fill_5c:
                            map_array[i, j, 0] = 4
                            
                        #check if is break-2
                        if NNoInF != fill_5c:
                            map_array[i, j, 0] = 3
                
                        #check if is break-1
                        if NNf2o != fill_5c:
                            map_array[i, j, 0] = 2
                        
                            
                        #if map_array[i, j, 0] == 2:
                        #    NNf2o_count += 1
                            
                        #if map_array[i, j, 0] == 3:
                        #    NNoInF_count += 1
                            
                        #if map_array[i, j, 0] == 4:
                        #    NNodcl_count += 1
                            
                        #if map_array[i, j, 0] == 5:
                        #    buffer_count += 1

            #no, it's not break
            elif br != 1:
                if (NNf2o != fill_5c) or (NNoInF != fill_5c) or (buff == 1):
                #if (NNoInF != fill_5c) or (buff == 1):
                    #check if is break-4
                    if buff == 1:
                        map_array[i, j, 0] = 5

                    #check if is break-2
                    elif NNoInF != fill_5c:
                        map_array[i, j, 0] = 3
                
                    #check if is break-1
                    elif NNf2o != fill_5c:
                        map_array[i, j, 0] = 2
                else:
                    map_array[i, j, 0] = 6
                    #NoBreak_count += 1
            
            
            
        
    strat_map_fname = tile_name +'_strata_0nan.tif'
    outfile = output_dir + strat_map_fname

    img_file = gdal.Open(NNoInF_file)
    geo_info = img_file.GetGeoTransform()
    ulx = geo_info[0]
    pix_x = geo_info[1]
    uly = geo_info[3]
    pix_y = geo_info[5]
    cols = img_file.RasterXSize
    rows = img_file.RasterYSize
    proj_info = img_file.GetProjection()
    grid_info = {'nrows':rows, 'ncols':cols, 'projection':proj_info, 
                'ulx':ulx, 'pix_x':pix_x, 'uly':uly, 'pix_y':pix_y}
    gdal_frmt = 'GTiff'
    #write_output(map_array, outfile, grid_info, gdal_frmt, band_names=None, ndv=-fill)
    write_output(map_array, outfile, grid_info, gdal_frmt, band_names=None, ndv=0)
        
    print(tile_name, "completed")


    #In[19]:

    #total = NoBreak_count + break_count + NNf2o_count + NNoInF_count + NNodcl_count + buffer_count + dist_count
    #tab_name = root_dir + tile_name + '_count.txt'
    #out_tab = [NoBreak_count, break_count, NNf2o_count, NNoInF_count, NNodcl_count, buffer_count, dist_count]
    #print(out_tab)
    #print(NoBreak_count/total, break_count/total, NNf2o_count/total, NNoInF_count/total, NNodcl_count/total, buffer_count/total, dist_count/total)

    #np.savetxt(tab_name, out_tab, delimiter=" ", fmt= '%5.0f')



# In[9]:
# MAPPING UTILITIES
#def write_output(raster, output, grid_info, gdal_frmt, band_names=None, ndv=fill):
def write_output(raster, output, grid_info, gdal_frmt, band_names=None, ndv=0):
    """ Write raster to output file """   

    logger.debug('Writing output to disk')
    driver = gdal.GetDriverByName(str(gdal_frmt))

    if len(raster.shape) > 2:
        nband = raster.shape[2]
    else:
        nband = 1

    ds = driver.Create(
        output,
        grid_info['ncols'], grid_info['nrows'], nband,
        gdal_array.NumericTypeCodeToGDALTypeCode(raster.dtype.type)
    )

    if band_names is not None:
        if len(band_names) != nband:
            logger.error('Did not get enough names for all bands')
            sys.exit(1)

    if raster.ndim > 2:
        for b in range(nband):
            logger.debug('    writing band {b}'.format(b=b + 1))
            ds.GetRasterBand(b + 1).WriteArray(raster[:, :, b])
            ds.GetRasterBand(b + 1).SetNoDataValue(ndv)

            if band_names is not None:
                ds.GetRasterBand(b + 1).SetDescription(band_names[b])
                ds.GetRasterBand(b + 1).SetMetadata({
                    'band_{i}'.format(i=b + 1): band_names[b]
                })
    else:
        logger.debug('    writing band')
        ds.GetRasterBand(1).WriteArray(raster)
        ds.GetRasterBand(1).SetNoDataValue(ndv)

        if band_names is not None:
            ds.GetRasterBand(1).SetDescription(band_names[0])
            ds.GetRasterBand(1).SetMetadata({'band_1': band_names[0]})
    #print(grid_info["projection"])
    ds.SetProjection(grid_info["projection"])
    ## the geo transform goes - ulx, pix_x(w-e pixel resolution), easting, uly, northing, pix_y(n-s pixel resolution, negative value)
    ds.SetGeoTransform((grid_info["ulx"],grid_info["pix_x"],0,
                        grid_info["uly"],0,grid_info["pix_y"]))

    ds = None



# In[2]:
@click.command()
@click.option('--tile_name', default='Bh04v04', help='Name of the tile, for example: Bh13v15')


# In[1]:

def main(tile_name):
    root_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/remap/'.format(tile_name)
    #root_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/'.format(tile_name)
    make_strata_map(root_dir, tile_name)

if __name__ == "__main__":
    main()








