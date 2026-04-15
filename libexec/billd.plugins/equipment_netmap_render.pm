=head1 NAME equipment_netmap_render

   getting neighbours from core and add:

   nas servers
   equipment
   equipent_ports

   ATTRIBUTES:
    SNMP_VERSION=v2c
    DEBUG
    CORE=192.168.23.13 - ip addres of main switch
    COMMUNITY - SNMP community (default publick)


=cut

use warnings FATAL => 'all';
use strict;
use Abills::Base qw(in_array startup_files _bp in_array);
use Net::SNMP;
use Equipment;
use Nas;
require Equipment::Snmp_cmd;

use SNMP_util;
use SNMP_Session;
require Abills::Misc;

our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir
);

our Admins $Admin;

$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $Nas = Nas->new($db, \%conf, $Admin);
my $Equipment = Equipment->new($db, $Admin, \%conf);

my @serials = ();
my @ips = ();
my @info = ();

equipment_grab($argv);


#***************************************************************************
=heade2 equipment_grab() - main function

=cut
#***************************************************************************
sub equipment_grab {
  my ($attr)=@_;

  if(! $attr->{CORE}) {
    print "Please addd core server ip: CORE=xxx.xxx.xxx.xxx\n";
    return 0;
  }

  my @equipment_info = @{equipment_scan($attr->{CORE})};

  foreach my $info (@equipment_info) {
    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if (!$Nas->{TOTAL}) {
      if ($debug > 0) {
        print "Not exists IP: $info->{IP}\n";
      }

      if (!$info->{NAS_TYPE}) {
        $info->{NAS_TYPE} = 'other';
      }
      if ($debug > 0) {
        _bp('NAS ADD', $info, { TO_CONSOLE => 1 });
      }
      $info->{NAS_MNG_IP_PORT} = $info->{IP} . ':::';
      $info->{NAS_MNG_PASSWORD} = $argv->{COMMUNITY} || 'public';
      $Nas->add($info);

      $info->{NAS_ID} = $Nas->{NAS_ID};
    }
    else {
      $info->{NAS_ID} = $nas_list->[0]{nas_id};
    }

  }
  foreach my $info (@equipment_info) {
    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if (!$Nas->{TOTAL}) {
      if ($debug > 0) {
        print 'NAS not exist IP:'. $info->{IP} ."\n";
      }
      next;
    }

    $info->{NAS_ID} = $nas_list->[0]{nas_id};

    $Equipment->info($info->{NAS_ID});

    if (!$Equipment->{list}) {
      if ($info->{MODEL_ID}) {
        my ($snmp_version) = $argv->{SNMP_VERSION} =~ /(\d)/xm;
        my %equipment_attr = ('NAS_ID' => $info->{NAS_ID}, COMMENTS => $info->{COMMENTS}, MODEL_ID => $info->{MODEL_ID}, SNMP_VERSION => $snmp_version);

        $Equipment->add(\%equipment_attr);
        if ($debug > 0) {
          _bp('Equipment ADD', \%equipment_attr, { TO_CONSOLE => 1 });
        }
      }
    }
    else {
      if ($debug > 0) {
        print "Equipment exist\n";
      }
    }

    if ($info->{NAS_ID} && defined $info->{PORT} && $info->{UPLINK}) {
      my $uplink = $Nas->list({
        NAS_IP    => $info->{UPLINK},
        COLS_NAME => 1,
      });

      $uplink = $uplink->[0]{id};
      my %port_attr = ('NAS_ID' => $info->{NAS_ID}, 'PORT' => $info->{PORT}, COMMENTS => $info->{COMMENTS}, 'UPLINK' => $uplink);
      $Equipment->port_info({
        NAS_ID => $info->{NAS_ID},
        PORT   => $info->{PORT},
      });
      if (!$Equipment->{TOTAL}) {
        $Equipment->port_add(\%port_attr);
      }
      if ($debug > 0) {
        _bp('PORT ADD', \%port_attr, { TO_CONSOLE => 1 });
      }
    }
  }

  return 1;
}

