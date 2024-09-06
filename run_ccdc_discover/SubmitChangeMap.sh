#!/bin/bash

#SBATCH --ntasks=60
#SBATCH --time=09:00:00
#SBATCH -J map_yatsm
#SBATCH -o map_yatsm.%j

## this is a script to process the YATSM model to estimate breakpoints related to disturbance
## the first argument is for the name of the scene
if [ -z "$1" ]
then
	echo Usage \"./MapYATSM.sh scene_name 
	exit 1
else
	name=$1
fi

#Root directory where the images are stored
#cur_dir=$(readlink -f $(pwd))

cur_dir="/discover/nobackup/projects/landsatts/CCDC/$name"
root="$cur_dir"

#Name of result folder where YATSM/CCDC results are stored
results="$root/output"


#Location of example image to grab extent and projection
vrt_dir="/discover/nobackup/projects/landsatts/ABoVEgridLandsat/VRTs/$name"
#input_list="${cur_dir}/${name}_inputs.csv"
vrt_list=`find $vrt_dir -name *.vrt`
example=`echo $vrt_list | cut -f2 -d" "`
## this will get out the VRT on the second line of the input list as an example 
#example=`awk 'NR==2' $input_list | cut -d"," -f3`

#start and end
start=1984-01-01
end=2015-01-01

# module purge
source activate yatsm_v0.6_par

out_dir=${cur_dir}/${name}_preds

## make the directory
if [ ! -d $out_dir ]; then mkdir ${out_dir}; fi

## make a prediction for every month from 2000 to 2015
## loop through the years
#for (( y=2000 ; y<2015 ; y++ )) ; do
y=2000
	## correction for leap years
	if [ $[$y % 400] -eq "0" ] ; then
		leap_flag=1
	elif [ $[$y % 4] -eq "0" ] ; then
		if [ $[$y % 100] -ne "0" ] ; then
			leap_flag=1
		else
			leap_flag=0
		fi
	else
		leap_flag=0
	fi

	if [ $leap_flag -eq "1" ] ; then
		mons=(31 29 31 30 31 30 31 31 30 31 30 31) 
	else
		mons=(31 28 31 30 31 30 31 31 30 31 30 31) 
	fi

	## print out the value for roughly the middle of each month
	cur_date=15
	m=7
	#for (( m=0 ; m<12 ; m++ )) ; do 

		cur_mon=$(( m+1 ))
		echo "Processing prediction for date ${y}-${cur_date}"
		output="${out_dir}/pred_mon_${y}_${cur_mon}.tif"
		echo yatsm map --root $root -r $results -i $example --before --after --ndvi -9999 predict "${y}-08-${cur_date}" $output
 	#	yatsm map --root $root -r $results -i $example --before --after --ndv -9999 predict "${y}-08-${cur_date}" $output
		output="${out_dir}/coef_${y}_${cur_mon}.tif"
	#	 yatsm map --root $root -r $results -i $example -c intercept -c slope --ndv -9999 coef "${y}-08-${cur_date}" $output
		cur_date=$(( $cur_date + ${mons[${m}]} ))
		
	#done

#done

output="${out_dir}/num_dist.tif"
#echo yatsm map --root $root -r $results -i $example --after 1999-12-31 -b 3 -b 4 -b 5 $output
yatsm changemap --root $root -r $results -i $example all $start $end $output

#output="${out_dir}/first_dist.tif"
#echo yatsm map --root $root -r $results -i $example --after 1999-12-31 -b 3 -b 4 -b 5 $output
#yatsm changemap --root $root -r $results -i $example first $start $end $output


source deactivate
