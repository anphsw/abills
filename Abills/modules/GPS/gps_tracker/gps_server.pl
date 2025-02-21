#!/usr/bin/perl -w
=head1 NAME

  GPS Server

=head2 FILENAME

  gps_server.pl


=head2 ARGUMENTS

  -d  - Demonize
  DEBUG=[1..5] - Debug mode

  start
  stop
  restart
  status

=head2 VERSION

  VERSION: 0.4
  REVISION: 20240621

=head2 SYNOPSIS

=cut

use strict;
use warnings;
use Time::Local;
use IO::Socket::INET;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir
);

BEGIN {
  use FindBin '$Bin';

  my $libpath = "$Bin/../";
  require "$libpath/libexec/config.pl";
  unshift(@INC,
    "$libpath/",
    "$libpath/Abills",
    "$libpath/lib/",
    "$libpath/Abills/$conf{dbtype}"
  );
}

use Log;
use Abills::Base qw(parse_arguments _caller);
use Abills::Server;
use Abills::SQL;
use GPS;

my $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $Log = Log->new(undef, \%conf);
#my $Gps = GPS->new($db, undef, \%conf);

$| = 1;

my $debug = 1;
my $prog_name = "gps_tracker";
my $ARGS = parse_arguments(\@ARGV);

if ($ARGS->{DEBUG}) {
  print "Debug mode on\n";
  $debug = $ARGS->{DEBUG};

  if ($debug >= 7) {
    #    $Gps->{debug} = 1
  };
}

my %daemon_args = (
  LOG_DIR      => $base_dir . '/var/log/',
  PROGRAM_NAME => $prog_name
);

my $log_file = '/tmp/gps_tracker.log';

if (defined $ARGS->{LOG_FILE}) {
  $log_file = $ARGS->{LOG_FILE};
}

$Log->{LOG_FILE} = $log_file;



my $start = sub {
  my $pid_file = daemonize(\%daemon_args);
  log_debug("Started... $pid_file", 'Daemon', 1);
  return $pid_file;
};

my $stop = sub {
  stop_server(undef, \%daemon_args);
  log_debug('Normal exit', 'Daemon', 1);
};

if (defined($ARGS->{stop})) {
  #stop_server();
  $stop->();
  exit;
}
elsif (defined($ARGS->{start})) {
  #stop_server();
  $start->();
  exit;
}
elsif (defined($ARGS->{restart})) {
  $stop->();
  $start->();
}
elsif (defined($ARGS->{'-d'})) {
  $start->();
}
elsif (make_pid() == 1) {
  exit;
}

my $port = $ARGS->{PORT} || '8790';

my $socket = IO::Socket::INET->new(
  LocalHost => '0.0.0.0',
  LocalPort => $port,
  Proto     => 'tcp',
  Listen    => 5,
  Reuse     => 1
);

die "cannot create socket $!\n" unless ($socket);
print "server waiting for client connection on port $port\n";

$SIG{INT} = sub {
  $socket->close();
  exit 0;
};

while (1) {
  gps_server();
}

$socket->close();


