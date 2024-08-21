package Api::Paths::Payments;
=head NAME

  Payments api functions

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);

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
    $self->{routes_list} = $self->admins_routes();
  }
  elsif ($type eq 'user') {
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
      method      => 'GET',
      path        => '/user/payments/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $payments = $module_obj->list({
          UID       => $path_params->{uid},
          DSC       => '_SHOW',
          SUM       => '_SHOW',
          DATETIME  => '_SHOW',
          EXT_ID    => '_SHOW',
          PAGE_ROWS => ($query_params->{PAGE_ROWS} || 10000),
          COLS_NAME => 1
        });

        foreach my $payment (@$payments) {
          delete @{$payment}{qw/inner_describe/};
        }

        return $payments;
      },
      module      => 'Payments',
      credentials => [
        'USER', 'USERBOT'
      ]
    },
  ];
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
      path        => '/payments/types/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{1}{3};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $module_obj->payment_type_list({
          %$query_params,
          COLS_NAME => 1
        });
      },
      module      => 'Payments',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/payments/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;
        return $self->_payments_user($path_params, $query_params, $module_obj);
      },
      module      => 'Payments',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/payments/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;
        return $self->_payments_user($path_params, $query_params, $module_obj);
      },
      module      => 'Payments',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/payments/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params) = @_;

        my %extra_results = ();

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if (!$self->{admin}->{permissions}{1}{1} && !$self->{admin}->{permissions}{1}{3});

        return {
          errno  => 10067,
          errstr => 'Wrong param sum, it\'s empty or must be bigger than zero',
        } if (!$query_params->{SUM} || $query_params->{SUM} !~ /[0-9\.]+/ || $query_params->{SUM} <= 0);

        my $max_payment = $self->{conf}->{MAX_ADMIN_PAYMENT} || 99999999;
        return {
          errno  => 10068,
          errstr => "Payment sum is bigger than allowed - $query_params->{SUM} > $max_payment",
        } if ($query_params->{SUM} > $max_payment);

        my $Users = $path_params->{user_object};
        require Bills;
        Bills->import();
        my $Bills = Bills->new($self->{db}, $self->{admin}, $self->{conf});
        $query_params->{BILL_ID} //= '--';

        if ($Users->{COMPANY_ID}) {
          $Bills->list({
            COMPANY_ID => $Users->{COMPANY_ID},
            BILL_ID    => $query_params->{BILL_ID},
            COLS_NAME  => 1,
          });
        }
        else {
          $Bills->list({
            UID       => $path_params->{uid},
            BILL_ID   => $query_params->{BILL_ID},
            COLS_NAME => 1,
          });
        }

        return {
          errno  => 10069,
          errstr => "User not found with uid - $path_params->{uid} and billId - $query_params->{BILL_ID}",
        } if (!$Bills->{TOTAL});

        my $payment_method = $query_params->{METHOD} || '0';
        delete $query_params->{METHOD};

        require Payments;
        Payments->import();
        my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

        my $allowed_payments = $Payments->admin_payment_type_list({
          COLS_NAME => 1,
          AID       => $self->{admin}->{AID},
        });

        my @allowed_payments_ids = map {$_->{payments_type_id}} @{$allowed_payments};

        if ($payment_method !~ /[0-9]+/) {
          my $payment_methods = $Payments->payment_type_list({
            COLS_NAME       => 1,
            FEES_TYPE       => '_SHOW',
            SORT            => 'id',
            DEFAULT_PAYMENT => 1,
            IDS             => scalar @allowed_payments_ids ? \@allowed_payments_ids : undef,
          });

          if ($path_params) {
            $payment_method = $payment_methods->[0]->{id};
          }
          else {
            $payment_method = 0;
          }
        }
        else {
          if (@allowed_payments_ids && !in_array($payment_method, \@allowed_payments_ids)) {
            return {
              errno  => 10070,
              errstr => 'Payment method is not allowed',
            };
          }
        }

        my $transaction = $self->{db}->{TRANSACTION} || 0;

        $Payments->{db}->{TRANSACTION} = 1;
        my $db_ = $Payments->{db}->{db};
        $db_->{AutoCommit} = 0;

        if ($query_params->{CREATE_RECEIPT} && in_array('Docs', \@main::MODULES)) {
          $query_params->{INVOICE_ID} = 'create';
          $query_params->{CREATE_RECEIPT} //= 1;
          $query_params->{APPLY_TO_INVOICE} //= 1;

          $main::LIST_PARAMS{UID} = $path_params->{uid};
          $main::users = $Users;
          ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 });
        }

        if ($query_params->{EXCHANGE_ID}) {
          if ($query_params->{DATE}) {
            my $list = $Payments->exchange_log_list({
              DATE      => "<=$query_params->{DATE}",
              ID        => $query_params->{EXCHANGE_ID},
              SORT      => 'date',
              DESC      => 'desc',
              PAGE_ROWS => 1,
              COLS_NAME => 1,
            });
            $query_params->{ER_ID} = $query_params->{EXCHANGE_ID};
            $query_params->{ER} = $list->[0]->{rate} || 1;
            $query_params->{CURRENCY} = $list->[0]->{iso} || 0;
            $extra_results{currency}{name} = $list->[0]->{money} || q{};
          }
          else {
            my $er = $Payments->exchange_info($query_params->{EXCHANGE_ID});
            $query_params->{ER_ID} = $query_params->{EXCHANGE_ID};
            $query_params->{ER} = $er->{ER_RATE};
            $query_params->{CURRENCY} = $er->{ISO};
            $extra_results{currency}{name} = $er->{ER_NAME};
          }
          $extra_results{currency}{iso} = $query_params->{CURRENCY};

          $extra_results{currency} = "exchangeId $query_params->{EXCHANGE_ID} not found" if (!$extra_results{currency}{iso} && !$query_params->{ER});
        }

        $query_params->{CURRENCY} = $self->{conf}->{SYSTEM_CURRENCY} if (!$query_params->{CURRENCY} && $self->{conf}->{SYSTEM_CURRENCY});

        $query_params->{DESCRIBE} //= '';
        $query_params->{METHOD} = $payment_method;
        %main::FORM = %$query_params;

        ::cross_modules('pre_payment', {
          USER_INFO    => $Users,
          SKIP_MODULES => 'Sqlcmd',
          SUM          => $query_params->{SUM},
          AMOUNT       => $query_params->{SUM},
          EXT_ID       => $query_params->{EXT_ID} || q{},
          METHOD       => $payment_method,
          FORM         => { %main::FORM },
        });

        $Payments->add({ UID => $path_params->{uid} }, {
          %$query_params,
          UID => $path_params->{uid},
        });

        if ($Payments->{errno}) {
          if (!$transaction) {
            $db_->rollback();
            $db_->{AutoCommit} = 1;
            delete($Payments->{db}->{TRANSACTION});
          }
          return {
            errno  => 10071,
            errstr => "Payments error - $Payments->{errno}, errstr - $Payments->{errno}",
          };
        }
        else {
          if (in_array('Employees', \@main::MODULES) && $query_params->{CASHBOX_ID}) {
            require Employees;
            Employees->import();
            my $Employees = Employees->new($self->{db}, $self->{admin}, $self->{conf});

            my $coming_type = $Employees->employees_list_coming_type({ COLS_NAME => 1 });

            my $id_type;
            foreach my $key (@$coming_type) {
              if ($key->{default_coming} == 1) {
                $id_type = $key->{id};
              }
            }

            $Employees->employees_add_coming({
              DATE           => $main::DATE,
              AMOUNT         => $query_params->{SUM},
              CASHBOX_ID     => $query_params->{CASHBOX_ID},
              COMING_TYPE_ID => $id_type,
              COMMENTS       => $query_params->{DESCRIBE},
              AID            => $self->{admin}->{AID},
              UID            => $path_params->{uid},
            });

            if ($Employees->{errno}) {
              $extra_results{employees}{errno} = $Employees->{errno};
              $extra_results{employees}{errstr} = $Employees->{errstr};
            }
            else {
              $extra_results{employees}{result} = 'OK';
              $extra_results{employees}{insert_id} = $Employees->{INSERT_ID};
            }
          }

          ::cross_modules('payments_maked', {
            USER_INFO    => $Users,
            METHOD       => $payment_method,
            SUM          => $query_params->{SUM},
            AMOUNT       => $query_params->{SUM},
            PAYMENT_ID   => $Payments->{PAYMENT_ID},
            EXT_ID       => $query_params->{EXT_ID} || q{},
            SKIP_MODULES => 'Sqlcmd',
            FORM         => { %main::FORM },
          });

          if (!$transaction) {
            $db_->commit();
            $db_->{AutoCommit} = 1;
            delete($Payments->{db}->{TRANSACTION});
          }

          return {
            insert_id  => $Payments->{INSERT_ID},
            payment_id => $Payments->{INSERT_ID},
            uid        => $path_params->{uid},
            %extra_results
          };
        }
      },
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/payments/users/:uid/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if (!$self->{admin}->{permissions}{1}{2} && !$self->{admin}->{permissions}{1}{3});

        $module_obj->list({
          UID => $path_params->{uid},
          ID  => $path_params->{id},
        });

        if (!$module_obj->{TOTAL}) {
          return {
            errno  => 10122,
            errstr => "Payment with id $path_params->{id} and uid $path_params->{uid} does not exist"
          };
        }

        my $comments = $query_params->{COMMENTS} || 'Deleted from API request';
        my $payment_info = $module_obj->list({
          ID         => $path_params->{id},
          UID        => '_SHOW',
          DATETIME   => '_SHOW',
          SUM        => '_SHOW',
          DESCRIBE   => '_SHOW',
          EXT_ID     => '_SHOW',
          COLS_NAME  => 1,
          COLS_UPPER => 1,
        });
        $module_obj->del($path_params->{user_object}, $path_params->{id}, { COMMENTS => $comments });

        if ($module_obj->{AFFECTED}) {
          ::cross_modules('payment_del', {
            FORM         => $query_params,
            UID          => $path_params->{uid},
            ID           => $path_params->{id},
            PAYMENT_INFO => $payment_info->[0] || {}
          });

          return {
            result     => "Successfully deleted payment for user $path_params->{uid} and payment id $path_params->{id}",
            uid        => $path_params->{uid},
            payment_id => $path_params->{id},
          };
        }
        else {
          return {
            errno  => 10121,
            errstr => "Payment with id $path_params->{id} and uid $path_params->{uid} does not exist"
          };
        }
      },
      module      => 'Payments',
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

#**********************************************************
=head2 _payments_user ($path_params, $query_params, $module_obj)

=cut
#**********************************************************
sub _payments_user {
  my $self = shift;
  my ($path_params, $query_params, $module_obj) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{1}{0} && !$self->{admin}->{permissions}{1}{3});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{DESC} = $query_params->{DESC} || 'DESC';
  $query_params->{SUM} = $query_params->{SUM} || '_SHOW';
  $query_params->{REG_DATE} = $query_params->{REG_DATE} || '_SHOW';
  $query_params->{METHOD} = $query_params->{METHOD} || '_SHOW';
  $query_params->{UID} = $path_params->{uid} || $query_params->{UID} || '_SHOW';
  $query_params->{FROM_DATE} = ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef;
  $query_params->{TO_DATE} = ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef;
  $query_params->{INVOICE_NUM} = '_SHOW' if ($query_params->{INVOICE_DATE} && !$query_params->{INVOICE_NUM});

  return $module_obj->list({
    %{$query_params},
    COLS_NAME => 1
  });
}

1;
