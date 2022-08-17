package Equipment::Api;
=head1 NAME

  Equipment::Api - Equipment api functions

=head VERSION

  DATE: 20220210
  UPDATE: 20220711
  VERSION: 0.02

=cut

use strict;
use warnings FATAL => 'all';

use Equipment;
require Equipment::Ports;

our (
  $db,
  $admin,
  %conf
);

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $Db, $conf, $Admin, $lang, $debug, $type) = @_;

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

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  bless($self, $class);

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
  my $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  $Equipment->{debug} = $self->{debug} || 0;

  return [
    {
      method      => 'GET',
      path        => '/equipment/onu/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my @allowed_params = (
          'BRANCH',
          'BRANCH_DESC',
          'VLAN_ID',
          'ONU_ID',
          'ONU_VLAN',
          'ONU_DESC',
          'ONU_BILLING_DESC',
          'OLT_RX_POWER',
          'ONU_DHCP_PORT',
          'ONU_GRAPH',
          'NAS_IP',
          'ONU_SNMP_ID',
          'DATETIME',
          'DELETED',
          'SERVER_VLAN',
          'GID',
          'TRAFFIC',
          'LOGIN',
          'USER_MAC',
          'MAC_BEHIND_ONU',
          'DISTANCE',
          'EXTERNAL_SYSTEM_LINK'
        );

        my %PARAMS = (
          SORT => (defined($query_params->{SORT}) ? $query_params->{SORT} : 5)
        );
        foreach my $param (@allowed_params) {
          next if (!defined($query_params->{$param}));
          $PARAMS{$param} = '_SHOW';
        }

        $Equipment->onu_list({
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
      path        => '/equipment/box/list/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %PARAMS = (
          PAGE_ROWS => (defined($query_params->{PAGE_ROWS}) ? $query_params->{PAGE_ROWS} : 100000),
          SORT      => (defined($query_params->{SORT}) ? $query_params->{SORT} : 1)
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
  ]
}

1;
