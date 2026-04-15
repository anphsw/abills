package Msgs::Api v1.11.00;
=head NAME

  Msgs::Api - Msgs api functions

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
      path        => '/user/msgs/chapters/',
      endpoint    => \&Msgs::Api::user::Root::get_user_msgs_chapters,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/msgs/',
      endpoint    => \&Msgs::Api::user::Root::get_user_msgs,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/msgs/',
      endpoint    => \&Msgs::Api::user::Root::post_user_msgs,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/msgs/:id/',
      endpoint    => \&Msgs::Api::user::Root::get_user_msgs_id,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/msgs/:id/reply/',
      endpoint    => \&Msgs::Api::user::Root::get_user_msgs_id_reply,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/msgs/:id/reply/',
      endpoint    => \&Msgs::Api::user::Root::post_user_msgs_id_reply,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method       => 'GET',
      path         => '/user/msgs/attachments/:id/',
      endpoint    => \&Msgs::Api::user::Root::get_user_msgs_attachments_id,
      credentials  => [
        'USER', 'USERBOT'
      ],
      content_type => 'undefined',
    },
    {
      method      => 'POST',
      path        => '/user/msgs/search/',
      endpoint    => \&Msgs::Api::user::Root::post_user_msgs_search,
      credentials => [
        'USER'
      ]
    }
  ]
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
      method      => 'POST',
      path        => '/msgs/',
      endpoint    => \&Msgs::Api::admin::Root::post_msgs,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/statuses/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_statuses,
      credentials => [
        'ADMIN', 'ADMINBOT', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/:id/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_id,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/msgs/:id/',
      endpoint    => \&Msgs::Api::admin::Root::put_msgs_id,
      credentials => [
        'ADMIN', 'ADMINSID', 'ADMINBOT'
      ]
    },
    #@deprecated
    # {
    #   method      => 'POST',
    #   path        => '/msgs/list/',
    #   endpoint    => \&Msgs::Api::admin::Root::post_msgs_list,
    #   credentials => [
    #     'ADMIN'
    #   ]
    # },
    {
      method      => 'GET',
      path        => '/msgs/list/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_list,
      credentials => [
        'ADMIN', 'ADMINSID', 'ADMINBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/workflow/',
      endpoint    => \&Msgs::Api::admin::Workflow::post_msgs_workflow,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/workflow/:id/',
      endpoint    => \&Msgs::Api::admin::Workflow::post_msgs_workflow_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/:id/reply/',
      endpoint    => \&Msgs::Api::admin::Root::post_msgs_id_reply,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      #TODO: add validations. closed STATE allowed only when present permission
      method      => 'GET',
      path        => '/msgs/:id/reply/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_id_reply,
      credentials => [
        'ADMIN'
      ]
    },
    {
      #TODO: we can save attachment with wrong filesize. fix it?
      method      => 'POST',
      path        => '/msgs/reply/:reply_id/attachment/',
      endpoint    => \&Msgs::Api::admin::Root::post_msgs_reply_reply_id_attachment,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/chapters/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_chapters,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/report/dynamics/',
      endpoint    => \&Msgs::Api::admin::Reports::get_msgs_report_dynamics,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/msgs/survey/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_survey,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/search/',
      endpoint    => \&Msgs::Api::admin::Root::get_msgs_search,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/:id/ai_suggest/',
      controller  => 'Msgs::Api::admin::AI',
      endpoint    => \&Msgs::Api::admin::AI::post_msgs_id_ai_suggest,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/:id/ai_feedback/',
      controller  => 'Msgs::Api::admin::AI',
      endpoint    => \&Msgs::Api::admin::AI::post_msgs_id_ai_feedback,
      credentials => [
        'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/msgs/ai_translate/',
      controller  => 'Msgs::Api::admin::AI',
      endpoint    => \&Msgs::Api::admin::AI::post_msgs_ai_translate,
      credentials => [
        'ADMINSID'
      ]
    },
  ];
}

1;
