=head1 NAME

  User registration sub functions

=cut

use strict;
use warnings;

our(
  %FORM,
  %lang,
  $db,
  %conf,
);

our Abills::HTML $html;
our Users $users;
our Admins $admin;

#**********************************************************
=head2 _group_add($attr) - Create groups

  Arguments:
    add_values

  Results
    True or False

=cut
#**********************************************************
sub _group_add {
  my ($add_values) = @_;

  if (!$add_values->{1}{GID_NAME}) {
    return 0;
  }

  my $gid_list = $users->groups_list({
    SORT      => 'g.gid',
    DESC      => 'desc',
    NAME      => $add_values->{1}{GID_NAME},
    PAGE_ROWS => 1,
    COLS_NAME => 1
  });

  if ($users->{TOTAL} > 0) {
    $add_values->{1}{GID} = $gid_list->[0]->{id};
  }
  else {
    $gid_list = $users->groups_list({
      SORT      => 'g.gid',
      DESC      => 'desc',
      PAGE_ROWS => 1,
      COLS_NAME => 1
    });

    my $gid = ($gid_list && $gid_list->[0]) ? ($gid_list->[0]->{id} || 0) + 1 : 1;
    $users->group_add({
      GID  => $gid,
      NAME => $add_values->{1}{GID_NAME}
    });

    if (!$users->{errno}) {
      $add_values->{1}{GID} = $gid;
    }
  }

  return $add_values->{1}{GID};
}

#**********************************************************
=head2 _company_add($attr) - Create user and services

  Arguments:
    $attr

  Results
    True or False

=cut
#**********************************************************
sub _company_add {
  my ($add_values) = @_;

  if (!$add_values->{1}{COMPANY_NAME}) {
    return 0;
  }

  require Companies;
  Companies->import();
  my $Company = Companies->new($db, $admin, \%conf);

  my $companies_list = $Company->list({
    COMPANY_NAME => $add_values->{1}{COMPANY_NAME},
    PAGE_ROWS    => 1,
    COLS_NAME    => 1
  });

  if ($Company->{TOTAL} > 0) {
    $add_values->{1}{COMPANY_ID} = $companies_list->[0]->{id};
    delete $add_values->{5};
    return $add_values->{1}{COMPANY_ID};
  }
  else {
    if ($add_values->{1}{COMPANY_ADDRESS_BUILD}) {
      require Control::Address_mng;
      $add_values->{1}{LOCATION_ID} = address_create({
        DISTRICT => $add_values->{1}{COMPANY_CITY},
        STREET   => $add_values->{1}{COMPANY_ADDRESS_STREET},
        BUILD    => $add_values->{1}{COMPANY_ADDRESS_BUILD},
        ZIP      => $add_values->{1}{COMPANY_ZIP},
        CITY     => $add_values->{1}{COMPANY_CITY},
      });
    }

    #Extraa Company Params
    my %company_company_params = ();
    if ($add_values->{1111}) {
      %company_company_params = %{$add_values->{1111}};
    }
    $Company->add({
      NAME         => $add_values->{1}{COMPANY_NAME},
      ADDRESS_FLAT => $add_values->{1}{COMPANY_ADDRESS_FLAT},
      LOCATION_ID  => $add_values->{1}{LOCATION_ID},
      COMMENTS     => $add_values->{1}{COMPANY_COMMENTS},
      CREATE_BILL  => 1,
      %company_company_params
    });

    if (!$Company->{errno}) {
      $add_values->{1}{COMPANY_ID} = $Company->{COMPANY_ID};
      return $add_values->{1}{COMPANY_ID};
    }
    else {
      _error_show($Company, { MESSAGE => "$lang{COMPANY} $add_values->{1}{COMPANY_NAME}" });
    }
  }

  return 0;
}

#**********************************************************
=head2 _extbill_add($add_values) - Create user and services

  Arguments:
    $add_values

  Results
    True or False

=cut
#**********************************************************
sub _extbill_add {
  my ($add_values) = @_;

  if (! $add_values->{5} || !$add_values->{5}->{'EXT_BILL_DEPOSIT'}) {
    return 0;
  }

  my $Fees = Finance->fees($db, $admin, \%conf);
  my $Finance = Finance->new($db, $admin, \%conf);
  my $Payments = Finance->payments($db, $admin, \%conf);

  my $uid = $add_values->{1}->{UID};

  my $message = q{};
  $add_values->{5}{SUM} = $FORM{'5.EXT_BILL_DEPOSIT'};
  # if Bonus $conf{BONUS_EXT_FUNCTIONS}
  if (in_array('Bonus', \@MODULES) && $conf{BONUS_EXT_FUNCTIONS}) {
    load_module('Bonus', $html);
    my $sum = $FORM{'5.EXT_BILL_DEPOSIT'};
    %FORM = %{$add_values->{8}};
    $FORM{UID} = $uid;
    $FORM{SUM} = $sum;
    $FORM{add} = $uid;
    if ($FORM{SUM} < 0) {
      $FORM{ACTION_TYPE} = 1;
      $FORM{SUM} = abs($FORM{SUM});
    }

    $FORM{SHORT_REPORT} = 1;
    bonus_user_log({ USER_INFO => $user });
  }
  else {
    if ($FORM{'5.EXT_BILL_DEPOSIT'} + 0 > 0) {
      my $er = ($FORM{'5.ER'}) ? $Finance->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
      $Payments->add(
        $user,
        {
          %{$add_values->{5}},
          BILL_ID => $user->{EXT_BILL_ID},
          ER      => $er->{ER_RATE}
        }
      );

      if (_error_show($Payments, { MODULE_NAME => $lang{PAYMENTS} })) {
        return 0;
      }
      else {
        $message = "$lang{SUM}: $add_values->{5}{SUM} "
          . (($er->{ER_SHORT_NAME}) ? $er->{ER_SHORT_NAME} : q{}) . "\n";
      }
    }
    elsif ($FORM{'5.EXT_BILL_DEPOSIT'} + 0 < 0) {
      my $er = ($FORM{'5.ER'}) ? $Finance->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
      $Fees->take(
        $user,
        abs($FORM{'5.EXT_BILL_DEPOSIT'}),
        {
          BILL_ID  => $user->{EXT_BILL_ID},
          DESCRIBE => 'MIGRATION',
          ER       => $er->{ER_RATE}
        }
      );

      if (_error_show($Fees, { MODULE_NAME => $lang{FEES} })) {
        return 0;
      }
      else {
        $message = "$lang{SUM}: $FORM{'5.EXT_BILL_DEPOSIT'} $er->{ER_SHORT_NAME}\n";
      }
    }
  }

  return 1;
}


1;