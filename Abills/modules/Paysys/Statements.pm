package Paysys::Statements;
=head Paysys_Base

  Paysys::Statements - module for advanced statements processing

  Paysys_Base - Old schema

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array is_number date_inc);
use Companies;
use Users;
use Paysys::Core;

my Users $Users;
my Companies $Companies;
my Paysys::Core $Paysys_Core;

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
  my ($db, $admin, $conf) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $conf,
    debug     => $conf->{PAYSYS_DEBUG} || 0,
  };

  bless($self, $class);

  $Users = Users->new($db, $admin, $conf);
  $Companies = Companies->new($db, $admin, $conf);
  $Paysys_Core = Paysys::Core->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 paysys_statement_processing() - execute external command

=cut
#**********************************************************
sub paysys_statement_processing {
  my $self = shift;
  my ($statement) = @_;

  return 1 if (!$self->{conf}->{PAYSYS_STATEMENTS_MULTI_CHECK});

  my @check_arr = split(/;\s?/, $self->{conf}->{PAYSYS_STATEMENTS_MULTI_CHECK});

  return 1 if (!scalar @check_arr);

  my $regex = $self->{conf}->{PAYSYS_STATEMENTS_MULTI_CHECK_REGEX} || '\s';

  my @values = split(/$regex/, $statement);
  @values = grep { defined $_ && $_ ne '' } @values;

  foreach my $check_field (@check_arr) {
    my ($field_name, $field_type, $field_regex, $extract_regex, $type) = split(/:/, $check_field);

    next if (!$field_name);
    $field_name = uc($field_name);

    my $pattern = $field_regex ? qr/$field_regex/ : '';
    my $search_str = '';

    if ($field_type && $field_type eq 'INT') {
      foreach my $value (@values) {
        next if (!is_number($value));
        next if ($pattern && $value !~ $pattern);
        if ($extract_regex) {
          ($value) = $value =~ /$extract_regex/gm;
        }
        $search_str .= "$value,";
      }
    }
    else {
      foreach my $value (@values) {
        next if ($pattern && $value !~ /$pattern/);
        if ($extract_regex) {
          ($value) = $value =~ /$extract_regex/gm;
        }
        if ($check_field eq 'FIO') {
          $search_str .= "*$value*,";
        }
        else {
          $search_str .= "$value,";
        }
      }
    }

    $search_str =~ s/,$//;

    my $CHECK_FIELD = $field_name || '';
    my $users_list = [];

    if ($type) {
      my $company = $Companies->list({
        COMPANY_ADMIN => '_SHOW',
        UID           => '_SHOW',
        COLS_NAME     => 1,
        $field_name   => $search_str || '--',
      });

      if ($Companies->{errno}) {
        delete $Companies->{errno};
        next;
      }

      if (scalar @{$company} != 1) {
        next;
      }

      # set user info of company admin
      $CHECK_FIELD = 'UID';
      $search_str = $company->[0]->{company_admin} || $company->[0]->{uid} || '--';
    }

    next if (!$search_str);

    $users_list = $Users->list({
      LOGIN          => '_SHOW',
      FIO            => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      PHONE          => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      GROUP_NAME     => '_SHOW',
      DISABLE        => '_SHOW',
      CONTRACT_ID    => '_SHOW',
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      BILL_ID        => '_SHOW',
      $CHECK_FIELD   => $search_str,
      _MULTI_HIT     => 1,
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
      SKIP_DEL_CHECK => 1,
      PAGE_ROWS      => 100,
    });

    if ($Users->{errno}) {
      delete $Users->{errno};
      next;
    }

    my %users_list = ();

    foreach my $user (@{$users_list}) {
      my $key = $user->{$field_name} || '--';

      $users_list{$key} = [] if (!exists $users_list{$key});
      push @{$users_list{$key}}, $user;
    }

    foreach my $key (keys %users_list) {
      my $matches = scalar @{$users_list{$key}} || 0;
      next if (!$matches);

      return 0, $users_list->[0] if ($matches < 2);

      #TODO: add logic of advanced address search

      next if ($matches > 1 && $field_name ne 'FIO');

      my $matched_user = '';

      foreach my $user_obj (@{$users_list{$key}}) {
        my @fio = split(/\s/, lc($user_obj->{FIO}));
        @fio = grep { defined $_ && $_ ne '' } @fio;

        my $fio_pattern = '(?=.*' . join(')(?=.*', map { quotemeta } @fio) . ')';

        if (lc($statement) =~ /$fio_pattern/) {
          if ($matched_user) {
            $matched_user = '';
            last;
          }
          else {
            $matched_user = $user_obj;
          }
        }
      }

      return 0, $matched_user if ($matched_user);
    }
  }

  return 1;
}

#**********************************************************
=head2 paysys_edrpou_check($edrpou)

  Arguments:
    $merchant
    $attr

  Returns:

