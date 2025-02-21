package Paysys::Api v1.10.0;
=head NAME

  Paysys::Api - Paysys api functions

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
      path        => '/user/paysys/systems/',
      controller  => 'Paysys::Api::user::Root',
      endpoint    => \&Paysys::Api::user::Root::get_user_paysys_systems,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/paysys/transaction/status/:string_id/',
      controller  => 'Paysys::Api::user::Root',
      endpoint    => \&Paysys::Api::user::Root::get_user_paysys_transaction_status_string_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/paysys/pay/',
      controller  => 'Paysys::Api::user::Root',
      endpoint    => \&Paysys::Api::user::Root::post_user_paysys_pay,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/paysys/applePay/session/',
      controller  => 'Paysys::Api::user::Root',
      endpoint    => \&Paysys::Api::user::Root::post_user_paysys_applepay_session,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/paysys/recurrent/',
      controller  => 'Paysys::Api::user::Root',
      endpoint    => \&Paysys::Api::user::Root::get_user_paysys_recurrent,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/paysys/recurrent/',
      controller  => 'Paysys::Api::user::Root',
      endpoint    => \&Paysys::Api::user::Root::get_user_paysys_recurrent,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

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
      path        => '/paysys/merchants/',
      controller  => 'Paysys::Api::admin::Merchants',
      endpoint    => \&Paysys::Api::admin::Merchants::get_paysys_merchants,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ]
}

1;
