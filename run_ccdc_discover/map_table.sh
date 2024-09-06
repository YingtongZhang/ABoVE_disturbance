#!/bin/bash -l

######### 
## For Discover 
## Maps the result of summ_table
## Takes one arg - tile name
#SBATCH --ntasks 22
#SBATCH --time=10:00:00
#SBATCH -o extract.%j
#SBATCH -J MAP_TAB

##########
### GEO qsub directives
# #$ -V
# #$ -l h_rt=3:00:00
# #$ -N YATSM_map
# #$ -j y
# #$ -l mem_total=98G
# #$ -pe omp 16

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

#Root is actually being used as the location of the outputs
results="$root/out_tif"
if [ ! -d $results ]; then
	mkdir -m 755 $results
fi

module purge
source activate yatsm_v0.6_par


i="map"

for i in "map" "change"; do 
output="$root/${name}.h5"
echo yatsm summ_table --root $root $i $output
yatsm summ_table --root $root $i $output

done

source deactivate

echo "Finished processing tile $name"
