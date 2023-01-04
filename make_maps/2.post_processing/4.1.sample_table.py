
# coding: utf-8

# ## changed pixels bf/af post-processing

# In[1]:


from osgeo import gdal, gdal_array, osr, ogr
from collections import Counter, Iterable

#from IPython.core.debugger import set_trace

import itertools
import numpy as np
import pdb
import matplotlib.pyplot as plt
import csv
import rasterio
import click
from affine import Affine
from pyproj import Proj, transform
from IPython.core.debugger import set_trace


# In[3]:


def make_sample_table(tile_name, out_class_dir, out_pp_dir, output_dir):
    
    """ extract off-diagonal pixels in bf/af post-processing confusion matrix
    
    Args:
      
    
    Returns: 
      np.ndarray: array with id, lat, lon, year, class
    
    Raises:
      KeyError: Raise KeyError when a required result output is missing
            from the saved record structure
    """
    
    
    year_avail = np.arange(1985, 2014, dtype=np.int16)
    attr = 7
    idx_start = 0
    
    for year in year_avail:
        
        print(year)
        #idx_start = 0
        
        #disturbance maps
        cl_file = out_class_dir + tile_name +'_FF_FN_NF_NN_' + str(year) + '_cl.tif'
        cl_ds = gdal.Open(cl_file)
        cl_raster = cl_ds.ReadAsArray()
        cl_array = np.array(cl_raster)
        
        #post-processing maps
        pp_file = out_pp_dir + tile_name + '_FF_FN_NF_NN_' + str(year) + '_cl_pp.tif'
        pp_ds = gdal.Open(pp_file)
        pp_raster = pp_ds.ReadAsArray()
        pp_array = np.array(pp_raster)
        
        # change all the NN_other(10-17) to one class with pixel value 9
        cl_array[cl_array > 9] = 9
        pp_array[pp_array > 9] = 9
        
        
        #get the lat/lon of the entire image 
        with rasterio.open(cl_file) as cl:
            print(cl.profile)
            T0 = cl.transform
            p1 = Proj(cl.crs)
            A = cl.read()
            
            cols, rows = np.meshgrid(np.arange(A.shape[2]), np.arange(A.shape[1]))
            # Get affine transform for pixel centres
            T1 = T0 * Affine.translation(0.5, 0.5)
            # Function to convert pixel row/column index (from 0) to easting/northing at centre
            rc2en = lambda r, c: (c, r) * T1
            # All eastings and northings (there is probably a faster way to do this)
            eastings, northings = np.vectorize(rc2en, otypes=[np.float, np.float])(rows, cols)
            # Project all longitudes, latitudes
            p2 = Proj(proj='latlon',datum='WGS84')
            lons, lats = transform(p1, p2, eastings, northings)   ## lons: 6000*6000; lats: 6000*6000
            
        
        class_bf = np.array([3, 3, 3, 4, 4, 4, 5, 5, 5, 6, 6, 6, 8, 9])
        class_af = np.array([4, 5, 6, 3, 5, 6, 3, 4, 6, 3, 4, 5, 9, 8])
        #class_bf = np.array([8, 9])
        #class_af = np.array([9, 8])
        
        
        #start the processing
        for i in np.arange(0, 14, dtype=np.int16):
            print(i)
            
            out_tab = case_switch(idx_start, attr, year, class_bf[i], class_af[i], cl_array, pp_array, lons, lats)
            #concatenate the class
            if i == 0:
                out_list_tmp = out_tab
            else:
                out_list_tmp = np.concatenate((out_list_tmp, out_tab))
            
            #id start continuously
            if out_list_tmp.size == 0:
                continue
            else:
                idx_start = out_list_tmp[-1, 0] + 1
               
                
        print(out_list_tmp)
        print(len(out_list_tmp))
        
        
        # concatenate the yearly data
        if year == 1985:
            out_list = out_list_tmp
        else:
            out_list = np.concatenate((out_list, out_list_tmp))
        
        # id start continuously for year
        if out_list.size == 0:
            continue
        else:
            idx_start = out_list[-1, 0] + 1
        

    # save the np file by tile    
    file_name = output_dir + tile_name +'_chngpix'
    np.save(file_name, out_list)
       


