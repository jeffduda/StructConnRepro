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

my @extensions = (".nii.gz");

my @subs= glob( "${base}/data/MMRR-21_ids/*" );
my $template = "${base}/data/MMRR-21_template/MMRR-21_template.nii.gz";
my $mask = "${base}/data/MMRR-21_template/MMRR-21_template_mask.nii.gz";

system( "${ants}/ThresholdImage 3 $template $mask 1 inf");
system("${ants}/ImageMath 3 $mask MD $mask 3");
system("${ants}/ImageMath 3 $mask ME $mask 3 ");
system("${ants}/ImageMath 3 $mask FillHoles $mask 3 ");
system("${ants}/ImageMath 3 $mask GetLargestComponent $mask 3 ");
system("${ants}/ImageMath 3 $mask G $mask 3 ");
system("${ants}/ThresholdImage 3 $mask $mask 0.2 inf" );
system("${ants}/ImageMath 3 $mask MD $mask 5");

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
    my $name = "${subID}_${timeID}_";

    # Job file can not start with a number
    my $jobname = "${outdir}/SCR_${name}align.sh";
    open(PROCESS,">${jobname}") or die "Can't write preprocess script";

    my $submask = "${outdir}/${name}brainmask.nii.gz";
    my $t1 =  "${outdir}/${name}MPRAGE_N4.nii.gz";

    if ( ! -s "$t1" ) {
      print("Missing required inputs for $name \n");
      exit(1);
    }

    my $reg = "${ants}antsRegistration -d 3 -u 1 -w [0.01,0.99] -r [ $template, $t1, useCenterOfMass ] -x [ $mask, $submask ] -o [ ${outdir}/${name}template, ${outdir}/${name}deformed.nii.gz ] -m MI[${template},${t1},1,32,Regular,0.25] -c [1000x500x250x100,1e-8,10] -t Affine[0.1] -f 8x4x2x1 -s 3x2x1x0 -m CC[${template},${t1},1,4,Regular,0.25] -c [100x100x70x20,1e-8,10] -t SyN[0.1,3,0] -f 8x4x2x1 -s 3x2x1x0 -z 1 \n";

    print PROCESS $reg;
    close(PROCESS);

    my $job = "qsub -V -pe serial 2 -S /bin/sh -wd $outdir ${jobname}";
    system($job);
    sleep(2);

  }
}



