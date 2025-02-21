package Api::Paths::Admins;
=head NAME

  Admins api functions

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
      method      => 'POST',
      path        => '/admins/login/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::post_admins_login,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      # TODO: add validation
      method      => 'POST',
      path        => '/admins/:aid/contacts/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::post_admins_aid_contacts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      # TODO: add validation
      method      => 'PUT',
      path        => '/admins/:aid/contacts/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::post_admins_aid_contacts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/:aid/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::get_admins_aid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/self/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::get_admins_self,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/admins/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::post_admins,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/admins/:aid/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::put_admins_aid,
      credentials => [
        'ADMIN',
        'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/admins/:aid/permissions/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::post_admins_aid_permissions,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/settings/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::get_admins_settings,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      # TODO: add validation
      method      => 'POST',
      path        => '/admins/settings/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::post_admins_settings,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/all/',
      controller  => 'Api::Controllers::Admin::Admins',
      endpoint    => \&Api::Controllers::Admin::Admins::get_admins_all,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
