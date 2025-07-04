package Api::Paths::Fees;
=head NAME

  Fees api functions

=cut

use strict;
use warnings FATAL => 'all';

use Api::Validations::Fees qw(POST_FEES_TYPES PUT_FEES_TYPES);

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
      path        => '/user/fees/',
      controller  => 'Api::Controllers::User::Fees',
      endpoint    => \&Api::Controllers::User::Fees::get_user_fees,
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
      path        => '/fees/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::get_fees,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/types/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::get_fees_types,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/types/:id/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::get_fees_types_id,
      credentials =>[
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/fees/types/:id/',
      params      => POST_FEES_TYPES,
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::post_fees_types_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/fees/types/:id/',
      params      => PUT_FEES_TYPES,
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::put_fees_types_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/fees/types/:id/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::delete_fees_types_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/users/:uid/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::get_fees,
      # That's not a typo, internally /fees/users/:uid/ and /fees/ is same.
      credentials => [
        'ADMIN'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/fees/users/:uid/:sum/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::post_fees_users_uid_sum,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/fees/users/:uid/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::post_fees_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/schedules/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::get_fees_schedules,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/fees/users/:uid/:id/',
      controller  => 'Api::Controllers::Admin::Fees',
      endpoint    => \&Api::Controllers::Admin::Fees::delete_fees_users_uid_id,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
