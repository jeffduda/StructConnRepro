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
    my $outlabels = "${outdir}/${name}labels.DKT25.nii.gz";
    my $mask = "${outdir}/${name}brainmask.nii.gz";
    my $brain = "${subdir}/KKI2009-${timeID}-t1weighted_brain.nii.gz";
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
      $brain =  "${altTime}/KKI2009-${altTimeID}-t1weighted_brain.nii.gz";

      print( "$labels \n $brain \n" );
      
      my @mprage1 = glob( "${subdir}/KKI2009-${timeID}-MPRAGE.nii.gz" );
      my @mprage2 = glob( "${altTime}/KKI2009-${altTimeID}-MPRAGE.nii.gz" );
      
      my $fixed = $mprage1[0];
      my $moving = $mprage2[0];
      print( "Register $moving to $fixed\n");
      
      my $reg = "${ants}antsRegistration -d 3 -o [ ${outdir}/${name}intrasub, ${outdir}/${name}alt.nii.gz ] -m mi[ $fixed, $moving, 1, 32, Regular, 0.3 ] -t Affine[0.2] -f 4x2x1 -s 2x1x0vox --winsorize-image-intensities [0.005, 0.995] -c [1500x1500x0, 1.e-8, 10] -l 1 -u 1 -b 0 -z 1 \n";
      print PREPROCESS $reg;
      
      my $warp = "${ants}/antsApplyTransforms -d 3 -i $labels -o ${outlabels} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $fixed \n";
      print PREPROCESS $warp;

      print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $brain -o $mask -n Linear -t ${outdir}/${name}intrasub0GenericAffine.mat -r $fixed \n";

      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 1 inf \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask MD $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask ME $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask FillHoles $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask GetLargestComponent $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask G $mask 3 \n";
      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 0.2 inf \n";

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
        $brain =  "${altTime}/KKI2009-${altTimeID}-t1weighted_brain.nii.gz";
        my $ref =  "${subdir}/KKI2009-${timeID}-MPRAGE.nii.gz";

        print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $labels -o ${outlabels} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $ref \n";

        print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i $brain -o $mask -n Linear -t ${outdir}/${name}intrasub0GenericAffine.mat -r $ref \n";
        
      }
      else {
         print PREPROCESS "cp $labels ${outlabels} \n";
         print PREPROCESS "cp $brain $mask \n";     
      }

      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 1 inf \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask MD $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask ME $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask FillHoles $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask GetLargestComponent $mask 3 \n";
      print PREPROCESS "${ants}/ImageMath 3 $mask G $mask 3 \n";
      print PREPROCESS "${ants}/ThresholdImage 3 $mask $mask 0.2 inf \n";
    }

    # N4 on MPRAGE
    if ( ! -s "${outdir}/${name}MPRAGE_N4.nii.gz" ) {
      print PREPROCESS "N4BiasFieldCorrection 3 -h 0 -i ${subdir}/KKI2009-${timeID}-MPRAGE.nii.gz -o ${outdir}/${name}MPRAGE_N4.nii.gz -s 2 -b [200] -c [20x20x20x20,0.0001] \n";
      print PREPROCESS "${ants}/ImageMath 3 ${outdir}/${name}MPRAGE_N4.nii.gz m ${outdir}/${name}MPRAGE_N4.nii.gz ${outdir}/${name}brainmask.nii.gz \n";
    }

    if ( ! -s "${outdir}/${name}dt.nii.gz" ) {
      
      my $dti = "${subdir}/KKI2009-${timeID}-DTI.nii.gz";
      if ( ! -s $dti ) {
        die "Missing DTI for ${subdir}";
      }
      my $grads = "${subdir}/KKI2009-${timeID}-DTI.grad";
      my $bvals = "${subdir}/KKI2009-${timeID}-DTI.b";
 
      my @names = split("-DTI.nii.gz", $dti);
      my $dwi = "${outdir}/${name}DWI.nii.gz";
      my $scheme = "${outdir}/${name}DWI.scheme";

      my $dwiList = "";
      for ( my $n = 1; $n < 34; $n++) {
        $dwiList = $dwiList." "."${outdir}/dwi".sprintf("%04d",$n).".nii.gz";
      }

      print PREPROCESS "${camino}split4dnii -inputfile $dti -outputroot ${outdir}/dwi \n";
      print PREPROCESS "rm ${outdir}/dwi0034.nii.gz \n";
      print PREPROCESS "cp ${outdir}/dwi0033.nii.gz ${outdir}/${name}b0.nii.gz \n";
      print PREPROCESS "${ants}ImageMath 4 ${outdir}/${name}DWI.nii.gz TimeSeriesAssemble 1 0 ${dwiList} \n";
         
      open(DATA,"<${grads}") or die "Can't open grad file";
      my @gradlines = <DATA>;
      close(DATA);
      
      open(DATA,"<${bvals}") or die "Can't open b file";
      my @blines = <DATA>;
      close(DATA);
      
      print ( "$scheme \n" );
      open(DATA,">${scheme}") or die "Can't write scheme file";
      print DATA "VERSION: 2\n";
      
      for (my $n = 0; $n < 33; $n++) {
        my $nGrad = $gradlines[$n];
        my $nB = $blines[$n];
        
        chomp($nGrad);
        chomp($nB);
        
        my @gradVec = split( " ", $nGrad );
        my $gradX = $gradVec[0];
        my $gradY = $gradVec[1];
        my $gradZ = -1.0 * $gradVec[2];
        
        print DATA $gradX." ".$gradY." ".$gradZ." ".$nB."\n";
    }
      
      print PREPROCESS "${camino}/image2voxel -4dimage ${outdir}/${name}DWI.nii.gz > ${outdir}/vo.Bfloat \n";
      print PREPROCESS "${camino}/wdtfit ${outdir}/vo.Bfloat $scheme ${outdir}/sigmaSq.img -outputdatatype float > ${outdir}/dt.Bfloat \n";

      print PREPROCESS "rm ${outdir}/dwi0033.nii.gz \n";
      
      print PREPROCESS "${camino}/dt2nii -header ${outdir}/${name}b0.nii.gz -outputroot ${outdir}/${name} -inputfile ${outdir}/dt.Bfloat -inputdatatype float \n";
      
      print PREPROCESS "rm ${outdir}/dwi* ${outdir}/vo.Bfloat ${outdir}/dt.Bfloat ${outdir}/sigmaSq.img \n";    
      
      print PREPROCESS "${ants}/ImageMath 3 ${outdir}/${name}fa.nii.gz TensorFA ${outdir}/${name}dt.nii.gz \n";
      print PREPROCESS "${ants}/ImageMath 3 ${outdir}/${name}rd.nii.gz TensorMeanDiffusion ${outdir}/${name}dt.nii.gz \n";
      print PREPROCESS "${ants}/ImageMath 3 ${outdir}/${name}md.nii.gz TensorRadialDiffusion ${outdir}/${name}dt.nii.gz\n"; 
    }


    
    # Align B0 to MPRAGE
    if ( ! -s "${outdir}/${name}b0_2_MPRAGE.nii.gz" ) {
      
      my $dtireg = "${ants}antsRegistration -d 3 -o [ ${outdir}/${name}b0_2_MPRAGE, ${outdir}/${name}b0_2_MPRAGE.nii.gz ] -m MeanSquares[ ${outdir}/${name}MPRAGE_N4.nii.gz, ${outdir}/${name}b0.nii.gz, 1, 4, Regular, 0.3 ] -t Rigid[1] -f 4 -s 2vox --winsorize-image-intensities [0.005, 0.995] -c [20, 1.e-8, 10] --initial-moving-transform[ ${outdir}/${name}MPRAGE_N4.nii.gz, ${outdir}/${name}b0.nii.gz, useCenterOfMass] -m mi[ ${outdir}/${name}MPRAGE_N4.nii.gz, ${outdir}/${name}b0.nii.gz, 1, 32, Regular, 0.3 ] -t Affine[0.2] -f 4x2x1 -s 2x1x0vox --winsorize-image-intensities [0.005, 0.995] -c [1500x1500x0, 1.e-8, 10] -l 1 -u 1 -b 0 -z 1 \n";
      print PREPROCESS $dtireg;
      
      my $dtilabels = "${ants}/antsApplyTransforms -d 3 -i ${outdir}/${name}labels.DKT25.nii.gz -o ${outdir}/${name}dti_labels.DKT25.nii.gz -n NearestNeighbor -r ${outdir}/${name}b0.nii.gz -t [ ${outdir}/${name}b0_2_MPRAGE0GenericAffine.mat, 1] \n";
      print PREPROCESS $dtilabels;

    }

    if ( ! -s "${outdir}/${name}dti_labels.DKT25.nii.gz" ) {
      print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i ${outdir}/${name}labels.DKT25.nii.gz -o ${outdir}/${name}dti_labels.DKT25.nii.gz -n NearestNeighbor -r ${outdir}/${name}b0.nii.gz -t [ ${outdir}/${name}b0_2_MPRAGE0GenericAffine.mat, 1] \n";
    }

    if ( ! -s "${outdir}/${name}dti_brainmask.nii.gz" ) {
      print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i ${outdir}/${name}brainmask.nii.gz -o ${outdir}/${name}dti_brainmask.nii.gz -n Linear -r ${outdir}/${name}b0.nii.gz -t [ ${outdir}/${name}b0_2_MPRAGE0GenericAffine.mat, 1] \n";
      print PREPROCESS "${ants}/ThresholdImage 3 ${outdir}/${name}dti_brainmask.nii.gz ${outdir}/${name}dti_brainmask.nii.gz 0.3 inf \n";
    }

    close(PREPROCESS);
    $idx = $idx + 1;
    
    my $job = "qsub -V -pe serial 2 -v CAMINO_HEAP_SIZE=3000 -S /bin/sh -wd $outdir ${jobname}";
    system($job);
    sleep(2);

  }
}



