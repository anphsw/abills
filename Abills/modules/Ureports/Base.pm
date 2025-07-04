package Ureports::Base;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array date_diff cmd convert next_month/;
use Abills::HTML;

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my Ureports $Ureports;
my $Sender;
my %sending_types = ();

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Ureports;
  Ureports->import();
  $Ureports = Ureports->new($db, $admin, $CONF);

  use Abills::Sender::Core;
  $Sender = Abills::Sender::Core->new($db, $admin, $CONF);

  %sending_types = %Abills::Sender::Core::PLUGIN_NAME_FOR_TYPE_ID;

  bless($self, $class);

  return $self;
}

#**********************************************************
=head iptv_quick_info($attr) - Quick information

  Arguments:
    $attr
      UID
      LOGIN

=cut
#**********************************************************
sub ureports_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID};

  my $reports_list = $Ureports->user_list({
    UID           => $uid,
    REPORTS_COUNT => '_SHOW',
    COLS_NAME     => 1,
  });

  return ($Ureports->{TOTAL} && $Ureports->{TOTAL} > 0) ? $reports_list->[0]->{reports_count} : '';
}

#**********************************************************
=head2 ureports_payments_maked($attr)

  Arguments:
    $attr
      USER_INFO
      METHOD
      SUM

  Results:

