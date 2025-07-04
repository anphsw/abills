#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More;

use lib '../../../../lib/';

# defines imported variable and modules correctly because it is not direct load
BEGIN {
  diag("Modules initialise");
  subtest 'load_modules' => sub {
    plan tests => 7;

    use_ok('Abills::Init', qw($db $admin %conf $DATE $TIME));
    use_ok('Abills::Base', qw(parse_arguments));
    use_ok('Paysys::Core');
    use_ok('Abills::Misc');
    use_ok('Paysys');
    use_ok('Payments');
    use_ok('Users');
  };
}

my Paysys::Core $Paysys_Core;
my Paysys $Paysys;
my Payments $Payments;
my Users $Users;

subtest 'init_objects' => sub {
  plan tests => 4;

  $Paysys_Core = new_ok('Paysys::Core' => [ $db, $admin, \%conf ]);
  $Paysys = new_ok('Paysys' => [ $db, $admin, \%conf ]);
  $Payments = new_ok('Payments' => [ $db, $admin, \%conf ]);
  $Users = new_ok('Users' => [ $db, $admin, \%conf ]);
};

my $argv = parse_arguments(\@ARGV);
my $uid = $argv->{UID};

if (!$uid) {
  plan skip_all => 'Parameter UID=YOUR_UID is not define';
}
else {
  plan tests => 10;
}

# calculate commission
subtest 'sum2commission_sum' => sub {
  plan tests => 6;

  diag("Sum with percent commission");
  my ($sum, $commission_sum, $total_sum) = $Paysys_Core->sum2commission_sum(325, 1.5, 0);

  cmp_ok($sum, '==', 325, 'Sum is valid 11');
  cmp_ok($commission_sum, '==', 4.95, 'Commission sum is valid 4.95');
  cmp_ok($total_sum, '==', 329.95, 'Total sum valid 329.95');

  diag("Sum with static commission");
  ($sum, $commission_sum, $total_sum) = $Paysys_Core->sum2commission_sum(11, 3.5, 1);

  cmp_ok($sum, '==', 11, 'Sum is valid 11');
  cmp_ok($commission_sum, '==', 3.5, 'Commission sum is valid 3.5');
  cmp_ok($total_sum, '==', 14.5, 'Total sum valid 14.5');
};

# calculate commission
subtest 'commission_sum2sum' => sub {
  plan tests => 2;

  diag("Sum with percent commission");
  my $final_amount = $Paysys_Core->commission_sum2sum(329.95, 1.5, 0);

  cmp_ok($final_amount, '==', 325, 'Final amount valid 325');

  diag("Sum with static commission");
  $final_amount = $Paysys_Core->commission_sum2sum(14.5, 3.5, 1);

  cmp_ok($final_amount, '==', 11, 'Final amount valid 11');
};

# descriptions
subtest 'desc_former' => sub {
  plan tests => 3;

  my $description = 'UID: %UID%';

  my ($desc) = $Paysys_Core->desc_former('', $uid);
  cmp_ok($desc, 'eq', '', 'Without description');

  ($desc) = $Paysys_Core->desc_former($description, 0);
  cmp_ok($desc, 'eq', $description, 'Without UID');

  ($desc) = $Paysys_Core->desc_former($description, $uid);
  cmp_ok($desc, 'eq', "UID: $uid", "Description is 'UID: $uid'");
};

