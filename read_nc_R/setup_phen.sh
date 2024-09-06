
#!/bin/bash -l

## We check to make sure there is an argument to the script - should be one argument for the tile name
if [ -z "$1" ]
then
echo Usage:  "./setup_phen.sh in_name"
## exit script if it doesnt find the arguments
exit
else
in_name=$1
fi


out_dir="/discover/nobackup/projects/landsatts/PHEN/${in_name}"

if [ ! -d $out_dir ]; then
        mkdir $out_dir
fi

in_dir="$HOME/codes/dsm/above/read_nc"

ln -s $in_dir/qsub.bat $out_dir/qsub.bat
ln -s $in_dir/read_nc.sh $out_dir/read_nc.sh
ln -s $in_dir/test_results.sh $out_dir/test_results.sh
