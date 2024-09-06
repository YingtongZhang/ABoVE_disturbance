#!/bin/bash -l


mkdir src
mkdir inputs
mkdir outputs
mkdir bin

in_dir="/usr2/faculty/dsm/codes/dsm/above/extract_pyc"

cp ${in_dir}/inputs/* inputs/
ln -s ${in_dir}/src/Makefile src/Makefile
ln -s ${in_dir}/src/read_vrts.c src/read_vrts.c
ln -s ${in_dir}/src/sendReceiveData.c src/sendReceiveData.c
ln -s ${in_dir}/src/write_netcdf.c src/write_netcdf.c

cd ${in_dir}/src
make

cd ../
ln -s ${in_dir}/bin/read_vrts.exe bin/read_vrts.exe


