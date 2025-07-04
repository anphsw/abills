package Triplay::Api v1.0.1;
=head NAME

  Triplay::Api - Triplay api functions

=head VERSION

  DATE: 20240729
  UPDATE: 20240729
  VERSION: 1.01

=cut

use strict;
use warnings FATAL => 'all';

use Triplay::Validations qw(POST_TRIPLAY_USERS PUT_TRIPLAY_USERS PATCH_TRIPLAY_USERS);


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
      path        => '/triplay/tariffs/',
      controller  => 'Triplay::Api::Admin::Tariffs',
      endpoint    => \&Triplay::Api::Admin::Tariffs::get_triplay_tariffs,
      credentials => [
        'ADMIN',
      ]
    },
    {
      method      => 'GET',
      path        => '/triplay/users/',
      controller  => 'Triplay::Api::Admin::Users',
      endpoint    => \&Triplay::Api::Admin::Users::get_triplay_users,
      credentials => [
        'ADMIN',
      ]
    },
    {
      method      => 'GET',
      path        => '/triplay/users/:uid/',
      controller  => 'Triplay::Api::Admin::Users',
      endpoint    => \&Triplay::Api::Admin::Users::get_triplay_users_uid,
      credentials => [
        'ADMIN',
      ]
    },
    {
      method      => 'POST',
      path        => '/triplay/users/:uid/',
      params      => POST_TRIPLAY_USERS,
      controller  => 'Triplay::Api::Admin::Users',
      endpoint    => \&Triplay::Api::Admin::Users::post_triplay_users_uid,
      credentials => [
        'ADMIN',
      ]
    },
    #TODO: add when will be isolated Triplay::Users::triplay_chg_tp()
    # {
    #   method      => 'PUT',
    #   path        => '/triplay/users/:uid/',
    #   params      => PUT_TRIPLAY_USERS,
    #   controller  => 'Triplay::Api::Admin::Users',
    #   endpoint    => \&Triplay::Api::Admin::Users::put_triplay_users_uid,
    #   credentials => [
    #     'ADMIN',
    #   ]
    # },
    {
      method      => 'PATCH',
      path        => '/triplay/users/:uid/',
      params      => PATCH_TRIPLAY_USERS,
      controller  => 'Triplay::Api::Admin::Users',
      endpoint    => \&Triplay::Api::Admin::Users::patch_triplay_users_uid,
      credentials => [
        'ADMIN',
      ]
    },
    {
      method      => 'DELETE',
      path        => '/triplay/users/:uid/',
      controller  => 'Triplay::Api::Admin::Users',
      endpoint    => \&Triplay::Api::Admin::Users::delete_triplay_users_uid,
      credentials => [
        'ADMIN',
      ]
    },
  ],
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
      path        => '/user/triplay/',
      controller  => 'Triplay::Api::User::Services',
      endpoint    => \&Triplay::Api::User::Services::get_user_triplay,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ],
}

1;
