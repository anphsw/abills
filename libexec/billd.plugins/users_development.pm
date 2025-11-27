=head1 NAME

 billd plugin

 DESCRIBE: fill users_development table

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Internet::Reports2;
use Internet;

our (
  $argv,
  $DATE,
  $TIME,
  $debug,
  $db,
  %conf,
  $admin,
  $base_dir,
  %lang
);

my $Internet = Internet->new($db, $admin, \%conf);

users_development();

sub users_development {
  my $Reports = Internet::Reports2->new($db, $admin, \%conf);
  $Reports->users_development_report($DATE, { GROUP_BY => 'districts.name' });
  return if $Reports->{TOTAL} && $Reports->{TOTAL} > 0;

  my $internet_users_list = $Internet->user_list({
    DAY_FEE         => '_SHOW',
    MONTH_FEE       => '_SHOW',
    UID             => '_SHOW',
    INTERNET_STATUS => '_SHOW',
    DISABLE         => 0,
    COLS_NAME       => 1,
    PAGE_ROWS       => 99999
  });

  foreach my $user (@{$internet_users_list}) {
    my $sum = $user->{month_fee} || $user->{day_fee} || 0;
    $Reports->users_development_add({
      UID     => $user->{uid},
      SUM     => $sum,
      DISABLE => $user->{internet_status},
      DATE    => $DATE,
    });

    print "UID: $user->{uid}, SUM: $sum\n" if $argv->{DEBUG} && !$Reports->{errno};
  }

  return 1;
}

1;