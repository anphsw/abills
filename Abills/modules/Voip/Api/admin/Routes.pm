package Voip::Api::admin::Routes;

=head1 NAME

  Voip Routes

  Endpoints:
    /voip/routes/
    /voip/route/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Voip;

my Voip $Voip;
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

  $Voip = Voip->new($db, $admin, $conf);

  $Voip->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_voip_routes($path_params, $query_params)

  Endpoint GET /voip/routes/

=cut
#**********************************************************
sub get_voip_routes {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Voip->routes_list({
    %$query_params,
    ROUTE_NAME   => $query_params->{NAME} || '_SHOW',
    DESCRIBE     => $query_params->{DESCR} || '_SHOW',
    ROUTE_PREFIX => $query_params->{PREFIX} || '_SHOW',
    SORT         => $query_params->{SORT} ? $query_params->{SORT} : 1,
    DESC         => $query_params->{DESC} ? $query_params->{DESC} : '',
    PG           => $query_params->{PG} ? $query_params->{PG} : 0,
    PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    COLS_NAME    => 1
  });
}

#**********************************************************
=head2 get_voip_route_id($path_params, $query_params)

  Endpoint GET /voip/route/:id

=cut
#**********************************************************
sub get_voip_route_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $route = $Voip->route_info($path_params->{id});
  delete @{$route}{qw/AFFECTED TOTAL/};
  return $route;
}

#**********************************************************
=head2 post_voip_route($path_params, $query_params)

  Endpoint POST /voip/route/

=cut
#**********************************************************
sub post_voip_route {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 30005,
    errstr => 'no fields prefix or name',
  } if (!$query_params->{PREFIX} || !$query_params->{NAME});

  my $validation_result = _validate_route_add($query_params);
  return $validation_result if ($validation_result->{errno});

  $Voip->route_add({
    ROUTE_PREFIX => $query_params->{PREFIX} || '',
    ROUTE_NAME   => $query_params->{NAME} || '',
    DISABLE      => $query_params->{DISABLE} || 0,
    DESCRIBE     => $query_params->{DESCRIBE} || '',
  });
}

#**********************************************************
=head2 put_voip_route_id($path_params, $query_params)

  Endpoint PUT /voip/route/:id/

=cut
#**********************************************************
sub put_voip_route_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{ROUTE_PREFIX} = $query_params->{PREFIX} if (defined $query_params->{PREFIX});
  $query_params->{ROUTE_NAME} = $query_params->{NAME} if (defined $query_params->{NAME});

  my $validation_result = _validate_route_add($query_params);
  return $validation_result if ($validation_result->{errno});

  $Voip->route_change({
    %$query_params,
    ROUTE_ID => $path_params->{id},
  });

  delete @{$Voip}{qw/AFFECTED TOTAL list/};
  return $Voip;
}

#**********************************************************
=head2 delete_voip_route_id($path_params, $query_params)

  Endpoint DELETE /voip/route/:id/

=cut
#**********************************************************
sub delete_voip_route_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->route_del($path_params->{id});

  if (!$Voip->{errno}) {
    if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30006,
        errstr => "routeId $path_params->{id} not exists",
      };
    }
  }
  return $Voip;
}

#**********************************************************
=head2 _validate_route_add()

=cut
#**********************************************************
sub _validate_route_add {
  my ($attr) = @_;

  if ($attr->{PREFIX}) {
    my $routes = $Voip->routes_list({
      ROUTE_PREFIX => $attr->{PREFIX} || '_SHOW',
      COLS_NAME    => 1
    });

    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno    => 21,
        errstr   => 'prefix is not valid',
        param    => 'prefix',
        type     => 'number',
        prefix   => $attr->{PREFIX},
        route_id => $routes->[0]->{id},
        reason   => "prefix already exists in route with id $routes->[0]->{id}"
      } ],
    } if ($routes->[0]->{id});
  }

  return {
    result => 'OK',
  };
}


1;
