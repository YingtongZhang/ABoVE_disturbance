""" Module for making map products from YATSM results

Contains functions used in "map" command line interface script.
"""

from .changes import get_change_mags,get_change_mags_list
from .classification import get_classification
from .prediction import get_prediction,get_rmse
from .summary import make_hdf
from .pytables import ArrayHandler, manage_pytables

__all__ = [
    'get_classification',
    'get_prediction',
    'get_rmse',
    'get_change_mags',
    'get_change_mags_list',
    'make_hdf',
    'manage_pytables',
    'ArrayHandler'
]