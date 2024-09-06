""" Utilities for turning YATSM record results into maps

Also stores definitions for model QA/QC values
"""
import logging

import numpy as np
import pdb

from ..regression import design_to_indices

logger = logging.getLogger('yatsm')

# QA/QC values for segment types
MODEL_QA_QC = {
    'INTERSECT': 3,
    'AFTER': 2,
    'BEFORE': 1
}


def find_result_attributes(results, bands, coefs, prefix=''):
    """ Returns attributes about the dataset from result files

    Args:
        results (list): Result filenames
        bands (list): Bands to describe for output
        coefs (list): Coefficients to describe for output
        prefix (str, optional): Search for coef/rmse results with given prefix
            (default: '')

    Returns:
        tuple: Tuple containing ``list`` of indices for output bands and output
            coefficients, ``bool`` for outputting RMSE, ``list`` of coefficient
            names, ``str`` design specification, and ``OrderedDict``
            design_info (i_bands, i_coefs, use_rmse, design, design_info)

    Raises:
        KeyError: Raise KeyError when a required result output is missing
            from the saved record structure

    """
    _coef = prefix + 'coef' if prefix else 'coef'
    _rmse = prefix + 'rmse' if prefix else 'rmse'

    # How many coefficients and bands exist in the results?
    n_bands, n_coefs = None, None
    design = None
    ## initialize the num coef 
    ## so we can run the model even if metadata is corrupt
    num_coef = 4
    for r in results:
        try:
            _result = np.load(r)
            rec = _result['record']
            # Handle pre/post v0.5.4 (see issue #53)
            if 'metadata' in _result.files:
                logger.debug('Finding X design info for version>=v0.5.4')
                md = _result['metadata'].item()
                #design = md['YATSM']['design']
                ## temporary fix as the design isnt getting added to the metadata properly
                #design = {'Intercept': 0, 'harm(x, 1)[1]': 3, 'harm(x, 1)[0]': 2, 'x': 1}

                ### this needs to be commented back in later
                num_coef = md['YATSM']['num_coef']
                design = build_design(num_coef)
                design_str = md['YATSM']['design_matrix']
            else:
                logger.debug('Finding X design info for version<0.5.4')
                #design = _result['design_matrix'].item()
                #design_str = _result['design'].item()
                design = build_design(4)
                design_str = "1 + x + harm(x,1)"
        except:
            continue

        
        if not rec.dtype.names:
            continue

        if _coef not in rec.dtype.names or _rmse not in rec.dtype.names:
            if prefix:
                logger.error('Coefficients and RMSE not found with prefix %s. '
                             'Did you calculate them?' % prefix)
            raise KeyError('Could not find coefficients ({0}) and RMSE ({1}) '
                           'in record'.format(_coef, _rmse))

        try:
            n_coefs, n_bands = rec[_coef][0].shape
        except:
            continue
        else:
            break

    if n_coefs is None:
        raise KeyError('Could not determine the number of coefficients')
    if n_bands is None:
        raise KeyError('Could not determine the number of bands')
    if design is None:
        raise KeyError('Design matrix specification not found in results')

    # How many bands does the user want?
    if bands == 'all':
        i_bands = range(0, n_bands)
    else:
        # NumPy index on 0; GDAL on 1 -- so subtract 1
        i_bands = [b - 1 for b in bands]
        if any([b > n_bands for b in i_bands]):
            raise KeyError('Bands specified exceed size of bands in results')

    # How many coefficients did the user want?
    use_rmse = False
    if coefs:
        if 'rmse' in coefs or 'all' in coefs:
            use_rmse = True
        i_coefs, coef_names = design_to_indices(design, coefs)
    else:
        i_coefs, coef_names = None, None

    logger.debug('Bands: {0}'.format(i_bands))
    if coefs:
        logger.debug('Coefficients: {0}'.format(i_coefs))

    return (i_bands, i_coefs, use_rmse, coef_names, design_str, design)


def find_indices(record, date):
    """ Yield indices matching time segments for a given date

    Args:
        record (np.ndarray): Saved model result
        date (int): Ordinal date to use when finding matching segments
        
        If date does not intersect a model, use
            previous non-disturbed time segment.  Otherwise first look before and then after.

    Yields:
        tuple: (int, np.ndarray) the QA value and indices of `record`
            containing indices matching criteria. If `before` or `after` are
            specified, indices will be yielded in order of least desirability
            to allow overwriting -- `before` indices, `after` indices, and
            intersecting indices.

    """

    ## get all the pixels
    min_y = min(record['py'])
    ncols = 6000
    nrows = 2
    npix = ncols*nrows
    pix_ind = (record['py']-min_y)*ncols + record['px']

    # Model before, as long as it didn't change
    before_index = (record['end'] <= date) & (record['break'] == 0)
    # First model starting after date specified
    after_index = (record['start'] >= date)
    # Model intersecting date
    cur_index = (record['start'] <= date) & (record['end'] >= date) & ~before_index & ~after_index

    all_index = before_index | after_index | cur_index

    index = np.where(all_index)[0]
    _, _index = np.unique(pix_ind[index], return_index=True)

    yield index[_index]

## end find_indices

## build a design for the model depending on number of coef
def build_design(num_coef):
    
    design = {'Intercept': 0, 'x': 1, 'harm(x, 1)[0]': 2, 'harm(x, 1)[1]': 3}
    
    if num_coef >= 6:
        design = {'Intercept': 0, 'x': 1, 'harm(x, 1)[0]': 2, 'harm(x, 1)[1]': 3,
                'harm(x, 2)[0]': 4, 'harm(x, 2)[1]': 5}
    if num_coef >= 8:
        design = {'Intercept': 0, 'x': 1, 'harm(x, 1)[0]': 2, 'harm(x, 1)[1]': 3,
                'harm(x, 2)[0]': 4, 'harm(x, 2)[1]': 5, 'harm(x, 3)[0]': 6, 'harm(x, 3)[1]': 7}

    return design
