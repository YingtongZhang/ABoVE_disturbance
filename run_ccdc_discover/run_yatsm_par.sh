#!/bin/bash -l

#SBATCH -N 1
# #SBATCH -N 4
#SBATCH --ntasks-per-node=22
#SBATCH --time=12:00:00
## if go over 12 hours
# #SBATCH --qos=long
#SBATCH -o yatsm.%j
#SBATCH -J YATSM

## directives for GEO
# #$ -pe omp 28
# #$ -l h_rt=24:00:00
# Queue array jobs. Must start from 1
# #$ -t 1-4


# set -x

if [ -z $1 ]; then
	echo "No input ini_file found. Abort!"
	echo "Usage: sbatch run_yatsm_par.sh ini_file"
	exit
fi


source activate yatsm_v0.6_par

echo jobnodelist $SLURM_JOB_NODELIST job id $SBATCH_JOB_ID task id $SLURM_TASK_PID proc_Id $SLURM_PROCID
echo $SLURM_NODEID

export PATH=/usr/local/other/GnuParallel/parallel-20110722/bin/:$PATH

# Get the 0-based array index from the queue array job ID
index=$(( $2 - 1 ))
## working on this iteration
echo "Working on job $index"

# Get the argument to the script as the ini_file
ini_file=$1
njob=1500
njob_per_node=50

## compute the beginning and ending job id - 0-indexed
job_start=$(( ${index} * ${njob_per_node} ))
job_end=$(( (${index} + 1) * ${njob_per_node} ))
# Echo all of the commands to run in this job into a file. - CMDS
CMDS=$TMPDIR/yatsm_cmds.txt
rm -f $CMDS

## the python program expects job to be 1-indexed
## so add 1 to job_start and job_end
for (( job=${job_start}+1; job<${job_end}+1; job++ ));
do
       one_cmd="yatsm -vvv line --resume $ini_file $job $njob"
       echo $one_cmd >> $CMDS
done

# Start parallel process - 22 cores
ncores=22
echo parallel --joblog "./yatsm.${index}.log" -j $ncores < $CMDS
parallel --joblog "./yatsm.${index}.log" -j $ncores < $CMDS
#cp $TMPDIR/yatsm_cmds.txt ./yatsm_cmds.${index}.txt

#/usr/local/other/PoDS/PoDS/pods.py -x $CMDS -n 25

source deactivate

