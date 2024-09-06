""" Functions relevant for accessing the HDF5 file and updating it with data
"""
from datetime import datetime as dt
import logging
import pdb
import re
import patsy
from timeit import default_timer as timer

import numpy as np
## for parallel job running
from joblib import Parallel, delayed, load, dump
from multiprocessing import Pool, cpu_count
import tempfile
import os
from .pytables import manage_pytables

from .utils import find_result_attributes, find_indices
from ..utils import find_results, iter_records, get_record_x,convert_to_ord
from ..regression.transforms import harm

logger = logging.getLogger('yatsm')

def make_hdf(result_location, image_ds, band, hdf_name,
                    out_format='%Y%j',
                    magnitude=False,
                    ndv=-9999, pattern='yatsm_c*', warn_on_empty=False):


    ## find all the locations of the yatsm_c* input files
    records = find_results(result_location, pattern)

    start = timer()

    # run the pytables function to create an hdf file from the records
    pytables_yatsm(records, hdf_file=hdf_name, image_info=image_ds, 
            method='put',  title='CCDC')

    end = timer()
    print(end - start)
    ## returns nothing

## main function to create hdf files - uses tables 
def pytables_yatsm(inputs,
             hdf_file,image_info=None,title='Landsat',
             method='put',group=None,table_row=None,meta_dict=None,
             out_name=None,chunk=False,node_title=None,
             array_type='c',grid_infos=None,sensor=None,
             complib='blosc',complevel=5,shuffle=True,
             cloud_band_included=False,
             **kwargs):
    
    """
    Inserts synthetic images into a HDF file
    
    Args:
        inputs (str list or ndarray): A list of CCDC output npz files.
        hdf_file (str): The HDF file to save images to.
        image_info (Optional[bool]): An ``ropen`` image object used to find tile dimensions and projection.
        title (Optional[str]): The HDF table title. Default is 'Landsat'.
        method (Optional[str]): The tables method. Default is 'put', or put data into a table. Choices are
            ['put', 'remove'].
        group (Optional[str]): A group array to remove. Default is None.
        table_row (Optional[list]): A table row list to remove. Default is []. Given as [int path, int row,
            str sensor, str year, str monthday].
        
    Returns:
        None, writes to ``hdf_file``.
        
    Examples:
        >>> from mappy.utilities.landsat import pytables
        >>>
        >>> # save two images to a HDF file
        >>> pytables(['/p228r78_etm_2000_0716.tif', '/p228r78_etm_2000_0920.tif'],
        >>>          '/2000_p228.h5')
        >>>
        >>> # remove an array group
        >>> pytables([], '/2000_p218.h5', method='remove', group='/2000/p218r63/ETM/p218r63_etm_2000_1117_ndvi')
        >>>
        >>> # remove a table row group
        >>> pytables([], '/2000_p218.h5', method='remove', table_row=[218, 63, 'ETM', '2000', '1117'])
    """
    #    Find result attributes to extract
    i_bands, _, _, _, design, design_info = find_result_attributes(
        inputs, 'all', None, prefix='')

    # Create X matrix from date -- ignoring categorical variables
    if re.match(r'.*C\(.*\).*', design):
        logger.warning('Categorical variable found in design matrix not used'
                       ' in predicted image estimate')
    design = re.sub(r'[\+\-][\ ]+C\(.*\)', '', design)

    i_coef = []
    for k, v in design_info.items():
        if not re.match('C\(.*\)', k):
            i_coef.append(v)
    i_coef = np.sort(i_coef)

    grid_info,ncols = get_grid_info(image_info,hdf_file)
    grid_info['design'] = design

    # import gc
    pt = manage_pytables()

    # open the HDF file
    pt.open_hdf_file(hdf_file, title=title)

    if method == 'put':

        if isinstance(inputs, list):
            ## this sets up the grid wide metadata
            pt.set_metadata(in_dict=grid_info) 

            ## adds the metadata to the hdf file
            pt.add_table(table_name='grid')  
            ## iterate through the records
            for rec in iter_records(inputs):

                ## calculate the peak summer reflectances for each band and year
                ## using from the coefficients inside of rec
                ## also get the rmse for that chunk
                all_dat,chunk_info = calc_refs(rec,i_coef,design)
                
                ## setup the group name for that chunk - could have other groups here
                pt.get_groups(chunk_info) 
                ## this adds the groups into the hdf5 file pt.h5_file
                pt.add_groups()
                ## this sets up the internal metadata
                pt.set_metadata(in_dict=chunk_info) 
                ## adds the metadata to the hdf file
                pt.add_table(table_name='metadata')  

                ## now we are ready to add our array into the hdf file
                pt.add_array(image_array=all_dat,array_storage="Int16",image_shape=all_dat.shape)

                ## later to read in the data
                #pt = manage_pytables()
                #pt.open_hdf_file('/2000_p228.h5', mode='r')            
                # open a 100 x 100 array
                #pt.get_array('/2000/p228r83/ETM/p228r83_etm_2000_0124_tcap_wetness', 0, 0, 100, 100)

    elif method == 'remove':

        if isinstance(group, str):
            pt.remove_array_group(group)
        elif table_row:
            pt.remove_table_group(table_row[0], table_row[1], table_row[2], table_row[3], table_row[4])

    elif method == 'write':

        pt.write2file(inputs[0], out_name, table_row[0], table_row[1], table_row[2], table_row[3])

    pt.close_hdf()

