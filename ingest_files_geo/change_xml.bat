#! /bin/bash
#$ -j y
#$ -N fix_xmls


## We check to make sure there is an argument to the script - should be two arguments for (1) the scene name and (2) the input directory
if [ -z "$1" ]
then
echo Usage:  "./rename_files.bat in_dir"
## exit script if it doesnt find the arguments
exit
else
in_dir=$1
fi

echo "Processing files from $in_dir"

n=$(find $in_dir -maxdepth 2 -name '*.xml' | wc -l)
i=1
echo "Found $n images to process"

for xml_file in $(find $in_dir -maxdepth 2 -name '*.xml'); do

    # Use AWK to remove .xml
    id=$(basename $xml_file | awk -F '.' '{ print $1 }')
    echo "<----- $i / $n: $id"
    
    cur_in_dir="$in_dir/${id}"
    
    sed -i 's/_hdf.img/.tif/g' $xml_file

    # Iterate count
    let i+=1
done


echo "Done with all scenes!"