# check user
subtest 'paysys_check_user' => sub {
  plan tests => 9;

  my @expected_keys = ('CONTRACT_DATE', 'contract_date', 'login', 'GROUP_NAME', 'RECOMENDED_PAY', 'CREDIT', 'DISABLE_PAYSYS', 'domain_id', 'ACTIVATE', 'TOTAL_DEBET', 'GID', 'DOMAIN_ID', 'bill_id', 'REDUCTION', 'deposit', 'DEPOSIT', 'phone', 'disable_paysys', 'credit', 'CONTRACT_ID', 'ADDRESS_FULL', 'UID', 'uid', 'contract_id', 'PHONE', 'fio', 'reduction', 'BILL_ID', 'group_name', 'gid', 'LOGIN', 'address_full', 'activate', 'FIO');
  my %check_params = (
    CHECK_FIELD    => 'UID',
    USER_ID        => $argv->{UID},
    RECOMENDED_PAY => 1,
    EXTRA_FIELDS   => {
      CONTRACT_DATE => '_SHOW',
    }
  );

  diag("Check exists user");
  my ($result_code, $user) = $Paysys_Core->paysys_check_user(\%check_params);

  cmp_ok($result_code, '==', 0, 'Status code is 0');
  isa_ok($user, 'HASH', 'Result user');

  my @user_keys = keys %{$user};

  is_deeply([ sort @user_keys ], [ sort @expected_keys ], 'All base keys present in user hash');

  SKIP: {
    diag("Check attr SKIP_FIO_HIDE");
    skip "FIO is empty impossible to check _hide_text", 4 if (!$user->{FIO});

    like($user->{FIO}, '/[*]/', "User fio is hidden '$user->{FIO}'");

    # check is valid showing normal fio
    ($result_code, $user) = $Paysys_Core->paysys_check_user({
      %check_params,
      SKIP_FIO_HIDE => 1
    });

    cmp_ok($result_code, '==', 0, 'Status code is 0');
    isa_ok($user, 'HASH', 'Result user');
    unlike($user->{FIO}, '/[*]/', "User fio is not hidden '$user->{FIO}'");
  }

  diag("Check not exists user");
  ($result_code, $user) = $Paysys_Core->paysys_check_user({
    %check_params,
    CHECK_FIELD => 'PHONE',
    USER_ID     => '-1000000000',
  });

  cmp_ok($result_code, '==', 1, 'Status code is 1');
  is($user, undef, 'Result user is undef');
};

# paysys pay
subtest 'paysys_pay' => sub {
  plan tests => 38;

  my $transaction = 100000 + int(rand(10000));
  my %payment_params = (
    PAYMENT_SYSTEM    => 'ABillS',
    PAYMENT_SYSTEM_ID => 1,
    CHECK_FIELD       => 'UID',
    USER_ID           => $uid,
    SUM               => 1.91,
    EXT_ID            => $transaction,
    DATE              => "$DATE $TIME",
    MK_LOG            => 1,
    PAYMENT_ID        => 1,
    PAYMENT_DESCRIBE  => 'ABillS Test payment',
  );

  _paysys_pay_not_valid_params(\%payment_params);

  # create transaction with status 1
  diag("Create transaction with error 1");

  $transaction = 200000 + int(rand(10000));

  my ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %payment_params,
    EXT_ID => $transaction,
    ERROR  => 1
  });

  cmp_ok($paysys_status, '==', 1, 'Status code is 1');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");


  # try to change transaction status to canceled
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    PAYMENT_SYSTEM    => 'ABillS',
    PAYMENT_SYSTEM_ID => 1,
    PAYSYS_ID         => $payments_id,
    ERROR             => 3,
    PAYMENT_ID        => 1
  });

  diag("Change transaction status from 1 to 3");
  cmp_ok($paysys_status, '==', 3, 'Status code is 3');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");


  # try to make payment
  diag("Make payment from transaction with status 0");
  $transaction = 300000 + int(rand(10000));
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %payment_params,
    EXT_ID => $transaction,
    ERROR  => 1
  });

  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    PAYMENT_SYSTEM    => 'ABillS',
    PAYMENT_SYSTEM_ID => 1,
    PAYSYS_ID         => $payments_id,
    PAYMENT_ID        => 1
  });

  cmp_ok($paysys_status, '==', 0, 'Status code is 0');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");
  # check is really present transaction in system
  _paysys_info($payments_id);

  _payment_after_transaction();
  _transaction_after_payment(\%payment_params);
};

# paysys pay cancel
subtest 'paysys_pay_cancel' => sub {
  plan tests => 16;

  # No valid params
  diag('No attr PAYSYS_ID or TRANSACTION_ID');
  my ($result, $payment_id) = $Paysys_Core->paysys_pay_cancel();

  cmp_ok($result, '==', 11, 'Cancel status 11');
  is($payment_id, undef, 'Payment id is undef');

  # No valid params
  diag('No attr PAYSYS_ID or TRANSACTION_ID, but with RETURN_CANCELED_ID');
  ($result, $payment_id) = $Paysys_Core->paysys_pay_cancel({ RETURN_CANCELED_ID => 1 });

  cmp_ok($result, '==', 11, 'Cancel status 11');
  cmp_ok(0, '==', 0, 'Payment id is 0');

  diag('Not exists transaction id');
  ($result, $payment_id) = $Paysys_Core->paysys_pay_cancel({ TRANSACTION_ID => 'NONSAS921921', RETURN_CANCELED_ID => 1 });

  cmp_ok($result, '==', 8, 'Cancel status 8');
  cmp_ok(0, '==', 0, 'Payment id is 0');

  diag('Not exists paysys id');
  ($result, $payment_id) = $Paysys_Core->paysys_pay_cancel({ PAYSYS_ID => 4294967291, RETURN_CANCELED_ID => 1 });

  cmp_ok($result, '==', 8, 'Cancel status 8');
  cmp_ok(0, '==', 0, 'Payment id is 0');

  my $paysys_id = _payment_after_transaction(600000 + int(rand(10000)));

  # cancel payment
  ($result, $payment_id) = $Paysys_Core->paysys_pay_cancel({ PAYSYS_ID => $paysys_id, RETURN_CANCELED_ID => 1 });

  cmp_ok($result, '==', 0, 'Cancel status 0');
  cmp_ok($payment_id, '!=', 0, "Payment is not null '$payment_id'");

  # try again cancel payment
  ($result, $payment_id) = $Paysys_Core->paysys_pay_cancel({ PAYSYS_ID => $paysys_id, RETURN_CANCELED_ID => 1 });

  cmp_ok($result, '==', 10, 'Cancel status 10');
  cmp_ok(0, '==', 0, 'Payment id is 0');
};

