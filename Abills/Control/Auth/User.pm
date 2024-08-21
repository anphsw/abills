package Abills::Control::Auth::User;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(mk_unique_value);
use Abills::Auth::Core;
use Users;

#TODO: add Control::Errors for throwing of errors with errmsg and simplifying of code
my Users $user;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    lang    => $attr->{LANG} || $attr->{lang} || {},
    html    => $attr->{HTML} || $attr->{html},
    libpath => $attr->{libpath} || ''
  };

  $user = Users->new($db, $admin, $conf);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 auth_user($user_name, $password, $session_id, $attr) - AUth user sessions

  Arguments:
    $user_name
    $password
    $session_id
    $attr
      FORM - Input form

  Returns:
    ($ret, $session_id, $login)

=cut
#**********************************************************
sub auth_user {
  my $self = shift;
  my ($login, $password, $session_id, $attr) = @_;

  my $params = {};
  if ($attr->{FORM}) {
    $params = $attr->{FORM};
  }

  # my $lang = $self->{lang};
  # my $html = $self->{html};
  my $index = $attr->{index} || 0;

  my $ret = 0;
  my $res = 0;
  my $REMOTE_ADDR = $ENV{'REMOTE_ADDR'} || '';
  my $uid = 0;

  my $Auth;

  # request from apple only POST without custom prop, we dont handle query params in POST request
  $params->{external_auth} = 'Apple' if ($self->{conf}->{AUTH_APPLE_ID} && $ENV{QUERY_STRING} && $ENV{QUERY_STRING} =~ /external_auth=Apple/);

  if ($params->{external_auth}) {
    $Auth = Abills::Auth::Core->new({
      CONF      => $self->{conf},
      DB        => $self->{db},
      ADMIN     => $self->{admin},
      lang      => $self->{lang},
      html      => $self->{html},
      AUTH_TYPE => $params->{external_auth},
      USERNAME  => $login,
      SELF_URL  => $main::SELF_URL,
      FORM      => $params,
      libpath   => $self->{libpath}
    });

    $Auth->check_access($params);

    if ($Auth->{auth_url}) {
      return {
        result       => 'OK',
        redirect_url => $Auth->{auth_url},
      };
    }
    elsif ($Auth->{RETURN_RESULT}) {
      return $Auth->{RETURN_RESULT};
    }
    elsif ($Auth->{USER_ID}) {
      $user->list({
        $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
        LOGIN                => '_SHOW',
        DELETED              => 0,
        COLS_NAME            => 1
      });

      if ($self->{conf}->{AUTH_EMAIL} && $Auth->{USER_EMAIL} && !$user->{TOTAL} && !$session_id) {
        $user->list({
          EMAIL     => $Auth->{USER_EMAIL} || '--',
          LOGIN     => '_SHOW',
          DELETED   => 0,
          COLS_NAME => 1
        });
        $Auth->{EXTERNAL_AUTH_EMAIL} = 1;
      }

      if ($user->{TOTAL}) {
        $uid = $user->{list}->[0]->{uid};
        $user->{LOGIN} = $user->{list}->[0]->{login};
        $user->{UID} = $uid;
        $res = $uid;
        $Auth->{USER_EXISTS} = 1;

        if ($self->{conf}->{AUTH_EMAIL} && $Auth->{EXTERNAL_AUTH_EMAIL}) {
          $user->pi_change({
            $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
            UID                  => $user->{UID}
          });
        }
      }
      else {
        if (!$session_id) {
          return {
            errno  => 1001001,
            errstr => 'ERR_UNKNOWN_SN_ACCOUNT',
          };
        }
      }
    }
    else {
      return {
        errno  => 1001002,
        errstr => 'ERR_SN_ERROR_AUTH',
      };
    }
  }

  if (!$self->{conf}->{PASSWORDLESS_ACCESS}) {
    if ($ENV{USER_CHECK_DEPOSIT}) {
      $self->{conf}->{PASSWORDLESS_ACCESS} = $ENV{USER_CHECK_DEPOSIT};
    }
    elsif ($attr->{PASSWORDLESS_ACCESS}) {
      $self->{conf}->{PASSWORDLESS_ACCESS} = 1;
    }
    elsif ($self->{conf}->{PASSWORDLESS_CREDIT} && $params->{change_credit}) {
      $self->{conf}->{PASSWORDLESS_ACCESS} = 1;
    }
  }

  #Passwordless Access
  if ($self->{conf}->{PASSWORDLESS_ACCESS} && !$login && !$password && !$session_id) {
    ($ret, $session_id, $login) = $self->_passwordless_access($REMOTE_ADDR, $session_id, $login,
      { PASSWORDLESS_GUEST_ACCESS => $self->{conf}->{PASSWORDLESS_GUEST_ACCESS} });

    if ($self->{conf}->{user_portal_debug}) {
      my $total = $user->{TOTAL} // 'N/D';
      $session_id //= q{};
      $session_id =~ s/\W+//g;
      my $p = $self->{conf}->{PASSWORDLESS_ACCESS} || 0;
      `echo "PA: IP: $REMOTE_ADDR SESSION_ID: $session_id TOTAL: $total index: $index DATE: $main::DATE $main::TIME PASWORDLESS: $p" >> portal_auth.log`;
    }

    if ($ret) {
      if ($self->{conf}->{user_portal_debug}) {
        my $total = $user->{TOTAL} // 'N/D';
        $session_id //= q{};
        $session_id =~ s/\W+//g;
        my $p = $self->{conf}->{PASSWORDLESS_ACCESS} || 0;
        `echo "PA ADD: IP: $REMOTE_ADDR SESSION_ID: $session_id TOTAL: $total index: $index DATE: $main::DATE $main::TIME PASWORDLESS: $p" >> portal_auth.log`;
      }

      $user->web_session_info({ IP => $REMOTE_ADDR });
      if ($user->{errno} && $user->{errno} == 2) {
        if ($self->{conf}->{user_portal_debug}) {
          my $total = $user->{TOTAL} // 'N/D';
          $session_id //= q{};
          $session_id =~ s/\W+//g;
          my $p = $self->{conf}{PASSWORDLESS_ACCESS} || 0;
          `echo "PA ADDD: IP: $REMOTE_ADDR SESSION_ID: $session_id TOTAL: $total index: $index DATE: $main::DATE $main::TIME PASWORDLESS: $p A: $ENV{HTTP_USER_AGENT}" >> portal_auth.log`;
        }
        $user->web_session_add({
          UID         => $ret,
          SID         => $session_id,
          LOGIN       => $login,
          REMOTE_ADDR => $REMOTE_ADDR,
          EXT_INFO    => $ENV{HTTP_USER_AGENT},
          COORDX      => $params->{coord_x} || '',
          COORDY      => $params->{coord_y} || ''
        });
      }
      else {
        $session_id = $user->{SID};
        if ($self->{conf}->{user_portal_debug}) {
          my $total = $user->{TOTAL} // 'N/D';
          $session_id //= q{};
          $session_id =~ s/\W+//g;
          my $p = $self->{conf}->{PASSWORDLESS_ACCESS} || 0;
          `echo "PA UPDATE: IP: $REMOTE_ADDR SESSION_ID: $session_id TOTAL: $total index: $index DATE: $main::DATE $main::TIME PASWORDLESS: $p A: $ENV{HTTP_USER_AGENT}" >> portal_auth.log`;
        }

        $user->web_session_update({ SID => $session_id });
      }

      return ($ret, $session_id, $login);
    }
  }

  if ($index == 1000) {
    $user->web_session_del({ SID => $session_id });
    return 0;
  }
  elsif ($session_id) {
    $user->web_session_info({ SID => $session_id });

    if ($user->{TOTAL} < 1) {
      delete $params->{REFERER};
      delete $user->{errno};
      if ($self->{conf}->{user_portal_debug}) {
        #$html->message('err', $lang->{ERROR}, $lang->{NOT_LOGINED}, { ID => 9999 });
        my $total = $user->{TOTAL} // 'N/D';
        $session_id =~ s/\W+//g;
        my $p = $self->{conf}->{PASSWORDLESS_ACCESS} || 0;
        `echo " IP: $REMOTE_ADDR SESSION_ID: $session_id TOTAL: $total index: $index DATE: $main::DATE $main::TIME PASWORDLESS: $p" >> portal_auth.log`;
      }
      #$html->message('err', "$lang->{ERROR}", "$lang->{NOT_LOGINED}");
      #return 0;
    }
    elsif ($user->{errno}) {
      #TODO: maybe do return? Previous error message nothing saying
      # $html->message('err', $lang->{ERROR});
    }
    elsif ($self->{conf}->{web_session_timeout} < $user->{SESSION_TIME}) {
      $user->web_session_del({ SID => $session_id });
      return {
        errno  => 1001003,
        errstr => 'ERR_SESSION_EXPIRE',
      };
    }
    elsif (!$self->{conf}->{USERPORTAL_MULTI_SESSIONS} && $user->{REMOTE_ADDR} ne $REMOTE_ADDR) {
      $user->web_session_del({ SID => $session_id });
      return {
        errno  => 1001004,
        errstr => 'ERR_WRONG_IP',
      };
    }
    else {
      $user->info($user->{UID}, { USERS_AUTH => 1 });
      $self->{admin}->{DOMAIN_ID} = $user->{DOMAIN_ID};
      $user->web_session_update({ SID => $session_id, REMOTE_ADDR => $REMOTE_ADDR });
      #Add social id
      if ($Auth->{USER_ID}) {
        if (!$Auth->{USER_EXISTS}) {
          $user->pi_change({
            $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
            UID                  => $user->{UID}
          });
        }
        else {
          return {
            errno  => 1001005,
            errstr => 'ERR_SN_ACCOUNT_LINKED_TO_OTHER_ACCOUNT',
            # errmsg => 'You already linked this social auth account to another account identifier.',
          };
        }
      }

      return ($user->{UID}, $session_id, $user->{LOGIN});
    }
  }

  if ($login && $password) {
    if ($self->{conf}->{wi_bruteforce}) {
      $user->bruteforce_list({
        LOGIN    => $login,
        PASSWORD => $password,
        CHECK    => 1
      });

      if ($user->{TOTAL} > $self->{conf}->{wi_bruteforce}) {
        return {
          errno  => 1001006,
          errstr => 'ERR_PASSWD_BRUTEFORCE'
          # errmsg => 'You try to brute password and system block your account. Please contact system administrator.'
        };
      }
    }

    #check password from RADIUS SERVER if defined $conf{check_access}
    if ($self->{conf}->{check_access}) {
      $Auth = Abills::Auth::Core->new({
        CONF      => $self->{conf},
        AUTH_TYPE => 'Radius',
        FORM      => $params
      });

      $res = $Auth->check_access({
        LOGIN    => $login,
        PASSWORD => $password
      });
    }
    #check password direct from SQL
    else {
      $res = $self->_auth_sql($login, $password, $params) if ($res < 1);
      return $res if (ref $res eq 'HASH');
    }
  }
  elsif ($login && !$password) {
    return {
      errno  => 1001007,
      errstr => 'ERR_WRONG_PASSWD',
    };
  }
  #Get user ip
  if (defined($res) && $res > 0) {
    $user->info($user->{UID} || 0, {
      LOGIN      => ($user->{UID}) ? undef : $login,
      DOMAIN_ID  => $params->{DOMAIN_ID},
      USERS_AUTH => 1
    });

    if ($self->{conf}->{AUTH_G2FA}) {
      $user->pi();
      if (!$params->{g2fa}) {
        if ($user->{_G2FA}) {
          return (0, $session_id, $login);
        }
      }
      else {
        my $OATH = Abills::Auth::Core->new({
          CONF      => $self->{conf},
          AUTH_TYPE => 'OATH'
        });

        if (!$OATH->check_access({ SECRET => $user->{_G2FA}, PIN => $params->{g2fa} })) {
          return {
            errno  => 1001008,
            errstr => 'G2FA_WRONG_CODE',
          };
        }
      }
    }

    if ($user->{TOTAL} > 0) {
      $session_id = mk_unique_value(16);
      $ret = $user->{UID};
      $user->{REMOTE_ADDR} = $REMOTE_ADDR;
      $self->{admin}->{DOMAIN_ID} = $user->{DOMAIN_ID};
      $login = $user->{LOGIN};

      if (!$self->{conf}->{SKIP_GROUP_ACCESS_CHECK}) {
        $user->group_info($user->{GID});

        if ($user->{DISABLE_ACCESS}) {
          delete $params->{logined};

          $user->bruteforce_add({
            LOGIN       => $login,
            PASSWORD    => $password,
            REMOTE_ADDR => $REMOTE_ADDR,
            AUTH_STATE  => 0
          });

          return {
            errno  => 1001009,
            errstr => 'ERR_ACCESS_DENY',
          };
        }
      }

      $user->web_session_add({
        UID         => $user->{UID},
        SID         => $session_id,
        LOGIN       => $login,
        REMOTE_ADDR => $REMOTE_ADDR,
        EXT_INFO    => $ENV{HTTP_USER_AGENT},
        COORDX      => $params->{coord_x} || '',
        COORDY      => $params->{coord_y} || ''
      });
    }
    else {
      return {
        errno  => 1001010,
        errstr => 'ERR_WRONG_PASSWD',
      };
    }
  }
  else {
    if ($login || $password) {
      $user->bruteforce_add({
        LOGIN       => $login,
        PASSWORD    => $password,
        REMOTE_ADDR => $REMOTE_ADDR,
        AUTH_STATE  => $ret
      });

      return {
        errno  => 1001011,
        errstr => 'ERR_WRONG_PASSWD',
      };
    }

    $ret = 0;
  }

  return ($ret, $session_id, $login);
}

