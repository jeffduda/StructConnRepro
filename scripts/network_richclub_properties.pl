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
my $petiole = "/Users/jtduda/pkg/ITK/Build/bin/petiole";
my $regioninfo = "${base}/data/info/labels.surface.DKT31.camino.names.txt";
my $aalinfo = "${base}/data/info/aal.cortical.nii.txt";

my @extensions = (".nii.gz");

my @labelsets = ("aal","dkt31");
my @methods = ("euler","fact","rk4","tend");

foreach my $label (@labelsets) {
  foreach my $method (@methods) {
    #print( "$label $method\n");
    my @files = glob( "${base}/data/MMRR-21_processed/*/*/*_${method}_${label}_sc.csv" );

    my $tmprc  = "${base}/data/Statistics/tmprc.csv";

    open(CLUB,">${base}/data/Statistics/richclub_${method}_${label}.csv") or die "Can't write richclub csv";
    print CLUB "File,";

    my $dstart = 3;
    my $di = 1;
    my $dend = 90;
    my $dval = $dstart;
 
    while ( $dval <= $dend ) {
      print CLUB "$dval";      
      $dval = $di + $dval;
      if ( !($dval > $dend) ) {
        print CLUB ","; 
      }
      else {
        print CLUB "\n"; 
      }
    }
    
    foreach my $file (@files) {
      
      chomp($file);
      print( "$file \n" );
      print CLUB "$file,"; 

      my $dstart = 3;
      my $di = 1;
      my $dend = 70;
      my $dval = $dstart;
      
      while ( $dval <= $dend ) {
        
        `${petiole}GraphDensityThreshold $file 0.15 $tmprc`;
        my $rcc = `${petiole}RichClubCoefficient $tmprc $dval`;

        chomp($rcc);
        print CLUB $rcc;

        $dval = $dval + $di;
        if ( !($dval > $dend) ) {
          print CLUB ",";
        }
        else {
          print CLUB "\n";
        }
      }
    }
    close CLUB;
      
    }
}





