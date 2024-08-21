package Api::Paths::Global;
=head NAME

  Global api functions

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type, $html) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug,
    html  => $html
  };

  bless($self, $class);

  $self->{routes_list} = ();

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
      method               => 'POST',
      path                 => '/global/',
      handler              => sub {
        my ($path_params, $query_params) = @_;

        my DBI $db = $self->{db}->{db};
        $db->{AutoCommit} = 0;
        $self->{db}->{TRANSACTION} = 1;

        if (!$query_params->{REQUESTS} || ref $query_params->{REQUESTS} ne 'ARRAY') {
          return {
            errno  => 10154,
            errstr => 'No field requests',
          };
        }

        my %results = (
          result  => 'OK',
          results => [],
        );

        my $id = -1;
        my %new_user;

        require Abills::Api::Handle;
        Abills::Api::Handle->import();
        my $handle = Abills::Api::Handle->new($self->{db}, $self->{admin}, $self->{conf}, {
          html           => $self->{html},
          lang           => $self->{lang},
          direct         => 1
        });

        foreach my $request (@{$query_params->{REQUESTS}}) {
          ++$id;

          if ($id == 20) {
            push @{$results{results}}, {
              url        => $request->{URL} || '',
              response   => {},
              successful => 'false',
              errno      => 10155,
              errstr     => 'Fatal error, not executed. Limit of execution equals 20',
              id         => $id,
            };
            last;
          }

          # handling routes for new user registration
          if (%new_user && $request->{URL} =~ /{UID}/) {
            $request->{URL} =~ s/{UID}/$results{uid}/;

            # handle params sent like "billId": "{BILL_ID}"
            if ($request->{BODY} && ref $request->{BODY} eq 'HASH') {
              foreach my $key (keys %{$request->{BODY}}) {
                if ($request->{BODY}->{$key} && $request->{BODY}->{$key} =~ /((?<=\{)[a-zA-z0-9_]+(?=\}))/g) {
                  my $value = $1 || '';
                  my $new_value = $new_user{$value} || '';
                  $request->{BODY}->{$key} =~ s/{$value}/$new_value/g;
                }
              }
            }
          }

          if ($results{errno}) {
            push @{$results{results}}, {
              url        => $request->{URL} || '',
              response   => {},
              successful => 'false',
              errno      => 10149,
              errstr     => 'Fatal error, not executed',
              id         => $id,
            };
            next;
          }

          # verify url and method valid or not
          if (!$request->{URL} || ref $request->{URL} ne '' || !$request->{METHOD} || ref $request->{METHOD} ne '') {
            $results{result} = 'Not valid method or url parameter';
            $results{errno} = 10150;
            push @{$results{results}}, {
              url        => $request->{URL},
              response   => {},
              successful => 'false',
              errno      => 10150,
              errstr     => 'Not valid method or url parameter',
              id         => $id,
            };
            next;
          }

          my ($result, $status) = $handle->api_call({
            PATH   => $request->{URL},
            METHOD => $request->{METHOD},
            PARAMS => $request->{BODY},
          });

          # catch error if it present
          if ($result && ref $result eq 'HASH' && ($result->{errno} || $result->{error})) {
            $results{result} = 'Execution failed';
            $results{errno} = $result->{errno} || $result->{error};
            push @{$results{results}}, {
              url        => $request->{URL},
              response   => $result,
              successful => 'false',
              id         => $id,
            };
            next;
          }

          # handle user registration
          if ($request->{METHOD} eq 'POST' && $request->{URL} eq '/users/') {
            $results{uid} = $result->{UID};
            require Users;
            Users->import();
            my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
            $Users->info($results{uid});
            $Users->pi({ UID => $results{uid} });
            %new_user = %$Users;
          }

          push @{$results{results}}, {
            response   => $result || '',
            status     => $status || 200,
            url        => $request->{URL},
            method     => $request->{METHOD},
            successful => 'true',
            id         => $id,
          };
        }

        if ($results{errno}) {
          $db->rollback();
        }
        else {
          $db->commit();
        }

        $db->{AutoCommit} = 1;

        return \%results;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
