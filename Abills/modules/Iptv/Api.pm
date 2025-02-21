package Iptv::Api;
=head NAME

  Iptv::Api - Iptv api functions

=head VERSION

  DATE: 20220715
  UPDATE: 20241111
  VERSION: 1.35

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
      path        => '/user/iptv/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/services/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_services,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/:id/tariffs/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_id_tariffs,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/:id/warnings/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_id_warnings,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/tariffs/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_tariffs,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/tariffs/:service_id/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_tariffs_service_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/promotion/tariffs/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_promotion_tariffs,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/:id/holdup/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/iptv/:id/holdup/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::post_user_iptv_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/iptv/:id/holdup/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::delete_user_iptv_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/iptv/tariff/add/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::post_user_iptv_tariff_add,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/iptv/:id/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::put_user_iptv_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/iptv/:id/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::delete_user_iptv_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/iptv/:id/activate/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::post_user_iptv_id_activate,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/:id/playlist/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_id_playlist,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/iptv/:id/url/',
      controller  => 'Iptv::Api::user::Root',
      endpoint    => \&Iptv::Api::user::Root::get_user_iptv_id_url,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

1;
