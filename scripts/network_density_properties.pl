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
    
    # Get Density to determine allowable comparison range
    my $mindensity = 1.0;
    foreach my $file ( @files ) {
      chomp($file);
      my $den = `${petiole}GraphDensity $file`;
      chomp($den);

      if ( $den < $mindensity ) {
        $mindensity = $den;
      }
    }
 
    my $mindensity2 = int(1000*$mindensity) / 1000;
    print ( "\n $label $method $mindensity $mindensity2 \n" );

    my $tmp = "${base}/data/Statistics/tmp.csv";
    #open(ASSORT,">${base}/data/Statistics/assort_${method}_${label}.csv") or die "Can't write assort csv";
    #print ASSORT "File,";
    #open(CPATH,">${base}/data/Statistics/pathlength_${method}_${label}.csv") or die "Can't write path csv";
    #print CPATH "File,";
    #open(CLUST,">${base}/data/Statistics/clustering_${method}_${label}.csv") or die "Can't write clustering csv";
    #print CLUST "File,";
    #open(GEFF,">${base}/data/Statistics/gefficiency_${method}_${label}.csv") or die "Can't write gefficiency csv";
    #print GEFF "File,";
    open(LEFF,">${base}/data/Statistics/lefficiency_${method}_${label}.csv") or die "Can't write lefficiency csv";
    print LEFF "File,";
    #open(CCSIZE,">${base}/data/Statistics/ccsize_${method}_${label}.csv") or die "Can't write ccsize csv";
    #print CCSIZE "File,";
    my $dstart = 0.005;
    my $di = 0.005;
    my $dval = $dstart;
 
    while ( $dval <= $mindensity2 ) {
      #print ASSORT "$dval";      
      #print CPATH "$dval";
      #print CLUST "$dval";
      #print GEFF "$dval";
      print LEFF "$dval";
      #print CCSIZE "$dval";

      $dval = $di + $dval;
      if ( !($dval > $mindensity2) ) {
        #print ASSORT ","; 
        #print CPATH ",";
        #print CLUST ",";
        #print GEFF ",";
        print LEFF ",";
        #print CCSIZE ",";
      }
      else {
        #print ASSORT "\n"; 
        #print CPATH "\n";
        #print CLUST "\n";
        #print GEFF "\n";
        print LEFF "\n";
        #print CCSIZE "\n";
      }
    }
    
    foreach my $file (@files) {
      
      chomp($file);
      print("$file \n" );
      #print ASSORT "$file,"; 
      #print CPATH "$file,";
      #print CLUST "$file,";
      #print GEFF "$file,";
      print LEFF "$file,";
      #print CCSIZE "$file,";

      my $dstart = 0.005;
      my $di = 0.005;
      my $dval = $dstart;
      
      while ( $dval <= $mindensity2 ) {
  
        `${petiole}GraphDensityThreshold $file $dval $tmp`;
        #my $assort = `${petiole}GraphAssortativity $tmp`;
        #my $path = `${petiole}CharacteristicPathLength $tmp 0`;
        #my $clust = `${petiole}MeanNodeClusteringCoefficient $tmp 0`;
        #my $globaleff = `${petiole}GlobalEfficiency $tmp 0`;
        my $localeff = `${petiole}MeanLocalEfficiency $tmp`;
        #my $ccsize = `${petiole}LargestConnectedComponentSize $tmp`;

        #chomp($assort);
        #print ASSORT $assort;
          
        #chomp($path);
        #print CPATH $path;

        #chomp($clust);
        #print CLUST $clust;

        #chomp($globaleff);
        #print GEFF $globaleff;
        
        chomp($localeff);
        print LEFF $localeff;

        #chomp($ccsize);
        #print CCSIZE $ccsize;

        $dval = $dval + $di;
        if ( !($dval > $mindensity2) ) {
          #print ASSORT ",";
          #print CPATH ",";
          #print CLUST ",";
          #print GEFF ",";
          print LEFF ",";
          #print CCSIZE ",";  
      }
        else {
          #print ASSORT "\n";
          #print CPATH "\n";
          #print CLUST "\n";
          #print GEFF "\n";
          print LEFF "\n";
          #print CCSIZE "\n";
        }
      }
    }
    #close ASSORT;
    #close CPATH;
    #close CLUST;
    #close GEFF;
    close LEFF;
    #close CCSIZE;
      
    }
}





