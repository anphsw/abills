package Internet::Api;
=head1 NAME

  Internet::Api - Internet api functions

=head VERSION

  DATE: 20220711
  UPDATE: 20220711
  VERSION: 0.01

=cut

use strict;
use warnings FATAL => 'all';

use Internet::Validations qw(POST_INTERNET_MAC_DISCOVERY POST_INTERNET_HANGUP POST_INTERNET_TARIFF PUT_INTERNET_TARIFF POST_INTERNET_USER PUT_INTERNET_USER);
use Abills::Base qw(json_former mk_unique_value in_array);

use Internet::Services;
use Internet;

my Internet $Internet;
my Internet::Services $Internet_services;

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
    $self->{routes_list} = $self->admin_routes();
  }
  elsif ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet->{debug} = $self->{debug};
  $Internet_services = Internet::Services->new($db, $admin, $conf, {
    lang        => $self->{lang},
  });

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
      params      => POST_INTERNET_USER,
      path        => '/internet/:uid/activate/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{18};

        # make empty before call not isolated function
        %main::FORM = ();

        ::load_module('Internet::Users', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Internet/Users.pm'}));
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $Users->pi({ UID => $path_params->{uid} });

        ::internet_user_add({
          %$query_params,
          API        => 1,
          UID        => $path_params->{uid},
          USERS_INFO => $Users,
        });
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'PUT',
      params      => PUT_INTERNET_USER,
      path        => '/internet/:uid/activate/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{0}{18};

        # make empty before call not isolated function
        %main::FORM = ();

        ::load_module('Internet::Users', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Internet/Users.pm'}));
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $Users->pi({ UID => $path_params->{uid} });

        ::internet_user_change({
          %$query_params,
          API        => 1,
          UID        => $path_params->{uid},
          USERS_INFO => $Users,
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
    {
      method      => 'POST',
      path        => '/internet/:uid/session/hangup/',
      params      => POST_INTERNET_HANGUP,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{5};

        ::load_module('Internet::Monitoring', { LOAD_PACKAGE => 1 });
        ::_internet_hangup({ %$query_params, UID => $path_params->{uid} });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'GET',
      path        => '/internet/tariffs/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{4};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $query_params->{ACTIV_PRICE} = $query_params->{ACTIVATE_PRICE} if ($query_params->{ACTIVATE_PRICE});

        if ($query_params->{TP_ID}) {
          $query_params->{INNER_TP_ID} = $query_params->{TP_ID};
          delete $query_params->{TP_ID};
        }
        $query_params->{TP_ID} = $query_params->{ID} if ($query_params->{ID});

        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        $Tariffs->list({
          %$query_params,
          MODULE       => 'Internet',
          COLS_NAME    => 1,
        });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'POST',
      path        => '/internet/tariff/',
      params      => POST_INTERNET_TARIFF,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $query_params = $self->tariff_add_preprocess($query_params);
        return $query_params if ($query_params->{errno});

        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        return $Tariffs->add({ %{$query_params}, MODULE => 'Internet' });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'PUT',
      path        => '/internet/tariff/:tpId/',
      params      => PUT_INTERNET_TARIFF,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        $query_params = $self->tariff_add_preprocess($query_params);
        return $query_params if ($query_params->{errno});

        require Tariffs;
        Tariffs->import();
        my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

        return $Tariffs->change(($path_params->{tpId} || '--'), {
          %{$query_params},
          MODULE => 'Internet',
          TP_ID  => $path_params->{tpId}
        });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'DELETE',
      path        => '/internet/tariff/:tpId/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Shedule;
        Shedule->import();
        my $Schedule = Shedule->new($self->{db}, $self->{conf}, $self->{admin});

        my $users_list = $Internet->user_list({
          TP_ID     => $path_params->{tpId},
          UID       => '_SHOW',
          COLS_NAME => 1
        });

        my $schedules = $Schedule->list({
          ACTION    => "*:$path_params->{tpId}",
          TYPE      => 'tp',
          MODULE    => 'Internet',
          COLS_NAME => 1,
        });

        if (($Internet->{TOTAL} && $Internet->{TOTAL} > 0) || ($Schedule->{TOTAL} && $Schedule->{TOTAL} > 0)) {
          my %users_msg = ();
          foreach my $user_tp (@{$users_list}) {
            $users_msg{active}{message} = 'List of users who currently have an active tariff plan';
            push @{$users_msg{active}{users}}, $user_tp->{uid};
          }

          foreach my $schedule (@{$schedules}) {
            $users_msg{schedule}{message} = 'List of users who have scheduled a change in their tariff plan';
            push @{$users_msg{schedule}{users}}, $schedule->{uid};
          }

          return {
            errno  => 102005,
            errstr => "Can not delete tariff plan with tpId $path_params->{tpId}",
            users  => \%users_msg,
          };
        }
        else {
          require Tariffs;
          Tariffs->import();
          my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
          $Tariffs->del($path_params->{tpId});

          if (!$Tariffs->{errno}) {
            if ($Tariffs->{AFFECTED} && $Tariffs->{AFFECTED} =~ /^[0-9]$/) {
              return {
                result => 'Successfully deleted',
              };
            }
            else {
              return {
                errno  => 102006,
                errstr => "No tariff plan with tpId $path_params->{tpId}",
                tpId   => $path_params->{tpId},
              };
            }
          }

          return $Tariffs;
        }
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'PUT',
      path        => '/internet/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        # clear global form
        %main::FORM = ();

        return $Internet_services->internet_user_chg_tp({
          %$query_params,
          UID => $path_params->{uid},
        });
      },
      credentials => [
        'ADMIN'
      ],
    },
    {
      method      => 'GET',
      path        => '/internet/sessions/:uid/',
      handler     => sub {
        require Internet::Api::admin::Sessions;
        my $Sessions = Internet::Api::admin::Sessions->new($self->{db}, $self->{admin}, $self->{conf});

        return $Sessions->get_sessions_uid(@_);
      },
      credentials => [
        'ADMIN'
      ],
    },
  ];
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
      method      => 'POST',
      path        => '/user/internet/:id/activate/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;
        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        my $user_info = $Users->info($path_params->{uid});

        $module_obj->user_info($path_params->{uid}, {
          ID        => $path_params->{id},
          DOMAIN_ID => $user_info->{DOMAIN_ID}
        });

        return {
          result => 'Already active'
        } if (defined $module_obj->{STATUS} && $module_obj->{STATUS} == 0);
        return {
          errno  => 200,
          errstr => 'Can\'t activate, not allowed'
        } unless (
          $module_obj->{STATUS} &&
            ($module_obj->{STATUS} == 2 || $module_obj->{STATUS} == 5 ||
              ($module_obj->{STATUS} == 3 && $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP})));

        if ($module_obj->{STATUS} == 3) {
          require Control::Service_control;
          Control::Service_control->import();
          my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});
          my $del_result = $Service_control->user_holdup({ del => 1, UID => $path_params->{uid}, ID => $path_params->{id} });
          return $del_result;
        }

        return {
          errno  => 201,
          errstr => 'Can\'t activate, not enough money'
        } if ($module_obj->{MONTH_ABON} != 0 && $module_obj->{MONTH_ABON} >= $user_info->{DEPOSIT});

        $module_obj->user_change({
          UID      => $path_params->{uid},
          ID       => $path_params->{id},
          STATUS   => 0,
          ACTIVATE => ($self->{conf}->{INTERNET_USER_ACTIVATE_DATE}) ? strftime("%Y-%m-%d", localtime(time)) : undef
        });

        if (!$module_obj->{errno}) {
          if (!$module_obj->{STATUS}) {
            ::service_get_month_fee($module_obj);
          }

          return {
            result => 'OK. Success activation'
          }
        }
        else {
          return {
            errno  => $module_obj->{errno},
            errstr => $module_obj->{errstr} || "",
          }
        }
      },
      module      => 'Internet',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
        return ::get_user_services({
          uid     => $path_params->{uid},
          service => 'Internet',
        });
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/session/active/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $sessions = $module_obj->online({
          CLIENT_IP          => '_SHOW',
          CID                => '_SHOW',
          DURATION_SEC2      => '_SHOW',
          ACCT_INPUT_OCTETS  => '_SHOW',
          ACCT_OUTPUT_OCTETS => '_SHOW',
          UID                => $path_params->{uid}
        });

        my @result = ();

        foreach my $session (@{$sessions}) {
          push @result, {
            duration => $session->{duration_sec2},
            cid      => $session->{cid},
            input    => $session->{acct_input_octets},
            output   => $session->{acct_output_octets},
            ip       => $session->{client_ip}
          }
        }

        return \@result;
      },
      module      => 'Internet::Sessions',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/sessions/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $sessions = $module_obj->list({
          UID          => $path_params->{uid},
          TP_NAME      => '_SHOW',
          TP_ID        => '_SHOW',
          IP           => '_SHOW',
          SENT         => '_SHOW',
          RECV         => '_SHOW',
          DURATION_SEC => '_SHOW',
          PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
          COLS_NAME    => 1
        });

        my @result = ();

        foreach my $session (@{$sessions}) {
          push @result, {
            duration => $session->{duration_sec},
            input    => $session->{recv},
            output   => $session->{sent},
            ip       => $session->{ip},
            tp_name  => $session->{tp_name},
            tp_id    => $session->{tp_id},
          }
        }

        return \@result;
      },
      module      => 'Internet::Sessions',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    #@deprecated
    {
      method  => 'POST',
      path    => '/user/internet/registration/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10091,
          errstr => 'Service not available',
        } if ($self->{conf}->{NEW_REGISTRATION_FORM});

        return {
          errno  => 10011,
          errstr => 'Service not available',
        } if (!in_array('Internet', \@main::MODULES) || !in_array('Internet', \@main::REGISTRATION));

        return {
          errno  => 10040,
          errstr => 'Service not available',
        } if ($self->{conf}->{REGISTRATION_PORTAL_SKIP});

        return {
          errno  => 10012,
          errstr => 'Invalid login',
        } if (!$query_params->{LOGIN});

        return {
          errno  => 10013,
          errstr => 'Invalid email',
        } if (!$query_params->{EMAIL} || $query_params->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/);

        return {
          errno  => 10014,
          errstr => 'Invalid phone',
        } if (!$query_params->{PHONE} || ($self->{conf}->{PHONE_FORMAT} && $query_params->{PHONE} !~ m/$self->{conf}->{PHONE_FORMAT}/));

        my $password = q{};

        if ($self->{conf}->{REGISTRATION_PASSWORD}) {
          return {
            errno  => 10037,
            errstr => 'No field password',
          } if (!$query_params->{PASSWORD});

          return {
            errno  => 10038,
            errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
          } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

          return {
            errno  => 10039,
            errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
          } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

          $password = $query_params->{PASSWORD};
        }

        #TODO: add a street GET PATH and validate it if enabled $conf{INTERNET_REGISTRATION_ADDRESS}
        #TODO: add referral

        if (!$password) {
          $password = mk_unique_value($self->{conf}->{PASSWD_LENGTH}, { SYMBOLS => $self->{conf}->{PASSWD_SYMBOLS} });
        }

        my $cid = q{};

        if ($self->{conf}->{INTERNET_REGISTRATION_IP}) {
          return {
            errno  => 10015,
            errstr => 'Invalid ip',
          } if (!$query_params->{USER_IP} || $query_params->{USER_IP} eq '0.0.0.0');

          require Internet::Sessions;
          Internet::Sessions->import();

          my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
          $Sessions->online({
            CLIENT_IP => $query_params->{USER_IP},
            CID       => '_SHOW',
            GUEST     => 1,
            COLS_NAME => 1
          });

          if ($Sessions->{TOTAL}) {
            $cid = $Sessions->{list}->[0]->{cid};
          }

          return {
            errno  => 10016,
            errstr => 'IP address and MAC was not found',
          } if (!$cid);
        }

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        $Users->add({
          LOGIN       => $query_params->{LOGIN},
          CREATE_BILL => 1,
          PASSWORD    => $password,
          GID         => $self->{conf}->{REGISTRATION_GID},
          PREFIX      => $self->{conf}->{REGISTRATION_PREFIX},
        });

        if ($Users->{errno}) {
          return {
            errno  => 10023,
            errstr => 'Invalid login of user',
          } if ($Users->{errno} eq 10);

          return {
            errno  => 10024,
            errstr => 'User already exist',
          } if ($Users->{errno} eq 7);

          return {
            errno  => 10018,
            errstr => 'Error occurred during creation of user',
          };
        }

        my $uid = $Users->{UID};
        $Users->info($uid);

        $Users->pi_add({
          UID   => $uid,
          FIO   => $query_params->{FIO},
          EMAIL => $query_params->{EMAIL},
          PHONE => $query_params->{PHONE}
        });

        if ($Users->{errno}) {
          $Users->del({
            UID => $uid,
          });

          return {
            errno  => 10019,
            errstr => 'Error occurred during add pi info of user',
          };
        }

        if ($query_params->{TP_ID}) {
          require Tariffs;
          Tariffs->import();
          my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

          my $tp_list = $Tariffs->list({
            MODULE       => 'Internet',
            TP_ID        => $query_params->{TP_ID},
            TP_GID       => '_SHOW',
            NEW_MODEL_TP => 1,
            COLS_NAME    => 1,
            STATUS       => '0',
          });

          if ($tp_list && scalar @{$tp_list} < 1) {
            $Users->del({
              UID => $uid,
            });

            return {
              errno  => 10020,
              errstr => 'No tariff plan with this tpId',
            };
          }
          elsif ($self->{conf}->{INTERNET_REGISTRATION_TP_GIDS} && !in_array($tp_list->{tp_gid}, $self->{conf}->{INTERNET_REGISTRATION_TP_GIDS})) {
            $Users->del({
              UID => $uid,
            });

            return {
              errno  => 10021,
              errstr => 'Not available tariff plan',
            };
          }
        }

        $Internet->user_add({
          UID    => $uid,
          TP_ID  => $query_params->{TP_ID} || $self->{conf}->{REGISTRATION_DEFAULT_TP} || 0,
          STATUS => 2,
          CID    => $cid
        });

        if ($query_params->{REGISTRATION_TAG} && $self->{conf}->{AUTH_ROUTE_TAG} && in_array('Tags', \@main::MODULES)) {
          require Tags;
          Tags->import();

          my $Tags = Tags->new($self->{db}, $self->{conf}, $self->{admin});
          $Tags->tags_user_change({
            IDS => $self->{conf}->{AUTH_ROUTE_TAG},
            UID => $uid,
          });
        }

        if ($Internet->{errno}) {
          $Users->del({
            UID => $uid,
          });

          return {
            errno  => 10022,
            errstr => 'Failed create Internet service',
          };
        }

        my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
        my $addr = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}/index.cgi" : '';

        ::load_module("Abills::Templates", { LOAD_PACKAGE => 1 });
        my $message = $self->{html}->tpl_show(::_include('internet_reg_complete_sms', 'Internet'), {
          %$Internet, %$query_params,
          PASSWORD => "$password",
          BILL_URL => $addr
        }, { OUTPUT2RETURN => 1 });

        require Abills::Sender::Core;
        Abills::Sender::Core->import();
        my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

        if (in_array('Sms', \@main::MODULES) && $self->{conf}->{INTERNET_REGISTRATION_SEND_SMS}) {
          $Sender->send_message({
            TO_ADDRESS  => $query_params->{PHONE},
            MESSAGE     => $message,
            SENDER_TYPE => 'Sms',
            UID         => $uid
          });
        }
        else {
          $Sender->send_message({
            TO_ADDRESS   => $query_params->{EMAIL},
            MESSAGE      => $message,
            SUBJECT      => $self->{lang}->{REGISTRATION},
            SENDER_TYPE  => 'Mail',
            QUITE        => 1,
            CONTENT_TYPE => $self->{conf}->{REGISTRATION_MAIL_CONTENT_TYPE} ? $self->{conf}->{REGISTRATION_MAIL_CONTENT_TYPE} : '',
          });
        }

        my %result = (
          result => "Successfully created user with uid: $uid",
        );

        $result{redirect_url} = $self->{conf}->{REGISTRATION_REDIRECT} if ($self->{conf}->{REGISTRATION_REDIRECT});
        $result{password} = $password if ($self->{conf}->{REGISTRATION_SHOW_PASSWD});

        return \%result;
      },
    },
    {
      method      => 'GET',
      path        => '/user/internet/tariffs/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $result = $module_obj->available_tariffs({
          SKIP_NOT_AVAILABLE_TARIFFS => 1,
          UID                        => $path_params->{uid},
          MODULE                     => 'Internet'
        });

        return {
          errno  => $result->{errno} || $result->{error},
          errstr => $result->{errstr}
        } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

        return $result;
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/tariffs/all/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $result = $module_obj->available_tariffs({
          UID    => $path_params->{uid},
          MODULE => 'Internet'
        });

        return {
          errno  => $result->{errno} || $result->{error},
          errstr => $result->{errstr}
        } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

        return $result;
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/internet/:id/warnings/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        $module_obj->service_warning({
          UID    => $path_params->{uid},
          ID     => $path_params->{id},
          MODULE => 'Internet'
        });
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/internet/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $result = $module_obj->user_chg_tp({
          %$query_params,
          UID    => $path_params->{uid},
          ID     => $path_params->{id}, #ID from internet main
          MODULE => 'Internet'
        });

        return {
          errno  => $result->{errno} || $result->{error},
          errstr => $result->{errstr}
        } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

        delete $result->{RESULT};
        $result->{result} = 'Successfully changed';

        return $result;
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/user/internet/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $result = $module_obj->del_user_chg_shedule({
          UID        => $path_params->{uid},
          SHEDULE_ID => $path_params->{id}
        });

        return {
          errno  => $result->{errno} || $result->{error},
          errstr => $result->{errstr}
        } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

        return $result;
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/internet/mac/discovery/',
      params      => POST_INTERNET_MAC_DISCOVERY,
      handler     => sub {
        my ($path_params, $query_params) = @_;

        return {
          errno  => 10124,
          errstr => 'Service not available',
        } if (!$self->{conf}->{INTERNET_MAC_DICOVERY});

        $Internet->user_list({ UID => $path_params->{uid}, ID => $query_params->{ID}, COLS_NAME => 1 });

        return {
          errno  => 10125,
          errstr => "Not found service with id $query_params->{ID}",
        } if (!$Internet->{TOTAL});

        delete $Internet->{TOTAL};
        $Internet->user_list({ CID => $query_params->{CID} });

        return {
          errno  => 10126,
          errstr => 'This mac address already set for another user',
          cid    => $query_params->{CID},
        } if ($Internet->{TOTAL});

        $Internet->user_change({
          ID  => $query_params->{ID},
          UID => $path_params->{uid},
          CID => $query_params->{CID}
        });

        ::load_module('Internet::User_portal', { LOAD_PACKAGE => 1 });

        ::internet_hangup({
          CID   => $query_params->{CID},
          GUEST => 1,
        });

        return {
          result => 'Hangup is done',
        };
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ];
}

