""" Functions related to writing to and retrieving from cache files
"""
import os

import pdb
import numpy as np
## for the netcdf ncdump function
import datetime as dt  # Python standard library datetime  module
from netCDF4 import Dataset  # http://code.google.com/p/netcdf4-python/

from .log_yatsm import logger

_image_ID_str = 'image_IDs'

def get_line_cache_name(in_path, row):
    """ Returns cache filename for specified config and line number

    Args:
        dataset_config (dict): configuration information about the dataset
        n_images (int): number of images in dataset
        row (int): line of the dataset for output
        nbands (int): number of bands in dataset

    Returns:
        str: filename of cache file

    """
    start_row = row*2
    end_row = row*2 + 1
    
    if not in_path:
        return

    filename = '%i-%i.nc' % (start_row, end_row)

    return os.path.join(in_path, filename)


def get_line_cache_pattern(row, nbands, regex=False):
    """ Returns a pattern for a cache file from a certain row

    This function is useful for finding all cache files from a line, ignoring
    the number of images in the file.

    Args:
        row (int): line of the dataset for output
        nbands (int): number of bands in dataset
        regex (bool, optional): return a regular expression instead of glob
            style (default: False)

    Returns:
        str: filename pattern for cache files from line ``row``

    """
    wildcard = '.*' if regex else '*'
    pattern = 'yatsm_r{l}_n{w}_b{b}.npy.npz'.format(
        l=row, w=wildcard, b=nbands)

    return pattern


def test_cache(dataset_config):
    """ Test cache directory for ability to read from or write to

    Args:
        dataset_config (dict): dictionary of dataset configuration options

    Returns:
        tuple: tuple of bools describing ability to read from and write to
            cache directory

    """
    # Try to find / use cache
    read_cache = False
    write_cache = False

    cache_dir = dataset_config.get('cache_line_dir')
    if cache_dir:
        # Test existence
        if os.path.isdir(cache_dir):
            if os.access(cache_dir, os.R_OK):
                read_cache = True
            if os.access(cache_dir, os.W_OK):
                write_cache = True
            if read_cache and not write_cache:
                logger.warning('Cache directory exists but is not writable')
        else:
            # If it doesn't already exist, can we create it?
            try:
                os.makedirs(cache_dir)
            except:
                logger.warning('Could not create cache directory')
            else:
                read_cache = True
                write_cache = True

    logger.debug('Attempt reading in from cache directory?: {b}'.format(
        b=read_cache))
    logger.debug('Attempt writing to cache directory?: {b}'.format(
        b=write_cache))

    return read_cache, write_cache


def read_cache_file(cache_filename):
    """ Returns image data from a cache file

    If ``image_IDs`` is not None this function will try to ensure data from
    cache file come from the list of image IDs provided. If cache file does not
    contain a list of image IDs, it will skip the check and return cache data.

    Args:
        cache_filename (str): cache filename
        image_IDs (iterable, optional): list of image IDs corresponding to data
            in cache file. If not specified, function will not check for
            correspondence (default: None)

    Returns:
        np.ndarray, or None: Return Y as np.ndarray if possible and if the
            cache file passes the consistency check specified by ``image_IDs``,
            else None

    """
    print("Reading in cache file ", cache_filename)

    nc_fid = Dataset(cache_filename, 'r')  # Dataset is the class behavior to open the file
    # and create an instance of the ncCDF4 class
    nc_attrs, nc_dims, nc_vars = ncdump(nc_fid)

    num_bands = nc_fid.dimensions['bands'].size
    num_time = nc_fid.dimensions['time'].size
    num_x = nc_fid.dimensions['x'].size
    num_y = nc_fid.dimensions['y'].size

    in_dat = nc_fid.variables['data'][ : ]
    head = nc_fid.variables['head'][ : ]

    ## can easily re-arrange these into the format we need
    # print(all_data[0,0,0, : ])

    Y = np.empty((num_bands, num_time, num_x*num_y),np.int16)

    for i in np.arange(num_time):
        for b in np.arange(num_bands):
            Y[ b, i, : ] = in_dat[ : , : , i, b ].flatten()

    return Y, head, num_x, num_y


def write_cache_file(cache_filename, Y, image_IDs):
    """ Writes data to a cache file using np.savez_compressed

    Args:
        cache_filename (str): cache filename
        Y (np.ndarray): data to write to cache file
        image_IDs (iterable): list of image IDs corresponding to data in cache
            file. If not specified, function will not check for correspondence

    """
    np.savez_compressed(cache_filename, **{
        'Y': Y, _image_ID_str: image_IDs
    })


