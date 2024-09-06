#!/bin/bash -l
#$ -pe mpi_28_tasks_per_node 420
#$ -l mem_total=98G
#$ -N vrt_run
#$ -j y
#$ -V

# module purge

# source activate yatsm_v0.6

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:~/envs/yatsm_v0.6
echo mpirun -np 400 .,/bin/make_vrts.exe ../VRTs/Bh11v11 ../outputs
mpirun -np 400 ../bin/make_vrts.exe ../../../VRTs/Bh11v11 ../outputs


