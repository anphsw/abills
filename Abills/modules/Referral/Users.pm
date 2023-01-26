package Referral::Users;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Referral users function

  ERROR ID: 410xx

=cut

use Abills::Base qw(date_inc load_pmodule);
use Referral;
use Users;

my Referral $Referral;
my Users $Users;

my Abills::HTML $html;

my %lang;

#**********************************************************
=head2 new($db, $conf, $admin, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  %lang = %{$attr->{lang} || {}};
  $html = $attr->{html};

  $Users = Users->new($db, $admin, $conf);
  $Referral = Referral->new($db, $admin, $conf, { SKIP_CONF => 1 });

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 referral_friend_manage() add friend by user


=cut
#**********************************************************
sub user_referral_manage {
  my $self = shift;
  my ($attr) = @_;

  my $phone_format = $self->{conf}->{PHONE_FORMAT} || $self->{conf}->{CELL_PHONE_FORMAT};

  if (!$attr->{PHONE} || !$attr->{FIO}) {
    return {
      errno   => 41003,
      errstr  => 'No fields fio or number',
      element => [ 'err', $lang{ERROR}, "$lang{FIO} $lang{OR} $lang{PHONE} $lang{EMPTY}", { ID => 41003 } ]
    };
  }
  elsif ($attr->{PHONE} && ($phone_format && $attr->{PHONE} !~ /^\d+$/g)) {
    return {
      errno   => 41001,
      errstr  => 'Invalid phone',
      element => [ 'err', $lang{ERROR}, $lang{ERR_ONLY_NUMBER}, { ID => 41001 } ]
    };
  }
  elsif ($attr->{PHONE} && $attr->{add}) {
    $Referral->request_list({
      REFERRER     => $Users->{UID},
      phone        => $attr->{PHONE},
      COLS_NAME    => 1,
    });

    if ($Referral->{TOTAL} && $Referral->{TOTAL} > 0) {
      return {
        errno   => 41002,
        errstr  => 'Referral already exists with this number',
        element => [ 'err', $lang{ERROR}, "$lang{PHONE} $lang{EXIST}", { ID => 41001 } ]
      };
    }
  }

  my %params = ();
  my @allowed_params = ('FIO', 'PHONE', 'ADDRESS');

  foreach my $param (@allowed_params) {
    $params{$param} = $attr->{$param} if ($attr->{$param});
  }

  if ($attr->{add}) {
    my $result = $Referral->add_request({
      %params,
      REFERRER => $attr->{UID},
    });

    return {
      result      => 'Successfully added',
      referral_id => $result->{INSERT_ID}
    };
  }
  elsif ($attr->{change}) {
    my $result = $Referral->change_request({
      %params,
      ID       => $attr->{ID} || '',
      REFERRER => $attr->{UID},
    });

    return {
      result      => 'Successfully changed',
      referral_id => $attr->{ID}
    };
  }
  else {
    return {
      result => 'OK',
    };
  }
}

#**********************************************************
=head2 referral_add_friend() add friend by user


=cut
#**********************************************************
sub user_referrals {
  my $self = shift;
  my ($attr) = @_;

  require Finance;
  Finance->import();
  my $Payments = Finance->payments($self->{db}, $self->{admin}, $self->{conf});
  my $Fees = Finance->fees($self->{db}, $self->{admin}, $self->{conf});

  $Users->info($attr->{UID});

  my $referral_list = $Referral->request_list({
    REFERRER     => $Users->{UID},
    phone        => '_SHOW',
    ADDRESS      => '_SHOW',
    FIO          => '_SHOW',
    STATUS       => '_SHOW',
    TP_ID        => '_SHOW',
    REFERRAL_UID => '_SHOW',
    USER_STATUS  => '_SHOW',
    COLS_NAME    => 1,
  });

  my %status = (
    0 => 'open',
    1 => 'in work',
    2 => 'executed',
    3 => 'canceled'
  );

  my @referrals = ();
  my $total_bonus = 0;

  foreach my $referral (@{$referral_list}) {
    if ($referral->{referral_uid}) {
      my $tp_info = $Referral->tp_info($referral->{referral_tp});

      my $log_list = $Referral->log_list({
        REFERRER  => $Users->{UID} . "' or rl.referrer = '0",
        LOG_TYPE  => 1,
        SORT      => 'date',
        DESC      => 'DESC',
        DATE      => '_SHOW',
        COLS_NAME => 1,
      });

      my $referral_fees = $Fees->list({
        UID            => $referral->{referral_uid},
        SUM            => '_SHOW',
        METHOD         => 1,
        COLS_NAME      => 1,
        FROM_DATE_TIME => $log_list->[0]->{date} || $main::DATE,
        TO_DATE_TIME   => date_inc($main::DATE) . ' 00:00:00',
      });

      my $spend_percent = $tp_info->{SPEND_PERCENT};
      my $fees_bonus = 0;
      if ($spend_percent) {
        for my $fees (@$referral_fees) {
          $fees_bonus += $fees->{sum} * ($spend_percent / 100);
          $total_bonus += $fees_bonus;
        }
      }

      my $payment = $Payments->list({
        UID            => $referral->{referral_uid},
        COLS_NAME      => 1,
        SUM            => '_SHOW',
        FROM_DATE_TIME => $log_list->[0]->{date} || $main::DATE,
        TO_DATE_TIME   => date_inc($main::DATE),
      });

      my $repl_percent = $tp_info->{REPL_PERCENT};
      my $repl_bonus = 0;
      if ($repl_percent) {
        for my $pay (@$payment) {
          $repl_bonus += $pay->{sum} * ($repl_percent / 100);
          $total_bonus += $repl_bonus;
        }
      }

      push @referrals, {
        ID             => $referral->{id} || '',
        FIO            => $referral->{fio} || '',
        PHONE          => $referral->{phone} || '',
        STATUS         => defined $referral->{status} ? $referral->{status} : 999,
        STATUS_NAME    => $status{$referral->{status}} || 'unknown',
        DISABLE        => defined $referral->{disable} ? $referral->{disable} : 1,
        PAYMENT_BONUS  => $repl_bonus || 0,
        SPENDING_BONUS => $fees_bonus || 0,
        ADDRESS        => $referral->{address},
        IS_USER        => 'true'
      }
    }
    else {
      push @referrals, {
        ID             => $referral->{id} || '',
        FIO            => $referral->{fio} || '',
        PHONE          => $referral->{phone} || '',
        STATUS         => defined $referral->{status} ? $referral->{status} : 999,
        STATUS_NAME    => $status{$referral->{status}} || 'unknown',
        DISABLE        => defined $referral->{disable} ? $referral->{disable} : 1,
        PAYMENT_BONUS  => 0,
        SPENDING_BONUS => 0,
        ADDRESS        => $referral->{address},
        IS_USER        => 'false'
      }
    }
  }

  my $referral_link = $main::SELF_URL || q{};
  my $script_name = $ENV{SCRIPT_NAME} || q{};
  $referral_link =~ s/$script_name/\/registration.cgi?REFERRER=$Users->{UID}/;

  return {
    result          => 'OK',
    referrals       => \@referrals,
    referrals_total => scalar @referrals,
    total_bonus     => $total_bonus,
    referral_link   => $referral_link
  };
}

#**********************************************************
=head2 user_get_bonus() take bonus


=cut
#**********************************************************
sub user_get_bonus {
  my $self = shift;
  my ($attr) = @_;

  my $result = $self->user_referrals({ UID => $attr->{UID} });
  my $total_bonus = $result->{total_bonus};

  require Bills;
  Bills->import();
  my $Bills = Bills->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->info($attr->{UID});

  if (!$Users->{EXT_BILL_ID}) {
    my $bill = $Bills->create({
      DEPOSIT => $total_bonus,
      UID     => $Users->{UID}
    });

    $Users->change($Users->{UID}, {
      UID         => $Users->{UID},
      EXT_BILL_ID => $bill->{BILL_ID}
    });
  }
  else {
    $Bills->action('add', $Users->{EXT_BILL_ID}, $total_bonus);
  }

  $Referral->add_log({
    UID              => 0,
    REFERRER         => $Users->{UID},
    TP_ID            => 0,
    REFERRAL_REQUEST => 0,
    LOG_TYPE         => 1,
  });

  if ($self->{conf}->{REFERRAL_SEND_BONUS_REPORT}) {
    my $referrals = $Referral->list({
      REFERRAL  => $Users->{UID},
      COLS_NAME => 1,
    });

    my @referrals_list = $referrals->[0] ? @{$referrals} : ();

    my %report = (
      refferal_system => {
        withdraw  => {
          uid      => $Users->{UID},
          date     => $main::DATE,
          withdraw => $total_bonus
        },
        referral => \@referrals_list
      }
    );

    my $xml = XML::Simple::XMLout(\%report, KeepRoot => 1);
    my $mail = $self->{conf}->{ADMIN_MAIL};

    require Abills::Sender::Core;
    Abills::Sender::Core->import();
    my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

    $Sender->send_message({
      SENDER_TYPE => 'Mail',
      TO_ADDRESS  => $mail,
      MESSAGE     => $xml,
      SUBJECT     => $lang{REFERRAL_SYSTEM},
      QUITE       => 1
    });
  }

  return {
    result    => "Successfully get bonus - $total_bonus",
    bonus_sum => $total_bonus
  };
}

1;
