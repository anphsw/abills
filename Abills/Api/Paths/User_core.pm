package Api::Paths::User_core;
=head NAME

  Api::Paths::User_core - User api functions

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Api::Helpers qw(static_string_generate);
use Abills::Base qw(in_array camelize);

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $lang, $debug, $type, $html, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    lang    => $lang,
    debug   => $debug,
    html    => $html,
    libpath => $attr->{libpath} || ''
  };

  bless($self, $class);

  $self->{routes_list} = ();

  if ($type eq 'user') {
    $self->{routes_list} = $self->user_routes();
  }

  return $self;
}

#**********************************************************
=head2 paths() - Returns available API paths

  Returns:
    {
      $resource_1_name => [ # $resource_1_name, $resource_2_name - names of API resources. always equals to first path segment
        {
          method  => 'GET',          # HTTP method. Path can be queried only with this method

          path    => '/users/:uid/', # API path. May contain variables like ':uid'.
                                     # these variables will be passed to handler function as argument ($path_params).
                                     # variables are always numerical.
                                     # example: if route's path is '/users/', and queried URL
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
      method      => 'DELETE',
      path        => '/user/logout/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        $module_obj->web_session_del({ SID => $ENV{HTTP_USERSID} });
        return {
          result => 'Success logout',
        };
      },
      module      => 'Users',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        $module_obj->info($path_params->{uid});

        delete @{$module_obj}{qw{COMPANY_NAME AFFECTED DELETED DISABLE COMPANY_VAT COMPANY_ID COMPANY_CREDIT G_NAME GID TOTAL}};
        delete @{$module_obj}{qw{REDUCTION REDUCTION_DATE}} if ($self->{conf}->{user_hide_reduction});

        if ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL}) {
          $module_obj->registration_pin_info({ UID => $path_params->{uid} });
          if ($module_obj->{errno}) {
            delete @{$module_obj}{qw{errno errstr}};
            $module_obj->{is_verified} = 'true';
          }
          else {
            $module_obj->{is_verified} = $module_obj->{VERIFY_DATE} eq '0000-00-00 00:00:00' ? 'false' : 'true';
          }
        }

        return $module_obj;
      },
      module      => 'Users',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/pi/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Info_fields;
        Info_fields->import();
        my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});

        my $info_fields = $Info_fields->fields_list({
          SQL_FIELD   => '_SHOW',
          ABON_PORTAL => 0,
          COLS_NAME   => 1,
        });

        my @delete_params = (
          'AFFECTED',
          'COMMENTS',
          'CONTACTS_NEW_APPENDED',
          'CONTRACT_SUFFIX',
          'TOTAL',
        );

        foreach my $info_field (@{$info_fields}) {
          push @delete_params, uc($info_field->{sql_field});
        }

        require Users;
        Users->import();
        my $users = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $users->pi({ UID => $path_params->{uid} });

        $users->{ADDRESS_FULL} =~ s/,\s?$// if ($users->{ADDRESS_FULL});
        $users->{ADDRESS_FULL_LOCATION} =~ s/,\s?$// if ($users->{ADDRESS_FULL_LOCATION});

        delete @{$users}{@delete_params};

        return $users;
      },
      module      => 'Users',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'PUT',
      path        => '/user/pi/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10066,
          errstr => 'Unknown operation happened',
        } if (!$self->{conf}->{user_chg_pi});

        my %result = ();

        my %allowed_params = (
          FIO          => 'FIO',
          FIO1         => 'FIO1',
          FIO2         => 'FIO2',
          FIO3         => 'FIO3',
          CELL_PHONE   => 'CELL_PHONE',
          FLOOR        => 'FLOOR',
          DISTRICT_ID  => 'DISTRICT_ID',
          BUILD_ID     => 'BUILD_ID',
          LOCATION_ID  => 'LOCATION_ID',
          STREET_ID    => 'STREET_ID',
          ADDRESS_FLAT => 'ADDRESS_FLAT',
          EMAIL        => 'EMAIL',
          PHONE        => 'PHONE',
        );

        if ($self->{conf}->{CHECK_CHANGE_PI}) {
          %allowed_params = ();
          my @allowed_params = split(',\s?', $self->{conf}->{CHECK_CHANGE_PI});
          foreach my $param (@allowed_params) {
            $allowed_params{$param} = uc $param;
            $allowed_params{$param} =~ s/^_//;
          }
        }
        else {
          if ($self->{conf}->{user_chg_info_fields}) {
            require Info_fields;
            Info_fields->import();

            my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
            my $info_fields = $Info_fields->fields_list({
              SQL_FIELD   => '_SHOW',
              ABON_PORTAL => 1,
              USER_CHG    => 1,
              COLS_NAME   => 1,
            });

            foreach my $info_field (@{$info_fields}) {
              $allowed_params{uc($info_field->{sql_field})} = uc($info_field->{sql_field});
              $allowed_params{uc($info_field->{sql_field})} =~ s/^_//;
            }
          }
        }

        if ($self->{conf}->{user_chg_pi_verification}) {
          require Abills::Sender::Core;
          Abills::Sender::Core->import();
          my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

          if ($query_params->{EMAIL}) {
            my $code = static_string_generate($query_params->{EMAIL}, $path_params->{uid});

            if ($query_params->{EMAIL_CODE} && "$query_params->{EMAIL_CODE}" ne "$code") {
              $result{email_confirm_message} = 'Wrong email code';
              $result{email_confirm_status} = 1;
              delete $allowed_params{EMAIL};
            }
            elsif (!$query_params->{EMAIL_CODE}) {
              delete $allowed_params{EMAIL};

              $Sender->send_message({
                TO_ADDRESS  => $query_params->{EMAIL},
                MESSAGE     => "$self->{lang}->{CODE} $code",
                SUBJECT     => $self->{lang}->{CODE},
                SENDER_TYPE => 'Mail',
                QUITE       => 1,
                UID         => $path_params->{uid},
              });

              $result{email_confirm_status} = 0;
              $result{email_confirm_status} = 'Email send with code send';
            }
          }

          if (in_array('Sms', \@main::MODULES) && $query_params->{PHONE}) {
            my $code = static_string_generate($query_params->{PHONE}, $path_params->{uid});

            if ($query_params->{PHONE_CODE} && "$query_params->{PHONE_CODE}" ne "$code") {
              $result{phone_confirm_message} = 'Wrong phone code';
              $result{email_confirm_status} = 1;
              delete $allowed_params{PHONE};
            }
            elsif (!$query_params->{PHONE_CODE}) {
              delete $allowed_params{PHONE};
              require Sms;
              Sms->import();
              my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

              my $sms_limit = $self->{conf}->{USER_LIMIT_SMS} || 5;

              my $current_mount = POSIX::strftime("%Y-%m-01", localtime(time));
              $Sms->list({
                COLS_NAME => 1,
                DATETIME  => ">=$current_mount",
                UID       => $path_params->{uid},
                NO_SKIP   => 1,
                PAGE_ROWS => 1000
              });

              my $sent_sms = $Sms->{TOTAL} || 0;

              if ($sms_limit <= $sent_sms) {
                $result{phone_confirm_message} = "User sms limit has been reached - $self->{conf}->{USER_LIMIT_SMS} sms";
                $result{email_confirm_status} = 2;
              }
              else {
                $Sender->send_message({
                  TO_ADDRESS  => $query_params->{PHONE},
                  MESSAGE     => "$self->{lang}->{CODE} $code",
                  SENDER_TYPE => 'Sms',
                  UID         => $path_params->{uid},
                });

                $result{email_confirm_status} = 0;
                $result{email_confirm_status} = 'Sms send with code send';
              }
            }
          }
        }

        my %PARAMS = ();
        foreach my $param (keys %allowed_params) {
          next if (!defined $query_params->{$allowed_params{$param}});
          $PARAMS{$param} = $query_params->{$allowed_params{$param}};
        }

        my $users = $module_obj;

        $users->pi({ UID => $path_params->{uid} });

        $users->pi_change({
          UID => $path_params->{uid},
          %PARAMS,
        });

        $result{result} = 'Successfully changed ' . join(', ', map($_ = camelize($_), keys %PARAMS));

        return \%result;
      },
      module      => 'Users',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'POST',
      path        => '/user/credit/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        $module_obj->user_set_credit({
          UID           => $path_params->{uid},
          change_credit => 1,
        });
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/credit/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        $module_obj->user_set_credit({
          UID => $path_params->{uid}
        });
      },
      module      => 'Control::Service_control',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/:id/holdup/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my %params = (
          UID          => $path_params->{uid},
          ACCEPT_RULES => 1,
        );

        $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

        my $result = $module_obj->user_holdup(\%params);

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
      path        => '/user/:id/holdup/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my %params = (
          UID          => $path_params->{uid},
          add          => 1,
          ACCEPT_RULES => 1,
          FROM_DATE    => $query_params->{FROM_DATE},
          TO_DATE      => $query_params->{TO_DATE},
        );

        $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

        my $result = $module_obj->user_holdup(\%params);

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
      method      => 'DELETE',
      path        => '/user/:id/holdup/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my %params = (
          UID => $path_params->{uid},
          del => 1,
        );

        $params{ID} = $path_params->{id} if ($self->{conf}->{INTERNET_USER_SERVICE_HOLDUP});

        my $result = $module_obj->user_holdup(\%params);

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
      method  => 'POST',
      path    => '/user/password/send/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        require Api::Core::User;
        Api::Core::User->import();
        my $User = Api::Core::User->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang}, html => $self->{html} });
        return $User->user_send_password(UID => $path_params->{uid} || '--',);
      },
      credentials => [
        'USER'
      ]
    },
    {
      method  => 'POST',
      path    => '/user/password/recovery/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        require Control::Registration_mng;
        Control::Registration_mng->import();
        my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

        return $Registration_mng->password_recovery($query_params);
      },
    },
    {
      method  => 'POST',
      path    => '/user/resend/verification/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        require Control::Registration_mng;
        Control::Registration_mng->import();
        my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

        return $Registration_mng->resend_pin($query_params);
      },
    },
    {
      method  => 'POST',
      path    => '/user/verify/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        require Control::Registration_mng;
        Control::Registration_mng->import();
        my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

        return $Registration_mng->verify_pin($query_params);
      },
    },
    {
      method      => 'POST',
      path        => '/user/reset/password/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10032,
          errstr => 'Service not available',
        } if (!$self->{conf}->{user_chg_passwd});

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        if ($self->{conf}->{group_chg_passwd}) {
          $Users->info($path_params->{uid});

          return {
            errno  => 10033,
            errstr => 'Service not available',
          } if ("$Users->{GID}" ne "$self->{conf}->{group_chg_passwd}");
        }

        return {
          errno  => 10036,
          errstr => 'No field password',
        } if (!$query_params->{PASSWORD});

        return {
          errno  => 10034,
          errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
        } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

        return {
          errno  => 10035,
          errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
        } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

        $Users->change($path_params->{uid}, {
          PASSWORD => $query_params->{PASSWORD},
          UID      => $path_params->{uid},
        });

        return {
          errno  => 10030,
          errstr => 'Failed to change user password',
        } if ($Users->{errno});

        return {
          result => 'Successfully changed password'
        };
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method  => 'POST',
      path    => '/user/registration/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        require Control::Registration_mng;
        Control::Registration_mng->import();
        my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

        return $Registration_mng->user_registration($query_params);
      },
    },
    {
      method  => 'POST',
      path    => '/user/password/reset/',
      handler => sub {
        my ($path_params, $query_params) = @_;

        require Control::Registration_mng;
        Control::Registration_mng->import();
        my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

        return $Registration_mng->password_reset($query_params);
      },
    },
    {
      method      => 'GET',
      path        => '/user/config/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;
        require Control::Service_control;
        Control::Service_control->import();
        my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

        require Abills::Api::Functions;
        Abills::Api::Functions->import();
        my $Functions = Abills::Api::Functions->new($self->{db}, $self->{admin}, $self->{conf}, {
          modules => \@main::MODULES,
          uid     => $path_params->{uid}
        });

        my $user = $module_obj->list({
          UID        => $path_params->{uid},
          GID        => '_SHOW',
          COMPANY_ID => '_SHOW',
          _GOOGLE    => '_SHOW',
          _FACEBOOK  => '_SHOW',
          _APPLE     => '_SHOW',
          COLS_NAME  => 1,
          COLS_UPPER => 1
        })->[0];

        my %functions = %{$Functions->{functions}};

        if ($functions{internet_user_chg_tp}) {
          my $list = $Service_control->available_tariffs({
            UID    => $path_params->{uid},
            MODULE => 'Internet'
          });

          if (ref $list ne 'ARRAY') {
            delete $functions{internet_user_chg_tp};
          }
          else {
            $functions{internet}{now} = 0 if ($self->{conf}->{INTERNET_USER_CHG_TP_NOW});
            $functions{internet}{next_month} = 1 if ($self->{conf}->{INTERNET_USER_CHG_TP_NEXT_MONTH});
            $functions{internet}{schedule} = 2 if ($self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE});
          }
        }

        if ($self->{conf}->{HOLDUP_ALL} || $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP}) {
          my ($type_holdup, $holdup);

          if ($self->{conf}->{HOLDUP_ALL}) {
            $type_holdup = 'user_holdup_all';
            $holdup = $self->{conf}->{HOLDUP_ALL};
          }
          else {
            $type_holdup = 'internet_user_holdup';
            $holdup = $self->{conf}->{INTERNET_USER_SERVICE_HOLDUP};
          }

          my @holdup_rules = split(/;/, $holdup);
          $functions{holdup} = [];

          foreach my $holdup_rule (@holdup_rules) {
            my ($min_period, $max_period, $holdup_period, $daily_fees, undef, $active_fees, $holdup_skip_gids) = split(/:/, $holdup_rule);

            if ($holdup_skip_gids) {
              my @holdup_skip_gids_arr = split(/,\s?/, $holdup_skip_gids);
              next if ($user->{GID} && in_array($user->{GID}, \@holdup_skip_gids_arr));
            }

            my $holdup_rules = {
              min_period    => $min_period,
              max_period    => $max_period,
              holdup_period => $holdup_period,
              daily_fees    => $daily_fees,
              active_fees   => $active_fees
            };

            if (!$functions{$type_holdup}) {
              $functions{$type_holdup} = {%$holdup_rules};
            }

            push @{$functions{holdup}}, $holdup_rules;
          }
        }

        if ($self->{conf}->{AUTH_GOOGLE_ID}) {
          $functions{social_auth}{google} = (($user->{_GOOGLE} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
        }
        if ($self->{conf}->{AUTH_FACEBOOK_ID}) {
          $functions{social_auth}{facebook} = (($user->{_FACEBOOK} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
        }
        if ($self->{conf}->{AUTH_APPLE_ID}) {
          $functions{social_auth}{apple} = (($user->{_APPLE} || q{}) =~ /(?<=,\s).*/gm) ? 1 : 0;
        }

        my $credit_info = $Service_control->user_set_credit({ UID => $path_params->{uid} });
        if (!exists($credit_info->{error}) && !exists($credit_info->{errno})) {
          $functions{user_credit} = '1001';
        }

        require Conf;
        Conf->import();
        my $Conf = Conf->new($self->{db}, $self->{admin}, $self->{conf});

        my $parameters = $Conf->config_list({
          PARAM     => 'ORGANIZATION_*',
          COLS_NAME => 1,
        });

        foreach my $param (@{$parameters}) {
          next if (!$param->{param} || !$param->{value});
          $functions{organization}{$param->{param}} = $param->{value};
        }

        if (in_array('Iptv', \@main::MODULES)) {
          my ($subscribe_id, $subscribe_name, $subscribe_describe) = split(/:/, $self->{conf}->{IPTV_SUBSCRIBE_ID} || q{});
          $functions{iptv_config}{subscribe}{id} = $subscribe_id || 'EMAIL';
          $functions{iptv_config}{subscribe}{name} = $subscribe_name || 'E-mail';
          $functions{iptv_config}{subscribe}{describe} = $subscribe_describe || '';

          require Iptv;
          Iptv->import();
          my $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
          $Iptv->iptv_promotion_tps();

          $functions{iptv_config}{promotion_tps} = 1 if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0);
        }

        if (in_array('Cards', \@main::MODULES)) {
          $functions{cards_user_payment}{serial} = ($self->{conf}->{CARDS_PIN_ONLY}) ? 0 : 1;
          delete $functions{cards_user_payment} if ($self->{conf}->{CARDS_SKIP_COMPANY} && $user->{COMPANY_ID});
        }

        if ($functions{iptv_user_chg_tp}) {
          $functions{iptv}{next_month} = 1;
          my $list = $Service_control->available_tariffs({
            UID    => $path_params->{uid},
            MODULE => 'Internet'
          });

          if (ref $list ne 'ARRAY') {
            delete $functions{internet_user_chg_tp};
          }
          else {
            $functions{iptv}{next_month} = 1;
            $functions{iptv}{schedule} = 2 if ($self->{conf}->{INTERNET_USER_CHG_TP_SHEDULE} && !$self->{conf}->{IPTV_USER_CHG_TP_NPERIOD});
          }
        }

        $functions{system}{currency} = $self->{conf}->{SYSTEM_CURRENCY} if ($self->{conf}->{SYSTEM_CURRENCY});
        $functions{system}{password}{regex} = $self->{conf}->{PASSWD_SYMBOLS} if ($self->{conf}->{PASSWD_SYMBOLS});
        $functions{system}{password}{symbols} = $self->{conf}->{PASSWD_LENGTH} if ($self->{conf}->{PASSWD_LENGTH});

        $functions{bots}{viber} = "viber://pa?chatURI=$self->{conf}->{VIBER_BOT_NAME}&text=/start&context=u_" if ($self->{conf}->{VIBER_TOKEN} && $self->{conf}->{VIBER_BOT_NAME});
        $functions{bots}{telegram} = "https://t.me/$self->{conf}->{TELEGRAM_BOT_NAME}?start=u_" if ($self->{conf}->{TELEGRAM_TOKEN} && $self->{conf}->{TELEGRAM_BOT_NAME});

        $functions{social_networks} = $self->{conf}->{SOCIAL_NETWORKS} if ($self->{conf}->{SOCIAL_NETWORKS});
        $functions{review_pages} = $self->{conf}->{REVIEW_PAGES} if ($self->{conf}->{REVIEW_PAGES});

        $functions{phone}{pattern} = $self->{conf}->{PHONE_NUMBER_PATTERN} if ($self->{conf}->{PHONE_NUMBER_PATTERN});

        if ($self->{conf}->{user_chg_passwd} || ($self->{conf}->{group_chg_passwd} && $self->{conf}->{group_chg_passwd} eq $user->{GID})) {
          $functions{user_chg_passwd} = 1;
        }

        if ($self->{conf}->{user_chg_pi}) {
          $functions{user_chg_pi} = 1;

          if ($self->{conf}->{CHECK_CHANGE_PI}) {
            $functions{user_chg_pi_allowed_params}{($_ || q{})} = 99 for (split ',\s?', ($self->{conf}->{CHECK_CHANGE_PI}));
          }
          else {
            $functions{user_chg_pi_allowed_params} = {
              fio        => 99,
              cell_phone => 99,
              email      => 99,
              phone      => 99,
            };

            if ($self->{conf}->{user_chg_info_fields}) {
              $functions{user_chg_info_fields_types} = [ 'String', 'Integer', 'List', 'Text', 'Flag' ];
              require Info_fields;
              Info_fields->import();

              my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
              my $info_fields = $Info_fields->fields_list({
                SQL_FIELD   => '_SHOW',
                TYPE        => '_SHOW',
                ABON_PORTAL => 1,
                USER_CHG    => 1,
                COLS_NAME   => 1,
              });

              foreach my $info_field (@{$info_fields}) {
                $functions{user_chg_pi_allowed_params}{uc($info_field->{sql_field})} = $info_field->{type};
              }
            }
          }
        }

        $functions{user_send_password} = 1 if ($self->{conf}->{USER_SEND_PASSWORD});

        return \%functions;
      },
      module      => 'Users',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method               => 'DELETE',
      path                 => '/user/social/networks/',
      handler              => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $changed_field = '--';

        if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{GOOGLE}) {
          $changed_field = '_GOOGLE';
        }
        elsif ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{FACEBOOK}) {
          $changed_field = '_FACEBOOK';
        }
        elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{APPLE}) {
          $changed_field = '_APPLE';
        }
        else {
          return {
            errno  => 11004,
            errstr => 'Unknown social network'
          };
        }

        $module_obj->pi_change({ UID => $path_params->{uid}, $changed_field => '' });

        return {
          result => 'success'
        };
      },
      module               => 'Users',
      credentials          => [
        'USER'
      ]
    },
    {
      method               => 'POST',
      path                 => '/user/social/networks/',
      handler              => sub {
        my ($path_params, $query_params) = @_;

        %main::FORM = ();
        if ($self->{conf}->{AUTH_GOOGLE_ID} && $query_params->{GOOGLE}) {
          $main::FORM{token} = $query_params->{GOOGLE};
          $main::FORM{external_auth} = 'Google';
          $main::FORM{API} = 1;
        }
        elsif ($self->{conf}->{AUTH_FACEBOOK_ID} && $query_params->{FACEBOOK}) {
          $main::FORM{token} = $query_params->{FACEBOOK};
          $main::FORM{external_auth} = 'Facebook';
          $main::FORM{API} = 1;
        }
        elsif ($self->{conf}->{AUTH_APPLE_ID} && $query_params->{APPLE}) {
          $main::FORM{token} = $query_params->{APPLE};
          $main::FORM{external_auth} = 'Apple';
          $main::FORM{API} = 1;
          $main::FORM{NONCE} = $query_params->{NONCE} if ($query_params->{NONCE});
        }
        else {
          return {
            errno  => 11002,
            errstr => 'Unknown social network or no token'
          }
        }

        my ($uid, $sid, $login) = ::auth_user('', '', $ENV{HTTP_USERSID}, { API => 1 });

        if (ref $uid eq 'HASH') {
          return $uid;
        }

        if (!$uid) {
          return {
            errno  => 11003,
            errstr => 'Failed to set social network token. Unknown token'
          };
        }

        return {
          result => 'success'
        };
      },
      credentials          => [
        'USER'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/services/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        ::load_module('Control::Services', { LOAD_PACKAGE => 1 });

        my $services = ::get_user_services({
          uid         => $path_params->{uid},
          active_only => $query_params->{ACTIVE_ONLY} ? 1 : 0
        });

        return $services;
      },
      credentials => [
        'USER', 'USERBOT', 'USERSID'
      ]
    },
    {
      method      => 'GET',
      path        => '/user/recommendedPay/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        require Users;
        Users->import();
        my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

        $Users->info($path_params->{uid});

        my $sum = ::recomended_pay($Users);
        my $min_sum = $self->{conf}->{PAYSYS_MIN_SUM} || 0;

        if ($self->{conf}->{PAYSYS_MIN_SUM_RECOMMENDED_PAY} && $sum > $min_sum) {
          $min_sum = $sum;
        }

        my $all_services_fee = ::recomended_pay($Users, { SKIP_DEPOSIT_CHECK => 1 });

        return {
          sum              => $sum,
          all_services_sum => $all_services_fee,
          max_sum          => $self->{conf}->{PAYSYS_MAX_SUM} || 0,
          min_sum          => $min_sum,
        };
      },
      credentials => [
        'USER', 'USERBOT'
      ]
    },
    {
      method               => 'POST',
      path                 => '/user/login/',
      handler              => sub {
        require Api::Core::User;
        Api::Core::User->import();
        my $User = Api::Core::User->new($self->{db}, $self->{admin}, $self->{conf}, {
          lang    => $self->{lang},
          html    => $self->{html},
          libpath => $self->{libpath}
        });
        return $User->user_login(@_);
      },
      credentials => [
        'PUBLIC'
      ]
    },
    {
      #TODO: remove when will be deprecated /users/login
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
  ];
}

1;
