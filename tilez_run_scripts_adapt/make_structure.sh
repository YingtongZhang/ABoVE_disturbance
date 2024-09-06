#!/bin/bash

base_dir="/att/pubrepo/LANDSAT/EDC-ESPA"

land_dirs=( LT5 LE7 )
out_dir="."

for l in "${land_dirs[@]}"; do
	pr_dirs=($(ls -d $base_dir/$l/0*))
        
	for p in "${pr_dirs[@]}";  do
      		echo Processing $p 
		#all_files=($(ls $p))
		
		all_dat=($(ls $p | cut -c1-21 | uniq))
		
		for i in "${all_dat[@]}"; do
        		echo $i
        		cur_dat=($(find $p/ -maxdepth 1 -name ${i}*))

       			 if [ ! -d `echo $out_dir/$i` ]; then
                		mkdir $out_dir/$i
        		 fi
			  	
        		 for j in "${cur_dat[@]}"; do
                		base=`basename $j`
                		echo "Making link $out_dir/$i/$base"
				ln -s $j $out_dir/$i/$base
        		 done  ## j loop
		done  ## i loop	
        done  ## p loop
done  ## l loop

