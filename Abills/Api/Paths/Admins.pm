package Api::Paths::Admins;
=head NAME

  Admins api functions

=cut

use strict;
use warnings FATAL => 'all';

use Admins;

#TODO: contacts get
my Admins $Admins;

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

  $Admins = Admins->new($self->{db}, $self->{conf});

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
      method      => 'POST',
      path        => '/admins/login/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 1000002,
          errstr => 'ERR_AUTH_PASSWORD_LOGIN_DISABLED',
        } if !$self->{conf}->{API_ADMIN_AUTH_LOGIN} || !$self->{conf}->{AUTH_METHOD};

        return {
          errno  => 1000003,
          errstr => 'ERR_NO_LOGIN',
        } if !$query_params->{LOGIN};

        return {
          errno  => 1000004,
          errstr => 'ERR_NO_PASSWORD'
        } if !$query_params->{PASSWORD};

        %main::FORM = ();

        my $status = ::check_permissions($query_params->{LOGIN}, $query_params->{PASSWORD}, 'plug', {
          API       => 1,
          FULL_INFO => 1
        });

        if (!$status) {
          my %params = (
            sid => $self->{admin}->{SID} || '',
          );

          #TODO: delete it as soon as possible
          $params{api_key} = $self->{admin}->{API_KEY} if $self->{conf}->{API_ADMIN_AUTH_LOGIN_RETURN_API_KEY};

          return \%params;
        }
        else {
          return {
            errno  => 10,
            errstr => 'ACCESS_DENIED',
            status => $status
          };
        }
      },
      credentials => [
        'PUBLIC'
      ]
    },
    {
      # TODO: add validation
      method      => 'POST',
      path        => '/admins/:aid/contacts/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        $Admins->admin_contacts_add({
          %$query_params,
          AID => $path_params->{aid},
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      # TODO: add validation
      method      => 'PUT',
      path        => '/admins/:aid/contacts/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        $Admins->admin_contacts_change({
          %$query_params,
          AID => $path_params->{aid}
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/:aid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        $Admins->info($path_params->{aid}, {
          %$query_params
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/admins/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        return {
          errno  => 700,
          errstr => 'No field aLogin'
        } if !$query_params->{A_LOGIN};

        my $admin_regex = $self->{conf}->{ADMINNAMEREGEXP} || '^\S{1,}$';

        return {
          errno  => 701,
          errstr => 'Not valid login admin',
          regexp => "$admin_regex",
        } if $query_params->{A_LOGIN} !~ /$admin_regex/;

        $Admins->{MAIN_AID} = $self->{admin}->{AID};
        $Admins->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

        $Admins->add({
          A_LOGIN          => $query_params->{A_LOGIN},
          A_FIO            => $query_params->{A_FIO} || '',
          PASPORT_GRANT    => $query_params->{PASPORT_GRANT} || '',
          BIRTHDAY         => $query_params->{BIRTHDAY} || '0000-00-00',
          GID              => $query_params->{GID} || 0,
          RFID_NUMBER      => $query_params->{RFID_NUMBER} || '',
          MIN_SEARCH_CHARS => $query_params->{MIN_SEARCH_CHARS} || 0,
          EMAIL            => $query_params->{EMAIL} || '',
          CELL_PHONE       => $query_params->{CELL_PHONE} || '',
          PASPORT_DATE     => $query_params->{PASPORT_DATE} || '0000-00-00',
          GPS_IMEI         => $query_params->{GPS_IMEI} || '',
          ADDRESS          => $query_params->{ADDRESS} || '',
          DOMAIN_ID        => $query_params->{DOMAIN_ID} || 0,
          PASPORT_NUM      => $query_params->{PASPORT_NUM} || '',
          MAX_CREDIT       => $query_params->{MAX_CREDIT} || 0,
          INN              => $query_params->{INN} || '',
          TELEGRAM_ID      => $query_params->{TELEGRAM_ID} || '',
          PHONE            => $query_params->{PHONE} || '',
          COMMENTS         => $query_params->{COMMENTS} || '',
          DISABLE          => $query_params->{DISABLE} || '',
          MAX_ROWS         => $query_params->{MAX_ROWS} || 0,
          ANDROID_ID       => $query_params->{ANDROID_ID} || '',
          EXPIRE           => $query_params->{EXPIRE} || '0000-00-00 00:00:00',
          CREDIT_DAYS      => $query_params->{CREDIT_DAYS} || 0,
          API_KEY          => $query_params->{API_KEY} || '',
          SIP_NUMBER       => $query_params->{SIP_NUMBER} || '',
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/admins/:aid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        if ($query_params->{A_LOGIN}) {
          my $admin_regex = $self->{conf}->{ADMINNAMEREGEXP} || '^\S{1,}$';

          return {
            errno  => 701,
            errstr => 'Not valid login admin',
            regexp => "$admin_regex",
          } if $query_params->{A_LOGIN} !~ /$admin_regex/;
        }

        $Admins->{AID} = $path_params->{aid};
        $Admins->{MAIN_AID} = $self->{admin}->{AID};
        $Admins->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

        $Admins->change({
          AID => $path_params->{aid},
          %$query_params
        });
      },
      credentials => [
        'ADMIN',
        'ADMINSID'
      ]
    },
    {
      method      => 'POST',
      path        => '/admins/:aid/permissions/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        $Admins->{AID} = $path_params->{aid};
        $Admins->{MAIN_AID} = $self->{admin}->{AID};
        $Admins->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

        $Admins->set_permissions($query_params);

        if ($Admins->{errno}) {
          return $Admins;
        }
        else {
          return {
            result => 'Permissions successfully set',
            aid    => $path_params->{aid}
          };
        }
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/settings/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Admins->{AID} = $self->{admin}{AID};
        $Admins->settings_info($query_params->{OBJECT_ID} || '--');
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      # TODO: add validation
      method      => 'POST',
      path        => '/admins/settings/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Admins->{AID} = $self->{admin}{AID};
        $Admins->settings_add({
          %$query_params,
          AID => $self->{admin}{AID},
        });
      },
      credentials => [
        'ADMIN', 'ADMINSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/admins/all/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4}{4};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
        $query_params->{SORT} = $query_params->{SORT} || 1;
        $query_params->{DESC} = $query_params->{DESC} || '';
        $query_params->{PG} = $query_params->{PG} || 0;

        my $admins = $Admins->list({
          %{$query_params},
          COLS_NAME => 1,
        });

        return $admins;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

1;
