# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/abills/libexec/billd fees_last_remove

    Attr:
     UID
     DEBUG - if DEBUG=8, show users and fees without removing

 DESCRIBE:  Remove last fees if deposit is negative (less than -1) AND internet status = 5 ( $lang{ERR_SMALL_DEPOSIT} )

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use Fees;
use Internet;
use Abills::Misc qw(_error_show);

our (
  $argv,
  $db,
  %conf
);

our Admins $Admin;
our $admin = $Admin;

my $Fees = Fees->new($db, $admin, \%conf);
my $Internet = Internet->new($db, $admin, \%conf);

fees_last_remove();

#**********************************************************
=head2 fees_last_remove($argv)

=cut
#**********************************************************
sub fees_last_remove {

  my ($Y, $m, $d) = split('-', $DATE);
  my $i = 0;

  #previuos month
  if ($m == 01){
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

1