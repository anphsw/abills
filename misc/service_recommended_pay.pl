#!/usr/bin/perl
=head1

  Extended service recomended pay

=cut

use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

our $VERSION = 0.71;
BEGIN {
  our %conf;
  require $Bin . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../Abills/modules/',
    $Bin . "/../Abills/$conf{dbtype}");
}

use Abills::SQL;
use Admins;
use Users;
use Abills::Base qw(parse_arguments days_in_month);
use Abills::Init;
use Control::Recommended_pay;

require Abills::Misc;

our (
  %conf,
  $db,
  $admin,
  $DATE
);

my $Recommended_pay = Control::Recommended_pay->new($db, $admin, \%conf);

my $argv = parse_arguments(\@ARGV);
my $user = get_test_user($argv);
my $result = 0;
if (!$argv->{DATE}) {
  $argv->{DATE} = $DATE;
}

if ($argv->{MODEL}) {
  $result = $Recommended_pay->recomended_sum_triplay($user, $argv);
}
elsif ($argv->{MODEL_RECOMMENDED_SUM_AS_DEPOSIT}) {
  $result = $Recommended_pay->recomended_sum_as_deposit($user, $argv);
}
else {
  $result = $Recommended_pay->recomended_sum_default($user, $argv);
}

print $result;

1;
