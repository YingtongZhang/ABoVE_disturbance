""" Command line interface for running YATSM on image lines """
import datetime as dt
import logging
import os
import time
import pdb

import click
import numpy as np
import pandas as pd

from IPython.core.debugger import Pdb

from . import options
from ..cache import test_cache
from ..config_parser import parse_config_file
from ..errors import TSLengthException
from ..io import get_image_attribute, mkdir_p, read_line
from ..utils import (distribute_jobs, get_output_name, get_image_IDs,
                     csvfile_to_dataframe, copy_dict_filter_key,convert_to_ord)
from ..algorithms import postprocess
from ..version import __version__

## for parallel job running
#from joblib import Parallel, delayed
#import multiprocessing as mtl 

logger = logging.getLogger('yatsm')

@click.command(short_help='Run YATSM on an entire image line by line')
@options.arg_config_file
@options.arg_job_number
@options.arg_total_jobs
@click.option('--check_cache', is_flag=True,
              help='Check that cache file contains matching data')
@click.option('--resume', is_flag=True,
              help='Do not overwrite preexisting results')
@click.option('--do-not-run', is_flag=True,
              help='Do not run YATSM (useful for just caching data)')
@click.pass_context
def line(ctx, config, job_number, total_jobs,
         resume, check_cache, do_not_run):

    # Parse config
    cfg = parse_config_file(config)
   
    logger.info('Job {i} of {n} - using config file {f}'.format(
        i=job_number, n=total_jobs, f=config))

    # Make sure output directory exists and is writable
    output_dir = cfg['dataset']['output']
    try:
        mkdir_p(output_dir)
    except OSError as err:
        raise click.ClickException('Cannot create output directory %s (%s)' %
                                   (output_dir, str(err)))
    if not os.access(output_dir, os.W_OK):
        raise click.ClickException('Cannot write to output directory %s' %
                                   output_dir)

    # Calculate the lines this job ID works on
    nchunk = 3000
    try:
        job_lines = distribute_jobs(job_number, total_jobs, nchunk)
    except ValueError as err:
        raise click.ClickException(str(err))
    logger.debug('Responsible for lines: {l}'.format(l=job_lines))

    # Begin process
    start_time_all = time.time()

    ### adding the parallel core outside of the for loop - 08/02/17 
    #parallelizer = Parallel(n_jobs=24,verbose=100)
    #accumulator = 0.
    #n_iter = 0
    #while accumulator < 1000:
    #    results = parallel(delayed(sqrt)(accumulator + i ** 2)
    #        for i in range(5))
    #        accumulator += sum(results)  # synchronization barrier
    #        n_iter += 1

    #with Parallel(n_jobs=24,verbose=100) as parallel:
    #numThread=12
    #pool = mtl.Pool(numThread)

    for line in job_lines:        
        
        out = get_output_name(cfg['dataset'], line)
        if resume:
            try:
                np.load(out)
            except:
                pass
            else:
                logger.debug('Already processed line %s' % line)
                continue

        logger.debug('Running line %s' % line)
        start_time = time.time()

        Y, dates, x_coords, y_coords = read_line(line, cfg['dataset'])
        #print(x_coords,y_coords)
        print(dates)
        ## jump through some hoops to get date_arr in the proper format
        ## not a python programmer - probably a faster way to do this
        date_str = np.char.mod('%d', dates)
        ndates = len(dates)
        dates = np.zeros(ndates,dtype=np.int64)
   
        for x in range(ndates):
            dates[x] = convert_to_ord(date_str[x])


        logger.debug('Took {s}m to read in the data'.format(
            s=round((time.time() - start_time)/60.0, 2)))

        if do_not_run:
            continue
        if cfg['YATSM']['reverse']:
            Y = np.fliplr(Y)

        # Create output metadata to save
        algo = cfg['YATSM']['algorithm']

        algo_cfg = cfg[cfg['YATSM']['algorithm']]
        md = {
            # Do not copy over prediction objects
            # Pickled objects potentially unstable across library versions
            'YATSM': copy_dict_filter_key(cfg['YATSM'], '.*object.*'),
            algo: cfg[algo].copy()
        }
        
        output = []
        # output = [None] * 10
        ## for non parallel version
        for col in np.arange(Y.shape[-1]):
            cur_out = do_yatsm_loop(Y.take(col, axis=2),dates,x_coords[col],y_coords[col],col,cfg)
            if cur_out is not None:
                output.extend(cur_out)

        ### parallel version using Parallel function from joblib - takes about an hour per chunk
        #output = Parallel(n_jobs=24)(delayed(do_yatsm_loop)
	    #	(Y.take(col, axis=2),dates,x_coords[col],y_coords[col],col,cfg) 
        #        	for col in np.arange(Y.shape[-1]))

        ### trying to get it to work with Pool from multiprocessing
        #cur_range = np.arange(Y.shape[-1])
        #cur_range = np.arange(0,10)
        #output = [pool.starmap(do_yatsm_loop,zip(Y.take(cur_range,axis=2),dates,x_coords[cur_range],y_coords[cur_range],cur_range,cfg))]
        
        #output = [pool.apply_async(do_yatsm_loop, args=(Y.take(col, axis=2),dates,x_coords[col],y_coords[col],col,cfg)) for col in cur_range]
        #for col in cur_range:
        #    output[col] = pool.apply_async(do_yatsm_loop, args=(Y.take(col, axis=2),dates,x_coords[col],y_coords[col],col,cfg))

        ### the process method from multiprocessing- would spawn spurious processes
        #output = Process(target=do_yatsm_loop, args=(Y.take(cur_range,axis=2),dates,x_coords[cur_range],y_coords[cur_range],cur_range,cfg))
        #output.start()
        #output.join()

        logger.debug('    Saving YATSM output to %s' % out)
        np.savez(out,
            record=np.array(output),
            version=__version__,
            metadata=md)

        run_time = time.time() - start_time
        logger.debug('Line %s took %s m to run' % (line, round(run_time/60.0,2)))

    ## end for loop
    #pool.close()
    #pool.terminate()
    
    logger.info('Completed {n} lines in {m} minutes'.format(
                n=len(job_lines),
                m=round((time.time() - start_time_all) / 60.0, 2)))

