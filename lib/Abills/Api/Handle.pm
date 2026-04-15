package Abills::Api::Handle;

use strict;
use warnings FATAL => 'all';

use Abills::Api::Router;
use Abills::Api::FieldsGrouper;
use Abills::Base qw(json_former xml_former gen_time in_array check_ip);
use Abills::Api::Helpers qw(password_converter);


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
  my ($self, $attr) = @_;

  my ($status, $router, $response, $content_type) = (200, {}, q{}, q{});

  my $request_body = $attr->{PARAMS}->{__BUFFER} || '';
  my @string_value = ('login', 'password', 'user_name', 'address_flat', 'ext_service_id', 'comments');

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
      $response->{error_msg} = $router->{error_msg} if ($router->{error_msg} && $self->{conf}{API_DEBUG});
    }
    else {
      $self->add_credentials($router);
      $router->handle();

      if($router && ref $router->{result} eq 'HASH' && $router->{result}->{COL_NAMES_ARR}) {
        @string_value = () if ($router->{result}->{COL_TYPES_ARR});
        for(my $i=0; $i<=$#{ $router->{result}->{COL_TYPES_ARR} }; $i++) {
          #print "$i $router->{result}->{COL_NAMES_ARR}->[$i] -> $router->{result}->{COL_TYPES_ARR}[$i]\n ";
          if($router->{result}->{COL_TYPES_ARR}[$i] eq 'varchar') {
            push @string_value, $router->{result}->{COL_NAMES_ARR}->[$i];
          }
        }
      }
      elsif(ref $router->{result} eq 'ARRAY' && $router->{COL_TYPES_ARR} ) {
        @string_value = () if ($router->{COL_TYPES_ARR});
        for(my $i=0; $i<=$#{ $router->{COL_TYPES_ARR} }; $i++) {
          #print "$i $router->{COL_NAMES_ARR}->[$i] -> $router->{COL_TYPES_ARR}[$i]\n ";
           if($router->{COL_TYPES_ARR}[$i] eq 'varchar') {
             push @string_value, 'nas_name'; #$router->{COL_NAMES_ARR}->[$i];
             #print "-- $router->{COL_NAMES_ARR}->[$i] --\n"
           }
        }
      }

      if ($router->{allowed}) {
        $router->transform(\&Abills::Api::FieldsGrouper::group_fields);
        $router->{status} = 400 if !$router->{status} && $router->{errno};
      }
      else {
        $router->{result} = { errstr => 'Access denied', errno => 10 };
        $router->{status} = $router->{status} || 401;
      }

      if (!$router->{status} && ref $router->{result} eq 'HASH' && (exists $router->{result}->{errno} || exists $router->{result}->{error})) {
        $router->{status} = 400;
        $router->{status} = 401 if ($router->{result}->{errno} && $router->{result}->{errno} == 10 || ($router->{result}->{errstr} && $router->{result}->{errstr} eq 'Access denied'));
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
          $content_type = ($router->{content_type} =~ /image/xm && ref $response eq 'HASH') ? q{} : $router->{content_type};
        }
      }
      $response = {} if (!defined $response || !$response);
    }

    if ($router->{error_msg} && !$self->{db}->{db}->{AutoCommit}) {
      $self->{db}->{db}->rollback();
      $self->{db}->{db}->{AutoCommit} = 1;
    }
  }

  #TODO: add support of arrays if will be needed
  if ($self->{conf}->{API_PASSWORD_ENCODE} && ref $response eq 'HASH') {
    my @pass_keys = ('PASSWORD');
    my $encode_type = uc($self->{conf}->{API_PASSWORD_ENCODE} || 'BASE64');
    my $encode_key = uc($self->{conf}->{API_PASSWORD_ENCODE_KEY} || '42');

    foreach my $key (@pass_keys) {
      next if (!$response->{$key});
      $response->{$key} = password_converter($response->{$key}, $encode_type, $encode_key);
    }
  }

  if ($self->{return_type} && $self->{return_type} eq 'json' && !$content_type) {
    my $use_camelize = ($router->{query_params}->{snakeCase} || (defined $self->{conf}{API_FILDS_CAMELIZE} && !$self->{conf}{API_FILDS_CAMELIZE})) ? 0 : 1;
    $response = json_former($response, {
      USE_CAMELIZE       => $use_camelize,
      CONTROL_CHARACTERS => 1,
      BOOL_VALUES        => 1,
      UNIQUE_KEYS        => 1,
      STRING_KEYS        => \@string_value
    });
  }
  elsif ($self->{return_type} && $self->{return_type} eq 'xml' && !$content_type) {
    $response = xml_former($response, { ROOT_NAME => 'response', PRETTY => 1, ENCODING => 'UTF-8' });
  }

  if ($self->{conf}->{API_LOG} || $self->{conf}->{API_IDEMPOTENCY_KEY}) {
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

  Arguments:
    $router
    $request_body
    $response
    $status
    $request_method
    $path
  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub api_add_log {
  my ($self, $router, $request_body, $response, $status, $request_method, $path) = @_;

  require Api;
  Api->import();
  my $Api = Api->new($self->{db}, $self->{admin}, $self->{conf});

  my %headers = ();
  foreach my $var (keys %ENV) {
    if ($var =~ /(?<=HTTP_).*/xm  ) {
      my ($header) = $var =~ /(?<=HTTP_).*/xmg;
      $headers{$header} = $ENV{$var};
    }
  }

  my $response_time = 0;
  if ($self->{begin_time}) {
    $response_time = gen_time($self->{begin_time}, { TIME_ONLY => 1 });
  }

  if ($self->{conf}->{API_LOG}) {
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

  if ($self->{conf}->{API_IDEMPOTENCY_KEY} && $ENV{HTTP_IDEMPOTENCY_KEY}) {
    $Api->idempotency_key_add({
      KEY_UUID    => $ENV{HTTP_IDEMPOTENCY_KEY},
      LOG_ID      => $Api->{INSERT_ID} || 0,
      RESPONSE    => $response,
      HTTP_STATUS => ($status || 200),
    });
  }

  return 1;
}

#**********************************************************
=head2 add_credentials($router)

  Arguments:
    $router

  Results:

=cut
#**********************************************************
sub add_credentials {
  my $self = shift;
  my Abills::Api::Router $router = shift;

  $router->add_credential('ADMIN', sub {
    shift;

    return 0 if ($self->{conf}->{API_IPS} && $ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{API_IPS}));

    my $API_KEY = $ENV{HTTP_KEY} || '';

    my $status;
    if(defined(&::check_permissions)) {
      $status = ::check_permissions('', '', '', { API_KEY => $API_KEY });
    }
    else {
      # why we passing API object to Control::Auth::Admin package
      $status = $self->Control::Auth::Admin::check_permissions('', '', '', { API_KEY => $API_KEY });
    }

    if ($status == 0) {
      return 1;
    }

    #Wrong passwd or bruteforce
    if ($status && $status == 4) {
      $router->{status} = 403;
    }

    return 0;
  });

  $router->add_credential('ADMINSID', sub {
    my $request = shift;
    my $admin_sid = $self->{cookies}->{admin_sid} || '';

    return 0 if ($self->{conf}->{API_IPS} && $ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $self->{conf}->{API_IPS}));

    $request->{query_params}{REQUEST_ADMINSID} = $admin_sid;

    #Old way
    if(defined(&::check_permissions)) {
      return ::check_permissions('', '', $admin_sid, {}) == 0;
    }

    # why we passing API object to Control::Auth::Admin package
    return $self->Control::Auth::Admin::check_permissions('', '', $admin_sid, {}) == 0;
  });

  $router->add_credential('USER', sub {
    #TODO check how does it work when user have G2FA
    my $request = shift;

    my $SID = $ENV{HTTP_USERSID} || $self->{cookies}->{sid} || '';

    my $ret = $self->_validate_user_session($SID, $request);
    $router->{USER_INFO} = $self->{USER_INFO} if ($self->{USER_INFO});
    return $ret;
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
=head2 _validate_user_session($sid, $request)

  Arguments:
    $sid
    $request

  Results:
    $uid

=cut
#**********************************************************
sub _validate_user_session {
  my ($self, $sid, $request) = @_;

  $main::admin->info($self->{conf}->{USERS_WEB_ADMIN_ID} || 3, {
    DOMAIN_ID => $request->{req_params}->{DOMAIN_ID} || 0,
    IP        => $ENV{REMOTE_ADDR},
    SHORT     => 1
  });

  require Control::Auth::User;
  Control::Auth::User->import();
  my $Auth_User = Control::Auth::User->new($self->{db}, $self->{admin}, $self->{conf}, { libpath => $self->{libpath} });

  my ($uid) = $Auth_User->auth_user('', '', $sid);

  return 0 if ref $uid ne '';

  $request->{path_params}{uid} = $uid;

  if ($Auth_User->{USER_INFO}) {
    $request->{path_params}{user_object} = $Auth_User->{USER_INFO};
    $self->{USER_INFO}=$Auth_User->{USER_INFO};
  }

  # please do not delete this line, bot authorization is linked to it
  $request->{query_params}{REQUEST_USERSID} = $sid;

  return $uid != 0;
}

1;