#**********************************************************
=head2 _passwordless_access($remote_addr, $session_id, $login, $attr) - Get passwordless access info

   Arguments:
     $remote_addr
     $session_id
     $login
     $attr
       PASSWORDLESS_GUEST_ACCESS

   Return:
     $uid, $session_id, $login

=cut
#**********************************************************
sub _passwordless_access {
  my $self = shift;
  my ($remote_addr, $session_id, $login, $attr) = @_;
  my $auth_uid = 0;

  require Internet::Sessions;
  Internet::Sessions->import();
  my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});

  my %params = ();

  if ($attr->{PASSWORDLESS_GUEST_ACCESS}) {
    $params{GUEST} = 1;
    if ($attr->{PASSWORDLESS_GUEST_ACCESS} ne '1') {
      $params{SERVICE_STATUS} = $attr->{PASSWORDLESS_GUEST_ACCESS};
      $params{INTERNET_STATUS} = $attr->{PASSWORDLESS_GUEST_ACCESS};
      delete $self->{conf}->{PASSWORDLESS_ACCESS};
    }
  }

  my $list = $Sessions->online({
    USER_NAME         => '_SHOW',
    FRAMED_IP_ADDRESS => $remote_addr,
    %params
  });

  if ($Sessions->{TOTAL} && $Sessions->{TOTAL} == 1) {
    $login = $list->[0]->{user_name} || $login;
    $auth_uid = $list->[0]->{uid};
    $user->info($auth_uid, { USERS_AUTH => 1 });

    $user->{REMOTE_ADDR} = $remote_addr;

    if (!$self->{conf}->{SKIP_GROUP_ACCESS_CHECK}) {
      $user->group_info($user->{GID});

      if ($user->{DISABLE_ACCESS}) {
        return {
          errno  => 1001012,
          errstr => 'ERR_ACCESS_DENY',
        };
      }
    }
  }
  else {
    require Internet;
    Internet->import();

    my $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});

    my $internet_list = $Internet->user_list({
      IP        => $remote_addr,
      %params,
      LOGIN     => '_SHOW',
      COLS_NAME => 1
    });

    if ($Internet->{TOTAL} && $Internet->{TOTAL} == 1) {
      $login = $internet_list->[0]->{login} || $login;
      $auth_uid = $internet_list->[0]->{uid} || 0;
      $user->info($auth_uid);

      if (!$self->{conf}->{SKIP_GROUP_ACCESS_CHECK}) {
        $user->group_info($user->{GID});

        if ($user->{DISABLE_ACCESS}) {
          return {
            errno  => 1001013,
            errstr => 'ERR_ACCESS_DENY',
          };
        }
      }

      $user->{REMOTE_ADDR} = $remote_addr;
    }
  }

  $session_id= mk_unique_value(14) if ($auth_uid);

  return ($auth_uid, $session_id, $login);
}

