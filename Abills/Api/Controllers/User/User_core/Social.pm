package Api::Controllers::User::User_core::Social;

=head1 NAME

  User API Credit

  Endpoints:
    /user/credit/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Users;

my Control::Auth::User $Auth_User;
my Control::Errors $Errors;
my Users $Users;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};

  $Auth_User = Control::Auth::User->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang    => $self->{lang},
    html    => $self->{html},
    libpath => $self->{libpath}
  });
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 delete_user_social_networks($path_params, $query_params)

  Endpoint DELETE /user/social/networks/

=cut
#**********************************************************
sub delete_user_social_networks {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $changed_field = '--';

  if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{GOOGLE}) {
    $changed_field = '_GOOGLE';
  }
  elsif ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{FACEBOOK}) {
    $changed_field = '_FACEBOOK';
  }
  elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{APPLE}) {
    $changed_field = '_APPLE';
  }
  else {
    return {
      errno  => 11004,
      errstr => 'Unknown social network'
    };
  }

  $Users->pi_change({ UID => $path_params->{uid}, $changed_field => '' });

  return {
    result => 'success'
  };
}

#**********************************************************
=head2 post_user_social_networks($path_params, $query_params)

  Endpoint POST /user/social/networks/

=cut
#**********************************************************
sub post_user_social_networks {
  my ($self, $path_params, $query_params) = @_;

  my @params = ('FACEBOOK', 'GOOGLE', 'APPLE');
  my %auth_params = (API => 1);

  foreach my $param (@params) {
    next if (!$query_params->{$param});

    $auth_params{external_auth} = ucfirst(lc($param));
    $auth_params{token} = $query_params->{$param};

    last;
  }

  my ($uid, $sid, $login) = $Auth_User->auth_user('', '',  $ENV{HTTP_USERSID}, { FORM => \%auth_params });

  if (!$uid || $Auth_User->{errno}) {
    return $Auth_User;
  }

  return {
    result => 'success'
  };
}

1;
