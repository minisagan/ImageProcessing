#!/bin/zsh 
#prep data for and run AMICO (NODDI) 

dwidir=/data1/CHD/ShardRecon03-cardiac
T2dir=/data1/CHD/derivatives 
diffFolder=/data1/CHD
dataset=CHD
"""
dwidir=/data2/dHCP/ShardRecon03
T2dir=/data2/dHCP/derivatives_dHCP
diffFolder=/data2/dHCP
dataset=dHCP
"""
#subjid=100
#sesid=65
subject_list=/home/sma22/Desktop/NormMod/${dataset}/surf_list.txt

echo "converting bvals and bvecs + creating and transforming cortical masks"
for subjid sesid pma in $(cat <${subject_list}) ; do 

mrconvert ${dwidir}/sub-${subjid}/ses-${sesid}/reconmask.mif.gz ${dwidir}/sub-${subjid}/ses-${sesid}/reconmask.nii -force

mrconvert ${dwidir}/sub-${subjid}/ses-${sesid}/postmc-dwi.mif.gz -strides -1,2,3,4 -export_grad_fsl ${dwidir}/sub-${subjid}/ses-${sesid}/protocol1.bvec ${dwidir}/sub-${subjid}/ses-${sesid}/protocol1.bval /${dwidir}/sub-${subjid}/ses-${sesid}/postmc-dwi.nii -force


#creating cortical mask
wb_command -volume-math 'x==2' ${T2dir}/sub-${subjid}/sub-${subjid}_ses-${sesid}_drawem_ribbon.nii.gz -var x ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_drawem_tissue_labels.nii.gz

#transforming cortical mask 
flirt -in ${T2dir}/sub-${subjid}/sub-${subjid}_ses-${sesid}_drawem_ribbon.nii.gz -ref ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz -out ${T2dir}/sub-${subjid}/transformed_ribbon.nii.gz -init ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat -applyxfm -interp nearestneighbour
done

echo "running AMICO" 
diff=1.3
#replace diffusivity in amico
sed -i "505s/.*/        self.dPar      = ${diff}E-3/" /home/sma22/Software/anaconda3/lib/python3.7/site-packages/amico/models.py
#run amico script 
python /home/sma22/Desktop/NormMod/scripts/AMICO_NODDI.py ${diff} ${subject_list} ${dwidir} ${T2dir}



echo "ribbon constrained volume to surface mapping" 
for subjid sesid pma in $(cat <${subject_list}); do 
echo "sub-${subjid} ses-${sesid}"
for hemi in left right ; do 
for mod in ICVF ISOVF OD ; do  #make sure correct 

diff=1.3

vol=${dwidir}/sub-${subjid}/ses-${sesid}/Diffusion/diff-${diff}/dMRI/AMICO/NODDI/FIT_${mod}.nii.gz
surface=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness.surf.gii
output=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_${mod}.shape.gii   #IS THIS WHAT I WANT TO CALL MY OUTPUT???
inner_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_white.surf.gii
outer_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial.surf.gii

wb_command -surface-apply-affine ${surface} ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness_str2diff.surf.gii -flirt ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz

wb_command -surface-apply-affine ${inner_surf} ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_white_str2diff.surf.gii -flirt ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz

wb_command -surface-apply-affine ${outer_surf} ${diffFolder}/xfms/sub-${subjid}_ses-${sesid}_str2diff.mat ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial_str2diff.surf.gii -flirt ${T2dir}/sub-${subjid}/ses-${sesid}/anat/sub-${subjid}_ses-${sesid}_T2w_restore_brain_for_diff.nii.gz ${dwidir}/sub-${subjid}/ses-${sesid}/mean_b1000_bet.nii.gz

str2diff_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness_str2diff.surf.gii
str2diff_inner_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_white_str2diff.surf.gii
str2diff_outer_surf=${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_pial_str2diff.surf.gii

wb_command -volume-to-surface-mapping ${vol} ${str2diff_surf} ${output} -ribbon-constrained ${str2diff_inner_surf} ${str2diff_outer_surf} 

echo "resampling"
output1=${diffFolder}/surface_processing/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_${mod}.shape.gii

#mkdir -p ${diffFolder}/surface_processing/sub-${subjid}/ses-${sesid}/dhcpSym_32k/Diffusion

wb_command -metric-resample ${output} ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/${hemi}.sphere.reg.surf.gii /data2/dHCP/dhcpSym_template/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_sphere.surf.gii ADAP_BARY_AREA -area-surfs ${T2dir}/sub-${subjid}/ses-${sesid}/anat/Native/sub-${subjid}_ses-${sesid}_${hemi}_midthickness.surf.gii ${diffFolder}/surface_processing/sub-${subjid}/ses-${sesid}/dhcpSym_32k/sub-${subjid}_ses-${sesid}_hemi-${hemi}_space-dhcpSym40_midthickness.surf.gii ${output1}


wb_command -metric-mask ${output1} /data1/CHD/surface_processing/week-40_hemi-${hemi}_space-dhcpSym_dens-32k_desc-medialwallsymm_mask.shape.gii ${output1}


done
done
done
