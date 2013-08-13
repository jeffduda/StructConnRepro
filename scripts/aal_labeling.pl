#!/usr/bin/perl -w
# preprocess_mmrr21.pl
#
# Try to limit all dataset specific processing to this step so 
# that later processing is applicable to any data set that
# meets the minimum specs.
# 
# 1 - Intrasub alignment of MRAGE
# 2 - Transfer labels/mask from manually labeled timepoint
# 3 - N4 correction of MPRAGE
# 4 - DTI reconstruction
# 5 - Intrasub/time aligment of DTI/MPRAGE
# 6 - Transfer cortical labels to DTI space

use strict;
use File::Path;
use File::Spec;
use File::Basename;
use Cwd 'abs_path';
use File::Temp;

my $base = abs_path(".." );

# FIXME - maybe be these from ENV VARS
#my $camino = "${base}/software/camino/bin/";
my $camino = "/home/jtduda/pkg/camino/bin/";
#my $ants = "${base}/software/ANTs/ANTs-build/bin/";
my $ants = "/home/avants/bin/ants/";

my $ch2 = "${base}/data/AAL/ch2.nii.gz";
my $ch2bet =  "${base}/data/AAL/ch2bet.nii.gz";
my $aal = "${base}/data/AAL/aal.nii.gz";
my $template = "${base}/data/MMRR-21_template/MMRR-21_head_template.nii.gz";
my $templateb = "${base}/data/MMRR-21_template/MMRR-21_template.nii.gz";

my $regCall = "${ants}antsRegistration -d 3 -u 1 -w [0.01,0.99] -r [ $templateb, $ch2bet, useCenterOfMass ] -o [ ${base}/data/AAL/ch2, ${base}/data/AAL/ch2_warped.nii.gz ] -m MI[${template},${ch2},1,32,Regular,0.25] -c [1000x500x250x100,1e-8,10] -t Affine[0.1] -f 8x4x2x1 -s 3x2x1x0 -m CC[${template},${ch2},1,4,Regular,0.25] -c [100x100x70x20,1e-8,10] -t SyN[0.1,3,0] -f 8x4x2x1 -s 3x2x1x0";
#print("$regCall \n");
system($regCall);

my $warpLabels = "${ants}antsApplyTransforms -d 3 -i $aal -o ${base}/data/MMRR-21_template/MMRR-21_template_aal.nii.gz -n NearestNeighbor -r $template -t ${base}/data/AAL/ch21Warp.nii.gz -t  ${base}/data/AAL/ch20GenericAffine.mat";
system($warpLabels);




