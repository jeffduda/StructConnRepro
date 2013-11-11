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
my $ants = "~/bin/";

my $mni = "${base}/data/MNI/MNI152_T1_1mm.nii.gz";
my $template = "${base}/data/Kirby/S_template3.nii.gz";
my $l1 = "${base}/data/MNI/Thalamus-maxprob-thr0-1mm.nii.gz";
my $l2 = "${base}/data/MNI/Thalamus-maxprob-thr25-1mm.nii.gz";
my $l3 = "${base}/data/MNI/Thalamus-maxprob-thr50-1mm.nii.gz";

my $prepFixed = "${ants}ResampleImageBySpacing 3 $template ${base}/data/MNI/InitialAffineFixed.nii.gz 4 4 4 1";
system($prepFixed);
my $prepMoving = "${ants}ResampleImageBySpacing 3 $mni  ${base}/data/MNI/InitialAffineMoving.nii.gz 4 4 4 1";
system($prepMoving);

my $laplacianFixed = "${ants}ImageMath 3 ${base}/data/MNI/FixedLaplacian.nii.gz Laplacian $template 1.5 1";
system( $laplacianFixed );
my $laplacianMoving = "${ants}ImageMath 3 ${base}/data/MNI/MovingLaplacian.nii.gz Laplacian $mni 1.5 1";
system( $laplacianMoving );

my $initialize = "${ants}antsAffineInitializer 3 ${base}/data/AAL/InitialAffineFixed.nii.gz ${base}/data/AAL/InitialAffineMoving.nii.gz ${base}/data/AAL/InitialAffine.mat 15 0.1 0 10";
system( $initialize );
 
my $fullReg = "${ants}antsRegistration -d 3 -u 1 -w [0.025,0.975] -o ${base}/data/AAL/align -r ${base}/data/AAL/InitialAffine.mat -z 1 -m MI[ ${template}, ${mni},1,32,Regular,0.25] -c [1000x500x250x100,1e-8,10] -t Rigid[0.1] -f 8x4x2x1 -s 4x2x1x0 -m MI[ ${template}, ${mni},1,32,Regular,0.25] -c [1000x500x250x100,1e-8,10] -t Affine[0.1] -f 8x4x2x1 -s 4x2x1x0 -m CC[ ${template}, ${mni},0.5,4] -m CC[${base}/data/AAL/FixedLaplacian.nii.gz, ${base}/data/AAL/MovingLaplacian.nii.gz,0.5,4] -c [50x10x0,1e-9,15] -t SyN[0.1,3,0] -f 4x2x1 -s 2x1x0";
system($fullReg);





