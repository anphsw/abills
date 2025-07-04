package Api::Controllers::Admin::Services;

=head1 NAME

  ADMIN API Services Statuses

  Endpoints:
    /services/statuses/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Service;

my Control::Errors $Errors;
my Service $Service;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

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

  $Service = Service->new($self->{db}, $self->{admin}, $self->{conf});
  $Errors  = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_services_statuses($path_params, $query_params)

  POST /services/statuses/

=cut
#**********************************************************
sub post_services_statuses {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Service->status_add({ %$query_params, ID => $path_params->{id} });

  return $Service if ($Service->{errno});

  $Service->status_info({ ID => $path_params->{id} });

  delete @{$Service}{qw/TOTAL list AFFECTED/};

  return $Service;
}

#**********************************************************
=head2 put_services_statuses_id($path_params, $query_params)

  PUT /services/statuses/:id/

=cut
#**********************************************************
sub put_services_statuses_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Service->status_change({ %$query_params, ID => $path_params->{id} });

  return $Service if ($Service->{errno});

  $Service->status_info({ ID => $path_params->{id} });

  delete @{$Service}{qw/TOTAL list AFFECTED/};

  return $Service;
}

#**********************************************************
=head2 get_services_statuses($path_params, $query_params)

  GET /services/statuses/

=cut
#**********************************************************
sub get_services_statuses {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} =
      ($query_params->{$param} || "$query_params->{$param}" eq '0')
        ? $query_params->{$param}
        : '_SHOW';
  }

  my $list = $Service->status_list({
    ID        => '_SHOW',
    NAME      => '_SHOW',
    COLOR     => '_SHOW',
    TYPE      => '_SHOW',
    GET_FEES  => '_SHOW',
    COLS_NAME => 1,
    %$query_params
  });

  foreach my $status (@{$list}) {
    $status->{locale_name} = ::_translate($status->{name}) || $status->{name};
  }

  return {
    total => $Service->{TOTAL},
    list  => $list
  };
}

#**********************************************************
=head2 get_services_statuses_id($path_params, $query_params)

  GET /services/statuses/:id/

=cut
#**********************************************************
sub get_services_statuses_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{0};

  $Service->status_info({ ID => $path_params->{id} });

  delete @{$Service}{qw/TOTAL list AFFECTED/};

  return $Service;
}

#**********************************************************
=head2 delete_services_statuses_id($path_params, $query_params)

  DELETE /services/statuses/:id/

=cut
#**********************************************************
sub delete_services_statuses_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Service->status_del({ ID => $path_params->{id} });

  return $Service if ($Service->{errno});

  if ($Service->{AFFECTED} && $Service->{AFFECTED} =~ /^[0-9]$/) {
    return {
      result  => 'Successfully deleted',
    }
  }

  return $Errors->throw_error(1001032, { errstr => "Status with id $path_params->{id} not exists" });
}

1;
