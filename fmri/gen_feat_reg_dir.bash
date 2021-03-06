#!/bin/bash
set -e

if command -v module >/dev/null; then
    module load "fsl/5.0.11" >/dev/null 2>&1
fi

#this script is used to setup reg dirs for first-level analyses in Feat.
#because we have preprocessed the data and warped into standard space, we do not need to
#warp the copes into standard space, as is conventional in FSL.

#thus, we emulate the output of standard Feat here by copying the identity matrix (i.e., no spatial transformation)
#into the .feat directory for each run of the task. This specifies no transformation, but provides
#the inputs that FSL looks for in second-level analyses (i.e., combining copes from each run)

[ $# -eq 0 ] && echo "Expect one input: directory containing all first-level clock runs." && exit 1

[ ! -d "$1" ] && echo "Unable to find directory: $1" && exit 1

cd "$1"

#featDirs=$(find $PWD -iname "FEAT_LVL1_run[0-9].feat" -type d)
featDirs=$(find $PWD -iname "FEAT_LVL1_*.feat" -type d)

for dir in ${featDirs}; do
    if [ -d "${dir}/reg" ]; then
	echo "Registration directory already exists: ${dir}/reg. Skipping run."
	continue
    fi

    if [ ! -f "${dir}/example_func.nii.gz" ]; then
	echo "FEAT appears to have failed in ${dir}. Skipping to next subject"
	continue
    fi

    echo "Generating reg directory: ${dir}/reg"
    mkdir "${dir}/reg"

    #fslroi "${dir}/../nfswkmtd_functional.nii.gz" "${dir}/reg/example_func" 0 1
    #fslroi "${dir}/../nfswkmtd_functional.nii.gz" "${dir}/reg/example_func2standard" 0 1

    #directory structure should include example_func images in root of each Feat directory. Copy these to reg
    cp "${dir}/example_func.nii.gz" "${dir}/reg/example_func.nii.gz"
    cp "${dir}/example_func.nii.gz" "${dir}/reg/example_func2standard.nii.gz"

    cp "${FSLDIR}/etc/flirtsch/ident.mat" "${dir}/reg/example_func2standard.mat"
    cp "${FSLDIR}/etc/flirtsch/ident.mat" "${dir}/reg/example_standard2example_func.mat"

    #for some reason, FSL 5.0.8 is now giving errors following this symlink... switch to copy (at the expense of disk space)
    ln -sfn $MRI_STDDIR/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_brain_2.3mm.nii "${dir}/reg/standard.nii"
    #cp $MRI_STDDIR/mni_icbm152_nlin_asym_09c/mni_icbm152_t1_tal_nlin_asym_09c_brain_2.3mm.nii "${dir}/reg/standard.nii"

    cd "${dir}/reg"
    slicer example_func2standard standard -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png \
	-y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png \
	-z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png

    pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png example_func2standard1.png 

    slicer standard example_func2standard -s 2 -x 0.35 sla.png -x 0.45 slb.png -x 0.55 slc.png -x 0.65 sld.png \
	-y 0.35 sle.png -y 0.45 slf.png -y 0.55 slg.png -y 0.65 slh.png \
	-z 0.35 sli.png -z 0.45 slj.png -z 0.55 slk.png -z 0.65 sll.png

    pngappend sla.png + slb.png + slc.png + sld.png + sle.png + slf.png + slg.png + slh.png + sli.png + slj.png + slk.png + sll.png example_func2standard2.png

    pngappend example_func2standard1.png - example_func2standard2.png example_func2standard.png

    rm -f sl?.png example_func2standard2.png

done
