#!/usr/bin/perl

=head1 NAME

  Company EDRPOU test via API

  Execute: company_edrpou.t <edrpou>

=cut

use strict;
use warnings;

use lib '../';
use FindBin '$Bin';

require $Bin . '/../libexec/config.pl';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

use XML::Simple;
use JSON::XS;
use Abills::Fetcher qw/web_request/;

our (
  %conf
);

companies_edrpou_test();

#**********************************************************
=head2 unifi()

=cut
#**********************************************************
sub companies_edrpou_test {

  if (!$conf{COMPANY_API_DATA_EDRPOU}) {
    print "Undefined \$conf{COMPANY_API_DATA_EDRPOU}. \nGo to http://abills.net.ua/wiki/pages/viewpage.action?pageId=6258917\n";
    return 1;
  }
  if (!$ARGV[0]) {
    print "No parameter EDRPOU\n";
    return 1;
  }

  my $url = "$conf{COMPANY_API_DATA_EDRPOU}?egrpou=$ARGV[0]";
  my $result = web_request($url, {
    CURL    => 1,
    HEADERS => [ 'Content-Type: text/xml' ],
  });

  my $xml = XML::Simple->new;
  my $data = $xml->XMLin($result);
  my $json = JSON::XS->new->utf8->encode($data);

  print $json || '';
  print "\n";

  return 1;
}
1;