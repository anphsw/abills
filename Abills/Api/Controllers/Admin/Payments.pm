package Api::Controllers::Admin::Payments;

=head1 NAME

  ADMIN API Payments

  Endpoints:
    /payments/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;
use Control::Errors;
use Payments;

my Control::Errors $Errors;
my Payments $Payments;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};
  $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 get_payments($path_params, $query_params)

  Endpoint GET /payments/

=cut
#**********************************************************
sub get_payments {
  my $self = shift;
  my ($path_params, $query_params) = @_;

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

  return $Payments->list({
    %{$query_params},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 post_payments_users_uid($path_params, $query_params)

  Endpoint POST /payments/users/:uid/

=cut
#**********************************************************
sub post_payments_users_uid {
  my $self = shift;
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

  my $allowed_payments = $Payments->admin_payment_type_list({
    COLS_NAME => 1,
    AID       => $self->{admin}->{AID},
  });

  my @allowed_payments_ids = map {$_->{payments_type_id}} @{$allowed_payments};

  if ($payment_method !~ /[0-9]+/) {
    my $payment_methods = $Payments->payment_type_list({
      COLS_NAME       => 1,
      payments_TYPE       => '_SHOW',
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

    # TODO: change method of checking deadlock
    $Payments->list({ ID => $Payments->{PAYMENT_ID} });
    #@experimental
    if (!$Payments->{errno} && !$Payments->{TOTAL}) {
      return {
        errno  => 10072,
        errstr => 'Failed add payment. Deadlock during transaction',
      };
    }

    return {
      insert_id  => $Payments->{INSERT_ID},
      payment_id => $Payments->{INSERT_ID},
      uid        => $path_params->{uid},
      %extra_results
    };
  }
}

#**********************************************************
=head2 get_payments_types($path_params, $query_params)

  Endpoint GET /payments/types/

=cut
#**********************************************************
sub get_payments_types {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{1}{0} && !$self->{admin}->{permissions}{1}{3});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Payments->payment_type_list({
    %$query_params,
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 delete_payments_users_uid_id($path_params, $query_params)

  Endpoint DELETE /payments/users/:uid/:id/

=cut
#**********************************************************
sub delete_payments_users_uid_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{1}{2} && !$self->{admin}->{permissions}{1}{3});

  $Payments->list({
    UID => $path_params->{uid},
    ID  => $path_params->{id},
  });

  if (!$Payments->{TOTAL}) {
    return {
      errno  => 10122,
      errstr => "Payment with id $path_params->{id} and uid $path_params->{uid} does not exist"
    };
  }

  my $comments = $query_params->{COMMENTS} || 'Deleted from API request';
  my $payment_info = $Payments->list({
    ID         => $path_params->{id},
    UID        => '_SHOW',
    DATETIME   => '_SHOW',
    SUM        => '_SHOW',
    DESCRIBE   => '_SHOW',
    EXT_ID     => '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1,
  });
  $Payments->del($path_params->{user_object}, $path_params->{id}, { COMMENTS => $comments });

  if ($Payments->{AFFECTED}) {
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
}

#**********************************************************
=head2 get_payments_types_id($path_params, $query_params)

  GET /payments/types/:id/

=cut
#**********************************************************
sub get_payments_types_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Payments->payment_type_info({ ID => $path_params->{id} });

  delete @{$Payments}{qw/TOTAL list AFFECTED/};

  return $Payments;
}

#**********************************************************
=head2 post_payments_types_id($path_params, $query_params)

  POST /payments/types/:id/

=cut
#**********************************************************
sub post_payments_types_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Payments->payment_type_add({ %$query_params, ID => $path_params->{id} });

  return $Payments if $Payments->{errno};

  $Payments->payment_type_info({ ID => $path_params->{id} });

  delete @{$Payments}{qw/TOTAL list AFFECTED INSERT_ID/};

  return $Payments;
}

#**********************************************************
=head2 put_payments_types_id($path_params, $query_params)

  PUT /payments/types/:id/

=cut
#**********************************************************
sub put_payments_types_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Payments->payment_type_change({ %$query_params, ID => $path_params->{id} });

  return $Payments if $Payments->{errno};

  $Payments->payment_type_info({ ID => $path_params->{id} });

  delete @{$Payments}{qw/TOTAL list AFFECTED/};

  return $Payments;
}

#**********************************************************
=head2 delete_payments_types_id($path_params, $query_params)

  DELETE /payments/types/:id/

=cut
#**********************************************************
sub delete_payments_types_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{4});

  $Payments->payment_type_del({ ID => $path_params->{id} });

  return $Payments if $Payments->{errno};

  if ($Payments->{AFFECTED} && $Payments->{AFFECTED} =~ /^[0-9]$/) {
    return {
      result => 'Successfully deleted',
      id     => $path_params->{id},
    };
  }

  return $Errors->throw_error(1001140, { errstr => "Payment type with id $path_params->{id} not exists" });
}

1;
