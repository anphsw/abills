package Api::Paths::Contacts;
=head NAME

  Api::Paths::Contacts - Contacts api functions

=cut

use strict;
use warnings FATAL => 'all';

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
      method      => 'DELETE',
      path        => '/user/contacts/:id/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::get_user_contacts_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/contacts/push/subscribe/:id/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::post_user_contacts_push_subscribe_id,
      credentials => [
        'USER', 'PUBLIC'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/contacts/push/subscribe/:id/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::delete_user_contacts_push_subscribe_id,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/contacts/push/subscribe/:id/:string_token/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::delete_user_contacts_push_subscribe_id_string_token,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/contacts/push/subscribe/:id/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::get_user_contacts_push_subscribe_id,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/contacts/push/messages/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::get_user_contacts_push_messages,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/contacts/push/badges/:id/',
      controller  => 'Api::Controllers::User::Contacts',
      endpoint    => \&Api::Controllers::User::Contacts::delete_user_contacts_push_badges,
      credentials => [
        'USER'
      ]
    },
  ];
}

1;
