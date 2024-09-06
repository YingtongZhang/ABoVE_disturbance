Bash scripts to call the Python backend to run CCDC and map output predictions including disturbance metrics.
DSM - 12/19/17

Directory listing:
create_params.sh - A helper script to SubmitYATSM.sh to create the .yaml parameter file.
make_summ_table.sh - A script that calls yatsm make hdf to make a HDF5 file containing all of the peak-summer greenness reflectance values for a tile.
map_table.sh - A script that calls yatsm map, rmse, or change to get the predictions or metrics from the summary table.
run_yatsm_par.sh - A bash script to call yatsm line - run CCDC reading in the NetCDF4 data.
setup_yatsm.sh - A simple script to make links and setup a directory to run scripts for a tile.
SubmitYATSM.sh - A script that runs create_params.sh and run_yatsm_par.sh - currently out of date. 
test_yatsm.sh - A helper script to check the output of run_yatsm_par.sh.
