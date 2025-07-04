#!/usr/bin/perl -w
# use strict;
# use warnings FATAL => 'all';

use lib '../libexec/';

our (
  $DATE,
  $TIME,
  %conf
);

require "config.pl";

print "Content-Type: text/html\n\n";

my $buffer = '-';

my $count = $ENV{'CONTENT_LENGTH'} || 0;
if ($ENV{'REQUEST_METHOD'} eq 'POST') {
  read(STDIN, $buffer, $count);
}

$buffer .= "\n";
my $filename = $conf{base_dir} .'/var/log/csp.log';
if (open (my $fh, '>>', $filename)) {
  #`echo "BUFFER ($count): $ENV{'REQUEST_METHOD'} $buffer" >> csp.log`;
  print $fh "$DATE $TIME $ENV{REMOTE_ADDR} ";
  print $fh $buffer;
  close($fh);
}
else {
  print "Filename: $filename Error: $!\n"
}

1;