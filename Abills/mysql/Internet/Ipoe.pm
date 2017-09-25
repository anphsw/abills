package Internet::Ipoe;

=head1 NAME

  Internet IPoE module managment functions

=cut

use strict;
use parent qw( main );
use Tariffs;
use Users;
use Fees;
use POSIX qw(strftime mktime);

our $VERSION = 1.00;
my $MODULE = 'Internet_ipoe';

my ($admin, $CONF);

#my $SORT      = 1;
#my $DESC      = '';
#my $PG        = 0;
#my $PAGE_ROWS = 25;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $CONF,
    module_name => $MODULE,
  };

  bless($self, $class);

  return $self;
}

#*******************************************************************
=head2 online_alive($attr)

 AMon Alive Check
 online_alive($i);

=cut
#*******************************************************************
sub online_alive {
  my $self = shift;
  my ($attr) = @_;

  my $session_id = ($attr->{SESSION_ID}) ? "and acct_session_id='$attr->{SESSION_ID}'" : '';

  $self->query2("SELECT CID FROM dv_calls
   WHERE  user_name='$attr->{LOGIN}'
    and framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}');"
  );

  if ($self->{TOTAL} > 0) {
    my $sql = "UPDATE dv_calls SET  lupdated=UNIX_TIMESTAMP(),
    CONNECT_INFO='$attr->{CONNECT_INFO}',
    status=3
     WHERE user_name = '$attr->{LOGIN}'
    $session_id
    and framed_ip_address=INET_ATON('$attr->{REMOTE_ADDR}')";

    $self->query2($sql, 'do');
    $self->{TOTAL} = 1;
  }

  return $self;
}

#**********************************************************
=head1 user_status($DATA)



