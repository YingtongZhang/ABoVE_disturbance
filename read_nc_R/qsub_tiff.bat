#!/bin/bash -l

if [ -z "$1" ]; then
    echo Usage is ./make_tiffs.sh in_tile out_met year
    echo No argument 1 provided!
else
    in_tile=$1
fi

if [ -z "$2" ]; then
    echo Usage is ./make_tiffs.sh in_tile out_met year
    echo "out_met has to be one of etm, tm5, phen"
    echo No argument 2 provided!
    exit
else
    out_met=$2
fi

if [ -z "$3" ]; then
    year="2000"
else
    year=$3
fi

in_dir="../${in_tile}_phen"

out_dir="./tifs"

## make directory if doesnt exist
if [ ! -d $out_dir ]; then
	mkdir $out_dir
fi


qsub make_tiffs.sh $in_tile $in_dir $out_dir $out_met $year