#**********************************************************
=head2 gps_server()

  Arguments:

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub gps_server {

  my $client_socket = $socket->accept();

  if (!$client_socket) {
    $socket = IO::Socket::INET->new(
      LocalHost => '0.0.0.0',
      LocalPort => $port,
      Proto     => 'tcp',
      Listen    => 5,
      Reuse     => 1
    );

    $client_socket = $socket->accept();

    log_debug("AGGGGGGGGGGGGGGGGGGGAIN", '----------------' . ($client_socket || 'NOT_DEFINED'), 4);
  }

  # log_debug("0000000000000000", '++++++++ ->' . $socket, 4);
  # log_debug("0000000000000000", '----------------' . ($client_socket || 'NOT_DEFINED'), 4);

  # get information about a newly connected client
  my $client_address = $client_socket->peerhost();
  my $client_port = $client_socket->peerport();
  log_debug("Connection", localtime() . ". Connection from $client_address:$client_port", 1);

  # read up to 2048 (max GET length) characters from the connected client
  my $data = "";
  $client_socket->recv($data, 2048);
  # my $CHUNK_MAX = 1024;
  #  while ( sysread( $client_socket, my $buffer, $CHUNK_MAX ) ) {
  #    $data .= unpack( "H*", $buffer );
  #  }

  log_debug("Raw HTTP", $data, 4);

  my $request = define_the_protocol($data);
  if ($request->{gps_imei}) {
    my $mappings = get_traccar_mappings();
    my $unified_data = unify_data($request, $mappings);
    $unified_data->{IP} = $client_address;

    if($debug > 2) {
      my $res_data = q{};
      foreach my $key (sort keys %$unified_data) {
        $res_data .= "$key -> ". ($unified_data->{$key} || q{}) ."\n";
      }
      log_debug("RESULT", $res_data, 4);
    }

    my $response = add2db($unified_data);
    my $status = ($response) ? 200 : 406;

    # write response data to the connected client
    if ($request->{RESPONSE}) {
      $request->{RESPONSE} =~ s/\%response\%/$response/g;
      $request->{RESPONSE} =~ s/\%status\%/$status/g;
      $client_socket->send($request->{RESPONSE});
      #$client_socket->send("HTTP/1.1 $status $response\nContent-Length:0\n\n");
    }
  }
  else {
    log_debug("IMEI NOT DEFINED", $data, 1);
  }

  # notify client that response has been sent
  shutdown($client_socket, 1);

  return 1;
}

# #**********************************************************
# =head2 get_admin_id_by_tracker_id($gps_id)
#
#   Arguments:
#     $gps_id - GPS id
#
#   Returns:
#     Tracked admin
#
# =cut
# #**********************************************************
# sub get_admin_id_by_tracker_id {
#   my ($gps_id) = @_;
#
#   return
# }

#**********************************************************
=head2 write_to_db($attr, $ip_address)

  Arguments:
    $attr,
      GPS_IMEI
      IP

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub add2db {
  my ($attr) = @_;

  my $Gps = GPS->new($db, undef, \%conf);

  log_debug("Client ID", $attr->{GPS_IMEI}, 1);

  my $aid = $Gps->tracked_admin_id_by_imei($attr->{GPS_IMEI});

  if (!$aid) {
    log_debug("WRONG GPS ID", "Administrator with such ID not found. ID is $attr->{GPS_IMEI}", 1);
    $Gps->unregistered_trackers_add($attr);
    return 0;
  }

  $attr->{AID} = $aid;

  $Gps->location_add($attr);

  return 1;
}


#**********************************************************
=head2 parse_http_request()

  Arguments:
    $http_request

  Returns:
    $FORM

