#!/usr/bin/env python

"""
@author: Jordan Graesser
Date Created: 4/17/2015

Heavily modified 9/20/17 
by Damien Sulla-Menashe
"""

import os
import sys
import time
import argparse
# import xml.etree.ElementTree as ET
from copy import copy
from operator import itemgetter
import psutil
import pdb

# NumPy
try:
    import numpy as np
except ImportError:
    raise ImportError('NumPy must be installed')

# PyTables
try:

    import tables

    tables.parameters.MAX_NUMEXPR_THREADS = 8
    tables.parameters.MAX_BLOSC_THREADS = 8

except ImportError:
    raise ImportError('PyTables must be installed')

tables.parameters.MAX_NUMEXPR_THREADS = 4
tables.parameters.MAX_BLOSC_THREADS = 4


## setup the classes to contain all the metadata
## not all of these are used by ABOVE
class ChunkInfo(tables.IsDescription):
    
    id = tables.UInt16Col()
    y_coords = tables.StringCol(10)
    x_coords = tables.StringCol(10)
    years = tables.StringCol(1000)
    bands = tables.StringCol(100)

class GridInfo(tables.IsDescription):
    
    tile = tables.StringCol(10)
    extent = tables.StringCol(500)
    projection = tables.StringCol(500)
    pix_size = tables.StringCol(100)
    grid_size= tables.StringCol(100)
    design = tables.StringCol(100)
    doy = tables.UInt16Col()
   
class OrderInfo(tables.IsDescription):

    index = tables.UInt32Col()
    jd = tables.UInt16Col()
    jdr = tables.UInt32Col()
    year = tables.UInt16Col()


class SensorInfo(tables.IsDescription):

    """Table columns"""

    Id = tables.StringCol(100)
    filename = tables.StringCol(100)
    storage = tables.StringCol(10)
    left = tables.Float64Col()
    top = tables.Float64Col()
    right = tables.Float64Col()
    bottom = tables.Float64Col()
    cell_size = tables.Float32Col()
    rows = tables.UInt16Col()
    rows_r = tables.UInt16Col()
    columns = tables.UInt16Col()
    columns_r = tables.UInt16Col()
    jd = tables.UInt16Col()
    jdr = tables.UInt32Col()
    utm = tables.UInt8Col()
    latitude = tables.StringCol(1)
    grid = tables.StringCol(2)
    bands = tables.UInt16Col()
    projection = tables.StringCol(1000)
    attribute = tables.StringCol(30)
    sensor = tables.StringCol(20)
    real_sensor = tables.StringCol(20)
    satellite = tables.StringCol(10)
    year = tables.UInt16Col()
    date = tables.StringCol(10)
    clear = tables.Float32Col()
    cblue = tables.UInt8Col()
    blue = tables.UInt8Col()
    green = tables.UInt8Col()
    red = tables.UInt8Col()
    nir = tables.UInt8Col()
    midir = tables.UInt8Col()
    farir = tables.UInt8Col()
    rededge = tables.UInt8Col()
    rededge2 = tables.UInt8Col()
    rededge3 = tables.UInt8Col()
    niredge = tables.UInt8Col()
    wv = tables.UInt8Col()              # Sentinel-2 water vapor band
    cirrus = tables.UInt8Col()
    zenith_angle = tables.Float64Col()
    azimuth_angle = tables.Float64Col()


class SetFilter(object):

    def set_filter(self, image_extension, **kwargs):

        """
        Sets the array storage filter
        Args:
            image_extension (str)
        """

        self.filters = tables.Filters(**kwargs)

        #self.atom = tables.Atom.from_dtype(np.dtype(STORAGE_DICT[image_extension]))
        self.atom = tables.Atom.from_dtype(np.dtype(image_extension))


def get_mem():

    """Gets the resident set size (MB) for the current process"""

    this_proc = psutil.Process(os.getpid())

    return this_proc.get_memory_info()[0] / 1E6


