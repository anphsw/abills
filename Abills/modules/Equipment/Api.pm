package Equipment::Api;
=head1 NAME

  Equipment::Api - Equipment api functions

=head VERSION

  DATE: 20220210
  UPDATE: 20220911
  VERSION: 0.05

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(cmd);
use Equipment;
use Nas;
require Equipment::Ports;

our (
  $db,
  $admin,
  %conf
);

my Equipment $Equipment;
my Nas $Nas;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $Db, $Admin, $conf, $lang, $debug, $type) = @_;

  my $self = {
    db    => $Db,
    admin => $Admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  $db = $self->{db};
  $admin = $self->{admin};
  %conf = %{$self->{conf}};

  $self->{routes_list} = ();

  bless($self, $class);

  $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  $Nas = Nas->new($self->{db}, $self->{conf}, $self->{admin});

  $Equipment->{debug} = $self->{debug} || 0;
  $Nas->{debug} = $self->{debug} || 0;

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
      path        => '/equipment/onu/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        return _get_onu_list($path_params, $query_params);
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/onu/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        return _get_onu_list($path_params, $query_params, { ONE => 1 });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/box/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        $Equipment->equipment_box_list({
          %PARAMS,
          COLS_NAME => 1,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/used/ports/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @allowed_params = (
          'NAS_ID',
          'GET_MAC',
          'FULL_LIST',
          'PORTS_ONLY'
        );

        my %PARAMS = (
          COLS_UPPER => 1
        );
        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = $query_params->{$param};
        }

        equipments_get_used_ports({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/types/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        require Control::Nas_mng;
        my $types = nas_types_list() || {};
        my @types_list = ();

        foreach my $type (sort keys %{$types}) {
          push @types_list, {
            name => $types->{$type} || '',
            id   => $type || ''
          };
        }

        return \@types_list;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/list/extra/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @allowed_params = (
          'TYPE',
          'NAS_NAME',
          'SYSTEM_ID',
          'TYPE_ID',
          'VENDOR_ID',
          'NAS_TYPE',
          'MODEL_NAME',
          'SNMP_TPL',
          'MODEL_ID',
          'VENDOR_NAME',
          'STATUS',
          'DISABLE',
          'TYPE_NAME',
          'PORTS',
          'PORTS_WITH_EXTRA',
          'MAC',
          'PORT_SHIFT',
          'AUTO_PORT_SHIFT',
          'FDB_USES_PORT_NUMBER_INDEX',
          'EPON_SUPPORTED_ONUS',
          'GPON_SUPPORTED_ONUS',
          'GEPON_SUPPORTED_ONUS',
          'DEFAULT_ONU_REG_TEMPLATE_EPON',
          'DEFAULT_ONU_REG_TEMPLATE_GPON',
          'NAS_IP',
          'NAS_MNG_HOST_PORT',
          'NAS_MNG_USER',
          'NAS_MNG_USER',
          'NAS_MNG_PASSWORD',
          'NAS_ID',
          'NAS_GID',
          'NAS_GROUP_NAME',
          'DISTRICT_ID',
          'STREET_ID',
          'LOCATION_ID',
          'DOMAIN_ID',
          'DOMAIN_NAME',
          'COORDX',
          'COORDY',
          'REVISION',
          'SNMP_VERSION',
          'SERVER_VLAN',
          'LAST_ACTIVITY',
          'INTERNET_VLAN',
          'TR_069_VLAN',
          'IPTV_VLAN',
          'NAS_DESCR',
          'NAS_IDENTIFIER',
          'NAS_ALIVE',
          'NAS_RAD_PAIRS',
          'NAS_ENTRANCE',
          'ZABBIX_HOSTID',
        );

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = $query_params->{$param} || '_SHOW';
        }

        $Equipment->_list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @allowed_params = (
          'NAS_ID',
          'NAS_NAME',
          'NAS_IDENTIFIER',
          'NAS_IP',
          'NAS_TYPE',
          'DISABLE',
          'DESCR',
          'NAS_GROUP_NAME',
          'ALIVE',
          'DOMAIN_ID',
          'MAC',
          'GID',
          'DISTRICT_ID',
          'LOCATION_ID',
          'NAS_MNG_HOST_PORT',
          'NAS_MNG_IP_PORT',
          'NAS_MNG_USER',
          'NAS_MNG_USER',
          'NAS_MNG_PASSWORD',
          'NAS_RAD_PAIRS',
          'NAS_IDS',
          'NAS_FLOOR',
          'NAS_ENTRANCE',
          'ADDRESS_FULL',
          'ZABBIX_HOSTID',
          'SHORT',
        );

        my %PARAMS = (
          COLS_NAME => 1,
          SHORT     => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $param = 'MNG_HOST_PORT' if ($param eq 'NAS_MNG_IP_PORT');
          $PARAMS{$param} = $query_params->{$param} || '_SHOW';
        }

        $Nas->list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200201,
          errstr => 'No field ip'
        } if !$query_params->{IP};

        return {
          errno  => 200202,
          errstr => 'No field nasName'
        } if !$query_params->{NAS_NAME};

        return {
          errno  => 200203,
          errstr => 'No field nas_type'
        } if !defined $query_params->{NAS_TYPE};

        my $result = $Nas->add($query_params);

        if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
          cmd($conf{RESTART_RADIUS});
        }

        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $result = $Nas->del($path_params->{id});

        if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
          cmd($conf{RESTART_RADIUS});
        }

        return ($result->{nas_deleted} eq 1) ? 1 : 0;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200204,
          errstr => 'No field nasId'
        } if !$path_params->{id};

        return {
          errno  => 200205,
          errstr => 'No field ip'
        } if !$query_params->{IP};

        return {
          errno  => 200206,
          errstr => 'No field nasName'
        } if !$query_params->{NAS_NAME};

        return {
          errno  => 200207,
          errstr => 'No field nasType'
        } if !defined $query_params->{NAS_TYPE};

        my $result = $Nas->change({ NAS_ID => $path_params->{id}, %$query_params });

        if ($conf{RESTART_RADIUS} && $conf{RESTART_RADIUS_API}) {
          cmd($conf{RESTART_RADIUS});
        }

        return $result;
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/groups/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        $Nas->nas_group_list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/groups/add/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Nas->nas_group_add({
          NAME     => $query_params->{NAME} || '',
          COMMENTS => $query_params->{COMMENTS} || '',
          DISABLE  => $query_params->{DISABLE} ? 1 : undef,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/equipment/nas/groups/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Nas->nas_group_change({
          ID       => $path_params->{id} || '--',
          NAME     => $query_params->{NAME} || '',
          COMMENTS => $query_params->{COMMENTS} || '',
          DISABLE  => $query_params->{DISABLE} ? 1 : undef,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/groups/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Nas->nas_group_del($path_params->{id});
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/equipment/nas/ip/pools/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @allowed_params = (
          'ID',
          'NAS_NAME',
          'POOL_NAME',
          'FIRST_IP',
          'LAST_IP',
          'IP',
          'LAST_IP_NUM',
          'IP_COUNT',
          'IP_FREE',
          'INTERNET_IP_FREE',
          'PRIORITY',
          'SPEED',
          'NAME',
          'NAS',
          'NETMASK',
          'GATEWAY',
          'STATIC',
          'ACTIVE_NAS_ID',
          'IP_SKIP',
          'COMMENTS',
          'DNS',
          'VLAN',
          'GUEST',
          'NEXT_POOL',
          'STATIC',
          'NAS_ID',
          'SHOW_ALL_COLUMNS'
        );

        if ($self->{conf}->{IPV6}) {
          push @allowed_params,
            'IPV6_PREFIX',
            'IPV6_MASK',
            'IPV6_TEMP',
            'IPV6_PD',
            'IPV6_PD_MASK',
            'IPV6_PD_TEMP';
        }

        my %PARAMS = (
          COLS_NAME => 1,
          PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
          PG        => $query_params->{PG} ? $query_params->{PG} : 0,
        );

        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = $query_params->{$param} || '_SHOW';
        }

        $Nas->nas_ip_pools_list({
          %PARAMS
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/equipment/nas/ip/pools/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 200208,
          errstr => 'No field poolId'
        } if !$query_params->{POOL_ID};

        return {
          errno  => 200209,
          errstr => 'No field nasId'
        } if !$query_params->{NAS_ID};

        $Nas->nas_ip_pools_add({
          NAS_ID  => $query_params->{NAS_ID},
          POOL_ID => $query_params->{POOL_ID},
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/equipment/nas/ip/pools/:nasId/:poolId/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Nas->nas_ip_pools_del({
          NAS_ID  => $path_params->{nasId},
          POOL_ID => $path_params->{poolId}
        });
        return 1;
      },
      credentials => [
        'ADMIN'
      ]
    },
  ]
}

#**********************************************************
=head2 _get_onu_list($path_params, $query_params, $attr)

  Arguments:
    $path_params: object  - hash of params from request path
    $query_params: object - hash of query params from request
    $attr: object         - params of function example
      ONE: boolean - returns one onu with $path_params value {id}

  Returns:
    optional
      array or object

=cut
#**********************************************************
sub _get_onu_list {
  my ($path_params, $query_params, $attr) = @_;

  $query_params->{ONU_VLAN} = $query_params->{VLAN} if ($query_params->{VLAN});
  $query_params->{DATETIME} = $query_params->{DATE_TIME} if ($query_params->{DATE_TIME});

  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
  $query_params->{SORT} = $query_params->{SORT} || 1;
  $query_params->{PG} = $query_params->{PG} || 0;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{ID} = ($attr && $attr->{ONE}) ? ($path_params->{id} || 0) : ($query_params->{ID} || 0);

  my $list = $Equipment->onu_list({
    %{$query_params},
    COLS_NAME => 1,
  });

  if ($attr && $attr->{ONE}) {
    return $list->[0] if (scalar @{$list});

    return {
      errno  => 200210,
      errstr => 'Unknown onu'
    };
  }
  else {
    return $list;
  }
}

1;