def calc_refs(rec,coefs,design):

    start_year = 1984
    ## this is actually the year after the end year
    end_year = 2015
    years = np.arange(start_year,end_year)
    mid_date = 212
    num_years = len(years)

    n_coefs, n_bands = rec['coef'][0].shape
    i_bands = np.arange(0, n_bands)

    ## get the spatial dimensions of the chunk
    ## we assume that rec['py'] will always have 2 unique entries to get the minimum
    min_y = min(rec['py'])
    #ncols = max(rec['px'])-min(rec['px'])+1
    ncols = 6000
    nrows = 2
    npix = ncols*nrows
    # y coords will be the starting and ending y-coord for the chunk - only need it for the metadata
    y_range = [min_y,min_y+1]
    # x coords will be the starting and ending x-coord for the chunk - only need it for the metadata
    x_range = [0,ncols-1]

    ## setup the chunk metadata table
    ## band names refers to the 7 land bands plus the date of break if any for that year
    band_names = ':'.join(['blue', 'green', 'red', 'nir', 'midir', 'farir','lir','break'])
    ## this will give the chunk number - 0-3000
    cur_chunk = int(min_y/nrows)
    ## create a dictionary to keep the chunk metadata 
    chunk_info = dict()
    ## fill in the metadata - some are saved as strings to save space
    chunk_info['id']= cur_chunk
    chunk_info['y_coords']=':'.join(map(str, y_range))
    ## x coords is already a list
    chunk_info['x_coords']=':'.join(map(str, x_range))
    chunk_info['years'] = ':'.join(map(str, list(years)))
    chunk_info['bands'] = band_names             

    ## we zero out the y dimensions for the sake of the output arrays
    pix_ind = (rec['py']-min_y)*ncols + rec['px']
    ## these will be the output coordinates
    un_pix_ind = np.unique(pix_ind)

    ## make sure the file has the right number of records
    #if (len(un_pix_ind) != npix):
    #    print("The record does not have the right number of pix: {0}!={1}".format(len(un_pix_ind),npix))

    ## create an output array to hold the reflectance data
    ndv = -9999
    ref_array = np.ones((npix, (n_bands + 1), num_years),
        dtype=np.int16) * ndv

    rmse_array = np.ones((npix, n_bands, num_years),
        dtype=np.int16) * ndv

    ## uncomment if want to add first 4 coefficients to hdf5 file
    #n_coef=4
    #coef_array = np.ones((npix, n_bands*n_coef, num_years),
    #    dtype=np.int16) * ndv

    #if(len(un_pix_ind) != npix):
    #    pdb.set_trace()

    ## fill the array with the break dates
    changed = np.where(rec['break'] != 0)[0]
    for i in changed:
        cur_date = rec['break'][i]
        break_jul = int(dt.fromordinal(cur_date).strftime('%j'))                
        break_year = int(dt.fromordinal(cur_date).strftime('%Y'))
        ## the x,y coordinate location for that pixel is changed to a 1d index
        ## note that if more than one disturbance occurs 
        ## for that pixel in that year, the first will be overwritten by the any subsequent
        cur_loc = (rec['py'][i]-min_y)*ncols + rec['px'][i]
        ## location of the year array
        out_y = break_year - start_year
        ## this is the location of the break date info
        ref_array[cur_loc,7,out_y] = break_jul
   
    ## loop through the years
    for y in years:
        ## calculate each year's reflectance at date 212
        date = convert_to_ord('{0}{1}'.format(y,mid_date))
        X = patsy.dmatrix(design, {'x': date}).squeeze()
        out_y = y - start_year

        for index in find_indices(rec, date):
            if index.shape[0] == 0:
                continue

            # Calculate prediction for that date
            _coef = rec['coef'].take(index, axis=0).\
                take(coefs, axis=1).take(i_bands, axis=2)

            ## this will create a spatial output index for the output reflectances
            fill_loc = (rec['py'][index]-min_y)*ncols + rec['px'][index]
            ## fill the outputs refs
            ref_array[fill_loc,0:n_bands,out_y] = np.tensordot(_coef, X, axes=(1, 0))
            ## Extract RMSE for that year's segment 
            rmse_array[fill_loc,0:n_bands,out_y] = rec['rmse'].take(index, axis=0).\
                                                        take(i_bands, axis=1)
            ## uncomment if you want to write out CCDC coefficients
            #for b in i_bands:
                ## cur_start = b*n_coef
                ## cur_end = (b+1)*n_coef
                #coef_array[fill_loc,cur_start:cur_end,out_y] = _coef[index,0:n_coef,b]
    
    ## merge the arrays by the second index (bands)
    all_out = np.concatenate((ref_array,rmse_array),axis=1)  
    ### change to the line below ifyou wnt to write out ccdc coefficients    
    #all_out = np.concatenate((ref_array,rmse_array,coef_array),axis=1) 
      
    return all_out,chunk_info