class BaseHandler(SetFilter):

    def add_array(self, image_array=None,
                  array_storage=None,
                  image_shape=None,
                  array_type='c',
                  cloud_band_included=False,
                  **kwargs):

        """
        Adds an image array to the HDF file
        Args:
            image_array (Optional[ndarray]): A ndarray. Default is None.
            array_storage (Optional[str]):
            image_shape (Optional[tuple]):
            array_type (Optional[str]): Choices are ['a', 'c', 'e'].
            cloud_band_included (Optional[bool])
            kwargs (Optional): Parameters for the Atom filter.
        """

        # Set the atom filter
        self.set_filter(array_storage, **kwargs)

       
        if array_type == 'c':

            array = self.h5_file.create_carray("/{}".format(self.node_name),
                        "Ref",
                        atom=self.atom,
                        shape=image_shape,
                        filters=self.filters,
                        title="Ref")

            # Enter the data into the carray.
            if isinstance(image_array, np.ndarray):

                if len(image_array.shape) > 2:

                    for bi, band in enumerate(image_array):
                        array[bi] = band

                else:
                    array[:] = image_array

            else:

               print("No Numpy ND array found. Error!") 

    ## end function add array


    def update_array(self, image2enter):

        if '_mask' in self.image_node:
            d_type = 'byte'
        else:
            d_type = 'float32'

        existing_array = self.get_array(self.image_node)

        array2enter_info = raster_tools.ropen(image2enter)
        array2enter = array2enter_info.read(bands2open=1, d_type=d_type)

        if '_mask' in self.image_node:

            iarg, jarg = np.where(((existing_array == 255) & (array2enter > 0) & (array2enter < 255)) |
                                  ((existing_array == 0) & (array2enter > 0) & (array2enter < 255)))

        else:
            iarg, jarg = np.where((existing_array == 0) & (array2enter != 0))

        existing_array[iarg, jarg] = array2enter[iarg, jarg]

        array2enter_info.close()

        # import matplotlib.pyplot as plt
        #
        # plt.subplot(121)
        # plt.imshow(existing_array)
        # plt.subplot(122)
        # plt.imshow(array2enter)
        # plt.show()
        # sys.exit()

    def get_array(self, array_name, z=None, i=None, j=None, rows=None, cols=None,
                  x=None, y=None, maximum=False, info_dict=None, time_formatted=False,
                  start_date=None, end_date=None):

        """
        Gets a ndarray
        Args:
            array_name (str): The node name of the array to get.
            z (int): The starting band position.
            i (int): The starting row position.
            j (int): The starting column position.
            rows (int): The number of rows to get.
            cols (int): The number of columns to get.
            x (float): The x coordinate to index.
            y (float): The y coordinate to index.
            info_dict (Optional[dict])
            time_formatted (Optional[bool])
            start_date (Optional[str]): yyyy/mm/dd
            end_date (Optional[str]): yyyy/mm/dd
            maximum (Optional[bool]): Whether to return the array maximum instead of the array. Default is False.
        Returns:
            A ``rows`` x ``cols`` ndarray.
        Examples:
            >>> from mappy.utilities.landsat.pytables import manage_pytables
            >>>
            >>> pt = manage_pytables()
            >>> pt.open_hdf_file('/2000_p228.h5', mode='r')
            >>>
            >>> # open a 100 x 100 array
            >>> pt.get_array('/2000/p228r83/ETM/p228r83_etm_2000_0124_tcap_wetness', 0, 0, 100, 100)
        """

        self.z = z
        self.i = i
        self.j = j
        self.x = x
        self.y = y
        self.info_dict = info_dict
        self.start_date = start_date
        self.end_date = end_date

        if (isinstance(self.x, float) and isinstance(self.y, float)) or \
                (isinstance(self.x, list) and isinstance(self.y, list) and isinstance(self.x[0], float)):
            self._get_offsets()

        ### dsm removed since cant use that function
        #if isinstance(self.start_date, str):
        #    self.get_time_range()

        # names = [x['Id'] for x in table.where("""(attribute == "ndvi") & (path == 228) & (row == 83)""")]
        # names = [x['Id'] for x in table.where("""(path == 228) & (row == 83)""")]

        if maximum:

            try:
                return self.h5_file.get_node(array_name).read()[i:i+rows, j:j+cols].max()
            except NameError:
                raise NameError('\nThe array does not exist.\n')

        else:

            try:

                if time_formatted:

                    h5_node = self.h5_file.get_node(array_name).read()

                    if isinstance(self.i, int) and not isinstance(rows, int):

                        return self.h5_file.get_node(array_name).read()[self.i,
                               self.index_positions[0]:self.index_positions[-1]]

                    elif (isinstance(self.y, float) and not isinstance(rows, int)) or \
                            (isinstance(self.y, list) and isinstance(self.y[0], float) and not isinstance(rows, int)):

                        if isinstance(self.x, list):
                            self.i_ = [(i_ * self.info_dict['columns_r']) + j_ for i_, j_ in zip(self.i_, self.j_)]
                            return np.array([h5_node[i, self.index_positions[0]:self.index_positions[-1]+1]
                                             for i in self.i_], dtype='float32')
                        else:
                            self.i_ = (self.i_ * self.info_dict['columns_r']) + self.j_
                            return h5_node[self.i_, self.index_positions[0]:self.index_positions[-1]+1]

                    elif isinstance(self.i, int) and isinstance(rows, int):

                        return self.h5_file.get_node(array_name).read()[self.i:self.i+rows,
                               self.index_positions[0]:self.index_positions[-1]]

                    elif isinstance(self.y, float) and isinstance(rows, int):

                        self.i_ = (self.i_ * self.info_dict['columns_r']) + self.j_

                        return self.h5_file.get_node(array_name).read()[self.i_:self.i_+rows,
                               self.index_positions[0]:self.index_positions[-1]]

                else:

                    if isinstance(self.z, int) or isinstance(self.z, list):

                        if self.z == -1:
                            return self.h5_file.get_node(array_name).read()[:, self.i:self.i+rows, self.j:self.j+cols]
                        else:

                            return self.h5_file.get_node(array_name).read()[self.z,
                                                                            self.i:self.i+rows,
                                                                            self.j:self.j+cols]

                    else:
                        return self.h5_file.get_node(array_name).read()[self.i:self.i+rows, self.j:self.j+cols]

            except NameError:
                raise NameError('\nThe array does not exist.\n')

    def _get_offsets(self):

        image_list = [self.info_dict['left'], self.info_dict['top'],
                      self.info_dict['right'], self.info_dict['bottom'],
                      -self.info_dict['cell_size'], self.info_dict['cell_size']]

        if isinstance(self.x, list):

            self.i_ = []
            self.j_ = []

            for xs, ys in zip(self.x, self.y):

                __, __, j_, i_ = vector_tools.get_xy_offsets(image_list=image_list,
                                                             x=xs,
                                                             y=ys,
                                                             check_position=False)

                self.i_.append(i_)
                self.j_.append(j_)

        else:

            __, __, self.j_, self.i_ = vector_tools.get_xy_offsets(image_list=image_list,
                                                                   x=self.x,
                                                                   y=self.y,
                                                                   check_position=False)


