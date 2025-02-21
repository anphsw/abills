package Api::Paths::User_core;
=head NAME

  Api::Paths::User_core - User api functions

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
    {
      method      => 'DELETE',
      path        => '/user/logout/',
      controller  => 'Api::Controllers::User::User_core::Login',
      endpoint    => \&Api::Controllers::User::User_core::Login::delete_user_logout,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/',
      controller  => 'Api::Controllers::User::User_core::Info',
      endpoint    => \&Api::Controllers::User::User_core::Info::get_user,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/pi/',
      controller  => 'Api::Controllers::User::User_core::Info',
      endpoint    => \&Api::Controllers::User::User_core::Info::get_user_pi,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/pi/',
      controller  => 'Api::Controllers::User::User_core::Info',
      endpoint    => \&Api::Controllers::User::User_core::Info::put_user_pi,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/credit/',
      controller  => 'Api::Controllers::User::User_core::Credit',
      endpoint    => \&Api::Controllers::User::User_core::Credit::post_user_credit,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/credit/',
      controller  => 'Api::Controllers::User::User_core::Credit',
      endpoint    => \&Api::Controllers::User::User_core::Credit::get_user_credit,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:id/holdup/',
      controller  => 'Api::Controllers::User::User_core::Holdup',
      endpoint    => \&Api::Controllers::User::User_core::Holdup::get_user_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:id/holdup/',
      controller  => 'Api::Controllers::User::User_core::Holdup',
      endpoint    => \&Api::Controllers::User::User_core::Holdup::post_user_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/:id/holdup/',
      controller  => 'Api::Controllers::User::User_core::Holdup',
      endpoint    => \&Api::Controllers::User::User_core::Holdup::delete_user_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/password/send/',
      controller  => 'Api::Controllers::User::User_core::Password',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_password_send,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/password/recovery/',
      controller  => 'Api::Controllers::User::User_core::Password',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_password_recovery,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/resend/verification/',
      controller  => 'Api::Controllers::User::User_core::Registration',
      endpoint    => \&Api::Controllers::User::User_core::Registration::post_user_resend_verification,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/verify/',
      controller  => 'Api::Controllers::User::User_core::Registration',
      endpoint    => \&Api::Controllers::User::User_core::Registration::post_user_verify,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/reset/password/',
      controller  => 'Api::Controllers::User::User_core::Password',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_reset_password,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/registration/',
      controller  => 'Api::Controllers::User::User_core::Registration',
      endpoint    => \&Api::Controllers::User::User_core::Registration::post_user_registration,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/password/reset/',
      controller  => 'Api::Controllers::User::User_core::Password',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_password_reset,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/config/',
      controller  => 'Api::Controllers::User::User_core::Config',
      endpoint    => \&Api::Controllers::User::User_core::Config::get_user_config,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/social/networks/',
      controller  => 'Api::Controllers::User::User_core::Social',
      endpoint    => \&Api::Controllers::User::User_core::Social::delete_user_social_networks,,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/social/networks/',
      controller  => 'Api::Controllers::User::User_core::Social',
      endpoint    => \&Api::Controllers::User::User_core::Social::post_user_social_networks,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/services/',
      controller  => 'Api::Controllers::User::User_core::Root',
      endpoint    => \&Api::Controllers::User::User_core::Root::get_user_services,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/recommendedPay/',
      controller  => 'Api::Controllers::User::User_core::Root',
      endpoint    => \&Api::Controllers::User::User_core::Root::get_user_recommendedPay,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/login/',
      controller  => 'Api::Controllers::User::User_core::Login',
      endpoint    => \&Api::Controllers::User::User_core::Login::post_user_login,
      credentials => [
        'PUBLIC'
      ]
    },
  ];
}

1;
