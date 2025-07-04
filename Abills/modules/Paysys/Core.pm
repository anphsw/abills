package Paysys::Core;
=head Paysys_Base

  Paysys::Core - new module for payment systems

  Paysys_Base - Old schema

=cut
use strict;
use warnings FATAL => 'all';

use Encode;

use Abills::Base qw(sendmail convert in_array is_number);
use Abills::Filters qw(_expr);
use Abills::Fetcher qw(web_request);

use Paysys;
use Users;
use Payments;

my Paysys $Paysys;
my Payments $Payments;
my Users $Users;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $conf,
    debug     => $conf->{PAYSYS_DEBUG} || 0,
    paysys_id => 0,
    insert_id => 0,
  };

  bless($self, $class);

  $self->{REMOTE_ADDR} = ($attr && $attr->{REMOTE_ADDR})
    ? $attr->{REMOTE_ADDR}
    : ($ENV{REMOTE_ADDR} || '127.0.0.1');

  $Paysys = Paysys->new($db, $admin, $conf);
  $Payments = Payments->new($db, $admin, $conf);
  $Users = Users->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 paysys_pay($attr) - make payment for user

  Arguments:
    $attr
      DEBUG                   - Level of debugging;
      EXT_ID                  - External unique identifier of payment;
      CHECK_FIELD             - Synchronization field for subscriber;
      USER_ID                 - Identifier for subscriber;
      PAYMENT_SYSTEM          - Short name of payment system;
      PAYMENT_SYSTEM_ID       - ID of payment system;
      CURRENCY                - The exchange rate for the payment of the system;
      CURRENCY_ISO            -
      SUM                     - Payment amount;
      DATA                    - HASH_REF Transaction information field;
      ORDER_ID                - Transaction identifier in ABillS;
      MK_LOG                  - Logging;
      REGISTRATION_ONLY       - Add payment info without real payment
      PAYMENT_DESCRIBE        - Description of payment;
      PAYMENT_INNER_DESCRIBE  - Inner description of payment;
      PAYMENT_ID        - if this attribute is on(1), function will return two values:
                                    $status_code - status code;
                                    $payments_id - transaction identifier in ABillS;
      USER_INFO         - Additional information;
      CROSSMODULES_TIMEOUT - Crossmodules function timeout
      ERROR             - Status error;
      PAYMENT_METHOD    - Payment method;
      MERCHANT_ID       - Merchant id;
      FORCE_PAYMENT     - Force make payment without checking is present transaction in system

  Returns:
    Payment status code.
    All codes:
      0   Operation was successfully completed
      1   User not present in the system
      2   The error in the database
      3   Such a payment already exists in the system, it is not present in the list of payments or the list of transactions
      5   Improper payment amount. It arises in systems with a tandem payment if the user starts a transaction with one amount but in the process of changing the amount of the transaction
      6   Too small amount
      7   The amount of the payment more than permitted
      8   The transaction is not found (Paysys list not found)
      9   Payments already exists
      10  This payment is not found in the system
      11  For this group of users not allowed to use external payment (Paysys)
      12  An unknown SQL error payment, happens when deadlock
      13  Error logging external payments (Paysys list exist transaction)
      14  User without bill account
      15  Transaction created and unpaid and canceled
      17  SQL when conducting payment
      28  Wrong exchange
      35  Wrong signature
      40  Duplicate identifier


  Examples:
    my $result_code = $Paysys_core->paysys_pay({
        PAYMENT_SYSTEM    => OP,
        PAYMENT_SYSTEM_ID => 100,
        CHECK_FIELD       => UID,
        USER_ID           => 1,
        SUM               => 50.00,
        EXT_ID            => 11111111,
        DATA              => \%FORM,
        CURRENCY          => $conf{PAYSYS_PAYNET_CURRENCY},
        PAYMENT_DESCRIBE  => 'Payment with paysystem Oplata'
        PAYMENT_ID        => 1,
        MK_LOG            => 1,
        DEBUG             => 7
    });
    $result_code - payment status code.

    my ($result_code, $payments_id ) = $Paysys_core->paysys_pay({
    PAYMENT_SYSTEM    => $payment_system,
    PAYMENT_SYSTEM_ID => $payment_system_id,
    CHECK_FIELD       => $CHECK_FIELD,
    USER_ID           => $request_params{customer_id},
    SUM               => $request_params{sum},
    EXT_ID            => $request_params{transaction_id},
    DATA              => \%request_params,
    CURRENCY          => $conf{PAYSYS_PAYNET_CURRENCY},
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    DEBUG             => $debug
    });

    Payment by ORDER_ID (without check field) Example from Lifecell:
      Most be ORDER_ID and EXT_ID.
     my $status_code = $Paysys_core->paysys_pay({
      PAYMENT_SYSTEM    => $PAYSYSTEM_SHORT_NAME,
      PAYMENT_SYSTEM_ID => $PAYSYSTEM_ID,
      SUM               => $FORM->{sum},
      ORDER_ID          => "$PAYSYSTEM_SHORT_NAME:$order_id",
      EXT_ID            => "$order_id",
      DATA              => $FORM,
      DATE              => "$date $time",
      MK_LOG            => 1,
      DEBUG             => $self->{DEBUG},
      PAYMENT_DESCRIBE  => $FORM->{desc} || "$PAYSYSTEM_NAME payment",
    });

