package Internet::Api;
=head1 NAME

  Internet::Api - Internet api functions

=head VERSION

  DATE: 20220711
  UPDATE: 20241112
  VERSION: 1.35

=cut

use strict;
use warnings FATAL => 'all';

use Internet::Validations qw(POST_INTERNET_MAC_DISCOVERY POST_INTERNET_HANGUP POST_INTERNET_TARIFF PUT_INTERNET_TARIFF POST_INTERNET_USER PUT_INTERNET_USER);

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }
  elsif ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  return $self;
}

#**********************************************************
=head2 routes_list() - Returns available API paths

  Returns:
    [
      {
        method      => 'GET',          # HTTP method. Path can be queried only with this method

        path        => '/users/:uid/', # API path. May contain variables like ':uid'.
                                       # variables will be passed to handler function as argument ($path_params).
                                       # example: if route's path is '/users/:uid/', and queried URL
                                       # is '/users/9/', $path_params will be { uid => 9 }.
                                       # if credentials is 'ADMIN', 'ADMINSID', 'ADMINBOT',
                                       # variable :uid will be checked to contain only existing user's UID.

        params      => POST_USERS,     # Validation schema.
                                       # Can be used as hashref, but we use constant for clear
                                       # visual differences.

        controller  => 'Api::Controllers::Admin::Users::Info',
                                       # Name of loadable controller.

        endpoint    => \&Api::Controllers::Admin::Users::Info::get_users_uid,
                                       # Path to handler function, must be coderef.

        credentials => [               # arrayref of roles required to use this path.
                                       # if API admin/user is authorized as at least one of
                                       # these roles access to this path will be granted. REQUIRED.
                                       # List of credentials:
          'ADMIN'                      # 'ADMIN', 'ADMINSID', 'ADMINBOT', 'USER', 'USERBOT', 'BOT_UNREG', 'PUBLIC'
        ],
      },
    ]

=cut
#**********************************************************
sub admin_routes {
  return [
    {
      method      => 'POST',
      params      => POST_INTERNET_USER,
      path        => '/internet/:uid/activate/',
      controller  => 'Internet::Api::admin::Users',
      endpoint    => \&Internet::Api::admin::Users::post_internet_uid_activate,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      params      => PUT_INTERNET_USER,
      path        => '/internet/:uid/activate/',
      controller  => 'Internet::Api::admin::Users',
      endpoint    => \&Internet::Api::admin::Users::put_internet_uid_activate,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/internet/:uid/:id/warnings/',
      controller  => 'Internet::Api::admin::Users',
      endpoint    => \&Internet::Api::admin::Users::get_internet_uid_id_warnings,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/internet/:uid/session/hangup/',
      params      => POST_INTERNET_HANGUP,
      controller  => 'Internet::Api::admin::Users',
      endpoint    => \&Internet::Api::admin::Users::post_internet_uid_session_hangup,
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'GET',
      path        => '/internet/tariffs/',
      controller  => 'Internet::Api::admin::Tariffs',
      endpoint    => \&Internet::Api::admin::Tariffs::get_internet_tariffs,
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'POST',
      path        => '/internet/tariff/',
      params      => POST_INTERNET_TARIFF,
      controller  => 'Internet::Api::admin::Tariffs',
      endpoint    => \&Internet::Api::admin::Tariffs::post_internet_tariff,
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'PUT',
      path        => '/internet/tariff/:tpId/',
      params      => PUT_INTERNET_TARIFF,
      controller  => 'Internet::Api::admin::Tariffs',
      endpoint    => \&Internet::Api::admin::Tariffs::put_internet_tariff_tpId,
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'DELETE',
      path        => '/internet/tariff/:tpId/',
      controller  => 'Internet::Api::admin::Tariffs',
      endpoint    => \&Internet::Api::admin::Tariffs::delete_internet_tariff_tpId,
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'PUT',
      path        => '/internet/:uid/',
      controller  => 'Internet::Api::admin::Users',
      endpoint    => \&Internet::Api::admin::Users::put_internet_uid,
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'GET',
      path        => '/internet/sessions/:uid/',
      controller  => 'Internet::Api::admin::Sessions',
      endpoint    => \&Internet::Api::admin::Sessions::get_sessions_uid,
      credentials => [
        'ADMIN'
      ],
    },
  ];
}

#**********************************************************
=head2 user_routes() - Returns available API paths

  Returns:
    [
      {
        method      => 'GET',          # HTTP method. Path can be queried only with this method

        path        => '/users/:uid/', # API path. May contain variables like ':uid'.
                                       # variables will be passed to handler function as argument ($path_params).
                                       # example: if route's path is '/users/:uid/', and queried URL
                                       # is '/users/9/', $path_params will be { uid => 9 }.
                                       # if credentials is 'ADMIN', 'ADMINSID', 'ADMINBOT',
                                       # variable :uid will be checked to contain only existing user's UID.

        params      => POST_USERS,     # Validation schema.
                                       # Can be used as hashref, but we use constant for clear
                                       # visual differences.

        controller  => 'Api::Controllers::Admin::Users::Info',
                                       # Name of loadable controller.

        endpoint    => \&Api::Controllers::Admin::Users::Info::get_users_uid,
                                       # Path to handler function, must be coderef.

        credentials => [               # arrayref of roles required to use this path.
                                       # if API admin/user is authorized as at least one of
                                       # these roles access to this path will be granted. REQUIRED.
                                       # List of credentials:
          'ADMIN'                      # 'ADMIN', 'ADMINSID', 'ADMINBOT', 'USER', 'USERBOT', 'BOT_UNREG', 'PUBLIC'
        ],
      },
    ]

=cut
#**********************************************************
sub user_routes {
  return [
    {
      method      => 'POST',
      path        => '/user/internet/:id/activate/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::post_user_internet_id_activate,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::get_user_internet,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/session/active/',
      controller  => 'Internet::Api::user::Sessions',
      endpoint    => \&Internet::Api::user::Sessions::get_user_internet_session_active,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/sessions/',
      controller  => 'Internet::Api::user::Sessions',
      endpoint    => \&Internet::Api::user::Sessions::get_user_internet_sessions,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/user/internet/registration/',
      controller  => 'Internet::Api::user::Registration',
      endpoint    => \&Internet::Api::user::Registration::post_user_internet_registration,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/tariffs/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::get_user_internet_tariffs,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/tariffs/all/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::get_user_internet_tariffs_all,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/:id/warnings/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::get_user_internet_id_warnings,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/internet/:id/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::put_user_internet_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/internet/:id/',
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::delete_user_internet_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/internet/mac/discovery/',
      params      => POST_INTERNET_MAC_DISCOVERY,
      controller  => 'Internet::Api::user::Root',
      endpoint    => \&Internet::Api::user::Root::post_user_internet_mac_discovery,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ];
}

1;
