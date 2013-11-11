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
    my $jobname = "${outdir}/SCR_${name}preprocess_dt.sh";
    open(PREPROCESS,">${jobname}") or die "Can't write preprocess script";

    my $brainmask = "${outdir}/${name}BrainExtractionMask.nii.gz";
    my $n4 = "${outdir}/${name}BrainSegmentation0N4.nii.gz";
    my $brain = "${outdir}/${name}Brain.nii.gz";

    # DWI Motion Correction
    if ( ! -s "${outdir}/${name}DWI.nii.gz" ) {
      
      my $dti = "${subdir}/KKI2009-${timeID}-DTI.nii.gz";
      if ( ! -s $dti ) {
        die "Missing DTI for ${subdir}";
      }
 
      my @names = split("-DTI.nii.gz", $dti);
      my $dwi = "${outdir}/${name}DWI.nii.gz";
      my $scheme = "${outdir}/${name}DWI.scheme";

      my $dwiList = "";
      for ( my $n = 1; $n < 34; $n++) {
        $dwiList = $dwiList." "."${outdir}/dwi".sprintf("%04d",$n).".nii.gz";
      }

      print PREPROCESS "${camino}split4dnii -inputfile $dti -outputroot ${outdir}/dwi \n";
      print PREPROCESS "cp ${outdir}/dwi0033.nii.gz ${outdir}/${name}B0.nii.gz \n";
      print PREPROCESS "${ants}ImageMath 4 ${dwi} TimeSeriesAssemble 1 0 ${dwiList} \n";
      print PREPROCESS "rm ${outdir}/dwi????.nii.gz \n";

      print PREPROCESS "${ants}antsMotionCorr -d 3 -u ${outdir}/${name}B0.nii.gz -o [ ${outdir}/${name}DWI, ${dwi}, ${outdir}/${name}AverageDWI.nii.gz ] -m mi[ ${outdir}/${name}DWI.nii.gz,${dwi}, 1, 32, Regular, 0.05 ] -t Affine[0.2] -i 25 -u 1 -e 1 -f 1 -s 0 -l 0 \n";

    }
               
    # DTI Reconstruction
    if ( ! -s "${outdir}/${name}DTI.nii.gz" ) {

      my $grads = "${subdir}/KKI2009-${timeID}-DTI.grad";
      my $bvals = "${subdir}/KKI2009-${timeID}-DTI.b";
      if ( ! -s "$grads" ) {
        die "Missing gradient info for ${subdir}";
      }

      my $dwi = "${outdir}/${name}DWI.nii.gz";
      my $scheme = "${outdir}/${name}DWI.scheme";

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
      
      print PREPROCESS "echo image2voxel \n";
      print PREPROCESS "${camino}image2voxel -4dimage ${dwi} > ${outdir}/vo.Bfloat \n";
      print PREPROCESS "echo wdtfit \n";
      print PREPROCESS "${camino}wdtfit ${outdir}/vo.Bfloat $scheme ${outdir}/sigmaSq.img -outputdatatype float > ${outdir}/dt.Bfloat \n";    
      print PREPROCESS "echo dt2nii \n";
      print PREPROCESS "${camino}dt2nii -header ${outdir}/${name}B0.nii.gz -outputroot ${outdir}/${name} -inputfile ${outdir}/dt.Bfloat -inputdatatype float \n";
      print PREPROCESS "mv ${outdir}/${name}dt.nii.gz ${outdir}/${name}DTI.nii.gz \n";
      
      # remove camino processing files
      print PREPROCESS "rm ${outdir}/vo.Bfloat ${outdir}/dt.Bfloat ${outdir}/sigmaSq.img ${outdir}/${name}exitcode.nii.gz \n";    
      
      # DTI-based scalar metrics of interest
      print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}FA.nii.gz TensorFA ${outdir}/${name}DTI.nii.gz \n";
      print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}RD.nii.gz TensorMeanDiffusion ${outdir}/${name}DTI.nii.gz \n";
      print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}MD.nii.gz TensorRadialDiffusion ${outdir}/${name}DTI.nii.gz \n"; 
    }


    if ( ! -s "$brain" ) {
      print PREPROCESS "${ants}ImageMath 3 $brain m $brainmask $n4 \n"
     }

    # Align B0 to MPRAGE
    if ( ! -s "${outdir}/${name}B02MPRAGE.nii.gz" ) {
      
      my $init = "${ants}antsAffineInitializer 3 $brain ${outdir}/${name}B0.nii.gz ${outdir}/${name}B02MPRAGEInitialize.mat 15 0.1 0 10 \n";
      print PREPROCESS $init;

      my $dtireg = "${ants}antsRegistration -d 3 --winsorize-image-intensities [0.005, 0.995] -o [ ${outdir}/${name}B02MPRAGE, ${outdir}/${name}B02MPRAGE.nii.gz ] -r ${outdir}/${name}B02MPRAGEInitialize.mat -m mi[ $brain, ${outdir}/${name}B0.nii.gz, 1, 32, Regular, 0.3 ] -t Affine[0.2] -f 4x2x1 -s 2x1x0vox -c [1000x500x100, 1.e-8, 10] -m mi[ $brain, ${outdir}/${name}B0.nii.gz, 1, 32, Regular, 0.3 ] -t SyN[0.1,3,0] -f 4x2x1 -s 2x1x0vox -c [200x100x20, 1.e-8, 10] -l 1 -u 1 -b 0 -z 1 \n";
      print PREPROCESS $dtireg;
      
    }

    if ( ! -s "${outdir}/${name}DTIMask.nii.gz" ) {
      print PREPROCESS "${ants}/antsApplyTransforms -d 3 -i ${brainmask} -o ${outdir}/${name}DTIMask.nii.gz -n Linear -r ${outdir}/${name}B0.nii.gz -t [ ${outdir}/${name}B02MPRAGE0GenericAffine.mat, 1] -t ${outdir}/${name}B02MPRAGE1InverseWarp.nii.gz \n";
      print PREPROCESS "${ants}/ThresholdImage 3 ${outdir}/${name}DTIMask.nii.gz ${outdir}/${name}DTIMask.nii.gz 0.3 inf \n";
    }

    close(PREPROCESS);
    $idx = $idx + 1;

    if ( -s "$jobname" ) {
      my $job = "qsub -V -pe serial 2 -v CAMINO_HEAP_SIZE=3000 -S /bin/sh -wd $outdir ${jobname}";
      system($job);
      sleep(2);
    }

  }
}



