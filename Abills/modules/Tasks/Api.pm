package Tasks::Api;
=head NAME

  Tasks::Api - Tasks api functions

=head VERSION

  DATE: 20230227
  UPDATE: 20241017
  VERSION: 0.02

=cut

use strict;
use warnings FATAL => 'all';

use Tasks::Validations qw/POST_TASKS/;

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
      path        => '/tasks/:id/',
      controller  => 'Tasks::Api::admin::Tasks',
      endpoint    => \&Tasks::Api::admin::Tasks::get_task_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/tasks/',
      controller  => 'Tasks::Api::admin::Tasks',
      endpoint    => \&Tasks::Api::admin::Tasks::get_tasks,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/tasks/',
      params      => POST_TASKS,
      controller  => 'Tasks::Api::admin::Tasks',
      endpoint    => \&Tasks::Api::admin::Tasks::post_tasks,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/tasks/:id/',
      controller  => 'Tasks::Api::admin::Tasks',
      endpoint    => \&Tasks::Api::admin::Tasks::put_tasks,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/tasks/:id/',
      controller  => 'Tasks::Api::admin::Tasks',
      endpoint    => \&Tasks::Api::admin::Tasks::delete_task_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },


    {
      method      => 'GET',
      path        => '/tasks/types/:id/',
      controller  => 'Tasks::Api::admin::Types',
      endpoint    => \&Tasks::Api::admin::Types::get_tasks_type_by_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'GET',
      path        => '/tasks/types/',
      controller  => 'Tasks::Api::admin::Types',
      endpoint    => \&Tasks::Api::admin::Types::get_tasks_types,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'POST',
      path        => '/tasks/types/',
      controller  => 'Tasks::Api::admin::Types',
      endpoint    => \&Tasks::Api::admin::Types::post_tasks_type,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'PUT',
      path        => '/tasks/types/:id/',
      controller  => 'Tasks::Api::admin::Types',
      endpoint    => \&Tasks::Api::admin::Types::put_tasks_type_by_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
    {
      method      => 'DELETE',
      path        => '/tasks/types/:id/',
      controller  => 'Tasks::Api::admin::Types',
      endpoint    => \&Tasks::Api::admin::Types::delete_tasks_type_by_id,
      credentials => [ 'ADMIN', 'ADMINSID' ]
    },
  ];
}

1;
