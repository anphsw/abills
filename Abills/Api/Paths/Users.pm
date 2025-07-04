package Api::Paths::Users;
=head NAME

  Users api functions

=cut

use strict;
use warnings FATAL => 'all';

use Api::Validations::Contracts qw(POST_USERS_CONTRACTS PUT_USERS_CONTRACTS);
use Api::Validations::Statuses qw(POST_USERS_STATUSES PUT_USERS_STATUSES);

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
    #@deprecated delete in future
    {
      method      => 'POST',
      path        => '/users/login/',
      controller  => 'Api::Controllers::User::User_core::Login',
      endpoint    => \&Api::Controllers::User::User_core::Login::post_user_login,
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/all/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::get_users_all,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::get_users_uid,
      credentials => [
        'ADMIN', 'ADMINBOT', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/users/:uid/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::put_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/users/:uid/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::delete_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/pi/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::get_users_uid_pi,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::post_users,
      credentials => [
        'ADMIN'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/users/:uid/pi/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::post_users_uid_pi,
      credentials => [
        'ADMIN'
      ]
    },
    #@deprecated
    {
      method      => 'PUT',
      path        => '/users/:uid/pi/',
      controller  => 'Api::Controllers::Admin::Users::Info',
      endpoint    => \&Api::Controllers::Admin::Users::Info::put_users_uid_pi,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/abon/',
      controller  => 'Api::Controllers::Admin::Users::Abon',
      endpoint    => \&Api::Controllers::Admin::Users::Abon::get_users_uid_abon,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/internet/all/',
      controller  => 'Api::Controllers::Admin::Users::Internet',
      endpoint    => \&Api::Controllers::Admin::Users::Internet::get_users_internet_all,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/internet/',
      controller  => 'Api::Controllers::Admin::Users::Internet',
      endpoint    => \&Api::Controllers::Admin::Users::Internet::get_users_uid_internet,
      credentials => [
        'ADMIN', 'ADMINBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/internet/:id/',
      controller  => 'Api::Controllers::Admin::Users::Internet',
      endpoint    => \&Api::Controllers::Admin::Users::Internet::get_users_uid_internet_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/contacts/',
      controller  => 'Api::Controllers::Admin::Users::Contacts',
      endpoint    => \&Api::Controllers::Admin::Users::Contacts::post_users_contacts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/contacts/',
      controller  => 'Api::Controllers::Admin::Users::Contacts',
      endpoint    => \&Api::Controllers::Admin::Users::Contacts::get_users_uid_contacts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/:uid/contacts/',
      controller  => 'Api::Controllers::Admin::Users::Contacts',
      endpoint    => \&Api::Controllers::Admin::Users::Contacts::post_users_uid_contacts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/users/:uid/contacts/:id/',
      controller  => 'Api::Controllers::Admin::Users::Contacts',
      endpoint    => \&Api::Controllers::Admin::Users::Contacts::delete_users_uid_contacts_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/users/:uid/contacts/:id/',
      controller  => 'Api::Controllers::Admin::Users::Contacts',
      endpoint    => \&Api::Controllers::Admin::Users::Contacts::put_users_uid_contacts_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/iptv/',
      controller  => 'Api::Controllers::Admin::Users::Iptv',
      endpoint    => \&Api::Controllers::Admin::Users::Iptv::get_users_uid_iptv,
      credentials => [
        'ADMIN'
      ]
    },
    {
      #TODO: :uid is not used
      method      => 'GET',
      path        => '/users/:uid/iptv/:id/',
      controller  => 'Api::Controllers::Admin::Users::Iptv',
      endpoint    => \&Api::Controllers::Admin::Users::Iptv::get_users_uid_iptv_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/contracts/types/',
      controller  => 'Api::Controllers::Admin::Users::Contracts',
      endpoint    => \&Api::Controllers::Admin::Users::Contracts::get_users_contracts_types,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/contracts/',
      controller  => 'Api::Controllers::Admin::Users::Contracts',
      endpoint    => \&Api::Controllers::Admin::Users::Contracts::get_users_contracts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/contracts/',
      params      => POST_USERS_CONTRACTS,
      controller  => 'Api::Controllers::Admin::Users::Contracts',
      endpoint    => \&Api::Controllers::Admin::Users::Contracts::post_users_contracts,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/users/contracts/:id/',
      params      => PUT_USERS_CONTRACTS,
      controller  => 'Api::Controllers::Admin::Users::Contracts',
      endpoint    => \&Api::Controllers::Admin::Users::Contracts::put_users_contracts_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/users/contracts/:id/',
      controller  => 'Api::Controllers::Admin::Users::Contracts',
      endpoint    => \&Api::Controllers::Admin::Users::Contracts::delete_users_contracts_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method       => 'GET',
      path         => '/users/contracts/:id/',
      controller   => 'Api::Controllers::Admin::Users::Contracts',
      endpoint     => \&Api::Controllers::Admin::Users::Contracts::get_users_contracts_id,
      content_type => 'Content-type: application/pdf',
      credentials  => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/history/',
      controller   => 'Api::Controllers::Admin::Users::Root',
      endpoint     => \&Api::Controllers::Admin::Users::Root::get_users_uid_history,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/statuses/',
      controller  => 'Api::Controllers::Admin::Users::Statuses',
      endpoint    => \&Api::Controllers::Admin::Users::Statuses::get_users_statuses,
      credentials => [ 'ADMIN' ]
    },
    {
      method      => 'POST',
      path        => '/users/statuses/:id/',
      params      => POST_USERS_STATUSES,
      controller  => 'Api::Controllers::Admin::Users::Statuses',
      endpoint    => \&Api::Controllers::Admin::Users::Statuses::post_users_statuses,
      credentials => [ 'ADMIN' ]
    },
    {
      method      => 'PUT',
      path        => '/users/statuses/:id/',
      params      => PUT_USERS_STATUSES,
      controller  => 'Api::Controllers::Admin::Users::Statuses',
      endpoint    => \&Api::Controllers::Admin::Users::Statuses::put_users_statuses_id,
      credentials => [ 'ADMIN' ]
    },
    {
      method      => 'DELETE',
      path        => '/users/statuses/:id/',
      controller  => 'Api::Controllers::Admin::Users::Statuses',
      endpoint    => \&Api::Controllers::Admin::Users::Statuses::delete_users_statuses_id,
      credentials => [ 'ADMIN' ]
    },
    {
      method      => 'GET',
      path        => '/users/statuses/:id/',
      controller  => 'Api::Controllers::Admin::Users::Statuses',
      endpoint    => \&Api::Controllers::Admin::Users::Statuses::get_users_statuses_id,
      credentials => [ 'ADMIN' ]
    },
  ];
}

1;
