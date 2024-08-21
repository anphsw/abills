package Api::Paths::Districts;
=head NAME

  Districts api functions

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);
use Address;

my Address $Address;

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

  $Address = Address->new(@{$self}{qw/db admin conf/});

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admins_routes();
  }

  return $self;
}

#**********************************************************
=head2 admins_routes() - Returns available API paths

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
sub admins_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/districts/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        # return {
        #   errno  => 10,
        #   errstr => 'Access denied'
        # } if !$self->{admin}->{permissions}{0}{35};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $Address->district_list({
          %$query_params,
          COLS_NAME => 1,
        });
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/districts/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{40};

        return {
          errno  => 10094,
          errstr => 'No field name'
        } if (!$query_params->{NAME});

        $Address->district_add({
          %$query_params
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/districts/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{40};

        $Address->district_info({ ID => $path_params->{id} });

        my $child_districts = $Address->district_list({
          PARENT_ID => $Address->{ID},
          TYPE_ID   => '_SHOW',
          TYPE_NAME => '_SHOW',
          FULL_NAME => '_SHOW',
          COLS_NAME => 1,
          PAGE_ROWS => 100000
        });

        if ($child_districts && !scalar @{$child_districts}) {
          my $streets = $Address->street_list({
            DISTRICT_ID => $Address->{ID},
            STREET_NAME => '_SHOW',
            SECOND_NAME => '_SHOW',
            COLS_NAME   => 1,
            PAGE_ROWS   => 100000
          });

          $Address->{STREETS} = $streets;
        }
        else {
          $Address->{CHILD_DISTRICTS} = $child_districts;
        }

        delete @{$Address}{qw/list AFFECTED TOTAL/};
        return $Address;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/districts/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{40};

        $Address->district_change({
          %$query_params,
          ID => $path_params->{id}
        });

        return $Address if ($Address->{errno});

        $Address->district_info({ ID => $path_params->{id}, });

        delete @{$Address}{qw/list/};
        return $Address;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