=cut
#**********************************************************
sub paysys_edrpou_check {
  my $self = shift;
  my ($edrpou, $CHECK_FIELD) = @_;

  return '' if (!$edrpou);

  my $check_field = (length($edrpou) == 8) ? 'EDRPOU' : 'TAX_NUMBER';
  my $company = $Companies->list({
    COMPANY_ADMIN => '_SHOW',
    COLS_NAME     => 1,
    $check_field  => $edrpou,
  });

  my $uid = (!$Companies->{errno} && scalar @{$company}) ? ($company->[0]->{company_admin} || $company->[0]->{uid}) : '';

  return $uid if (($uid || length($edrpou) == 8) && $CHECK_FIELD eq 'UID');

  my $users = $Users->list({
    $CHECK_FIELD => '_SHOW',
    TAX_NUMBER   => $uid ? '_SHOW' : $edrpou,
    FIO          => '_SHOW',
    LOGIN        => '_SHOW',
    COLS_NAME    => 1,
    COLS_UPPER   => 1,
    PAGE_ROWS    => 2
  });

  if (!$uid && !$Users->{errno} && scalar(@$users) && scalar(@$users) == 1) {
    return $users->[0]->{$CHECK_FIELD} || '';
  }

  return $uid;
}

#**********************************************************
=head2 paysys_statement_transaction($payment, $report_data, $reg_payments)

  Arguments:
    $payment: obj - data about payment
    $attr: obj - extra params for process
      TRANSACTION_PREFIX_CHECK: bool - check is
      TRANSACTION_AS_MD5:

  Returns:

=cut
#**********************************************************
sub paysys_statement_transaction {
  my $self = shift;
  my ($payment, $report_data, $reg_payments, $plugin_conf) = @_;

  my $PAYSYSTEM_SHORT_NAME = $plugin_conf->{PAYSYSTEM_SHORT_NAME};
  my ($transaction, $ext_id) = ('', '');

  # check is already present payment from other payment system
  if ($report_data->{TRANSACTION_PREFIX_CHECK}) {
    $transaction = $self->_paysys_report_transaction_prefix_check($payment, $report_data, $reg_payments);
    $ext_id = $transaction;
  }

  # create transaction with custom format if it present
  if (!$transaction) {
    if ($report_data->{TRANSACTION_FORMAT}) {
      foreach my $format (@{$report_data->{TRANSACTION_FORMAT}}) {
        if ($format->{type} eq 'field') {
          Encode::_utf8_off($payment->{$format->{value}});
          $transaction .=  $payment->{$format->{value}} || '';
        }
        else {
          $transaction .= $format->{value} || '';
        }
      }

      if ($report_data->{TRANSACTION_AS_MD5}) {
        require Digest::MD5;
        Digest::MD5->import('md5_hex');
        $transaction = Digest::MD5::md5_hex($transaction);
      }
    }
    else {
      $transaction = $payment->{$report_data->{IMPORT_FIELD}} || '';
    }
  }

  if (!$ext_id) {
    $ext_id = $report_data->{SKIP_SYSTEM_PREFIX} ? $transaction : "$PAYSYSTEM_SHORT_NAME:$transaction";
  }

  return $transaction, $ext_id;
}

#**********************************************************
=head2 _paysys_report_transaction_prefix_check($payment, $report_data, $reg_payments)

=cut
#**********************************************************
sub _paysys_report_transaction_prefix_check {
  my $self = shift;
  my ($payment, $report_data, $reg_payments) = @_;

  foreach my $tran_check (@{$report_data->{TRANSACTION_PREFIX_CHECK}}) {
    if ($tran_check->{REGEX}) {
      my ($transaction) = $payment->{$tran_check->{FIELD}} =~ /$tran_check->{REGEX}/gm;

      next if (!$transaction);

      if (!$tran_check->{TRAN_PREFIX} && $reg_payments->{$transaction}) {
        return $transaction;
      }

      foreach my $pref (@{$tran_check->{TRAN_PREFIX}}) {
        return "$pref:$transaction" if ($reg_payments->{"$pref:$transaction"});
      }
    }
  }

  return '';
}

#**********************************************************
=head2 paysys_statements_periodic($reg_payments, $statements_data, $Payment_Plugin)