def do_yatsm_loop(_Y,dates,x_coord,y_coord,col,cfg):

    model = cfg['YATSM']['algorithm_object']
    algo_cfg = cfg[cfg['YATSM']['algorithm']]
    yatsm = model(estimator=cfg['YATSM']['estimator'],
                  **algo_cfg.get('init', {}))

    num_coef = cfg['YATSM']['num_coef']
    # Setup algorithm and create design matrix (if needed)
    try:
#        X = yatsm.setup(dates, **cfg)
        X = coefficient_matrix(dates, num_coef)
    except Exception as exc:
        Pdb().set_trace()

    if hasattr(X, 'design_info'):
        cfg['YATSM']['design'] = X.design_info.column_name_indexes
    else:
        cfg['YATSM']['design'] = {}

    # Flip for reverse
    if cfg['YATSM']['reverse']:
        X = np.flipud(X)

    #_Y = Y.take(col, axis=2)
    # Preprocess
    _X, _Y, _dates = yatsm.preprocess(X, _Y, dates, **cfg['dataset'])

    #pdb.set_trace()

    # Run model
    yatsm.px = x_coord
    yatsm.py = y_coord
    # print("Processing pixel: ",yatsm.px,yatsm.py)

    #Pdb().set_trace()

    try:
        yatsm.fit(_X, _Y, _dates, **algo_cfg.get('fit', {}))
    except TSLengthException:
        # continue
        return yatsm.record

    if yatsm.record is None or len(yatsm.record) == 0:
        # continue
        return yatsm.record 

    # Postprocess
    if cfg['YATSM'].get('commission_alpha'):
        yatsm.record = postprocess.commission_test(
            yatsm, cfg['YATSM']['commission_alpha'])

    for prefix, estimator, stay_reg, fitopt in zip(
            cfg['YATSM']['refit']['prefix'],
            cfg['YATSM']['refit']['prediction_object'],
            cfg['YATSM']['refit']['stay_regularized'],
            cfg['YATSM']['refit']['fit']):
        yatsm.record = postprocess.refit_record(
            yatsm, prefix, estimator,
            fitopt=fitopt, keep_regularized=stay_reg)


    # print(yatsm.px,yatsm.py)
    # output.extend(yatsm.record)

    return yatsm.record

## dsm fixed a bug in this function on 8/21/17
def coefficient_matrix(dates, num_coefficients):
    """
    Fourier transform function to be used for the matrix of inputs for
    model fitting
    Args:
        dates: list of ordinal dates
        num_coefficients: how many coefficients to use to build the matrix
    Returns:
        Populated numpy array with coefficient values
    """
    w = 2 * np.pi / 365.25

    matrix = np.zeros(shape=(len(dates), num_coefficients), order='F')

    matrix[:, 0] = 1.0
    matrix[:, 1] = dates
    matrix[:, 2] = np.cos(w * dates)
    matrix[:, 3] = np.sin(w * dates)

    if num_coefficients >= 6:
        matrix[:, 4] = np.cos(2 * w * dates)
        matrix[:, 5] = np.sin(2 * w * dates)

    if num_coefficients >= 8:
        matrix[:, 6] = np.cos(3 * w * dates)
        matrix[:, 7] = np.sin(3 * w * dates)

    return matrix

