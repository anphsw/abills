package Api::Paths::Companies;
=head NAME

  Callback api functions

=cut

use strict;
use warnings FATAL => 'all';

use Api::Validations::Companies qw(POST_COMPANY PUT_COMPANY PUT_COMPANY_ADMINS);

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
      path        => '/companies/',
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::get_companies,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/companies/:id/',
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::get_companies_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/companies/:id/users/',
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::get_companies_id_users,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/companies/',
      params      => POST_COMPANY,
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::post_companies,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/companies/:id/',
      params      => PUT_COMPANY,
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::put_companies_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/companies/:id/',
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::delete_companies_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/companies/public-records/:edrpou/',
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::get_companies_public_records_edrpou,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/companies/admins/',
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::get_companies_admins,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/companies/:id/admins/',
      params      => PUT_COMPANY_ADMINS,
      controller  => 'Api::Controllers::Admin::Companies',
      endpoint    => \&Api::Controllers::Admin::Companies::put_companies_id_admins,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

1;
