
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


out_dir="/discover/nobackup/projects/landsatts/CCDC/${in_name}"

if [ ! -d $out_dir ]; then
        mkdir -m 755 $out_dir
fi

in_dir="$HOME/codes/dsm/above/run_ccdc"

ln -s $in_dir/create_params.sh $out_dir/create_params.sh
ln -s $in_dir/test_yatsm.sh $out_dir/test_yatsm.sh
ln -s $in_dir/SubmitYATSM.sh $out_dir/SubmitYATSM.sh
ln -s $in_dir/MapYATSM.sh $out_dir/MapYATSM.sh
ln -s $in_dir/run_yatsm_par.sh $out_dir/run_yatsm_par.sh
ln -s $in_dir/make_summ_table.sh $out_dir/make_summ_table.sh
