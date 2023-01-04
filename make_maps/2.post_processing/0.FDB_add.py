
# coding: utf-8

# # ABoVE post-processing

from osgeo import gdal, gdal_array, osr, ogr
import numpy as np
import logging
import click
import pdb
import os
from IPython.core.debugger import set_trace
from scipy import stats

logger = logging.getLogger('post_pro_agr')
fill = -32767
window_size = 61
n = window_size
k = int((n - 1) / 2)

window_threshold = 0.13


def generate_add_fire_perm(tile_name, combine_dir, fireDB_path, output_dir):
    
    year_avail = np.arange(1986, 2014, dtype=np.int16)
    #year_avail = np.arange(2000, 2005, dtype=np.int16)
    nrows=6000
    ncols=6000
    
    for year in year_avail:
        print(year)
        # the fire database of three-year-range(before, middle, after) --- (before2, before1, current)
        fireYear = []
        cc_file = []
        
        #for i in range(-1, 2):
        for i in range(-2, 1):
            fireDB_filename = ('{0}_fireDB_{1}.tif').format(tile_name, year + i)
            fireYear.append(fireDB_path + fireDB_filename)
        
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
        cc_file = combine_dir + tile_name +'_FF_FN_NF_NN_' + str(year) + '_cl.tif'
        cc_ds = gdal.Open(cc_file)
        cc_raster = cc_ds.ReadAsArray()
        cc_array = np.array(cc_raster)
        
        # initialize
        fire_array = np.ones((nrows, ncols, 1), dtype=np.float32) * 0
        map_array = np.ones((nrows, ncols, 1), dtype=np.float32) * 0
        
        # if the pixel is FN fire (3)
        for i in np.arange(0, nrows ):
            for j in np.arange(0, ncols):  
                cc = int(cc_array[i, j])

                if cc == 3:
                    if (fdb_array0[i, j] == 1 or fdb_array1[i, j] == 1 or fdb_array2[i, j] == 1):
                        fire_array[i, j, 0] =  0
                    else:
                        fire_array[i, j, 0] =  1
                else:
                    fire_array[i, j, 0] = 0
                    
        # take the average in the moving window
        for i in np.arange(k, nrows - k):
            for j in np.arange(k, ncols - k):  
                cc = int(fire_array[i, j])
                
                tmp_window = fire_array[i-k:i+k+1, j-k:j+k+1, 0]
                window = np.array(tmp_window)
                window = np.reshape(window, n * n)
                window_average = np.average(window)
                if window_average > window_threshold:
                    map_array[i, j, 0] = 1
                else:
                    map_array[i, j, 0] = 0
                #map_array[i, j, 0] = np.average(window)
        
        FDB_map_name = tile_name +'_FDB_add_' + str(year) +'.tif'
        outfile = output_dir + FDB_map_name

        img_file = gdal.Open(cc_file)
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



@click.command()
@click.option('--tile_name', default='Bh13v15', help='Name of the tile, for example: Bh13v15')
#tile_name = 'Bh02v04'
#print(tile_name, "starts processing.")


def main(tile_name):
    combine_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_classes/'.format(tile_name)
    fireDB_path = r'/projectnb/landsat/users/shijuan/above/ABOVE_fires_new/ABOVE_fireDB/' + tile_name + '/'
    output_dir = r'/projectnb/landsat/users/zhangyt/above/ABOVE_fires/FDB_ADD/{0}/'.format(tile_name)
    #output_dir = r'/projectnb/landsat/users/zhangyt/above/ABOVE_fires/Additional_FDB/{0}/thre_0/test_61'.format(tile_name)

    #if not os.path.exists(output_dir):
    #    os.mkdir(output_dir)
    #    print("Directory " , output_dir ,  " Created ")
    #else:    
    #    print("Directory " , output_dir ,  " already exists")

    # the function starts
    generate_add_fire_perm(tile_name, combine_dir, fireDB_path, output_dir)


if __name__ == "__main__":
    main()