# In[4]:


def case_switch(idx_start, attr, year, class_bf, class_af, cl_array, pp_array, lons, lats):

    """ Define the disturbance class and change class because of post-processing
      FF -- decline: 1 growth: 2
      FN -- fire: 3 insect: 4 logging: 5 others: 6
      NF -- regrowth: 7
      NN -- fire: 8 comb: 9-17

      *no changes between FF two classes and neither NF
      FN                                                   NN
      3--4: 1     4--3: 4     5--3: 7     6--3: 10         8--(9, 17): 13
      3--5: 2     4--5: 5     5--4: 8     6--4: 11         (9,17)--8: 14
      3--6: 3     4--6: 6     5--6: 9     6--5: 12
    
    """
    fill = -9999
    
    # re-class the change type on the off-diagonal
    if (class_bf == 3) & (class_af == 4):
        chn_type = 1
    elif (class_bf == 3) & (class_af == 5):
        chn_type = 2
    elif (class_bf == 3) & (class_af == 6):
        chn_type = 3
    elif (class_bf == 4) & (class_af == 3):
        chn_type = 4
    elif (class_bf == 4) & (class_af == 5):
        chn_type = 5
    elif (class_bf == 4) & (class_af == 6):
        chn_type = 6
    elif (class_bf == 5) & (class_af == 3):
        chn_type = 7
    elif (class_bf == 5) & (class_af == 4):
        chn_type = 8
    elif (class_bf == 5) & (class_af == 6):
        chn_type = 9
    elif (class_bf == 6) & (class_af == 3):
        chn_type = 10
    elif (class_bf == 6) & (class_af == 4):
        chn_type = 11
    elif (class_bf == 6) & (class_af == 5):
        chn_type = 12
    elif (class_bf == 8) & (class_af == 9):
        chn_type = 13
    elif (class_bf == 9) & (class_af == 8):
        chn_type = 14


    indices = np.where((cl_array == class_bf) & (pp_array == class_af))      # two arrays -- row/col
    #print(indices[0], indices[1])
    length = len(indices[0])
    
    # give lons and lats the pix idx
    cl_lon, cl_lat = lons[indices[0], indices[1]], lats[indices[0], indices[1]]
    
    # write to np.array -- with id, lat1(int), lat2(dec), lon1(int), lon2(dec), year, class
    out_tab = np.ones((length, attr), dtype=np.int32) * int(fill)

    for idx in np.arange(0, length, dtype=np.int32):
        lon_i = int(cl_lon[idx])
        lon_d = int((cl_lon[idx] - int(cl_lon[idx])) * 10000)
        lat_i = int(cl_lat[idx])
        lat_d = int((cl_lat[idx] - int(cl_lat[idx])) * 10000)
        out_tab[idx,] = (idx + idx_start, year, lon_i, lon_d, lat_i, lat_d, chn_type)
    
    print(len(out_tab))
    print(out_tab)
    
    return out_tab



# In[2]:


@click.command()
@click.option('--tile_name', default='Bh13v15', help='Name of the tile, for example: Bh13v15')
#tile_name = 'Bh04v04'
#print(tile_name, "starts checking.")

# In[ ]:


def main(tile_name):
    out_classes_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_classes/'.format(tile_name)
    out_pp_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/new_map/out_pp/'.format(tile_name)
    output_dir = r'/projectnb/landsat/users/zhangyt/above/post_processing/analysis/conf_mtx/all/'
    
    make_sample_table(tile_name, out_classes_dir, out_pp_dir, output_dir)
    

if __name__ == "__main__":
    main()

