#!/bin/bash

for t in `cat tiles.txt`; do
	tile="B${t}"
	if [ -f "./${tile}/${tile}.h5" ]; then
		echo "rm -rf ./${tile}/${tile}.h5"
		echo "cd ${tile}"
		echo "sbatch make_summ_table.sh ${tile}"
		echo "cd .."

		rm -rf ./${tile}/${tile}.h5
                cd ${tile}
                sbatch make_summ_table.sh ${tile}
		cd ..

	fi
done
