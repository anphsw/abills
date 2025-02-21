package Api::Paths::Payments;
=head NAME

  Payments api functions

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
      method      => 'GET',
      path        => '/user/payments/',
      controller  => 'Api::Controllers::User::Payments',
      endpoint    => \&Api::Controllers::User::Payments::get_user_payments,
      credentials => [
        'USER', 'USERBOT'
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
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/payments/types/',
      controller  => 'Api::Controllers::Admin::Payments',
      endpoint    => \&Api::Controllers::Admin::Payments::get_payments_types,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/payments/',
      controller  => 'Api::Controllers::Admin::Payments',
      endpoint    => \&Api::Controllers::Admin::Payments::get_payments,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/payments/users/:uid/',
      controller  => 'Api::Controllers::Admin::Payments',
      endpoint    => \&Api::Controllers::Admin::Payments::get_payments,
      # That's not a typo, internally /payments/users/:uid/ and /payments/ is same.
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/payments/users/:uid/',
      controller  => 'Api::Controllers::Admin::Payments',
      endpoint    => \&Api::Controllers::Admin::Payments::post_payments_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/payments/users/:uid/:id/',
      controller  => 'Api::Controllers::Admin::Payments',
      endpoint    => \&Api::Controllers::Admin::Payments::delete_payments_users_uid_id,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