class ArrayHandler(object):

    """
    A class to handle PyTables Arrays
    Examples:
        >>> from mappy.utilities.pytables import ArrayHandler
        >>>
        >>> a = np.random.random((100, 100, 100)).astype(np.float32)
        >>>
        >>> with ArrayHandler('/some_file.h5') as ea:
        >>>     ea.create_array(a.shape)
        >>>
        >>> with ArrayHandler('/some_file.h5') as ea:
        >>>     ea.add_array(a)
    """

    def __init__(self,
                 h5_file,
                 array_type='c',
                 complib='blosc',
                 complevel=5,
                 shuffle=True,
                 dtype='float32',
                 group_name=None):

        self.h5_file = h5_file
        self.array_type = array_type
        self.dtype = dtype
        self.group_name = group_name

        if os.path.isfile(self.h5_file):
            self.file_mode = 'a'
        else:
            self.file_mode = 'w'

        self._set_filter(complib=complib, complevel=complevel, shuffle=shuffle)

        # Open the HDF5 file.
        self._open_file()

        # Open the metadata table.
        self._open_table()

    def _open_table(self):

        # Get the nodes
        self.nodes = [node._v_title for node in self.h5_file.walk_nodes()]

        if 'metadata' in self.nodes:

            self.h5_table = self.h5_file.root.metadata
            self.column_names = self.h5_table.colnames

    def _open_file(self):
        self.h5_file = tables.open_file(self.h5_file, mode=self.file_mode)

    def evaluate(self, expression, **kwargs):

        """Evaluates an expression"""

        texpr = tables.Expr(expression, **kwargs)

        return texpr.eval()

    def create_array(self, array_shape, data_name=None):

        if not isinstance(data_name, str):
            data_name = 'data'

        if isinstance(self.group_name, str):

            # Check if the group exists.
            if not [True for node in self.h5_file.walk_nodes() if node._v_pathname == '/{}'.format(self.group_name)]:
                self.h5_file.create_group('/', self.group_name)

        # self.h5_file.create_carray(self.node_name, self.name_dict['filename'],
        #                            atom=self.atom,
        #                            shape=(self.image_info.rows, self.image_info.cols),
        #                            filters=self.filters,
        #                            title=self.name_dict['attribute'],
        #                            obj=self.image_info.read(bands2open=1))

        if self.array_type == 'c':

            if isinstance(self.group_name, str):

                self.data_storage = self.h5_file.create_carray('/{}'.format(self.group_name),
                                                               data_name,
                                                               atom=self.atom,
                                                               shape=array_shape,
                                                               filters=self.filters)

            else:

                self.data_storage = self.h5_file.create_carray(self.h5_file.root,
                                                               data_name,
                                                               atom=self.atom,
                                                               shape=array_shape,
                                                               filters=self.filters)

        elif self.array_type == 'e':

            if isinstance(self.group_name, str):

                self.data_storage = self.h5_file.create_earray('/{}'.format(self.group_name),
                                                               data_name,
                                                               atom=self.atom,
                                                               shape=array_shape,
                                                               filters=self.filters)

            else:

                self.data_storage = self.h5_file.create_earray(self.h5_file.root,
                                                               data_name,
                                                               atom=self.atom,
                                                               shape=array_shape,
                                                               filters=self.filters)

    def add_array(self, array2add, z=None, i=None, j=None, nz=None, nr=None, nc=None):

        if self.array_type == 'e':

            if isinstance(self.group_name, str):
                self.h5_file.get_node('/{}/data'.format(self.group_name)).append(array2add)
            else:
                self.h5_file.root.data.append(array2add)

        else:

            if not isinstance(z, int) and not isinstance(i, int):

                if isinstance(self.group_name, str):
                    self.data_storage[:] = array2add
                else:
                    self.h5_file.root.data[:] = array2add

            else:

                if isinstance(self.group_name, str):

                    if isinstance(z, int):
                        self.data_storage[z:z+nz, i:i+nr, j:j+nc] = array2add
                    else:
                        self.data_storage[i:i+nr, j:j+nc] = array2add

                else:

                    if isinstance(z, int):
                        self.h5_file.root.data[z:z+nz, i:i+nr, j:j+nc] = array2add
                    else:
                        self.h5_file.root.data[i:i+nr, j:j+nc] = array2add

        # for i in xrange(0, array2add.shape[0]):
        #     self.data_storage.append(array2add[i][None])

    ## read array will read the table no matter what the data type and return the correct type
    def read_array(self, is_3d=False, z=None, i=None, j=None, nz=None, nr=None, nc=None, is_flat=False, d_type='float32'):

        """
        Args:
            is_3d (Optional[bool])
        """

        if not isinstance(nz, int):
            nz = 1

        if not isinstance(nr, int):
            nr = 1

        if not isinstance(nc, int):
            nc = 1

        if is_3d:

            if isinstance(self.group_name, str):

                if not isinstance(z, int):
                    return self.h5_file.get_node(self.group_name).read()[:].astype(d_type)
                else:
                    return self.h5_file.get_node(self.group_name)[z:z+nz, i:i+nr, j:j+nc].astype(d_type)

            else:

                if not isinstance(z, int):
                    return self.h5_file.root.data[:].astype(d_type)
                else:
                    return self.h5_file.root.data[z:z+nz, i:i+nr, j:j+nc].astype(d_type)

        else:

            if isinstance(self.group_name, str):

                if is_flat:
                    return self.h5_file.get_node(self.group_name)[i].astype(d_type)
                else:

                    if isinstance(i, np.ndarray) and not isinstance(j, np.ndarray):
                        return self.h5_file.get_node(self.group_name)[i, :].astype(d_type)
                    elif not isinstance(i, np.ndarray) and isinstance(j, np.ndarray):
                        return self.h5_file.get_node(self.group_name)[:, j].astype(d_type)
                    elif isinstance(i, int) and not isinstance(j, int):
                        return self.h5_file.get_node(self.group_name)[i:i+nr, :].astype(d_type)
                    elif not isinstance(i, int) and isinstance(j, int):
                        return self.h5_file.get_node(self.group_name)[:, j:j+nc].astype(d_type)
                    elif isinstance(i, int) and isinstance(j, int):
                        return self.h5_file.get_node(self.group_name)[i:i+nr, j:j+nc].astype(d_type)
                    else:
                        return self.h5_file.get_node(self.group_name)[:].astype(d_type)

            else:

                if isinstance(i, np.ndarray) and not isinstance(j, np.ndarray):
                    return self.h5_file.root.data[i, :].astype(d_type)
                elif not isinstance(i, np.ndarray) and isinstance(j, np.ndarray):
                    return self.h5_file.root.data[:, j].astype(d_type)
                elif isinstance(i, int) and not isinstance(j, int):
                    return self.h5_file.root.data[i:i+nr, :].astype(d_type)
                elif not isinstance(i, int) and isinstance(j, int):
                    return self.h5_file.root.data[:, j:j+nc].astype(d_type)
                elif isinstance(i, int) and isinstance(j, int):
                    return self.h5_file.root.data[i:i+nr, j:j+nc].astype(d_type)
                else:
                    return self.h5_file.root.data[:].astype(d_type)

    def _set_filter(self, **kwargs):

        self.filters = tables.Filters(**kwargs)

        self.atom = tables.Atom.from_dtype(np.dtype(self.dtype))

    def close(self):
        self.h5_file.close()

    def __enter__(self):
        return self

    def __exit__(self, type, value, traceback):
        self.close()