=cut
#**********************************************************
sub paysys_statements_periodic {
  my $self = shift;
  my ($reg_payments, $statements_data, $Payment_Plugin) = @_;

  my $PAYSYSTEM_SHORT_NAME = $Payment_Plugin->{SHORT_NAME};
  my $payments = $statements_data->{PAYMENTS} || [];

  if (ref $payments eq 'ARRAY' && !scalar @{$payments}) {
    return {
      ERROR => 'No payments',
    };
  }

  my $not_success_statements = 0;
  my $success_statements = 0;
  my $exists_statements = 0;
  my %error_codes = ();

  foreach my $payment (@{$payments}) {
    my ($transaction_id, $ext_id) = $self->paysys_statement_transaction($payment, $statements_data, $reg_payments, {
      PAYSYSTEM_SHORT_NAME => $PAYSYSTEM_SHORT_NAME
    });

    if ($payment->{_SKIP_PAYMENT}) {
      print "EXT_ID: $ext_id - $payment->{_SKIP_PAYMENT}\n\n";
      next;
    }
    elsif ($payment->{_DEPOSIT_PAYMENT}) {
      print "EXT_ID: $ext_id - IS DEBIT PAYMENT SKIP\n\n";
      next;
    }
    elsif (exists($reg_payments->{$ext_id})) {
      $exists_statements++;
      print "EXT_ID: $ext_id - PAYMENT ALREADY ADDED. LOGIN: $reg_payments->{$ext_id}->{login} UID: $reg_payments->{$ext_id}->{uid}\n\n";
      next;
    }
    elsif ($payment->{_ERROR}) {
      print "EXT_ID: $ext_id - ERROR $payment->{_ERROR}\n\n";
      next;
    }

    my $user_id = '';
    my $desc = $payment->{$statements_data->{IMPORT_FIELDS}->{DESC}} || '';
    print "EXT_ID: $ext_id START SEARCHING USER_ID\n";
    print "DESC OF PAYMENT: $desc\n" if ($desc);

    if ($statements_data->{EDRPOU_CHECK}) {
      my $CHECK_FIELD = $statements_data->{CHECK_FIELD} || 'UID';
      $user_id = $self->paysys_edrpou_check($payment->{EDRPOU}, $CHECK_FIELD);
      print "USER_ID FOUND - $user_id. FOUND BY EDRPOU $payment->{EDRPOU}\n" if ($user_id);
    }

    if (!$user_id && $Payment_Plugin->can('_search_user')) {
      $user_id = $Payment_Plugin->_search_user($payment);
      print "USER_ID FOUND - $user_id. FOUND BY REGEX.\n" if ($user_id);
    }

    if (!$user_id) {
      $not_success_statements++;
      print "USER_ID NOT FOUND NEXT\n";
      print "ERROR - TRANSACTION: $ext_id ERROR:  STATUS: 1\n\n";
      next;
    }

    my $result = $Payment_Plugin->payment_import({
      ID   => $transaction_id,
      UID  => $user_id,
      SUM  => $payment->{$statements_data->{IMPORT_FIELDS}->{SUM}} || 0,
      DESC => $desc || '',
      DATE => $payment->{$statements_data->{IMPORT_FIELDS}->{DATE}} || '',
    });

    if ($result->{status_code} == 0) {
      $success_statements++;
      print "OK - TRANSACTION: $ext_id ID:  STATUS: 0\n\n"
    }
    else {
      $error_codes{$result->{status_code}} = ($error_codes{$result->{status_code}} // 0) + 1;
      $not_success_statements++;
      print "ERROR - TRANSACTION: $ext_id ERROR:  STATUS: $result->{status_code}\n\n";
    }
  }

  print "\n------------------------RESULTS------------------------\n";
  print "SUCCESS STATEMENTS: $success_statements\n";
  print "ERROR STATEMENTS: $not_success_statements\n";
  print "EXISTS STATEMENTS: $exists_statements\n";

  return 1;
}

#**********************************************************
=head2 paysys_get_reg_payments($attr) - Get register payments

  Arguments:
    $attr
      DATE_FROM
      DATE_TO
      EXT_ID

  Results:
    \%reg_payments_list

=cut
#**********************************************************
sub paysys_get_reg_payments {
  my $self = shift;
  my ($attr) = @_;

  require Payments;
  Payments->import();
  my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});
  my %reg_payments_list = ();

  require POSIX;
  POSIX->import(qw(mktime strftime));

  my ($Y, $M, $D) = split(/-/, ($attr->{DATE_FROM} || $main::DATE), 3);
  ($Y, $M, $D) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) - (86400 * 7)))));

  my $payments_list = $Payments->list({
    FROM_DATE => "$Y-$M-$D",
    TO_DATE   => date_inc($main::DATE),
    EXT_ID    => ($attr->{TRANSACTION_PREFIXES}) ? $attr->{TRANSACTION_PREFIXES} : ($attr->{EXT_ID} || q{}) . ':*',
    LOGIN     => '_SHOW',
    SUM       => '_SHOW',
    PAGE_ROWS => 100000,
    COLS_NAME => 1
  });

  foreach my $payment (@$payments_list) {
    $reg_payments_list{$payment->{ext_id}} = {
      id       => $payment->{id},
      uid      => $payment->{uid},
      sum      => $payment->{sum},
      login    => $payment->{login},
      datetime => $payment->{datetime},
    };
  }

  return \%reg_payments_list;
}

1;
