#!/usr/bin/perl

=head1 NAME

  Huawei UNC test

=head1 DESCRIPTION

  Script add and delete users from Huawei UNC

  Output:
    0 - Error
    1 - Success


=cut
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use JSON;

BEGIN {
  our $libpath = $Bin . '/../../../../';
  require "$libpath/libexec/config.pl";
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

our (
  %conf
);

use Abills::Base qw(parse_arguments);
require Internet::Nas::Huawei_unc;
Internet::Nas::Huawei_unc->import();

my $script_aid = -11;
my $argv = parse_arguments(\@ARGV);

my $message = q{};

_activate($argv);

#print "$result: $message";

#print "$result:$message";

#**********************************************************
=head2 _activate($attr) Change tp in next period

  Argumnets:
    $attr
      LOGIN
      HOST
      PASSWORD
      DEBUG

  Returns:
    $debug_output

=cut
#**********************************************************
sub _activate {
  my ($attr) = @_;

  my $result = 1;

  my $debug = $attr->{DEBUG} || 1;
  $attr->{CID} ||= $attr->{CPE_MAC} || '';

  if ($debug > 0) {
    print "1:";
  }

  # 401100000000195

  if (!$attr->{CID}) {
    if ($debug) {
      print "0:WRONG CPE_MAC: ";
    }
    else {
      print "1:NO_ACTIONS";
    }
    return 0;
  }

  if ($attr->{CID} !~ /\d{15}/xm) {
    print "1:WRONG CPE_MAC_FORMAT";
    return 0;
  }

  if (!$attr->{TP_FILTER_ID}) {
    print "1:NO_FILTERS";
    return 0;
  }

  my $login = $attr->{LOGIN};
  my $host = $attr->{HOST};
  my $password = $attr->{PASSWORD};

  my $Hunc = Internet::Nas::Huawei_unc->new(\%conf, {
    HOST       => $host,
    LOGIN      => $login,
    PASSWORD   => $password,
    DEBUG      => 4 || $debug,
    DEBUG_FILE => $conf{INTERNET_SERVICE_DEBUG_FILE} || q{}, # '/tmp/huawei_mng.log'
  });

  $Hunc->{AID} = $attr->{AID} || $script_aid;

  if ($debug > 4) {
    foreach my $key (sort keys %$attr) {
      print "$key - $attr->{$key}\n";
    }
  }

  if ($attr->{DISABLE}) {
    if ($attr->{DISABLE} == 2) {
      $Hunc->addSubscriber($attr);
      $message = "DISABLED";
    }
    else {
      $Hunc->unSubscribeService($attr);
      if (!$Hunc->{error}) {
        $message = "DISABLED";
      }
    }
  }
  else {
    $Hunc->user_add($attr);
    if (!$Hunc->{error}) {
      $message = "ADDED";
    }
  }

  if ($Hunc->{error}) {
    if ($Hunc->{error}) {
      print "1:ERROR: $Hunc->{error} $Hunc->{errstr}. WRONG CPE_MAC or CID";
    }
    else {
      print "0:ERROR: $Hunc->{error} $Hunc->{errstr}";
    }
    return 0;
  }

  print "$result:$message";

  return 1;
}

1;