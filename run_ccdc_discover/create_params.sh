
main_dir=$1
tile_name=$2
ini_file=$3
in_dir=$4

## create the ini file based on the template provided
cat -v > $ini_file << done

# Example configuration file for YATSM line runner
#
# This configuration includes details about the dataset and how YATSM should
# run

# Version of config
version: "0.7.0"

dataset:
    # Text file containing dates and images
    input_dir: "${in_dir}"
    # Input date format
    date_format: "%Y%j"
    # Output location
    output: "${main_dir}/output"
    # Output file prefix (e.g., [prefix]_[chunk].npz)
    output_prefix: "yatsm_c"
    # Total number of bands
    n_bands: 8
    # Mask band (e.g., Fmask)
    mask_band: 8
    # List of integer values to mask within the mask band
    mask_values: [2, 3, 4, 255]
    # Valid range of band data
    # specify 1 range for all bands, or specify ranges for each band
    ## need a special one for the cloud mask - the others have random 0's as missing data - will fix this
    min_values: 0
    max_values: 10000
    # Indices for multi-temporal cloud masking (indexed on 1)
    green_band: 2
    swir1_band: 5

# Parameters common to all timeseries analysis models within YATSM package
YATSM:
    algorithm: "CCDCesque"
    prediction: "glmnet_Lasso20"
    design_matrix: "1 + x + harm(x, 1) + harm(x, 2) + harm(x, 3)"
    num_coef: 8
    reverse: False
    commission_alpha:
    # Re-fit each segment, adding new coefficients & RMSE info to record
    refit:
        prefix: [robust]
        prediction: [rlm_maxiter10]
        stay_regularized: [True]

# Parameters for CCDCesque algorithm -- referenced by "algorithm" key in YATSM
CCDCesque:
    init:  # hyperparameters
        consecutive: 6
        threshold: 2.5
        min_obs: 12
        min_rmse: 150
        test_indices: [2, 4, 5]
        retrain_time: 1461.00
        screening: RLM
        screening_crit: 400.0
        slope_test: True
        remove_noise: True
        dynamic_rmse: False

# Section for phenology fitting
phenology:
    enable: False
    init:
        # Specification for dataset indices required for EVI based phenology monitoring
        red_index: 2
        nir_index: 3
        blue_index: 0
        # Scale factor for reflectance bands
        scale: 0.0001
        # You can also specify index of EVI if contained in dataset to override calculation
        evi_index:
        evi_scale:
        # Number of years to group together when normalizing EVI to upper and lower percentiles
        year_interval: 3
        # Upper and lower percentiles of EVI used for max/min scaling
        q_min: 10
        q_max: 90

# Section for training and classification
classification:
    # Training data file
    training_image: "/home/ceholden/Documents/yatsm/examples/training_data.gtif"
    # Training data masked values
    roi_mask_values: [0, 255]
    # Date range:
    training_start: "1999-01-01"
    training_end: "2001-01-01"
    training_date_format: "%Y-%m-%d"
    # Cache X feature input and y labels for training data image into file?
    cache_training:

done
