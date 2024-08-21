package Api::Paths::Fees;
=head NAME

  Fees api functions

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
      path        => '/user/fees/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        my $fees = $module_obj->list({
          UID       => $path_params->{uid},
          DSC       => '_SHOW',
          SUM       => '_SHOW',
          DATETIME  => '_SHOW',
          PAGE_ROWS => ($query_params->{PAGE_ROWS} || 10000),
          COLS_NAME => 1
        });

        foreach my $fee (@$fees) {
          delete @{$fee}{qw/inner_describe/};
        }

        return $fees;
      },
      module      => 'Fees',
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
      path        => '/fees/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;
        return $self->_fees_user($path_params, $query_params, $module_obj);
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/types/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if !$self->{admin}->{permissions}{2}{3};

        foreach my $param (keys %{$query_params}) {
          $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
        }

        $module_obj->fees_type_list({
          %$query_params,
          COLS_NAME => 1
        });
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;
        return $self->_fees_user($path_params, $query_params, $module_obj);
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
    #@deprecated
    {
      method      => 'POST',
      path        => '/fees/users/:uid/:sum/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if (!$self->{admin}->{permissions}{2}{1} && !$self->{admin}->{permissions}{2}{3});

        $module_obj->take({ UID => $path_params->{uid} }, $path_params->{sum}, {
          %$query_params,
          UID => $path_params->{uid}
        });
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'POST',
      path        => '/fees/users/:uid/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if (!$self->{admin}->{permissions}{2}{1} && !$self->{admin}->{permissions}{2}{3});

        return {
          errno  => 10102,
          errstr => 'Wrong param sum, it\'s empty or must be bigger than zero',
        } if (!$query_params->{SUM} || $query_params->{SUM} !~ /[0-9\.]+/ || $query_params->{SUM} <= 0);

        my $Users = $path_params->{user_object};
        require Bills;
        Bills->import();
        my $Bills = Bills->new($self->{db}, $self->{admin}, $self->{conf});
        $query_params->{BILL_ID} //= '--';
        $query_params->{DESCRIBE} //= '';
        $query_params->{METHOD} //= 0;

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
          errno  => 10101,
          errstr => "User not found with uid - $path_params->{uid} and billId - $query_params->{BILL_ID}",
        } if (!$Bills->{TOTAL});

        my %results = ();

        if ($query_params->{PERIOD} && $query_params->{PERIOD} eq '2') {
          return {
            errno  => 10103,
            errstr => 'No param date',
          } if (!$query_params->{DATE});

          require Shedule;
          Shedule->import();
          my $Schedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});

          my ($Y, $M, $D) = split(/-/, $query_params->{DATE});

          $Schedule->add({
            DESCRIBE => $query_params->{DESCRIBE},
            D        => $D,
            M        => $M,
            Y        => $Y,
            UID      => $path_params->{uid},
            TYPE     => 'fees',
            ACTION   => ($self->{conf}->{EXT_BILL_ACCOUNT})
              ? "$query_params->{SUM}:$query_params->{DESCRIBE}:BILL_ID=$query_params->{BILL_ID}:$query_params->{METHOD}"
              : "$query_params->{SUM}:$query_params->{DESCRIBE}::$query_params->{METHOD}"
          });

          if ($Schedule->{errno}) {
            $results{result} = 'Failed add schedule';
            $results{errno} = 10105;
            $results{errstr} = $Schedule->{errstr};
          }
          else {
            $results{result} = 'Schedule added';
            $results{schedule_id} = $Schedule->{INSERT_ID};
          }
        }
        else {
          delete $query_params->{DATE};

          if ($query_params->{ER} && $query_params->{ER} ne '') {
            my $er = $module_obj->exchange_info($query_params->{ER});
            return {
              errstr => "Not valid parameter $query_params->{ER}",
              errno  => 10104
            } if ($module_obj->{errno});
            $query_params->{ER} = $er->{ER_RATE};
            $query_params->{SUM} = $query_params->{SUM} / $query_params->{ER};
          }

          $module_obj->take({ UID => $path_params->{uid} }, $query_params->{SUM}, {
            %$query_params,
            UID => $path_params->{uid}
          });

          if ($module_obj->{errno}) {
            $results{errno} = $module_obj->{errno};
            $results{errstr} = $module_obj->{errno};
          }
          else {
            $results{result} = 'OK';
            $results{fee_id} = $module_obj->{INSERT_ID};

            if ($query_params->{CREATE_FEES_INVOICE} && in_array('Docs', \@main::MODULES)) {
              require Docs;
              Docs->import();
              my $Docs = Docs->new($self->{db}, $self->{admin}, $self->{conf});
              $Docs->invoice_add({ %$query_params, ORDER => $query_params->{DESCRIBE}, UID => $path_params->{uid} });

              if ($Docs->{errno}) {
                $results{docs}{result} = 'Failed add fees invoice';
                $results{docs}{errno} = $Docs->{errno};
                $results{docs}{errstr} = $Docs->{errstr};
              }
              else {
                $results{docs}{result} = 'OK';
                $results{docs}{invoice_id} = $Docs->{INVOICE_NUM};
              }
            }

            if ($self->{conf}->{external_fees}) {
              ::_external($self->{conf}->{external_fees}, { %$query_params, UID => $path_params->{uid} });
              $results{external_fees} = 'Executed';
            }
          }
        }

        return \%results;
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'GET',
      path        => '/fees/schedules/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        require Shedule;
        Shedule->import();
        my $Schedule = Shedule->new($self->{db}, $self->{conf}, $self->{admin});

        my $list = $Schedule->list({
          %$query_params,
          UID       => $query_params->{UID} || '_SHOW',
          TYPE      => 'fees',
          COLS_NAME => 1
        });

        return $list;
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
    {
      method      => 'DELETE',
      path        => '/fees/users/:uid/:id/',
      handler     => sub {
        my ($path_params, $query_params, $module_obj) = @_;

        return {
          errno  => 10,
          errstr => 'Access denied'
        } if (!$self->{admin}->{permissions}{2}{2} && !$self->{admin}->{permissions}{2}{3});

        $module_obj->list({
          UID => $path_params->{uid},
          ID  => $path_params->{id},
        });

        if (!$module_obj->{TOTAL}) {
          return {
            errno  => 10128,
            errstr => "Fee with id $path_params->{id} and uid $path_params->{uid} does not exist"
          };
        }

        my $comments = $query_params->{COMMENTS} || 'Deleted from API request';
        $module_obj->del($path_params->{user_object}, $path_params->{id}, { COMMENTS => $comments });

        if ($module_obj->{AFFECTED}) {
          return {
            result     => "Successfully deleted fee for user $path_params->{uid} and fee id $path_params->{id}",
            uid        => $path_params->{uid},
            payment_id => $path_params->{id},
          };
        }
        else {
          return {
            errno  => 10129,
            errstr => "Fee with id $path_params->{id} and uid $path_params->{uid} does not exist"
          };
        }
      },
      module      => 'Fees',
      credentials => [
        'ADMIN'
      ]
    },
  ];
}

#**********************************************************
=head2 _fees_user($path_params, $query_params, $module_obj)

=cut
#**********************************************************
sub _fees_user {
  my $self = shift;
  my ($path_params, $query_params, $module_obj) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{2}{0} && !$self->{admin}->{permissions}{2}{3});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{INVOICE_ID} = $query_params->{INVOICE_ID} || '_SHOW' if ($query_params->{INVOICE_NUM});
  $query_params->{DESC} = $query_params->{DESC} || 'DESC';
  $query_params->{SUM} = $query_params->{SUM} || '_SHOW';
  $query_params->{REG_DATE} = $query_params->{REG_DATE} || '_SHOW';
  $query_params->{METHOD} = $query_params->{METHOD} || '_SHOW';
  $query_params->{DSC} = $query_params->{DSC} || '_SHOW';
  $query_params->{UID} = $path_params->{uid} || $query_params->{UID} || '_SHOW';
  $query_params->{FROM_DATE} = ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef;
  $query_params->{TO_DATE} = ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef;

  $module_obj->list({
    %{$query_params},
    COLS_NAME => 1
  });
}

1;
