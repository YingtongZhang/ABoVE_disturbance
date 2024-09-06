#!/bin/bash

if [ -z "$1" ] ; then
   echo Usage \./dist_nodes.bat last_run total_num_nodes cur_sens
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



code_dir="$NOBACKUP/tilez_all_above"
global_tiles="$NOBACKUP/setup_global_runs/global_scene.txt"
num_scenes=$(more $global_tiles | wc -l)
echo Processing total of $num_scenes scenes.  Currently running with $total_num_nodes nodes. Last run finished at $last_run.  Currently running sensor $cur_sens.

let first=($last_run+1)
let last=($last_run+$total_num_nodes)

echo Processing scenes $first $last out of $num_scenes

count=1
cur_last=1
for p in `cat $global_tiles`; do
    if [ "$count" -ge $first ] && [ "$count" -le $last ] ; then
	echo $p $count
	cur_last=$(( $count+1 ))
	cur_num=$(printf "%03d" $in_count)
#	s="LT5"
	echo nohup pupsh "hostname ~ 'adaptlight${cur_num}'" "bash $code_dir/run_tiles.sh $p $cur_sens &> $code_dir/logs/run_tiles_%h_${count}_${cur_sens}.log"
	nohup pupsh "hostname ~ 'adaptlight${cur_num}'" "bash $code_dir/run_tiles.sh $p $cur_sens &> $code_dir/logs/run_tiles_%h_${count}_${cur_sens}.log" &
	(( in_count++ ))
    fi
    (( count++ ))
done
echo "The next one will start at $cur_last"
