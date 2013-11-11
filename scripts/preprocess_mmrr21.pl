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

my $base = abs_path(".." );

# FIXME - maybe be these from ENV VARS
#my $camino = "${base}/software/camino/bin/";
my $camino = "/home/jtduda/pkg/camino/bin/";
#my $ants = "${base}/software/ANTs/ANTs-build/bin/";
my $ants = "/home/avants/bin/ants/";

my @extensions = (".nii.gz");

mkdir "${base}/data/MMRR-21_processed";

my @subs= glob( "${base}/data/MMRR-21_ids/*" );

foreach my $sub (@subs) {
  chomp($sub);

  my @subpath = split("/", $sub );
  my $subID =  $subpath[scalar(@subpath)-1];

  mkdir "${base}/data/MMRR-21_processed/$subID";

  my @times = glob( "${sub}/*");
  chomp(@times);

  my $idx = 0;
  foreach my $subdir (@times) {
    chomp($subdir);
    
    my @timepath = split("/", $subdir );
    my $timeID =  $timepath[scalar(@timepath)-1];

    my $outdir = "${base}/data/MMRR-21_processed/$subID/$timeID";

    mkdir "$outdir";
    my $name = "${subID}_${timeID}_";

    # Job file can not start with a number
    my $jobname = "${outdir}/SCR_${name}preprocess.sh";
    open(PREPROCESS,">${jobname}") or die "Can't write preprocess script";


    
    # Only do these steps for data that is manually labeled
    my $labels = "${subdir}/KKI2009-${timeID}-labels.DKT25.manual.nii.gz";
    my $labels2 = "${subdir}/KKI2009-${timeID}-labels.DKT31.manual.nii.gz";
    my $outlabels = "${outdir}/${name}labels.DKT25.nii.gz";
    my $outlabels2 = "${outdir}/${name}labels.DKT31.nii.gz";
    my $mask = "${outdir}/${name}brainmask.nii.gz";
    my $brain = "${subdir}/KKI2009-${timeID}-t1weighted_brain.nii.gz";
    my $n4brain = "${outdir}/${name}brain.nii.gz";

    if ( (! -s "$labels" ) && ( ! -s "$outlabels") ) {
      
      if ( ! -s "${outlabels}" ) {
        print( "Missing $outlabels \n" );
      }

      my $altTime = $times[0];
      # Register this data to other time point for same subject
      if ( $idx < 1 ) {
        $altTime = $times[1];
      }
      my @alttimepath = split("/", $altTime );
      my $altTimeID =  $alttimepath[scalar(@alttimepath)-1];
      
      $labels = "${altTime}/KKI2009-${altTimeID}-labels.DKT25.manual.nii.gz";
      $labels2 = "${altTime}/KKI2009-${altTimeID}-labels.DKT31.manual.nii.gz";
      $brain =  "${altTime}/KKI2009-${altTimeID}-t1weighted_brain.nii.gz";

      print( "$labels \n $brain \n" );

      my $altOutdir = "${base}/data/MMRR-21_processed/$subID/${altTimeID}";
      my $altName= "${subID}_${altTimeID}_";
      
      my @mprage1 = glob( "${outdir}/${name}MPRAGE_N4.nii.gz" );
      my @mprage2 = glob( "${altOutdir}/${altName}MPRAGE_N4.nii.gz" );
      
      my $fixed = $mprage1[0];
      my $moving = $mprage2[0];
      print( "Register $moving to $fixed\n");
      
      my $reg = "${ants}antsRegistration -d 3 -o [ ${outdir}/${name}intrasub, ${outdir}/${name}alt.nii.gz ] -m mi[ $fixed, $moving, 1, 32, Regular, 0.3 ] -t Affine[0.2] -f 4x2x1 -s 2x1x0vox --winsorize-image-intensities [0.005, 0.995] -c [1500x1500x0, 1.e-8, 10] -l 1 -u 1 -b 0 -z 1 \n";
      print PREPROCESS $reg;
      
      my $warp = "${ants}/antsApplyTransforms -d 3 -i $labels -o ${outlabels} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $fixed \n";
      print PREPROCESS $warp;

      my $warp2 = "${ants}/antsApplyTransforms -d 3 -i $labels2 -o ${outlabels2} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $fixed \n";
      print PREPROCESS $warp2;

      print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $brain -o $mask -n Linear -t ${outdir}/${name}intrasub0GenericAffine.mat -r $fixed \n";

      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 1 inf \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask MD $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask ME $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask FillHoles $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask GetLargestComponent $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask G $mask 3 \n";
      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 0.2 inf \n";

      print PREPROCESS "${ants}/ImageMath 3 $n4brain m $mask ${outdir}/${name}MPRAGE_N4.nii.gz \n";

    }
    else {

      if ( ! -s "$labels" ) {
        my $altTime = $times[0];
        # Register this data to other time point for same subject
        if ( $idx < 1 ) {
          $altTime = $times[1];
        }
        my @alttimepath = split("/", $altTime );
        my $altTimeID =  $alttimepath[scalar(@alttimepath)-1];
        $labels = "${altTime}/KKI2009-${altTimeID}-labels.DKT25.manual.nii.gz";
        $labels2 = "${altTime}/KKI2009-${altTimeID}-labels.DKT31.manual.nii.gz";
        $brain =  "${altTime}/KKI2009-${altTimeID}-t1weighted_brain.nii.gz";
        my $ref =  "${subdir}/KKI2009-${timeID}-MPRAGE.nii.gz";

        print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $labels -o ${outlabels} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $ref \n";

        print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $labels2 -o ${outlabels2} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $ref \n";

        print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $brain -o $mask -n Linear -t ${outdir}/${name}intrasub0GenericAffine.mat -r $ref \n";
        
      }
      else {
         print PREPROCESS "cp $labels ${outlabels} \n";
         print PREPROCESS "cp $labesl2 ${outlabels2} \n";
         print PREPROCESS "cp $brain $mask \n";     
      }

      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 1 inf \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask MD $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask ME $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask FillHoles $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask GetLargestComponent $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask G $mask 3 \n";
      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 0.2 inf \n";

      print PREPROCESS "${ants}/ImageMath 3 $n4brain m $mask ${outdir}/${name}MPRAGE_N4.nii.gz \n";

    }

    close(PREPROCESS);
    $idx = $idx + 1;
    
    my $job = "qsub -V -pe serial 2 -v CAMINO_HEAP_SIZE=3000 -S /bin/sh -wd $outdir ${jobname}";
    system($job);
    sleep(2);

  }
}



