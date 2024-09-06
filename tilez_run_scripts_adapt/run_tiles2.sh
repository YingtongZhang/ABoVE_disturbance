home_dir="/home/dsullame"
## this activates the virtual environment i need to run
source $home_dir/miniconda3/bin/activate tilezilla
## go into the run directory
work_dir="/att/nobackup/dsullame/tilez2"
cd $work_dir
## export this directory as root
export root=$(readlink -f $(pwd))
myhost=`/bin/hostname -s`
case "$myhost" in 
#	'dsullame101' ) params="-C above_ingest.yaml ingest -pe process /att/nobackup/dsullame/test_mirror/Landsat/*198*" ;;
	'adaptlight101' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7034022*" ;;
	'adaptlight102' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5034022*" ;;
	'adaptlight103' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7034021*" ;;	
    	'adaptlight104' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5034021*" ;;
	'adaptlight105' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7033022*" ;;
	'adaptlight106' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5033022*" ;;
	'adaptlight107' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7033021*" ;;
	'adaptlight108' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5033021*" ;;
	'adaptlight109' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7032022*" ;;
	'adaptlight110' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5032022*" ;;
	'adaptlight111' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7032021*" ;;
	'adaptlight112' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5032021*" ;;
        'adaptlight113' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7035022*" ;;
        'adaptlight114' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5035022*" ;;
        'adaptlight115' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LE7035021*" ;;
	'adaptlight116' ) params="-C above_ingest.yaml ingest -pe process -j 2 /att/nobackup/dsullame/test_mirror/Landsat/LT5035021*" ;;
	
	# 'dsullame10[3-4]' ) params="-C above_ingest.yaml ingest -pe process /att/nobackup/dsullame/test_mirror/Landsat/yet*something*else*" ;;
esac

tilez $params


