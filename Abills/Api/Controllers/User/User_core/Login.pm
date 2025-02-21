package Api::Controllers::User::User_core::Login;

=head1 NAME

  User API Login

  Endpoints:
    /user/login/*

    deprecated
    /users/login/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Api::Helpers qw(caesar_cipher);

use Control::Errors;
use Abills::Control::Auth::User;

my Abills::Control::Auth::User $Auth_User;
my Control::Errors $Errors;

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

  $Auth_User = Abills::Control::Auth::User->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang    => $self->{lang},
    html    => $self->{html},
    libpath => $self->{libpath}
  });
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_login($path_params, $query_params)

  Endpoint POST /user/login

=cut
#**********************************************************
sub post_user_login {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %params = (API => 1);
  my $session_id = '';

  #TODO: review this zoo
  if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{GOOGLE}) {
    $params{token} = $query_params->{GOOGLE};
    $params{external_auth} = 'Google';
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }
  elsif ($self->{conf}->{AUTH_FACEBOOK_ID} && $query_params->{FACEBOOK}) {
    $params{token} = $query_params->{FACEBOOK};
    $params{external_auth} = 'Facebook';
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }
  elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{APPLE}) {
    $params{token} = $query_params->{APPLE};
    $params{external_auth} = 'Apple';
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }
  elsif ($self->{conf}->{AUTH_BY_PHONE} && ($query_params->{PHONE} || $query_params->{PIN_CODE})) {
    $params{PHONE} = $query_params->{PHONE} || '';
    $params{PIN_CODE} = $query_params->{PIN_CODE} || '';
    $params{AUTH_CODE} = $query_params->{AUTH_CODE} || '';
    $params{UID} = $query_params->{UID} || '';
    $params{PIN_ALREADY_EXIST} = $query_params->{PIN_ALREADY_EXISTS} || '';
    $params{external_auth} = 'Phone';
    $session_id = 'plug' if ($self->{conf}->{PASSWORDLESS_ACCESS});
  }

  my ($uid, $sid, $login) = $Auth_User->auth_user($query_params->{LOGIN} || '', $query_params->{PASSWORD} || '', $session_id, { FORM => \%params });

  if (ref $uid eq 'HASH') {
    return $uid;
  }

  if (!$uid) {
    return {
      errno  => 10001,
      errstr => 'Wrong login or password or auth token'
    };
  }

  my %result = (
    uid   => $uid,
    sid   => $sid,
    login => $login
  );

  if ((defined $self->{conf}->{API_LOGIN_SHOW_PASSWORD} && $main::FORM{external_auth}) ||
    ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL})) {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

    if (defined $self->{conf}->{API_LOGIN_SHOW_PASSWORD} && $main::FORM{external_auth}) {
      my $user_info = $Users->info($uid, { SHOW_PASSWORD => 1 });

      $result{password} = caesar_cipher($user_info->{PASSWORD}, $self->{conf}->{API_LOGIN_SHOW_PASSWORD});
      $result{password} = "<str_>$result{password}";
    }

    if ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL}) {
      $Users->registration_pin_info({ UID => $uid });
      if ($Users->{errno}) {
        $result{is_verified} = 'true';
      }
      else {
        $result{is_verified} = $Users->{VERIFY_DATE} eq '0000-00-00 00:00:00' ? 'false' : 'true';
      }
    }
  }

  $result{login} = "<str_>$result{login}";
  return \%result;
}

#**********************************************************
=head2 delete_user_logout($path_params, $query_params)

  Endpoint DELETE /user/logout

=cut
#**********************************************************
sub delete_user_logout {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  require Users;
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->web_session_del({ SID => $ENV{HTTP_USERSID} });
  return {
    result => 'Success logout',
  };
}

1;
