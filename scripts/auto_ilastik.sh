#!/bin/bash

# This script takes all images from a given folder and runs a batch of pixel segmentation and object detection
# headlessly on the Hyak server.
# PARAMETERS:
#   imagesDir: This is the path to the folder titled "day X" relative to where this script is being run.
#     It should contain only raw images that you intend to process with ilastik.
# EFFECTS:
# All files in the given directory will be renamed to use underscores instead of spaces.
# It's better this way, trust me.
# Output will go to ./../out/.
# It will consist of probability images from pixel segmentation, detected object images from object detection, and
# csv measurement and analysis from object detection, as well as one output excel file summarizing the findings.
#XXX This output may get cleaned up later using cleanup.sh, leaving only the excel file output.

imagesDir=$1
#https://stackoverflow.com/questions/14447406/bash-shell-script-check-for-a-flag-and-grab-its-value
#cleanup

# Gets all images from
images=$(ls "$imagesDir")
echo "Dir: "
echo $imagesDir
echo "IMAGES: "
echo $(ls "$imagesDir")
#NOTE: ilastik has an error which requires NO SPACES in files, 
# even if in quotes
noSpacesImages=""
SAVEIFS=$IFS
IFS=$(echo -en "\n\b")
#XXX need to do this same looping technique to get probability files from output of segmentation
for image in $images
do
	echo "Image: $image"
	newImage=$(echo $image | sed -e "s/ /_/g")
	cp "$imagesDir/$image" "$imagesDir/$newImage"
	echo "New file name: $newImage"
	noSpacesImages="$noSpacesImages $imagesDir/$newImage "
done
IFS=$SAVEIFS
echo "Done renaming"

# PIXEL SEGMENTATION
#NOTE: Put your model name under --project="your_model.ilp"
# (and make sure to put your model in the models directory)

#XXX instead of making output dir underneath imgs dir, could as for
# root dir and then make output under that and get images by looking
# recursively for .tif

#XXX need to install ilastik in freedman and chaytan directories
#XXX not sure --raw_data $noSpacesImages works -- will have to test once disk quota is fixed
/gscratch/iscrm/freedman/ilastik/ilastik-1.3.3-Linux ./run_ilastik.sh \
  --headless \
	--project="../models/cyst_pixel_seg.ilp" \
	--output_format=tif \
	--output_filename_format=/{dataset_dir}/../out/{nickname}.tif \
	--export_source="Probabilities" \
	--raw_data=$noSpacesImages || return 1;

# OBJECT DETECTION
#NOTE: Put your model name under --project="../models/your_model.ilp"

# If you are processing more than one volume in a single command, provide all inputs of a given type in sequence:
#--raw_data "my_grayscale_stack_1/*.png" "my_grayscale_stack_2/*.png" "my_grayscale_stack_3/*.png" \
#--segmentation_image my_unclassified_objects_1.h5/binary_segmentation_volume my_unclassified_objects_2.h5/binary_segmentation_volume my_unclassified_objects_3.h5/binary_segmentation_volume
/gscratch/iscrm/freedman/ilastik/ilastik-1.3.3-Linux ./run_ilastik.sh \
  --headless \
	--project="../models/cyst_object_det3.ilp" \
	--output_format=tif \
	--output_filename_format=/{dataset_dir}/../out/{nickname}.tif \
	--export_source="Probabilities" \
  --raw_data=$noSpacesImages \
#XXX --segmentation_image-


#XXX run cleanup script (base on flag parameter passed in)

# Check error status of run
if [ $(echo $?) == "0" ] 
then
	echo "Ilastik ran on the images successfully!"
else
	echo "Failure! check the log files in home directory (~/ilastik_log.txt)??"
fi
