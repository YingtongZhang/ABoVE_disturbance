#!/bin/bash -l

    count=0

	for h in `seq 0 22`; do
		a=`printf "%.2d" $h`
        for v in `seq 0 22`; do
            b=`printf "%.2d" $v`
            tile="Bh${a}v${b}"
            if [ -d CCDC/$tile ]; then
                count=$(( count+1 ))                
                cur_num=`ls CCDC/$tile/output/yatsm_*.npz | wc -l`
                echo $tile $count $cur_num
            fi
        done
    done

