package Portal::Api;

=head1 NAME

  Portal Api

=cut

use strict;
use warnings FATAL => 'all';

use Portal::Validations qw(POST_PORTAL_NEWSLETTER POST_PORTAL_ARTICLES POST_PORTAL_MENUS);

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
      path        => '/user/portal/menu/',
      endpoint    => \&Portal::Api::user::News::get_user_portal_menu,
      credentials => [
        'USER', 'USERBOT', 'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/portal/news/',
      endpoint    => \&Portal::Api::user::News::get_user_portal_news,
      credentials => [
        'USER', 'USERBOT', 'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/portal/news/:string_id/',
      endpoint    => \&Portal::Api::user::News::get_user_portal_news_id,
      credentials => [
        'USER', 'USERBOT', 'PUBLIC'
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
      path        => '/portal/attachment/',
      endpoint    => \&Portal::Api::admin::Attachment::get_portal_attachment,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/attachment/',
      endpoint    => \&Portal::Api::admin::Attachment::post_portal_attachment,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/attachment/:id/',
      endpoint    => \&Portal::Api::admin::Attachment::get_portal_attachment_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/attachment/:id/',
      endpoint    => \&Portal::Api::admin::Attachment::delete_portal_attachment_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/newsletter/',
      endpoint    => \&Portal::Api::admin::Newsletter::get_portal_newsletter,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/newsletter/',
      params      => POST_PORTAL_NEWSLETTER,
      endpoint    => \&Portal::Api::admin::Newsletter::post_portal_newsletter,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/newsletter/:id/',
      endpoint    => \&Portal::Api::admin::Newsletter::get_portal_newsletter_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/newsletter/:id/',
      endpoint    => \&Portal::Api::admin::Newsletter::delete_portal_newsletter_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/articles/',
      endpoint    => \&Portal::Api::admin::Articles::get_portal_articles,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/articles/',
      params      => POST_PORTAL_ARTICLES,
      endpoint    => \&Portal::Api::admin::Articles::post_portal_articles,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/articles/:id/',
      endpoint    => \&Portal::Api::admin::Articles::get_portal_articles_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/portal/articles/:id/',
      endpoint    => \&Portal::Api::admin::Articles::put_portal_articles_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/articles/:id/',
      endpoint    => \&Portal::Api::admin::Articles::delete_portal_articles_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/menus/',
      endpoint    => \&Portal::Api::admin::Menus::get_portal_menus,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/portal/menus/',
      params      => POST_PORTAL_MENUS,
      endpoint    => \&Portal::Api::admin::Menus::post_portal_menus,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/portal/menus/:id/',
      endpoint    => \&Portal::Api::admin::Menus::get_portal_menus_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/portal/menus/:id/',
      endpoint    => \&Portal::Api::admin::Menus::put_portal_menus_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/portal/menus/:id/',
      endpoint    => \&Portal::Api::admin::Menus::delete_portal_menus_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

1;