#**********************************************************
=head2 new($, $admin, $CONF)

  Arguments:
    $query_params: object - hash of query params from request

  Returns:
    updated $query_params

=cut
#**********************************************************
sub tariff_add_preprocess {
  my $self = shift;
  my ($query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4};

  $query_params->{SIMULTANEOUSLY} = $query_params->{SIMULTANEOUSLY} if ($query_params->{LOGINS});
  $query_params->{ALERT} = $query_params->{UPLIMIT} if ($query_params->{UPLIMIT});
  $query_params->{ACTIV_PRICE} = $query_params->{ACTIVATE_PRICE} if ($query_params->{ACTIVATE_PRICE});
  $query_params->{NEXT_TARIF_PLAN} = $query_params->{NEXT_TP_ID} if ($query_params->{NEXT_TP_ID});

  if ($query_params->{CREATE_FEES_TYPE}) {
    require Fees;
    Fees->import();
    my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
    $Fees->fees_type_add({ NAME => $query_params->{NAME}});
    $query_params->{FEES_METHOD} = $Fees->{INSERT_ID};
  }

  if ($query_params->{RAD_PAIRS}) {
    require Abills::Radius_Pairs;
    Abills::Radius_Pairs->import();
    $query_params->{RAD_PAIRS} = Abills::Radius_Pairs::parse_radius_params_json(json_former($query_params->{RAD_PAIRS}));
  }

  if ($query_params->{PERIOD_ALIGNMENT} || $query_params->{ABON_DISTRIBUTION} || $query_params->{FIXED_FEES_DAY}) {
    my $period = $query_params->{PERIOD_ALIGNMENT} ? $query_params->{PERIOD_ALIGNMENT} > 0 : 0;
    my $distribution = $query_params->{ABON_DISTRIBUTION} ? $query_params->{ABON_DISTRIBUTION} > 0 : 0;
    my $fixed = $query_params->{FIXED_FEES_DAY} ? $query_params->{FIXED_FEES_DAY} > 0 : 0;
    return {
      errno  => 102007,
      errstr => "Can not use params periodAlignment, abonDistribution and fixedFeesDay",
    } if (($period + $distribution + $fixed) > 1);
  }

  return $query_params;
}

1;
