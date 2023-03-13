#!/bin/zsh 

#create midthickness surface in template space to use for resampling of other metrics 
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
#subjid=177
#sesid=113
#subject_list=/home/sma22/Desktop/NormMod/${dataset}/emma_mean_list_dhcp.txt

for subjid sesid pma in $(cat <${subject_list}) ; do
#subjid=CC01111XX06
#sesid=100031
for hemi in left ; do 
echo ${subjid} ${sesid}

wb_command -surface-resample ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness.surf.gii ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/${hemi}.sphere.reg.surf.gii /data2/dHCP/dhcpSym_template/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii BARYCENTRIC ${diffFolder}/surface_processing/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_midthickness.surf.gii
done



#${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/left.sphere.LR.reg.surf.gii 