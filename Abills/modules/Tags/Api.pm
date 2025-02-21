package Tags::Api v1.01.00;
=head1 NAME

  Tags::Api - Tags api functions

=cut

use strict;
use warnings FATAL => 'all';

use Tags::Api::Validations qw(POST_TAGS);

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
      path        => '/tags/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::get_tags,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/tags/',
      params      => POST_TAGS,
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::post_tags,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/tags/:id/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::get_tags_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/tags/:id/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::put_tags_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/tags/:id/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::delete_tags_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/tags/:id/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::post_tags_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/tags/:id/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::put_tags_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/tags/:id/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::delete_tags_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/tags/users/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::get_tags_users,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::get_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::post_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::put_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PATCH',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::patch_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
