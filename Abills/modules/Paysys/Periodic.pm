=head1 NAME

  Paysys periodic functions

=cut

use strict;
use warnings;
use Abills::Fetcher;
use Paysys;
use Payments;
use Users;
use Paysys::Init;

require Paysys::Configure;

our (
  %ADMIN_REPORT,
  $db,
  %conf,
  $admin,
  $html,
  %lang
);

my $Paysys = Paysys->new($db, $admin, \%conf);
#my $Payments = Finance->payments($db, $admin, \%conf);

#**********************************************************
=head2 paysys_periodic($attr)

  Arguments:
    $attr
      PAYSYS_ID

  Results:

=cut
#**********************************************************
sub paysys_periodic_new {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Paysys: Daily periodic payments\n" if ($debug > 1);
  my $users = Users->new($db, $admin, \%conf);

  if (!$attr->{DATE_FROM}) {
    $attr->{DATE_FROM} = POSIX::strftime('%Y-%m-%d', localtime(time - 86400 * 3));
  }

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAYSYS_ID        => $attr->{PAYSYS_ID} ? $attr->{PAYSYS_ID} : '_SHOW',
  });

  foreach my $connected_system (@$connected_systems_list) {
    my $module = $connected_system->{module};
    my $name = $connected_system->{name};

    my $Module = _configure_load_payment_module($module);
    if ($Module->can('periodic')) {
      if ($debug > 2) {
        print "Paysys periodic: $module ($connected_system->{id}/$connected_system->{paysys_id})\n";
      }
      my $Paysys_module = $Module->new($db, $admin, \%conf, {
        USER  => $users,
        NAME  => $name,
        DEBUG => $attr->{DEBUG}
      });

      $debug_output .= $Paysys_module->periodic($attr);

      if($Paysys_module->{errno}) {
        print "ERROR: $Paysys_module->{errno} $Paysys_module->{errstr}\n";
      }
    }
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


#**********************************************************
=head paysys_monthly_new($attr) - Month periodic payments

  Arguments:
    $attr
      LOGIN
      PAYSYS_ID

  Results:


=cut
#**********************************************************
sub paysys_monthly_new {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "Paysys: Monthly periodic payments\n" if ($debug > 1);

  my %USERS_LIST_PARAMS = ();

  $USERS_LIST_PARAMS{LOGIN}     = $attr->{LOGIN} if ($attr->{LOGIN});
  $USERS_LIST_PARAMS{GID}       = $attr->{GID} if ($attr->{GID});
  $USERS_LIST_PARAMS{UID}       = $attr->{UID} if ($attr->{UID});
  $USERS_LIST_PARAMS{DEPOSIT}   = $attr->{DEPOSIT} if ($attr->{DEPOSIT});

  $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
  my (undef, undef, $d) = split(/-/, $ADMIN_REPORT{DATE}, 3);
  my $START_PERIOD_DAY = $conf{START_PERIOD_DAY} || 1;

  if ($d != $START_PERIOD_DAY) {
    $DEBUG .= $debug_output;
    return $debug_output;
  }

  if ($debug > 6) {
    $Paysys->{debug}=1;
  }

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAYSYS_ID        => $attr->{PAYSYS_ID} ? $attr->{PAYSYS_ID} : '_SHOW',
  });

  foreach my $connected_system (@$connected_systems_list) {
    my $module = $connected_system->{module};
    my $name = $connected_system->{name};

    my $Module = _configure_load_payment_module($module);
    if ($Module->can('subscribe_pay')) {
      if ($debug > 2) {
        print "Paysys periodic: $module ($connected_system->{id}/$connected_system->{paysys_id})\n";
      }
      my $Paysys_module = $Module->new($db, $admin, \%conf, {
        USER  => $users,
        NAME  => $name,
        DEBUG => $attr->{DEBUG}
      });

      my $paysys_user_list = $Paysys->user_list({
        PAYSYS_ID => $connected_system->{paysys_id},
        GID       => '_SHOW',
        DEPOSIT   => '_SHOW',
        %USERS_LIST_PARAMS,
        PAGE_ROWS => 100000,
        COLS_NAME => 1
      });

    foreach my $paysys_user (@$paysys_user_list) {
      my $token = $paysys_user->{token};
      my $sum = $paysys_user->{sum} || 0;
      my $paysys_id = $paysys_user->{paysys_id};
      my $order_id = $paysys_user->{order_id} || q{};

      print "UID: $paysys_user->{uid} PAYSYS_ID: $paysys_id SUM: $sum\n" if ($debug > 0);


        $Paysys_module->subscribe_pay({
          USER     => $paysys_user,
          SUM      => $sum,
          ORDER_ID => $order_id,
          TOKEN    => $token,
          PAYSYS   => $Paysys,
          DEBUG    => $debug
        });
    }

      if($Paysys_module->{errno}) {
        print "ERROR: $Paysys_module->{errno} $Paysys_module->{errstr}\n";
      }
    }

  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


# #**********************************************************
# =head paysys_periodic_p24_api() - P24 API
#
#
# =cut
# #**********************************************************
# sub paysys_periodic_p24_api {
#   my ($attr) = @_;
#   my $debug = $attr->{DEBUG} || 0;
#
#   if ($debug) {
#     print "paysys_periodic_p24_api: ";
#   }
#
#   my @merchants = split(';', $conf{PAYSYS_P24_API_AUTO_INFO});        # list of merchants
#   my $url = "https://acp.privatbank.ua/api/proxy/transactions/today"; # url for api
#   my $success_payments = 0;
#   my $not_success_payments = 0;
#   my $already_exist_payments = 0;
#
#   foreach my $merchant (@merchants) {
#     my ($bill, $id, $token) = split(':', $merchant);
#
#     #request for transactions list
#     my $json_result = web_request($url, {
#       #      POST    => qq[{"sessionId":"$session_id"}],
#       DEBUG       => ($debug > 3) ? 1 : 0,
#       HEADERS     => [ "Content-Type: application/json; charset=utf8", "id: $id", "token: $token" ],
#       JSON_RETURN => 1,
#     });
#
#     # if there is no error
#     if ($json_result->{StatementsResponse}) {
#       # show error if something wrong
#       if (!$json_result->{StatementsResponse}->{statements} || ref $json_result->{StatementsResponse}->{statements} ne 'ARRAY') {
#         print "NOT ARRAY REF";
#         return 1;
#       }
#     }
#
#     #BPL_SUM - сумма платежа
#     #BPL_OSND - коментарий
#     #DATE_TIME_DAT_OD_TIM_P - дата время
#     #AUT_MY_NAM -
#     #BPL_PR_PR - статус(r - проведена)
#     #DATE_TIME_DAT_OD_TIM_P - дата
#
#     # get payments list for this system
#     my $payments_extid_list = 'P24_API:*';
#     my $payments_list = $Payments->list({
#       EXT_ID    => $payments_extid_list,
#       DATETIME  => '_SHOW',
#       PAGE_ROWS => 100000,
#       COLS_NAME => 1,
#     });
#
#     # make hash with added payments
#     my %added_payments = ();
#     foreach my $line (@$payments_list) {
#       if ($line->{ext_id}) {
#         $line->{ext_id} =~ s/$payments_extid_list://;
#         $added_payments{ $line->{ext_id} } = "$line->{id}:" . "$line->{uid}:" . ($line->{login} || '') . ":$line->{datetime}";
#       }
#     }
#
#     my $transactions = $json_result->{StatementsResponse}{statements}[0]{$bill};
#     foreach my $transaction (@$transactions) {
#       my ($tran_id) = keys %$transaction;
#       my $transaction_info = $transaction->{$tran_id}; # get transaction info
#
#       my $amount = $transaction_info->{BPL_SUM};
#       my $comment = $transaction_info->{BPL_OSND};
#       $comment = decode_utf8($comment);
#       my $status = $transaction_info->{BPL_PR_PR};
#       my $date = $transaction_info->{DATE_TIME_DAT_OD_TIM_P};
#       $date =~ s/\./\-/g;
#       my ($user_identifier) = $comment =~ /$conf{PAYSYS_P24_API_PARSE}/;
#
#       if (exists $added_payments{$tran_id}) {
#         print "Payment $tran_id exist\n";
#         $already_exist_payments++;
#         next;
#       }
#       else {
#         if ($conf{PAYSYS_P24_API_FILTER} && $comment =~ /$conf{PAYSYS_P24_API_FILTER}/) {
#           next;
#         }
#
#         if ($status ne "r") {
#           print "Payment $tran_id not success in private";
#           $not_success_payments++;
#           next;
#         };
#
#         if (!$user_identifier || $user_identifier eq "") {
#           print "Payment $tran_id. User identifier is empty\n";
#           $not_success_payments++;
#           next;
#         };
#
#         # if payments is new - add it to base
#         require Paysys::systems::P24_api;
#         Paysys::systems::P24_api->import();
#         my $P24 = Paysys::systems::P24_api->new(\%conf);
#
#         my $payment_status = $P24->make_payment({
#           TRANSACTION_ID => $tran_id,
#           ACCOUNT_KEY    => $user_identifier,
#           SUM            => $amount,
#           #                      DATE           => $date || $DATE,
#           COMMENT        => $comment || '',
#         });
#
#         print "Payment $tran_id. User $user_identifier. Payment status $payment_status\n";
#         $success_payments++;
#       }
#     }
#   }
#
#   print "Sucecss payments - $success_payments\n";
#   print "Not sucecss payments - $not_success_payments\n";
#   print "Already exist payments - $already_exist_payments\n";
#   return 1;
# }

#**********************************************************
=head paysys_periodic_portmone($attr) - P24 API

=cut
#**********************************************************
# sub paysys_periodic_portmone {
#   my ($attr) = @_;
#
#   my $debug = $attr->{DEBUG} || 0;
#   my $debug_output = '';
#
#   my $payment_methods = get_payment_methods();
#
#   paysys_load('Portmone');
#
#   #my $payment_system    = 'PM';
#   my $payment_system_id = 45;
#   my $status;
#
#   $ADMIN_REPORT{DATE} = $DATE if (!$ADMIN_REPORT{DATE});
#   my ($y, $m, $mday) = split(/-/, $ADMIN_REPORT{DATE});
#
#   #replace the parameters with your own values..
#   my $mon = $m - 1;
#   my $year = $y - 1900;
#   my $timestamp = POSIX::mktime(0, 0, 0, $mday, $mon, $year, 0, 0, -1);
#   my $DATE = POSIX::strftime('%Y-%m-%d', localtime($timestamp - 86400));
#   my $res_arr = paysys_portmone_result(0, { DEBUG => $debug, DATE => $DATE });
#
#   if (ref $res_arr ne 'ARRAY' || $#{$res_arr} == -1) {
#     return 0;
#   }
#
#   my %res_hash = ();
#   for (my $i = 0; $i <= $#{$res_arr}; $i++) {
#     $res_hash{ 'PM:' . $res_arr->[$i]{ordernumber} } = $i;
#   }
#
#   my $list = $Paysys->list({
#     DATE           => $DATE,
#     PAYMENT_SYSTEM => $payment_system_id,
#     ID             => '_SHOW',
#     SUM            => '_SHOW',
#     TRANSACTION_ID => '_SHOW',
#     STATUS         => 1,
#     COLS_NAME      => 1,
#   });
#
#   my $users = Users->new($db, $admin, \%conf);
#   foreach my $line (@$list) {
#     #Add payments to abills
#     $debug_output .= "Unfinished payment ID: $line->{id}/$line->{transaction_id}\n" if ($debug > 2);
#     if (defined($res_hash{ $line->{transaction_id} })) {
#       my $uid = $line->{uid};
#       my $sum = $line->{sum};
#       my $order_num = $line->{transaction_id};
#       my $user_ = $users->info($uid);
#
#       if ($res_arr->[$res_hash{$line->{transaction_id}}]{approvalcode} > 0) {
#         $Payments->add(
#           $user_,
#           {
#             SUM          => $sum,
#             DESCRIBE     => 'PORTMONE',
#             METHOD       => ($payment_methods->{$payment_system_id}) ? $payment_system_id : '2',
#             EXT_ID       => "PM:$order_num",
#             CHECK_EXT_ID => "PM:$order_num"
#           }
#         );
#       }
#
#       #Exists
#       if ($Payments->{errno}) {
#         if ($Payments->{errno} == 7) {
#           $status = 8;
#         }
#         else {
#           $status = 4;
#         }
#       }
#       else {
#         $status = 0;
#         my $info = '';
#         while (my ($k, $v) = each %{$res_arr->[$res_hash{$line->{transaction_id}}]}) {
#           $info .= "$k, $v\n";
#         }
#
#         if ($res_arr->[$res_hash{$line->{transaction_id}}]{approvalcode} > 0) {
#           $status = 2;
#           $debug_output .= "Add payments TRANSACTION_ID: $line->{transaction_id}\n" if ($debug > 0);
#         }
#         else {
#           $status = 6;
#           $debug_output .= "Add payments Error: TRANSACTION_ID: $line->{transaction_id} / [$res_hash{$line->{transaction_id}}]{error_code} ([$res_hash{$line->{transaction_id}}]{error_message}) \n" if ($debug > 0);
#         }
#
#         $Paysys->change(
#           {
#             ID     => $line->{id},
#             INFO   => $info . ' (periodic)',
#             STATUS => $status
#           }
#         );
#         $status = 1;
#       }
#
#       if ($conf{PAYSYS_EMAIL_NOTICE}) {
#         my $message = "\n" . "System: Portmone\n" . "DATE: $DATE $TIME\n" . "LOGIN: $user->{LOGIN} [$uid]\n" . "\n" . "\n" . "ID: $line->{id}\n" . "SUM: $sum\n";
#         sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "Paysys Portmone Add", "$message", "$conf{MAIL_CHARSET}", "2 (High)");
#       }
#     }
#   }
#
#   return 1;
# }

#**********************************************************
=head paysys_periodic_electrum($attr) - P24 API

=cut
#**********************************************************
sub paysys_periodic_electrum {
  my ($attr) = @_;

  #my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';

  my $payment_system_id = 125;
  my $payment_system = 'Electrum';

  require Paysys::systems::Electrum;
  Paysys::systems::Electrum->import();
  my $Electrum = Paysys::systems::Electrum->new(\%conf);

  my $list = $Paysys->list({
    PAYMENT_SYSTEM => $payment_system_id,
    ID             => '_SHOW',
    SUM            => '_SHOW',
    TRANSACTION_ID => '_SHOW',
    STATUS         => 1,
    LIST2HASH      => 'transaction_id,status'
  });

  my $list2hash = $Paysys->{list_hash};

  my $list_requests = $Electrum->list_requests();

  foreach my $request (@$list_requests) {
    if ($list2hash->{"$payment_system:$request->{id}"}) {
      if ($request->{status} eq 'Paid') {
        my $paysys_status = paysys_pay(
          {
            PAYMENT_SYSTEM    => $payment_system,
            PAYMENT_SYSTEM_ID => $payment_system_id,
            #CHECK_FIELD       => $conf{PAYSYS_YANDEX_KASSA_ACCOUNT_KEY},
            #USER_ID           => $FORM{customerNumber},
            SUM               => ($request->{amount} / 100000000),
            ORDER_ID          => "$payment_system:$request->{id}",
            EXT_ID            => $request->{id},
            # REGISTRATION_ONLY => 1,
            DATA              => $request,
            MK_LOG            => 1,
            DEBUG             => 1,
          }
        );
      }
    }
  }

  return $debug_output;
}

1;
