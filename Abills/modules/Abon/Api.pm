package Abon::Api;
=head NAME

  Abon::Api - Abon api functions

=head VERSION

  DATE: 20220628
  UPDATE: 20220628
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

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
      method      => 'GET',
      path        => '/user/abon/',
      controller  => 'Abon::Api::user::Root',
      endpoint    => \&Abon::Api::user::Root::get_user_abon,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/abon/:id/',
      controller  => 'Abon::Api::user::Root',
      endpoint    => \&Abon::Api::user::Root::post_user_abon,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

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
      method      => 'GET',
      path        => '/abon/tariffs/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::get_abon_tariffs,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/abon/tariffs/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::post_abon_tariffs,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/tariffs/:id/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::get_abon_tariffs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/abon/tariffs/:id/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::put_abon_tariffs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/abon/tariffs/:id/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::delete_abon_tariffs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/abon/tariffs/:id/users/:uid/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::get_abon_tariffs_id_users_uid,,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/abon/tariffs/:id/users/:uid/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::delete_abon_tariffs_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/users/',
      controller  => 'Abon::Api::admin::Users',
      endpoint    => \&Abon::Api::admin::Users::get_abon_users,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/plugin/:plugin_id/info/',
      controller  => 'Abon::Api::admin::Plugin',
      endpoint    => \&Abon::Api::admin::Plugin::get_abon_plugin_plugin_id_info,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method       => 'GET',
      path         => '/abon/plugin/:plugin_id/print/',
      controller  => 'Abon::Api::admin::Plugin',
      endpoint    => \&Abon::Api::admin::Plugin::get_abon_plugin_plugin_id_print,
      credentials  => [
        'ADMIN', 'ADMINSID'
      ],
      content_type => 'Content-type: application/pdf'
    }
  ],
}

1;
