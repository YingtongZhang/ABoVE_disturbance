#!/bin/bash -l

#SBATCH -N 1
#SBATCH --ntasks-per-node=22
#SBATCH --time=8:00:00
#SBATCH -o table.%j
#SBATCH -J SM_TBLE

## this is a script to read the YATSM model and extract tables of peak-summer reflectances and break dates
if [ -z "$1" ]
then
	echo Usage \"./make_summ_table.sh scene_name 
	exit 1
else
	name=$1
fi

#Root directory where the images are stored
root="/discover/nobackup/projects/landsatts/CCDC/$name"


#Name of result folder where YATSM/CCDC results are stored
results="$root/output"

#Location of example image to grab extent and projection
vrt_dir="/discover/nobackup/projects/landsatts/ABoVEgridLandsat/VRTs/$name"

vrt_list=`find $vrt_dir -name *.vrt`
example=`echo $vrt_list | cut -f3 -d" "`

module purge
source activate yatsm_v0.6_par

output="./${name}.h5"
echo yatsm summ_table --root $root -r $results -i $example hdf $output
yatsm summ_table --root $root -r $results -i $example hdf $output

source deactivate

echo "Finished processing tile $name"
