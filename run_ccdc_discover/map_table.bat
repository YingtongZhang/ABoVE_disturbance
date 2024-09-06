#!/bin/bash

for t in `cat tiles.txt`; do
	tile="B${t}"
	if [ -d "./${tile}" ]; then
		echo "rm -rf ${tile}/out_tif"
		echo "cd ${tile}"
		echo "sbatch map_table.sh ${tile}"
		echo "cd .."

		rm -rf ${tile}/out_tif
                cd ${tile}
                sbatch map_table.sh ${tile}
                cd ..

	fi
done
