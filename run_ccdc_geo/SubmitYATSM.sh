#!/bin/bash -l
#$ -l h_rt=36:00:00
#$ -j y
#$ -N setup_yatsm
#$ -V

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
main_dir=$(readlink -f $(pwd))
in_dir="/projectnb/landsat/users/dsm/above/VRTs/${name}"
ini_file=${main_dir}/"${name}.yaml"

## make sure that the intermediate files exist before further processing
image_list=${main_dir}/${name}_inputs.csv
if [ ! -f $image_list ] 
then
	echo "No $image_list file found. Will create."
        ## create the image list file
	echo ./gen_date_file.sh $in_dir $image_list
	./gen_date_file.sh $in_dir $image_list
	
else
	echo "$image_list found will use."
fi

if [ ! -f $ini_file ] 
then
	echo "No $ini_file file found. Will create."
	## create the params file
	echo ./create_params.sh $main_dir $name $ini_file
	./create_params.sh $main_dir $name $ini_file
else
	echo "$ini_file found. Will use."
fi

## make the output directory
out_dir="./${name}"
if [ ! -d $out_dir ]; then
	mkdir $out_dir
fi

module purge
source activate yatsm_v0.6

job=1
njob=200
## for job in $(seq 1 $njob); do
    qsub -j y -V -l h_rt=48:00:00 -l mem_total=98G -N yatsm_$job -b y yatsm -v line --resume $ini_file $job $njob
##done

source deactivate
