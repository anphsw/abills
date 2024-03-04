package Abills::Api::Postman::Utils;

use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

our @EXPORT = qw(
  read_file
  write_to_file
);

our @EXPORT_OK = qw(
  read_file
  write_to_file
);

#**********************************************************
=head2 read_file($path) read file content

  Arguments
    $path: str    - full path of file where store info

=cut
#**********************************************************
sub read_file {
  my ($path) = @_;

  my $content = undef;

  if (open(my $fh, '<', $path)) {
    while(<$fh>) {
      $content .= $_;
    }

    close($fh);
  }
  else {
    print "Can not open file for read '$path' $!. Skip read operation";
  }

  return $content;
}

#**********************************************************
=head2 write_to_file($path, $content) write info to file

  Arguments
    $path: str    - full path of file where store info
    $content: str - content which need to save

=cut
#**********************************************************
sub write_to_file {
  my ($path, $content) = @_;

  if (open my $fh, '>', $path) {
    print $fh $content;
    close $fh;

    print "File saved $path\n";
  }
  else {
    print "Can't open '$path' $!. Skip write operation\n";
  }

  return 1;
}

1;
