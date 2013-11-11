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
my $ants = "/home/jtduda/bin/ants/";

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
    my $jobname = "${outdir}/SCR_${name}label.sh";
    open(PREPROCESS,">${jobname}") or die "Can't write preprocess script";

    # Only do these steps for data that is manually labeled
    my $labels = "${subdir}/KKI2009-${timeID}-labels.DKT25.manual.nii.gz";
    my $labels2 = "${subdir}/KKI2009-${timeID}-labels.DKT31.manual.nii.gz";

    my $outlabels = "${outdir}/${name}LabelsDKT25.nii.gz";
    my $outlabels2 = "${outdir}/${name}LabelsDKT31.nii.gz";

    my $dtioutlabels = "${outdir}/${name}DTILabelsDKT25.nii.gz";
    my $dtioutlabels2 = "${outdir}/${name}DTILabelsDKT31.nii.gz";

    my $aal = "${base}/data/Kirby/S_template_aal.nii.gz";
    my $aallabels = "${outdir}/${name}LabelsAAL.nii.gz";
    my $dtiaallabels = "${outdir}/${name}DTILabelsAAL.nii.gz";
 
    my $brainmask = "${outdir}/${name}BrainExtractionMask.nii.gz";
    my $n4 = "${outdir}/${name}BrainSegmentation0N4.nii.gz";
    my $brain = "${outdir}/${name}Brain.nii.gz";

    if ( ! -s "$brain" ) {
      print PREPROCESS "${ants}ImageMath 3 $brain m $n4 $brainmask \n";
    }
    
    if ( ( ! -s "$labels" ) || ( ! -s "$outlabels") ) {
      
      my $altTime = $times[0];
      # Register this data to other time point for same subject
      if ( $idx < 1 ) {
        $altTime = $times[1];
      }
      chomp($altTime);
      my @alttimepath = split("/", $altTime );
      my $altTimeID =  $alttimepath[scalar(@alttimepath)-1];
      
      my $altOutdir = "${base}/data/MMRR-21_processed/$subID/${altTimeID}";
      $labels = "${altTime}/KKI2009-${altTimeID}-labels.DKT25.manual.nii.gz";
      $labels2 = "${altTime}/KKI2009-${altTimeID}-labels.DKT31.manual.nii.gz";

      my $altName= "${subID}_${altTimeID}_";
      my $altbrainmask =  "${altOutdir}/${altName}BrainExtractionMask.nii.gz";
      my $altn4 = "${altOutdir}/${altName}BrainSegmentation0N4.nii.gz";
      my $altbrain = "${altOutdir}/${altName}Brain.nii.gz";

      if ( ! -s "$altbrain" ) {
        print PREPROCESS "${ants}ImageMath 3 $altbrain m $altn4 $altbrainmask \n";
      }

      if ( ! -s "${outdir}/${name}intrasub0GenericAffine.mat") {
        my $reg = "${ants}antsRegistration -d 3 -o [ ${outdir}/${name}intrasub, ${outdir}/${name}alt.nii.gz ] -m mi[ $brain, $altbrain, 1, 32, Regular, 0.3 ] -t Rigid[0.2] -f 4x2x1 -s 2x1x0vox --winsorize-image-intensities [0.005, 0.995] -c [1500x1500x100, 1.e-8, 10] -l 1 -u 1 -b 0 -z 1 \n";
        print PREPROCESS $reg;
      }

      # T1 Mindboggle Labels
      my $warp = "${ants}/antsApplyTransforms -d 3 -i $labels -o ${outlabels} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $brain \n";
      print PREPROCESS $warp;

      my $warp2 = "${ants}/antsApplyTransforms -d 3 -i $labels2 -o ${outlabels2} -n NearestNeighbor -t ${outdir}/${name}intrasub0GenericAffine.mat -r $brain \n";
      print PREPROCESS $warp2;

      # DTI Mindboggle Labels
      my $dtiwarp = "${ants}/antsApplyTransforms -d 3 -i $labels -o ${dtioutlabels} -n NearestNeighbor -t [ ${outdir}/${name}B02MPRAGE0GenericAffine.mat, 1] -t ${outdir}/${name}B02MPRAGE1InverseWarp.nii.gz -t ${outdir}/${name}intrasub0GenericAffine.mat -r ${outdir}/${name}B0.nii.gz \n";
      print PREPROCESS $dtiwarp;

      my $dtiwarp2 = "${ants}/antsApplyTransforms -d 3 -i $labels2 -o ${dtioutlabels2} -n NearestNeighbor -t [ ${outdir}/${name}B02MPRAGE0GenericAffine.mat, 1] -t ${outdir}/${name}B02MPRAGE1InverseWarp.nii.gz -t ${outdir}/${name}intrasub0GenericAffine.mat -r ${outdir}/${name}B0.nii.gz \n";
      print PREPROCESS $dtiwarp2;

    }
    else {
      print PREPROCESS "cp $labels ${outlabels} \n";
      print PREPROCESS "cp $labels2 ${outlabels2} \n";   

      # DTI Mindboggle Labels
      my $dtiwarp = "${ants}/antsApplyTransforms -d 3 -i $labels -o ${dtioutlabels} -n NearestNeighbor -t [ ${outdir}/${name}B02MPRAGE0GenericAffine.mat, 1] -t ${outdir}/${name}B02MPRAGE1InverseWarp.nii.gz -r ${outdir}/${name}B0.nii.gz \n";
      print PREPROCESS $dtiwarp;

      my $dtiwarp2 = "${ants}/antsApplyTransforms -d 3 -i $labels2 -o ${dtioutlabels2} -n NearestNeighbor -t [ ${outdir}/${name}B02MPRAGE0GenericAffine.mat, 1] -t ${outdir}/${name}B02MPRAGE1InverseWarp.nii.gz -r ${outdir}/${name}B0.nii.gz \n";
      print PREPROCESS $dtiwarp2;

    }

    # Remove labels that are "undefined" and only exist in some images ( a few voxels each )
    my @badlabels = (1032,1033,2032,2033);
    foreach my $nonlabel (@badlabels) {
      print PREPROCESS "${ants}ImageMath 3 $outlabels ReplaceVoxelValue $outlabels $nonlabel $nonlabel 0\n";
      print PREPROCESS "${ants}ImageMath 3 $outlabels2 ReplaceVoxelValue $outlabels2 $nonlabel $nonlabel 0\n";
      print PREPROCESS "${ants}ImageMath 3 $dtioutlabels ReplaceVoxelValue $dtioutlabels $nonlabel $nonlabel 0\n";
      print PREPROCESS "${ants}ImageMath 3 $dtioutlabels2 ReplaceVoxelValue $dtioutlabels2 $nonlabel $nonlabel 0\n";
    }

    if ( ( ! -s "$aallabels" ) || ( ! -s "{${outdir}/${name}DTILabelsCorticalAAL.nii.gz" ) ) {

      print PREPROCESS "${ants}ThresholdImage 3 $outlabels ${outdir}/${name}CorticalMask.nii.gz 1 inf \n";      

      print PREPROCESS "${ants}ThresholdImage 3 $dtioutlabels ${outdir}/${name}DTICorticalMask.nii.gz 1 inf \n";

      my $aalwarp = "${ants}/antsApplyTransforms -d 3 -i $aal -o ${outdir}/${name}LabelsAAL.nii.gz -n NearestNeighbor -t ${outdir}/${name}TemplateToSubject1Warp.nii.gz -t ${outdir}/${name}TemplateToSubject0GenericAffine.mat -r $brain \n";
      print PREPROCESS $aalwarp;

      print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}LabelsCorticalAAL.nii.gz m ${outdir}/${name}LabelsAAL.nii.gz  ${outdir}/${name}CorticalMask.nii.gz \n";

      my $dtiaalwarp = "${ants}/antsApplyTransforms -d 3 -i $aal -o ${outdir}/${name}DTILabelsAAL.nii.gz -n NearestNeighbor -t [ ${outdir}/${name}B02MPRAGE0GenericAffine.mat, 1] -t ${outdir}/${name}B02MPRAGE1InverseWarp.nii.gz -t ${outdir}/${name}TemplateToSubject1Warp.nii.gz -t ${outdir}/${name}TemplateToSubject0GenericAffine.mat -r ${outdir}/${name}B0.nii.gz \n";
      print PREPROCESS $dtiaalwarp;

      print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}DTILabelsCorticalAAL.nii.gz m ${outdir}/${name}DTILabelsAAL.nii.gz  ${outdir}/${name}DTICorticalMask.nii.gz \n";

      print PREPROCESS "${ants}ThresholdImage 3 ${outdir}/${name}DTILabelsCorticalAAL.nii.gz ${outdir}/${name}DTILabelsCorticalAALMask.nii.gz 1 90 \n";

      print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}DTILabelsCorticalAAL.nii.gz m ${outdir}/${name}DTILabelsCorticalAAL.nii.gz  ${outdir}/${name}DTILabelsCorticalAALMask.nii.gz \n";

      # Add in deep gray structures to prevent unconnected components that make this difficult later
      my @deepgray = (37,38,41,42,73,74,75,76,77,78);
      foreach my $struct ( @deepgray ) {
        print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}DTILabelsCorticalAAL.nii.gz ReplaceVoxelValue ${outdir}/${name}DTILabelsCorticalAAL.nii.gz $struct $struct 0 \n";
        print PREPROCESS "${ants}ThresholdImage 3 ${outdir}/${name}DTILabelsAAL.nii.gz ${outdir}/tmp.nii.gz $struct $struct \n";      
        print PREPROCESS "${ants}ImageMath 3 ${outdir}/tmp.nii.gz m ${outdir}/tmp.nii.gz $struct \n";
        print PREPROCESS "${ants}ImageMath 3 ${outdir}/${name}DTILabelsCorticalAAL.nii.gz + ${outdir}/${name}DTILabelsCorticalAAL.nii.gz ${outdir}/tmp.nii.gz \n";
      }

     }

    close(PREPROCESS);
    $idx = $idx + 1;

    if ( -s ${jobname} ) {
      my $job = "qsub -V -pe serial 2 -S /bin/sh -wd $outdir ${jobname}";
      system($job);
      sleep(2);
    }
  }
}