# check payment status in paysys log
subtest 'paysys_pay_check' => sub {
  plan tests => 11;

  diag("Create payment");
  my $transaction_id = 700000 + int(rand(10000));
  my $payment_id = _payment_after_transaction($transaction_id);

  diag("Check payment");
  my ($paysys_id, $paysys_status, $transaction) = $Paysys_Core->paysys_pay_check({
    PAYSYS_ID => $payment_id,
  });

  cmp_ok($paysys_id, '==', $payment_id, "Paysys id is $payment_id");
  cmp_ok($paysys_status, '==', 2, 'Paysys status is 2');
  isa_ok($transaction, 'HASH', 'Transaction is');
  cmp_ok($transaction->{transaction_id}, 'eq', "ABillS:$transaction_id", "Transaction is $transaction->{transaction_id}");

  diag("Check not exists payment");
  ($paysys_id, $paysys_status, $transaction) = $Paysys_Core->paysys_pay_check({PAYSYS_ID => 4294967291});
  cmp_ok($paysys_id, '==', 0, "Paysys id is 0");
  is($paysys_status, 0, 'Paysys status is 0');
  is_deeply($transaction, {}, 'Transaction is undef');
};

# paysys info
subtest 'paysys_info' => sub {
  plan tests => 4;

  diag("Not valid parameters test. Correct test were before");

  my $transaction = $Paysys_Core->paysys_info();

  isa_ok($transaction, 'HASH', 'Transaction is');
  ok(scalar keys %{$transaction} == 0, 'Transaction is empty hash');

  my $second_transaction = $Paysys_Core->paysys_info({PAYSYS_ID => 4294967291});

  isa_ok($second_transaction, 'HASH', 'Second transaction is');
  ok(scalar keys %{$second_transaction} == 0, 'Second transaction is empty hash');
};

#**********************************************************
=head2 _paysys_pay_not_valid_params()

=cut
#**********************************************************
sub _paysys_pay_not_valid_params {
  my $payment_params = shift;

  # not valid parameters
  diag("Try make payment with not valid parameters");

  diag("Pass empty params");
  my ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay();
  cmp_ok($paysys_status, '==', 1, 'Status code is 1');
  is($payments_id, undef, 'Payment id is undef');

  diag("No exists user");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    CHECK_FIELD => 'PHONE',
    USER_ID     => '-1000000000',
  });

  cmp_ok($paysys_status, '==', 1, 'Status code is 1');
  is($payments_id, undef, 'Payment id is undef');

  diag("Sum is lover than 0");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    SUM => -1,
  });

  cmp_ok($paysys_status, '==', 5, 'Status code is 5');
  is($payments_id, undef, 'Payment id is undef');

  diag("Sum is lover than MIN_SUM");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    SUM     => 10,
    MIN_SUM => 11
  });

  cmp_ok($paysys_status, '==', 6, 'Status code is 6');
  is($payments_id, undef, 'Payment id is undef');

  diag("Sum is bigger than MAX_SUM");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    SUM     => 10,
    MAX_SUM => 9
  });

  cmp_ok($paysys_status, '==', 7, 'Status code is 7');
  is($payments_id, undef, 'Payment id is undef');

  diag("EXT_ID is no_ext_id");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    EXT_ID => 'no_ext_id',
  });

  cmp_ok($paysys_status, '==', 29, 'Status code is 29');
  is($payments_id, undef, 'Payment id is undef');

  diag("PAYSYS_ID not exists");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    PAYSYS_ID => 99999999999,
  });

  cmp_ok($paysys_status, '==', 8, 'Status code is 8');
  is($payments_id, undef, 'Payment id is undef');

  diag("ORDER_ID not exists");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    ORDER_ID => 99999999999,
  });

  cmp_ok($paysys_status, '==', 8, 'Status code is 8');
  is($payments_id, undef, 'Payment id is undef');

  # simple payment with transaction and payment creation
  diag("Create payment and transaction for it");

  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay($payment_params);

  cmp_ok($paysys_status, '==', 0, 'Status code is 0');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");


  # one more time try make payment, but with exists $payments_id
  diag("Try crate duplicate payment with existing payment id '$payments_id'");
  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    PAYSYS_ID => $payments_id,
  });

  cmp_ok($paysys_status, '==', 9, 'Status code is 9');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");

  # check is really present transaction in system
  _paysys_info($payments_id);
}

