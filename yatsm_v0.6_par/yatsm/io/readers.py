""" Helper functions for reading various types of imagery data
"""
import logging
import time

import numpy as np
from osgeo import gdal, gdal_array

from .stack_line_readers import bip_reader, gdal_reader
from .. import cache

logger = logging.getLogger('yatsm')


def get_image_attribute(image_filename):
    """ Use GDAL to open image and return some attributes

    Args:
        image_filename (str): image filename

    Returns:
        tuple: nrow (int), ncol (int), nband (int), NumPy datatype (type)
    """
    try:
        image_ds = gdal.Open(image_filename, gdal.GA_ReadOnly)
    except Exception as e:
        logger.error('Could not open example image dataset ({f}): {e}'
                     .format(f=image_filename, e=str(e)))
        raise

    nrow = image_ds.RasterYSize
    ncol = image_ds.RasterXSize
    nband = image_ds.RasterCount
    dtype = gdal_array.GDALTypeCodeToNumericTypeCode(
        image_ds.GetRasterBand(1).DataType)

    return (nrow, ncol, nband, dtype)


def read_image(image_filename, bands=None, dtype=None):
    """ Return raster image bands as a sequence of NumPy arrays

    Args:
        image_filename (str): Image filename
        bands (iterable, optional): A sequence of bands to read from image.
            If `bands` is None, function returns all bands in raster. Note that
            bands are indexed on 1 (default: None)
        dtype (np.dtype): NumPy datatype to use for image bands. If `dtype` is
            None, arrays are kept as the image datatype (default: None)

    Returns:
        list: list of NumPy arrays for each band specified

    Raises:
        IOError: raise IOError if bands specified are not contained within
            raster
        RuntimeError: raised if GDAL encounters errors
    """
    try:
        ds = gdal.Open(image_filename, gdal.GA_ReadOnly)
    except:
        logger.error('Could not read image {i}'.format(i=image_filename))
        raise

    if bands:
        if not all([b in range(1, ds.RasterCount + 1) for b in bands]):
            raise IOError('Image {i} ({n} bands) does not contain bands '
                          'specified (requested {b})'.
                          format(i=image_filename, n=ds.RasterCount, b=bands))
    else:
        bands = range(1, ds.RasterCount + 1)

    if not dtype:
        dtype = gdal_array.GDALTypeCodeToNumericTypeCode(
            ds.GetRasterBand(1).DataType)

    output = []
    for b in bands:
        output.append(ds.GetRasterBand(b).ReadAsArray().astype(dtype))

    return output


def read_pixel_timeseries(files, px, py):
    """ Returns NumPy array containing timeseries values for one pixel

    Args:
        files (list): List of filenames to read from
        px (int): Pixel X location
        py (int): Pixel Y location

    Returns:
        np.ndarray: Array (nband x n_images) containing all timeseries data
            from one pixel
    """
    nrow, ncol, nband, dtype = get_image_attribute(files[0])

    if px < 0 or px >= ncol or py < 0 or py >= nrow:
        raise IndexError('Row/column {r}/{c} is outside of image '
                         '(nrow/ncol: {nrow}/{ncol})'.
                         format(r=py, c=px, nrow=nrow, ncol=ncol))

    Y = np.zeros((nband, len(files)), dtype=dtype)

    for i, f in enumerate(files):
        ds = gdal.Open(f, gdal.GA_ReadOnly)
        for b in range(nband):
            Y[b, i] = ds.GetRasterBand(b + 1).ReadAsArray(px, py, 1, 1)

    return Y


def read_line(line, dataset_config):
    """ Reads in dataset from cache

    Args:
        line (int): line to read in from images
        dataset_config (dict): dictionary of dataset configuration options
        in_dir (char): location of the input cache files
      
    Returns:
        np.ndarray: 3D array of image data (nband, n_image, n_cols)
    """
    start_time = time.time()

    read_from_disk = True
    cache_filename = cache.get_line_cache_name(
        dataset_config['input_dir'], line)

    Y, head, ncol, nrow = cache.read_cache_file(cache_filename)
    
    ## get the date information and sort all the data based on that field
    dates = head.take(2,axis=1)
    inds = dates.argsort()
    dates = dates[inds]
    Y_sort = Y[ : , inds, : ]
    ### to separate out dates and years
    #dates = np.empty(ndates)
    #years = np.empty(ndates)
    #for i in range(ndates):
    #    temp_str = str(head[i,2])
    #    years[i] = int(temp_str[0:4])
    #    dates[i] = int(temp_str[5:7])    

    npix = ncol*nrow
    x_coords = np.empty(npix)
    y_coords = np.empty(npix)
    ## if we start with line 0
    ## this will give the beginning y of the chunk
    start_row = line*nrow
    
    for i in range(nrow):
        ## get the actual pixel coordinates in the larger tile
        start = i*ncol
        end = (i+1)*ncol
        y_coords[start:end] = i + start_row
        x_coords[start:end] = range(ncol)

    if Y is not None:
        logger.debug('Read in Y from cache file')
        
    return Y_sort, dates, x_coords, y_coords
