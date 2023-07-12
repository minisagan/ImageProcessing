#!/bin/zsh 

#dataset=CHD
dataset=dHCP
dwidir=/data2/New_${dataset}/ShardRecon03
T2dir=/data2/New_${dataset}/derivatives
diffFolder=/data2/New_${dataset}

subject_list=/home/sma22/Desktop/NormMod/${dataset}/pma_list.txt

for subjid sesid pma in $(cat <${subject_list}) ; do 
for mod in pial ; do
for hemi in left right ; do
echo ${subjid} ${sesid}
echo "extracting surface"
wb_command -surface-vertex-areas ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}.surf.gii ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial_SA.shape.gii

input=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}_SA.shape.gii
output=${diffFolder}/surface_processing/surface_transforms/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_${mod}.shape.gii

echo "resampling"
wb_command -metric-resample ${input} ${diffFolder}/surface_processing/surface_transforms/surface_transforms/sub-${subjid}_ses-${sesid}_hemi-${hemi}_from-native_to-dhcpSym40_dens-32k_mode-sphere.reg40.surf.gii /data2/dHCP/dhcpSym_template/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii ADAP_BARY_AREA -area-surfs ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness.surf.gii ${diffFolder}/surface_processing/surface_transforms/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_midthickness.surf.gii ${output}

echo "masking"
wb_command -metric-mask ${output} /data2/New_CHD/surface_processing/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii ${output}

done 
done
done