## the main class we work with
class manage_pytables(BaseHandler):

    """
    A class to manage the PyTables information and file
    """

    def __init__(self):

        self.time_stamp = time.asctime(time.localtime(time.time()))

        self.h5_file = None

    ## opens an hdf file for reading and writing
    def open_hdf_file(self, hdf_file, title='Landsat', mode='a'):

        """
        Opens an HDF file
        Args:
            hdf_file (str): The HDF file to open.
            title (Optional[str]): The HDF table title.
            mode (Optional[str])
        Attributes:
            hdf_file (object)
        """

        if hasattr(self.h5_file, 'isopen'):

            if not self.h5_file.isopen:
                self.h5_file = tables.open_file(hdf_file, mode=mode, title=title)

        else:
            self.h5_file = tables.open_file(hdf_file, mode=mode, title=title)

        self.nodes = [node._v_pathname for node in self.h5_file.walk_nodes()
                      if hasattr(node, 'title') and ('metadata' not in node._v_pathname)]

    def set_metadata(self, in_dict, **kwargs):

        """
        Sets the table metadata
        Args:
            meta_dict (Optional[dict])
        """
        ## creates an internal copy of in_dict in the self.meta_dict object
        ## each call will erase the previous version of meta_dict
        if isinstance(in_dict, dict):
            self.meta_dict = copy(in_dict)
        else:
            self.meta_dict = dict()

        if kwargs:

            for key, value in kwargs.items():
                self.in_dict[key] = value


    def get_groups(self, grid_info):

        self.grid_info = grid_info
        # self.sensor = sensor

        # The end node group name - could setup multiple groups
        self.node_name = 'C{}'.format(self.grid_info['id'])

    def add_groups(self):

        """
        Adds the groups to the HDF file
        """

        # ID group
        try:
            self.h5_file.get_node("/{}".format(self.node_name))
        except:
            self.h5_file.create_group('/',self.node_name)
        ## could add additional groups here

    def remove_array_group(self, group2remove):

        """
        Args:
            group2remove (str)
        Example:
            pt.open_hdf_file('py_table.h5', 'Landsat')
            pt.remove_array_group('/2000/p218r63/ETM/p218r63_etm_2000_1117_ndvi')
            pt.close_hdf()
        """

        try:

            print('Removing array {} ...'.format(group2remove))

            self.h5_file.remove_node(group2remove)

        except:
            print('{} does not exist'.format(group2remove))

    def remove_table_group(self, path2remove, row2remove, sensor2remove, year2remove, date2remove):

        """
        Args:
            path2remove (int)
            row2remove (int)
            sensor2remove (str)
            year2remove (str)
            date2remove (str)
        Example:
            pt.open_hdf_file('py_table.h5', 'Landsat')
            pt.remove_table_group(218, 63, 'ETM', '2000', '1117')
            pt.close_hdf()
        """

        try:
            table = self.h5_file.root.metadata
        except:
            print('The table does not have metadata.')
            return

        full_list = True

        while full_list:

            result = [ri for ri, row in enumerate(table.iterrows()) if row['path'] == int(path2remove) and
                      row['row'] == int(row2remove) and row['sensor'] == str(sensor2remove).upper() and
                      row['year'] == str(year2remove) and row['date'] == str(date2remove)]

            # Remove only one row because the
            #   table is updated.
            if result:

                print('Removing {} from table...'.format(','.join([str(path2remove), str(row2remove),
                                                                   sensor2remove, year2remove, date2remove])))

                table.remove_row(result[0])

            else:
                full_list = False

    def add_table(self, table_name='metadata', separate_rows=False):

        """
        Adds the table to the HDF file
        """

        nodes = [node._v_title for node in self.h5_file.walk_nodes()]

        if table_name == 'metadata':

            if 'metadata' not in nodes:
                self.table = self.h5_file.create_table('/', table_name, ChunkInfo, table_name)
            else:
                self.table = self.h5_file.root.metadata

             # Check if the id has been entered.
            table_query = """(id == {:d})""".format(self.meta_dict['id'])

            if not [x for x in self.table.where(table_query)]:

                pointer = self.table.row
                for mkey, mvalue in self.meta_dict.items():
                    pointer[mkey] = mvalue

                pointer.append()

        elif table_name == 'grid':

            if 'grid' not in nodes:
                self.table = self.h5_file.create_table('/', table_name, GridInfo, table_name)
            else:
                self.table = self.h5_file.root.grid

            pointer = self.table.row
            for mkey, mvalue in self.meta_dict.items():
                pointer[mkey] = mvalue

            pointer.append()


        # Commit changes to disk.
        self.table.flush()
        self.h5_file.flush()

        self.table = None
        pointer = None
        nodes = None

    def set_image_node(self, file_name, extension, strip_str):

        d_name, f_name = os.path.split(file_name)
        self.image_base, __ = os.path.splitext(f_name)

        if strip_str:
            self.image_base = self.image_base[:-6]

        if isinstance(extension, str):
            self.image_node = '{}/{}_{}'.format(self.node_name, self.image_base, extension)
        else:
            self.image_node = '{}/{}'.format(self.node_name, self.image_base)

    def check_array_node(self, file_name, extension=None, strip_str=False):

        """
        Checks if the image array has already been created
        Args:
            file_name (str): The base file name to open.
        Returns:
            True if the array has been created and False if it does not exist
            '/utm/latitude/grid/Landsat/p224r84_oli_tirs_2016_0710_ndvi'
        """

        self.array_node = None

        self.set_image_node(file_name, extension, strip_str)

        try:
            self.array_node = self.h5_file.get_node(self.image_node)
            return True
        except:
            return False

    def query_file(self, start_id, end_id):

        self.table = self.h5_file.root.metadata

        existing_chunks = [table_row['id']
                          for table_row in self.table.where("""(id >= {:d}) & (id <= {:d})""".format(start_id,end_id))]

        for existing_chunk in existing_chunks:
            print(existing_chunk)

    def write2file(self, out_name, year):

        """
        Example:
            >>> from mappy.utilities.landsat.pytables import manage_pytables
            >>> pt = manage_pytables()
            >>> pt.open_hdf_file('/2000_p228.h5', 'Landsat')
            >>> pt.write2file('p226r80_etm_2000_0110_ndvi.tif', '/out_image.tif', '2000', 226, 80, 'ETM')
        """

        try:
            table = self.h5_file.root.metadata
        except:
            print('The table does not have metadata.')
            return

        # First get the image information.
        result = [(x['filename'], x['rows'], x['columns'], x['bands'], x['projection'], x['cell_size'], \
                   x['left'], x['top'], x['right'], x['bottom'], x['storage'])
                  for x in table.where("""(filename == "%s")""" % file_name)][0]

        group_name = '/{}/p{:d}r{:d}/{}/{}'.format(str(year), int(path), int(row), sensor.upper(),
                                                   result[0].replace('.tif', ''))

        array2write = self.get_array(group_name, 0, 0, result[1], result[2])

        # Create the output file.
        # out_rst = raster_tools.create_raster(out_name, None, rows=result[1], cols=result[2], bands=result[3],
        #                                      projection=result[4], cellY=result[5], cellX=-result[5], left=result[6],
        #                                      top=result[7])

        with raster_tools.ropen('create', rows=result[1], cols=result[2], bands=result[3], 
                                projection=result[4], cellY=result[5], cellX=-result[5], 
                                left=result[6], top=result[7], right=result[8], 
                                bottom=result[9], storage=result[10]) as o_info:
    
            raster_tools.write2raster(array2write, out_name, o_info=o_info, flush_final=True)
    
            self.close_hdf()
        
        o_info = None

    def close_hdf(self):

        """
        Closes the HDF file
        """

        if hasattr(self, 'h5_file'):

            if hasattr(self.h5_file, 'isopen'):

                if self.h5_file.isopen:
                    self.h5_file.close()

        self.h5_file = None

