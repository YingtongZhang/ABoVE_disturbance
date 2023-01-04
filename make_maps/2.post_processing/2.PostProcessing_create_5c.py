
# coding: utf-8

# # ABoVE post-processing

# In[1]:


from osgeo import gdal, gdal_array, osr, ogr
import numpy as np
import logging
import click
import pdb
from IPython.core.debugger import set_trace
from scipy import stats

logger = logging.getLogger('post_pro_agr')
fill = -32767


# In[14]:


def mask_not_5c(tile_name, pp_dir, pp_5c_dir):
    """
      FF -- decline: 1 growth: 2
      FN -- fire: 3 insect: 4 logging: 5 others: 6 & 18
      NF -- regrowth: 7
      NN -- fire: 8 comb: 9-18
    """
    
    year_avail = np.arange(1987, 2013, dtype=np.int16)
    #year_avail = np.arange(1995, 1996, dtype=np.int16)
    nrows=6000
    ncols=6000

    for year in year_avail:
        print(year)
        # the fire database of three-year-range(before, middle, after)
        
        # disturbance maps after post-processing
        pp_file = pp_dir + tile_name +'_FF_FN_NF_NN_' + str(year) + '_cl_pp.tif'
        pp_ds = gdal.Open(pp_file)
        pp_raster = pp_ds.ReadAsArray()
        pp_array = np.array(pp_raster)
        
        # initialize
        map_array = np.ones((nrows, ncols, 1), dtype=np.int16) * fill 
        
        
        # if the pixel is FNfire/insect/logging/other/NNfire
        for i in np.arange(0, nrows):
            for j in np.arange(0, ncols):  
                pp = int(pp_array[i, j])
                map_array[i, j, 0] = pp

                if pp == 3:
                    map_array[i, j, 0] = 1
                elif pp == 4:
                    map_array[i, j, 0] = 2
                elif pp == 5:
                    map_array[i, j, 0] = 3
                elif pp == 6:
                    map_array[i, j, 0] = 4
                elif pp == 8:
                    map_array[i, j, 0] = 5
                else:
                    map_array[i, j, 0] = fill
                    
        
        pp_5c_name = tile_name +'_FF_FN_NF_NN_' + str(year) +'_cl_' + '5c.tif'
        outfile = pp_5c_dir + pp_5c_name

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
                                                                             


# In[10]:


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
@click.option('--tile_name', default='Bh13v15', help='Name of the tile, for example: Bh13v15')

#tile_name = 'Bh04v04'
#print(tile_name, "starts processing.")

# In[16]:


def main(tile_name):
    pp_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/remap/'.format(tile_name)
    #pp_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/'.format(tile_name)
    pp_5c_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp_5c/remap/'.format(tile_name)
    #pp_5c_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp_5c/'.format(tile_name)
    
    mask_not_5c(tile_name, pp_dir, pp_5c_dir)


if __name__ == "__main__":
    main()

