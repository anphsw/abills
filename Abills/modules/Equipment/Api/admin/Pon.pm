package Equipment::Api::admin::Pon;
=head1 NAME

  Equipment Box

  Endpoints:
    /equipment/pon/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Equipment;
my Equipment $Equipment;
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

  $Equipment = Equipment->new($db, $admin, $conf);
  $Equipment->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_equipment_pon_ports($path_params, $query_params)

  Endpoint GET /equipment/pon/ports/

=cut
#**********************************************************
sub get_equipment_pon_ports {
  my ($self, $path_params, $query_params) = @_;

  my $ports = $Equipment->pon_port_list({
    STATUS    => '_SHOW',
    %$query_params,
    PAGE_ROWS => 10000
  });

  return {
    list  => $ports,
    total => $Equipment->{TOTAL}
  };
}

1;
