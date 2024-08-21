#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

if (scalar @ARGV != 1) {
  die "Oops, you did not specify which folder need to unlink\n";
}

my $dir = $ARGV[0];

if (!-d $dir) {
  die "Error: $dir is not a valid directory\n";
}

sub process_directory {
  my ($directory) = @_;

  opendir(my $dh, $directory) or die "Cannot open directory $directory: $!\n";

  while (my $file = readdir($dh)) {
    next if $file eq '.' or $file eq '..';

    my $path = "$directory/$file";

    if (-d $path) {
      process_directory($path);
    }
    elsif (-f $path && $file eq '.postman-id') {
      print "Deleting file: $path\n";
      unlink $path or warn "Failed to delete $path: $!\n";
    }
  }

  closedir($dh);
}

process_directory($dir);

print "Completed deleting .postman-id files from $dir\n";

1;
