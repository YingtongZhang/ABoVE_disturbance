home_dir="/home/dsullame"
## this activates the virtual environment i need to run
source $home_dir/miniconda3/bin/activate tilezilla
## go into the run directory
work_dir="/att/nobackup/dsullame/tilez2"
cd $work_dir
## export this directory as root
export root=$(readlink -f $(pwd))



