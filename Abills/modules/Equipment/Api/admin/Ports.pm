package Equipment::Api::admin::Ports;
=head1 NAME

  Equipment Box

  Endpoints:
    /equipment/nas/:id/ports

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
=head2 get_equipment_nas_ports($path_params, $query_params)

  Endpoint GET /equipment/nas/:nas_id/ports/

=cut
#**********************************************************
sub get_equipment_nas_ports {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $ports = $Equipment->port_list({
    STATUS    => '_SHOW',
    %$query_params,
    %PARAMS,
    NAS_ID    => $path_params->{nas_id},
    COLS_NAME => 1,
  });

  return {
    list  => $ports,
    total => $Equipment->{TOTAL}
  };
}

#**********************************************************
=head2 put_equipment_nas_ports_id($path_params, $query_params)

  Endpoint PUT /equipment/nas/:nas_id/ports/:port_id/

=cut
#**********************************************************
sub put_equipment_nas_ports_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  delete $query_params->{NAS_ID};
  $Equipment->port_change({
    %{$query_params},
    ID => $path_params->{port_id}
  });

  return $Equipment;
}

1;
