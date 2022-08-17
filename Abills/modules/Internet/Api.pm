package Internet::Api;
=head1 NAME

  Equipment::Api - Equipment api functions

=head VERSION

  DATE: 20220711
  UPDATE: 20220711
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);
do 'Abills/Misc.pm';
our $DATE = strftime "%Y-%m-%d", localtime(time);

require Abills::Misc;

our (
  $db,
  $admin,
  %conf,
  %permissions
);

use Internet;
my Internet $Internet;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $Db, $conf, $Admin, $lang, $debug, $type, $additional_params) = @_;

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

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'admin') {
    $self->{routes_list} = $self->admin_routes();
  }

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet->{debug} = $self->{debug};
  %permissions = %{$additional_params->{permissions} || {}};

  require Abills::Misc;
  require Internet::Users;

  return $self;
}

#**********************************************************
=head2 routes_list() - Returns available API paths

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
      method      => 'POST',
      path        => '/internet/:uid/activate/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 100,
          errstr => 'No field tpId'
        } if !$query_params->{TP_ID};

        return {
          errno  => 101,
          errstr => 'No field status'
        } if !defined $query_params->{STATUS};

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $Users->pi({ UID => $path_params->{uid} });

        #TODO: fix with option $conf{MSG_REGREQUEST_STATUS}=1;
        internet_user_add({
          API              => 1,

          UID              => $path_params->{uid},
          TP_ID            => $query_params->{TP_ID},
          STATUS           => $query_params->{STATUS} || 0,
          USERS_INFO       => $Users,

          CID              => $query_params->{CID},
          IP               => $query_params->{IP} || '0.0.0.0',
          PERSONAL_TP      => $query_params->{PERSONAL_TP} || 0,
          SERVICE_EXPIRE   => $query_params->{SERVICE_EXPIRE} || '0000-00-00',
          SERVICE_ACTIVATE => $query_params->{SERVICE_ACTIVATE} || '0000-00-00',

          PORT             => $query_params->{PORT} || '',
          COMMENTS         => $query_params->{COMMENTS} || '',
          STATIC_IP_POOL   => $query_params->{STATIC_IP_POOL} || '',
          STATUS_DAYS      => $query_params->{STATUS_DAYS} || '',
          NAS_ID           => $query_params->{NAS_ID} || '',
          NAS_ID1          => $query_params->{NAS_ID1} || '',
          CPE_MAC          => $query_params->{CPE_MAC} || '',
          SERVER_VLAN      => $query_params->{SERVER_VLAN} || '',
          VLAN             => $query_params->{VLAN} || '',

          #IPV6
          IPV6_MASK        => $query_params->{IPV6_MASK} || 32,
          IPV6             => $query_params->{IPV6} || '',
          IPV6_PREFIX      => $query_params->{IPV6_PREFIX} || '',
          IPV6_PREFIX_MASK => $query_params->{IPV6_PREFIX_MASK} || 32,
          STATIC_IPV6_POOL => $query_params->{STATIC_IPV6_POOL} || '0',
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      path        => '/internet/:uid/activate/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 102,
          errstr => 'No field id'
        } if !$query_params->{ID};

        return {
          errno  => 103,
          errstr => 'No field status'
        } if !defined $query_params->{STATUS};

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $Users->pi({ UID => $path_params->{uid} });

        #TODO: fix with option $conf{MSG_REGREQUEST_STATUS}=1;
          internet_user_change({
            API              => 1,

            UID              => $path_params->{uid},
            ID               => $query_params->{ID},
            STATUS           => $query_params->{STATUS} || 0,
            USERS_INFO       => $Users,

            CID              => $query_params->{CID},
            IP               => $query_params->{IP} || '0.0.0.0',
            PERSONAL_TP      => $query_params->{PERSONAL_TP} || '0',
            SERVICE_EXPIRE   => $query_params->{SERVICE_EXPIRE} || '0000-00-00',
            SERVICE_ACTIVATE => $query_params->{SERVICE_ACTIVATE} || '0000-00-00',

            PORT             => $query_params->{PORT} || '',
            COMMENTS         => $query_params->{COMMENTS} || '',
            STATIC_IP_POOL   => $query_params->{STATIC_IP_POOL} || '',
            STATUS_DAYS      => $query_params->{STATUS_DAYS} || '',
            NAS_ID           => $query_params->{NAS_ID} || '',
            NAS_ID1          => $query_params->{NAS_ID1} || '',
            CPE_MAC          => $query_params->{CPE_MAC} || '',
            SERVER_VLAN      => $query_params->{SERVER_VLAN} || '',
            VLAN             => $query_params->{VLAN} || '',

            #IPV6
            IPV6_MASK        => $query_params->{IPV6_MASK} || 32,
            IPV6             => $query_params->{IPV6} || '',
            IPV6_PREFIX      => $query_params->{IPV6_PREFIX} || '',
            IPV6_PREFIX_MASK => $query_params->{IPV6_PREFIX_MASK} || 32,
            STATIC_IPV6_POOL => $query_params->{STATIC_IPV6_POOL} || '0',
          });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/internet/:uid/:id/warnings/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Control::Service_control;
        Control::Service_control->import();
        my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

        $Service_control->service_warning({
          UID    => $path_params->{uid},
          ID     => $path_params->{id},
          MODULE => 'Internet'
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
  ]
}

1;
