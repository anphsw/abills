# billd plugin
#**********************************************************
=head1

 billd plugin

 Standart execute
    /usr/abills/libexec/billd internet_status

    Attr:
     UID
     DISABLE_STATUS - set internet status for disable
     DEBUG

 DESCRIBE: Changing user's internet status if negative deposit

=cut
#*********************************************************
use strict;
use warnings FATAL => 'all';
use Internet;

our (
  $argv,
  $db,
  %conf
);

our Admins $Admin;
our $admin = $Admin;
my $Internet = Internet->new($db, $admin, \%conf);

internet_status();

#**********************************************************
=head2 internet_status($argv)

=cut
#**********************************************************
sub internet_status {

  my $users_list = $Internet->user_list({
    UID             => $argv->{UID} ? $argv->{UID} : '_SHOW',
    FIO             => '_SHOW',
    DEPOSIT         => '<-1',
    INTERNET_STATUS => 0,
    PAGE_ROWS       => 10000,
    COLS_NAME       => 1,
  });

  return if (!$Internet->{TOTAL});

  foreach my $user (@$users_list) {
    print "UID: $user->{uid}, DEPOSIT: $user->{deposit}\n" if ($argv->{DEBUG});

    $Internet->user_change({
      ID     => $user->{id},
      UID    => $user->{uid},
      STATUS => $argv->{DISABLE_STATUS} ? $argv->{DISABLE_STATUS} : 5 ,
    });
  }

  print "\nUSERS TOTAL: $Internet->{TOTAL}\n" if ($argv->{DEBUG});

  return 1;
}

1