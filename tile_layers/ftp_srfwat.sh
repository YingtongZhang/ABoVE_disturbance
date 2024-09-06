#!/bin/bash -l

#$ -N download_http
#$ -pe omp 4
#$ -l eth_speed=10

ftp_loc="https://storage.googleapis.com/global-surface-water/downloads"


#for (( y = 2003; y < 2011; y++ ))

for ty in occurrence change seasonality recurrence transitions extent ; do

    if [ ! -d $ty ]; then
        mkdir $ty
    fi

    for (( lon = 60; lon < 180; lon += 10 )); do
        for (( lat = 60; lat < 90; lat += 10 )); do
            echo "${ftp_loc}/${ty}/${ty}_${lon}W_${lat}N.tif"
	        #new_d=`printf "%03d" $d`
            wget --no-check-certificate "${ftp_loc}/${ty}/${ty}_${lon}W_${lat}N.tif" ;
        done
   done
done
