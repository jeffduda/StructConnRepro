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

my ($input, $outputl, $outputr) = @ARGV;

# FIXME - maybe be these from ENV VARS
my $ants = "/home/avants/bin/ants/";

my $sensory = "sensory.nii.gz";
my $occipital = "occipital.nii.gz";
my $frontal = "frontal.nii.gz";
my $motor = "motor.nii.gz";
my $parietal = "parietal.nii.gz";
my $temporal = "temporal.nii.gz";
my $cingulate = "cingulate.nii.gz";
my $temp = "temp.nii.gz";

my @sensoryLeft = (1022);
my @occipitalLeft = (1005, 1011, 1013, 1021);
my @frontalLeft = (1003, 1012, 1014, 1018, 1019, 1020, 1027, 1028);
my @motorLeft = (1024);
my @parietalLeft = (1008, 1017, 1025, 1029, 1031);
my @temporalLeft = (1006, 1007, 1009, 1015, 1016, 1030, 1034, 1035);
my @cingulateLeft = (1002, 1010, 1023, 1026);



system( "${ants}ImageMath 3 $sensory m $input 0" );
for my $lbl ( @sensoryLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $sensory + $sensory $temp" );
}
system( "${ants}ImageMath 3 $sensory m $sensory 1" );
system( "cp $sensory $outputl" );

system( "${ants}ImageMath 3 $sensory m $input 0" );
for my $lbl ( @sensoryLeft ) { 
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $sensory + $sensory $temp" );
}
system( "${ants}ImageMath 3 $sensory m $sensory 1" );
system( "cp $sensory $outputr" );


system( "${ants}ImageMath 3 $occipital m $input 0" );
for my $lbl ( @occipitalLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $occipital + $occipital $temp" );
}
system( "${ants}ImageMath 3 $occipital m $occipital 2" );
system( "${ants}ImageMath 3 $outputl + $outputl $occipital" );

system( "${ants}ImageMath 3 $occipital m $input 0" );
for my $lbl ( @occipitalLeft ) {
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $occipital + $occipital $temp" );
}
system( "${ants}ImageMath 3 $occipital m $occipital 2" );
system( "${ants}ImageMath 3 $outputr + $outputr $occipital" );


system( "${ants}ImageMath 3 $frontal m $input 0" );
for my $lbl ( @frontalLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $frontal + $frontal $temp" );
}
system( "${ants}ImageMath 3 $frontal m $frontal 3" );
system( "${ants}ImageMath 3 $outputl + $outputl $frontal" );

system( "${ants}ImageMath 3 $frontal m $input 0" );
for my $lbl ( @frontalLeft ) { 
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $frontal + $frontal $temp" );
}
system( "${ants}ImageMath 3 $frontal m $frontal 3" );
system( "${ants}ImageMath 3 $outputr + $outputr $frontal" );


system( "${ants}ImageMath 3 $motor m $input 0" );
for my $lbl ( @motorLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $motor + $motor $temp" );
}
system( "${ants}ImageMath 3 $motor m $motor 4" );
system( "${ants}ImageMath 3 $outputl + $outputl $motor" );

system( "${ants}ImageMath 3 $motor m $input 0" );
for my $lbl ( @motorLeft ) { 
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $motor + $motor $temp" );
}
system( "${ants}ImageMath 3 $motor m $motor 4" );
system( "${ants}ImageMath 3 $outputr + $outputr $motor" );

system( "${ants}ImageMath 3 $parietal m $input 0" );
for my $lbl ( @parietalLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $parietal + $parietal $temp" );
}
system( "${ants}ImageMath 3 $parietal m $parietal 5" );
system( "${ants}ImageMath 3 $outputl + $outputl $parietal" );

system( "${ants}ImageMath 3 $parietal m $input 0" );
for my $lbl ( @parietalLeft ) { 
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $parietal + $parietal $temp" );
}
system( "${ants}ImageMath 3 $parietal m $parietal 5" );
system( "${ants}ImageMath 3 $outputr + $outputr $parietal" );

system( "${ants}ImageMath 3 $temporal m $input 0" );
for my $lbl ( @temporalLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $temporal + $temporal $temp" );
}
system( "${ants}ImageMath 3 $temporal m $temporal 6" );
system( "${ants}ImageMath 3 $outputl + $outputl $temporal" );

system( "${ants}ImageMath 3 $temporal m $input 0" );
for my $lbl ( @temporalLeft ) { 
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $temporal + $temporal $temp" );
}
system( "${ants}ImageMath 3 $temporal m $temporal 6" );
system( "${ants}ImageMath 3 $outputr + $outputr $temporal" );


system( "${ants}ImageMath 3 $cingulate m $input 0" );
for my $lbl ( @cingulateLeft ) { 
  system( "${ants}ThresholdImage 3 $input $temp $lbl $lbl" );
  system( "${ants}ImageMath 3 $cingulate + $cingulate $temp" );
}
system( "${ants}ImageMath 3 $cingulate m $cingulate 7" );
system( "${ants}ImageMath 3 $outputl + $outputl $cingulate" );

system( "${ants}ImageMath 3 $cingulate m $input 0" );
for my $lbl ( @cingulateLeft ) { 
  my $rlbl = $lbl + 1000;
  system( "${ants}ThresholdImage 3 $input $temp $rlbl $rlbl" );
  system( "${ants}ImageMath 3 $cingulate + $cingulate $temp" );
}
system( "${ants}ImageMath 3 $cingulate m $cingulate 7" );
system( "${ants}ImageMath 3 $outputr + $outputr $cingulate" );

system( "rm $temp $sensory $temporal $parietal $motor $frontal $cingulate $occipital" );