=cut
#**********************************************************
sub ureports_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  return 0 if ($attr->{CREDIT_NOTIFICATION} && $CONF->{UREPORTS_CREDIT_NOTIFICATION});
  return 0 unless (exists $attr->{USER_INFO} && defined $attr->{USER_INFO} && $attr->{USER_INFO}{UID});

  if ($CONF->{UREPORTS_PAYMENT_METHOD} && $attr->{METHOD}) {
    my @arr = split(/,\s?/x, $CONF->{UREPORTS_PAYMENT_METHOD});
    return 0 if !in_array($attr->{METHOD}, \@arr);
  }

  my $form = $attr->{FORM} || {};

  return '' if ($form->{DISABLE} || $form->{CREDIT});
  return '' if (!$attr->{SUM} || $attr->{SUM} !~ m/\d+/x);

  my $user = $attr->{USER_INFO};

  $Ureports->tp_user_reports_reset_date({ UID => $user->{UID}, REPORT_ID => 15 });

  my %users_params = ();

  if (in_array('Internet', \@main::MODULES)) {
    $users_params{INTERNET_TP} = 1;
    $users_params{INTERNET_STATUS} = '_SHOW';
  }
  $Ureports->tp_user_reports_list({
    UID              => $user->{UID} || '-',
    DESTINATION_TYPE => '_SHOW',
    DESTINATION_ID   => '_SHOW',
    TP_ID            => '_SHOW',
    %users_params,
    REPORT_ID        => 12,
    STATUS           => 0,
    COLS_UPPER       => 1,
    COLS_NAME        => 1
  });

  return 0 if $Ureports->{TOTAL} < 1 || !$Ureports->{list}[0]{UID};

  my $user_info = $Ureports->{list}->[0];
  my $total_daily_fee = 0;
  my %info = ();
  $info{AMOUNT} = $attr->{AMOUNT} if $attr->{AMOUNT};

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 }) if (!exists($INC{"Control/Services.pm"}));

  my $service_info = ::get_services({
    UID           => $user->{UID},
    REDUCTION     => $user->{REDUCTION},
    SKIP_DISABLED => 1,
    PAYMENT_TYPE  => 0
  }, { SKIP_MODULES => 'Ureports,Sqlcmd' });

  foreach my $service (@{$service_info->{list}}) {
    $user->{RECOMMENDED_PAYMENT} += $service->{SUM};
  }

  $total_daily_fee = $service_info->{distribution_fee} if $service_info->{distribution_fee};
  $user->{TOTAL_FEES_SUM} = $user->{RECOMMENDED_PAYMENT};

  $user->{DEPOSIT} -= $user_info->{msg_price} if $user_info->{msg_price};

  if ($total_daily_fee) {
    my $deposit = $user->{DEPOSIT} + $user->{CREDIT};
    my $expire_days = int($deposit / $total_daily_fee);

    if ($attr->{CREDIT_NOTIFICATION}) {
      my (undef, $days) = split(':', $CONF->{user_credit_change});
      $days = $days || 0;
      $expire_days = $days if ($days && $days < $expire_days);
    }

    $info{EXPIRE_DAYS} = $expire_days;
    $info{EXPIRE_DATE} = POSIX::strftime("%Y-%m-%d", localtime(time + $info{EXPIRE_DAYS} * 86400));
  }
  else {
    $info{EXPIRE_DAYS} = '';
    require Internet::Service_mng;
    my $Service = Internet::Service_mng->new({
      db    => $db,
      admin => $admin,
      conf  => $CONF
    });

    $Service->get_next_abon_date({
      MONTH_ABON     => $user_info->{tp_month_fee},
      ACTIVATE       => $info{ACTIVATE},
      FIXED_FEES_DAY => $info{TP_FIXED_FEES_DAY},
    });

    if ($Service->{ABON_DATE}) {
      $info{EXPIRE_DATE} = $Service->{ABON_DATE};
      $info{EXPIRE_DAYS} = date_diff($main::DATE, $Service->{ABON_DATE});
    }
  }

  $lang->{ALL_SERVICE_EXPIRE} =~ s/XX/ $info{EXPIRE_DAYS} /x;
  $info{MESSAGE} = $lang->{ALL_SERVICE_EXPIRE};
  $info{PAYMENT_ID} = $attr->{PAYMENT_ID};

  if ($user->{DEPOSIT} + $user->{CREDIT} > 0) {
    $info{RECOMMENDED_PAYMENT} = sprintf("%.2f", ($info{RECOMMENDED_PAYMENT} || 0) - ($user->{DEPOSIT} + $user->{CREDIT}));
    if ($info{RECOMMENDED_PAYMENT} < 0) {
      $info{RECOMMENDED_PAYMENT} = 0
    }
  }
  else {
    $info{RECOMMENDED_PAYMENT} += sprintf("%.2f", abs($user->{DEPOSIT} + $user->{CREDIT}));
  }

  if ($CONF->{UREPORTS_ROUNDING} && $info{RECOMMENDED_PAYMENT} > 0) {
    if (int($info{RECOMMENDED_PAYMENT}) < $info{RECOMMENDED_PAYMENT}) {
      $info{RECOMMENDED_PAYMENT} = int($info{RECOMMENDED_PAYMENT} + 1);
    }
  }


  $user->pi({ UID => $user->{UID} });
  $info{DEPOSIT} = sprintf("%.2f", $user->{DEPOSIT});
  # This date dont shows in report
  $info{DATE} = "$main::DATE $main::TIME";
  # Added for some reason
  $info{TIME} = $main::TIME;
  $info{NEXT_MONTH}=next_month({ DATE => $main::DATE });

  # Add 0 to correct encoding of sum
  $info{SUM} = sprintf("%.2f", $attr->{SUM} + 0);
  my $recommended_payment = $info{RECOMMENDED_PAYMENT};

  if ($recommended_payment && $recommended_payment > 0) {
    $info{MESSAGE} .= "\n $lang->{RECOMMENDED_PAYMENT}:  $recommended_payment\n";
  }

  # Payment method name in report
  if(defined($attr->{METHOD}) && defined($attr->{PAYMENTS_METHODS})) {
    $info{PAYMENT_METHOD} = $attr->{PAYMENTS_METHODS}{$attr->{METHOD}} // '';
  }

  if (ref $html ne 'Abills::HTML') {
    $html = Abills::HTML->new({
      CONF     => $CONF,
      CHARSET  => $CONF->{default_charset},
    });
  }

  my %params = (
    %{$user},
    %{$user_info},
    %info,
    SUBJECT   => $lang->{ACCOUNT_REPLENISHMENT},
    UID       => $user->{UID},
    TP_ID     => $user_info->{TP_ID},
    DATE      => $main::DATE,
    REPORT_ID => 12,
  );

  my $send_tpl = $html->tpl_show(main::_include('ureports_report_12', 'Ureports'), \%params,
    { ID => 'ureports_report_12', OUTPUT2RETURN => 1 });

  $self->ureports_send_reports(
    $user_info->{DESTINATION_TYPE},
    $user_info->{DESTINATION_ID},
    $send_tpl,
    \%params,
    DEBUG => 0
  );

  if ($user_info->{MSG_PRICE} > 0) {
    my $sum = $user_info->{MSG_PRICE};

    my %PARAMS = (DESCRIBE => "$lang->{REPORTS} ($user_info->{REPORT_ID}) ");

    require Fees;
    Fees->import();
    my $Fees = Fees->new($db, $admin, $CONF);
    $Fees->take($user, $sum, { %PARAMS });

    if ($Fees->{errno}) {
      print "Error: [$Fees->{errno}] $Fees->{errstr} ";
      if ($Fees->{errno} == 14) {
        print "[ $user->{UID} ] $user_info->{LOGIN} - Don't have money account";
      }
      print "\n";
    }
  }

  return 1;
}