=cut
#**********************************************************
sub paysys_pay {
  my $self = shift;
  my ($attr) = @_;

  # my attr
  my $debug = $attr->{DEBUG} || 0;
  my $ext_id = $attr->{EXT_ID} || '';
  my $CHECK_FIELD = $attr->{CHECK_FIELD} || 'UID';
  my $user_account = $attr->{USER_ID};
  my $amount = $attr->{SUM};
  my $order_id = $attr->{ORDER_ID};
  $Users = $attr->{USER_INFO} if ($attr->{USER_INFO});

  # local vars
  $self->{paysys_id} = 0;
  my $domain = $ENV{DOMAIN_ID} // 0;
  my $status = 0;
  my $uid = 0;
  $attr->{_EXT_INFO} = $self->_paysys_pay_ext_info($attr);

  $user_account = _expr($user_account, $self->{conf}->{PAYSYS_ACCOUNT_EXPR});

  #Wrong sum
  if ($amount && $amount <= 0) {
    return 5;
  }
  #Small sum
  elsif ($attr->{MIN_SUM} && $amount < $attr->{MIN_SUM}) {
    return 6;
  }
  # large sum
  elsif ($attr->{MAX_SUM} && $amount > $attr->{MAX_SUM}) {
    return 7;
  }
  elsif ($ext_id eq 'no_ext_id') {
    return 29;
  }

  if ($debug > 6) {
    $Users->{debug} = 1;
    $Paysys->{debug} = 1;
    $Payments->{debug} = 1;
  }

  #Get transaction info
  if ($order_id || $attr->{PAYSYS_ID}) {
    print "Order: " . ($order_id || $attr->{PAYSYS_ID}) if ($debug > 1);

    my $list = $Paysys->list({
      TRANSACTION_ID => $order_id || '_SHOW',
      ID             => $attr->{PAYSYS_ID} || undef,
      DATETIME       => '_SHOW',
      STATUS         => '_SHOW',
      SUM            => '_SHOW',
      COLS_NAME      => 1,
      DOMAIN_ID      => '_SHOW',
      SKIP_DEL_CHECK => 1
    });

    # if transaction not exist
    if ($Paysys->{errno} || $Paysys->{TOTAL} < 1) {
      $status = 8;
      return $status;
    }
    #If transaction success
    elsif ($list->[0]->{status} == 2) {
      $status = 9;
      return $status, $list->[0]->{id};
    }

    if (!$order_id) {
      (undef, $ext_id) = split(/:/, $list->[0]->{transaction_id});
    }

    $uid                = $list->[0]->{uid};
    $self->{paysys_id}  = $list->[0]->{id};

    if (!$attr->{NEW_SUM}) {
      $amount = $list->[0]->{sum};
    }

    #Register success payments
    if ($attr->{REGISTRATION_ONLY} && !$attr->{ERROR}) {
      $self->_paysys_pay_update_transaction($attr);
      return 0;
    }
  }
  else {
    my $list = $self->_paysys_extra_check_user({
      MAIN_CHECK_FIELD => $CHECK_FIELD,
      USER_ACCOUNT     => $user_account || '---',
      EXTRA_USER_IDS   => $attr->{EXTRA_USER_IDS} || [],
    });

    if ($Users->{errno} || $Users->{TOTAL} < 1) {
      if ($self->{conf}->{SECOND_BILLING_OUT} && !(defined($self->{conf}->{SECOND_BILLING_OUT_GROUPS}))) {
        return $self->_paysys_pay_second_bill({
          USER_ACCOUNT => $user_account,
          SUM          => $amount,
          EXT_ID       => $ext_id,
          PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
        });
      }
      else {
        return 1;
      }
    }

    if ($list->[0]->{disable_paysys} && $self->{conf}->{SECOND_BILLING_DISABLE_PAYSYS}) {
      return 11;
    }

    if ($self->{conf}->{SECOND_BILLING_OUT_GROUPS} && $list->[0]->{gid}) {
      my @groups = split(', ', $self->{conf}->{SECOND_BILLING_OUT_GROUPS});
      foreach my $group (@groups) {
        next if ($list->[0]->{gid} != $group);
        return $self->_paysys_pay_second_bill({
          USER_ACCOUNT => $user_account,
          SUM          => $amount,
          EXT_ID       => $ext_id,
          PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
        });
      }
    }

    #disable paysys
    if ($list->[0]->{disable_paysys}) {
      return 11;
    }

    $uid = $list->[0]->{uid};
  }

  # For skip license check if payment
  my $user = $Users->info($uid, { USERS_AUTH => 1, DOMAIN_ID => $domain });

  # delete param for cross modules
  delete $user->{PAYMENTS_ADDED};

  # Register error
  if ($attr->{ERROR}) {
    return $self->_paysys_pay_error({
      %$attr,
      UID      => $user->{UID},
      EXT_ID   => $ext_id,
      ERROR    => ($attr->{ERROR} == 35) ? 5 : $attr->{ERROR},
      AMOUNT   => $amount,
    });
  }

  return $self->_paysys_pay_payment_process({
    %$attr,
    _EXT_ID       => $ext_id,
    _USER_INFO    => $user,
    _USER_ACCOUNT => $user_account,
    _AMOUNT       => $amount
  });
}

#**********************************************************
=head2 _paysys_pay_error() - add transaction with error

  Arguments:
    $attr
      ...paysys_pay.attr

  Returns:
    $error_code, $payment_id

=cut
#**********************************************************
sub _paysys_pay_error {
  my $self = shift;
  my ($attr) = @_;

  if ($self->{paysys_id}) {
    $self->_paysys_pay_update_transaction($attr);
  }
  else {
    my $params = $self->_paysys_pay_conf($attr);
    my ($merchant_id, undef, undef) = @{$params}{qw/merchant_id method inner_describe/};

    $Paysys->add({
      SYSTEM_ID         => $attr->{PAYMENT_SYSTEM_ID},
      DATETIME          => $attr->{DATE} || "$main::DATE $main::TIME",
      SUM               => ($attr->{COMMISSION} && $attr->{SUM}) ? $attr->{SUM} : $attr->{AMOUNT},
      UID               => $attr->{UID},
      IP                => $attr->{IP},
      TRANSACTION_ID    => "$attr->{PAYMENT_SYSTEM}:$attr->{EXT_ID}",
      INFO              => $attr->{_EXT_INFO},
      USER_INFO         => $attr->{USER_INFO},
      PAYSYS_IP         => $self->{REMOTE_ADDR},
      STATUS            => $attr->{ERROR},
      DOMAIN_ID         => $ENV{DOMAIN_ID} || 0,
      MERCHANT_ID       => $merchant_id,
      RECURRENT_PAYMENT => $attr->{RECURRENT_PAYMENT} ? 1 : 0,
    });

    $self->{paysys_id} = $Paysys->{errno} ? 0 : $Paysys->{INSERT_ID};
  }

  if ($attr->{PAYMENT_ID}) {
    return $attr->{ERROR}, $self->{paysys_id};
  }

  return $attr->{ERROR};
}

#**********************************************************
=head2 _paysys_pay_ext_info($attr) - create ext info message

  Arguments
    $attr
      ...paysys_pay.attr

  Return:
    message: str

=cut
#**********************************************************
sub _paysys_pay_ext_info {
  my $self = shift;
  my ($attr) = @_;

  my $ext_info = '';

  if ($attr->{DATA}) {
    foreach my $k (sort keys %{$attr->{DATA}}) {
      if ($k eq '__BUFFER') {
        next;
      }

      Encode::_utf8_off($attr->{DATA}->{$k});
      $ext_info .= "$k, $attr->{DATA}->{$k}\n" if($attr->{DATA}->{$k});
    }

    if ($attr->{MK_LOG}) {
      $self->mk_log($ext_info, { PAYSYS_ID => "$attr->{PAYMENT_SYSTEM}/$attr->{PAYMENT_SYSTEM_ID}", REQUEST => 'Request' });
    }
  }

  return $ext_info;
}

#**********************************************************
=head2 _paysys_pay_payment_process() - process of payment

  Arguments:
    $attr
      ...paysys_pay.attr
      _EXT_ID       - id of transaction
      _USER_INFO    - info user
      _USER_ACCOUNT - user account based on which will made payment
      _AMOUNT       - amount of payment

  Returns:
    $status, $payment_id