#**********************************************************
=head2 _auth_sql($login, $password) - Authentification from SQL DB

=cut
#**********************************************************
sub _auth_sql {
  my $self = shift;
  my ($user_name, $password, $attr) = @_;
  my $ret = 0;

  $self->{conf}->{WEB_AUTH_KEY} //= 'LOGIN';

  if ($self->{conf}->{WEB_AUTH_KEY} eq 'LOGIN') {
    $user->info(0, {
      LOGIN      => $user_name,
      PASSWORD   => $password,
      DOMAIN_ID  => $attr->{DOMAIN_ID} || 0,
      USERS_AUTH => 1
    });
  }
  else {
    my @a_method = split(/,/, $self->{conf}->{WEB_AUTH_KEY});
    foreach my $auth_param (@a_method) {
      $user->list({
        $auth_param => $user_name,
        PASSWORD    => $password,
        DELETED     => 0,
        DOMAIN_ID   => $attr->{DOMAIN_ID} || 0,
        COLS_NAME   => 1
      });

      if ($user->{TOTAL}) {
        $user->info($user->{list}->[0]->{uid});
        last;
      }
    }
  }

  if ($user->{TOTAL} < 1) {
    if (!$self->{conf}->{PORTAL_START_PAGE}) {
      return {
        errno  => 1001014,
        errstr => 'ERR_WRONG_PASSWD',
      };
    }
  }
  elsif ($user->{errno}) {
    return {
      errno  => 1001015,
      errstr => 'ERR_ACCESS_DENY',
    };
  }
  elsif ($user->{DELETED}) {
    return {
      errno  => 1001016,
      errstr => 'ERR_ACCESS_DENY',
    };
  }
  else {
    $ret = $user->{UID} || $user->{list}->[0]->{uid};
  }

  $self->{admin}->{DOMAIN_ID} = $user->{DOMAIN_ID};

  return $ret;
}

1;
