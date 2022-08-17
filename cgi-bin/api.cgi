#!/usr/bin/perl

use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . 'Abills/modules/',
    $libpath . '/lib/',
    $libpath . '/Abills/',
    $libpath . '/Abills/Api/',
    $libpath
  );

  eval {require Time::HiRes;};
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::JSON;
use Abills::Defs;
use Users;
use Admins;
use Conf;
use Api;
use Abills::Api::Router;
use Abills::Api::FildsGrouper;

require Control::Auth;

our (
  %LANG,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  $base_dir,
  @REGISTRATION,
  @MODULES,
  %functions,
);

my $VERSION = 0.28;
do 'Abills/Misc.pm';
do '../libexec/config.pl';
do $libpath . '/language/english.pl';

if ($conf{API_NGINX} && $ENV{REQUEST_URI}) {
  $ENV{REQUEST_URI} =~ s/\/api.cgi//;
  $ENV{PATH_INFO} = $ENV{REQUEST_URI};
}

our $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  });

our $admin      = Admins->new($db, \%conf);
our Users $user = Users->new($db, $admin, \%conf);
our $Conf       = Conf->new($db, $admin, \%conf);

our $html = Abills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE}
});

_start();

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {
  my $response = q{};
  my $status = q{};

  if (!$conf{API_ENABLE}) {
    $status = 400;
    $response = Abills::Base::json_former({ errstr => 'API didn\'t enable please enable API in config $conf{API_ENABLE}=1;', errno => 301 });
  }
  else {
    #define $admin->{permissions}
    check_permissions('', '', '', { API_KEY => $ENV{HTTP_KEY} });

    #TODO : Fix %FORM add make possible to paste query params with request body
    my $router = Abills::Api::Router->new(($ENV{PATH_INFO} || q{}), $db, $user, $admin, $Conf->{conf}, \%FORM, \%lang, \@MODULES, 0,
      {
        permissions => $admin->{permissions}
      });

    if ($router->{errno}) {
      $status = 400;
      $response = Abills::Base::json_former({ errstr => $router->{errstr}, errno => $router->{errno} });
    }
    else {
      add_custom_paths($router);
      add_credentials($router);
      $router->handle();

      if ($router->{allowed}) {
        $router->transform(\&Abills::Api::FildsGrouper::group_fields);
        $router->{status} = 400 if !$router->{status} && $router->{errno};
      }
      else {
        $router->{result} = { errstr => 'Access denied', errno => 10 };
        $router->{status} = 401;
      }
      my $use_camelize = defined $ENV{HTTP_CAMELIZE} ? $ENV{HTTP_CAMELIZE} : (
        defined $conf{API_FILDS_CAMELIZE} ? $conf{API_FILDS_CAMELIZE} : 1
      );

      $router->{status} = 400 if (ref $router->{result} eq 'HASH' && ($router->{result}->{errno} || $router->{result}->{error}));
      $response = Abills::Base::json_former($router->{result}, { USE_CAMELIZE => $use_camelize, CONTROL_CHARACTERS => 1, BOOL_VALUES => 1 });
      $status = $router->{status};
    }

    if ($conf{API_LOG}) {
      my $Api = Api->new($db, $admin, \%conf);
      my $response_time = Abills::Base::gen_time($begin_time);
      ($response_time) =~ s/GT: //g;

      $Api->add({
        UID           => ($router->{user}->{UID} || q{}),
        SID           => ($router->{user}->{SID} || q{}),
        AID           => ($router->{user}->{admin}->{AID} || q{}),
        REQUEST_URL   => ($ENV{REQUEST_URI} || q{}),
        REQUEST_BODY  => $FORM{__BUFFER},
        RESPONSE_TIME => $response_time,
        RESPONSE      => $response,
        IP            => $ENV{REMOTE_ADDR},
        HTTP_STATUS   => ($status || 200),
        HTTP_METHOD   => $ENV{REQUEST_METHOD}
      });
    }
  }

  print Abills::JSON::header(undef, { STATUS => $status || '' });
  print $response;
  return 1;
}

#**********************************************************
=head2 add_custom_paths()

