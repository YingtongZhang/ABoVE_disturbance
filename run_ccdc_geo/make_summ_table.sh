#!/bin/bash -l
#$ -V
#$ -l h_rt=48:00:00
#$ -N YATSM_map
#$ -j y
#$ -l mem_total=98G

## this is a script to read the YATSM model and extract tables of peak-summer reflectances and break dates
if [ -z "$1" ]
then
	echo Usage \"./make_summ_table.sh scene_name 
	exit 1
else
	name=$1
fi

#Root directory where the images are stored
cur_dir=$(readlink -f $(pwd))
root="$cur_dir"

#Name of result folder where YATSM/CCDC results are stored
results_dir="/projectnb/landsat/users/dsm/above/ccdc_develop/ccdc_Bh04v06"
results="${results_dir}/output"

#Location of example image to grab extent and projection
#example=`echo $vrt_list | cut -f2 -d" "`
example="${results_dir}/old_results/Bh04v06_2000.tif"

module purge
source activate yatsm_v0.6_par

i="hdf"
output="./${name}.h5"
echo yatsm summ_table --root $root -r $results -i $example $i $output
yatsm summ_table --root $root -r $results -i $example $i $output

source deactivate

echo "Finished processing tile $name"
