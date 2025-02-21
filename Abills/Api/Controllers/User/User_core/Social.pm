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
  my $self = shift;
  my ($path_params, $query_params) = @_;

  %main::FORM = ();
  if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{GOOGLE}) {
    $main::FORM{token} = $query_params->{GOOGLE};
    $main::FORM{external_auth} = 'Google';
    $main::FORM{API} = 1;
  }
  elsif ($self->{conf}->{AUTH_FACEBOOK_ID} && $query_params->{FACEBOOK}) {
    $main::FORM{token} = $query_params->{FACEBOOK};
    $main::FORM{external_auth} = 'Facebook';
    $main::FORM{API} = 1;
  }
  elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{APPLE}) {
    $main::FORM{token} = $query_params->{APPLE};
    $main::FORM{external_auth} = 'Apple';
    $main::FORM{API} = 1;
    $main::FORM{NONCE} = $query_params->{NONCE} if ($query_params->{NONCE});
  }
  else {
    return {
      errno  => 11002,
      errstr => 'Unknown social network or no token'
    }
  }

  my ($uid, $sid, $login) = ::auth_user('', '', $ENV{HTTP_USERSID}, { API => 1 });

  if (ref $uid eq 'HASH') {
    return $uid;
  }

  if (!$uid) {
    return {
      errno  => 11003,
      errstr => 'Failed to set social network token. Unknown token'
    };
  }

  return {
    result => 'success'
  };
}

1;
