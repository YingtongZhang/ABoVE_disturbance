#!/bin/bash -l

#$ -pe omp 16
#$ -l h_rt=24:00:00
#$ -N par_yatsm
#$ -j y

# Queue array jobs. Must start from 1
#$ -t 1-10
## #$ -t 1-60
module purge

# Load the GNU Bash parallel library
module load parallel/20131222


export LANG=en_US.utf-8
export LC_ALL=en_US.utf-8

source activate yatsm_v0.6_par

#njob=576
# job=1

njob=50

CMDS=$TMPDIR/yatsm_cmds.txt
rm -f $CMDS
# Get the 0-based array index from the queue array job ID
index=`expr $SGE_TASK_ID - 1`
## working on this iteration
echo "Working on job $index"

# Get the argument to the script as the ini_file
ini_file=$1
## compute the beginning and ending job id - 0-indexed
job_start=$(( ${index} * ${njob} ))
job_end=$(( (${index} + 1) * ${njob} ))
# Echo all of the commands to run in this job into a file. - CMDS
## the python program expects job to be 1-indexed 
## so add 1 to job_start and job_end
for (( job=${job_start}+1; job<${job_end}+1; job++ )); do
       one_cmd="yatsm -vvv line --resume $ini_file $job 3000"
       echo $one_cmd >> $CMDS
done

# Start parallel processing the commands
parallel --joblog "./yatsm.${index}.log" -j $NSLOTS < $CMDS
cp $TMPDIR/yatsm_cmds.txt ./yatsm_cmds.${index}.txt


source deactivate

