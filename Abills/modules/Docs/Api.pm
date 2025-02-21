package Docs::Api;
=head NAME

  Docs::Api - Docs api functions

=head VERSION

  DATE: 20230703
  UPDATE: 20230703
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Docs::Validations qw(POST_INVOICE_ADD POST_DOCS_INVOICES_PAYMENTS DELETE_DOCS_INVOICES_PAYMENTS PATCH_DOCS_INVOICES_PAYMENTS POST_USER_DOCS_INVOICES);

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
sub admin_routes {
  return [
    {
      method      => 'GET',
      path        => '/docs/invoices/payments/',
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::get_docs_invoices_payments,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/docs/invoices/payments/',
      params      => POST_DOCS_INVOICES_PAYMENTS,
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::post_docs_invoices_payments,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PATCH',
      path        => '/docs/invoices/payments/',
      params      => PATCH_DOCS_INVOICES_PAYMENTS,
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::patch_docs_invoices_payments,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/invoices/',
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::get_docs_invoices,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/invoices/:id/',
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::get_docs_invoices_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      #TODO: use in future when will known all properties
      # params      => POST_INVOICE_ADD,
      path        => '/docs/invoices/',
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::post_docs_invoices,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/docs/invoices/:id/',
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::put_docs_invoices_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/docs/invoices/',
      params      => DELETE_DOCS_INVOICES_PAYMENTS,
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::delete_docs_invoices,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/invoices/:uid/period/',
      controller  => 'Docs::Api::admin::Invoices',
      endpoint    => \&Docs::Api::admin::Invoices::get_docs_invoices_period,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/users/:uid/',
      controller  => 'Docs::Api::admin::Users',
      endpoint    => \&Docs::Api::admin::Users::get_docs_users_uid,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/edocs/branches/',
      controller  => 'Docs::Api::admin::Edocs',
      endpoint    => \&Docs::Api::admin::Edocs::get_docs_edocs_branches,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/docs/edocs/',
      controller  => 'Docs::Api::admin::Edocs',
      endpoint    => \&Docs::Api::admin::Edocs::post_docs_edocs,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/docs/edocs/',
      controller  => 'Docs::Api::admin::Edocs',
      endpoint    => \&Docs::Api::admin::Edocs::get_docs_edocs,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/docs/edocs/:id/',
      controller  => 'Docs::Api::admin::Edocs',
      endpoint    => \&Docs::Api::admin::Edocs::delete_docs_edocs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ]
}

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
      path        => '/user/docs/invoices/',
      controller  => 'Docs::Api::user::Invoices',
      endpoint    => \&Docs::Api::user::Invoices::get_user_docs_invoices,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/docs/invoices/:id/',
      controller  => 'Docs::Api::user::Invoices',
      endpoint    => \&Docs::Api::user::Invoices::get_user_docs_invoices_id,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      params      => POST_USER_DOCS_INVOICES,
      path        => '/user/docs/invoices/',
      controller  => 'Docs::Api::user::Invoices',
      endpoint    => \&Docs::Api::user::Invoices::post_user_docs_invoices,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/docs/invoices/period/',
      controller  => 'Docs::Api::user::Invoices',
      endpoint    => \&Docs::Api::user::Invoices::get_user_docs_invoices_period,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/docs/',
      controller  => 'Docs::Api::user::Root',
      endpoint    => \&Docs::Api::user::Root::get_user_docs,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/docs/edocs/sign/:id/',
      controller  => 'Docs::Api::user::Edocs',
      endpoint    => \&Docs::Api::user::Edocs::get_user_docs_edocs_sign_id,
      credentials => [
        'USER'
      ]
    },
  ],
}

1;
