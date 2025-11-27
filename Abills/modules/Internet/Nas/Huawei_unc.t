=head1 NAME

  Huawei UNC test

=cut
use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use JSON;

BEGIN {
  our $libpath = $Bin . '/../../../../';
  require "$libpath/libexec/config.pl";
  # my $sql_type = 'mysql';
  # unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
}

our (
  %conf
);

use Abills::Base;
#require 'libexec/config.pl';
require Internet::Nas::Huawei_unc;

Internet::Nas::Huawei_unc->import();

my $argv = parse_arguments(\@ARGV);

my $login = $argv->{LOGIN};
my $host = $argv->{HOST};
my $password = $argv->{PASSWORD};

my $Hunc = Internet::Nas::Huawei_unc->new(\%conf, {
  HOST     => $host,
  LOGIN    => $login,
  PASSWORD => $password,
  DEBUG    => $argv->{DEBUG} || 1
});

if ($argv->{filter}) {
  if ($Hunc->can('online_filter')) {
    my $value = $argv->{filter} || '8904f10100290504f101098e4b72c0';
    $Hunc->online_filter($value);
  }
}
else {
  $Hunc->test();
}

1