package Api::Paths::Users;
=head NAME

  Users api functions

=cut

use strict;
use warnings FATAL => 'all';

use Api::Validations::Contracts qw(POST_USERS_CONTRACTS PUT_USERS_CONTRACTS);
use Abills::Base qw(in_array);

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
    #@deprecated delete in future
    {
      method               => 'POST',
      path                 => '/users/login/',
      handler              => sub {
        require Api::Core::User;
        Api::Core::User->import();
        my $User = Api::Core::User->new($self->{db}, $self->{admin}, $self->{conf});
        return $User->user_login(@_);
      },
      credentials => [
        'PUBLIC'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/all/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{2};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
        $query_params->{SORT} = $query_params->{SORT} || 1;
        $query_params->{DESC} = $query_params->{DESC} || '';
        $query_params->{PG} = $query_params->{PG} || 0;

        my $users = $module_obj->list({
          %{$query_params},
          COLS_NAME => 1,
        });

        if (in_array('Tags', \@main::MODULES) && $query_params->{TAGS}) {
          foreach my $user (@{$users}) {
            my @tags = $user->{tags} ? split('\s?,\s?', $user->{tags}) : ();
            $user->{tags} = \@tags;
          }
        }

        return $users;
      },
      module      => 'Users',
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{0};

        my @allowed_params = (
          'SHOW_PASSWORD'
        );
        my %PARAMS = ();
        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = '_SHOW';
        }

        $module_obj->info($path_params->{uid}, \%PARAMS);
        delete @{$module_obj}{qw/list AFFECTED/};
        return $module_obj;
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $Users = $module_obj;
        $query_params->{SKIP_STATUS_CHANGE} = 1 if (!defined $query_params->{DISABLE});

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        $Users->change($path_params->{uid}, {
          %$query_params
        });

        if (!$Users->{errno}) {
          if ($query_params->{CREDIT} && $query_params->{CREDIT_DATE}) {
            $Users->info($path_params->{uid});
            ::cross_modules('payments_maked', { USER_INFO => $Users, SUM => $query_params->{CREDIT}, SILENT => 1, CREDIT_NOTIFICATION => 1 });
          }

          $Users->pi_change({
            UID => $path_params->{uid},
            %$query_params
          });
        }

        return $Users;
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params, $Users) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{5};

        my @allowed_params = (
          'COMMENTS',
          'DATE',
        );
        my %PARAMS = ();
        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = '_SHOW';
        }

        $Users->del({
          %PARAMS,
          UID => $path_params->{uid}
        });

        if (!$Users->{errno}) {
          return {
            result => "Successfully deleted user with uid $path_params->{uid}",
            uid    => $path_params->{uid},
          };
        }
        else {
          return $Users;
        }
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/pi/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{0};

        $module_obj->pi({ UID => $path_params->{uid} });
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $Users = $module_obj;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{1};

        $Users->add({
          %$query_params
        });

        if (!$Users->{errno}) {
          $Users->pi_add({
            UID => $Users->{UID},
            %$query_params
          });
        }

        return $Users;
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/users/:uid/pi/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{1};

        $module_obj->pi_add({
          %$query_params,
          UID => $path_params->{uid}
        });
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    #@deprecated
    {
      method      => 'PUT',
      path        => '/users/:uid/pi/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        $module_obj->pi_change({
          %$query_params,
          UID => $path_params->{uid}
        });
      },
      module      => 'Users',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/abon/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Abon};

        $module_obj->user_tariff_list($path_params->{uid}, {
          COLS_NAME => 1
        });
      },
      module      => 'Abon',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/internet/all/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
        $query_params->{SORT} = $query_params->{SORT} || 1;
        $query_params->{DESC} = $query_params->{DESC} || '';
        $query_params->{PG} = $query_params->{PG} || 0;

        $query_params->{SIMULTANEONSLY} = $query_params->{LOGINS} if ($query_params->{LOGINS});

        my $users = $module_obj->user_list({
          %{$query_params},
          COLS_NAME => 1,
        });

        if (in_array('Tags', \@main::MODULES) && $query_params->{TAGS}) {
          foreach my $user (@{$users}) {
            my @tags = $user->{tags} ? split('\s?,\s?', $user->{tags}) : ();
            $user->{tags} = \@tags;
          }
        }

        return $users;
      },
      module      => 'Internet',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/internet/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $module_obj->user_list({
          %$query_params,
          UID             => $path_params->{uid},
          CID             => '_SHOW',
          INTERNET_STATUS => '_SHOW',
          TP_NAME         => '_SHOW',
          MONTH_FEE       => '_SHOW',
          DAY_FEE         => '_SHOW',
          TP_ID           => '_SHOW',
          GROUP_BY        => 'internet.id',
          COLS_NAME       => 1
        });
      },
      module      => 'Internet',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/internet/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Internet};

        $module_obj->user_info($path_params->{uid}, {
          %$query_params,
          ID        => $path_params->{id},
          COLS_NAME => 1
        });
      },
      module      => 'Internet',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/contacts/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        $module_obj->contacts_list({
          %$query_params,
          UID => '_SHOW'
        });
      },
      module      => 'Contacts',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/contacts/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{0};

        $module_obj->contacts_list({
          UID       => $path_params->{uid},
          VALUE     => '_SHOW',
          PRIORITY  => '_SHOW',
          TYPE      => '_SHOW',
          TYPE_NAME => '_SHOW',
        });
      },
      module      => 'Contacts',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/:uid/contacts/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{1};

        $module_obj->contacts_add({
          %$query_params,
          UID => $path_params->{uid},
        });
      },
      module      => 'Contacts',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/users/:uid/contacts/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{5};

        $module_obj->contacts_del({
          ID  => $path_params->{id},
          UID => $path_params->{uid}
        });
      },
      module      => 'Contacts',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/users/:uid/contacts/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        $module_obj->contacts_change({
          %$query_params,
          ID  => $path_params->{id},
          UID => $path_params->{uid}
        });
      },
      module      => 'Contacts',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/:uid/iptv/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Iptv};

        $module_obj->user_list({
          %$query_params,
          UID          => $path_params->{uid},
          SERVICE_ID   => '_SHOW',
          TP_FILTER    => '_SHOW',
          MONTH_FEE    => '_SHOW',
          DAY_FEE      => '_SHOW',
          TP_NAME      => '_SHOW',
          SUBSCRIBE_ID => '_SHOW',
          COLS_NAME    => 1
        });
      },
      module      => 'Iptv',
      credentials => [
        'ADMIN'
      ]
    },
    {
      #TODO: :uid is not used
      method      => 'GET',
      path        => '/users/:uid/iptv/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Iptv};

        $module_obj->user_info($path_params->{id}, {
          %$query_params,
          COLS_NAME => 1
        });
      },
      module      => 'Iptv',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/contracts/types/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{0};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        return $Users->contracts_type_list({
          %$query_params,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/users/contracts/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{0};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        my $contracts_list = $Users->contracts_list({
          %$query_params,
        });

        foreach my $contract (@{$contracts_list}) {
          delete $contract->{signature} if (!$query_params->{SIGNATURE});
        }

        return $contracts_list;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/users/contracts/',
      params      => POST_USERS_CONTRACTS,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{1};

        $query_params->{DATE} = $main::DATE if (!$query_params->{DATE});

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        $Users->contracts_add($query_params);

        delete @{$Users}{qw/list TOTAL AFFECTED/};

        return $Users;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/users/contracts/:id/',
      params      => PUT_USERS_CONTRACTS,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        $Users->contracts_change($path_params->{id}, $query_params);

        delete @{$Users}{qw/list TOTAL AFFECTED/};

        return $Users;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/users/contracts/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{4};

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        $Users->contracts_del({ ID => $path_params->{id} });

        if (!$Users->{errno}) {
          if ($Users->{AFFECTED} && $Users->{AFFECTED} =~ /^[0-9]$/) {
            return {
              result => 'Successfully deleted',
              id     => $path_params->{id}
            };
          }
          else {
            return {
              errno       => 10225,
              errstr      => 'ERROR_NOT_EXIST',
              err_message => 'No exists',
            };
          }
        }
        return $Users;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method       => 'GET',
      path         => '/users/contracts/:id/',
      handler      => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{0};

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        ::load_module('Control::Contracts_mng', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Control/Contracts_mng.pm'}));

        my $document = ::_print_user_contract({
          ID            => $path_params->{id},
          USER_OBJ      => $Users,
          pdf           => 1,
          OUTPUT2RETURN => 1
        });

        return $document;
      },
      content_type => 'Content-type: application/pdf',
      credentials  => [
        'ADMIN'
      ]
    },
  ];
}

1;