def _examples():

    sys.exit("""\
    # Insert two images into a HDF file.
    pytables.py -i /p228r78_2000_0716.tif /p228r78_2000_0920.tif --hdf /2000_p228.h5
    # Remove an array group.
    pytables.py -i dummy --hdf /2000_p218.h5 --method remove --group /2000/p218r63/ETM/p218r63_etm_2000_1117_ndvi
    # Remove a table row group.
    pytables.py -i dummy --hdf /2000_p218.h5 --method remove --table_row 281,63,ETM,2000,1117
    # Write an array to a GeoTiff
    pytables.py -i p226r80_etm_2000_0110_ndvi.tif -o /out_name.tif --hdf /2000_p226.h5 --method write --table_row 226,80,ETM,2000,0110
    """)

## main code
def main():

    parser = argparse.ArgumentParser(description='Manage PyTables',
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument('-e', '--examples', dest='examples', action='store_true', help='Show usage examples and exit')
    parser.add_argument('-i', '--inputs', dest='inputs', help='The input image list', default=[], nargs='+')
    parser.add_argument('-o', '--output', dest='output', help='The output image with -m write', default=None)
    parser.add_argument('--hdf', dest='hdf', help='The HDF file to open', default=None)
    parser.add_argument('-t', '--title', dest='title', help='The table title', default='Landsat')
    parser.add_argument('-m', '--method', dest='method', help='The tables method', default='put',
                        choices=['put', 'remove', 'write'])
    parser.add_argument('-g', '--group', dest='group', help='The array group to remove', default=None)
    parser.add_argument('-tr', '--table_row', dest='table_row', help='The table row list to remove', default=None)

    args = parser.parse_args()

    if args.examples:
        _examples()

    if args.table_row:
        args.table_row = args.table_row.split(',')
        args.table_row[0] = int(args.table_row[0])
        args.table_row[1] = int(args.table_row[1])

    print('\nStart date & time --- (%s)\n' % time.asctime(time.localtime(time.time())))

    start_time = time.time()
    ## call the main function
    pytables(args.inputs, args.hdf, title=args.title, method=args.method,
             group=args.group, table_row=args.table_row, out_name=args.output)

    print('\nEnd data & time -- (%s)\nTotal processing time -- (%.2gs)\n' %
          (time.asctime(time.localtime(time.time())), (time.time()-start_time)))

if __name__ == '__main__':
    main()
