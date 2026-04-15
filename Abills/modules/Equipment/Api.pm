package Equipment::Api;
=head1 NAME

  Equipment::Api - Equipment api functions

=head VERSION

  DATE: 20220210
  UPDATE: 20241111
  VERSION: 1.35

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
      path        => '/user/equipment/',
      endpoint    => \&Equipment::Api::user::Root::get_user_equipment,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
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
      method      => 'GET',
      path        => '/equipment/onu/list/',
      endpoint    => \&Equipment::Api::admin::Onu::get_equipment_onu_list,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/onu/:id/',
      endpoint    => \&Equipment::Api::admin::Onu::get_equipment_onu_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/box/list/',
      endpoint    => \&Equipment::Api::admin::Box::get_equipment_box_list,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/pon/ports/',
      endpoint    => \&Equipment::Api::admin::Pon::get_equipment_pon_ports,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/used/ports/',
      endpoint    => \&Equipment::Api::admin::Nas::get_equipment_used_ports,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/types/',
      endpoint    => \&Equipment::Api::admin::Nas::get_equipment_nas_types,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/list/extra/',
      endpoint    => \&Equipment::Api::admin::Nas::get_equipment_nas_list_extra,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/list/',
      endpoint    => \&Equipment::Api::admin::Nas::get_equipment_nas_list,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/',
      endpoint    => \&Equipment::Api::admin::Nas::post_equipment_nas,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/:id/',
      endpoint    => \&Equipment::Api::admin::Nas::delete_equipment_nas,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/:id/',
      endpoint    => \&Equipment::Api::admin::Nas::put_equipment_nas,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/groups/list/',
      endpoint    => \&Equipment::Api::admin::Nas::get_equipment_nas_groups_list,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/groups/add/',
      endpoint    => \&Equipment::Api::admin::Nas::post_equipment_nas_groups_add,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/groups/:id/',
      endpoint    => \&Equipment::Api::admin::Nas::put_equipment_nas_groups_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/groups/:id/',
      endpoint    => \&Equipment::Api::admin::Nas::delete_equipment_nas_groups_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/ip/pools/',
      endpoint    => \&Equipment::Api::admin::Nas::get_equipment_nas_ip_pools,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/ip/pools/',
      endpoint    => \&Equipment::Api::admin::Nas::post_equipment_nas_ip_pools,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/ip/pools/:nasId/:poolId/',
      endpoint    => \&Equipment::Api::admin::Nas::delete_equipment_nas_ip_pools_nasId_poolId,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/:uid/',
      endpoint    => \&Equipment::Api::admin::Users::get_equipment_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/:nas_id/:port_id/details/',
      endpoint    => \&Equipment::Api::admin::Users::get_equipment_nas_id_port_id_details,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/:id/details/',
      endpoint    => \&Equipment::Api::admin::Nas::post_equipment_nas_details,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/netmap/positions/',
      endpoint    => \&Equipment::Api::admin::Nas::post_equipment_nas_netmap_positions,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },

    {
      method      => 'GET',
      path        => '/equipment/nas/:nas_id/ports/',
      endpoint    => \&Equipment::Api::admin::Ports::get_equipment_nas_ports,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/:nas_id/ports/:port_id/',
      endpoint    => \&Equipment::Api::admin::Ports::put_equipment_nas_ports_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ]
}

1;
