#!/bin/bash


all=`find . -name *.h5`
for tile in ${all[@]} ; do

in=`echo $tile | cut -f2 -d"/"`
more "./${in}/table.*" | grep "Finished"
echo $in
done
