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
      endpoint    => \&Api::Controllers::User::User_core::Login::delete_user_logout,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/',
      endpoint    => \&Api::Controllers::User::User_core::Info::get_user,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/pi/',
      endpoint    => \&Api::Controllers::User::User_core::Info::get_user_pi,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/pi/',
      endpoint    => \&Api::Controllers::User::User_core::Info::put_user_pi,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/credit/',
      endpoint    => \&Api::Controllers::User::User_core::Credit::post_user_credit,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/credit/',
      endpoint    => \&Api::Controllers::User::User_core::Credit::get_user_credit,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:id/holdup/',
      endpoint    => \&Api::Controllers::User::User_core::Holdup::get_user_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:id/holdup/',
      endpoint    => \&Api::Controllers::User::User_core::Holdup::post_user_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/:id/holdup/',
      endpoint    => \&Api::Controllers::User::User_core::Holdup::delete_user_id_holdup,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/password/send/',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_password_send,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/password/recovery/',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_password_recovery,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/resend/verification/',
      endpoint    => \&Api::Controllers::User::User_core::Registration::post_user_resend_verification,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/verify/',
      endpoint    => \&Api::Controllers::User::User_core::Registration::post_user_verify,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/reset/password/',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_reset_password,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/registration/',
      endpoint    => \&Api::Controllers::User::User_core::Registration::post_user_registration,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/password/reset/',
      endpoint    => \&Api::Controllers::User::User_core::Password::post_user_password_reset,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/config/',
      endpoint    => \&Api::Controllers::User::User_core::Config::get_user_config,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/social/networks/',
      endpoint    => \&Api::Controllers::User::User_core::Social::delete_user_social_networks,,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/social/networks/',
      endpoint    => \&Api::Controllers::User::User_core::Social::post_user_social_networks,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/services/',
      endpoint    => \&Api::Controllers::User::User_core::Root::get_user_services,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/services/statuses/',
      endpoint    => \&Api::Controllers::User::User_core::Root::get_user_services_statuses,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/recommendedPay/',
      endpoint    => \&Api::Controllers::Common::Users::get_user_recommendedPay,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/login/',
      endpoint    => \&Api::Controllers::User::User_core::Login::post_user_login,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/accept-rules/',
      endpoint    => \&Api::Controllers::User::User_core::Root::post_user_acceptRules,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ];
}

1;
