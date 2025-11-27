=head1 NAME

   internet_unactive();

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

my $t = localtime;

require Internet;
require Internet::Sessions;
my $Internet = Internet->new($db, $Admin, \%conf);
my $Sessions = Internet::Sessions->new($db, $Admin, \%conf);

internet_unactive($argv);

#**********************************************************
=head2 internet_unactive()

=cut
#**********************************************************
sub internet_unactive{
  my ($attr)=@_;

  my $last_activity_date = '';
  my $date_now = $t->ymd;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100000;

  if ($attr->{PERIOD}) {
    $last_activity_date = $attr->{PERIOD};
  }
  else {
    my $t2 = $t - 7776000;
    $last_activity_date = $t2->ymd;
  }

  if ($debug > 6) {
    $Sessions->{debug}=1;
  }

  my $sum_traffic = 0;
  if ($attr->{TRAFFIC_SUM}) {
    $sum_traffic = $attr->{TRAFFIC_SUM};
  }

  my $WHERE = qq{ WHERE i.disable=0 AND u.registration <= '$last_activity_date' };
  if ($attr->{LOGIN}) {
    $WHERE .= " AND  u.id='$attr->{LOGIN}' "
  }

  my $sql = <<"SQL";
SELECT
  i.id,
  u.uid,
  SUM(l.recv) AS traffic_sum,
  l.start
FROM users u
       LEFT JOIN internet_main i ON (u.uid=i.uid)
       LEFT JOIN internet_log l ON (u.uid=l.uid AND (DATE_FORMAT(l.start, '%Y-%m-%d')>='$last_activity_date' and DATE_FORMAT(l.start, '%Y-%m-%d')<='$date_now'))
  $WHERE
GROUP BY u.uid
HAVING traffic_sum<=$sum_traffic
LIMIT $PAGE_ROWS;
SQL

  my $alive_list = $Sessions->query($sql, undef, { COLS_NAME => 1 });

  if ($Sessions->{TOTAL} && $Sessions->{TOTAL} > 0) {
    foreach my $u (@{ $alive_list->{list} }) {
      my $uid = $u->{uid};
      if ($debug > 1) {
        print "UID: $uid ";
        # print "LOGIN: $u->{login} ACTIVATE: $u->{internet_activate} DEPOSIT: $u->{deposit} CREDIT: $u->{credit} STATUS: $u->{internet_status} \n";
      }

      if ($debug < 6) {
        $Internet->user_change({
          UID      => $uid,
          STATUS   => 5,
          ID       => $u->{id},
          COMMENTS => 'BILLD_INTERNET_UNACTIVATE'
        });
      }

      print "$DATE $TIME UID: $uid unactive\n";
    }
  }

  return 1;
}

1;
