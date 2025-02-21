package Api::Paths::Bots;

=head NAME

  Api::Paths::Bots - Bots api functions

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 paths() - Returns available API paths

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
    #@deprecated
    {
      method      => 'POST',
      path        => '/user/bots/subscribe/phone/',
      controller  => 'Api::Controllers::Common::Bots',
      endpoint    => \&Api::Controllers::Common::Bots::post_bots_subscribe_phone,
      credentials => [
        'BOT_UNREG'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/user/bots/subscribe/',
      controller  => 'Api::Controllers::Common::Bots',
      endpoint    => \&Api::Controllers::Common::Bots::post_bots_subscribe,
      credentials => [
        'BOT_UNREG'
      ]
    },

    {
      method      => 'GET',
      path        => '/user/bots/subscribe/link/:string_bot/',
      controller  => 'Api::Controllers::User::Bots',
      endpoint    => \&Api::Controllers::User::Bots::get_user_bots_subscribe_link_bot,
      credentials => [
        'USER'
      ]
    },
    {
      method       => 'GET',
      path         => '/user/bots/subscribe/qrcode/:string_bot/',
      controller  => 'Api::Controllers::User::Bots',
      endpoint    => \&Api::Controllers::User::Bots::get_user_bots_subscribe_qrcode_bot,
      content_type => 'Content-Type: image/jpeg',
      credentials  => [
        'USER'
      ]
    },
  ];
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
      method      => 'POST',
      path        => '/bots/subscribe/phone/',
      controller  => 'Api::Controllers::Common::Bots',
      endpoint    => \&Api::Controllers::Common::Bots::post_bots_subscribe_phone,
      credentials => [
        'BOT_UNREG'
      ]
    },
    {
      method      => 'POST',
      path        => '/bots/subscribe/',
      controller  => 'Api::Controllers::Common::Bots',
      endpoint    => \&Api::Controllers::Common::Bots::post_bots_subscribe,
      credentials => [
        'BOT_UNREG'
      ]
    },

    {
      method      => 'GET',
      path        => '/bots/subscribe/link/:string_bot/',
      controller  => 'Api::Controllers::Admin::Bots',
      endpoint    => \&Api::Controllers::Admin::Bots::get_bots_subscribe_link_bot,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method       => 'GET',
      path         => '/bots/subscribe/qrcode/:string_bot/',
      controller  => 'Api::Controllers::Admin::Bots',
      endpoint    => \&Api::Controllers::Admin::Bots::get_bots_subscribe_qrcode_bot,
      content_type => 'Content-Type: image/jpeg',
      credentials  => [
        'ADMIN'
      ]
    },
  ];
}

1;