#***************************************************************************
=heade2 equipment_scan($nas_ip, $uplink, $port) - getting neighbours of $core

  Arguments:
    $nas_ip - ip of main switch
    $uplink - parent (optional)
    $port - uplink port(optional)

  Returns:
    \@info

=cut
#***************************************************************************
sub equipment_scan {
  my ($nas_ip, $uplink, $port) = @_;

  my $oid = "1.0.8802.1.1.2.1.4.2.1.5";
  my $community = $argv->{COMMUNITY} || 'public';

  my $list = $Equipment->model_list({
    MODEL_NAME => '_SHOW',
    COLS_NAME  => 1,
  });

  my $serial = snmp_get({
    SNMP_COMMUNITY => $community . '@' . $nas_ip,
    OID            => "1.3.6.1.2.1.47.1.1.1.1.11.1",
    SILENT         => 1,
    TIMEOUT        => 1,
    VERSION        => $argv->{SNMP_VERSION} || 1
  });

  if (in_array($serial, \@serials)) {
    if ($debug > 0) {
      print "SERIAL EXIST  " . $nas_ip ."\n";
    }
    return \@info;
  }

  push @serials, $serial;
  push @ips, $nas_ip;

  my %host = ();

  print "CHECKING IP: $community@" . $nas_ip . (($uplink) ? " UPLINK: $uplink " : q{} )
    . (($port) ? " PORT: $port " : q{}) ."\n";

  $host{IP} = $nas_ip;
  $host{PORT} = $port if ($port);
  $host{COMMENTS} = snmp_get({
    SNMP_COMMUNITY => $community . '@' . $nas_ip,
    OID            => ".1.3.6.1.2.1.1.1.0",
    SILENT         => 1,
    TIMEOUT        => 1,
    VERSION        => $argv->{SNMP_VERSION} || 1,
    DEBUG          => ($debug > 1) ? $debug - 2 : 0
  });

  $host{NAS_NAME} = snmp_get({
    SNMP_COMMUNITY => $community . '@' . $nas_ip,
    OID            => ".1.3.6.1.2.1.1.5.0",
    SILENT         => 1,
    TIMEOUT        => 1,
    VERSION        => $argv->{SNMP_VERSION} || 1,
    DEBUG          => ($debug > 1) ? $debug - 2 : 0
  });

  if ($host{COMMENTS}) {
    if ($debug || $argv->{INFO_ONLY}) {
      print "SNMP answer: ";
      print $host{COMMENTS};
      print "\n";
    }
    foreach (@$list) {
      next unless ($_->{model_name});
      if ($debug > 0) {
        if ($host{COMMENTS} =~ m/$_->{model_name}/x) {
          print "Found matches:\n model_id: '$_->{id}'\n model_name: '$_->{model_name}'\n";

          $host{MODEL_ID} = $_->{id};
        }
      }
    }
  }

  if ($host{COMMENTS}) {
    my ($session, $error) = Net::SNMP->session(
      -hostname  => $nas_ip,
      -version   => $argv->{SNMP_VERSION} || 1,
      -community => $community
    );

    if (!$session) {
      print "ERROR: " . $error . "\n";
      return [];
    }
    if ($uplink) {
      $host{UPLINK} = $uplink
    }

    my $neighbours = $session->get_table($oid);
    for my $oid_ (keys %{$neighbours}) {
      my $regex = '(\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b$)';
      if ($oid_ =~ /$regex/xm) {
        $oid_ =~ qr/$regex/x;
        my $ip = $1;
        my ($port_) = $oid_ =~ /^\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.\d+.(\d+)/xm;
        if (in_array($ip, \@ips)) {
          next;
        }
        equipment_scan($ip, $nas_ip, $port_);
      }
    }

    push @info, \%host;
  }
  else {
    print "NO RESPONSE\n";
  }

  return \@info;
}

1;
