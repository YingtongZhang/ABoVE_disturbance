#!/bin/bash
#$ -l h_rt=24:00:00
#$ -j y
#$ -N make_vrt
#$ -V
#$ -pe omp 16

module purge
source ~/.module

## we make lists of the bands to composite
declare -a in_names
in_dir="/projectnb/modislc/data/aboveaster/ASTERGDEMv2"
for f in `ls -f ${in_dir}/*.tif`; do    
    
        in_names+="$f"
done

out_file="./dem_mos.vrt"
## run the query - we reorder bands 7 and 8 since band 7 is listed as the cfmask
#gdalbuildvrt -separate -b "1 2 3 4 5 6 8 7" ${out_dir}/${pr}/${pr}.vrt -input_file_list temp_${cur_tile}.txt
echo gdalbuildvrt -b 1 -srcnodata -9999 -vrtnodata -9999 -overwrite $out_file $in_names 
gdalbuildvrt -b 1 -srcnodata -9999 -vrtnodata -9999 -overwrite $out_file $in_names 

#for t in `cat tiles.txt`; do    
#    in_file="/projectnb.tif"
    
#    if [ -f $in_file ]; then
#        in_names+=" $in_file"
        #echo $in_names $in_file
#    fi  

#done


#done
