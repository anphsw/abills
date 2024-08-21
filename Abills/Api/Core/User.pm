package Api::Core::User;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);
use Abills::Api::Helpers qw(caesar_cipher);

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    libpath => $attr->{libpath} || '',
    html    => $attr->{html},
    lang    => $attr->{lang} || {}
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 user_login($path_params, $query_params)

=cut
#**********************************************************
sub user_login {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %params = (API => 1);
  my $session_id = '';

  require Abills::Control::Auth::User;
  Abills::Control::Auth::User->import();
  my $Auth_User = Abills::Control::Auth::User->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang    => $self->{lang},
    html    => $self->{html},
    libpath => $self->{libpath}
  });

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
=head2 user_send_password($path_params, $query_params)

=cut
#**********************************************************
sub user_send_password {
  my $self = shift;
  my ($attr) = @_;

  return {
    errno  => 1000001,
    errstr => 'SERVICE_NOT_ENABLED',
  } if (!$self->{conf}->{USER_SEND_PASSWORD});

  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Abills/Templates.pm'}));

  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->pi({ UID => $attr->{UID} });
  $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });

  my $send_status = 0;
  my $type = '';

  if (in_array('Sms', \@main::MODULES) && ($Users->{PHONE} || $Users->{CELL_PHONE})) {
    $type = 'sms';
    my $sms_number = $Users->{CELL_PHONE} || $Users->{PHONE};
    my $message = $self->{html}->tpl_show(::_include('sms_password_recovery', 'Sms'), $Users, { OUTPUT2RETURN => 1 });

    $send_status = $Sender->send_message({
      TO_ADDRESS  => $sms_number,
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
      UID         => $Users->{UID},
    });
  }
  else {
    $type = 'email';
    my $message = $self->{html}->tpl_show(::templates('email_password_recovery'), $Users, { OUTPUT2RETURN => 1 });

    $send_status = $Sender->send_message({
      TO_ADDRESS   => $Users->{EMAIL},
      MESSAGE      => $message,
      SUBJECT      => $main::PROGRAM,
      SENDER_TYPE  => 'Mail',
      QUITE        => 1,
      UID          => $Users->{UID},
      CONTENT_TYPE => $self->{conf}->{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} ? $self->{conf}->{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} : '',
    });
  }

  return {
    result      => 'Successfully send password',
    send_status => $send_status,
    type        => $type
  };
}

1;
