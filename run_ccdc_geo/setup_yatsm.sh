#!/bin/bash -l

## We check to make sure there is an argument to the script - should be one argument for the tile name
if [ -z "$1" ]
then
echo Usage:  "./setup_yatsm.sh in_name"
## exit script if it doesnt find the arguments
exit
else
in_name=$1
fi


out_dir="./ccdc_${in_name}"

if [ ! -d $out_dir ]; then
	mkdir $out_dir
fi

### important update this with the location of your repo
in_dir="/usr2/faculty/dsm/codes/above/run_ccdc"

ln -s $in_dir/create_params.sh $out_dir/create_params.sh
ln -s $in_dir/gen_date_file.sh $out_dir/gen_date_file.sh
ln -s $in_dir/test_yatsm.sh $out_dir/test_yatsm.sh
ln -s $in_dir/run_yatsm_par.sh $out_dir/run_yatsm_par.sh
ln -s $in_dir/make_summ_table.sh $out_dir/make_summ_table.sh
ln -s $in_dir/map_table.sh $out_dir/map_table.sh
