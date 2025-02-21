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
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
  );

  my $ports = $Equipment->pon_port_list({
    STATUS    => '_SHOW',
    %$query_params,
    COLS_NAME => 1,
  });

  return {
    list  => $ports,
    total => $Equipment->{TOTAL}
  };
}

1;
