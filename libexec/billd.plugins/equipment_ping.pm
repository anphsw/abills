=head1 NAME

   equipment ping

   Arguments:

     TIMEOUT

=cut

use Equipment;
use Net::Ping;
use Events::API;
our (
  $Admin,
  $db,
  %conf,
  $argv,
  $base_dir,
);

my $Equipment = Equipment->new( $db, $Admin, \%conf );
my $Events = Events::API->new( $db, $Admin, \%conf );

equipment_ping();


#**********************************************************
=head2 equipment_ping($attr)

  Arguments:
    
    
  Returns:
  
=cut
#**********************************************************
sub equipment_ping {
  my ($attr) = @_;

  my $timeout = $attr->{TIMEOUT} || '4';

  my $p = Net::Ping->new( 'syn' ) or die "Can't create new ping object: $!\n";

  my $equipment = $Equipment->_list( {
      COLS_NAME => 1,
      PAGE_ROWS => 100000,
      NAS_IP    => '_SHOW',
      STATUS    => '0;1',
      NAS_NAME  => '_SHOW'
    } );

  my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
  my $datetime = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

  my %ips;
  foreach my $host (@$equipment) {
    $ips{$host->{nas_ip}} = { NAS_ID => $host->{nas_id}, STATUS => $host->{status}, NAS_NAME => $host->{nas_name} };
  }

  my %syn;
  my %ret_time;
  foreach my $key (keys %ips) {
    my ($ret, $duration, $ip) = $p->ping( $key, $timeout );
    if ($ret) {
      $syn{$key} = $ip;
      $ret_time{$key} = $duration;
    }
    else {
      print "$key address not found\n";
    }
  }
  my $message = '';
  while (my ($host, undef, undef) = $p->ack) {
    if ($ips{$host}{STATUS} == 1) {
      $message .= "$ips{$host}{NAS_NAME}($host) _{AVAILABLE}_\n";
    }
    $Equipment->_change({
      NAS_ID        => $ips{$host}{NAS_ID},
      STATUS        => 0,
      LAST_ACTIVITY => $datetime
    });

    $Equipment->ping_log_add({
      DATE     => $datetime,
      NAS_ID   => $ips{$host}{NAS_ID},
      STATUS   => 1,
      DURATION => $ret_time{$host},
    });

    print " $host is reachable\n" if ( $debug > 1);
    delete $syn{$host};
  }
  foreach my $host (keys %syn) {
    if ($ips{$host}{STATUS} == 0) {
      $Equipment->_change( { NAS_ID => $ips{$host}{NAS_ID}, STATUS => 1 } );
      $message .= "$ips{$host}{NAS_NAME}($host) _{UNAVAILABLE}_\n";
    }

    $Equipment->ping_log_add({
      DATE     => $datetime,
      NAS_ID   => $ips{$host}{NAS_ID},
      STATUS   => 0,
      DURATION => $timeout,
    });

    print " $host is unreachable\n" if ( $debug > 1);
  }

  $p->close;

  if ($message) {
    ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
    my $datestr = sprintf("%02d:%02d:%02d %02d.%02d.%04d", $hour, $min, $sec, $mday, $mon + 1, $year + 1900);
    $message = $datestr . "\n$message";
    generate_new_event( "$message" );
  }

  return 1;
}

#**********************************************************
=head2 generate_new_event($comments)

  Arguments:
    $comments - text of message to show

  Returns:

=cut
#**********************************************************
sub generate_new_event{
  my ($comments) = @_;

  #  print "EVENT: $name, $comments \n";
  print $comments . "\n" if ($argv->{DEBUG});

  $Events->add_event({
    MODULE      => "Equipment",
    PRIORITY_ID => 5,
    STATE_ID    => 1,
    TITLE       => '_{WARNING}_',
    COMMENTS    => $comments,
  });
  
  return 1;
}

1