=cut
#**********************************************************
sub parse_http_request {
  my ($http_request) = @_;

  my %FORM = ();

  my $buffer = [ split(/\n/, $http_request) ]->[0];
  $buffer =~ s/^.*\?//;
  $buffer =~ s/\s.*$//;

  my @pairs = split(/&/, $buffer);
  $FORM{__BUFFER} = $buffer if ($#pairs > -1);

  foreach my $pair (@pairs) {
    my ($side, $value) = split(/=/, $pair, 2);
    if (defined($value)) {
      $value =~ tr/+/ /;
      $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
      $value =~ s/<!--(.|\n)*-->//g;
      $value =~ s/<([^>]|\n)*>//g;
    }
    else {
      $value = '';
    }
    $FORM{$side} = $value;
  }

  if ($FORM{id}) {
    $FORM{gps_imei}=$FORM{id};
    #Response for TRaccar
    $FORM{RESPONSE}="HTTP/1.1 %status% %response%\nContent-Length:0\n\n";
  }

  return \%FORM;
}


#**********************************************************
=head2 get_traccar_mappings()

  Arguments:

  Returns:

  Examples:

  This is representation of data got from traccar;
  $VAR1 = {
    'speed' => '0.0',
    'lon' => '25.079458951950073',
    'batt' => '48.0',
    'lat' => '48.569440841674805',
    'altitude' => '354.0',
    'bearing' => '8.0859375',
    'id' => '617323',
    'timestamp' => '1452233539'
  };

=cut
#**********************************************************
sub get_traccar_mappings {

  return {
    'GPS_IMEI' => 'gps_imei',
    'GPS_TIME' => 'timestamp',
    'COORD_X'  => 'lat',
    'COORD_Y'  => 'lon',
    'SPEED'    => 'speed',
    'BEARING'  => 'bearing',
    'ALTITUDE' => 'altitude',
    'BATT'     => 'batt',
    'STATUS'   => 'status',
    'PROTOCOL' => 'protocol'
  };
}

#**********************************************************
=head2 unify_data($FORM, $mapping)

  Arguments:
    $FORM,
    $mappings

  Returns:
    %$data

=cut
#**********************************************************
sub unify_data {
  my ($input, $mappings) = @_;

  my %data = ();

  for my $key (keys %{$mappings}) {
    $data{$key} = $input->{$mappings->{$key}};
  }

  return \%data;
}

#**********************************************************
=head2 log_debug($name, $str, $level)

  Arguments:
    $name,
    $str,
    $level

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub log_debug {
  my ($name, $str, $level) = @_;

  my $log_line = '';
  $level //= 1;

  if (ref $str eq 'ARRAY') {
    $str = join ", ", @{$str};
  }

  if ($debug >= $level) {
    $log_line .= "$name : $str \n";
  }

  if (! defined($ARGS->{'-d'})) {
    print "$log_line\n";
  }
  else {
    $Log->log_print('LOG_INFO', $prog_name, $log_line, { LOG_FILE => $log_file });
  }

  return 1;
}

#**********************************************************
=head2 UTC2LocalString()

  Arguments:
    $t - time

=cut
#**********************************************************
sub UTC2LocalString {
  my $t = shift;
  my ($datehour, $rest) = split(/:/, $t, 2);
  my ($year, $month, $day, $hour) = $datehour =~ /(\d+)-(\d\d)-(\d\d)\s+(\d\d)/;

  $month = $month - 1;
  if ($month eq -1) {
    return ('1970-01-01 00:00:00');
  }
  my $epoch = timegm(0, 0, $hour, $day, $month, $year);

  my ($lyear, $lmonth, $lday, $lhour, undef) = (localtime($epoch))[5, 4, 3, 2, -1];

  $lyear += 1900; # year is 1900 based
  $lmonth++;      # month number is zero based

  return (sprintf("%04d-%02d-%02d %02d:%s", $lyear, $lmonth, $lday, $lhour, $rest));
}


#**********************************************************
=head2 define_the_protocol($ps_data)

  Arguments:
    $pa_data,

  Returns:
    $FORM

=cut
#**********************************************************
sub define_the_protocol {
  my ($ps_data) = @_;
  my $result;

  #TK102
  if (substr($ps_data, 0, 2) eq '(0' && substr($ps_data, -9) eq '00000000)') {
    # (027043576388BR00150919A4949.6147N02402.0461E000.60650290.000000000000L00000000)
    $result = parse_tk103($ps_data);
  }
  elsif (substr($ps_data, 0, 3) eq '*HQ') {
    $result = parse_5013_h02($ps_data);
  }
  elsif ($conf{GPS_PROTOCOL}) {
    parse_fm_xxx($ps_data);
  }
  else {
    $result = parse_http_request($ps_data)
  }

  return $result;
}

#**********************************************************
=head2 parse_fm_xxx($ps_data) - teltonika fm_xxx

  Protocol:
    https://voxtrail.com/assets/company/Teltonika/protocol/FMXXXX_Protocols_v2.10.pdf

  Arguments:
    $pa_data,

  Returns:
    $FORM

=cut
#**********************************************************
sub parse_fm_xxx {
  my ($ps_data) = @_;

  my %FORM = ();

  my @arr = $ps_data =~ /(\S{2})/g;

  $FORM{CODEC_ID} = $arr[0] || 0;
  $FORM{NUMOFDATA} = $arr[1] || 0;
  $FORM{UNIX_TIMESTAMP} = join('', @arr[2 .. 8]) if ($#arr > 7);

  while (my ($k, $v) = each %FORM) {
    print "$k, $v\n";
  }

  return \%FORM;
}

#**********************************************************
=head2 parse_5013_h02($ps_data)

  Arguments:
    $ps_data

  Results:
    %$result

  Example:
    *HQ,9175692753,V1,102639,V,5024.5466,N,03019.7321,E,0.00,167,270624,fbfffbff,255,06,13419,701#


  https://www.traccar.org/protocol/5013-h02/GPS+Tracker+Platform+Communication+Protocol-From+Winnie+HuaSunTeK-V1.0.5-2017.pdf
  https://gpsonline.com.ua/media/SinoTrack%20Protocol%20.pdf

=cut
#**********************************************************
sub parse_5013_h02 {
  my ($ps_data, $attr) = @_;

  my %status = (
    'fbfffbff' => 0,
  );

  my ($ihdr, $gps_imei, $instruction_pkg, $time, $data_valid_bit, $latitude, $latitude_symbol,
    $longitude, $longitude_symbol,$speed,$direction,$date,
    $terminal_status, $power, $count, $country_code, $operation_code, $disctrict_code) = split(/,/, $ps_data);

  my %result = (
    gps_imei => $gps_imei,
    protocol => 'h02',
  );

  if ($instruction_pkg && $instruction_pkg eq 'V1') {
    $result{lat} = $latitude;
    $result{lon} = $longitude;
    $result{speed} = ($speed) ? $speed * 1.852 : 0;
    #  'BEARING'  => 'bearing',
    #$result{altitude},
    $result{batt}=$power;
    $result{status}=($status{$terminal_status}) ? $status{$terminal_status} : 0;

    my ($mday, $mon, $year, $hour, $min, $sec) = unpack('A2A2A2A2A2A2', $date . $time);
    $result{timestamp} = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);
  }

  return \%result;
}

#**********************************************************
=head2 parse_tk103_protokol()

  Arguments:
    $ps_data - data of protokol

  Returns:
    $FORM

  Examples:
    0
    27045495314
    BR05
    3553
    27045495314
    180604
    A
    4804.3391N
    02300.8468E
    000.0
    120438
    000.00
    00000000L00000000

=cut
#**********************************************************
sub parse_tk103 {
  my ($ps_data) = @_;

  my %result = ();
  my ($ps_dev_id, $subProtocol, $x, $y, $utcDate, $ps_local_date, $ps_x, $ps_x_1, $ps_x_2, $ps_y,
    $ps_y_1, $ps_y_2, $ps_speed) = '';

  $ps_dev_id = substr($ps_data, 2, 11);

  $result{gps_imei} = $ps_dev_id;

  $subProtocol = substr($ps_data, 13, 4);

  if ($subProtocol eq 'BP05') {
    $x = substr($ps_data, 39, 9);
    $y = substr($ps_data, 49, 10);

    $utcDate = '20' . substr($ps_data, 32, 2) . '-' . substr($ps_data, 34, 2) . '-' . substr($ps_data, 36, 2) . ' ' .
      substr($ps_data, 65, 2) . ':' . substr($ps_data, 67, 2) . ':' . substr($ps_data, 69, 2);
    $ps_local_date = UTC2LocalString($utcDate);

    $ps_x = int($x * 10000);
    $ps_x_1 = int($ps_x * 0.000001);
    $ps_x_2 = int(($ps_x - $ps_x_1 * 1000000) / 6 * 10);
    $ps_x = $ps_x_1 . '.' . substr("00" . $ps_x_2, -6);

    $ps_y = int($y * 10000);
    $ps_y_1 = int($ps_y * 0.000001);
    $ps_y_2 = int(($ps_y - $ps_y_1 * 1000000) / 6 * 10);
    $ps_y = $ps_y_1 . '.' . substr("00" . $ps_y_2, -6);

    $ps_speed = substr($ps_data, 60, 5);

    $result{lat} = $ps_x;
    $result{lon} = $ps_y;
    my ($year, $mon, $mday, $hour, $min, $sec) = split(/[\s\-\:]+/, $ps_local_date);
    my $time = timelocal($sec, $min, $hour, $mday, $mon - 1, $year);
    $result{timestamp} = $time;
  }

  return \%result;
}


1;
