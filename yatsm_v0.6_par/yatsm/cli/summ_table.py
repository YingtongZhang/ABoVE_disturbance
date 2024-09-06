""" Command line interface for creating maps of YATSM algorithm output
"""
import logging

import click
import numpy as np
from osgeo import gdal
import pdb
import os

## relative local function
from . import options
from ..mapping import make_hdf, get_prediction,get_rmse,get_change_mags,get_change_mags_list

gdal.AllRegister()
gdal.UseExceptions()

logger = logging.getLogger('yatsm')

## these are the arguments given - choose either hdf, map, change, rmse
@click.command(short_help='Make summ_table of YATSM output for a given date')
@click.argument('map_type', metavar='<map_type>',
                type=click.Choice(['hdf', 'map', 'change', 'rmse']))
@options.arg_output
@options.opt_rootdir
@options.opt_resultdir
@options.opt_exampleimg
@options.opt_date_format
@options.opt_nodata
@options.opt_format
@click.option('--warn-on-empty', is_flag=True,
              help='Warn user when reading in empty results files')
@click.option('--band', '-b', multiple=True, metavar='<band>', type=int,
              callback=options.valid_int_gt_zero,
              help='Bands to export for coefficient/prediction maps')
@click.pass_context

## function to switch to the right mode
def summ_table(ctx, map_type, output,
        root, result, image, date_frmt, ndv, gdal_frmt, warn_on_empty,
        band):
    """
    Summ Table types: hdf, map

    \b
    Examples:
    > yatsm summ_table
    ... --band 3 --band 4 --band 5 --ndv -9999
    ... coef 2000-01-01 coef_map.gtif

    \b
    Notes:
        - Image predictions will not use categorical information in timeseries
          models.
    """
    if len(band) == 0:
        band = 'all'

    ## file name will be the last file after cutting off the extension
    tile = str(os.path.splitext(output)[0].split("/")[-1]).strip()

    ## if type hdf then we make the HDF5 table
    band_names = None
    if map_type == 'hdf':
        ## open up the example file if it exists
        try:
            image_ds = gdal.Open(image, gdal.GA_ReadOnly)
        except RuntimeError as err:
            raise click.ClickException('Could not open example image for reading '
                                   '(%s)' % str(err))
        
        make_hdf(result, image_ds,band,output)
    ## case of map can make a tif for each year 
    ## from the peak summer reflectance of the CCDC fits
    elif map_type == 'map':
        print("Type map specified. Here we go....")
        for year in np.arange(1984,2015):
            out_loc = "{0}/{1}_{2}.tif".format(root,tile,year)
            get_prediction(year=year, hdf_file=output,out_tif=out_loc,bands=band)

    ## for rmse we make a tif containing the model rmse for that year
    elif map_type == 'rmse':
        print("Type rmse specified. Here we go....")
        for year in np.arange(1984,2015):
            out_loc = "{0}/{1}.{2}.rmse.tif".format(root,tile,year)
            get_rmse(year=year, hdf_file=output,out_tif=out_loc,bands=band)
    ## change maps makes tifs of change metrics across whole time series
    elif map_type == 'change':
        print("Type change specified. Start your engines....")
        #get_change_mags(output, root, ndv=-9999)
        get_change_mags_list(output, root, ndv=-9999)
    else:
        print("Incorrect map type option specified. Game over.")
  
    image_ds = None
