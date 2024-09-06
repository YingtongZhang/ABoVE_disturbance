#! /bin/csh -f
#this script is used to change the dates of part2_paths.txt
sed -e 's/h19v09/h22v08/g' ftp.h19v09.2006.bat > temp
mv temp ftp.h22v08.2006.bat

