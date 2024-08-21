=head1 NAME

 billd plugin

 Standart execute
    /usr/abills/libexec/billd internet_deposit_correction

     Arg:
      TP_ID - id of internet tariff
      CORRECTION - correction sum will add to user's balance (CORRECTION = 1)
      UID

 DESCRIBE: Correcting user's deposit if paid for more than a month and amount of internet tariff is increased

=cut

use strict;
use warnings FATAL => 'all';
use Users;
use Fees;
use Payments;

our (
  $db,
  $Admin,
  %conf,
  %lang,
  $argv,
  $base_dir
);

do "$base_dir/language/" . ($conf{default_language} || 'english') . ".pl";

my $Internet = Internet->new($db, $Admin, \%conf);
my $Users = Users->new($db, $Admin, \%conf);
my $Fees = Fees->new($db, $Admin, \%conf);
my $Payments = Payments->new($db, $Admin, \%conf);

deposit_correction();

#**********************************************************
=head2 deposit_correction()

=cut
#**********************************************************
sub deposit_correction {

  if (!$argv->{TP_ID}){
    print "Error. It's not specified TP_ID \n";
    return 1;
  }

  my $tp_user_list = $Internet->user_list({
    TP_ID        => $argv->{TP_ID},
    UID          => $argv->{UID} ? $argv->{UID} : '_SHOW',
    DEPOSIT      => '>0',
    MONTH_FEE    => '_SHOW',
    DESCRIBE_AID => '_SHOW',
    TP_NAME      => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 1000000
  });

  return 1 if (!$Internet->{TOTAL});

  if ($tp_user_list->[0]->{month_fee} == 0){
    print "TP ID: $argv->{TP_ID}. Month fee is 0 \n";
    return 1;
  }
  if (!$tp_user_list->[0]->{describe_aid} || $tp_user_list->[0]->{describe_aid} !~ /^\d+$/){
    print "TP ID: $argv->{TP_ID}. New amount of tariff plan is not specified in the field 'DESCRIBE_AID' \n";
    return 1;
  }

  my $total = 0;

  foreach my $user_tp (@$tp_user_list) {
    next if ($user_tp->{deposit} < $user_tp->{month_fee});

    my $abon_count = int($user_tp->{deposit}/$user_tp->{month_fee});
    my $correction_amount = ($abon_count * $user_tp->{describe_aid}) - ($abon_count * $user_tp->{month_fee});
    my $new_deposit = sprintf("%.2f",$user_tp->{deposit} + $correction_amount);
    my $corrected = '';

    if ($argv->{CORRECTION}){
      my $user = $Users->info($user_tp->{uid});
      $Payments->add($user, {
        SUM      => $correction_amount,
        METHOD   => 5,
        DESCRIBE => "$lang{DEPOSIT} $lang{CORRECTION}",
      });

      if ($Payments->{INSERT_ID}){
        $corrected = '(CORRECTED)';
      }
    }

    print "UID: $user_tp->{uid}, DEPOSIT: $user_tp->{deposit}, CORRECTION: $correction_amount, NEW DEPOSIT: $new_deposit $corrected\n" ;
    $total++;
  }
  print "\nTOTAL: $total\n\n";

  return;
}