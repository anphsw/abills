package Api::Controllers::Common::Addresses;
=head1 NAME

  ADMIN/USER API Addresses info

  Endpoints:

    ADMIN
      get/districts/
      get/streets/
      get/builds/

    USER
      get/user/addresses/districts/
      get/user/addresses/streets/
      get/user/addresses/builds/

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
=head2 get_districts($path_params, $query_params)

  Endpoint GET
    /districts/
    /user/addresses/districts/

=cut
#**********************************************************
sub get_districts {
  my ($self, $path_params, $query_params) = @_;

  my %params = ();

  if ($path_params->{uid}) {
    $params{PARENT_NAME} = '_SHOW';
    $params{PARENT_ID} = $query_params->{PARENT_ID} || '_SHOW';
    $params{ID} = $query_params->{ID} || '_SHOW';
    $params{PAGE_ROWS} = 1000;
  }
  else {
    foreach my $param (keys %{$query_params}) {
      $params{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
    }
  }

  return $Address->district_list({
    %params,
    COLS_NAME => 1,
  });
}

#**********************************************************
=head2 get_streets($path_params, $query_params)

  Endpoint GET /streets/
      /user/addresses/streets/

=cut
#**********************************************************
sub get_streets {
  my ($self, $path_params, $query_params) = @_;

  my %params = ();

  if ($path_params->{uid}) {
    $params{DISTRICT_ID} = $query_params->{DISTRICT_ID} || '_SHOW';
    $params{SORT} = $params{SORT} || 'street_name';
    $params{PAGE_ROWS} = $params{PAGE_ROWS} || 1000;
  }
  else {
    foreach my $param (keys %{$query_params}) {
      $params{BUILD_COUNT} = '_SHOW';
      $params{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
    }
  }

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{34};

  return $Address->street_list({
    SECOND_NAME => '_SHOW',
    DISTRICT_ID => '_SHOW',
    STREET_NAME => '_SHOW',
    %params,
    COLS_NAME   => 1,
  });
}

#**********************************************************
=head2 get_builds($path_params, $query_params)

  Endpoint GET /builds/
        /user/addresses/builds/

=cut
#**********************************************************
sub get_builds {
  my ($self, $path_params, $query_params) = @_;

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{35};

  my %params = ();

  if ($path_params->{uid}) {
    $params{STREET_ID} = $query_params->{DISTRICT_ID} || '_SHOW';
    $params{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 1000;
  }
  else {
    foreach my $param (keys %{$query_params}) {
      $params{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
    }
  }

  return $Address->build_list({
    DISTRICT_NAME => '_SHOW',
    STREET_NAME   => '_SHOW',
    %$query_params,
    COLS_NAME     => 1,
  });
}

1;
