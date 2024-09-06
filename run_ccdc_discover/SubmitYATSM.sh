#!/bin/bash -l
#SBATCH --ntasks=1 
#SBATCH -o submit_%j
#SBATCH -J SUB_YAT

## this is a script to process the YATSM model to estimate breakpoints related to disturbance
## the first argument is for the name of the scene
if [ -z "$1" ]
then
	echo Usage \"./SubmitYATSM.sh scene_name 
	exit 1
else
	name=$1
fi

## important paths - should be fairly constant
main_dir="/discover/nobackup/projects/landsatts/CCDC/${name}"
#in_dir="/projectnb/landsat/users/dsm/above/VRTs/${name}"
in_dir="/discover/nobackup/projects/landsatts/NC_FILES/${name}/output/"
ini_file=${main_dir}/"${name}.yaml"

if [ ! -f $ini_file ] 
then
	echo "No $ini_file file found. Will create."
	## create the params file
	echo ./create_params.sh $main_dir $name $ini_file $in_dir
	./create_params.sh $main_dir $name $ini_file $in_dir
else
	echo "$ini_file found. Will use."
fi

## make the output directory
out_dir="${main_dir}/output"
if [ ! -d $out_dir ]; then
	mkdir -m 755 $out_dir
fi

#njob=576
# job=1
job=1
njob=30
#njob=4
for job in $(seq 1 $njob); do
#for job in $(seq 11 30); do
echo sbatch run_yatsm_par.sh $ini_file $job
sbatch run_yatsm_par.sh $ini_file $job

done

