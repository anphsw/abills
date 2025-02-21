=head2 NAME

  Triplay User portal

=cut

use warnings FATAL => 'all';
use strict;

our (
  $db,
  $admin,
  %conf,
  %lang,
);

our Users $user;
our Abills::HTML $html;
#my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Triplay = Triplay->new($db, $admin, \%conf);

#**********************************************************
=head2 triplay_user_info()

=cut
#**********************************************************
sub triplay_user_info {
  my $uid = $LIST_PARAMS{UID};

  my $user_info = $Triplay->user_info({ UID => $uid });

  if ($user_info->{errno}) {
    $html->tpl_show(_include('triplay_unreg_info', 'Triplay'), $user_info, { ID => 'triplay_unreg_info' });
    return 0;
  }
  if($user_info->{REDUCTION_FEE} && $user->{REDUCTION} > 0) {
    if ($user->{REDUCTION} < 100) {
      $user_info->{DAY_ABON}   = sprintf('%.2f', $user_info->{DAY_ABON} * (100 - $user->{REDUCTION}) / 100) if ($user_info->{DAY_ABON} > 0);
      $user_info->{MONTH_ABON} = sprintf('%.2f', $user_info->{MONTH_ABON} * (100 - $user->{REDUCTION}) / 100) if($user_info->{MONTH_ABON} > 0);
    }
    else {
      $user_info->{DAY_ABON}=0;
      $user_info->{MONTH_ABON}=0;
    }
  }

  $Triplay->{STATUS} = $user_info->{DISABLE} || 0;

  if ($FORM{activate}) {
    return 0 if (! in_array($Triplay->{STATUS}, [2, 5]));
    $Triplay->user_change({
      UID      => $uid,
      #ID       => $service_id,
      STATUS   => 0,
    });

    if (!$Triplay->{errno}) {
      $Triplay->{STATUS} = 0;
      if (!$Triplay->{STATUS}) {
        require Triplay::Base;
        Triplay::Base->import();
        my $Triplay_base = Triplay::Base->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });

        $user_info = $Triplay->user_info({ UID => $uid });

        my $service_list = $Triplay->service_list({
          UID        => $uid,
          MODULE     => '_SHOW',
          SERVICE_ID => '_SHOW',
          COLS_NAME  => 1
        });

        my %sub_services = ();
        foreach my $service (@$service_list) {
          $sub_services{uc($service->{module}) . '_SERVICE_ID'} = $service->{service_id} if ($service->{service_id});
        }

        $Triplay_base->triplay_service_activate_web({
          %sub_services,
          USER_INFO => $user,
          TP_INFO   => $Triplay->{TP_INFO},
          TP_ID     => $Triplay->{TP_ID}
        });

        $html->message('info', $lang{SUCCESS}, $lang{CHANGED});
      }
    }
    else {
      $html->message('err', $lang{ACTIVATE}, $lang{ERROR}, { ID => 102 });
    }
  }

  my $service_status = sel_status({ HASH_RESULT => 1 });
  my ($status, $color) = split(/:/, $service_status->{ $user_info->{DISABLE} });
  $user_info->{STATUS_FIELD} = $color;
  $user_info->{STATUS_VALUE} = $status;

  if ($Triplay->{STATUS} == 2) {
    #$Triplay->{STATUS_VALUE} = $status;
    $Triplay->{STATUS_FIELD} = 'text-warning';
    $user_info->{STATUS_BTN} = ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
      : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ID=>'ACTIVATE', class=> 'btn btn-sm btn-success float-right' });
  }
  elsif ($Triplay->{STATUS} == 5) {
    # $Triplay->{STATUS_VALUE} = $status;
    $Triplay->{STATUS_FIELD} = 'text-danger';

    if ($Triplay->{MONTH_ABON} && $user->{DEPOSIT} && $Triplay->{MONTH_ABON} <= $user->{DEPOSIT}) {
      $user_info->{STATUS_BTN} = ($user->{DISABLE} > 0) ? $html->b("($lang{ACCOUNT} $lang{DISABLE})")
        : $html->button($lang{ACTIVATE}, "&index=$index&sid=$sid&activate=1", { ex_params => ' ID="ACTIVATE"', class=> 'btn btn-sm btn-success float-right' });
    }
    else {
      if ($functions{$index} && $functions{$index} eq 'internet_user_info') {
        form_neg_deposit($user);
      }
    }
  }
  elsif ($Triplay->{STATUS} == 1) {
    #$Triplay->{STATUS_VALUE} = $status;
    $Triplay->{STATUS_FIELD} = 'text-danger';
  }
  else {
    #$Triplay->{STATUS_VALUE} = $status;
    $Triplay->{STATUS_FIELD} = 'text-success';
  }

  if ($user_info->{TOTAL} && $user_info->{TOTAL} > 0) {
    $Triplay->{ACTION_LNG} = $lang{CHANGE};
    $Triplay->{ACTION} = 'change';

    my $service_list = $Triplay->service_list({
      UID        => $uid,
      MODULE     => '_SHOW',
      SERVICE_ID => '_SHOW',
      COLS_NAME  => 1
    });

    my %user_services = ();
    foreach my $service (@$service_list) {
      $user_services{uc($service->{module}).'_SERVICE_ID'} = $service->{service_id};
    }

    my $tp_info = $Triplay->tp_info({ TP_ID => $user_info->{TP_ID} });

    $user_info->{INTERNET_TP} = $tp_info->{INTERNET_NAME};
    $user_info->{VOIP_TP}  = $tp_info->{VOIP_NAME};
    $user_info->{IPTV_TP}  = $tp_info->{IPTV_NAME};
    $user_info->{ABON_TP}  = $tp_info->{ABON_NAME};

    my $money_name = '';
    if ($conf{MONEY_UNIT_NAMES}) {
      if (ref $conf{MONEY_UNIT_NAMES} eq 'ARRAY') {
        $money_name = $conf{MONEY_UNIT_NAMES}->[0] || '';
      }
      else {
        $money_name = (split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
      }
    }

    #Extra fields
    $user_info->{EXTRA_FIELDS} = '';
    my @check_fields = (
      "MONTH_ABON:0.00:MONTH_FEE:$money_name",
      "DAY_ABON:0.00:DAY_FEE:$money_name",
      #"TP_ACTIVATE_PRICE:0.00:ACTIVATE_TARIF_PLAN:$money_name",
      "SERVICE_EXPIRE:0000-00-00:EXPIRE",
      "TP_AGE:0:AGE:DAYS",
      "INTERNET_TP::INTERNET",
      "VOIP_TP::VOIP",
      "IPTV_TP::TV",
      "ABON_TP::ABON",
    );

    my @extra_fields = ();
    foreach my $param ( @check_fields ) {
      my($id, $default_value, $lang_, $value_prefix )=split(/:/, $param, 4);

      if(! defined($user_info->{$id}) || $user_info->{$id} eq $default_value) {
        next;
      }
      elsif ($user_info->{TP_AGE} && $id =~/MONTH_ABON|DAY_ABON/) {
        next;
      }

      if ($value_prefix && $lang{$value_prefix}) {
        $value_prefix=$lang{$value_prefix};
      }

      push @extra_fields,$html->tpl_show(templates('form_row_client'), {
        ID    => $id,
        NAME  => $lang{$lang_} || $lang_,
        VALUE => $user_info->{$id} . ( $value_prefix ? (' ' . $value_prefix) : '' ),
      }, { OUTPUT2RETURN => 1, ID => $id });
    }

    $user_info->{EXTRA_FIELDS} = join(($FORM{json} ? ',' : ''), @extra_fields);

    # my $services_info = $html->tpl_show(_include('triplay_sevices_info', 'Triplay'), {
    #   INTERNET_TP=> $tp_info->{INTERNET_NAME},
    #   VOIP_TP  => $tp_info->{VOIP_NAME},
    #   IPTV_TP  => $tp_info->{IPTV_NAME},
    #   ABON_TP  => $tp_info->{ABON_NAME},
    # }, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(_include('triplay_user_info', 'Triplay'), $user_info,
    {  ID => 'triplay_user_info' });

  return 1;
}

1;
