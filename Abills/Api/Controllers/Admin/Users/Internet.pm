package Api::Controllers::Admin::Users::Internet;

=head1 NAME

  ADMIN API Users Internet

  Endpoints:
    /users/internet/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;
use Control::Errors;
use Internet;

my Control::Errors $Errors;
my Internet $Internet;

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

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};
  return $self;
}

#**********************************************************
=head2 get_users_uid_internet($path_params, $query_params)

  Endpoint GET /users/:uid/internet/

=cut
#**********************************************************
sub get_users_uid_internet {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Internet->user_list({
    %$query_params,
    UID             => $path_params->{uid},
    CID             => '_SHOW',
    INTERNET_STATUS => '_SHOW',
    TP_NAME         => '_SHOW',
    MONTH_FEE       => '_SHOW',
    DAY_FEE         => '_SHOW',
    TP_ID           => '_SHOW',
    GROUP_BY        => 'internet.id',
    COLS_NAME       => 1
  });
}

#**********************************************************
=head2 get_users_uid_internet($path_params, $query_params)

  Endpoint GET /users/:uid/internet/:id/

=cut
#**********************************************************
sub get_users_uid_internet_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

  $Internet->user_info($path_params->{uid}, {
    %$query_params,
    ID        => $path_params->{id},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 get_users_internet_all($path_params, $query_params)

  Endpoint GET /users/internet/all/

=cut
#**********************************************************
sub get_users_internet_all {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
  $query_params->{SORT} = $query_params->{SORT} || 1;
  $query_params->{DESC} = $query_params->{DESC} || '';
  $query_params->{PG} = $query_params->{PG} || 0;

  $query_params->{SIMULTANEONSLY} = $query_params->{LOGINS} if ($query_params->{LOGINS});

  my $users = $Internet->user_list({
    %{$query_params},
    COLS_NAME => 1,
  });

  if (in_array('Tags', \@main::MODULES) && $query_params->{TAGS}) {
    foreach my $user (@{$users}) {
      my @tags = $user->{tags} ? split('\s?,\s?', $user->{tags}) : ();
      $user->{tags} = \@tags;
    }
  }

  return $users;
}

1;
