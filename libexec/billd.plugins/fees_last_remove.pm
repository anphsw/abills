# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/abills/libexec/billd fees_last_remove

    Attr:
     UID
     DEBUG - if DEBUG=8, show users and fees without removing
     FINE  - add fine to fees (FINE=1)

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use Fees;
use Internet;
use Abills::Misc;

our (
  $argv,
  $db,
  %conf,
  $base_dir,
  %lang,
);

our Admins $Admin;
our $admin = $Admin;
do "$base_dir/language/$conf{default_language}.pl";

my $Fees = Fees->new($db, $admin, \%conf);
my $Internet = Internet->new($db, $admin, \%conf);

if ($argv->{FINE}){
  fees_last_remove_with_fine();
}
else{
  fees_last_remove();
}


#**********************************************************
=head2 fees_last_remove($argv) - Removing last fees if deposit is negative AND internet status = 5 ( $lang{ERR_SMALL_DEPOSIT} )

=cut
#**********************************************************
sub fees_last_remove {

  my ($Y, $m, $d) = split('-', $DATE);
  my $i = 0;

  #previuos month
  if ($m == 1){
    $m = 12;
    $Y = sprintf( "%04d", $Y-1 );
  }
  else {
    $m = sprintf( "%02d", $m-1 );
  }
  print "FEES DATE: $Y-$m-01\n\n" if ($argv->{DEBUG});

  my $users_list = $Internet->user_list({
    UID          => $argv->{UID} ? $argv->{UID} : '_SHOW',
    FIO          => '_SHOW',
    INTERNET_STATUS => 5,
    DEPOSIT      => '<-1',
    PAGE_ROWS    => 10000,
    COLS_NAME    => 1,
  });

  return if (!$Internet->{TOTAL});

  foreach my $user (@$users_list) {
    my $last_fee = $Fees->list({
      UID       => $user->{uid},
      DATE      => "$Y-$m-01",
      DESC      => 'desc',
      SORT      => 1,
      PAGE_ROWS => 1,
      COLS_NAME => 1
    });

    next if (!$Fees->{TOTAL});

    print "UID:$user->{uid}, DEPOSIT:$user->{deposit}, FEE ID: $last_fee->[0]->{id}\n" if ($argv->{DEBUG});
    $i++;

    if ($argv->{DEBUG} && $argv->{DEBUG} > 7){
      next;
    }

    $Fees->del({ UID => $user->{uid} }, $last_fee->[0]->{id});

    if (!_error_show($Fees) && $argv->{DEBUG}){
      print "  REMOVED FEE ID:$last_fee->[0]->{id}\n";
    }
  }

  print "\nTOTAL:$i\n" if ($argv->{DEBUG});

  return 1;
}

#**********************************************************
=head2 fees_last_remove_with_fine($argv) -
   Removing last fees if deposit is negative and last payment more than 2 month

   Attr:
    FINE - for start function
    UID - if uids are several, indicate UIDs via comma (UID=1,5,25)
    LAST_PAYMENT_MONTH - quantity last monthes
    DEBUG - if debug > 8 - is not add/remove data to database

    EXAMPLE: /usr/abills/libexec/billd fees_last_remove FINE=1

=cut
#**********************************************************
sub fees_last_remove_with_fine {

  my $users = Users->new( $db, $admin, \%conf );
  my $last_payments_month = (defined $argv->{LAST_PAYMENT_MONTH}) ? $argv->{LAST_PAYMENT_MONTH} : 2;
  my $WHERE = '';

  if ($argv->{UID}){
    $WHERE .= <<"WHERE";
    WHERE u.uid IN ($argv->{UID})
WHERE
  }

  my $sql = <<"SQL";
  SELECT
    u.id AS login,
    u.uid AS uid,
    u.disable AS status,
    b.deposit AS deposit,
    u.bill_id AS bill_id,
    MAX(p.date) AS last_payment_date,
    MAX(DATE_FORMAT(f.date, '%Y-%m-%d')) AS last_fee_date,
    tp.fine AS fine_sum,
    TIMESTAMPDIFF(MONTH, MAX(p.date), NOW()) AS last_pay_month_count,
    (tp.fine * TIMESTAMPDIFF(MONTH, MAX(p.date), NOW())) AS fine_total
  FROM users u
       LEFT JOIN bills b ON (u.uid = b.uid)
       LEFT JOIN payments p ON (u.uid = p.uid)
       LEFT JOIN fees f ON (u.uid = f.uid)
       INNER JOIN internet_main i ON (i.uid=u.uid)
       LEFT JOIN tarif_plans tp ON (i.tp_id=tp.tp_id)
  $WHERE
  GROUP BY u.uid
  HAVING ((MAX(p.date) < NOW() - INTERVAL $last_payments_month MONTH) AND b.deposit < 0)
  ORDER by MAX(p.date) DESC
SQL

  $users->query($sql, undef, { COLS_NAME => 1 } );

  my $debtors_list = $users->{list};

  foreach my $user (@$debtors_list) {

    my $last_fees = $Fees->list({
      UID       => $user->{uid},
      DATE      => ">$user->{last_payment_date}",
      AFTER_DEPOSIT => '<0',
      METHOD_ID => '_SHOW',
      DESCRIBE  => '_SHOW',
      DESC      => 'desc',
      SORT      => 1,
      PAGE_ROWS => 100,
      COLS_NAME => 1
    });

    next if (!$Fees->{TOTAL});

    my $has_fine = 0;

    foreach my $fee (@$last_fees) {
      if ($fee->{dsc} && $fee->{dsc} =~ /$lang{FINE}/xm){
        $has_fine = 1;
      }
      if ($fee->{id} && $fee->{method_id} == 1) {
        if (!$argv->{DEBUG} || $argv->{DEBUG} && $argv->{DEBUG} < 7){
          $Fees->del({ UID => $user->{uid} }, $fee->{id});
        }
        if (!_error_show($Fees) && $argv->{DEBUG}){
          print "UID:$user->{uid} $lang{DELETED} FEE_ID:$fee->{id}\n";
        }
      }
    }

    my $monthes = ($has_fine) ? 1 : $user->{last_pay_month_count};
    my $fine = 0;

    if ($monthes && $user->{status} < 6){
      if ($monthes <= 11) {
        $fine = ($has_fine) ? $user->{fine_sum} : $user->{fine_total};
        if (!$argv->{DEBUG} || $argv->{DEBUG} && $argv->{DEBUG} < 7){
          $users->change($user->{uid}, { DISABLE => 5 }) if ($user->{status} < 5);
          $Fees->take({ UID => $user->{uid}, BILL_ID => $user->{bill_id}}, $fine, {
            DESCRIBE => "$lang{FINE} $monthes $lang{MONTHES_A2}",
            METHOD   => 2
          });
        }
      }
      elsif ($monthes > 11) {
        $users->change($user->{uid}, { DISABLE => 6 });
        if ($has_fine == 0) {
          $monthes = 12;
          $fine = $user->{fine_sum} * $monthes;
          if (!$argv->{DEBUG} || $argv->{DEBUG} && $argv->{DEBUG} < 7) {
            $Fees->take({ UID => $user->{uid}, BILL_ID => $user->{bill_id} }, $fine, {
              DESCRIBE => "$lang{FINE} $monthes $lang{MONTHES_A2}",
              METHOD   => 2
            });
          }
        }
      }
    }
    print "UID:$user->{uid} $lang{FINE}:$fine $lang{MONTHES_A2}:$monthes\n" if ($argv->{DEBUG});
  }

  return 1;
}

1;