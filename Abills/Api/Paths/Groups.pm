package Api::Paths::Groups;
=head NAME

  Groups api functions

=cut

use strict;
use warnings FATAL => 'all';

use Api::Validations::Groups qw(POST_GROUP PUT_GROUP);
use Users;

my Users $Users;

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

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->{debug} = $debug;

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
      path        => '/groups/',
      handler     => sub {
        return $self->groups_list(@_);
      },
      module      => 'Users',
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/groups/:id/',
      handler     => sub {
        return $self->groups_info(@_);
      },
      module      => 'Users',
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/groups/',
      params      => POST_GROUP,
      handler     => sub {
        return $self->groups_add(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'PUT',
      path        => '/groups/:id/',
      params      => PUT_GROUP,
      handler     => sub {
        return $self->groups_chg(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/groups/:id/',
      handler     => sub {
        return $self->groups_del(@_);
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
  ];
}

#**********************************************************
=head2 groups_list($path_params, $query_params) list of groups

=cut
#*********************************************************
sub groups_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28};

  my $groups = $Users->groups_list({
    DOMAIN_ID        => '_SHOW',
    G_NAME           => '_SHOW',
    DISABLE_PAYMENTS => '_SHOW',
    GID              => '_SHOW',
    NAME             => '_SHOW',
    BONUS            => '_SHOW',
    DESCR            => '_SHOW',
    ALLOW_CREDIT     => '_SHOW',
    DISABLE_PAYSYS   => '_SHOW',
    DISABLE_CHG_TP   => '_SHOW',
    USERS_COUNT      => '_SHOW',
    SMS_SERVICE      => '_SHOW',
    DOCUMENTS_ACCESS => '_SHOW',
    DISABLE_ACCESS   => '_SHOW',
    SEPARATE_DOCS    => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  return {
    list  => $groups,
    total => $Users->{TOTAL},
  };
}

#**********************************************************
=head2 groups_info($path_params, $query_params) group info

=cut
#*********************************************************
sub groups_info {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28};

  $Users->group_info($path_params->{id});
  delete @{$Users}{qw/TOTAL list AFFECTED/};

  $Users->{G_NAME} = $Users->{NAME};

  return $Users;
}

#**********************************************************
=head2 groups_add($path_params, $query_params) add group

=cut
#*********************************************************
sub groups_add {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28} || !$self->{admin}->{permissions}{0}{1};

  $Users->group_add($query_params);

  $Users->group_info($query_params->{GID}) if ($Users->{AFFECTED});
  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 groups_chg($path_params, $query_params) change group

=cut
#*********************************************************
sub groups_chg {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{28} || !$self->{admin}->{permissions}{0}{4};

  $Users->group_change($path_params->{id}, $query_params);
  $Users->group_info($path_params->{id});
  delete @{$Users}{qw/TOTAL list AFFECTED/};

  return $Users;
}

#**********************************************************
=head2 groups_del($path_params, $query_params) delete group

=cut
#*********************************************************
sub groups_del {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{39};

  my $groups = $Users->groups_list({ GID => $path_params->{id}, USERS_COUNT => '_SHOW', COLS_NAME => 1 });

  if (!$Users->{TOTAL} || $Users->{errno}) {
    return {
      errno  => 100056,
      errstr => 'NO_DELETE_GROUPS',
    };
  }
  elsif ($Users->{TOTAL} && $Users->{TOTAL} > 0 && $groups->[0]->{users_count}) {
    return {
      errno  => 100057,
      errstr => 'NO_DELETE_GROUPS_USERS_EXISTS',
    };
  }

  $Users->group_del($path_params->{id});

  return $Users if ($Users->{errno});

  return {
    result => 'Successfully deleted',
    gid    => $path_params->{id},
  };
}

1;