=cut
#**********************************************************
sub add_custom_paths {
  my ($router) = @_;

  $router->add_custom_handler('users', {
    method               => 'POST',
    path                 => '/users/login/',
    handler              => sub {
      my ($path_params, $query_params) = @_;

      if ($conf{AUTH_GOOGLE_ID} && $query_params->{google}) {
        $FORM{token} = $query_params->{google};
        $FORM{external_auth} = 'Google';
        $FORM{API} = 1;
      }

      my ($uid, $sid, $login) = auth_user($query_params->{login}, $query_params->{password}, '', { API => 1 });

      if (ref $uid eq 'HASH') {
        return $uid;
      }

      if (!$uid) {
        return {
          errno  => 10001,
          errstr => 'Wrong login or password or auth token'
        }
      }

      return {
        uid   => $uid,
        sid   => $sid,
        login => $login
      }
    },
    no_decamelize_params => 1
  });

  $router->add_custom_handler('user', {
    method               => 'POST',
    path                 => '/user/:uid/social/networks/',
    handler              => sub {
      my ($path_params, $query_params) = @_;

      if ($conf{AUTH_GOOGLE_ID} && $query_params->{google}) {
        $FORM{token} = $query_params->{google};
        $FORM{external_auth} = 'Google';
        $FORM{API} = 1;
      } else {
        return {
          errno  => 11002,
          errstr => 'Unknown social network or no token'
        }
      }

      my ($uid, $sid, $login) = auth_user('', '', $ENV{HTTP_USERSID}, { API => 1 });

      if (ref $uid eq 'HASH') {
        return $uid;
      }

      if (!$uid) {
        return {
          errno  => 11003,
          errstr => 'Failed to set social network token. Unknown token'
        }
      }

      return {
        result => 'success'
      }
    },
    no_decamelize_params => 1,
    credentials => [
      'USER'
    ]
  });

  $router->add_custom_handler('user', {
    method               => 'DELETE',
    path                 => '/user/:uid/social/networks/',
    handler              => sub {
      my ($path_params, $query_params) = @_;

      my $changed_field = '--';

      if ($conf{AUTH_GOOGLE_ID} && $query_params->{google}) {
        $changed_field = '_GOOGLE';
      } else {
        return {
          errno  => 11004,
          errstr => 'Unknown social network'
        }
      }

      $user->pi_change({ UID => $path_params->{uid}, $changed_field => '' });

      return {
        result => 'success'
      }
    },
    no_decamelize_params => 1,
    credentials => [
      'USER'
    ]
  });

  $router->add_custom_handler('version', {
    method      => 'GET',
    path    => '/version/',
    handler => sub {
      return {
        version     => get_version(),
        billing     => 'ABillS',
        api_version => $VERSION,
      };
    },
  });

  $router->add_custom_handler('user', {
    method               => 'GET',
    path                 => '/user/:uid/config/',
    handler              => sub {
      my ($path_params, $query_params) = @_;
      require Control::Service_control;
      Control::Service_control->import();
      my $Service_control = Control::Service_control->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

      $user->pi({ UID => $path_params->{uid} });

      mk_menu([], { USER_FUNCTION_LIST => 1 });

      %functions = reverse %functions;

      if ($functions{internet_user_chg_tp}) {
        my $list = $Service_control->available_tariffs({
          UID    => $path_params->{uid},
          MODULE => 'Internet'
        });

        if (ref $list ne 'ARRAY') {
          delete $functions{internet_user_chg_tp};
        }
        else {
          $functions{internet}{now} = 0 if ($conf{INTERNET_USER_CHG_TP_NOW});
          $functions{internet}{next_month} = 1 if ($conf{INTERNET_USER_CHG_TP_NEXT_MONTH});
          $functions{internet}{schedule} = 2 if ($conf{INTERNET_USER_CHG_TP_SHEDULE});
        }
      }

      if ($conf{INTERNET_USER_SERVICE_HOLDUP}) {
        my ($min_period, $max_period, $holdup_period, $daily_fees, undef, $active_fees) = split(/:/, $conf{INTERNET_USER_SERVICE_HOLDUP});

        $functions{internet_user_holdup} = {
          min_period    => $min_period,
          max_period    => $max_period,
          holdup_period => $holdup_period,
          daily_fees    => $daily_fees,
          active_fees   => $active_fees
        };
      }

      if ($conf{AUTH_GOOGLE_ID}) {
        $functions{social_auth}{google} = $user->{_GOOGLE} ? 1 : 0;
      }

      my $credit_info = $Service_control->user_set_credit({ UID => $path_params->{uid} });
      unless ($credit_info->{error} || $credit_info->{errno}) {
        $functions{user_credit} = '1001';
      }

      if ($conf{SYSTEM_CURRENCY}) {
        $functions{system}{currency} = $conf{SYSTEM_CURRENCY};
      }

      return \%functions;
    },
    credentials => [
      'USER'
    ]
  });

  $router->add_custom_handler('config', {
    method               => 'GET',
    path                 => '/config/',
    handler              => sub {
      my %config = ();
      if ($conf{AUTH_GOOGLE_ID}) {
        $config{social_auth}{google} = 1;
      }

      return \%config;
    },
  });

  return 1;
}

#**********************************************************
=head2 add_credentials()

=cut
#**********************************************************
sub add_credentials {
  my ($router) = @_;

  $router->add_credential('ADMIN', sub {
    shift;
    my $API_KEY = $ENV{HTTP_KEY} || '-';

    return check_permissions('', '', '', { API_KEY => $API_KEY }) == 0;
  });

  $router->add_credential('USER', sub {
    #TODO check how does it work when user have G2FA
    my $self = shift;
    my $SID = $ENV{HTTP_USERSID};
    my ($uid) = auth_user('', '', $SID); #TODO check

    $uid = $self->{path_params}{uid} ne $uid ? 0 : $uid if $self->{path_params}{uid};
    return $uid != 0;
  });

  if ($ENV{REMOTE_ADDR} && $conf{BOT_APIS} && check_ip($ENV{REMOTE_ADDR}, $conf{BOT_APIS})) {
    $router->add_credential('USERBOT', sub {
      my $self = shift;

      my %bot_types = (
        VIBER    => 5,
        TELEGRAM => 6
      );

      my $Bot_type = $bot_types{$ENV{HTTP_USERBOT}} || '--';
      my $Bot_user = $ENV{HTTP_USERID} || '--';

      require Contacts;
      Contacts->import();
      my $Contacts = Contacts->new($db, $admin, \%conf);

      my $list = $Contacts->contacts_list({
        TYPE  => $Bot_type,
        VALUE => $Bot_user,
        UID   => '_SHOW',
      });

      if ($Contacts->{TOTAL} < 1) {
        return 0
      }
      else {
        $self->{path_params}{uid} = $list->[0]->{uid};
        return 1;
      }
    });
  }

  return 1;
}

1;
