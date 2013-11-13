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
my $petiole = "/Users/jtduda/pkg/ITK/Build/bin/petiole";
my $regioninfo = "${base}/data/info/labels.surface.DKT31.camino.names.txt";
my $aalinfo = "${base}/data/info/aal.cortical.nii.txt";

my @extensions = (".nii.gz");

my @labelsets = ("aal","dkt31");
my @methods = ("euler","fact","rk4","tend");

foreach my $label (@labelsets) {
  foreach my $method (@methods) {
    my @files = glob( "${base}/data/MMRR-21_processed/*/*/*_${method}_${label}_sc.csv" );

    open(DEGREE,">${base}/data/Statistics/meandegree_${method}_${label}.csv") or die "Can't write degree csv";
    print DEGREE "File,Degree";
    
    foreach my $file (@files) {
      
      chomp($file);
      my $deg = `${petiole}MeanNodeDegree $file`;
      chomp($deg);
      print DEGREE "${file},${deg}\n";;
    }   
  }
}





