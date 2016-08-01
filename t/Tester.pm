package Tester;
#use strict;
#use warnings FATAL => 'all';

#test specific
use Test;
use TAP::Harness;

use vars qw(
  $sql_type
  $global_begin_time
  %conf
  @MODULES
  %functions
  %FORM
  $users
 );
$sql_type = 'mysql';

my $libpath = '..';

my $libs = [
    $libpath,
    $libpath . "/Abills/$sql_type/",
    $libpath . "/Abills/",
    $libpath . "/Abills/modules/",
    $libpath . "/lib/",
    $libpath . '/libexec/',
    "$libpath/misc/mikrotik"
];

#require "../libexec/config.pl";

my $modules_directory = "$libpath/Abills/modules/";
my $nases_directory = "$libpath/lib/Abills/Nas/";
my $sender_directory = "$libpath/lib/Abills/Sender/";

my $harness = TAP::Harness->new( {
        verbosity => 1,
        lib       => $libs,
    } );

if ( $ARGV[0] ) {
  # First arg is name of module
  my $module_name = $ARGV[0];
  my @module_tests = @{ get_list_of_files_in( "$libpath/Abills/modules/$module_name/t", 't' ) };

  $harness->runtests( @module_tests );
}
else {

  my @tests = @{ find_tests_in( [
          $modules_directory,
          $nases_directory,
          $sender_directory
      ] )};


  # Run all tests
  $harness->runtests( @tests );
}


#$harness->summary();


#**********************************************************
=head2 find_tests_in($test_dirs)

=cut
#**********************************************************
sub find_tests_in {
  my ($test_dirs) = @_;

  my @test_files = ();

  foreach my $dir ( @{$test_dirs} ) {
    #open modules dir
    #    print "$dir \n";
    my @directories_inside = ();
    #read names of directories inside
    opendir ( my $tests_dir, "$dir" ) or do {
      print " Error opening /$dir/ : $!";
      next
    };
    while (my $file = readdir( $tests_dir )) {
      next if ($file =~ /\./);
      if ( -d "$dir$file" ) {
        push ( @directories_inside, "$dir$file" );
      }
    }
    closedir( $tests_dir );

    #check each directory for t/
    foreach my $directory ( @directories_inside ) {
      push (@test_files, @{ get_list_of_files_in($directory, 't') });
    }

  }

  return \@test_files;
}

#**********************************************************
=head2 get_list_of_files_in($dir_name[, $extension]) - get filenames in a directory

  Arguments:
     $dir_name    - directory to look in
     [$extension] - filter by extension

  Returns:
    \@arr_ref     - filenames

=cut
#**********************************************************
sub get_list_of_files_in {
  my ($dir_name, $extension) = @_;

  my @result = ();

  opendir ( my $dir_inside, $dir_name ) or next;

  while (my $file = readdir( $dir_inside )) {
    next if ($file =~ /^\.*$/ || ( $extension && $file != /\.$extension$/ ));

    print "Found $dir_name/$file \n";

    push ( @result, "$dir_name/$file" );
  }

  closedir( $dir_inside );

  return \@result;
}




1;