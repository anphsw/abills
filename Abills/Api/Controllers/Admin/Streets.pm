package Api::Controllers::Admin::Streets;

=head1 NAME

  ADMIN API Streets

  Endpoints:
    /streets/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Address;

my Control::Errors $Errors;
my Address $Address;

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

  $Errors = $self->{attr}->{Errors};
  $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 get_streets($path_params, $query_params)

  Endpoint GET /streets/

=cut
#**********************************************************
sub get_streets {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{34};

  $Address->street_list({
    DISTRICT_ID => '_SHOW',
    STREET_NAME => '_SHOW',
    BUILD_COUNT => '_SHOW',
    %$query_params,
    COLS_NAME   => 1,
  });
}

#**********************************************************
=head2 get_streets_id($path_params, $query_params)

  Endpoint GET /streets/:id/

=cut
#**********************************************************
sub get_streets_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{34};

  $Address->street_info({
    %$query_params,
    COLS_NAME => 1,
    ID        => $path_params->{id}
  });

  my $builds = $Address->build_list({
    NUMBER              => '_SHOW',
    ENTRANCES           => '_SHOW',
    FLORS               => '_SHOW',
    BUILD_SCHEMA        => '_SHOW',
    LOCATION_ID         => '_SHOW',
    COORDY              => '_SHOW',
    ZIP                 => '_SHOW',
    PUBLIC_COMMENTS     => '_SHOW',
    NUMBERING_DIRECTION => '_SHOW',
    TYPE_ID             => '_SHOW',
    TYPE_NAME           => '_SHOW',
    STATUS_NAME         => '_SHOW',
    STREET_ID           => $path_params->{id},
    COLS_NAME           => 1,
    PAGE_ROWS           => 10000
  });

  $Address->{BUILDS} = $builds || [];

  delete @{$Address}{qw/list AFFECTED/};
  return $Address;
}

#**********************************************************
=head2 post_streets($path_params, $query_params)

  Endpoint POST /streets/

=cut
#**********************************************************
sub post_streets {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10095,
    errstr => 'No field districtId'
  } if (!$query_params->{DISTRICT_ID});

  return {
    errno  => 10096,
    errstr => 'No field name'
  } if (!$query_params->{NAME});

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{34};

  $Address->street_add({
    %$query_params
  });

  return $Address if ($Address->{errno});

  $Address->street_info({
    COLS_NAME => 1,
    ID        => $Address->{INSERT_ID}
  });

  delete @{$Address}{qw/list/};
  return $Address;
}

#**********************************************************
=head2 put_streets_id($path_params, $query_params)

  Endpoint PUT /streets/:id/

=cut
#**********************************************************
sub put_streets_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{34};

  $Address->street_change({
    %$query_params,
    ID => $path_params->{id}
  });

  return $Address if ($Address->{errno});

  $Address->street_info({
    COLS_NAME => 1,
    ID        => $path_params->{id}
  });

  delete @{$Address}{qw/list/};
  return $Address;
}

1;
