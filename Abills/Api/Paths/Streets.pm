package Api::Paths::Streets;
=head NAME

  Streets api functions

=cut

use strict;
use warnings FATAL => 'all';

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
      path        => '/streets/',
      controller  => 'Api::Controllers::Admin::Streets',
      endpoint    => \&Api::Controllers::Admin::Streets::get_streets,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/streets/:id/',
      controller  => 'Api::Controllers::Admin::Streets',
      endpoint    => \&Api::Controllers::Admin::Streets::get_streets_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/streets/',
      controller  => 'Api::Controllers::Admin::Streets',
      endpoint    => \&Api::Controllers::Admin::Streets::post_streets,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/streets/:id/',
      controller  => 'Api::Controllers::Admin::Streets',
      endpoint    => \&Api::Controllers::Admin::Streets::put_streets_id,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
