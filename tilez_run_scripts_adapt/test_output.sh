#!/bin/bash

if [ -z "$1" ] ; then
   echo Usage \./test_output.sh last_run total_num_nodes cur_sens
   exit 1
else
   last_run="$1" 
fi

if [ -z "$2" ] ; then
   echo No argument 2 provided!
   exit 1
else
   total_num_nodes="$2"
fi

if [ -z "$3" ] ; then
   echo No argument 3 provided!
   exit 1
else
   cur_sens="$3"
fi

if [ -z "$4" ] ; then
   echo No argument 4 provided!
   exit 1
else
   in_count="$4"
fi

log_dir="$NOBACKUP/tilez_all_above/logs"

let first=($last_run+1)
let last=($last_run+$total_num_nodes)

name_stem="${log_dir}/run_tiles_adaptlight"

good_count=0
for (( i=first; i<=last; i++ )); do
	cur_num=$in_count
	full_name=${name_stem}${cur_num}_${i}_${cur_sens}.log
	status=`cat $full_name | tail | grep "Done"`
	if [ -z "$status" ]; then
		echo Job $i not finished logfile $full_name.
	else
		echo Job $i is finished logfile $full_name.
		(( good_count++ ))
	fi
	(( in_count++ ))
done

echo "$good_count out of $total_num_nodes are finished"

#if [ $good_count -eq $total_num_nodes ]; then
#	mv ${name_stem}* ${log_dir}/finished
#fi
