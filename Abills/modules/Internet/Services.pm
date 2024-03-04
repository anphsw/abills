package Internet::Services;

=head1 NAME

  Internet users function

  ERROR ID: 136ХХХХ

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Internet;
use Users;

my Control::Errors $Errors;
my Internet $Internet;
my Users $Users;

my %permissions = ();

#**********************************************************
=head2 new($db, $conf, $admin, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);
  $Internet = Internet->new($db, $admin, $conf);
  $Users = Users->new($db, $admin, $conf);
  $Errors = Control::Errors->new($db, $admin, $conf, { lang => $self->{lang}, module => 'Internet' });

  return $self;
}

#**********************************************************
=head2 internet_user_chg_tp($attr) internet user change tp

  UID: int          - user for whom change tariff
  ID: int           - id of tariff from internet_main table
  TP_ID: int        - id of tp on which need to change
  PERIOD: int       - type of period of change tp
  DATE: str         - if used period equals 2
  TP_ID: int        - id of tp on which need to change
  GET_ABON: int     - make fee for user
  RECALCULATE: int  - recalculate of fees for user

=cut
#**********************************************************
sub internet_user_chg_tp {
  my $self = shift;
  my ($attr) = @_;

  #TODO: move it to the API schema validation can not right now
  #TODO: because the same function used in two different places
  if (!$attr->{UID}) {
    return $Errors->throw_error(1360001, { lang_vars => { FIELD => 'uid' } });
  }
  elsif (!$attr->{ID}) {
    return $Errors->throw_error(1360002, { lang_vars => { FIELD => 'id' } });
  }
  elsif (!$permissions{0}{4}) {
    return $Errors->throw_error(1360004);
  }
  elsif (!$permissions{0}{10}) {
    return $Errors->throw_error(1360005);
  }

  if (!$attr->{TP_ID}) {
    return $Errors->throw_error(1360003, { lang_vars => { FIELD => 'tpId' } });
  }
  else {
    require Tariffs;
    Tariffs->import();
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
    $Tariffs->info($attr->{TP_ID});

    if (!$Tariffs->{MODULE} || $Tariffs->{MODULE} ne 'Internet') {
      return $Errors->throw_error(1360015);
    }
  }

  $Users->info($attr->{UID});

  if ($Users->{errno}) {
    return $Errors->throw_error(1360006);
  }

  $Internet->user_info($Users->{UID}, {
    DOMAIN_ID => $Users->{DOMAIN_ID},
    ID        => $attr->{ID}
  });

  if ($Internet->{errno} || $Internet->{TOTAL} < 1) {
    return $Errors->throw_error(1360007);
  }

  if ($attr->{TP_ID} && "$attr->{TP_ID}" eq ("$Internet->{TP_ID}" || '')) {
    return $Errors->throw_error(1360008);
  }

  $Internet->{ABON_DATE} = $self->_internet_user_get_abon_date();
  my $period = $attr->{PERIOD} || $attr->{period} || 0;
  my ($year, $month, $day) = split(/-/, $main::DATE, 3);

  if ($period > 0) {
    if ($period == 1) {
      ($year, $month, $day) = split(/-/, $Internet->{ABON_DATE}, 3);
    }
    else {
      if (!$attr->{DATE}) {
        return $Errors->throw_error(1360009, { lang_vars => { FIELD => 'id' } });
      }
      ($year, $month, $day) = split(/-/, $attr->{DATE}, 3);

      if (!$year || !$month || !$day) {
        return $Errors->throw_error(1360010);
      }
    }
    my $seltime = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

    if ($seltime <= time()) {
      return $Errors->throw_error(1360011);
    }
    # what is it?
    elsif ($attr->{date_D} && $attr->{date_D} > ($month != 2 ? (($month % 2) ^ ($month > 7)) + 30 : (!($year % 400) || !($year % 4) && ($year % 25) ? 29 : 28))) {
      return $Errors->throw_error(1360012);
    }

    my $comments = ($self->{lang}->{FROM} || 'from') . ": $Internet->{TP_ID}:" .
      (($Internet->{TP_NAME}) ? "$Internet->{TP_NAME}" : q{}) . ((!$attr->{GET_ABON}) ? "\nGET_ABON=-1" : '')
      . ((!$attr->{RECALCULATE}) ? "\nRECALCULATE=-1" : '');

    require Shedule;
    Shedule->import();
    my $Schedule = Shedule->new($self->{db}, $self->{admin});

    $Schedule->add({
      UID          => $Users->{UID},
      TYPE         => 'tp',
      ACTION       => "$attr->{ID}:$attr->{TP_ID}",
      D            => $day,
      M            => $month,
      Y            => $year,
      MODULE       => 'Internet',
      COMMENTS     => $comments,
      ADMIN_ACTION => 1
    });

    if ($Schedule->{errno}) {
      return $Errors->throw_error(1360013);
    }
    else {
      return {
        result  => 'OK',
        message => 'TARIFF_SCHEDULE_SET',
      };
    }
  }
  else {
    if ($Internet->{ACTIVATE} && $Internet->{ACTIVATE} ne '0000-00-00' && !$Internet->{STATUS}) {
      $attr->{ACTIVATE} = $main::DATE;
    }

    $attr->{PERSONAL_TP} = 0.00;
    $Internet->user_change($attr);

    if ($Internet->{TP_INFO} && $Internet->{TP_INFO}->{MONTH_FEE} && $Internet->{TP_INFO}->{MONTH_FEE} < $Users->{DEPOSIT}) {
      $Internet->{STATUS} = 0;
      $attr->{ACTIVE_SERVICE} = 1;
    }

    if (!$Internet->{errno}) {
      if (!$Internet->{STATUS} && $attr->{GET_ABON}) {
        ::service_get_month_fee($Internet, {
          QUITE       => 1,
          RECALCULATE => $attr->{RECALCULATE} || 0
        });
        if ($attr->{ACTIVE_SERVICE}) {
          $attr->{STATUS} = 0;
          $Internet->user_change($attr);
        }
      }

      return {
        result  => 'OK',
        message => 'TARIFF_CHANGED',
      };
    }
    else {
      return $Errors->throw_error(1360014);
    }
  }
}

#**********************************************************
=head2 _internet_user_get_abon_date($attr) internet get abon date for user

  Returns:
    $abon_date: string - date of user fee

=cut
#**********************************************************
sub _internet_user_get_abon_date {
  my $self = shift;

  my $abon_date = '';

  if (
    ($Internet->{MONTH_ABON} && $Internet->{MONTH_ABON} > 0)
      && !$Internet->{STATUS}
      && !$Users->{DISABLE}
      && (($Users->{DEPOSIT} ? $Users->{DEPOSIT} : 0) + ($Users->{CREDIT} ? $Users->{CREDIT} : 0) > 0
      || $Internet->{POSTPAID_ABON}
      || ($Internet->{PAYMENT_TYPE} && $Internet->{PAYMENT_TYPE} == 1))
  ) {
    if ($Internet->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split(/-/, $Internet->{ACTIVATE}, 3);
      $M--;
      $abon_date = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 +
        (($self->{conf}->{START_PERIOD_DAY}) ? $self->{conf}->{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split(/-/, $main::DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      if ($self->{conf}->{START_PERIOD_DAY}) {
        $D = $self->{conf}->{START_PERIOD_DAY};
      }
      else {
        $D = '01';
      }
      $abon_date = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  return $abon_date;
}

1;
