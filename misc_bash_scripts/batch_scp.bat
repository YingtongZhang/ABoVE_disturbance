#! /bin/csh

set in_dir = ./mxndvi/outputs
foreach i (`ls -fd $in_dir/*`)
set name = `echo $i | cut -d"/" -f4`
echo scp ${i}patch_map.bsq dsm@hawaii.bu.edu:/Users/dsm/Desktop/$name.bsq
scp ${i}patch_map.bsq dsm@hawaii.bu.edu:/Users/dsm/Desktop/$name.bsq
end
