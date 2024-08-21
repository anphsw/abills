=head1 NAME

 billd plugin

 DESCRIBE: Equipment errors

 Arguments:
   NAS_ID
   DEBUG

  EXECUTE: /usr/abills/libexec/billd equipment_errors

=cut

use strict;
use warnings;
use Equipment;
use Abills::Misc qw(snmp_get file_op);
require Equipment::Grabbers;
use Equipment::Pon_mng;

our (
  $db,
  %conf,
  $Admin,
  $argv,
  $debug,
  %lang,
  $DATE,
  $TIME
);

my $Equipment = Equipment->new($db, $Admin, \%conf);


equipment_errors();


#**********************************************************
=head2 equipment_errors ($attr)

=cut
#**********************************************************
sub equipment_errors {
  
  my $equipment_list = $Equipment->_list({
    NAS_ID           => $argv->{NAS_ID} || '_SHOW',
    NAS_IP           => '_SHOW',
    NAS_NAME         => '_SHOW',
    NAS_MNG_USER     => '_SHOW',
    NAS_MNG_PASSWORD => '_SHOW',
    NAS_MNG_HOST_PORT=> '_SHOW',
    SNMP_VERSION     => '_SHOW',
    SNMP_TPL         => '_SHOW',
    COLS_NAME        => 1,
    PAGE_ROWS        => 10000,
  });
  return if (!$Equipment->{TOTAL});

  print "Equipment total: $Equipment->{TOTAL}\n" if ($argv->{DEBUG});

  foreach my $nas (@$equipment_list) {
    next if (!$nas->{nas_ip});

    my $nas_mng_password = $nas->{nas_mng_password} || 'public';
    my $nas_mng_ip = $nas->{nas_ip};
    my $SNMP_COMMUNITY = "$nas_mng_password\@$nas_mng_ip";

    my $ports_info = equipment_test({
      NAS_INFO        => $Equipment,
      SNMP_COMMUNITY  => $SNMP_COMMUNITY,
      SNMP_TPL        => $nas->{snmp_tpl},
      VERSION         => $nas->{snmp_version} || 2,
      TIMEOUT         => 5,
      PORT_INFO       => 'PORT_IN_ERR,PORT_OUT_ERR',
    });

    return if (!$ports_info);

    foreach my $port (keys %{ $ports_info }) {
      if ($ports_info->{$port}->{PORT_IN_ERR} > 0 || $ports_info->{$port}->{PORT_OUT_ERR} > 0){
        $Equipment->port_errors_add({
          DATE       => "$DATE $TIME",
          NAS_ID     => $nas->{nas_id},
          PORT_ID    => $port,
          IN_ERRORS  => $ports_info->{$port}->{PORT_IN_ERR},
          OUT_ERRORS => $ports_info->{$port}->{PORT_OUT_ERR},
        });

        if ($argv->{DEBUG}){
          print "ID:$nas->{nas_id} $nas->{nas_name} Port:$port Errors: IN - $ports_info->{$port}->{PORT_IN_ERR}, OUT - $ports_info->{$port}->{PORT_OUT_ERR}\n";
        }
      }
    }
  }

  return;
}

