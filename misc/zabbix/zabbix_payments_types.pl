#!/usr/bin/perl -w
#**********************************************************
=head1 NAME

 Zabbix payment types

  Arguments:
    id - id payment method
    count/sum/name - count, total sum or name of payments
    daily/monthly - if daily - today's payments are shown, if monthly - current month's payments are shown

=head1  EXAMPLE

  /usr/abills/misc/zabbix/zabbix_payments_types.pl 1 count daily
  /usr/abills/misc/zabbix/zabbix_payments_types.pl 0 sum monthly
  /usr/abills/misc/zabbix/zabbix_payments_types.pl 2 name

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use FindBin '$Bin';

BEGIN {
  my $libpath = "$Bin/../../";
  my $sql_type = 'mysql';
  do $libpath . 'libexec/config.pl';

  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . 'Abills/modules/',
    $libpath . '/lib/',
    $libpath . '/Abills/',
    $libpath
  );
}

use Abills::SQL;
use Abills::Misc qw/_translate/;
use Admins;
use Finance;

our (
  %conf,
  $base_dir,
);

my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $debug = 0;

if (@ARGV) {
  payments_types(\@ARGV);
}

#**********************************************************
=head2 payments_types($attr)

  Arguments:
    id
    count/sum
    daily/monthly

  Result:
    float

=cut
#**********************************************************
sub payments_types {
  my ($attr) = @_;
  my %search_params = ();

  my $Payments = Finance->payments($db, $admin, \%conf);
  $search_params{METHOD} = $attr->[0] if (defined($attr->[0]));

  if (defined($attr->[0]) && $attr->[1] && $attr->[1] eq 'name') {
    do "$base_dir/language/$conf{default_language}.pl";

    $Payments->payment_type_info({ ID => $attr->[0] });
    my $payment_name = _translate($Payments->{NAME});
    print $payment_name."\n";
    return;
  }

  if ($attr->[2]) {
    use POSIX qw(strftime);
    my $cur_date = strftime("%Y-%m-%d", localtime(time));

    if ($attr->[2] eq 'daily') {
      $search_params{FROM_DATE} = $cur_date;
    }
    elsif ($attr->[2] eq 'monthly'){
      my $cur_month = strftime("%Y-%m", localtime(time));
      $search_params{FROM_DATE} = $cur_month . '-01';
    }

    $search_params{TO_DATE} = $cur_date;
  }

  if ($debug) {
    $Payments->{debug} = 1;
  }

  $Payments->list({
    %search_params,
    TOTAL_ONLY     => 1,
    SKIP_DEL_CHECK => 1,
    PAGE_ROWS      => 10000000,
    COLS_NAME      => 1
  });

  print $Payments->{TOTAL} || 0 if ($attr->[1] && $attr->[1] eq 'count');
  print $Payments->{SUM} || 0 if ($attr->[1] && $attr->[1] eq 'sum');
  print "\n";

  return 1;
}

1;