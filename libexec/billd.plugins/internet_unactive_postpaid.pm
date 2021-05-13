=head1 NAME

   internet_unactive_postpaid();

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

use Time::Piece;

require Internet;
require Users;
use Tariffs;
use Fees;

my $Internet = Internet->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $Admin);


internet_unactive_postpaid();

#**********************************************************
=head2 internet_unactive_postpaid()

=cut
#**********************************************************
sub internet_unactive_postpaid{

  if($debug > 1) {
    print "internet_status_postpaid\n";
    if($debug > 6) {
      $Internet->{debug}=1;
      $Tariffs->{debug}=1;
    }
  }

  my $tar_plan = 0;
  if ($argv->{TARPLAN_TP_ID}) {
    $tar_plan= $argv->{TARPLAN_TP_ID};
  }

  my $user_login = '';
  if ($argv->{LOGIN}) {
    $user_login = $argv->{LOGIN};
  }

  my $tp_list = $Tariffs->list({
    TP_ID                 => '_SHOW',
    POSTPAID_MONTHLY_FEE  => '_SHOW',
    ABON_DISTRIBUTION     => '_SHOW',
    MONTH_FEE             => '_SHOW',
    MONTH_TRAF_LIMIT      => '_SHOW',
    ID                    => '_SHOW',
    %LIST_PARAMS,
    COLS_NAME        => 1,
    COLS_UPPER       => 1
  });

  foreach my $tp ( @$tp_list ) {
    if($debug > 1) {
      print "TP_ID: $tp->{tp_id} \n";
    }

    my $month_fee = $tp->{MONTH_FEE};

    if($tp->{POSTPAID_MONTHLY_FEE} == 1 || $tar_plan ){

      my $internet_list = $Users->list({
        INTERNET_ACTIVATE => '_SHOW',
        LOGIN             => '_SHOW',
        DEPOSIT           => '_SHOW',
        CREDIT            => '_SHOW',
        TP_CREDIT         => '_SHOW',
        MONTH_FEE         => '>0',
        TP_ID             => $tp->{tp_id},
        INTERNET_STATUS   => 0,
        COLS_NAME         => 1,
        PAGE_ROWS         => 10000000,
        %LIST_PARAMS
      });

      foreach my $users(@$internet_list){
        my $uid = $users->{uid};

        if(($user_login eq $users->{login}) && ($users->{deposit} <= -$month_fee)){
          if ($debug < 6) {
            $Internet->change({
              UID    => $uid,
              STATUS => 5,
            });
          }

          print "UID: $uid status 5 \n";

          return 1;
        }
        else {
          if ($users->{deposit} <= -$month_fee) {
            if ($debug > 1) {
              print "UID: $uid ";
            }

            if ($debug < 6) {
              $Internet->change({
                UID    => $uid,
                STATUS => 5,
              });
            }

            print "UID: $uid status 5 \n";

          }
        }
      }
    }

  }
  return 1;
}

1;
