package Tags::Api v1.01.00;
=head1 NAME

  Tags::Api - Tags api functions

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

use Tags;
use Tags::Api::Validations qw(POST_TAGS);

my Control::Errors $Errors;
my Tags $Tags;

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

  $self->{routes_list} = ();

  bless($self, $class);

  $Tags = Tags->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $lang, module => 'Tags' });
  $self->{Errors} = $Errors;

  $Tags->{debug} = $self->{debug} || 0;

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  return $self;
}

#**********************************************************
=head2 admin_routes() - Returns available API paths

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
                $module_obj          # object of needed DB module (in this example - Users). used to run it's methods.
                                     # may be empty if name of module is not set.
               ) = @_;

            $module_obj->info(       # handler should return hashref or arrayref with needed data
              $path_params->{uid}
            );                       # in this example we call Users->info, and it's result are implicitly returned
          },

          module  => 'Users',        # name of DB module. it's object will be created and passed to handler as $module_obj. optional.

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
      path        => '/tags/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::get_tags,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/tags/',
      params      => POST_TAGS,
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::post_tags,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/tags/:id/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::get_tags_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/tags/:id/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::put_tags_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/tags/:id/',
      controller  => 'Tags::Api::Admin::Tags',
      endpoint    => \&Tags::Api::Admin::Tags::delete_tags_id,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/tags/:id/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::post_tags_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/tags/:id/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::put_tags_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/tags/:id/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::delete_tags_id_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/tags/users/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::get_tags_users,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::get_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::post_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::put_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PATCH',
      path        => '/tags/users/:uid/',
      controller  => 'Tags::Api::Admin::Users',
      endpoint    => \&Tags::Api::Admin::Users::patch_tags_users_uid,
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
