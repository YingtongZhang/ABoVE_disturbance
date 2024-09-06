#!/bin/bash

echo "Job starting on $HOSTNAME"


start_run=$1
end_run=$2

echo "Starting on $start_run and ending on $end_run"

## setup output directory

work_dir="/att/nobackup/dsullame/tilez_all_above"
cur_yaml="${work_dir}/above_ingest.yaml"
in_dir="/att/nobackup/dsullame/test_mirror"

##  this is the file that contains all the problem scenes to be processed still
cur_input="${work_dir}/all_scenes.txt"

export LC_ALL=en_US.utf-8
export LANG=en_US.utf-8
## this activates the virtual environment i need to run
source $HOME/miniconda3/bin/activate tilezilla

## when we start this environ we lost gdal_data
GDAL_DATA="/opt/gdal-static/share/gdal"

## go into the run directory
cd $work_dir

## export this directory as root
export root=$(readlink -f $(pwd))


count=1
for id in `cat $cur_input`; do

    if [ "$count" -ge "$start_run" -a "$count" -le "$end_run" ]; then
    ## for location of current run
      cur_in_dir=${in_dir}/${id}

      echo "tilez -C $cur_yaml ingest $cur_in_dir"
      tilez -C $cur_yaml ingest $cur_in_dir
      echo "Finished tiling ${id}"
    fi
    (( count++ ))
done
source deactivate
echo "Done with all files"
