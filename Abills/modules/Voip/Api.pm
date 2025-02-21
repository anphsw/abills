package Voip::Api;
=head NAME

  Voip::Api - Voip api functions

=head VERSION

  DATE: 20221212
  UPDATE: 20221212
  VERSION: 0.01

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
      method      => 'GET',
      path        => '/user/voip/',
      controller  => 'Voip::Api::user::Root',
      endpoint    => \&Voip::Api::user::Root::get_user_voip,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/voip/sessions/',
      controller  => 'Voip::Api::user::Root',
      endpoint    => \&Voip::Api::user::Root::get_user_voip_sessions,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/voip/routes/',
      controller  => 'Voip::Api::user::Root',
      endpoint    => \&Voip::Api::user::Root::get_user_voip_routes,
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/voip/tariffs/',
      controller  => 'Voip::Api::user::Root',
      endpoint    => \&Voip::Api::user::Root::get_user_voip_tariffs,
      credentials => [
        'USER'
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
  #TODO: add API for tariff intervals, recalculation and different reports

  return [
    {
      method      => 'GET',
      path        => '/voip/users/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::get_voip_users,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/:uid/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::post_voip_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/:uid/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::put_voip_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/:uid/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::get_voip_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/:uid/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::delete_voip_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/:uid/tariff/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::put_voip_uid_tariff,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/:uid/tariff/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::delete_voip_uid_tariff,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/phone/aliases/',
      controller  => 'Voip::Api::admin::Phones',
      endpoint    => \&Voip::Api::admin::Phones::get_voip_phone_aliases,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/:uid/phone/aliases/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::get_voip_uid_phone_aliases,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/:uid/phone/aliases/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::post_voip_uid_phone_aliases,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/:uid/phone/alias/:id/',
      controller  => 'Voip::Api::admin::Users',
      endpoint    => \&Voip::Api::admin::Users::delete_voip_uid_phone_aliases,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/tariffs/',
      controller  => 'Voip::Api::admin::Tariffs',
      endpoint    => \&Voip::Api::admin::Tariffs::get_voip_tariffs,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/tariff/:tpId/',
      controller  => 'Voip::Api::admin::Tariffs',
      endpoint    => \&Voip::Api::admin::Tariffs::get_voip_tariff_tpId,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/tariff/',
      controller  => 'Voip::Api::admin::Tariffs',
      endpoint    => \&Voip::Api::admin::Tariffs::post_voip_tariff,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/tariff/:tpId/',
      controller  => 'Voip::Api::admin::Tariffs',
      endpoint    => \&Voip::Api::admin::Tariffs::put_voip_tariff_tpId,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/tariff/:tpId/',
      controller  => 'Voip::Api::admin::Tariffs',
      endpoint    => \&Voip::Api::admin::Tariffs::delete_voip_tariff_tpId,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/routes/',
      controller  => 'Voip::Api::admin::Routes',
      endpoint    => \&Voip::Api::admin::Routes::get_voip_routes,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/route/:id/',
      controller  => 'Voip::Api::admin::Routes',
      endpoint    => \&Voip::Api::admin::Routes::get_voip_route_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/route/',
      controller  => 'Voip::Api::admin::Routes',
      endpoint    => \&Voip::Api::admin::Routes::post_voip_route,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/route/:id/',
      controller  => 'Voip::Api::admin::Routes',
      endpoint    => \&Voip::Api::admin::Routes::put_voip_route_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/route/:id/',
      controller  => 'Voip::Api::admin::Routes',
      endpoint    => \&Voip::Api::admin::Routes::delete_voip_route_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/extra/tarifications/',
      controller  => 'Voip::Api::admin::Extra',
      endpoint    => \&Voip::Api::admin::Extra::get_voip_extra_tarifications,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/extra/tarification/:id/',
      controller  => 'Voip::Api::admin::Extra',
      endpoint    => \&Voip::Api::admin::Extra::get_voip_extra_tarifications_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/extra/tarification/',
      controller  => 'Voip::Api::admin::Extra',
      endpoint    => \&Voip::Api::admin::Extra::post_voip_extra_tarification,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/extra/tarification/:id/',
      controller  => 'Voip::Api::admin::Extra',
      endpoint    => \&Voip::Api::admin::Extra::put_voip_extra_tarification_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/extra/tarification/:id/',
      controller  => 'Voip::Api::admin::Extra',
      endpoint    => \&Voip::Api::admin::Extra::delete_voip_extra_tarification_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/trunk/protocols/',
      controller  => 'Voip::Api::admin::Trunks',
      endpoint    => \&Voip::Api::admin::Trunks::get_voip_trunk_protocols,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/trunks/',
      controller  => 'Voip::Api::admin::Trunks',
      endpoint    => \&Voip::Api::admin::Trunks::get_voip_trunks,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/trunk/:id/',
      controller  => 'Voip::Api::admin::Trunks',
      endpoint    => \&Voip::Api::admin::Trunks::get_voip_trunk_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/voip/trunk/',
      controller  => 'Voip::Api::admin::Trunks',
      endpoint    => \&Voip::Api::admin::Trunks::post_voip_trunk,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/voip/trunk/:id/',
      controller  => 'Voip::Api::admin::Trunks',
      endpoint    => \&Voip::Api::admin::Trunks::delete_voip_trunk_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/voip/trunk/:id/',
      controller  => 'Voip::Api::admin::Trunks',
      endpoint    => \&Voip::Api::admin::Trunks::put_voip_trunk_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/voip/sessions/',
      controller  => 'Voip::Api::admin::Sessions',
      endpoint    => \&Voip::Api::admin::Sessions::get_voip_sessions,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
