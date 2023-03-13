#!/bin/zsh 
#extracting area from pial and midthickness surface files 


T2dir=/data1/CHD/derivatives 
dataset=CHD
"""
T2dir=/data2/dHCP/derivatives_dHCP
dataset=dHCP
"""
subject_list=/home/sma22/Desktop/NormMod/${dataset}/surf_list_test.txt

for subjid sesid in $(cat <${subject_list}) ; do 

for mod in pial midthickness; do
for hemi in left right ; do


wb_command -surface-vertex-areas ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}.surf.gii ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}_SA.shape.gii

done 
done
done