=cut
#**********************************************************
#@deprecated
# Use internet sessions online
sub user_status {
  my $self = shift;
  my ($DATA) = @_;

  my $SESSION_START = 'now()';
  my $sql  = '';

  my $nas_id = $DATA->{NAS_ID_SWITCH} || $DATA->{NAS_ID} || 0;

  #Get active session
  $self->query2("SELECT framed_ip_address FROM internet_online WHERE
    user_name='$DATA->{USER_NAME}'
    AND acct_session_id='IP'
    AND nas_id='$nas_id' LIMIT 1;");

  if ($self->{TOTAL} > 0) {
    $sql = "UPDATE dv_calls SET
      status='$DATA->{ACCT_STATUS_TYPE}',
      started=$SESSION_START,
      lupdated=UNIX_TIMESTAMP(),
      nas_port_id='$DATA->{NAS_PORT}',
      acct_session_id='$DATA->{ACCT_SESSION_ID}',
      framed_ip_address=INET_ATON('$DATA->{FRAMED_IP_ADDRESS}'),
      cid='$DATA->{CALLING_STATION_ID}',
      connect_info='$DATA->{CONNECT_INFO}'
    WHERE user_name='$DATA->{USER_NAME}'
      AND acct_session_id='IP'
      AND nas_id='$nas_id' LIMIT 1;";
    $self->query2("$sql", 'do');
  }
  else {
    $self->query_add('internet_online', {
      %$DATA,
      STATUS          => $DATA->{ACCT_STATUS_TYPE} || 1,
      STARTED         => $SESSION_START,
      LUPDATED        => 'UNIX_TIMESTAMP()',
      NAS_PORT_ID     => $DATA->{NAS_PORT},
      FRAMED_IP_ADDRESS=>"INET_ATON('$DATA->{FRAMED_IP_ADDRESS}')",
      CID             => $DATA->{CALLING_STATION_ID},
      NAS_ID          => $nas_id,
    });
  }

  return $self;
}

#*******************************************************************
=head2 ipn_log_rotate($attr) Delete information from detail table and log table

  Arguments:
    $attr
      PERIOD
      DETAIL

  Returns:
    $self

=cut
#*******************************************************************
sub log_rotate {
  my $self = shift;
  my ($attr) = @_;

  #yesterday date
  #my $DATE = (strftime("%Y_%m_%d", localtime(time - 86400)));
  #my ($Y, $M, $D) = split(/_/, $DATE);
  my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  my ($Y, $M, $D) = split(/-/, $DATE, 3);

  $DATE =~ s/\-/\_/g;

  my @rq      = ();
  my $version = $self->db_version();
  $attr->{PERIOD} = 30 if (! $attr->{PERIOD});
  #Detail Daily rotate
  if ($attr->{DETAIL}) {
    $self->query2("SELECT count(*) FROM ipn_traf_detail;", undef, { DB_REF => $self->{db2} });

    if ($self->{list}->[0]->[0] > 0) {
      $self->query2("SHOW TABLES LIKE 'ipn_traf_detail_$DATE';", undef, { DB_REF => $self->{db2} });
      if ($self->{TOTAL} == 0 && $version > 4.1) {
        @rq = ('CREATE TABLE IF NOT EXISTS ipn_traf_detail_new LIKE ipn_traf_detail;',
          'RENAME TABLE ipn_traf_detail TO ipn_traf_detail_' . $DATE . ', ipn_traf_detail_new TO ipn_traf_detail;',
        );
      }
      else {
        @rq = ("DELETE FROM ipn_traf_detail WHERE f_time < f_time - INTERVAL 1 DAY;");
      }
    }

    $self->query2("SHOW TABLES LIKE 'ipn_traf_detail_%'", undef,  { DB_REF => $self->{db2} });
    foreach my $table_name (@{ $self->{list} }) {
      $table_name->[0] =~ /(\d{4})\_(\d{2})\_(\d{2})$/;
      my ($log_y, $log_m, $log_d) = ($1, $2, $3);
      my $seltime  = POSIX::mktime(0, 0, 0, $log_d, ($log_m - 1), ($log_y - 1900));
      my $cur_time = time;
      if (($cur_time - $seltime) > (86400 * $attr->{PERIOD})) {
        push @rq, "DROP table `$table_name->[0]`;";
      }
    }

    if($self->{db2}) {
      foreach my $query (@rq) {
        $self->query2($query, 'do', { DB_REF => $self->{db2} });
      }
      @rq = ();
    }

    push @rq, 'TRUNCATE TABLE ipn_unknow_ips;';
  }

  if($attr->{DAILY_LOG}) {
    push @rq, 'DROP TABLE IF EXISTS ipn_log_new;',
      'CREATE TABLE ipn_log_new LIKE ipn_log;',
      'DROP TABLE IF EXISTS ipn_log_backup;',
      'RENAME TABLE ipn_log TO ipn_log_backup, ipn_log_new TO ipn_log;',
      'CREATE TABLE IF NOT EXISTS ipn_log_' . $Y . '_' . $M . '_'. $D .' LIKE ipn_log;',
      'INSERT INTO ipn_log_' . $Y . '_' . $M . '_' . $D ." (
        uid,
        start,
        stop,
        traffic_class,
        traffic_in,
        traffic_out,
        nas_id, ip,
        interval_id,
        sum,
        session_id
         )
       SELECT
        uid, DATE_FORMAT(start, '%Y-%m-%d %H:00:00'), DATE_FORMAT(stop, '%Y-%m-%d %H:00:00'), traffic_class,
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m-%d')='$Y-$M-$D'
        GROUP BY 2, traffic_class, ip, session_id;",
      "INSERT INTO ipn_log (
      uid,
      start,
      stop,
      traffic_class,
      traffic_in,
      traffic_out,
      nas_id, ip,
      interval_id,
      sum,
      session_id
       )
     SELECT
      uid, DATE_FORMAT(start, '%Y-%m-%d 00:00:00'), DATE_FORMAT(stop, '%Y-%m-%d 00:00:00'), traffic_class,
      SUM(traffic_in), SUM(traffic_out),
      nas_id, ip, interval_id, SUM(sum), session_id
      FROM ipn_log_backup
      WHERE DATE_FORMAT(start, '%Y-%m-%d')>'$Y-$M-$D'
      GROUP BY 2, traffic_class, ip, session_id;";
  }

  #IPN log rotate
  if ($attr->{LOG} && $version > 4.1) {
    push @rq, 'DROP TABLE IF EXISTS ipn_log_new;',
      'CREATE TABLE ipn_log_new LIKE ipn_log;',
      'DROP TABLE IF EXISTS ipn_log_backup;',
      'RENAME TABLE ipn_log TO ipn_log_backup, ipn_log_new TO ipn_log;',
      'CREATE TABLE IF NOT EXISTS ipn_log_' . $Y . '_' . $M . ' LIKE ipn_log;',
      'INSERT INTO ipn_log_' . $Y . '_' . $M . " (
        uid,
        start,
        stop,
        traffic_class,
        traffic_in,
        traffic_out,
        nas_id, ip,
        interval_id,
        sum,
        session_id
         )
       SELECT
        uid, DATE_FORMAT(start, '%Y-%m-%d'), DATE_FORMAT(stop, '%Y-%m-%d'), traffic_class,
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m')='$Y-$M'
        GROUP BY 2, traffic_class, ip, session_id;", "INSERT INTO ipn_log (
        uid,
        start,
        stop,
        traffic_class,
        traffic_in,
        traffic_out,
        nas_id, ip,
        interval_id,
        sum,
        session_id
         )
       SELECT
        uid, DATE_FORMAT(start, '%Y-%m-%d'), DATE_FORMAT(stop, '%Y-%m-%d'), traffic_class,
        SUM(traffic_in), SUM(traffic_out),
        nas_id, ip, interval_id, SUM(sum), session_id
        FROM ipn_log_backup
        WHERE DATE_FORMAT(start, '%Y-%m')>'$Y-$M'
        GROUP BY 2, traffic_class, ip, session_id;";
  }

  foreach my $query (@rq) {
    $self->query2("$query", 'do');
  }

  return $self;
}

1