#**********************************************************
=head2 ureports_send_reports($type, $destination, $message, $attr)

  Arguments:
    $type           - sender type
    $destination    - Destination address (See: Sender Core)
    $message
    $attr
       MESSAGE_TEPLATE || REPORT_ID
       UID
       TP_ID
       REPORT_ID
       SUBJECT
       DEBUG

   Returns:
     boolean

=cut
#**********************************************************
sub ureports_send_reports {
  my $self = shift;
  my ($type, $destination, $message, $attr) = @_;

  if (!$type) {
    return 0;
  }
  elsif (! $destination) {
    print "ERROR: No destination... UID: " . ($attr->{UID} || q{}) ."\n";
    return 0;
  }

  my @types = split(',\s?', $type);
  my @destinations = split(',\s?', $destination);
  my $debug = $attr->{DEBUG} || 0;
  my $subject = $attr->{SUBJECT} || '';

  my $type_index = 0;
  my $status = 0;
  my %sended_distination = ();
  my @status_list = ();

  foreach my $send_type (@types) {
    # Fix old EMAIL type 0 -> 9
    $send_type = 9 if (! $send_type || $send_type eq '0');

    if ($attr->{MESSAGE_TEPLATE}) {
      $message = $html->tpl_show(main::_include($attr->{MESSAGE_TEPLATE}, 'Ureports'), $attr, { OUTPUT2RETURN => 1 });
    }
    elsif ($send_type == 1 && $message && $CONF->{UREPORTS_CUSTOM_FIRST}) {
      $attr->{MESSAGE} = $message;
      $message = $html->tpl_show(main::_include('ureports_sms_message', 'Ureports'), $attr, { OUTPUT2RETURN => 1 });
    }
    elsif ($attr->{REPORT_ID}) {
      my $message_template = 'ureports_report_' . $attr->{REPORT_ID};

      if($sending_types{$send_type}) {
        my $send_type_format = lc($sending_types{$send_type});
        my $send_type_tpl = 'ureports_report_'. $send_type_format .'_' . $attr->{REPORT_ID};
        my $check_tpl = $html->tpl_show(main::_include($send_type_tpl, 'Ureports'), $attr, { OUTPUT2RETURN => 1 });
        if ($check_tpl !~ m/No such module/x) {
          $message_template = $send_type_tpl;
        }
      }

      $message = $html->tpl_show(main::_include($message_template, 'Ureports'), $attr, { OUTPUT2RETURN => 1 });
    }

    if ($attr->{SUBJECT_TEMPLATE}) {
      $subject = $html->tpl_show(main::_include($attr->{SUBJECT_TEMPLATE}, 'Ureports'), $attr, { OUTPUT2RETURN => 1 });
    }

    if (! $destinations[$type_index] ) {
      print "Skip unknown send type: $type_index Destination: $destination\n";
      $type_index++;
      next;
    }

    $sended_distination{$send_type.'_'.$destinations[$type_index]}++;

    if ($debug > 6) {
      print "TYPE: ". ($send_type || 'Not defined')
        ." DESTINATION: ". ($destinations[$type_index] || 'Use default')
        ." MESSAGE: ". ($message || 'TPL only') ."\n";

      if ($sended_distination{$send_type.'_'.$destinations[$type_index]} > 1) {
        print "DUPLICATE DESTINATION\n\n";
      }

      $type_index++;
      next;
    }

    if ($sended_distination{$send_type.'_'.$destinations[$type_index]} > 1) {
      next;
    }

    if ($CONF->{UREPORTS_SMS_CMD}) {
      cmd("$CONF->{UREPORTS_SMS_CMD} $destinations[$type_index] $message");
    }
    else {
      $message = convert($message, { txt2translit => 1 }) if $CONF->{SMS_TRANSLIT};

      my $result = $Sender->send_message({
        UID           => $attr->{UID},
        TO_ADDRESS    => $destinations[$type_index],
        SENDER_TYPE   => $send_type,
        MESSAGE       => $message,
        SUBJECT       => in_array($send_type, [ 1 ]) ? $subject : '',
        DEBUG         => ($debug > 2) ? $debug - 2 : undef,
        RETURN_RESULT => 1,
        PARSE_MODE    => 'HTML'
      });

      if ($result) {
        if (ref $result eq 'HASH' && defined $result->{errno}) {
          $Ureports->user_send_type_change({
            UID         => $attr->{UID},
            DESTINATION => $destinations[$type_index],
            ERROR_CODE  => $result->{errno},
            ERROR_MSG   => $result->{errstr}
          });

          $status = $result->{errno} || 0;
        }
        else {
          $status = 1;
        }
      }
      else {
        $status = 0;
        $Ureports->user_send_type_change({
          UID         => $attr->{UID},
          DESTINATION => $destinations[$type_index],
          ERROR_CODE  => $status
        });
      }
    }

    $Ureports->log_add({
      DESTINATION => $destinations[$type_index],
      BODY        => $message,
      UID         => $attr->{UID},
      TP_ID       => $attr->{TP_ID} || 0,
      REPORT_ID   => $attr->{REPORT_ID} || 0,
      STATUS      => $status || 0
    }) if $debug < 5;

    push @status_list, $status;

    $type_index++;
  }

  return ($debug > 6) ? 1 : (in_array(1, \@status_list)) ? 1 : 0;
}

