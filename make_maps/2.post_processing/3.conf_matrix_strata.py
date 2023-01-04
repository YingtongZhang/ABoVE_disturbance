
# coding: utf-8

# ## post-processing check

from osgeo import gdal, gdal_array
#from collections import Counter, Iterable
from sklearn.metrics import confusion_matrix

#from IPython.core.debugger import set_trace

#import itertools
import numpy as np
import pdb
import csv
import click
import logging
#import matplotlib.pyplot as plt
 

def post_process_smoothing(tile_name, zone, out_class_dir, out_pp_dir, output_dir):

    fill = -32767
    n = 6000
    count_all_year_cc = 0
    count_all_year_pp = 0

    # disturbance maps
    cc_file = out_class_dir + tile_name + '_strata_0nan.tif'
    cc_ds = gdal.Open(cc_file)
    cc_raster = cc_ds.ReadAsArray()
    cc_array = np.array(cc_raster)

    pp_file = out_pp_dir + tile_name + '_strata_0nan.tif'
    pp_ds = gdal.Open(pp_file)
    pp_raster = pp_ds.ReadAsArray()
    pp_array = np.array(pp_raster)                    
	    
    cc_lst = cc_array.tolist()
    pp_lst = pp_array.tolist()

    cc_lst = [y for x in cc_lst for y in x]
    pp_lst = [y for x in pp_lst for y in x]

    class_names = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]
	   

    # Compute confusion matrix
    cnf_matrix = confusion_matrix(cc_lst, pp_lst, labels=class_names)
    np.set_printoptions(precision=2)

    sum_cnf_matrix = cnf_matrix

    
    # write sum output 
    all_name = tile_name + '_cmat.csv'
    outfile = output_dir + all_name
        
    with open(outfile, 'w', newline='') as csvfile:
        wr = csv.writer(csvfile, delimiter=' ', quotechar='|', quoting=csv.QUOTE_MINIMAL)
        wr.writerows(sum_cnf_matrix)                   

@click.command()
@click.option('--tile_name', default='Bh13v15', help='Name of the tile, for example: Bh13v15')
@click.option('--zone', default='AK', help='Alaska(AK) or Canada(CA)')


def main(tile_name, zone):
    out_classes_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/'.format(tile_name)
    out_pp_dir = r'/projectnb/landsat/projects/ABOVE/CCDC/{0}/validation/remap/'.format(tile_name)
    output_dir = r'/projectnb/landsat/users/zhangyt/above/post_processing/analysis/conf_mtx/changed_strata/{0}/'.format(zone)
    
    post_process_smoothing(tile_name, zone, out_classes_dir, out_pp_dir, output_dir)
    

if __name__ == "__main__":
    main()

