=head1 NAME

   internet_unactive_postpaid();

=head1 HELP

  TP_ID=

=cut

use strict;
use warnings;

our (
  $Admin,
  $db,
  %conf,
  $argv,
  $debug,
);

use Internet;
use Tariffs;

my $Internet = Internet->new($db, $Admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $Admin);

internet_unactive_postpaid();

#**********************************************************
=head2 internet_unactive_postpaid()

=cut
#**********************************************************
sub internet_unactive_postpaid {

  if ($debug > 1) {
    print "internet_status_postpaid\n";
    if ($debug > 6) {
      $Internet->{debug} = 1;
      $Tariffs->{debug} = 1;
    }
  }

  if ($argv->{TP_ID}) {
    $LIST_PARAMS{TP_ID} = $argv->{TP_ID};
  }

  if ($argv->{LOGIN}) {
    $LIST_PARAMS{LOGIN} = $argv->{LOGIN};
  }

  my $tp_list = $Tariffs->list({
    TP_ID                => '_SHOW',
    POSTPAID_MONTHLY_FEE => 1,
    ABON_DISTRIBUTION    => '_SHOW',
    MONTH_FEE            => '>0',
    ID                   => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME            => 1,
  });

  foreach my $tp (@$tp_list) {
    if ($debug > 1) {
      print "TP_ID: $tp->{tp_id} MONTH_FEE: $tp->{month_fee}\n";
    }

    my $month_fee = $tp->{month_fee};

    my $internet_list = $Internet->user_list({
      INTERNET_ACTIVATE => '_SHOW',
      LOGIN             => '_SHOW',
      DEPOSIT           => '_SHOW',
      CREDIT            => '_SHOW',
      TP_CREDIT         => '_SHOW',
      REDUCTION         => '_SHOW',
      MONTH_FEE         => '>0',
      TP_ID             => $tp->{tp_id},
      INTERNET_STATUS   => 0,
      COLS_NAME         => 1,
      PAGE_ROWS         => 10000000,
      %LIST_PARAMS
    });

    foreach my $internet (@$internet_list) {
      my $uid = $internet->{uid};
      my $deposit = $internet->{deposit} || 0;

      if ($internet->{reduction} && $internet->{reduction} == 100) {
        next;
      }

      if ($deposit <= -$month_fee * ( 100 - $internet->{reduction} ) / 100) {
        if ($debug > 1) {
          print "UID: $uid ";
        }

        if ($debug < 6) {
          $Internet->user_change({
            UID    => $uid,
            STATUS => 5,
          });
        }

        print "UID: $uid status 5 \n";
      }
    }
  }

  return 1;
}

1;
