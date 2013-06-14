#!/usr/bin/perl -w
use strict;

#my $camino = "../software/camino/bin";
#my $ants = "../software/ANTs/ANTs-build/bin";
my $camino = "/home/jtduda/pkg/camino/bin";
my $ants = "/home/jtduda/bin/ants";

my @subs= glob( "../data/MMRR-21_subjects/*" );

foreach my $subdir (@subs) {
  chomp($subdir);
  #my $subdir = "../data/MMRR-21_subjects/${sub}";
  my $dti = glob( "${subdir}/*DTI.nii.gz" );
  chomp($dti);
  my $grads = glob( "${subdir}/*DTI.grad" );
  chomp( $grads );
  my $bvals = glob( "${subdir}/*DTI.b" );
  chomp( $bvals );
 
  my @names = split("-DTI.nii.gz", $dti);
  my $dwi = $names[0]."-DWI.nii.gz";
  my $scheme = $names[0]."-DWI.scheme";
  
  # eliminate average DWI at end of 4D image
  print ("${camino}/split4dnii -inputfile $dti -outputroot ${subdir}/dwi");
  system("${camino}/split4dnii -inputfile $dti -outputroot ${subdir}/dwi ");
  system( "rm ${subdir}/dwi0034.nii.gz" );
  system( "cp ${subdir}/dwi0033.nii.gz $names[0]-b0.nii.gz" );
  
  my @dwis = glob( "${subdir}/dwi*.nii.gz" );      
  my $dwiList = join( " ", @dwis );  
  my $nImages = scalar( @dwis );
  system("${ants}/ImageMath 4 $dwi TimeSeriesAssemble 1.0 0.0 $dwiList");
  system("${ants}/antsMotionCorr -d 3 -o [ $names[0]-DWI, $dwi, $names[0]-avgdwi.nii.gz ] -m mi[ $names[0]-b0.nii.gz , $dwi, 1 , 32 , Regular, 0.05 ]  -t Affine[ 0.25 ] -i 10 -u 1 -e 1 -s 1 -f 1 -n $nImages -l 0" ); 
  system("rm ${subdir}/dwi*.nii.gz");
  
  open(DATA,"<${grads}") or die "Can't open grad file";
  my @gradlines = <DATA>;
  close(DATA);
  
  open(DATA,"<${bvals}") or die "Can't open b file";
  my @blines = <DATA>;
  close(DATA);
  
  open(DATA,">${scheme}") or die "Can't write scheme file";
  
  print DATA "VERSION: 2\n";
  
  for (my $n = 0; $n < 33; $n++) {
    my $nGrad = $gradlines[$n];
    my $nB = $blines[$n];
    
    chomp($nGrad);
    chomp($nB);
    
    print DATA $nGrad.$nB."\n";  
  }
  
  close(DATA);
}



