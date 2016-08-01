#!/usr/bin/perl

=head1 NAME

  Show Dv warning message

=cut

use FindBin '$Bin';

my $debug   = 0;
my $version = 0.02;

require $Bin . '/../libexec/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");

require Abills::SQL;
Abills::SQL->import();

require Abills::Base;
Abills::Base->import();

require Admins;
Admins->import();
require Dv_Sessions;
Dv_Sessions->import();
require Dv;
Dv->import();

require Finance;
Finance->import();

require Users;
Users->import();

my $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $admin = Admins->new($db, \%conf);
my $Fees = Finance->fees($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID},
                 { 
                   IP        => '127.0.0.1',
                   SHORT     => 1 
                 });


require "Abills/Misc.pm";

my $ARGV = parse_arguments(\@ARGV);

if ($ARGV->{help}) {
  exit;
}

$lang{START_MONTH_DEPOSIT} = 'Депозит По состоянию на 01.%m%.%Y%: %DEPOSIT%';
$lang{PAYMENT_MESSAGE} = 'Пожалуйста, оплатите платеж до 15.%m%.%Y%';


show_warning();

#**********************************************************
#
#**********************************************************
sub show_warning {

  if ($debug > 1 ) {
    print "Args: ";
    print %$ARGV;
    print "\n";
  }

  my ($Y, $m, $d)=split(/\-/, $DATE);

  my $user_list = $Users->list({ LOGIN     => $ARGV->{LOGIN}, 
                                 DEPOSIT   => '_SHOW', 
                                 COLS_NAME => 1,
                                 PAGE_ROWS => 1 
                               });

  my $user_deposit  =  $user_list->[0]->{deposit};
  my $month_deposit = 0;

  my $list = $Fees->list({ 
      LOGIN     => $ARGV->{LOGIN} || '-',
      SUM       => '_SHOW',
      LAST_DEPOSIT => '_SHOW',
      DATE      => "<=$Y-$m-01",
      COLS_NAME => 1,
      SORT      => 'id',
      DESC      => 'DESC',
      PAGE_ROWS => 1    
  }) ;

  if ($Fees->{TOTAL} > 0) {
    $month_deposit = $list->[0]->{last_deposit} - $list->[0]->{sum};
  }
  else {
    $month_deposit = 0;
  }

  $lang{START_MONTH_DEPOSIT} =~ s/%m%/$m/g;
  $lang{START_MONTH_DEPOSIT} =~ s/%Y%/$Y/g;
  $lang{START_MONTH_DEPOSIT} =~ s/%DEPOSIT%/$month_deposit/g;

  print $lang{START_MONTH_DEPOSIT} . "\n";
  
  if ($user_deposit < 0 && $user_deposit <= $month_deposit) {
    $lang{PAYMENT_MESSAGE} =~ s/%m%/$m/g;
    $lang{PAYMENT_MESSAGE} =~ s/%Y%/$Y/g;
    $lang{PAYMENT_MESSAGE} =~ s/%DEPOSIT%/$month_deposit/g;
    print "<br><font color='red'>$lang{PAYMENT_MESSAGE}</font>";
  }

  return 1;
}


#**********************************************************
#
#**********************************************************
sub help() {

print << "[END]";
Version: $version
  
[END]

  return 1;  
}

1