=cut
#**********************************************************
sub _paysys_pay_payment_process {
  my $self = shift;
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $status = 0;
  my $payments_id = 0;
  my $user = $attr->{_USER_INFO};
  my $user_account = $attr->{_USER_ACCOUNT};
  my $amount = $attr->{_AMOUNT};
  my $payment_system = $attr->{PAYMENT_SYSTEM};
  my $ext_id = $attr->{_EXT_ID};

  my $er = '';
  my $currency = 0;

  #Exchange rates
  my $PAYMENT_SUM = 0;
  if ($attr->{CURRENCY} || $attr->{CURRENCY_ISO}) {
    $Payments->exchange_info(0, {
      SHORT_NAME => $attr->{CURRENCY},
      ISO        => $attr->{CURRENCY_ISO} });
    if ($Payments->{errno} && $Payments->{errno} != 2) {
      return 28;
    }
    elsif ($Payments->{TOTAL} > 0) {
      $er = $Payments->{ER_RATE};
      $currency = $Payments->{ISO};
    }
    if ($er && $er != 1) {
      $PAYMENT_SUM = sprintf('%.2f', $amount / $er);
    }
  }

  my $params = $self->_paysys_pay_conf($attr);
  my ($merchant_id, $method, $inner_describe, $payment_describe) = @{$params}{qw/merchant_id method inner_describe payment_describe/};

  #Sucsess
  if (!$self->{conf}->{PAYMENTS_POOL}) {
    ::cross_modules('pre_payment', {
      USER_INFO    => $user,
      SKIP_MODULES => 'Sqlcmd, Cards',
      SILENT       => 1,
      QUITE        => 1,
      SUM          => $PAYMENT_SUM || $amount,
      AMOUNT       => $amount || $PAYMENT_SUM,
      EXT_ID       => "$payment_system:$ext_id",
      METHOD       => $method || 2,
      timeout      => $attr->{CROSSMODULES_TIMEOUT} || $self->{conf}->{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
      FORM         => $attr,
    });
  }

  $user->{UID} = $user->{_COMPANY_ADMIN} if ($user->{_COMPANY_ADMIN});

  $Payments->add($user, {
    SUM            => $amount,
    DATE           => $attr->{DATE},
    DESCRIBE       => $attr->{PAYMENT_DESCRIBE} || $payment_describe || "$payment_system:$ext_id",
    INNER_DESCRIBE => $inner_describe || '',
    METHOD         => $method || 2,
    EXT_ID         => "$payment_system:$ext_id",
    CHECK_EXT_ID   => $attr->{FORCE_PAYMENT} ? '' : "$payment_system:$ext_id",
    ER             => $er,
    CURRENCY       => $currency,
    USER_INFO      => $user
  });

  # Exists payments Duplicate
  if ($Payments->{errno} && $Payments->{errno} == 7) {
    my $list = $Paysys->list({
      TRANSACTION_ID => "$payment_system:$ext_id",
      STATUS         => '_SHOW',
      COLS_NAME      => 1
    });

    $payments_id = $Payments->{ID};

    # paysys list not exist
    if ($Paysys->{TOTAL} == 0) {
      $self->_paysys_pay_payments_made({
        %$attr,
        _MERCHANT_ID              => $merchant_id,
        _PAYMENT_SUM              => $PAYMENT_SUM,
        _PAYMENTS_ID              => $payments_id,
        _TRANSACTION_REGISTRATION => 1
      });

      $status = 3;
    }
    else {
      $self->{paysys_id} = $list->[0]->{id};

      if ($self->{paysys_id} && $list->[0]->{status} != 2) {
        $self->_paysys_pay_update_transaction({
          %$attr,
          _MERCHANT_ID => $merchant_id,
        });
      }

      $status = 13;
    }
  }
  #Payments error
  elsif ($Payments->{errno}) {
    if ($debug > 3) {
      print "Payment Error: [$Payments->{errno}] $Payments->{errstr}\n";
    }

    if ($Payments->{errno} == 14) {
      $status = 14;
    }
    else {
      # happens if deadlock
      $status = 12;
    }
  }
  else {
    if ($self->{paysys_id}) {
      $self->_paysys_pay_update_transaction({
        %$attr,
        _MERCHANT_ID => $merchant_id,
      });
    }
    else {
      $attr->{_TRANSACTION_REGISTRATION} = 1;
    }

    $self->_paysys_pay_payments_made({
      %$attr,
      _MERCHANT_ID => $merchant_id,
      _PAYMENT_SUM => $PAYMENT_SUM,
      _PAYMENTS_ID => $payments_id,
    });

    #Transactions registration error
    if ($Paysys->{errno} && $Paysys->{errno} == 7) {
      $status = $attr->{FORCE_PAYMENT} ? 0 : 3;
      $payments_id = $Payments->{ID};
    }
    #Payments error
    elsif ($Paysys->{errno}) {
      $status = 2;
    }
  }

  if ($self->{conf}->{SECOND_BILLING_SYNC}) {
    my @groups = $self->{conf}->{SECOND_BILLING_SYNC_GROUPS} ? split(', ', $self->{conf}->{SECOND_BILLING_SYNC_GROUPS})
      : ($user->{GID});
    foreach my $group (@groups) {
      next if ($user->{GID} != $group);

      $self->_paysys_pay_second_bill({
        USER_ACCOUNT => ($user_account || ($user->{$self->{conf}->{SECOND_BILLING_SYNC_KEY}} || $user->{UID})),
        SUM          => $amount,
        EXT_ID       => $attr->{EXT_ID},
        PAYMENT_ID   => $attr->{PAYMENT_ID} || 0
      });
    }
  }

  if ($attr->{PAYMENT_ID}) {
    return $status, $self->{paysys_id};
  }

  return $status;
}

#**********************************************************
=head2 _paysys_pay_update_transaction() - register transaction and make cross_modules

  Arguments:
    $attr
      ..._paysys_pay_payment_process.attr
      _TRANSACTION_REGISTRATION - register payment in paysys_log

=cut
#**********************************************************
sub _paysys_pay_payments_made {
  my $self = shift;
  my ($attr) = @_;

  my $payments_id = $attr->{_PAYMENTS_ID} || 0;
  my $user = $attr->{_USER_INFO};
  my $amount = $attr->{_AMOUNT};
  my $payment_system = $attr->{PAYMENT_SYSTEM};
  my $payment_system_id = $attr->{PAYMENT_SYSTEM_ID};
  my $ext_id = $attr->{_EXT_ID};
  my $ext_info = $attr->{_EXT_INFO};
  my $merchant_id = $attr->{_MERCHANT_ID} || 0;
  my $payment_sum = $attr->{_PAYMENT_SUM} || 0;
  my $debug = $attr->{DEBUG} || 0;

  if ($attr->{_TRANSACTION_REGISTRATION}) {
    $Paysys->add({
      SYSTEM_ID         => $payment_system_id,
      DATETIME          => $attr->{DATE} || "$main::DATE $main::TIME",
      SUM               => ($attr->{COMMISSION} && $attr->{SUM}) ? $attr->{SUM} : ($payment_sum || $amount),
      UID               => $user->{UID},
      TRANSACTION_ID    => "$payment_system:$ext_id",
      INFO              => $ext_info,
      PAYSYS_IP         => $ENV{'REMOTE_ADDR'},
      STATUS            => 2,
      USER_INFO         => $attr->{USER_INFO},
      MERCHANT_ID       => $merchant_id,
      DOMAIN_ID         => $ENV{DOMAIN_ID} || 0,
      RECURRENT_PAYMENT => $attr->{RECURRENT_PAYMENT} ? 1 : 0,
    });

    $self->{paysys_id} = $Paysys->{INSERT_ID};
  }

  if (!$Paysys->{errno}) {
    if (!$payments_id && $self->{conf}->{PAYMENTS_POOL}) {
      $Payments->pool_add({ PAYMENT_ID => $Payments->{PAYMENT_ID} });
      return 1;
    }

    # if parallel payments need do new info about user
    $user = $Users->info($user->{UID}, { USERS_AUTH => 1 });

    ::cross_modules('payments_maked', {
      PAYSYS_PAYMENT => {
        PAYMENT_SYSTEM => $payment_system,
        EXT_ID         => $ext_id,
      },
      USER_INFO      => $user,
      PAYMENT_ID     => $payments_id,
      SUM            => $payment_sum || $amount,
      AMOUNT         => $amount || $payment_sum,
      SILENT         => ($debug > 5) ? 0 : 1,
      DEBUG          => ($debug > 5) ? 1 : 0,
      QUITE          => 1,
      timeout        => $attr->{CROSSMODULES_TIMEOUT} || $self->{conf}{PAYSYS_CROSSMODULES_TIMEOUT} || 4,
      SKIP_MODULES   => 'Cards',
      FORM           => $attr
    });
  }

  return 1;
}

#**********************************************************
=head2 _paysys_pay_update_transaction() - update transaction info

  Arguments:
    $attr
      ..._paysys_pay_payment_process.attr

=cut
#**********************************************************
sub _paysys_pay_update_transaction {
  my $self = shift;
  my ($attr) = @_;

  my %transaction = (
    ID          => $self->{paysys_id},
    STATUS      => $attr->{ERROR} || 2,
    PAYSYS_IP   => $self->{REMOTE_ADDR},
    INFO        => $attr->{_EXT_INFO},
    USER_INFO   => $attr->{USER_INFO},
  );

  $transaction{SUM} = $attr->{_AMOUNT} if ($attr->{NEW_SUM});
  $transaction{MERCHANT_ID} = $attr->{_MERCHANT_ID} if ($attr->{_MERCHANT_ID});

  $Paysys->change(\%transaction);

  return 1;
}

#**********************************************************
=head2 _paysys_pay_conf() - get base config

  Arguments:
    $attr
      ..._paysys_pay_payment_process.attr

  Returns: $obj
    method
    merchant_id
    inner_describe

=cut
#**********************************************************
sub _paysys_pay_conf {
  my $self = shift;
  my ($attr) = @_;

  my $method = $attr->{PAYMENT_METHOD} || 0;
  my $merchant_id = $attr->{MERCHANT_ID} || 0;
  my $inner_describe = $attr->{PAYMENT_INNER_DESCRIBE} || '';
  my $payment_describe = $attr->{PAYMENT_DESCRIBE} || '';
  my $user = $attr->{_USER_INFO};
  my $payment_system_id = $attr->{PAYMENT_SYSTEM_ID};

  my $params = $Paysys->gid_params({
    GID       => $user->{GID} ? "$user->{GID},0" : '0',
    PAYSYS_ID => $payment_system_id,
    COLS_NAME => 1,
  });

  if (scalar(@{$params})) {
    $merchant_id = $params->[0]->{merchant_id} if (!$attr->{MERCHANT_ID});
    foreach my $param (@{$params}) {
      next if !$param->{param};
      if (!$attr->{PAYMENT_METHOD} && $param->{param} =~ /PAYMENT_METHOD/ && is_number($param->{value}, 0, 1)) {
        $method = $param->{value};
      }
      elsif (!$attr->{PAYMENT_INNER_DESCRIBE} && $param->{param} =~ /INNER_DESCRIPTION/) {
        $inner_describe = $param->{value};
      }
      elsif (!$attr->{PAYMENT_DESCRIBE} && $param->{param} =~ /PAYSYS\_[a-zA-Z0-9]+\_DESCRIPTION/ && $param->{value}) {
        $payment_describe = $self->desc_former($param->{value}, $user->{UID});
      }
    }
  }

  if (!$method) {
    my $system_info = $Paysys->paysys_connect_system_list({
      PAYSYS_ID      => $payment_system_id,
      PAYMENT_METHOD => '_SHOW',
      COLS_NAME      => 1,
    });

    $method = $system_info->[0]{payment_method};
  }

  return {
    method           => $method,
    merchant_id      => $merchant_id,
    inner_describe   => $inner_describe,
    payment_describe => $payment_describe
  };
}

#**********************************************************
=head2 paysys_check_user() - check user in system;

  Arguments:
    $attr
      CHECK_FIELD     - Searching field for user;
      USER_ID         - User identifier for CHECK_FIELD;
      EXTRA_FIELDS    - Extra fields
      DEBUG           - Debug mode
      SKIP_FIO_HIDE   - Skip hide fio
      RECOMENDED_PAY  - Returns total sum
      PAYSYS_ID       - ID of payment system

  Returns:
    $result, $user_info

    $result - result code;
    $user_info - users information fields.

    Checking code.
    All codes:
      0  - User exist;
      1  - User not exist;
      2  - SQL error;
      11 - Disable paysys for group
      14 - No bill_id
      30 - Not filled user identifier in request

  Examples:
    my ($result, $list) = paysys_check_user({
     CHECK_FIELD => 'UID',
     USER_ID     => 1
    });

=cut
#**********************************************************
sub paysys_check_user {
  my $self = shift;
  my ($attr) = @_;
  my $result = 0;

  my $CHECK_FIELD = $attr->{CHECK_FIELD} || 'UID';
  my $user_account = $attr->{USER_ID} || q{};

  $user_account =~ s/\*//;

  $user_account = _expr($user_account, $self->{conf}->{PAYSYS_ACCOUNT_EXPR});

  if (!$user_account) {
    return 30;
  }

  if ($attr->{DEBUG} && $attr->{DEBUG} > 6) {
    $Users->{debug} = 1;
  }

  my $list = $self->_paysys_extra_check_user({
    %$attr,
    USER_ACCOUNT     => $user_account,
    MAIN_CHECK_FIELD => $CHECK_FIELD,
    EXTRA_USER_IDS   => $attr->{EXTRA_USER_IDS} || [],
    COLS_UPPER       => 1
  });

  if ($Users->{errno}) {
    $self->mk_log('Mysql error ' . ($Users->{errno} || q{}));
    # need to make empty if call the same object multiple times
    delete $Users->{errno};
    return 2;
  }
  elsif ($Users->{TOTAL} < 1) {
    if ($self->{conf}->{SECOND_BILLING_OUT} && !(defined($self->{conf}->{SECOND_BILLING_OUT_GROUPS}))) {
      return $self->_paysys_check_user_second_bill({USER_ACCOUNT => $user_account});
    }
    else {
      return 1;
    }
  }
  elsif ($self->{conf}->{SECOND_BILLING_OUT_GROUPS} && $list->[0]->{GID}) {
    my @groups = split(', ', $self->{conf}->{SECOND_BILLING_OUT_GROUPS});
    if (in_array($list->[0]->{GID}, \@groups)) {
      return $self->_paysys_check_user_second_bill({ USER_ACCOUNT => $user_account });
    }
  }
  elsif ($list->[0]->{DISABLE_PAYSYS}) {
    return 11;
  }
  elsif (!$list->[0]->{BILL_ID}) {
    return 14;
  }

  return 11 if (defined $list->[0]->{GID} && $attr->{PAYSYS_ID} && $self->{conf}->{"PAYSYS_PAYMENTS_DISABLED_$list->[0]->{GID}_$attr->{PAYSYS_ID}"});

  foreach my $user (@{$list}) {
    if ($attr->{RECOMENDED_PAY}) {
      $user->{RECOMENDED_PAY} = main::recomended_pay($list->[0]);
    }

    if ($user->{FIO}) {
      $user->{FIO} =~ s/\'/_/g;
      $user->{FIO} =~ s/\s+$//g;
      $user->{FIO} =~ s/&|%//g;
    }

    $user->{DEPOSIT} = sprintf("%.2f", $user->{DEPOSIT} || 0);

    if (!$attr->{SKIP_FIO_HIDE}) {
      $user->{FIO} = $self->_hide_text($user->{FIO} || q{});
      $user->{PHONE} = $self->_hide_text($user->{PHONE} || q{});
      $user->{ADDRESS_FULL} = $self->_hide_text($user->{ADDRESS_FULL} || q{});
    }

    last if (!$attr->{MULTI_USER});
  }

  if ($attr->{MULTI_USER}) {
    return $result, $list;
  }

  return $result, $list->[0];
}

#**********************************************************
=head2 paysys_pay_cancel() - cancel payment;

  Arguments:
    $attr
      PAYSYS_ID      - Paysys ID (unique number of operation);
      TRANSACTION_ID - Paysys Transaction identifier
      RETURN_CANCELED_ID - 1 (return $result, $paysys_canceled_id)
      CANCEL_TRANSACTION - force cancel of transaction if payment not exists
      DEBUG

  Returns:
    Cancel code.
    All codes:
      0  - Success Delete
      2  - Error with mysql
      8  - Paysys not exist
      10 - Payments not exist
      11 - no required parameter PAYSYS_ID or TRANSACTION_ID

  Examples:

    my $result = paysys_pay_cancel({
                  TRANSACTION_ID => "OP:11111111"
                 });

    $result - cancel code.

=cut
#**********************************************************
sub paysys_pay_cancel {
  my $self = shift;
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $result = 0;
  my $status = 0;
  my $canceled_payment_id = 0;
  my $cancel_status = $attr->{CANCEL_STATUS} || 3;

  if ($debug > 6) {
    $Users->{debug} = 1;
    $Paysys->{debug} = 1;
    $Payments->{debug} = 1;
  }

  if (!$attr->{PAYSYS_ID} && !$attr->{TRANSACTION_ID}) {
    $attr->{RETURN_CANCELED_ID} ?
      return 11, 0 :
      return 11;
  }

  my $paysys_list = $Paysys->list({
    ID             => $attr->{PAYSYS_ID} || '_SHOW',
    TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
    SUM            => '_SHOW',
    COLS_NAME      => 1
  });

  if (!$Paysys->{TOTAL}) {
    $self->{paysys_id} = 0;
    $attr->{RETURN_CANCELED_ID} ? return 8, $canceled_payment_id : return 8;
  }

  my $transaction_id = $paysys_list->[0]->{transaction_id};

  my $list = $Payments->list({
    ID        => '_SHOW',
    EXT_ID    => "$transaction_id",
    BILL_ID   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1
  });

  if ($status == 0) {
    if ($Payments->{errno}) {
      $result = 2;
    }
    elsif ($Payments->{TOTAL} < 1) {
      $result = 10;
      # cancel transaction status if no payments
      $Paysys->change({
        ID     => $paysys_list->[0]->{id},
        STATUS => $cancel_status
      });
    }
    else {
      my %user = (
        BILL_ID => $list->[0]->{bill_id},
        UID     => $list->[0]->{uid}
      );

      $Users->list({ UID => $list->[0]->{uid}, COLS_NAME => 1, COLS_UPPER => 1 }) if ($self->{conf}->{PAYSYS_LOG});
      my $payment_id = $list->[0]->{id};

      $Payments->del(\%user, $payment_id);
      if ($Payments->{errno}) {
        $result = 2;
      }
      else {
        $Paysys->change({
          ID     => $paysys_list->[0]->{id},
          STATUS => $cancel_status
        });
        $canceled_payment_id = $paysys_list->[0]->{id};
      }
    }
  }

  $self->{paysys_id} = $canceled_payment_id;

  if ($attr->{RETURN_CANCELED_ID}) {
    return $result, $canceled_payment_id;
  }

  return $result;
}

#**********************************************************
=head2 paysys_pay_check() - Checking existing transaction

  Arguments:
    $attr
      PAYSYS_ID      - Payment system identifier;
      TRANSACTION_ID - Transaction identifier;
      GID            -

  Returns:
    FALSE
      0      - if transaction not found;
    TRUE
      $number - transaction ID
      $transaction_status
      \%transaction_info

  Examples:

    my $result = paysys_pay_check({
                  TRANSACTION_ID => "OP:11111111",
                  GID => '_SHOW',
             });

    $result - 0 or transaction id;

=cut
#**********************************************************
sub paysys_pay_check {
  my $self = shift;
  my ($attr) = @_;

  my $paysys_list = $Paysys->list({
    ID             => $attr->{PAYSYS_ID} || '_SHOW',
    TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
    SUM            => '_SHOW',
    GID            => '_SHOW',
    UID            => '_SHOW',
    SKIP_TOTAL     => 1,
    COLS_NAME      => 1
  });

  $Users->list({ UID => $paysys_list->[0]->{uid}, COLS_NAME => 1, COLS_UPPER => 1 }) if ($self->{conf}->{PAYSYS_LOG});

  if ($Paysys->{TOTAL} && $paysys_list->[0]->{id}) {
    $self->{paysys_id} = $paysys_list->[0]->{id};
    return $paysys_list->[0]->{id}, $paysys_list->[0]->{status}, $paysys_list->[0];
  }

  return 0, 0, {};
}

#**********************************************************
=head2 paysys_info($attr) -

  Arguments:
    $attr
      PAYSYS_ID: int      - internal payment system identifier
      TRANSACTION_ID: str - externals payment system identifier

  Returns:
    $payment: hash - info about transaction

  #TODO: remove P.S. in next few months
  P.S renamed from paysys_get_full_info and removed old paysys_info logic

=cut
#**********************************************************
sub paysys_info {
  shift;
  my ($attr) = @_;

  return {} if (!$attr->{PAYSYS_ID} && !$attr->{TRANSACTION_ID});

  my $list = $Paysys->list({
    ID             => $attr->{PAYSYS_ID} || '_SHOW',
    TRANSACTION_ID => $attr->{TRANSACTION_ID} || '_SHOW',
    STATUS         => '_SHOW',
    PAYMENT_SYSTEM => '_SHOW',
    SUM            => '_SHOW',
    IP             => '_SHOW',
    STATUS         => '_SHOW',
    DATE           => '_SHOW',
    DATETIME       => '_SHOW',
    COLS_NAME      => 1,
    COLS_UPPER     => 1,
  });

  if ($Paysys->{TOTAL} == 1) {
    return $list->[0];
  }

  return {};
}

#**********************************************************
=head2 mk_log($message, $attr) - add data to logfile;

 Make log file for paysys request

  Arguments:
    $message -
    $attr
      PAYSYS_ID     - payment system ID
      REQUEST       - System Request
      REQUEST_BODY  - System Request
      REQUEST_TYPE  - System Request
      REPLY         - ABillS Reply
      SHOW          - print message to output
      LOG_FILE      - Log file. (Default: paysys_check.log)
      HEADER        - Print header
      DATA          - Make form log
      TYPE          - Request TYPE
      STATUS        - Request ABillS Status
      ERROR         - Error during validation of request

  Returns:

     TRUE or FALSE

  Examples:
    mk_log("Data for logfile", { PAYSYS_ID => '63' });


=cut
#**********************************************************
sub mk_log {
  my $self = shift;
  my ($message, $attr) = @_;

  my $base_dir = $main::base_dir // '';
  if (!$base_dir) {
    our $Bin;
    require FindBin;
    FindBin->import('$Bin');

    if ($Bin =~ m/\/abills(\/)/){
      $base_dir = substr($Bin, 0, $-[1]);
      $base_dir .= '/';
    }
  }

  my $paysys          = $attr->{PAYSYS_ID} || '';
  my $paysys_log_file = $attr->{LOG_FILE} || ($base_dir // '/usr/abills/') . 'var/log/paysys_check.log';

  if ($attr->{HEADER}) {
    print "Content-Type: text/plain\n\n";
  }

  if ($attr->{REPLY}) {
    $paysys .= " REPLY: $attr->{REPLY}";
  }

  if ($attr->{TYPE}) {
    $paysys .= " TYPE: $attr->{TYPE}";
  }

  if ($attr->{STATUS}) {
    $paysys .= " STATUS: $attr->{STATUS}";
  }

  if ($attr->{DATA} && ref $attr->{DATA} eq 'HASH') {
    foreach my $key (keys %{$attr->{DATA}}) {
      next if (in_array($key, [ 'index', '__BUFFER', 'root_index' ]));
      $message .= $key . ' => ' . (defined($attr->{DATA}->{$key}) ? $attr->{DATA}->{$key} : q{}) . "\n";
    }
  }
  elsif ($attr->{DATA} && ref $attr->{DATA} eq '') {
    $message .= $attr->{DATA};
  }

  if ($self->{conf}->{PAYSYS_LOG}) {
    my $buffer = $attr->{REQUEST_BODY} || q{};

    if (!$self->{insert_id}) {
      my $result = $Paysys->log_add({
        REQUEST        => $buffer,
        PAYSYS_IP      => $self->{REMOTE_ADDR},
        HTTP_METHOD    => $ENV{REQUEST_METHOD},
        SYSTEM_ID      => $attr->{PAYSYS_ID},
        ERROR          => $attr->{ERROR} || '',
        STATUS         => 1,
        TRANSACTION_ID => $self->{paysys_id},
        REQUEST_TYPE   => $attr->{REQUEST_TYPE} || 0,
        SUM            => $attr->{SUM} || 0
      });

      $self->{insert_id} = $result->{INSERT_ID} || 0;
      delete $Paysys->{INSERT_ID};
    }
    elsif ($self->{insert_id} && $attr->{REPLY}) {
      my $uid = 0;
      if ($Users->{TOTAL} && $Users->{TOTAL} > 0) {
        $uid = $Users->{list}->[0]->{uid} || $Users->{UID} || 0;
      }

      $Paysys->log_change({
        ID             => $self->{insert_id} || '--',
        REQUEST        => $buffer,
        RESPONSE       => $message,
        IP             => $self->{REMOTE_ADDR},
        HTTP_METHOD    => $ENV{REQUEST_METHOD},
        SYSTEM_ID      => $attr->{PAYSYS_ID},
        UID            => $uid || $attr->{UID},
        ERROR          => $attr->{ERROR} || '',
        STATUS         => 0,
        TRANSACTION_ID => $self->{ext_id},
        REQUEST_TYPE   => $attr->{REQUEST_TYPE} || 0,
        SUM            => $attr->{SUM} || 0
      });
    }
  }

  if (!defined($self->{conf}->{PAYSYS_LOG}) || ($self->{conf}->{PAYSYS_LOG} && $self->{conf}->{PAYSYS_LOG} != 2)) {
    if (open(my $fh, '>>', $paysys_log_file)) {
      if ($attr->{SHOW}) {
        print "$message";
      }

      if (!$main::DATE) {
        require POSIX;
        POSIX->import(qw( strftime ));
        $main::DATE = strftime("%Y-%m-%d", localtime(time));
        $main::TIME = strftime("%H:%M:%S", localtime(time));
      }

      $self->{REMOTE_ADDR} //= '127.0.0.1';
      print $fh "\n$main::DATE $main::TIME $self->{REMOTE_ADDR} $paysys =========================\n";

      if ($attr->{REQUEST}) {
        print $fh "$attr->{REQUEST}\n=======\n";
      }

      print $fh $message || q{};
      close($fh);
    }
    else {
      print "Content-Type: text/plain\n\n";
      print "Can't open log file '$paysys_log_file' $!\n";
      print "Error:\n";
      print "================\n$message================\n";
      die "Can't open log file '$paysys_log_file' $!\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 conf_gid_split($attr) - Find payment system parameters for some user group (GID)

  Arguments:
    $attr
      Required:
        PAYSYS_ID: int  - id of payment system
        Optional:
        GID?: int       - group identifier
        PARAM?: string  - nam of conf param
        VALUE?: string  - value of conf param

      Examples:
        Find parameters for processing of user

        $Paysys_Core->conf_gid_split({
          GID       => 10,
          PAYSYS_ID => $PAYSYSTEM_ID
        });

        Find parameters for processing of user based on Payment system service id

        $Paysys_Core->conf_gid_split({
          PARAMETER     => 'PAYSYS_PORTMONE_PAYEE_ID',
          VALUE         => 10,
          PAYSYS_ID     => $PAYSYSTEM_ID
        });

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub conf_gid_split {
  my $self = shift;
  my ($attr) = @_;

  return 1 if (!$attr->{PAYSYS_ID});

  $attr->{GID} //= 0;

  my $merchant_params = $Paysys->merchant_settings({
    PARAMETER   => '_SHOW',
    VALUE       => '_SHOW',
    %$attr,
    MERCHANT_ID => '_SHOW',
    COLS_NAME   => 1,
  });

  foreach my $param (@{$merchant_params}) {
    # in config stored in one type in, in merchant params in second type
    $param->{value} =~ s/\\"/"/g if ($param->{value});
    $self->{conf}->{$param->{param}} = $param->{value} || '';
  }

  my $merchant_id = 0;
  $merchant_id = $merchant_params->[0]->{merchant_id} || '--' if (scalar @{$merchant_params});

  return $self->_check_max_payments({ %$attr, MERCHANT_ID => $merchant_id });
}

#**********************************************************
=head2 _check_max_payments($attr) - Check is allowed make payment for user

  Arguments:
    $attr
      MERCHANT_ID        - ID of merchant which need to check
      MERCHANTS          - list of executed merchants, infinite loop

  Returns:

    0 - not allowed payment
    1 - allowed payment

=cut
#**********************************************************
sub _check_max_payments {
  my $self = shift;
  my ($attr) = @_;

  my $params = {};
  my $merchant_id = '--';

  return 1 if !$attr->{MERCHANT_ID};

  $params = $Paysys->merchant_params_info({ MERCHANT_ID => $attr->{MERCHANT_ID} });
  delete $Paysys->{errno};

  return 1 if (!scalar keys %{$params});

  my ($max_sum_key) = grep {/PAYMENTS_MAX_SUM/g} keys %{$params};
  return 1 if ((!$max_sum_key || !$params->{$max_sum_key}) && !$attr->{MERCHANT_ID});

  my ($payment_method_key) = grep {/PAYMENT_METHOD/g} keys %{$params};
  return 1 if ((!$payment_method_key || !$params->{$payment_method_key}) && !$attr->{MERCHANT_ID});

  my $payment_method = $params->{$payment_method_key || '--'};
  my $max_sum = $params->{$max_sum_key || ''} || 0;

  if ($max_sum) {
    my ($year, $month) = $main::DATE =~ /(\d{4})\-(\d{2})\-(\d{2})/g;
    $Payments->list({
      PAYMENT_METHOD => $payment_method,
      FROM_DATE      => "$year-$month-01",
      TO_DATE        => $main::DATE,
      TOTAL_ONLY     => 1
    });

    $Payments->{SUM} //= 0;
    delete $Payments->{errno};
  }

  if (!$max_sum || (defined $Payments->{SUM} && $max_sum > $Payments->{SUM})) {
    if ($attr->{MERCHANT_ID}) {
      foreach my $param (keys %{$params}) {
        $self->{conf}->{$param} = $params->{$param};
      }
    }

    return 1;
  }

  my ($merchant_id_key) = grep {/PAYMENTS_NEXT_MERCHANT/g} keys %{$params};
  if (!$merchant_id_key || !$params->{$merchant_id_key}) {
    if ($attr->{MERCHANT_ID} || $max_sum) {
      return 0;
    }
    else {
      return 1;
    }
  }

  $attr->{MERCHANT_ID} = $params->{$merchant_id_key || ''} || '--';
  $attr->{MERCHANTS} ||= [ $merchant_id ];
  return 0 if (in_array($attr->{MERCHANT_ID}, $attr->{MERCHANTS}));
  push @{$attr->{MERCHANTS}}, $attr->{MERCHANT_ID};

  return $self->_check_max_payments($attr);
}

#**********************************************************
=head2 _hide_text($text) - Hide text string

  Arguments:
     $text

  Returns:
    $hidden_text

=cut
#**********************************************************
sub _hide_text {
  shift;
  my ($text) = @_;

  my $hidden_text = '';
  if (!$text) {
    return q{};
  }

  my @join_test = ();
  $text =~ s/\s+$//gm;
  $text =~ s/\'/_/g;
  $text =~ s/&|%//g;
  my $str_utf8 = decode('UTF-8', $text);

  my @split_fio = split(/ /, $str_utf8);
  my @split_word = ();
  foreach my $key (@split_fio) {
    @split_word = split(//, $key);
    for (my $i = 0; $i < @split_word; $i++) {
      if ($i != 0 && ($i % 2 == 0 || $i % 3 == 0)) {
        $split_word[$i] = '*';
      }
    }
    my $fio_hiden_1 = join('', @split_word);
    push(@join_test, $fio_hiden_1);
  }

  $hidden_text = encode('UTF-8', join(' ', @join_test));

  return $hidden_text;
}

#**********************************************************
=head2 _paysys_check_user_second_bill() - check user in second bill;

  Arguments:
    $attr
      USER_ACCOUNT - user account

  Returns:
    $result, $user_info

=cut
#**********************************************************
sub _paysys_check_user_second_bill {
  my $self = shift;
  my ($attr) = @_;
  my $request_url = $self->{conf}->{SECOND_BILLING};

  my $response_second_billing = web_request($request_url, {
    REQUEST_PARAMS => {
      command => 'check',
      account => $attr->{USER_ACCOUNT},
      sum     => 1 },
    GET            => ($attr->{SOURCE}) ? undef : 1,
    CURL           => 1,
    REQUEST_COUNT  => 1,
    CURL_OPTIONS   => ' -L -k -s '
  });

  $response_second_billing =~ /(?<=<result>)(\d+)(?=<\/result>)/g;
  my $response_result = $1 // q{};
  $response_second_billing =~ /((?<=<comment>)(.*)(?=<\/comment>))/g;
  my $response_comment = $2 // q{};

  $self->mk_log("Status of Check: " . ($response_result || q{}) . ", comment: $response_comment");

  if ($response_result eq '0') {
    return 0, { comment => $response_comment };
  }
  else {
    return 1;
  }
}

#**********************************************************
=head2 _paysys_pay_second_bill() - check user in second bill;

  Arguments:
    $attr
      USER_ACCOUNT  - user account
      SUM           - user account
      EXT_ID        - id transaction
      PAYMENT_ID    - return payment id
  Returns:
    $result, $prv_txn (prv-txn(pay_id) - id transaction in our system)

=cut
#**********************************************************
sub _paysys_pay_second_bill {
  my $self = shift;
  my ($attr) = @_;
  my $request_url = $self->{conf}->{SECOND_BILLING};

  my $response_second_billing = web_request($request_url, {
    REQUEST_PARAMS => {
      command => 'pay',
      account => $attr->{USER_ACCOUNT},
      sum     => $attr->{SUM},
      txn_id  => $attr->{EXT_ID} },
    GET            => ($attr->{SOURCE}) ? undef : 1,
    CURL           => 1,
    REQUEST_COUNT  => 1,
    CURL_OPTIONS   => ' -L -k -s '
  });

  $response_second_billing =~ /(?<=<result>)(\d+)(?=<\/result>)/g;
  my $response_result = $1 // q{};
  $response_second_billing =~ /((?<=<prv_txn>)(.*)(?=<\/prv_txn>))/g;
  my $response_pay_id = $2 // q{};

  $self->mk_log("Status of Payment: " . ($response_result || q{}) . " PayId: $response_pay_id");

  if ($response_result eq '0') {
    if ($attr->{PAYMENT_ID}) {
      return 0, $response_pay_id;
    }
    else {
      return 0;
    }
  }
  else {
    return 1;
  }
}

#**********************************************************
=head2 _paysys_extra_check_user() - check with multi params

  USER_ACCOUNT      - for multi check fields put ARRAY:
  MAIN_CHECK_FIELD  - CHECK FIELD if present conf param PAYSYS_USER_MULTI_CHECK will be first in check
  EXTRA_USER_IDS    - If defined will be pushed to array to exist USER_ACCOUNT and CHECK_FIELD
                        Example ARRAY:
                          [{ CHECK_FIELD => 'LOGIN', USER_ACCOUNT => $FORM->{login} }, { CHECK_FIELD => 'UID', USER_ACCOUNT => $FORM->{uid} }]
  EXTRA_FIELDS      - Extra field
  COLS_UPPER        - if defined will used COLS_UPPER for $users->list function
  MAIN_GID          - main GID

=cut
#**********************************************************
sub _paysys_extra_check_user {
  my $self = shift;
  my ($attr) = @_;

  my $list = [];
  my @params_array = ({
    USER_ACCOUNT => $attr->{USER_ACCOUNT},
    CHECK_FIELD  => $attr->{MAIN_CHECK_FIELD}
  });
  my %EXTRA_FIELDS = ();

  if (scalar @{$attr->{EXTRA_USER_IDS}}) {
    foreach my $user_id (@{$attr->{EXTRA_USER_IDS}}) {
      next unless ($attr->{MAIN_CHECK_FIELD} || $attr->{USER_ACCOUNT});
      my $user_account = _expr($user_id->{USER_ACCOUNT}, $self->{conf}->{PAYSYS_ACCOUNT_EXPR});
      next if (!$user_account);

      push @params_array, $user_id;
    }
  }

  if ($attr->{EXTRA_FIELDS}) {
    %EXTRA_FIELDS = %{$attr->{EXTRA_FIELDS}};
  }

  foreach my $params (@params_array) {
    my @check_fields = ();

    if ($params->{USER_ACCOUNT}) {
      $params->{USER_ACCOUNT} =~ s/[,*;]//g;
    }

    if ($self->{conf}->{PAYSYS_USER_MULTI_CHECK}) {
      my @check_arr = split(/,\s?/, uc($self->{conf}->{PAYSYS_USER_MULTI_CHECK}));
      @check_fields = grep {$_ ne $params->{CHECK_FIELD}} @check_arr;
    }

    unshift @check_fields, $params->{CHECK_FIELD};

    foreach my $CHECK_FIELD (@check_fields) {

      if ($CHECK_FIELD eq 'PHONE') {
        if ($params->{USER_ACCOUNT} && $params->{USER_ACCOUNT} !~ /\d{10,}$/g) {
          $params->{USER_ACCOUNT} = '-------';
        }
        else {
          $params->{USER_ACCOUNT} = "*$params->{USER_ACCOUNT}*";
        }
      }

      # need to make empty if call the same object multiple times
      delete $Users->{errno};
      $list = $Users->list({
        $params->{CHECK_FIELD} => '_SHOW',
        LOGIN                  => '_SHOW',
        FIO                    => '_SHOW',
        DEPOSIT                => '_SHOW',
        CREDIT                 => '_SHOW',
        PHONE                  => '_SHOW',
        ADDRESS_FULL           => '_SHOW',
        GID                    => defined($attr->{MAIN_GID}) ? $attr->{MAIN_GID} : '_SHOW',
        DOMAIN_ID              => defined($ENV{DOMAIN_ID}) ? $ENV{DOMAIN_ID} : '_SHOW',
        DISABLE_PAYSYS         => '_SHOW',
        GROUP_NAME             => '_SHOW',
        DISABLE                => ($self->{conf}->{PAYSYS_SKIP_USERS_STATUS})
          ? join(',', map { "!$_" } split(',', $self->{conf}->{PAYSYS_SKIP_USERS_STATUS})) : '_SHOW',
        CONTRACT_ID            => '_SHOW',
        ACTIVATE               => '_SHOW',
        REDUCTION              => '_SHOW',
        BILL_ID                => '_SHOW',
        %EXTRA_FIELDS,
        $CHECK_FIELD           => $params->{USER_ACCOUNT} || '---',
        COLS_NAME              => 1,
        COLS_UPPER             => $attr->{COLS_UPPER} ? 1 : '',
        PAGE_ROWS              => 8,
      });

      delete $Users->{errno} if ($Users->{errno} && $CHECK_FIELD ne $check_fields[-1]);
      if ($Users->{TOTAL} && $Users->{TOTAL} > 0) {
        if (!$list->[0]->{lc($CHECK_FIELD)}) {
          $Users->{TOTAL} = 0;
          $list = [];
        }
        else {
          last;
        }
      }
    }

    delete $Users->{errno} if ($Users->{errno} && $params->{CHECK_FIELD} ne $params_array[-1]->{CHECK_FIELD});
    last if ($Users->{TOTAL} && $Users->{TOTAL} > 0);
  }

  return $list;
}

#**********************************************************
=head2 sum2commission($attr)

    Arguments:
      $sum: float             - payment sum
      $commission: float      - commission amount
      $commission_type: bool  - commission type
        0 - classical commission in percent
        1 - fixed commission sum
          $commission + $sum

  Returns:
    ARRAY
      $sum: float             - sum of payment
      $commission_sum: float  - calculated commission
      $total_sum: float       - sum with commission sum $sum + $commission_sum

=cut
#**********************************************************
sub sum2commission_sum {
  my $self = shift;
  my ($sum, $commission, $commission_type) = @_;

  my $total_sum = 0;
  my $commission_sum = 0;

  if ($commission_type) {
    $total_sum = $sum + $commission;
    $commission_sum = $commission;
  }
  else {
    $total_sum = $sum * (1 / (1 - (($commission || 0) / 100)));
    $commission_sum = sprintf('%.2f', ($total_sum - $sum));
  }

  return $sum, sprintf('%.2f', $commission_sum), sprintf('%.2f', $total_sum);
}

#**********************************************************
=head2 sum2commission($attr)

    Arguments:
      $sum: float             - payment sum
      $commission: float      - commission amount
      $commission_type: bool  - commission type
        0 - classical commission in percent
        1 - fixed commission sum
          $commission + $sum

  Returns:
    $final_amount: float -

=cut
#**********************************************************
sub commission_sum2sum {
  my $self = shift;
  my ($sum, $commission, $commission_type) = @_;

  my $final_amount = 0;

  if ($commission_type) {
    $final_amount = $sum - $commission;
  }
  else {
    $final_amount = ($sum / (1 / (1 - ($commission || 0) / 100)));
  }

  return sprintf('%.2f', $final_amount);
}

#**********************************************************
=head2 desc_former($attr)

    Arguments:
      $desc: str  - description for payment system
      $uid: int   - user id

  Returns:
    $desc: str - final description for payment system

=cut
#**********************************************************
sub desc_former {
  shift;
  my ($desc, $uid) = @_;

  return $desc if (!$desc || !$uid);

  $Users->info($uid);
  $Users->pi({ UID => $uid });

  my @vars = $desc =~ /\%(.+?)\%/g;

  foreach my $var (@vars) {
    $desc =~ s/\%$var\%/($Users->{$var} || '')/ge;
  }

  return $desc;
}

1;
