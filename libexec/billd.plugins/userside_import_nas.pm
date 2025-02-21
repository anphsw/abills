#!perl

=head1 equipment synchronization

  Arguments:
      DEBUG
      IP - synchronization with current IP
   conf Arguments
      USERSIDE_API_URL   - Link to the userside
      USERSIDE_API_KEY - Api key
      USERSIDE_CAT    - Type of request (default is 'module')

   Execute:
   /usr/abills/libexec/billd userside_nas_sync

=cut

use Abills::Base qw/ip2int int2ip/;
use utf8;
use Equipment;
use Nas;
require Equipment::Grabbers;

our ($db, $Admin, %conf, $argv);

my $debug = $argv->{DEBUG} || '';
my $Equipment = Equipment->new($db, $Admin, \%conf);
my $Nas = Nas->new($db, \%conf, $Admin);

nas_sync($argv);

sub nas_sync {
  my ($attr)=@_;

  if ($attr->{REQUEST_TIMEOUT}) {
    $conf{USERSIDE_TIMEOUT}=$attr->{REQUEST_TIMEOUT};
  }
  if ($argv->{URL}) {
    $conf{USERSIDE_API_URL}=$argv->{URL};
  }

  use Userside::Import;
  my $Userside = Userside::Import->new(\%conf);

  if ($attr->{DEBUG}) {
    $Userside->{debug}=$attr->{DEBUG};
  }

  _log('LOG_DEBUG', "Userside: userside_import_nas");

  my $us_device_list = $Userside->fetch('get_device_list');
  my $us_device_model = $Userside->fetch('get_device_model');

  my %nas_type = (
    switch => 'switch',
    radio  => 'wifipoint',
    other  => 'other',
  );

  my ($i_add, $i_update) = (0, 0);

  foreach my $us_device (values %{$us_device_list}) {
    next if !$us_device->{ip};
    next if ($argv->{IP} && $argv->{IP} ne $us_device->{ip});

    my $nas_info = $Nas->info({ IP => $us_device->{ip} });

    my $mng_host_port = "$us_device->{ip}:3799:22:" . ($us_device->{snmp_port} || 161);
    my $mng_password = $us_device->{snmp_read_community} || '';
    my $nas_type_ = ($us_device->{type_id}) ? $nas_type{$us_device->{type_id}} : 'other';
    my $mac = $us_device->{mac} || '';
    my $entrance = $us_device->{entrance} || '';
    my $floor = $us_device->{floor} || '';
    my $snmp_version = $us_device->{snmp_version} || '';
    my $software_version = $us_device->{software_version} || '';
    my $comments = $us_device->{comment} || '';
    my $last_activity = $us_device->{date_activity} || '0000-00-00 00:00:00';

    my $us_model = $us_device_model->{$us_device->{model_id}};
    my ($model_vendor, $model_name) = ('', '');
    if ($us_model) {
      ($model_vendor, $model_name) = split(/ /, $us_model->{name});
    }
    else {
      print "$us_device->{ip} has no model data. Model id=$us_device->{model_id} \n" if ($debug);
    }

    my $model_detect = equipment_model_detect($model_name, { _EQUIPMENT => $Equipment });
    my $model_detect_id = $model_detect->[0]->{ID} || '';
    my $model_detect_type = $model_detect->[0]->{TYPE_ID} || '';

    if (!$nas_info->{IP}) {
      $Nas->add({
        IP                => $us_device->{ip},
        NAS_NAME          => ($us_model) ? $us_model->{name} : $us_device->{ip},
        NAS_DESCRIBE      => ($us_device->{comment} || '') . $us_device->{location},
        NAS_MNG_HOST_PORT => $mng_host_port,
        NAS_MNG_PASSWORD  => $mng_password,
        NAS_TYPE          => $nas_type_,
        MAC               => $mac,
        ENTRANCE          => $entrance,
        FLOOR             => $floor,
        CHANGED           => $last_activity,
        ACTION_ADMIN      => 1
      });

      if ($Nas->{INSERT_ID}) {
        print "$us_device->{ip}. Added NAS ID:$Nas->{INSERT_ID} \n" if ($debug);
        $i_add++;

        if ($model_detect_id) {
          $Equipment->_add({
            NAS_ID        => $Nas->{INSERT_ID},
            MODEL_ID      => $model_detect_id,
            TYPE_ID       => $model_detect_type,
            SNMP_VERSION  => $snmp_version,
            FIRMWARE      => $software_version,
            COMMENTS      => $comments,
            LAST_ACTIVITY => $last_activity,
          });
        }
      }
    }
    else {
      $Nas->change({
        NAS_ID            => $nas_info->{NAS_ID},
        NAS_DESCRIBE      => $nas_info->{NAS_DESCRIBE} ? $nas_info->{NAS_DESCRIBE} : $us_device->{location},
        NAS_MNG_HOST_PORT => $nas_info->{MNG_HOST_PORT} ? $nas_info->{MNG_HOST_PORT} : $mng_host_port,
        NAS_MNG_PASSWORD  => $nas_info->{MNG_PASSWORD} ? $nas_info->{MNG_PASSWORD} : $mng_password,
        NAS_TYPE          => $nas_info->{NAS_TYPE} ? $nas_info->{NAS_TYPE} : $nas_type_,
        MAC               => $nas_info->{MAC} ? $nas_info->{MAC} : $mac,
        ENTRANCE          => $nas_info->{ENTRANCE} ? $nas_info->{ENTRANCE} : $entrance,
        FLOOR             => $nas_info->{FLOOR} ? $nas_info->{FLOOR} : $floor,
      });

      print "$us_device->{ip}. Updated NAS ID:$nas_info->{NAS_ID} \n" if ($debug);
      $i_update++;

      $Equipment->_info($nas_info->{NAS_ID});
      if (!$Equipment->{MODEL_ID} && $model_detect_id) {
        $Equipment->_add({
          NAS_ID        => $Nas->{INSERT_ID},
          MODEL_ID      => $model_detect_id,
          TYPE_ID       => $model_detect_type,
          SNMP_VERSION  => $snmp_version,
          FIRMWARE      => $software_version,
          COMMENTS      => $comments,
          LAST_ACTIVITY => $last_activity,
        });
        delete($Equipment->{MODEL_ID});
      }
      else {
        $Equipment->_change({
          NAS_ID        => $nas_info->{NAS_ID},
          SNMP_VERSION  => $Equipment->{SNMP_VERSION} ? $Equipment->{SNMP_VERSION} : $snmp_version,
          FIRMWARE      => $Equipment->{FIRMWARE} ? $Equipment->{FIRMWARE} : $software_version,
          COMMENTS      => $Equipment->{COMMENTS} ? $Equipment->{COMMENTS} : $comments,
          LAST_ACTIVITY => $Equipment->{LAST_ACTIVITY} ? $Equipment->{LAST_ACTIVITY} : $last_activity,
        });
      }
    }
    delete($nas_info->{IP});
  }
  print "Nas: added - $i_add, updated - $i_update\n";

  return 1;
}

1;