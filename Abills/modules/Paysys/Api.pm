package Paysys::Api;
=head NAME

  Paysys::Api - Paysys api functions

=head VERSION

  DATE: 20211227
  UPDATE: 20220524
  VERSION: 0.05

=cut

use strict;
use warnings FATAL => 'all';

use Paysys;
use Paysys::Init;
use Abills::Base qw(mk_unique_value);

our %lang;
require 'Abills/modules/Paysys/lng_english.pl';

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $conf, $admin, $lang, $debug) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $lang,
    debug => $debug
  };

  bless($self, $class);

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
sub routes_list {
  my $self = shift;
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  $Paysys->{debug} = $self->{debug};

  return [
    {
      method      => 'GET',
      path        => '/user/:uid/paysys/systems/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        my $users_info = $Users->list({
          GID       => '_SHOW',
          UID       => $path_params->{uid},
          COLS_NAME => 1,
        });

        my $allowed_systems = $Paysys->groups_settings_list({
          GID       => $users_info->[0]->{gid},
          PAYSYS_ID => '_SHOW',
          COLS_NAME => 1,
        });

        my $systems = $Paysys->paysys_connect_system_list({
          NAME      => '_SHOW',
          MODULE    => '_SHOW',
          ID        => '_SHOW',
          PAYSYS_ID => '_SHOW',
          STATUS    => 1,
          COLS_NAME => 1,
        });

        if (!$users_info->[0]->{gid}) {
          my $gid_list = $Users->groups_list({
            COLS_NAME      => 1,
            GID            => '0'
          });

          if (!$gid_list) {
            $allowed_systems = $systems;
          }
        }

        my @systems_list;
        foreach my $allowed_system (@{$allowed_systems}) {
          foreach my $system (@{$systems}) {
            next if ($system->{paysys_id} != $allowed_system->{paysys_id});
            my $Module = _configure_load_payment_module($system->{module}, 1);
            next if (ref $Module eq 'HASH' || !$Module->can('fast_pay_link'));
            push(@systems_list, $system);
          }
        }

        return \@systems_list || [];
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',                                  #TODO: GET
      path        => '/user/:uid/paysys/transaction/status/', #TODO :id/
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $Paysys->list({
          TRANSACTION_ID => $query_params->{TRANSACTION_ID} || '--',
          UID            => $path_params->{uid},
          STATUS         => '_SHOW',
          DOMAIN_ID      => '_SHOW',
          COLS_NAME      => 1,
          SORT           => 1
        });
      },
      credentials => [
        'USER'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/:uid/paysys/pay/',
      handler     => sub {
        my ($path_params, $query_params) = @_;
        my $sum = $query_params->{SUM} || 0;
        my $operation_id = $query_params->{OPERATION_ID} || '';

        if (!defined $query_params->{SYSTEM_ID}) {
          return {
            errno  => '601',
            errstr => 'No value: systemId'
          }
        }
        if (!$sum) {
          require Users;
          Users->import();
          my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

          my $users_info = $Users->list({
            DEPOSIT   => '_SHOW',
            UID       => $path_params->{uid},
            COLS_NAME => 1,
          });

          my $deposit = abs(sprintf("%.2f", $users_info->[0]->{deposit}));
          $sum = ($users_info->[0]->{deposit} > 0) ? 1 : $deposit;
        }
        if (!$operation_id) {
          $operation_id = mk_unique_value(9, { SYMBOLS => '0123456789' }),
        }

        my $paysys = $Paysys->paysys_connect_system_list({
          SHOW_ALL_COLUMNS => 1,
          STATUS           => 1,
          COLS_NAME        => 1,
          ID               => $query_params->{SYSTEM_ID} || '--'
        });

        if ($paysys == []) {
          return [];
        }
        else {
          return $self->paysys_link({
            UID          => $path_params->{uid},
            SUM          => $sum,
            OPERATION_ID => $operation_id,
            MODULE       => $paysys,
          })
        }
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

#**********************************************************
=head2 paysys_link($attr) function for call fast_pay_link in Paysys modules

  Arguments:
    $attr
      UID           - uid of user
      SUM           - amount of sum payment
      OPERATION_ID  - ID of transaction
      MODULE        - Paysys module

  Result:
    fastpay url or Errno

=cut
#**********************************************************
sub paysys_link {
  my $self = shift;
  my ($attr) = @_;
  my %LANG = (%{$self->{lang}}, %lang);
  my $Module = _configure_load_payment_module($attr->{MODULE}->[0]->{module}, 1);

  if (ref $Module eq 'HASH') {
    return $Module;
  }

  if ($Module->can('fast_pay_link')) {
    my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    return $Paysys_plugin->fast_pay_link({
      SUM          => $attr->{SUM},
      OPERATION_ID => $attr->{OPERATION_ID},
      USER         => $Users->info($attr->{UID}),
    });
  }
  else {
    return {
      errno  => '610',
      errstr => 'No fast pay link for this module'
    };
  }
}

1;