def get_grid_info(image_info,hdf_file):
    ## now we have metadata on the rows within the chunk and the years
    ## we need some raster metadata - extent, projection, etc
    ncols_ras = image_info.RasterXSize
    nrows_ras = image_info.RasterYSize
    proj_WKT_str = image_info.GetProjectionRef()  
    transform = image_info.GetGeoTransform()
    ## always consider the upper left corner of the upper left pixel the convention 
    ulx_grid = transform[0]
    uly_grid = transform[3]
    pixelWidth = transform[1]
    pixelHeight = transform[5]
    ## this is the lower right corner of the lower right pixel coordinates 
    lrx_grid = ulx_grid + ((ncols_ras+1)*pixelWidth)
    lry_grid = uly_grid + ((nrows_ras+1)*pixelHeight)
    ## make a dictionary object for the grid extent
    extent = "ulx:{0},uly:{1},lrx:{2},lry:{3}".format(ulx_grid,uly_grid,lrx_grid,lry_grid)
    pix_size = "pix_x:{0},pix_y:{1}".format(pixelWidth, pixelHeight)
    grid_size = "ncols:{0},nrows:{1}".format(ncols_ras,nrows_ras)

    ## get the name of the current tile
    ## file name will be the last file after cutting off the extension
    cur_tile = str(os.path.splitext(hdf_file)[0].split("/")[-1]).strip()
        
    ## make the output dictionary and fill it with metadata            
    grid_info = dict()
    grid_info['tile'] = cur_tile
    grid_info['extent'] = extent
    grid_info['projection'] = proj_WKT_str
    grid_info['pix_size'] = pix_size
    grid_info['grid_size'] = grid_size
    ## doy is the julian date we assume to be the year's midpoint in terms of greenness
    grid_info['doy'] = 212

    return(grid_info,ncols_ras)

