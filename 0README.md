The goal of the ABoVE project was to generate a suite of Landsat products covering a large region of the Northwest of North America.
DSM - 12/15/17

Directory listing:
ingest_files_geo - Mostly bash scripts to run tilezilla on GEO. Tilezilla takes in the original Landsat data and reprojects and tiles everything. It was available on Chris Holdens git repo.
make_nc_discover - A C program that uses MPI to read in all of the scenes and reformat them to be date-indexed and output as NetCDF files.
misc_bash_scripts - A set of useful bash scripts to do a variety of tasks.
read_nc_R - R scripts to read in the NetCDF files and calculate phenology and greenness metrics.
rf_classify - R scripts to run RandomForests classifier and interpret the results.
run_ccdc_geo - Bash scripts to run CCDC and check the outputs.
tile_layers - Bash scripts to reproject and tile assorted ancillary layers
tilez_run_scripts_adapt - Another set of bash scripts that run tilezilla but on NASA ADAPT.
validation - Mostly R scripts to sample validation points according to pre-defined strata and create shapefiles for interpretations.i
yatsm_v0.6_par - DSM adaptation of Chris Holdens YATSM Python 3.6 implementation of CCDC. Reads in NC chunks and outputs fitted time series models in Numpy NPZ format.

Data were processed with the following steps:
1) Mark Carroll downloaded all available Landsat 4, 5 and 7 data 1984-2014 in UTM projection from the USGS.These were originally in HDF format and had to be translated into TIFF files.

2) Reprojected and tiled all of the Landsat data into 280 6000x6000 pixel grids in AEA projection using a Python 2.7 program Tilezilla from Chris Holden. Created VRT files containing all 7 TM/ETM+ bands plus the FMASK for each date.  FMASK was run at the USGS with default parameters. This procedure was carried out on the NASA ADAPT computing system.

3) Due to problems using ADAPT we moved the data to the NASA Discover computing system and recreated the VRT files.

4) Developed a C program to re-format the Landsat data to be date-indexed and saved as NetCDF files.  Each 2-row chunk was read in from all bands and dates for that tile and saved in its own NC file. The code was run on 600 nodes using MPI to have enough memory to read in each tile.  Each NetCDF file contained between 50-250MB of data depending on the number of dates.  Each tile took 5-8 hours to process.

5) CCDC was run on each 2-row chunk of NC data in Python 3.6 using an adapted version of Chris Holdens YATSM code.  The fitted time series model outputs were saved as npz files and the total archive took up about 30GB per tile.  The data were read in and processed using GNU parallel with 30 processors each processing 100 row-chunks of data.  Each tile took 12-20 hours to process.

6) Two post-processing steps were developed in Python 3.6.  The first step combines the 3000 two-row chunks that come out of CCDC into a single HDF5 file containing the metrics to create synthetic observations and perform change detection.  The second step reads in the HDF5 table and produces maps for that tile of either synthetic observations, model RMSE, or disturbance metrics.  These codes use PyTable and contain several options:  create the HDF table, write out synthetic observations to file, write out rmse to file, and do change detection. The output HDF5 tables contained annual peak summer (julian date 212) reflectance predictions from CCDC for all 7 bands as well as the 7 RMSE values for the current segment in the model. If there was a break in a model that year, the julian date of that break was also recorded. From there we created maps of the 7 band synthetic observations and the disturbance metrics.  These codes run in about 6 hours and take up about 20 GB using a single compute node.

7) Phenology and greenness trends can be produced with the same set of R-scripts.  They are run last because the phenology needs the disturbance information.  These read in the NC files from step 4 and calculate EVI and NDVI for each cloud-free value. The phenology code creates 66 phenology metrics including num_obs, rsquare, min/max EVI, long term mean SOS and EOS, and annual SOS and EOS.  The peak greenness metrics are produced for each row chunk and contain 7 bands for the max-NDVI observation plus the date and num_obs during the DOY 180-240 period.  These codes are run using doPar and foreach parallelization with at least 20 cores needed per node and take about 5 hours to run per tile.   


