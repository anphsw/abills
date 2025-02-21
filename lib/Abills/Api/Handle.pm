package Abills::Api::Handle;

use strict;
use warnings FATAL => 'all';

use Abills::Api::Router;
use Abills::Api::FieldsGrouper;
use Abills::Base qw(json_former xml_former gen_time in_array check_ip);

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  # define db calls from api to prevent direct prints from dbcore
  $db->{api} = 1;

  my $self = {
    db          => $db,
    admin       => $admin,
    conf        => $conf,
    html        => $attr->{html},
    lang        => $attr->{lang},
    cookies     => $attr->{cookies},
    begin_time  => $attr->{begin_time},
    return_type => $attr->{return_type},
    libpath     => $attr->{libpath},
    debug       => $attr->{debug},
    direct      => $attr->{direct} || 0,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 api_call($attr)

  Arguments:
    PATH: str    - '/users/889/' required
    METHOD?: str - http method ('GET', 'POST'), default GET
    PARAMS?: obj - \%hash, default empty hash

  Returns:
    (
      $response     - { result... } OR { errno => ... }
      $status       - http code
      $content_type - content type of response
    )

  Examples:
    # GET
    my $uid = 228;
    my $result = $handle->call_api({
      METHOD       => "GET",
      PATH         => "/users/$uid",
    });

    # GET WITH QUERY PARAMS
    my $uid = 228;
    my $result = $handle->call_api({
      METHOD       => "GET",
      PATH         => "/users/$uid",
      PARAMS       => \%FORM
    });

    # POST
    my $result = $handle->call_api({
      METHOD  => "POST",
      PATH    => "/portal/newsletter",
      PARAMS  => \%FORM
    });

=cut
#**********************************************************
sub api_call {
  my $self = shift;
  my ($attr) = @_;

  my ($status, $router, $response, $content_type) = (200, {}, q{}, q{});

  my $request_body = $attr->{PARAMS}->{__BUFFER} || '';

  if (!$self->{conf}->{API_ENABLE} && !$self->{direct} && !$self->{cookies}->{admin_sid}) {
    $status = 400;
    $response = {
      errno  => 301,
      errstr => 'It seems that the API is currently disabled in the configuration. To enable it,  add the following line of code: $conf{API_ENABLE}=1;',
    };
  }
  else {
    $router = Abills::Api::Router->new($self->{db}, $self->{admin}, $self->{conf}, {
      url            => $attr->{PATH},
      request_method => $attr->{METHOD} || 'GET',
      query_params   => $attr->{PARAMS},
      lang           => $self->{lang},
      modules        => \@main::MODULES,
      html           => $self->{html},
      debug          => $self->{debug},
      direct         => $self->{direct},
      libpath        => $self->{libpath}
    });

    if (defined $router->{errno}) {
      $status = $router->{errno} == 10 ? 403 : ($router->{status}) ? $router->{status} : 400;
      $response = { errstr => $router->{errstr}, errno => $router->{errno} };
    }
    else {
      $self->add_credentials($router);
      $router->handle();

      if ($router->{allowed}) {
        $router->transform(\&Abills::Api::FieldsGrouper::group_fields);
        $router->{status} = 400 if !$router->{status} && $router->{errno};
      }
      else {
        $router->{result} = { errstr => 'Access denied', errno => 10 };
        $router->{status} = 401;
      }

      if (!$router->{status} && ref $router->{result} eq 'HASH' && (exists $router->{result}->{errno} || exists $router->{result}->{error})) {
        $router->{status} = 400;
        $router->{status} = 401 if ($router->{result}->{errno} && $router->{result}->{errno} eq 10 || ($router->{result}->{errstr} && $router->{result}->{errstr} eq 'Access denied'));
      }

      $response = $router->{result};
      $status = $router->{status} || 200;
      $content_type = q{};

      if ($router->{content_type} && !$router->{status}) {
        if ($router->{content_type} eq 'undefined' && ref $response eq 'HASH') {
          $content_type = $response->{CONTENT_TYPE};
          $response = $response->{CONTENT};
        }
        else {
          $content_type = ($router->{content_type} =~ /image/ && ref $response eq 'HASH') ? q{} : $router->{content_type};
        }
      }
      $response = {} if (!defined $response || !$response);
    }

    if ($router->{error_msg} && !$self->{db}->{db}->{AutoCommit}) {
      $self->{db}->{db}->rollback();
      $self->{db}->{db}->{AutoCommit} = 1;
    }
  }

  if ($self->{return_type} && $self->{return_type} eq 'json' && !$content_type) {
    my $use_camelize = ($router->{query_params}->{snakeCase} || (defined $self->{conf}{API_FILDS_CAMELIZE} && !$self->{conf}{API_FILDS_CAMELIZE})) ? 0 : 1;

    $response = json_former($response, {
      USE_CAMELIZE       => $use_camelize,
      CONTROL_CHARACTERS => 1,
      BOOL_VALUES        => 1,
      UNIQUE_KEYS        => 1,
    });
  }
  elsif ($self->{return_type} && $self->{return_type} eq 'xml' && !$content_type) {
    $response = xml_former($response, { ROOT_NAME => 'response', PRETTY => 1, ENCODING => 'UTF-8' });
  }

  if ($self->{conf}->{API_LOG}) {
    $self->api_add_log(
      $router,
      ($self->{return_type} ? $request_body : json_former($request_body || '')),
      ($self->{return_type} ? $response : json_former($response || '')),
      $status,
      $attr->{METHOD} || 'GET',
      $attr->{PATH} || '',
    );
  }

  return ($response, $status, $content_type);
}

#**********************************************************
=head2 api_add_log($router, $request_body, $response, $status, $request_method, $path)

=cut
#**********************************************************
sub api_add_log {
  my $self = shift;
  my ($router, $request_body, $response, $status, $request_method, $path) = @_;

  require Api;
  Api->import();

  my $begin_time = $main::begin_time || $self->{begin_time} || 0;
  my $Api = Api->new($self->{db}, $self->{admin}, $self->{conf});
  my $response_time = gen_time($begin_time, { TIME_ONLY => 1 });

  my %headers = ();
  foreach my $var (keys %ENV) {
    if ($var =~ /(?<=HTTP_).*/) {
      my ($header) = $var =~ /(?<=HTTP_).*/g;
      $headers{$header} = $ENV{$var};
    }
  }

  $Api->add({
    UID             => ($router->{handler}->{path_params}->{uid} || q{}),
    SID             => ($router->{handler}->{query_params}->{REQUEST_USERSID} || q{}),
    AID             => ($router->{admin}->{AID} || q{}),
    REQUEST_URL     => $path,
    REQUEST_BODY    => $request_body,
    REQUEST_HEADERS => json_former(\%headers),
    RESPONSE_TIME   => $response_time,
    RESPONSE        => $response,
    IP              => $ENV{REMOTE_ADDR},
    HTTP_STATUS     => ($status || 200),
    HTTP_METHOD     => $request_method || 'GET',
    ERROR_MSG       => $router->{error_msg} || q{}
  });
}

#**********************************************************
=head2 add_credentials()

=cut
#**********************************************************
sub add_credentials {
  my $self = shift;
  my Abills::Api::Router $router = shift;

  $router->add_credential('ADMIN', sub {
    shift;

    return 0 if ($self->{conf}->{API_IPS} && $ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{API_IPS}));

    my $API_KEY = $ENV{HTTP_KEY} || '';

    return ::check_permissions('', '', '', { API_KEY => $API_KEY }) == 0;
  });

  $router->add_credential('ADMINSID', sub {
    my $request = shift;
    my $admin_sid = $self->{cookies}->{admin_sid} || '';

    return 0 if ($self->{conf}->{API_IPS} && $ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{API_IPS}));

    $request->{query_params}{REQUEST_ADMINSID} = $admin_sid;

    return ::check_permissions('', '', $admin_sid, {}) == 0;
  });

  $router->add_credential('USER', sub {
    #TODO check how does it work when user have G2FA
    my $request = shift;

    my $SID = $ENV{HTTP_USERSID} || $self->{cookies}->{sid} || '';
    return $self->_validate_user_session($SID, $request);
  });

  $router->add_credential('PUBLIC', sub {
    return 1;
  });

  if ($self->{direct} || ($ENV{REMOTE_ADDR} && $self->{conf}->{BOT_APIS} && check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{BOT_APIS}))) {
    return 0 if (!$ENV{HTTP_USERBOT} || (!$ENV{HTTP_USERID} && !$ENV{HTTP_ADMINID}));

    if (!$self->{direct} && $self->{conf}{BOT_SECRET}) {
      return 0 if (!$ENV{HTTP_BOTSECRET});
      return 0 if ($self->{conf}{BOT_SECRET} ne $ENV{HTTP_BOTSECRET});
    }

    my %bot_types = ();
    $bot_types{VIBER} = 5 if ($self->{conf}->{VIBER_TOKEN});
    $bot_types{TELEGRAM} = 6 if ($self->{conf}->{TELEGRAM_TOKEN});

    return 0 if (!scalar keys %bot_types);

    my $Bot_type = $bot_types{uc($ENV{HTTP_USERBOT})} || '--';
    my $Bot_user = $ENV{HTTP_USERID} || '--';
    my $Bot_admin = $ENV{HTTP_ADMINID} || '--';

    $router->add_credential('USERBOT', sub {
      my $request = shift;

      $main::admin->info($self->{conf}->{USERS_WEB_ADMIN_ID} || 3, {
        DOMAIN_ID => $request->{req_params}->{DOMAIN_ID},
        IP        => $ENV{REMOTE_ADDR},
        SHORT     => 1
      });

      require Contacts;
      Contacts->import();
      my $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

      my $list = $Contacts->contacts_list({
        TYPE  => $Bot_type,
        VALUE => $Bot_user,
        UID   => '_SHOW',
      });

      if ($Contacts->{TOTAL} < 1) {
        return 0
      }
      else {
        $request->{path_params}{uid} = $list->[0]->{uid};
        return 1;
      }
    });

    $router->add_credential('ADMINBOT', sub {
      my $request = shift;

      my $list = $self->{admin}->admins_contacts_list({
        TYPE           => $Bot_type,
        VALUE          => $Bot_admin,
        AID            => '_SHOW',
        SKIP_AID_CHECK => 1
      });

      if (!scalar @{$list}) {
        return 0
      }
      else {
        $self->{admin}->info($list->[0]->{aid});
        %main::permissions = %{$self->{admin}->get_permissions()};
        return 1;
      }
    });

    $router->add_credential('BOT_UNREG', sub {
      my $request = shift;

      # defined as path_params, because query params can go through validations
      $request->{path_params}{bot} = $Bot_type;
      $request->{path_params}{bot_name} = $ENV{HTTP_USERBOT};
      $request->{path_params}{user_id} = $Bot_user;

      return 1;
    });
  }

  return 1;
}

#**********************************************************
=head2 _validate_user_session()

=cut
#**********************************************************
sub _validate_user_session {
  my $self = shift;
  my ($SID, $request) = @_;

  $main::admin->info($self->{conf}->{USERS_WEB_ADMIN_ID} || 3, {
    DOMAIN_ID => $request->{req_params}->{DOMAIN_ID} || 0,
    IP        => $ENV{REMOTE_ADDR},
    SHORT     => 1
  });

  require Abills::Control::Auth::User;
  Abills::Control::Auth::User->import();
  my $Auth_User = Abills::Control::Auth::User->new($self->{db}, $self->{admin}, $self->{conf}, { libpath => $self->{libpath} });

  my ($uid) = $Auth_User->auth_user('', '', $SID);

  return 0 if ref $uid ne '';

  $request->{path_params}{uid} = $uid;
  # please do not delete this line, bot authorization is linked to it
  $request->{query_params}{REQUEST_USERSID} = $SID;

  return $uid != 0;
}

1;