#**********************************************************
=head2 _payment_after_transaction()

=cut
#**********************************************************
sub _payment_after_transaction {
  my $transaction_id = shift;

  diag("Making payment after adding payment with Paysys object");
  my $transaction = $transaction_id || 400000 + int(rand(10000));
  $Paysys->add({
    SYSTEM_ID      => 1,
    SUM            => 1.99,
    UID            => $uid,
    IP             => $ENV{REMOTE_ADDR},
    TRANSACTION_ID => "ABillS:$transaction",
    INFO           => 'Test payment after transaction',
    PAYSYS_IP      => $ENV{REMOTE_ADDR},
    STATUS         => 1,
  });

  ok($Paysys->{INSERT_ID}, 'Add transaction with id ' . ($Paysys->{INSERT_ID} || 0));

  my ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    PAYMENT_SYSTEM    => 'ABillS',
    PAYMENT_SYSTEM_ID => 1,
    SUM               => 2,
    NEW_SUM           => 1,
    PAYSYS_ID         => $Paysys->{INSERT_ID},
    PAYMENT_ID        => 1
  });

  cmp_ok($paysys_status, '==', 0, 'Status code is 0');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");

  # check is really present transaction in system
  _paysys_info($payments_id);

  return $payments_id;
}

#**********************************************************
=head2 _transaction_after_payment()

=cut
#**********************************************************
sub _transaction_after_payment {
  my $payment_params = shift;

  my $transaction = 500000 + int(rand(10000));
  $Users->info($uid);

  $Payments->add($Users, {
    SUM            => 1.98,
    DATE           => "$DATE $TIME",
    DESCRIBE       => '',
    INNER_DESCRIBE => 'Test payment adding before paysys_pay call',
    METHOD         => 2,
    EXT_ID         => "ABillS:$transaction",
    CHECK_EXT_ID   => "ABillS:$transaction",
    USER_INFO      => $Users,
  });

  ok($Payments->{INSERT_ID}, 'Add payment with id ' . ($Payments->{INSERT_ID} || 0));

  my ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    EXT_ID => $transaction,
  });

  cmp_ok($paysys_status, '==', 3, 'Status code is 3');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");

  ($paysys_status, $payments_id) = $Paysys_Core->paysys_pay({
    %{$payment_params},
    EXT_ID => $transaction,
  });

  cmp_ok($paysys_status, '==', 13, 'Status code is 13');
  cmp_ok($payments_id, '!=', 0, "Payment is not null '$payments_id'");

  # check is really present transaction in system
  _paysys_info($payments_id);
}

#**********************************************************
=head2 _paysys_info()

=cut
#**********************************************************
sub _paysys_info {
  my ($payments_id) = @_;

  subtest 'paysys_info' => sub {
    plan tests => 3;

    my $transaction = $Paysys_Core->paysys_info({
      PAYSYS_ID => $payments_id || '',
    });

    isa_ok($transaction, 'HASH', 'Transaction is');

    my @keys = ('ext_id', 'domain_id', 'system_id', 'uid', 'id', 'transaction_id', 'status', 'ip', 'datetime', 'login', 'sum',
      'EXT_ID', 'DOMAIN_ID', 'SYSTEM_ID', 'UID', 'ID', 'TRANSACTION_ID', 'STATUS', 'IP', 'DATETIME', 'LOGIN', 'SUM');
    my @transaction_keys = keys %{$transaction};

    is_deeply([ sort @keys ], [ sort @transaction_keys ], 'All base keys present in transaction hash');
    cmp_ok($payments_id, '==', $transaction->{id}, "Correct transaction found");
  }
}

done_testing();

1;
