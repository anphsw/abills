package Equipment::Api::admin::Users;

=head1 NAME

  Equipment Box

  Endpoints:
    /equipment/:uid/
    /equipment/:nas_id/:port_id/details/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Equipment;

my Equipment::Users $Equipment_users;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Equipment_users = Equipment::Users->new($db, $admin, $conf);
  $Equipment_users->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_equipment_uid($path_params, $query_params)

  Endpoint GET /equipment/:uid/

=cut
#**********************************************************
sub get_equipment_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $devices = $Equipment_users->devices({
    UID => $path_params->{uid},
  });

  foreach my $chapter (@{$devices}) {
    if (ref $chapter eq 'HASH') {
      delete @{$chapter}{qw/tp_id login_status id/};
    }
  }

  return $devices;
}

#**********************************************************
=head2 get_equipment_nas_id_port_id_details($path_params, $query_params)

  Endpoint GET /equipment/:nas_id/:port_id/details/

=cut
#**********************************************************
sub get_equipment_nas_id_port_id_details {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $device_info = $Equipment_users->cpe_info({
    NAS_ID => $path_params->{nas_id},
    PORT   => $path_params->{port_id},
    SIMPLE => 1,
    SILENT => 1,
  });

  return $device_info->{CPE_INFO};
}

1;
