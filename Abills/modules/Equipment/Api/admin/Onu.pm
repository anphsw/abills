package Equipment::Api::admin::Onu;

=head1 NAME

  Equipment Onu

  Endpoints:
    /equipment/onu/*

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
=head2 get_equipment_onu_list($path_params, $query_params)

  Endpoint GET /equipment/onu/list/

=cut
#**********************************************************
sub get_equipment_onu_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $self->_get_onu_list($path_params, $query_params);
}

#**********************************************************
=head2 get_equipment_onu_id($path_params, $query_params)

  Endpoint GET /equipment/onu/:id/

=cut
#**********************************************************
sub get_equipment_onu_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $self->_get_onu_list($path_params, $query_params, { ONE => 1 });
}

#**********************************************************
=head2 _get_onu_list($path_params, $query_params, $attr)

  Arguments:
    $path_params: object  - hash of params from request path
    $query_params: object - hash of query params from request
    $attr: object         - params of function example
      ONE: boolean - returns one onu with $path_params value {id}

  Returns:
    optional
      array or object

=cut
#**********************************************************
sub _get_onu_list {
  my $self = shift;
  my ($path_params, $query_params, $attr) = @_;

  $query_params->{ONU_VLAN} = $query_params->{VLAN} if ($query_params->{VLAN});
  $query_params->{DATETIME} = $query_params->{DATE_TIME} if ($query_params->{DATE_TIME});

  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
  $query_params->{SORT} = $query_params->{SORT} || 1;
  $query_params->{PG} = $query_params->{PG} || 0;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{ID} = ($attr && $attr->{ONE}) ? ($path_params->{id} || 0) : ($query_params->{ID} || 0);

  my $list = $Equipment->onu_list({
    %{$query_params},
    COLS_NAME => 1,
  });

  if ($attr && $attr->{ONE}) {
    return $list->[0] if (scalar @{$list});

    return {
      errno  => 200210,
      errstr => 'Unknown onu'
    };
  }
  else {
    my $res = $query_params->{RETURN_TOTAL} ? { list => $list, total => $Equipment->{TOTAL} } : $list;
    return $res;
  }
}

1;
