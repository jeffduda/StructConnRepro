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

my $mbbrain = "${base}/data/MMRR-21_template/MMRR-21_template.nii.gz";
my $mbhead = "${base}/data/MMRR-21_template/MMRR-21_head_template.nii.gz";
my $template = "${base}/data/Kirby/S_template3.nii.gz";
my $mask = "${base}/data/Kirby/S_templateProbabilityMaskFull.nii.gz";
my $cmask = "${base}/data/Kirby/S_templateProbabilityMask.nii.gz";

 
if ( ! -s "${base}/data/Kirby/align1Warp.nii.gz" ) {
  my $prepFixed = "${ants}ResampleImageBySpacing 3 $template ${base}/data/Kirby/InitialAffineFixed.nii.gz 4 4 4 1";
  system($prepFixed);
  my $prepMoving = "${ants}ResampleImageBySpacing 3 $mbhead ${base}/data/Kirby/InitialAffineMoving.nii.gz 4 4 4 1";
  system($prepMoving);
  
  my $laplacianFixed = "${ants}ImageMath 3 ${base}/data/Kirby/FixedLaplacian.nii.gz Laplacian $template 1.5 1";
  system( $laplacianFixed );
  my $laplacianMoving = "${ants}ImageMath 3 ${base}/data/Kirby/MovingLaplacian.nii.gz Laplacian $mbhead 1.5 1";
  system( $laplacianMoving );
  
  my $initialize = "${ants}antsAffineInitializer 3 ${base}/data/Kirby/InitialAffineFixed.nii.gz ${base}/data/Kirby/InitialAffineMoving.nii.gz ${base}/data/Kirby/InitialAffine.mat 15 0.1 0 10";
  print( "$initialize \n");
  system( $initialize );
  
  my $fullReg = "${ants}antsRegistration -d 3 -u 1 -w [0.025,0.975] -o ${base}/data/Kirby/align -r ${base}/data/Kirby/InitialAffine.mat -z 1 -m MI[ ${template}, ${mbhead},1,32,Regular,0.25] -c [1000x500x250x100,1e-8,10] -t Rigid[0.1] -f 8x4x2x1 -s 4x2x1x0 -m MI[ ${template}, ${mbhead},1,32,Regular,0.25] -c [1000x500x250x100,1e-8,10] -t Affine[0.1] -f 8x4x2x1 -s 4x2x1x0 -m CC[ ${template}, ${mbhead},0.5,4] -m CC[${base}/data/Kirby/FixedLaplacian.nii.gz, ${base}/data/Kirby/MovingLaplacian.nii.gz,0.5,4] -c [50x10x0,1e-9,15] -t SyN[0.1,3,0] -f 4x2x1 -s 2x1x0";
  system($fullReg);
}

my $warpBrain = "${ants}antsApplyTransforms -d 3 -i $mbbrain -o $mask -n NearestNeighbor -r $template -t ${base}/data/Kirby/align1Warp.nii.gz -t  ${base}/data/Kirby/align0GenericAffine.mat";
system($warpBrain);

my $thresh = "${ants}ThresholdImage 3 $mask $mask 1 inf";
system($thresh);
my $comp = "${ants}ImageMath 3 $mask GetLargestComponent $mask";
system($comp);
my $holes = "${ants}ImageMath 3 $mask FillHoles $mask";
system($holes);
my $erode = "${ants}ImageMath 3 $mask ME $mask 3";
system($erode);
system($comp);
system($holes);
my $dilate = "${ants}ImageMath 3 $mask MD $mask 3";
system($dilate); 
my $smooth = "${ants}ImageMath 3 $mask G $mask 1";
system($smooth);
my $add = "${ants}ImageMath 3 $mask + $mask $cmask";
#system($add);
my $norm = "${ants}ImageMath 3 $mask Normalize $mask";
#system($norm);

