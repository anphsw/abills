=head1 NAME

  Internet Periodic

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(date_diff in_array sendmail);
use Abon;
use Fees;

our(
  $db,
  $admin,
  %conf,
  %ADMIN_REPORT,
  %lang,
  $html,
);

#**********************************************************
=head2 abon_periodic($attr) - daily_fees

  Arguments:
    DATE
    LOGIN
    TP_ID
    COMPANY_ID

  Returns:
    $DEBUG_INFO

=cut
#**********************************************************
sub abon_periodic {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || 0;
  my $debug_output = '';
  $debug_output .= "ABON: Periodic payments\n" if ($debug > 1);
  $LIST_PARAMS{LOGIN} = $attr->{LOGIN} if ($attr->{LOGIN});
  $LIST_PARAMS{COMPANY_ID} = $attr->{COMPANY_ID} if ($attr->{COMPANY_ID});

  my $Abon     = Abon->new($db, $admin, \%conf);
  my $Fees     = Fees->new($db, $admin, \%conf);

  if ($attr->{TP_ID}) {
    $attr->{TP_ID} =~ s/,/;/gx;
    $LIST_PARAMS{TP_ID} = $attr->{TP_ID};
  }

  if (in_array('Docs', \@MODULES)) {
    $FORM{QUICK} = 1;
    load_module('Docs', $html);
  }

  $Abon->{debug} = 1 if ($debug > 6);
  my $list = $Abon->periodic_list({
    DISCOUNT_ACTIVATE => '_SHOW',
    DISCOUNT_EXPIRE   => '_SHOW',
    DISCOUNT_SERVICE  => '_SHOW',
    %LIST_PARAMS,
    DELETED           => 0,
    LOGIN_STATUS      => 0,
    COLS_NAME         => 1,
    COLS_UPPER        => 1,
    PLUGIN            => '_SHOW',
    FEES_PERIOD       => '_SHOW',
  });

  my %docs_info = ();
  my $cur_date = $ADMIN_REPORT{DATE};
  my $m = (split(/-/x, $cur_date, 3))[1];
  $m--;

  foreach my $u (@{$list}) {
    $u->{DATETIME} = "$cur_date $TIME";
    if ($u->{EXT_BILL_ACCOUNT}) {
      $u->{BILL_ID} = $u->{EXT_BILL_ID};
      $u->{DEPOSIT} = $u->{EXT_DEPOSIT};
    }

    if ($debug > 2) {
      $debug_output .= "UID: $u->{UID} TP_ID: $u->{TP_ID} SUM: $u->{PRICE} DEPOSIT: "
        . ((defined($u->{DEPOSIT})) ? $u->{DEPOSIT} : 'Undefined')
        . " NOT1: $u->{NOTIFICATION1} NOT2: $u->{NOTIFICATION2} ABON: $u->{ABON_DATE} BILL_ID: "
        . ($u->{BILL_ID} || 'N/D') . "\n";
    }

    if (defined($u->{DEPOSIT})) {
      my %user = (
        UID     => $u->{UID},
        BILL_ID => $u->{BILL_ID}
      );

      my $period_dates = get_period_dates({
        TYPE         => $u->{PERIOD},
        START_PERIOD => $cur_date
      });

      my $describe = fees_dsc_former({
        TEMPLATE_KEY_NAME => 'ABON_FEES_DSC',
        SERVICE_NAME      => $lang{ABON},
        FEES_PERIOD_MONTH => ($u->{PERIOD} ? $lang{MONTH} : ''),
        FEES_PERIOD_DAY   => (!$u->{PERIOD} ? $lang{DAY} : ''),
        TP_NAME           => $u->{TP_NAME},
        TP_ID             => $u->{TP_ID},
        EXTRA             => $u->{COMMENTS},
        PERIOD            => $period_dates || (!$u->{PERIOD} ? $DATE : ''), # If period is DAY, show current date
      });

      my %PARAMS = (
        DESCRIBE => $describe,
        METHOD   => $u->{FEES_TYPE},
        DATE     => $cur_date
      );

      $u->{CREDIT} = 0 if (!$u->{CREDIT});

      my $discount = $u->{SERVICE_DISCOUNT} || 0;
      my $sum = $u->{PRICE};

      if ($discount > 0) {
        if ($u->{DISCOUNT_ACTIVATE} && date_diff($cur_date, $u->{DISCOUNT_ACTIVATE}) > 0) {
          #print " Wrong activate" if ($debug);
        }
        elsif($u->{DISCOUNT_EXPIRE} && date_diff($cur_date, $u->{DISCOUNT_EXPIRE}) < 0){
          #print " Wrong expire $DATE_, $attr->{DISCOUNT_EXPIRE}: " . date_diff($DATE_, $attr->{DISCOUNT_EXPIRE}) if ($debug);
        }
        else {
          $sum = $sum * ((100 - $discount) / 100);
        }
      }
      elsif ($u->{DISCOUNT} > 0) {
        $sum = $sum * (100 - $u->{DISCOUNT}) / 100;
      }

      if ($u->{SERVICE_COUNT} > 1) {
        $sum = $u->{SERVICE_COUNT} * $sum;
      }

      #Get daily abon
      if (!$u->{MANUAL_FEE} && ($cur_date eq $u->{ABON_DATE})
        || ($u->{PERIOD} == 0 && date_diff($cur_date, $u->{ABON_DATE}) < 2)
      ) {
        if (defined($u->{DEPOSIT}) && ($u->{DEPOSIT} + $u->{CREDIT} > 0 || $u->{PAYMENT_TYPE} == 1) && $u->{DISABLE} == 0) {
          $PARAMS{DESCRIBE} =~ s/\'/\\\'/gx;
          $Fees->{debug} = 1 if ($debug > 7);

          if ($debug < 8) {
            $Fees->take(\%user, $sum, { %PARAMS }) if ($u->{DISCOUNT} < 100);
          }

          if ($Fees->{errno}) {
            my $message = "ERROR: ABon not defined bill account UID: $u->{UID}  $Fees->{errstr}\n";
            if ($Fees->{errno} == 12)  {
              $message = "ERROR: Abon Service without sum UID: $u->{UID}  $Fees->{errstr}\n";
            }
            print $message;
            next;
          }

          my %user_tarifs_update = (
            UID   => $u->{UID},
            DATE  => $cur_date,
            TP_ID => $u->{TP_ID}
          );

          if ($u->{FEES_PERIOD}) {
            if ($u->{FEES_PERIOD} > 1) {
              $user_tarifs_update{FEES_PERIOD} = $u->{FEES_PERIOD} - 1;
            }
            else {
              $user_tarifs_update{DEL} = $u->{TP_ID};
              if ($debug < 8) {
                $Abon->user_tariff_del(\%user_tarifs_update);
              }
              %user_tarifs_update = ();
            }
          }

          if (%user_tarifs_update) {
            if ($debug < 8) {
              $Abon->user_tariff_update(\%user_tarifs_update);
            }
          }

          if ($u->{CREATE_ACCOUNT} && $u->{CREATE_DOCS}) {
            push @{$docs_info{ $user{UID} }}, {
              SUM        => $sum / (($u->{SERVICE_COUNT}) ? $u->{SERVICE_COUNT} : 1),
              COUNT      => $u->{SERVICE_COUNT},
              ORDER      => "$u->{TP_NAME} $u->{COMMENTS}",
              SEND_EMAIL => $u->{SEND_DOCS} || 0
            };
          }

          if ($u->{ext_cmd}) {
            my $cmd = $u->{ext_cmd};
            $cmd .= " ACTION=ACTIVE UID=$user{UID} TP_ID=$u->{TP_ID} COMMENTS=\"$u->{COMMENTS}\" SUM=$sum";
            my $ret = cmd($cmd);
            # if ($ret) {
            #
            # }
          }
          elsif ($u->{plugin}) {
            _plugin_action('ACTIVE', $u);
          }

          if ($u->{ACTIVATE_NOTIFICATION} && $u->{SEND_DOCS}) {
            my $message = $html->tpl_show(_include('abon_notification3', 'Abon'), { %{$Abon}, %{$u} }, { OUTPUT2RETURN => 1 });
            sendmail("$conf{ADMIN_MAIL}", "$u->{EMAIL}", "$conf{WEB_TITLE} - $u->{TP_NAME} $u->{COMMENTS}", "$message", "$conf{MAIL_CHARSET}", '', {});
          }
          $debug_output .= "$user{UID} TP_ID: $u->{TP_ID} SUM: $sum ACCOUNT: $u->{CREATE_ACCOUNT} "
            . (($u->{CREATE_ACCOUNT}) ? "ACCOUNT SEND_EMAIL: $u->{EMAIL}" : '')
            . (($u->{ACTIVATE_NOTIFICATION}) ? " NOTIFICATION: $u->{EMAIL}" : '') . "\n" if ($debug > 1);
        }

        #Send Alert
        elsif ($cur_date eq $u->{ABON_DATE} && $u->{SEND_DOCS}) {
          $debug_output .= "$user{UID} SUM: $sum TP_ID: $u->{TP_ID} $sum ACCOUNT: $u->{CREATE_ACCOUNT} Alert EMAIL: $u->{EMAIL}\n" if ($debug > 1);

          my $message = $html->tpl_show(_include('abon_alert', 'Abon'), { %{$Abon}, %{$u} }, { OUTPUT2RETURN => 1 });
          my $attach;
          if ($u->{ALERT_ACCOUNT} && $u->{CREATE_DOCS}) {
            push @{$docs_info{ $user{UID} }}, {
              SUM        => $sum / $u->{SERVICE_COUNT},
              COUNT      => $u->{SERVICE_COUNT} || 1,
              ORDER      => "$u->{TP_NAME} $u->{COMMENTS}",
              SEND_EMAIL => $u->{SEND_DOCS} || 0
            };

            if ($debug < 8) {
              $Abon->user_tariff_update({
                UID                     => $user{UID},
                NOTIFICATION            => 1,
                DATE                    => $cur_date,
                NOTIFICATION_ACCOUNT_ID => $FORM{ACCOUN_ID},
                TP_ID                   => $u->{TP_ID}
              });
            }
          }

          sendmail("$conf{ADMIN_MAIL}", "$u->{EMAIL}", "$conf{WEB_TITLE} - $u->{TP_NAME} $u->{COMMENTS}",
            "$message", "$conf{MAIL_CHARSET}", '', { ATTACHMENTS => $attach });

          if ($u->{ext_cmd}) {
            my $cmd = $u->{ext_cmd};
            $cmd .= " ACTION=ALERT UID=$user{UID} TP_ID=$u->{TP_ID} COMMENTS=\"$u->{COMMENTS}\" SUM=$sum";
            cmd($cmd);
          }
          elsif ($u->{plugin}) {
            _plugin_action('ALERT', $u);
          }
        }
      }
      #Notification Section
      elsif ($u->{NOTIFICATION1} eq $cur_date) {
        my $message = $html->tpl_show(_include('abon_notification1', 'Abon'), { %{$Abon}, %{$u} }, { OUTPUT2RETURN => 1 });
        my $attach;
        $debug_output .= "$user{UID} TP_ID: $u->{TP_ID} SUM: $sum ACCOUNT: $u->{CREATE_ACCOUNT} Notification 1 EMAIL: $u->{EMAIL}\n" if ($debug > 0);

        if ($u->{NOTIFICATION_ACCOUNT} && $u->{CREATE_DOCS}) {
          push @{$docs_info{ $user{UID} }}, {
            SUM        => $sum / $u->{SERVICE_COUNT},
            COUNT      => $u->{SERVICE_COUNT} || 1,
            ORDER      => "$u->{TP_NAME} $u->{COMMENTS}",
            SEND_EMAIL => $u->{SEND_DOCS} || 0
          };
        }

        if ($debug < 8) {
          $Abon->user_tariff_update({
            UID                     => $user{UID},
            NOTIFICATION            => 1,
            NOTIFICATION_ACCOUNT_ID => $FORM{ACCOUNT_ID},
            TP_ID                   => $u->{TP_ID}
          });
        }

        if ($u->{SEND_DOCS}) {
          sendmail("$conf{ADMIN_MAIL}", "$u->{EMAIL}", "$conf{WEB_TITLE} - $u->{TP_NAME} $u->{COMMENTS}",
            "$message", "$conf{MAIL_CHARSET}", '', { ATTACHMENTS => $attach });
        }
      }
      elsif ($u->{NOTIFICATION2} eq $cur_date) {
        $debug_output .= "$user{UID} TP_ID: $u->{TP_ID} SUM: $sum ACCOUNT: $u->{NOTIFICATION1_ACCOUNT_ID} Notification 2 EMAIL: $u->{email}\n" if ($debug > 0);

        my $message = $html->tpl_show(_include('abon_notification2', 'Abon'), { %{$Abon}, %{$u} }, { OUTPUT2RETURN => 1 });
        my $attach;

        if ($u->{NOTIFICATION1_ACCOUNT_ID} && $u->{CREATE_DOCS}) {
          $FORM{print} = $u->{NOTIFICATION1_ACCOUNT_ID};
          $FORM{CHECK_PEYMENT_ID} = 1;
          $FORM{pdf} = $conf{DOCS_PDF_PRINT};
          my $content = docs_invoice({ QUITE => 1, OUTPUT2RETURN => 1 });
          if ($content) {
            $attach = [ {
              CONTENT      => $content,
              CONTENT_TYPE => 'Content-type: application/pdf',
              FILENAME     => 'invoice.pdf'
            } ];
          }
        }

        if ($debug < 8) {
          $Abon->user_tariff_update({
            UID          => $user{UID},
            NOTIFICATION => 2,
            DATE         => $cur_date,
            TP_ID        => $u->{TP_ID}
          });
        }

        if ($u->{SEND_DOCS}) {
          sendmail("$conf{ADMIN_MAIL}", "$u->{EMAIL}", "$conf{WEB_TITLE} - $u->{TP_NAME} $u->{COMMENTS}",
            "$message", "$conf{MAIL_CHARSET}", '', { ATTACHMENTS => $attach });
        }
      }
    }
    else {
      print "[ $u->{UID} ] $u->{LOGIN} Ext bill: $u->{EXT_BILL_ACCOUNT} - Don't have money account (Abon)\n";
    }
  }

  #Create and Send documents
  if (in_array('Docs', \@MODULES)) {
    $^W = 0;
    while (my ($uid, $values) = each %docs_info) {
      my $i = 1;
      my @docs_ids = ();
      %FORM = ();
      foreach my $doc (@{$values}) {
        next if ($doc->{SUM} == 0);
        $FORM{ 'SUM_' . $i } = $doc->{SUM};
        $FORM{ 'COUNTS_' . $i } = $doc->{COUNT};
        $FORM{ 'ORDER_' . $i } = $doc->{ORDER};
        $FORM{SEND_EMAIL} = ($FORM{SEND_EMAIL}) ? 1 : $doc->{SEND_EMAIL};
        push @docs_ids, "$i";
        $i++;
      }

      $FORM{IDS} = join(', ', @docs_ids);
      $FORM{UID} = $uid;
      $FORM{create} = 1;

      if ($debug < 8) {
        docs_invoice({
          QUITE          => 1,
          SEND_EMAIL     => $FORM{SEND_EMAIL},
          OUTPUT2RETURN  => 1,
          GET_EMAIL_INFO => $FORM{SEND_EMAIL}
        });
      }
    }

    $^W = 1;
  }

  $DEBUG .= $debug_output;
  return $debug_output;
}


1;