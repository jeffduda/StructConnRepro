#!/opt/local/bin/perl -w
use strict;
use File::Path;
use File::Spec;
use File::Basename;
use LWP::Simple;

my @extensions = ( ".nii.gz", ".nii", ".tar.gz", ".tar", ".tar.bz2" );

sub DownloadFiles {
  my $failure = 0;
  foreach my $url ( @_ ) {
    my ($filename, $filebase, $fileext ) = fileparse( $url, @extensions ); 

    if ( ! -s $filename.$fileext ) {
      system( "wget $url" );
    }

    if ( ! -s $filename.$fileext ) {
      print ( "Failed to download: $url\n" );
      $failure = 1;
    }
  }
  return( $failure );
}
  
# Get the mindboggle MMRR-21 template and manually defined labels
my @mindboggleurls = ( "http://mindboggle.info/data/mindboggle101/MMRR-21_volumes.tar.gz", "http://mindboggle.info/data/templates/ants/MMRR-21_template.nii.gz", "http://mindboggle.info/data/templates/ants/MMRR-21_head_template.nii.gz" );
if ( ( ! -d "MMRR-21_volumes" ) || ( ! -d "MMRR-21_template" ) ) {
  if ( DownloadFiles( @mindboggleurls ) ) {
    exit 1;
  }
  system( "tar xfz MMRR-21_volumes.tar.gz" );
  system( "rm MMRR-21_volumes.tar.gz" );
  system( "mkdir MMRR-21_template" );
  system( "mv MMRR-21_template.nii.gz MMRR-21_template/." );
  system( "mv MMRR-21_head_template.nii.gz MMRR-21_template/." );
}

my $kirbybase = "http://www.nitrc.org/frs/downloadlink.php/22";
my @kirbyurls = ();
for ( my $i = 1; $i <= 42; $i++) {
  my $id = sprintf( "%02d", $i );
  push( @kirbyurls, $kirbybase.$id );
}
print ( "@kirbyurls \n " );
if ( ! -d "MMRR-21_subjects" ) {
  system( "mkdir MMRR-21_subjects" );
  if ( DownloadFiles( @kirbyurls ) ) {
    exit 1;
  }
  foreach my $url ( @kirbyurls ) {
    my ($filename, $filebase, $fileext ) = fileparse( $url, @extensions ); 
    system ( "bunzip2 ${filename}.${fileext}" );    
  }
  

#}







