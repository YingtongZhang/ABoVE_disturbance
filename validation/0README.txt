These R scripts are meant to produce a sample of pixels according to predefined strata.
DSM - 12/19/17

Directory listing:
create_valid_shp.R - Read in the disturbance metrics and sample according to predefined strata. Convert to a shapefile.
do_above_val.R - Once you have the disturbance values extracted from the map, read in the interpreter (reference) csv files and perform accuracy assessment.
extract_csv_from_shp.R - Takes the shapefile with the validation points and extracts out values from any number of rasters
run_csv_script.sh - A bash script to run extract_csv_from_shp.R
run_script.sh - A bash script to run create_valid_shp.R

