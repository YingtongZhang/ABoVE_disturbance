
## this is a script to check the YATSM model runs.  The first argument is the number of expected scenes.
if [ -z "$1" ]
then
	echo Usage \"./test_yatsm.sh num_runs tile
	exit 1
else
	num=$1
fi

tile=$2

cur_num=`ls ${tile}_phen/*.RData | wc -l`
out_dir="./phen_reports"

flag=0
if [ $cur_num != $num ]; then
	echo "Some jobs didn't complete $cur_num != $num"
	flag=1
else
	echo "All jobs complete - moving to finished_jobs dir"
	if [ $flag -eq 0 ]; then
		mkdir $out_dir
		mv nc_read.* $out_dir/
	fi
fi