#**********************************************************
=head2 ureports_docs($attr)

  Arguments:

   Returns:
     boolean

=cut
#**********************************************************
sub ureports_docs {
  my $self = shift;
  my ($attr) = @_;

  my $uid = $attr->{UID} || '';
  my @services = ();
  my %info = ();
  our %FEES_METHODS;

  my $service_list = $Ureports->user_list({
    UID               => $uid,
    MONTH_FEE         => '_SHOW',
    TP_NAME           => '_SHOW',
    GROUP_BY          => 'internet.id',
    COLS_NAME         => 1
  });

  if ($attr->{FEES_INFO} || $attr->{FULL_INFO}) {
    foreach my $service_info (@{$service_list}) {
      my %FEES_DSC = (
        MODULE          => 'Ureports',
        TP_ID           => $service_info->{tp_id},
        TP_NAME         => $service_info->{tp_name},
        FEES_PERIOD_DAY => $lang->{MONTH_FEE_SHORT},
        FEES_METHOD     => $service_info->{fees_method} ? $FEES_METHODS{$service_info->{fees_method}} : undef,
        SERVICE_NAME    => 'Ureports'
      );

      $info{service_name} = ::fees_dsc_former(\%FEES_DSC);
      $info{service_desc} = q{};
      $info{tp_name} = $service_info->{tp_name};
      $info{module_name} = $lang->{UREPORTS};
      $info{month} = $service_info->{month_fee} || 0;

      return \%info if (!$attr->{FULL_INFO});

      push @services, { %info };
    }
  }

  if ($attr->{FULL_INFO} || $Ureports->{TOTAL} < 1) {
    return \@services;
  }

  return \@services;
}

#**********************************************************
=head2 ureports_user_del($uid, $attr) - Delete user from module

=cut
#**********************************************************
sub ureports_user_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  $Ureports->{UID} = $attr->{USER_INFO}{UID};
  $Ureports->user_del({ UID => $attr->{USER_INFO}{UID}, COMMENTS => $attr->{USER_INFO}{COMMENTS} });

  return 1;
}

1;
