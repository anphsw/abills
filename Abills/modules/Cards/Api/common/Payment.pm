package Cards::Api::common::Payment;
=head1 NAME

  Docs Invoices common functions for admin and user API

  For Endpoints:
    /cards/:uid/payment
    /user/cards/payment

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;
use Control::Errors;

use Cards;
use Users;

my Cards $Cards;
my Users $Users;
my Control::Errors $Errors;

# TODO: make status from Constants.pm after Cards API migration
my @status = ('enable', 'disable', 'used', 'deleted', 'returned', 'processing', 'Transferred to production');

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
  };

  bless($self, $class);

  $Cards = Cards->new($db, $admin, $conf);
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 docs_invoices_period($attr)

  ARGS:
    UID
    NEXT_PERIOD
    NEW_INVOICES
    USER_API_CALL

=cut
#**********************************************************
#**********************************************************
=head2 _cards_payment($path_params, $query_params, $attr)

  Arguments:
    $path_params: object  - hash of params from request path
    $query_params: object - hash of query params from request

  Returns:
    $result

=cut
#**********************************************************
sub _cards_payment {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $user_info = $Users->info($path_params->{uid});

  if ($self->{conf}->{CARDS_SKIP_COMPANY} && $user_info->{COMPANY_ID}) {
    return $Errors->throw_error(1060001);
  }

  if (!$query_params->{PIN}) {
    return $Errors->throw_error(1060002, { lang_vars => { FIELD => 'pin' } });
  }

  if (!$query_params->{SERIAL} && !$self->{conf}->{CARDS_PIN_ONLY}) {
    return $Errors->throw_error(1060003, { lang_vars => { FIELD => 'serial' } });
  }

  my $bruteforce_lim = $self->{conf}->{CARDS_BRUTE_LIMIT} ? $self->{conf}->{CARDS_BRUTE_LIMIT} : 5;
  $Cards->bruteforce_list({ UID => $user_info->{UID} });

  if ($Cards->{BRUTE_COUNT} && $Cards->{BRUTE_COUNT} >= $bruteforce_lim) {
    return $Errors->throw_error(1060004, { lang_vars => { COUNT => $Cards->{BRUTE_COUNT}, LIMIT => $bruteforce_lim } });
  }

  my DBI $db = $self->{db}->{db};
  $db->{AutoCommit} = 0;

  $Cards->cards_info({
    SERIAL   => $self->{conf}->{CARDS_PIN_ONLY} ? '_SHOW' : $query_params->{SERIAL},
    PIN      => $query_params->{PIN},
    PAYMENTS => 1,
  });

  if ($Cards->{errno}) {
    if ($Cards->{errno} == 2) {
      $Cards->bruteforce_add({ UID => $user_info->{UID}, PIN => $query_params->{PIN} });
      $db->commit();
      $db->{AutoCommit} = 1;
      return $Errors->throw_error(1060005);
    }
    else {
      $db->{AutoCommit} = 1;
      return $Errors->throw_error(1060006, { lang_vars => { ERROR => $Cards->{errno} } });
    }
  }
  elsif ($Cards->{EXPIRE_STATUS} == 1) {
    $db->{AutoCommit} = 1;
    return $Errors->throw_error(1060007, { lang_vars => { EXPIRE => $Cards->{EXPIRE} } });
  }
  elsif ($Cards->{TOTAL} < 1 || !$Cards->{NUMBER}) {
    $Cards->bruteforce_add({ UID => $user_info->{UID}, PIN => $query_params->{PIN} });
    $db->commit();
    $db->{AutoCommit} = 1;
    return $Errors->throw_error(1060008);
  }
  elsif ($user_info->{GID} && $Cards->{ALLOW_GID} && !in_array($user_info->{GID}, [ split(/,\s?/, $Cards->{ALLOW_GID}) ])) {
    $db->{AutoCommit} = 1;
    return $Errors->throw_error(1060009);
  }
  elsif ($Cards->{SUM} < 1) {
    $db->{AutoCommit} = 1;
    return $Errors->throw_error(1060010);
  }
  elsif ($Cards->{UID} && $Cards->{UID} == $user_info->{UID}) {
    $db->{AutoCommit} = 1;
    return $Errors->throw_error(1060011);
  }
  elsif ($Cards->{STATUS} != 0) {
    $db->{AutoCommit} = 1;
    return $Errors->throw_error(1060012, { lang_vars => { STATUS => ($status[$Cards->{STATUS}] || '') } });
  }
  else {
    if ($Cards->{UID}) {
      my $user = Users->new($self->{db}, $self->{admin}, $self->{conf});
      $user->info($Cards->{UID});

      require Log;
      Log->import();
      my $Log = Log->new($self->{db}, $self->{conf});

      $Log->log_list({ USER => $user->{LOGIN} });
      if ($Log->{TOTAL} > 0) {
        $db->{AutoCommit} = 1;
        return $Errors->throw_error(1060013);
      }
    }

    require Payments;
    Payments->import();
    my $Payments = Payments->new($self->{db}, $self->{admin}, $self->{conf});

    ::cross_modules('pre_payment', {
      USER_INFO    => $user_info,
      SUM          => $Cards->{SUM},
      SKIP_MODULES => 'Cards,Sqlcmd',
      QUITE        => 1,
      SILENT       => 1,
      METHOD       => 2,
      timeout      => 8,
      FORM         => {}
    });

    my $cards_number_length = $self->{conf}->{CARDS_NUMBER_LENGTH} || 11;
    $Payments->add($user_info, {
      SUM          => $Cards->{SUM},
      METHOD       => 2,
      DESCRIBE     => sprintf("%s%." . $cards_number_length . "d", $Cards->{SERIAL}, $Cards->{NUMBER}),
      EXT_ID       => "$Cards->{SERIAL}$Cards->{NUMBER}",
      CHECK_EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}",
      TRANSACTION  => 1
    });

    if (!$Payments->{errno}) {
      $Cards->cards_change({
        ID       => $Cards->{ID},
        STATUS   => 2,
        UID      => $user_info->{UID},
        DATETIME => "$main::DATE $main::TIME",
      });

      if ($Cards->{errno}) {
        $db->rollback();
        $db->{AutoCommit} = 1;
        return $Errors->throw_error(1060014, { lang_vars => { ERROR => $Cards->{errno} } });
      }

      if ($self->{conf}->{CARDS_PAYMENTS_EXTERNAL}) {
        ::_external("$self->{conf}->{CARDS_PAYMENTS_EXTERNAL}", { %$Cards, %$user_info });
      }

      if ($Cards->{COMMISSION}) {
        require Fees;
        Fees->import();
        my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
        $Fees->take(
          $user_info,
          $Cards->{COMMISSION},
          {
            DESCRIBE => "Commission $Cards->{SERIAL}$Cards->{NUMBER}",
            METHOD   => 0,
          }
        );
      }

      if ($Cards->{UID} > 0) {
        my $user_new = Users->new($self->{db}, $self->{admin}, $self->{conf});
        $user_new->info($Cards->{UID});
        $user_new->del();
      }

      if ($Cards->{DILLER_ID}) {
        require Dillers;
        Dillers->import();
        my $Diller = Dillers->new($self->{db}, $self->{admin}, $self->{conf});
        $Diller->diller_info({ ID => $Cards->{DILLER_ID} });
        my $diller_fees = 0;
        if ($Diller->{PAYMENT_TYPE} && $Diller->{PAYMENT_TYPE} == 2 && $Diller->{OPERATION_PAYMENT} > 0) {
          $diller_fees = $Cards->{SUM} / 100 * $Diller->{OPERATION_PAYMENT};
        }
        elsif ($Diller->{DILLER_PERCENTAGE} && $Diller->{DILLER_PERCENTAGE} > 0) {
          $diller_fees = $Diller->{DILLER_PERCENTAGE};
        }

        if ($diller_fees > 0) {
          my $user_new = Users->new($self->{db}, $self->{admin}, $self->{conf});
          $user_new->info($Diller->{UID});

          require Fees;
          Fees->import();
          my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

          $Fees->take($user_new, $diller_fees, {
            DESCRIBE => "CARD_ACTIVATE: $Cards->{ID} CARD: $Cards->{SERIAL}$Cards->{NUMBER}",
            METHOD   => 0,
          });
        }
      }

      $Payments->list({ EXT_ID => "$Cards->{SERIAL}$Cards->{NUMBER}", TOTAL_ONLY => 1 });
      if ($Payments->{TOTAL} <= 1) {
        $db->commit();
      }

      $db->{AutoCommit} = 1;
      ::load_module("Abills::Templates", { LOAD_PACKAGE => 1 }) if (!exists($INC{"Abills/Templates.pm"}));
      ::cross_modules('payments_maked', {
        USER_INFO    => $user_info,
        SUM          => $Cards->{SUM},
        SKIP_MODULES => 'Cards,Sqlcmd',
        QUITE        => 1,
        SILENT       => 1,
        METHOD       => 2,
        FORM         => {}
      });

      return {
        result     => "Success payment, ID $Payments->{INSERT_ID}",
        amount     => $Cards->{SUM},
        payment_id => $Payments->{INSERT_ID},
        commission => $Cards->{COMMISSION} || 0,
      };
    }
    else {
      $db->rollback();
      if ($Payments->{errno} == 7) {
        if ($Cards->{STATUS} != 2) {
          $Cards->cards_change({
            ID       => $Cards->{ID},
            STATUS   => 2,
            UID      => $user_info->{UID},
            DATETIME => "$main::DATE $main::TIME",
          });
        }

        $db->{AutoCommit} = 1;

        return $Errors->throw_error(1060015);
      }
      else {
        $db->{AutoCommit} = 1;

        return $Errors->throw_error(1060016, { lang_vars => { ERROR => $Payments->{errno} } });
      }
    }
  }
}

1;
