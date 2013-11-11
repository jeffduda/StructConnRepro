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
my $regioninfo = "${base}/data/info/labels.surface.DKT31.camino.names.txt";
my $aalinfo = "${base}/data/info/aal.cortical.nii.txt";

my @extensions = (".nii.gz");

mkdir "${base}/data/MMRR-21_processed";

my @subs= glob( "${base}/data/MMRR-21_ids/*" );

foreach my $sub (@subs) {
  chomp($sub);

  my @subpath = split("/", $sub );
  my $subID =  $subpath[scalar(@subpath)-1];

  #mkdir "${base}/data/MMRR-21_processed/$subID";

  my @times = glob( "${sub}/*");
  chomp(@times);

  my $idx = 0;
  foreach my $subdir (@times) {
    chomp($subdir);
    
    my @timepath = split("/", $subdir );
    my $timeID =  $timepath[scalar(@timepath)-1];

    my $outdir = "${base}/data/MMRR-21_processed/$subID/$timeID";
    my $name = "${subID}_${timeID}_";

    print( "$name \n");

    # Job file can not start with a number
    my $jobname = "${outdir}/SCR_${name}deterministic.sh";
    open(PROCESS,">${jobname}") or die "Can't write preprocess script";
    
    my $labels = "${outdir}/${name}DTILabelsDKT31.nii.gz";
    my $aal =  "${outdir}/${name}DTILabelsCorticalAAL.nii.gz";
    my $mask = "${outdir}/${name}DTIMask.nii.gz";
    my $dti =  "${outdir}/${name}DTI.nii.gz";

    if ( (! -s "$labels" ) || ( ! -s "$dti") ) {
      print("Missing required inputs for $name \n");
      exit(1);
    }
  
    my $caminodt = "${outdir}/${name}DTI.Bfloat";  
    if ( ! -s "${caminodt}" ) {
      #print PROCESS "${ants}/RebaseTensorImage 3 $dti $localdti LOCAL"; # convert if direction mat is not Identity

      print PROCESS "${camino}/nii2dt -inputfile $dti -lns0 ${outdir}/${name}lns0.nii.gz -bgmask $mask > $caminodt \n";
    }

    # Create "seed" mask
    my $seeds = "${outdir}/${name}DTIseeds.nii.gz";
    print PROCESS "${ants}/ThresholdImage 3 ${outdir}/${name}FA.nii.gz ${seeds} 0.2 inf \n";
    print PROCESS "${ants}/ImageMath 3 $seeds m $seeds $mask \n";    

    # Shared parameters
    my $curvethresh = "-curvethresh 90";
    my $curveinterval = "-curveinterval 5";
    my $anisthresh = "-anisthresh 0.2";
    my $stepsize = "-stepsize 0.5";
    my $linearinterp = "-interpolator linear";
    my $tendinterp =   "-interpolator tend";
    my $bg = "-bgmask ${outdir}/${name}DTIMask.nii.gz";

    # FACT Tracking
    if ( ! -s  "${outdir}/${name}tracts.Bfloat" ) {
      print PROCESS "cat $caminodt | ${camino}/track -inputmodel dt -seedfile $seeds $bg -tracker fact $curvethresh $curveinterval $anisthresh > ${outdir}/${name}tracts.Bfloat \n";
      
      print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}fact_dkt31_ \n";
      
      print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}fact_dkt31_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";
      
      print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}fact_dkt31_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";
      
      print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}fact_dkt31_length_ -tractstat length \n";    
      
      print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}fact_aal_ \n";
      
      print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}fact_aal_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";
      
      print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}fact_aal_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";
      
      print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}fact_aal_length_ -tractstat length \n";    

      print PROCESS "rm ${outdir}/${name}tracts.Bfloat \n";
    }
    
    # EULER Tracking
    print PROCESS "cat $caminodt | ${camino}/track -inputmodel dt -seedfile $seeds $bg -tracker euler $curvethresh $curveinterval $anisthresh $linearinterp $stepsize > ${outdir}/${name}tracts.Bfloat \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}euler_dkt31_ \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}euler_dkt31_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}euler_dkt31_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";
    
    print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}euler_dkt31_length_ -tractstat length \n"; 

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}euler_aal_ \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}euler_aal_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}euler_aal_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";
    
    print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}euler_aal_length_ -tractstat length \n";


    print PROCESS "rm ${outdir}/${name}tracts.Bfloat \n";


    # RK4 Tracking
    print PROCESS "cat $caminodt | ${camino}/track -inputmodel dt -seedfile $seeds $bg -tracker rk4 $curvethresh $curveinterval $anisthresh $linearinterp $stepsize > ${outdir}/${name}tracts.Bfloat \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}rk4_dkt31_ \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}rk4_dkt31_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}rk4_dkt31_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";

    print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}rk4_dkt31_length_ -tractstat length \n"; 

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}rk4_aal_ \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}rk4_aal_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}rk4_aal_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";

    print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}rk4_aal_length_ -tractstat length \n"; 

    print PROCESS "rm ${outdir}/${name}tracts.Bfloat \n";

    # Tensorline Tracking
    print PROCESS "cat $caminodt | ${camino}/track -inputmodel dt -seedfile $seeds $bg -tracker rk4  $curvethresh $curveinterval $anisthresh $tendinterp $stepsize -tendf 0.0 -tendg 1.0 > ${outdir}/${name}tracts.Bfloat \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}tend_dkt31_ \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}tend_dkt31_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}tend_dkt31_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";

    print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $labels -targetnamefile $regioninfo -outputroot ${outdir}/${name}tend_dkt31_length_ -tractstat length \n"; 

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}tend_aal_ \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}tend_aal_fa_ -scalarfile ${outdir}/${name}FA.nii.gz -tractstat mean \n";

    print PROCESS "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}tend_aal_rd_ -scalarfile ${outdir}/${name}RD.nii.gz -tractstat mean \n";

    print PROCESS  "cat ${outdir}/${name}tracts.Bfloat | ${camino}/conmat -targetfile $aal -targetnamefile $aalinfo -outputroot ${outdir}/${name}tend_aal_length_ -tractstat length \n"; 

    print PROCESS "rm ${outdir}/${name}tracts.Bfloat \n";

    close(PROCESS);
    my $job = "qsub -V -pe serial 1 -v CAMINO_HEAP_SIZE=3000 -S /bin/sh -wd $outdir ${jobname}";
    system($job);
    #print( $job );
    sleep(2);

  }
}



