package Api::Paths::Groups;
=head NAME

  Groups api functions

=cut

use strict;
use warnings FATAL => 'all';

use Api::Validations::Groups qw(POST_GROUP PUT_GROUP);

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
      path        => '/groups/',
      controller  => 'Api::Controllers::Admin::Groups',
      endpoint    => \&Api::Controllers::Admin::Groups::get_groups,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/groups/:id/',
      controller  => 'Api::Controllers::Admin::Groups',
      endpoint    => \&Api::Controllers::Admin::Groups::get_groups_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/groups/',
      params      => POST_GROUP,
      controller  => 'Api::Controllers::Admin::Groups',
      endpoint    => \&Api::Controllers::Admin::Groups::post_groups,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/groups/:id/',
      params      => PUT_GROUP,
      controller  => 'Api::Controllers::Admin::Groups',
      endpoint    => \&Api::Controllers::Admin::Groups::put_groups_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/groups/:id/',
      controller  => 'Api::Controllers::Admin::Groups',
      endpoint    => \&Api::Controllers::Admin::Groups::delete_groups_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

1;
