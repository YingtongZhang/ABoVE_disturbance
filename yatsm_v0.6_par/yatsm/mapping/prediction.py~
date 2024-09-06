""" Functions relevant for mapping statistical model predictions or fits
"""
import logging
import re

import numpy as np
import patsy
import pdb
from timeit import default_timer as timer

from .utils import find_result_attributes, find_indices
from ..utils import find_results, iter_records, write_output
from ..regression.transforms import harm
from .pytables import manage_pytables

logger = logging.getLogger('yatsm')

## major function to read in hdf data and write out tifs containing CCDC predictions
def get_prediction(hdf_file, out_tif,year, bands='all', ndv=-9999):
    """ Output a raster with the predictions from model fit for a given date

    Args:
        hdf_file (str): Location of input hdf file
        out_tif (str): Location of output tif file for this year
        year (int): Year for prediction image
        bands (str, list): Bands to predict - 'all' for every band, or specify
            a list of bands
        ndv (int, optional): NoDataValue
        
    """

    if(bands=='all'):
        n_bands=8
    else:
        n_bands=len(bands)
    
    ## open up the hdf file for reading
    # import the functions
    pt = manage_pytables()

    # open the HDF file
    pt.open_hdf_file(hdf_file)

    ## location of the grid info metadata
    grid_info = read_grid_info(pt.h5_file.root.grid)

    meta = pt.h5_file.root.metadata

    logger.debug('Allocating memory')
    raster = np.ones((grid_info['nrows'], grid_info['ncols'], n_bands),
                     dtype=np.int16) * int(ndv)

    nchunks = meta.nrows
    meta_info = read_meta(meta)
    out_bands = np.arange(0,n_bands)
    ## read in start year from metadata
    ## need to do all this part differently
    y_loc = year - meta_info['years'][0]

    ## should have 2 rows per chunk
    chunk_nrows = 2
    ##chunk_nrows = len(meta_info['y_coords'][0,])

    logger.debug('Processing results')
    for n in meta_info['ids']:
        ## access the current group
        array_name = "/C{}/Ref".format(n)
        h5_node = pt.h5_file.get_node(array_name).read()
        ## read the node for the year and reshape it to 3 dimensions
        temp = h5_node[:,out_bands,y_loc].reshape(chunk_nrows,grid_info['ncols'],n_bands)
        start_loc = n*chunk_nrows
        end_loc = (n*chunk_nrows) + chunk_nrows
        raster[start_loc:end_loc,:,:] = temp

    logger.debug('Writing output file {}'.format(out_tif))
    write_output(raster, out_tif, grid_info, gdal_frmt='GTiff')

    pt.close_hdf()
    ## doesnt return anything

## similar function to get the RMSE data for the current year's segment
def get_rmse(hdf_file, out_tif,year, bands='all', ndv=-9999):
    """ Output a raster with the rmse from model fit for a given date

    Args:
        hdf_file (str): Location of input hdf file
        out_tif (str): Location of output tif file for this year
        year (int): Year for prediction image
        bands (str, list): Bands to predict - 'all' for every band, or specify
            a list of bands
        ndv (int, optional): NoDataValue
        
    """

    if(bands=='all'):
        n_bands=7
    else:
        n_bands=len(bands)
    
    ## open up the hdf file for reading
    # import the functions
    pt = manage_pytables()

    # open the HDF file
    pt.open_hdf_file(hdf_file)

    ## location of the grid info metadata
    grid_info = read_grid_info(pt.h5_file.root.grid)

    meta = pt.h5_file.root.metadata

    logger.debug('Allocating memory')
    raster = np.ones((grid_info['nrows'], grid_info['ncols'], n_bands),
                     dtype=np.int16) * int(ndv)

    nchunks = meta.nrows
    meta_info = read_meta(meta)
    ## the rmse starts at the 9th tuple of the 2nd index
    prev_bands = 8
    out_bands = np.arange(prev_bands,n_bands+prev_bands)
    ## read in start year from metadata
    ## need to do all this part differently
    y_loc = year - meta_info['years'][0]

    ## should have 2 rows per chunk
    chunk_nrows = 2
    ##chunk_nrows = len(meta_info['y_coords'][0,])

    logger.debug('Processing results')
    for n in meta_info['ids']:
        ## access the current group
        array_name = "/C{}/Ref".format(n)
        h5_node = pt.h5_file.get_node(array_name).read()
        ## read the node for the year and reshape it to 3 dimensions
        temp = h5_node[:,out_bands,y_loc].reshape(chunk_nrows,grid_info['ncols'],n_bands)
        start_loc = n*chunk_nrows
        end_loc = (n*chunk_nrows) + chunk_nrows
        raster[start_loc:end_loc,:,:] = temp

    logger.debug('Writing output file {}'.format(out_tif))
    write_output(raster, out_tif, grid_info, gdal_frmt='GTiff')

    pt.close_hdf()
    ## doesnt return anything

## reads in the grid_info from the HDF5 file
def read_grid_info(in_tab):

    ## parse out the grid info for making the raster
    grid_size = in_tab.col('grid_size')[0].decode("UTF-8")
    projection = in_tab.col('projection')[0].decode("UTF-8")
    extent = in_tab.col('extent')[0].decode("UTF-8")
    pix_size = in_tab.col('pix_size')[0].decode("UTF-8")
    doy = in_tab.col('doy')[0]
    tile = in_tab.col('tile')[0].decode("UTF-8")
 
    grid_info = dict()
    grid_info['projection'] = projection
    grid_info['doy'] = doy
    grid_info['tile'] = tile

    for i in extent.split(","):
        key = i.split(":")[0]
        value = float(i.split(":")[1])
        grid_info[key] = value

    for i in pix_size.split(","):
        key = i.split(":")[0]
        value = float(i.split(":")[1])
        grid_info[key] = value

    for i in grid_size.split(","):
        key = i.split(":")[0]
        value = int(i.split(":")[1])
        grid_info[key] = value


    return(grid_info)

def read_meta(in_tab):

    ### parse the chunk metadata - most of them only need the first value
    band_names = in_tab.col('bands')[0].decode("UTF-8").split(":")
    year_str_arr = in_tab.col('years')[0].decode("UTF-8").split(":")
    ids = in_tab.col('id')
    y_str_arr = in_tab.col('y_coords')
    x_str = in_tab.col('x_coords')[0].decode("UTF-8").split(":")
    
    num_rows_tab = in_tab.nrows
    nchunks = 3000
    ## nchunks = in_tab.nrows

    ## fill in the chunk metadata
    meta_info = dict()
    meta_info['bands'] = band_names
    meta_info['years'] = np.arange(int(year_str_arr[0]),int(year_str_arr[-1])+1)
    meta_info['ids'] = ids
    meta_info['x_coords'] = np.arange(int(x_str[0]),int(x_str[1])+1)
    ## make the y coords as a list of array coordinates
    meta_info['y_coords'] = np.zeros((nchunks,2),dtype=np.int16)
    for i in ids:
        ## make sure the index exists - otherwize we leave 0s
        try:
            cur_chunk = y_str_arr[i].decode("UTF-8").split(":")
            out_val = np.arange(int(cur_chunk[0]),int(cur_chunk[1])+1)
            meta_info['y_coords'][i,] = out_val
        except IndexError:
            print('no index found for id {}.'.format(i))
            continue

    return(meta_info)



