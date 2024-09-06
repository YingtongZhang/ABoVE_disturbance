#!/bin/bash -l


t="$1"

if [ -z $t ]; then
echo "Usage: copy_files.sh tile"
exit
fi

### found this function to sftp files easily
in_dir="${t}/out_tif"
out_dir="/projectnb/modislc/projects/above/validation/val_dat_121617"

scp -r ${in_dir}/${t}_*tif ${in_dir}/${t}.*tif dsm@geo.bu.edu:${out_dir}/
