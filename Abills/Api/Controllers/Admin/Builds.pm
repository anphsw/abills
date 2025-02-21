package Api::Controllers::Admin::Builds;

=head1 NAME

  ADMIN API Builds

  Endpoints:
    /builds/*

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
=head2 get_builds($path_params, $query_params)

  Endpoint GET /builds/

=cut
#**********************************************************
sub get_builds {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{35};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Address->build_list({
    DISTRICT_NAME => '_SHOW',
    STREET_NAME   => '_SHOW',
    %$query_params,
    COLS_NAME     => 1,
  });
}

#**********************************************************
=head2 get_builds_id($path_params, $query_params)

  Endpoint GET /builds/:id/

=cut
#**********************************************************
sub get_builds_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{35};

  $Address->build_info({
    %$query_params,
    COLS_NAME => 1,
    ID        => $path_params->{id}
  });

  delete @{$Address}{qw/list/};
  return $Address;
}

#**********************************************************
=head2 post_builds($path_params, $query_params)

  Endpoint POST /builds/

=cut
#**********************************************************
sub post_builds {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{35};

  return {
    errno  => 10097,
    errstr => 'No field streetId'
  } if (!$query_params->{STREET_ID});

  return {
    errno  => 10098,
    errstr => 'No field number'
  } if (!$query_params->{NUMBER});

  $Address->build_add({
    %$query_params
  });

  return $Address if ($Address->{errno});

  $Address->build_info({
    COLS_NAME => 1,
    ID        => $Address->{INSERT_ID}
  });

  delete @{$Address}{qw/list/};
  return $Address;
}

#**********************************************************
=head2 put_builds_id($path_params, $query_params)

  Endpoint PUT /builds/:id/

=cut
#**********************************************************
sub put_builds_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{35};

  $Address->build_change({
    %$query_params,
    ID => $path_params->{id},
  });

  return $Address if ($Address->{errno});

  $Address->build_info({
    COLS_NAME => 1,
    ID        => $path_params->{id}
  });

  delete @{$Address}{qw/list/};
  return $Address;
}

1;
