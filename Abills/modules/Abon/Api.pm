package Abon::Api;
=head NAME

  Abon::Api - Abon api functions

=head VERSION

  DATE: 20220628
  UPDATE: 20220628
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Abills::Base qw(date_diff);

my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }
  elsif ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf},
    { lang => $self->{lang}, module => 'Abon' }
  );

  $self->{Errors} = $Errors;

  return $self;
}


#**********************************************************
=head2 user_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at Abills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using Abills::Base::decamelize unless no_decamelize_params is set
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/user/abon/',
      controller  => 'Abon::Api::user::Root',
      endpoint    => \&Abon::Api::user::Root::get_user_abon,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/abon/:id/',
      controller  => 'Abon::Api::user::Root',
      endpoint    => \&Abon::Api::user::Root::post_user_abon,
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

  ARGUMENTS
    admin_routes: boolean - if true return all admin routes, false - user

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/:uid/', and queried URL
                                     # is '/users/9/', $path_params will be { uid => 9 }.
                                     # if credentials is 'USER', variable :uid will be checked to contain only
                                     # authorized user's UID.

          handler => sub {           # handler function, coderef. Arguments that are passed to handler:
            my (
                $path_params,        # params from path. look at docs of path. hashref.
                $query_params,       # params from query. for details look at Abills::Api::Router::new(). hashref.
                                     # keys will be converted from camelCase to UPPER_SNAKE_CASE
                                     # using Abills::Base::decamelize unless no_decamelize_params is set
                        # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

          ->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler a. optional.

          type    => 'HASH',         # type of returned data. may be 'HASH' or 'ARRAY'. by default (if not set) it is 'HASH'. optional.

          credentials => [           # arrayref of roles required to use this path. if API user is authorized as at least one of
                                     # these roles access to this path will be granted. optional.
            'ADMIN'                  # may be 'ADMIN' or 'USER'
          ],

          no_decamelize_params => 0, # if set, $query_params for handler will not be converted to UPPER_SNAKE_CASE. optional.

          conf_params => [ ... ]     # variables from $conf to be returned in result. arrayref.
                                     # experimental feature, currently disabled
        },
        ...
      ],
      $resource_2_name => [
        ...
      ],
      ...
    }

=cut
#**********************************************************
sub admin_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/abon/tariffs/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::get_abon_tariffs,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/abon/tariffs/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::post_abon_tariffs,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/tariffs/:id/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::get_abon_tariffs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/abon/tariffs/:id/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::put_abon_tariffs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/abon/tariffs/:id/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::delete_abon_tariffs_id,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/abon/tariffs/:id/users/:uid/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::get_abon_tariffs_id_users_uid,,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/abon/tariffs/:id/users/:uid/',
      controller  => 'Abon::Api::admin::Tariffs',
      endpoint    => \&Abon::Api::admin::Tariffs::delete_abon_tariffs_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/users/',
      controller  => 'Abon::Api::admin::Users',
      endpoint    => \&Abon::Api::admin::Users::get_abon_users,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/abon/plugin/:plugin_id/info/',
      controller  => 'Abon::Api::admin::Plugin',
      endpoint    => \&Abon::Api::admin::Plugin::get_abon_plugin_plugin_id_info,
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method       => 'GET',
      path         => '/abon/plugin/:plugin_id/print/',
      controller  => 'Abon::Api::admin::Plugin',
      endpoint    => \&Abon::Api::admin::Plugin::get_abon_plugin_plugin_id_print,
      credentials  => [
        'ADMINSID'
      ],
      content_type => 'Content-type: application/pdf'
    }
  ],
}

1;
