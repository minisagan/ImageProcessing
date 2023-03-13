#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#run AMICO 

import sys
diffusivity = sys.argv[1]
subject_list = sys.argv[2]
dwidir = sys.argv[3]
T2dir = sys.argv[4]
"""
diffusivity=0.3
dwidir=/data1/CHD/ShardRecon03-cardiac
T2dir=/data1/CHD/derivatives 
subject_list=/home/sma22/Desktop/NormMod/${dataset}/surf_list_test.txt
"""

import amico 
#amico.setup()
amico.core.setup()

import numpy as np 
subject_list = np.loadtxt(subject_list,dtype=str)
for subject, session in subject_list: 

	print(subject, session)

	ae = amico.Evaluation("{}/sub-{}/ses-{}/Diffusion/diff-{}".format(dwidir, subject, session, diffusivity),"dMRI")
	amico.util.fsl2scheme("{}/sub-{}/ses-{}/protocol1.bval".format(dwidir, subject, session), "{}/sub-{}/ses-{}/protocol1.bvec".format(dwidir, subject, session))
	# DONT NEED BET IMAGE BC OF RIBBON
	ae.load_data(dwi_filename="{}/sub-{}/ses-{}/postmc-dwi.nii".format(dwidir, subject, session), scheme_filename="{}/sub-{}/ses-{}/protocol1.scheme".format(dwidir, subject, session), mask_filename="{}/sub-{}/transformed_ribbon.nii.gz".format(T2dir, subject))
	ae.set_model("NODDI")
	ae.generate_kernels(regenerate=True)
	ae.load_kernels()
	ae.fit()
	ae.save_results()
