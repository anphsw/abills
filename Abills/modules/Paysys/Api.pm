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

my Paysys $Paysys;
our %lang;
require 'Abills/modules/Paysys/lng_english.pl';

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

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});
  $Paysys->{debug} = $self->{debug};

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
          SORT      => 'priority',
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
        my %LANG = (%{$self->{lang}}, %lang);
        foreach my $system (@{$systems}) {
          foreach my $allowed_system (@{$allowed_systems}) {
            next if ($system->{paysys_id} != $allowed_system->{paysys_id});
            my $Module = _configure_load_payment_module($system->{module}, 1);
            next if ($query_params->{GPAY} && (ref $Module eq 'HASH' || !$Module->can('google_pay')));
            next if (!$query_params->{GPAY} && (ref $Module eq 'HASH' || !$Module->can('fast_pay_link')));
            delete @{$system}{qw/status/};

            my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });
            my %settings = $Module->get_settings();
            $system->{request} = $settings{REQUEST} if (%settings && $settings{REQUEST});

            if ($query_params->{REQUEST_METHOD} && $system->{request} && $system->{request}->{METHOD}) {
              next if ("$query_params->{REQUEST_METHOD}" ne $system->{request}->{METHOD});
            }

            if ($system->{module} && $system->{module} eq 'GooglePay.pm') {
              next if ($query_params->{REQUEST_METHOD});
              my $config = $Paysys_plugin->get_config($users_info->[0]->{gid});
              $system->{google_config} = $config;
            }
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
          COLS_NAME      => 1,
          SORT           => 1
        })->[0] || {};
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
          my %pay_params = (
            UID          => $path_params->{uid},
            SUM          => $sum,
            OPERATION_ID => $operation_id,
            MODULE       => $paysys,
            RETURN_URL   => defined $query_params->{RETURN_URL},
          );
          if ($query_params->{GPAY}) {
            return $self->paysys_pay({
              GPAY         => $query_params->{GPAY},
              %pay_params
            });
          }
          else {
            return $self->paysys_pay(\%pay_params);
          }
        }
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ]
}

#**********************************************************
=head2 paysys_pay($attr) function for call fast_pay_link in Paysys modules

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
sub paysys_pay {
  my $self = shift;
  my ($attr) = @_;
  my %LANG = (%{$self->{lang}}, %lang);
  my $Module = _configure_load_payment_module($attr->{MODULE}->[0]->{module}, 1);

  if (ref $Module eq 'HASH') {
    return $Module;
  }

  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  if ($Module->can('google_pay') && $attr->{GPAY}) {
    my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });
    return $Paysys_plugin->google_pay({
      USER         => $Users->info($attr->{UID}),
      %$attr
    });
  }
  elsif ($Module->can('fast_pay_link')) {
    my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });
    return $Paysys_plugin->fast_pay_link({
      USER         => $Users->info($attr->{UID}),
      %$attr
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
