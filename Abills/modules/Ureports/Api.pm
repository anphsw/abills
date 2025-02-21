package Ureports::Api;

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
  return [
    {
      method      => 'GET',
      path        => '/ureports/user/list/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::get_ureports_user_list,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/ureports/user/:uid/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::get_ureports_user_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/ureports/user/:uid/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::post_ureports_user_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/ureports/user/:uid/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::put_ureports_user_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::delete_ureports_user_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/ureports/user/:uid/reports/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::get_ureports_user_uid_reports,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/ureports/user/:uid/reports/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::post_ureports_user_uid_reports,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/reports/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::delete_ureports_user_uid_reports,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/ureports/user/:uid/reports/:id/',
      controller  => 'Ureports::Api::admin::User',
      endpoint    => \&Ureports::Api::admin::User::delete_ureports_user_uid_reports_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/ureports/plugins/',
      controller  => 'Ureports::Api::admin::Plugins',
      endpoint    => \&Ureports::Api::admin::Plugins::get_ureports_plugins,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

1;
