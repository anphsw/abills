package Referral::Api;
=head NAME

  Referral::Api - Referral api functions

=head VERSION

  DATE: 20220109
  UPDATE: 20220109
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
      path        => '/user/referral/',
      controller  => 'Referral::Api::user::Root',
      endpoint    => \&Referral::Api::user::Root::get_user_referral,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/referral/bonus/',
      controller  => 'Referral::Api::user::Root',
      endpoint    => \&Referral::Api::user::Root::post_user_referral_bonus,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/referral/bonus/',
      controller  => 'Referral::Api::user::Root',
      endpoint    => \&Referral::Api::user::Root::get_user_referral_bonus,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/referral/friend/',
      controller  => 'Referral::Api::user::Root',
      endpoint    => \&Referral::Api::user::Root::post_user_referral_friend,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/referral/friend/:id/',
      controller  => 'Referral::Api::user::Root',
      endpoint    => \&Referral::Api::user::Root::put_user_referral_friend_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

1;
