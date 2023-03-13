#!/bin/zsh
# prep data for run DTI (extract FA and MD) 
"""
dwidir=/data1/CHD/ShardRecon03-cardiac
T2dir=/data1/CHD/derivatives 
diffFolder=/data1/CHD
dataset=CHD

"""
dwidir=/data2/dHCP/ShardRecon03
T2dir=/home/sma22/data/derivatives
diffFolder=/data2/dHCP
dataset=dHCP

subject_list=/home/sma22/Desktop/NormMod/${dataset}/emma_mean_list_dhcp.txt

for subjid sesid pma in $(cat <${subject_list}) ; do
echo "${subjid}"
#subjid=100
#sesid=65

echo "making sure strides are consistent"
mrconvert ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain.nii.gz ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz -stride -1,2,3 -axes 0,1,2 -force

# extract mean b1000 and massage strides
echo "extracting mean b1000 and massaging strides" 

dwiextract ${dwidir}/sub-${subjid}/ses-${sesid}/postmc-dwi.mif.gz -shell 1000 - | mrmath - mean -axis 3 - | mrconvert - -stride -1,2,3 -axes 0,1,2 ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000.nii.gz -force 

bet ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz -R -f 0.3

wb_command -volume-math 'x==3' ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_wmmask.nii.gz -var x ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_drawem_tissue_labels.nii.gz

echo "Running FLIRT diff -> struct using NMI and BBR"

flirt -in ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz -ref ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz -out ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff -omat ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat -bins 256 -cost normmi -wmseg ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_wmmask.nii.gz -dof 6 -interp spline -nosearch

#echo "warping diff to struct"
#mrtransform ${dwidir}/sub-${subjid}/ses-${sesid}/postmc-dwi.mif.gz ${dwidir}/sub-${subjid}/ses-${sesid}/postmc-dwi_to-struct.mif.gz -linear ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_diff2str.mat -force


echo "extracting fa and md"
dwiextract -shell 0,400,1000 ${dwidir}/sub-${subjid}/ses-${sesid}/postmc-dwi.mif.gz - | dwi2tensor - -mask ${dwidir}/sub-${subjid}/ses-${sesid}/reconmask.mif.gz - | tensor2metric - -adc ${dwidir}/sub-${subjid}/ses-${sesid}/md.nii.gz -fa ${dwidir}/sub-${subjid}/ses-${sesid}/fa.nii.gz -mask ${dwidir}/sub-${subjid}/ses-${sesid}/reconmask.mif.gz -force

#echo "ribbon constrained volume to surface mapping" 
for hemi in left right ; do 

for mod in fa md ; do

vol=${dwidir}/sub-${subjid}/ses-${sesid}/${mod}.nii.gz
surface=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness.surf.gii
output=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}.shape.gii
inner_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_white.surf.gii
outer_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial.surf.gii

wb_command -surface-apply-affine ${surface} ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness_str2diff.surf.gii -flirt ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz

wb_command -surface-apply-affine ${inner_surf} ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_white_str2diff.surf.gii -flirt ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz

wb_command -surface-apply-affine ${outer_surf} ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial_str2diff.surf.gii -flirt ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz

str2diff_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness_str2diff.surf.gii
str2diff_inner_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_white_str2diff.surf.gii
str2diff_outer_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial_str2diff.surf.gii

wb_command -volume-to-surface-mapping ${vol} ${str2diff_surf} ${output} -ribbon-constrained ${str2diff_inner_surf} ${str2diff_outer_surf} 

#resampling
input=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}.shape.gii
output2=${diffFolder}/surface_processing/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_${mod}.shape.gii

wb_command -metric-resample ${input} ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/${hemi}.sphere.reg.surf.gii /data2/dHCP/dhcpSym_template/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii ADAP_BARY_AREA -area-surfs ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness.surf.gii ${diffFolder}/surface_processing/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_midthickness.surf.gii ${output2}


wb_command -metric-mask ${output2} /data1/CHD/surface_processing/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii ${output2}

done
done
echo "DONE"
done
