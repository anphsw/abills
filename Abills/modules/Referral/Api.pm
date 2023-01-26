package Referral::Api;
=head NAME

  Referral::Api - Referral api functions

=head VERSION

  DATE: 20220109
  UPDATE: 20220109
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Referral;
use Referral::Users;

my Referral $Referral;
my Referral::Users $Referral_users;

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

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  $Referral = Referral->new($self->{db}, $self->{admin}, $self->{conf});
  $Referral_users = Referral::Users->new($db, $admin, $conf, {
    html        => $html,
    lang        => $lang,
  });

  return $self;
}

#**********************************************************
=head2 user_routes() - Returns available API paths

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
sub user_routes {
  my $self = shift;

  return [
    {
      method      => 'GET',
      path        => '/user/referral/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Referral_users->user_referrals({ UID => $path_params->{uid} });
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/referral/bonus/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my $result = $Referral_users->user_get_bonus({ UID => $path_params->{uid} });
        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/referral/friend/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        $query_params->{UID} = $path_params->{uid};
        $query_params->{add} = 1;

        my $result = $Referral_users->user_referral_manage($query_params);
        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/referral/friend/:id/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        $query_params->{UID} = $path_params->{uid};
        $query_params->{ID} = $path_params->{id};
        $query_params->{change} = 1;

        my $result = $Referral_users->user_referral_manage($query_params);
        delete @{$result}{qw/object fatal element/};
        return $result;
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

1;
