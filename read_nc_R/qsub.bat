#!/bin/bash -l

in_tile="$1"

if [ -z $in_tile ]; then
echo "No argument given. Expected in_tile."
exit	
fi

data_dir="/projectnb/landsat/users/dsm/above/ccdc_develop/ccdc_${in_tile}_from_nc/${in_tile}_NC"

out_dir="./${in_tile}_green_110217"

## make directory if doesnt exist
if [ ! -d $out_dir ]; then
	mkdir $out_dir
fi

counter=0
i=1

## 20 processors each running 150 chunks
# for i in `seq 1 20` ; do
for i in `seq 1 10` ; do
echo $i
(( counter++ ))
start_row=$(( ($i-1)*150 + 1 ))
end_row=$(( $i*150 )) 
echo "qsubv read_nc.sh $data_dir $in_tile $out_dir $start_row $end_row"
qsub read_nc.sh $data_dir $in_tile $out_dir $start_row $end_row
done  ## end i

echo Count was $counter
