package Api::Controllers::Admin::Districts;

=head1 NAME

  ADMIN API Districts

  Endpoints:
    /districts/*

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

  Endpoint GET /districts/

=cut
#**********************************************************
sub get_districts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # return {
  #   errno  => 10,
  #   errstr => 'Access denied'
  # } if !$self->{admin}->{permissions}{0}{35};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Address->district_list({
    %$query_params,
    COLS_NAME => 1,
  });
}

#**********************************************************
=head2 post_districts($path_params, $query_params)

  Endpoint POST /districts/

=cut
#**********************************************************
sub post_districts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{40};

  return {
    errno  => 10094,
    errstr => 'No field name'
  } if (!$query_params->{NAME});

  $Address->district_add({
    %$query_params
  });
}

#**********************************************************
=head2 get_districts_id($path_params, $query_params)

  Endpoint GET /districts/:id/

=cut
#**********************************************************
sub get_districts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{40};

  $Address->district_info({ ID => $path_params->{id} });

  my $child_districts = $Address->district_list({
    PARENT_ID => $Address->{ID},
    TYPE_ID   => '_SHOW',
    TYPE_NAME => '_SHOW',
    FULL_NAME => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 100000
  });

  if ($child_districts && !scalar @{$child_districts}) {
    my $streets = $Address->street_list({
      DISTRICT_ID => $Address->{ID},
      STREET_NAME => '_SHOW',
      SECOND_NAME => '_SHOW',
      COLS_NAME   => 1,
      PAGE_ROWS   => 100000
    });

    $Address->{STREETS} = $streets;
  }
  else {
    $Address->{CHILD_DISTRICTS} = $child_districts;
  }

  delete @{$Address}{qw/list AFFECTED TOTAL/};
  return $Address;
}

#**********************************************************
=head2 put_districts_id($path_params, $query_params)

  Endpoint PUT /districts/:id/

=cut
#**********************************************************
sub put_districts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{40};

  $Address->district_change({
    %$query_params,
    ID => $path_params->{id}
  });

  return $Address if ($Address->{errno});

  $Address->district_info({ ID => $path_params->{id}, });

  delete @{$Address}{qw/list/};
  return $Address;
}


1;
