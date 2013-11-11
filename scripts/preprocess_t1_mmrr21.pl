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
    my $name = "${subID}_${timeID}_";

    mkdir "$outdir";
  
    my $mprage = "${subdir}/KKI2009-${timeID}-MPRAGE.nii.gz";

    # Job file can not start with a number
    my $jobname = "${outdir}/SCR_${name}preprocess_t1.sh";
    open(PREPROCESS,">${jobname}") or die "Can't write preprocess script";

    # This handles:
    # 1. Brain extraction
    # 2. Brain 3-tissue segmentation
    # 3. Cortical thickness
    # 4. Registration to a template
    print PREPROCESS "${ants}antsCorticalThickness.sh -d 3 -a $mprage -e ${base}/data/Kirby/S_template3.nii.gz -m ${base}/data/Kirby/S_templateProbabilityMask.nii.gz -p ${base}/data/Kirby/Priors/priors%d.nii.gz -f ${base}/data/Kirby/S_templateExtractionMask.nii.gz -t ${base}/data/Kirby/S_template3.nii.gz -o ${outdir}/${name} -k 1 -n 3 -w 0.25 \n";

    close(PREPROCESS);
    $idx = $idx + 1;
    
    my $job = "qsub -V -pe serial 3 -v CAMINO_HEAP_SIZE=3000 -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=3 -S /bin/sh -wd $outdir ${jobname}";
    system($job);
    sleep(2);

  }
}