# Cache file updating
def update_cache_file(images, image_IDs,
                      old_cache_filename, new_cache_filename,
                      line, reader):
    """ Modify an existing cache file to contain data within `images`

    This should be useful for updating a set of cache files to reflect
    modifications to the timeseries dataset without completely reading the
    data into another cache file.

    For example, the cache file could be updated to reflect the deletion of
    a misregistered or cloudy image. Another common example would be for
    updating cache files to include newly acquired observations.

    Note that this updater will not handle updating cache files to include
    new bands.

    Args:
        images (iterable): list of new image filenames
        image_IDs (iterable): list of new image identifying strings
        old_cache_filename (str): filename of cache file to update
        new_cache_filename (str): filename of new cache file which includes
            modified data
        line (int): the line of data to be updated
        reader (callable): GDAL or BIP image reader function from
            :mod:`yatsm.io.stack_line_readers`

    Raises:
        ValueError: Raise error if old cache file does not record ``image_IDs``

    """
    images = np.asarray(images)
    image_IDs = np.asarray(image_IDs)

    # Cannot proceed if old cache file doesn't store filenames
    old_cache = np.load(old_cache_filename)
    if _image_ID_str not in old_cache.files:
        raise ValueError('Cannot update cache.'
                         'Old cache file does not store image IDs.')
    old_IDs = old_cache[_image_ID_str]
    old_Y = old_cache['Y']
    nband, _, ncol = old_Y.shape

    # Create new Y and add in values retained from old cache
    new_Y = np.zeros((nband, image_IDs.size, ncol),
                     dtype=old_Y.dtype.type)
    new_IDs = np.zeros(image_IDs.size, dtype=image_IDs.dtype)

    # Check deletions -- find which indices to retain in new cache
    retain_old = np.where(np.in1d(old_IDs, image_IDs))[0]
    if retain_old.size == 0:
        logger.warning('No image IDs in common in old cache file.')
    else:
        logger.debug('    retaining {r} of {n} images'.format(
            r=retain_old.size, n=old_IDs.size))
        # Find indices of old data to insert into new data
        idx_old_IDs = np.argsort(old_IDs)
        sorted_old_IDs = old_IDs[idx_old_IDs]
        idx_IDs = np.searchsorted(sorted_old_IDs,
                                  image_IDs[np.in1d(image_IDs, old_IDs)])

        retain_old = idx_old_IDs[idx_IDs]

        # Indices to insert into new data
        retain_new = np.where(np.in1d(image_IDs, old_IDs))[0]

        new_Y[:, retain_new, :] = old_Y[:, retain_old, :]
        new_IDs[retain_new] = old_IDs[retain_old]

    # Check additions -- find which indices we need to insert
    insert = np.where(np.in1d(image_IDs, old_IDs, invert=True))[0]

    if retain_old.size == 0 and insert.size == 0:
        raise ValueError('Cannot update cache file -- '
                         'no data retained or added')

    # Read in the remaining data from disk
    if insert.size > 0:
        logger.debug('Inserting {n} new images into cache'.format(
            n=insert.size))
        insert_Y = reader.read_row(images[insert], line)
        new_Y[:, insert, :] = insert_Y
        new_IDs[insert] = image_IDs[insert]

    np.testing.assert_equal(new_IDs, image_IDs)

    # Save
    write_cache_file(new_cache_filename, new_Y, image_IDs)



def ncdump(nc_fid, verb=True):
    '''
    ncdump outputs dimensions, variables and their attribute information.
    The information is similar to that of NCAR's ncdump utility.
    ncdump requires a valid instance of Dataset.

    Parameters
    ----------
    nc_fid : netCDF4.Dataset
        A netCDF4 dateset object
    verb : Boolean
        whether or not nc_attrs, nc_dims, and nc_vars are printed

    Returns
    -------
    nc_attrs : list
        A Python list of the NetCDF file global attributes
    nc_dims : list
        A Python list of the NetCDF file dimensions
    nc_vars : list
        A Python list of the NetCDF file variables
    '''
    def print_ncattr(key):
        """
        Prints the NetCDF file attributes for a given key

        Parameters
        ----------
        key : unicode
            a valid netCDF4.Dataset.variables key
        """
        try:
            print("\t\ttype:", repr(nc_fid.variables[key].dtype))
            for ncattr in nc_fid.variables[key].ncattrs():
                print('\t\t%s:' % ncattr,\
                      repr(nc_fid.variables[key].getncattr(ncattr)))
        except KeyError:
            print("\t\tWARNING: %s does not contain variable attributes" % key)

    # NetCDF global attributes
    nc_attrs = nc_fid.ncattrs()
    if verb:
        print("NetCDF Global Attributes:")
        for nc_attr in nc_attrs:
            print('\t%s:' % nc_attr, repr(nc_fid.getncattr(nc_attr)))
    nc_dims = [dim for dim in nc_fid.dimensions]  # list of nc dimensions
    # Dimension shape information.
    if verb:
        print( "NetCDF dimension information:")
        for dim in nc_dims:
            print("\tName:", dim )
            print( "\t\tsize:", len(nc_fid.dimensions[dim]))
            print_ncattr(dim)
    # Variable information.
    nc_vars = [var for var in nc_fid.variables]  # list of nc variables
    if verb:
        print("NetCDF variable information:")
        for var in nc_vars:
            if var not in nc_dims:
                print('\tName:', var)
                print( "\t\tdimensions:", nc_fid.variables[var].dimensions)
                print( "\t\tsize:", nc_fid.variables[var].size)
                print_ncattr(var)
    return nc_attrs, nc_dims, nc_vars



