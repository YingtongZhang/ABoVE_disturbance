
# coding: utf-8

# In[1]:

from osgeo import gdal, gdal_array, osr, ogr
import numpy as np
import logging
import click
import csv
import matplotlib.pyplot as plt
from IPython.core.debugger import set_trace

logger = logging.getLogger('post_pro_agr')

#window_size = 61
window_size = 31  # 15-pix buffer
n = window_size
k = int((n - 1) / 2)
fill = fill_5c = -127

# In[4]:
def NNinFireMask(tile_name, pp_dir, stacked_5c_dir, output_dir):
    
    fireDB_path=r'/projectnb/landsat/users/shijuan/above/ABOVE_fires_new/ABOVE_fireDB/' + tile_name + '/'
    #year_avail = np.arange(2000, 2013, dtype=np.int16)
    year_avail = np.arange(1987, 2013, dtype=np.int16)
    nrows=6000
    ncols=6000
    
    # 5c maps
    stacked_5c_file = stacked_5c_dir + tile_name +'_stacked_5c.tif'
    stacked_5c_ds = gdal.Open(stacked_5c_file)
    stacked_5c_raster = stacked_5c_ds.ReadAsArray()
    stacked_5c_array = np.array(stacked_5c_raster)

    # initialize
    map_array = np.ones((nrows, ncols, 1), dtype=np.int16) * fill 

    for year in year_avail:
        print(year)
        # the fire database of three-year-range(before, middle, after)
        fireYear = []
        
        for i in range(-2, 1):
            fireDB_filename = ('{0}_fireDB_{1}.tif').format(tile_name, year + i)
            fireYear.append(fireDB_path + fireDB_filename)
        
        # need to be optimized after
        # fire database
        fdb_ds0 = gdal.Open(fireYear[0])
        fdb_raster0 = fdb_ds0.ReadAsArray()
        fdb_array0 = np.array(fdb_raster0)
    
        fdb_ds1 = gdal.Open(fireYear[1])
        fdb_raster1 = fdb_ds1.ReadAsArray()
        fdb_array1 = np.array(fdb_raster1)
    
        fdb_ds2 = gdal.Open(fireYear[2])
        fdb_raster2 = fdb_ds2.ReadAsArray()
        fdb_array2 = np.array(fdb_raster2)
        
        # disturbance maps
        pp_file = pp_dir + tile_name +'_FF_FN_NF_NN_' + str(year) + '_cl_pp.tif'
        #pp_file = pp_dir + tile_name +'_FF_FN_NF_NN_' + str(year) + '_cl.tif'
        pp_ds = gdal.Open(pp_file)
        pp_raster = pp_ds.ReadAsArray()
        pp_array = np.array(pp_raster)

        #set_trace()
        # 1. NNother in the fire mask
        # 2. NNother not in the fire mask but near the fire in the map (15 pixel)
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):
                #print(stacked_5c_array[i,j])
                #if stacked_5c_array[i,j] not in [1, 2, 3, 4, 5]:
                if (stacked_5c_array[i,j] == fill_5c):
                    pp = int(pp_array[i, j])
                    
                    # if the pixel is NN fire (9-17)
                    if pp > 8:
                        # count NNother in the fire mask
                        if (fdb_array0[i, j] == 1 or fdb_array1[i, j] == 1 or fdb_array2[i, j] == 1):
                            map_array[i, j, 0] = 1
                    

                        # count NNother outside the fire mask in the 15-pixel buffer
                        else:
                            tmp_window = pp_array[i-k:i+k+1, j-k:j+k+1]
                            window = np.array(tmp_window)
                            window = np.reshape(window, n * n)
                            FireInWindow = 0
                            for pix in window:
                                pix = int(pix)
                                if pix in [3, 8]:
                                    FireInWindow += 1
                        
                            if FireInWindow > 0:
                                map_array[i, j, 0] = 1


    stacked_NNother_name = tile_name +'_NNotherInFire.tif'
    outfile = output_dir + stacked_NNother_name

    img_file = gdal.Open(pp_file)
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
    write_output(map_array, outfile, grid_info, gdal_frmt, band_names=None, ndv=fill)
        
    print(year, "completed")
                            
                          
        
# MAPPING UTILITIES
def write_output(raster, output, grid_info, gdal_frmt, band_names=None, ndv=fill):
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


# In[5]:

def main(tile_name):

    pp_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/remap/'.format(tile_name)
    stacked_5c_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/remap/'.format(tile_name)
    output_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/remap/'.format(tile_name)
    #pp_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/'.format(tile_name)
    #stacked_5c_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/'.format(tile_name)
    #output_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/'.format(tile_name) 
    
    # the smoothing function starts
    NNinFireMask(tile_name, pp_dir, stacked_5c_dir, output_dir)


if __name__ == "__main__":
    main()





