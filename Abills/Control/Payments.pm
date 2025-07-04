=head1 NAME

  Payments manipulation

=cut


use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array mk_unique_value convert);
use Abills::Defs;

our(
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
  @MONTHES,
  @WEEKDAYS,
  %err_strs,
  @bool_vals,
  @state_colors,
  @service_status_colors,
  @service_status,
);

my $Payments = Finance->payments($db, $admin, \%conf);
our Abills::HTML $html;

#**********************************************************
=head2 form_payments($attr) Payments form

  Arguments:
    $attr

=cut
#**********************************************************
sub form_payments {
  my ($attr) = @_;

  return 0 if (!$permissions{1});

  my $allowed_payments = $Payments->admin_payment_type_list({
    COLS_NAME => 1,
    AID => $admin->{AID},
  });

  my @allowed_payments_ids = map { $_->{payments_type_id} } @{ $allowed_payments };

  my $payment_list = $Payments->payment_type_list({
    COLS_NAME => 1,
    FEES_TYPE => '_SHOW',
    SORT      => 'id',
    IDS       => scalar @allowed_payments_ids ? \@allowed_payments_ids : undef,
  });

  foreach my $line (@$payment_list) {
    $attr->{DEFAULT_ID} = $line->{id} if ($line->{default_payment});
    $attr->{PAYMENTS_METHODS}->{$line->{id}} = _translate($line->{name});
    if ($FORM{METHOD} && $FORM{METHOD} eq $line->{id} && $line->{fees_type}) {
      $attr->{GET_FEES}=$line->{fees_type};
      last;
    }
  }

  our $Docs;
  if (in_array('Docs', \@MODULES)) {
    load_module('Docs', $html);
    if ($FORM{print}) {
      if ($FORM{INVOICE_ID}) {
        docs_invoice(\%FORM);
      }
      else {
        docs_receipt(\%FORM);
      }
      exit;
    }
  }

  $FORM{METHOD} = $FORM{FIELDS} if $FORM{FIELDS};
  $FORM{METHOD} =~ s/,/;/g if $FORM{METHOD};

  if (($FORM{search_form} || $FORM{search}) && $index != 7) {
    form_search({
      HIDDEN_FIELDS => {
        subf       => ($FORM{subf}) ? $FORM{subf} : undef,
        COMPANY_ID => $FORM{COMPANY_ID},
        LEAD_ID    => $FORM{LEAD_ID},
      },
      ID            => 'SEARCH_PAYMENTS',
      ARCHIVE_TABLE => 'payments',
      CONTROL_FORM  => 1
    });
  }

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};
    $Payments->{UID} = $user->{UID};

    if (in_array('Docs', \@MODULES)) {
      $FORM{QUICK} = 1;
    }

    if (!$attr->{REGISTRATION}) {
      if (! $user->{BILL_ID}) {
        form_bills({ USER_INFO => $user });
        return 0;
      }
    }

    if ($FORM{OP_SID} && $FORM{OP_SID} eq ($COOKIES{OP_SID} || q{})) {
      $html->message( 'err', $lang{ERROR}, "$lang{EXIST}" );
    }
    elsif ($FORM{add} && $FORM{SUM}) {
      payment_add($attr);
    }
    elsif ($FORM{del} && $FORM{COMMENTS}) {
      if (!defined($permissions{1}{2})) {
        $html->message( 'err', $lang{ERROR}, "[13] $err_strs{13}" );
        return 0;
      }

      if ($permissions{0}{41}) {
        $FORM{del} =~ s/,/;/g;
      }

      my $payment_info = $Payments->list({
        ID         => $FORM{del},
        UID        => '_SHOW',
        DATETIME   => '_SHOW',
        SUM        => '_SHOW',
        DESCRIBE   => '_SHOW',
        EXT_ID     => '_SHOW',
        COLS_NAME  => 1,
        COLS_UPPER => 1,
      });

      foreach my $payment (@{$payment_info}) {
        $Payments->del($user, $payment->{ID}, { COMMENTS => $FORM{COMMENTS} });
        if ($Payments->{errno}) {
          if ($Payments->{errno} == 3) {
            $html->message('err', $lang{ERROR}, "$lang{ERR_DELETE_RECEIPT} " .
              $html->button($lang{SHOW},
                "search=1&PAYMENT_ID=$payment->{ID}&index=" . (get_function_index('docs_receipt_list')),
                { BUTTON => 1 }));
          }
          else {
            _error_show($Payments);
          }
        }
        else {
          cross_modules('payment_del', { %$attr, FORM => \%FORM, ID => $payment->{ID}, PAYMENT_INFO => $payment });
          $html->message( 'info', $lang{PAYMENTS}, "$lang{DELETED} ID: $payment->{ID}" );
        }
      }
    }

    return 1 if ($attr->{REGISTRATION} && $FORM{add});
    form_payment_add($attr);
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    require Control::Admins_mng;
    form_admins();
    return 0;
  }
  elsif ($FORM{UID} && ! $FORM{type}) {
    $index = get_function_index('form_payments');
    form_users();
    return 0;
  }

  form_payments_list($attr);

  return 0;
}

#**********************************************************
=head2 form_payment_add($attr)

  Arguments:
    $attr
      GET_FEES

=cut
#**********************************************************
sub form_payment_add {
  my ($attr) = @_;

  my $user = $attr->{USER_INFO};
  our $Docs;

  if ($user->{GID}) {
    $user->group_info($user->{GID});
    if ($user->{DISABLE_PAYMENTS}) {
      $html->message('err', $lang{ERROR}, "$lang{DISABLE} $lang{PAYMENTS} $lang{CASHBOX}");
      return 0;
    }
  }
  my %BILL_ACCOUNTS = ();
  if ($conf{EXT_BILL_ACCOUNT}) {
    $BILL_ACCOUNTS{ $user->{BILL_ID} } = "$lang{PRIMARY} : $user->{BILL_ID}" if ($user->{BILL_ID});
    $BILL_ACCOUNTS{ $user->{EXT_BILL_ID} } = "$lang{EXTRA} : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID});
  }

  my $PAYMENTS_METHODS = $attr->{PAYMENTS_METHODS};

  #exchange rate sel
  my $er_list   = $Payments->exchange_list({%FORM, COLS_NAME => 1 });
  my %ER_ISO2ID = ();
  foreach my $line (@$er_list) {
    $ER_ISO2ID{ $line->{iso} } = $line->{id};
  }

  if ($FORM{ER} && $FORM{ISO}) {
    $FORM{ER} = $ER_ISO2ID{ $FORM{ISO} };
    $FORM{ER_ID} = $ER_ISO2ID{ $FORM{ISO} };
  }
  elsif($conf{SYSTEM_CURRENCY}) {
    $FORM{ER_ID} = $ER_ISO2ID{ $conf{SYSTEM_CURRENCY} };
  }

  if ($Payments->{TOTAL} > 0) {
    $Payments->{SEL_ER} = $html->form_select('ER', {
      SELECTED       => $FORM{ER_ID} || $FORM{ER},
      SEL_LIST       => $er_list,
      SEL_KEY        => 'id',
      SEL_VALUE      => 'money,rate',
      NO_ID          => 1,
      MAIN_MENU      => get_function_index('form_exchange_rate'),
      MAIN_MENU_ARGV => "chg=" . ($FORM{ER} || ''),
      SEL_OPTIONS    => { '' => '' }
    });

    $Payments->{ER_FORM} = $html->tpl_show(templates('form_row'), {
      ID         => '',
      NAME       => "$lang{CURRENCY} : $lang{EXCHANGE_RATE}",
      VALUE      => $Payments->{SEL_ER},
      COLS_LEFT  => 'col-md-3',
      COLS_RIGHT => 'col-md-9',
    }, { OUTPUT2RETURN => 1 });
  }

  $Payments->{SEL_METHOD} = $html->form_select('METHOD', {
    SELECTED => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : ($attr->{DEFAULT_ID} || 0),
    SEL_HASH => $PAYMENTS_METHODS,
    NO_ID    => 1,
  });

  if ($permissions{1} && $permissions{1}{1}) {
    $Payments->{OP_SID} = ($FORM{OP_SID}) ? $FORM{OP_SID} : mk_unique_value(16);

    if ($conf{EXT_BILL_ACCOUNT}) {
      $Payments->{EXT_DATA_FORM} = $html->tpl_show(templates('form_row'), {
        ID    => 'BILL_ID',
        NAME  => $lang{BILL},
        VALUE => $html->form_select('BILL_ID', {
          SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
          SEL_HASH => \%BILL_ACCOUNTS,
          NO_ID    => 1
        }),
      }, { OUTPUT2RETURN => 1 });
    }

    if ($permissions{1}{4}) {
      if ($COOKIES{hold_date}) {
        ($DATE, $TIME) = split(/ /, $COOKIES{hold_date}, 2);
      }

      if ($FORM{DATE}) {
        ($DATE, $TIME) = split(/ /, $FORM{DATE});
      }

      my $date_field = $html->form_datetimepicker('DATE', $FORM{DATE}, {
        FORM_ID => 'form_payments_add',
        FORMAT  => 'YYYY-MM-DD HH:mm:ss'
      });

      $Payments->{VALUE} = $date_field;
      $Payments->{ADDON} = $html->form_input( 'hold_date', '1', {
        TYPE      => 'checkbox',
        EX_PARAMS => "NAME='hold_date' data-tooltip='$lang{HOLD}'",
        ID        => 'DATE',
        STATE     => (($COOKIES{hold_date}) ? 1 : undef)
      }, { OUTPUT2RETURN => 1 });

      $Payments->{DATE_FORM} = $html->tpl_show(templates('form_row_dynamic_size_input_group'), {
        ID    => 'DATE',
        NAME  => $lang{DATE} . ':',
        VALUE => $date_field,
        ADDON => $html->form_input('hold_date', '1', {
          TYPE      => 'checkbox',
          EX_PARAMS => "NAME='hold_date' data-tooltip='$lang{HOLD}'",
          ID        => 'DATE',
          STATE     => (($COOKIES{hold_date}) ? 1 : undef) }, { OUTPUT2RETURN => 1 }) },
        { OUTPUT2RETURN => 1 });
    }

    _docs_invoice_receipt($user);

    if ($attr->{ACTION}) {
      $Payments->{ACTION}     = $attr->{ACTION};
      $Payments->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $Payments->{ACTION}     = 'add';
      $Payments->{LNG_ACTION} = $lang{ADD};
    }

    if( in_array('Employees', \@MODULES)){
      load_module('Employees', $html);
      my $cashbox_lists = employees_cashbox_admin_payment($attr);
      $attr->{CASHBOX_SELECT} = $cashbox_lists->{CASHBOX_SELECT} || '';
      $attr->{CASHBOX_COMING_TYPE_SELECT} = $cashbox_lists->{CASHBOX_COMING_TYPE_SELECT} || '';
    }
    else {
      $attr->{CASHBOX_HIDDEN} = 'hidden'
    }

    if(in_array('Cards', \@MODULES)) {
      $attr->{CARDS_BTN}=$html->button($lang{ICARDS},
        "index=". get_function_index('cards_user_payment'). "&UID=$Payments->{UID}",
        { BUTTON => 1 })
    }

    $Payments->{ADMIN_PAY} = $lang{ADMIN_PAY};
    $Payments->table_info('payments');

    $attr->{MAX_PAYMENT} = $conf{MAX_ADMIN_PAYMENT} || 99999999;
    if ($attr->{EXT_HTML}) {
      my $payment_template = $html->tpl_show(templates('form_payments'),
        { %FORM, %{$attr}, %{$Payments} }, { ID => 'form_payments', OUTPUT2RETURN => 1 }
      );
      print "<div class='row'><div class='col-md-6'>" . $attr->{EXT_HTML} . "</div>";
      print "<div class='col-md-6'>" . $payment_template . "</div></div>";
    }
    else {
      $html->tpl_show(templates('form_payments'), { %FORM, %{$attr}, %{$Payments} }, { ID => 'form_payments'  });
    }
  }

  return 1;
}

#**********************************************************
=head2 _docs_invoice_receipt()

=cut
#**********************************************************
sub _docs_invoice_receipt {
  my $user = shift;
  
  return if (!in_array('Docs', \@MODULES) || $conf{DOCS_PAYMENT_DOCS_SKIP} || ($admin->{MODULES} && ! $admin->{MODULES}->{Docs}));

  if ($user->{GID}) {
    $user->group_info($user->{GID});
    return if !$user->{DOCUMENTS_ACCESS};
  }
  
  our $Docs;
  $Payments->{INVOICE_SEL} = $html->form_select('INVOICE_ID', {
    SELECTED         => $FORM{INVOICE_ID} || 'create' || 0,
    SEL_LIST         => $Docs->invoices_list({
      UID       => $FORM{UID},
      UNPAIMENT => 1,
      PAGE_ROWS => 200,
      SORT      => 2,
      DESC      => 'DESC',
      COLS_NAME => 1
    }),
    SEL_KEY          => 'id',
    SEL_VALUE        => 'invoice_num,date,total_sum,payment_sum',
    SEL_VALUE_PREFIX => "$lang{NUM}: ,$lang{DATE}: ,$lang{SUM}: ,$lang{PAYMENTS}: ",
    SEL_OPTIONS      => {
      0 => $lang{DONT_CREATE_INVOICE},
      %{(!$conf{PAYMENTS_NOT_CREATE_INVOICE}) ? { create => $lang{CREATE} } : {}}
    },
    NO_ID            => 1,
    MAIN_MENU        => get_function_index('docs_invoices_list'),
    MAIN_MENU_ARGV   => "UID=$FORM{UID}&INVOICE_ID=" . ($FORM{INVOICE_ID} || q{}),
  });

  delete($FORM{pdf});
  $Payments->{CREATE_RECEIPT_CHECKED}='checked'  if !$conf{DOCS_PAYMENT_RECEIPT_SKIP};
  $Payments->{SEND_MAIL}= $conf{DOCS_PAYMENT_SENDMAIL} ? 1 : 0;

  $Payments->{DOCS_INVOICE_RECEIPT_ELEMENT} = $html->tpl_show(_include('docs_create_invoice_receipt', 'Docs'),
    { %$Payments }, { OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 payment_add($attr)

=cut
#**********************************************************
sub payment_add {
  my ($attr) = @_;

  if(! $permissions{1} || ! $permissions{1}{1}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 0;
  }

  our $Docs;
  my $er;
  my $user = $attr->{USER_INFO};
  #$Payments->{AUTOFOCUS}  = '';
  $FORM{SUM} =~ s/,/\./g;
  $FORM{SUM} =~ s/\s+//g;

  $db->{TRANSACTION}=1;
  my DBI $db_ = $db->{db};
  $db_->{AutoCommit} = 0;

  if ($FORM{SUM} !~ /[0-9\.]+/) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM} SUM: $FORM{SUM}", { ID => 22 });
    return 0 if ($attr->{REGISTRATION});
  }
  else {
    my $max_payment = $conf{MAX_ADMIN_PAYMENT} || 99999999;
    if ($FORM{SUM} > $max_payment) {
      $html->message('err', "$lang{PAYMENTS}: $lang{ERR_WRONG_SUM}", "$lang{ALLOW} $lang{SUM}: < $max_payment \n$lang{PAYMENTS} $lang{SUM}: $FORM{SUM}");
      return 0;
    }

    $FORM{CURRENCY} = $conf{SYSTEM_CURRENCY};

    if ($FORM{ER}) {
      if ($FORM{DATE}) {
        my $list = $Payments->exchange_log_list({
          DATE      => "<=$FORM{DATE}",
          ID        => $FORM{ER},
          SORT      => 'date',
          DESC      => 'desc',
          PAGE_ROWS => 1
        });
        $FORM{ER_ID}    = $FORM{ER};
        $FORM{ER}       = $list->[0]->[2] || 1;
        $FORM{CURRENCY} = $list->[0]->[4] || 0;
      }
      else {
        $er = $Payments->exchange_info($FORM{ER});
        $FORM{ER_ID}    = $FORM{ER};
        $FORM{ER}       = $er->{ER_RATE};
        $FORM{CURRENCY} = $er->{ISO};
      }
    }

    $attr->{AMOUNT} = $FORM{SUM};
    if ($FORM{ER} && $FORM{ER} != 1 && $FORM{ER} > 0) {
      $FORM{PAYMENT_SUM} = sprintf("%.2f", $FORM{SUM} / $FORM{ER});
    }
    else {
      $FORM{PAYMENT_SUM} = $FORM{SUM};
    }

    my $uid = $user->{UID};
    #Make pre payments functions in all modules
    cross_modules('pre_payment', { %$attr, FORM => \%FORM });

    if (!$conf{PAYMENTS_NOT_CHECK_INVOICE_SUM} && ($FORM{INVOICE_SUM} && $FORM{INVOICE_SUM} != $FORM{PAYMENT_SUM})) {
      $html->message( 'err', "$lang{PAYMENTS}: $lang{ERR_WRONG_SUM}",
        " $lang{INVOICE} $lang{SUM}: " . ($Docs->{TOTAL_SUM} || 0) . "\n $lang{PAYMENTS} $lang{SUM}: $FORM{SUM}" );
    }
    else {
      $user->{UID} = $uid;
      $Payments->add($user, { %FORM, INNER_DESCRIBE => ($FORM{INNER_DESCRIBE} || q{})
        . (($FORM{DATE} && $COOKIES{hold_date}) ? " $DATE $TIME" : '') });

      if (_error_show($Payments)) {
        return 0 if ($attr->{REGISTRATION});
      }
      else {
        if( in_array('Employees', \@MODULES) && $FORM{CASHBOX_ID}){
          require Employees::Salary;
          Employees->import();
          my $Employees = Employees->new($db, $admin, \%conf);
          my $coming_type = $Employees->employees_list_coming_type({ COLS_NAME => 1});

          my $id_type;
          foreach my $key (@$coming_type) {
            if ($key->{default_coming} == 1){
              $id_type = $key->{id};
            }
          }

          $Employees->employees_add_coming({
            DATE           => $FORM{DATE} || $DATE,
            AMOUNT         => $FORM{SUM},
            CASHBOX_ID     => $FORM{CASHBOX_ID},
            COMING_TYPE_ID => $FORM{COMING_TYPE_ID} || $id_type,
            COMMENTS       => $FORM{DESCRIBE},
            AID            => $admin->{AID},
            UID            => $user->{UID},
            PAYMENT_ID     => $Payments->{PAYMENT_ID} || 0,
          });

          _error_show($Employees);
        }

        $FORM{SUM} = $Payments->{SUM};
        $html->message( 'info', $lang{PAYMENTS}, "$lang{ADDED} $lang{SUM}: $FORM{SUM} ". ($er->{ER_SHORT_NAME} || q{}) );

        #Make cross modules Functions
        $FORM{PAYMENTS_ID} = $Payments->{PAYMENT_ID};

        cross_modules('payments_maked', {
          %$attr,
          METHOD       => $FORM{METHOD},
          SUM          => $FORM{SUM},
          AMOUNT       => $attr->{AMOUNT},
          PAYMENT_ID   => $Payments->{PAYMENT_ID},
          SKIP_MODULES => 'Sqlcmd',
          FORM         => \%FORM
        });
      }
    }

    if ($attr->{GET_FEES}) {
      my $Fees = Finance->fees($db, $admin, \%conf);
      $user->{UID} = $uid;
      $Fees->take($user, $FORM{SUM}, {
        DESCRIBE => ($FORM{DESCRIBE} || q{}) . " PAYMENT: $Payments->{PAYMENT_ID}",
        METHOD   => $attr->{GET_FEES}
      });

      if (! $Fees->{errno}) {
        $html->message('info', $lang{FEES}, "$lang{FEES}: ". sprintf('%.2f', $FORM{SUM}));
      }
    }
  }

  if (! $attr->{REGISTRATION} && ! $db->{db}->{AutoCommit}) {
    $db_->commit();
    $db_->{AutoCommit}=1;
  }


  if ($conf{external_payments}) {
    if (!_external($conf{external_payments}, \%FORM)) {
      return 0;
    }
  }

  return 1;
}


#**********************************************************
=head2 form_payments_list()

=cut
#**********************************************************
sub form_payments_list {
  my ($attr) = @_;

  return 0 if (! $permissions{1}{0});

  my $PAYMENTS_METHODS = get_payment_methods();
  my $user = $attr->{USER_INFO};
  my %BILL_ACCOUNTS = ();
  if ($conf{EXT_BILL_ACCOUNT}) {
    $BILL_ACCOUNTS{ $user->{BILL_ID} } = "$lang{PRIMARY} : $user->{BILL_ID}" if ($user->{BILL_ID});
    $BILL_ACCOUNTS{ $user->{EXT_BILL_ID} } = "$lang{EXTRA} : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID});
  }

  if (! $FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  $LIST_PARAMS{ID} = $FORM{ID} if ($FORM{ID});

  if ($conf{SYSTEM_CURRENCY}) {
    $LIST_PARAMS{AMOUNT}='_SHOW' if (! $FORM{AMOUNT});
    $LIST_PARAMS{CURRENCY}='_SHOW' if (! $FORM{CURRENCY});
  }

  if ($FORM{INVOICE_NUM}) {
    $LIST_PARAMS{INVOICE_NUM} = $FORM{INVOICE_NUM};
  }

  if ($FORM{DESCRIBE}) {
    $LIST_PARAMS{DSC} = $FORM{DESCRIBE};
  }

  my Abills::HTML $table;
  my $payments_list;

  my $Docs;
  if (in_array('Docs', \@MODULES) && (!$admin->{MODULES} || $admin->{MODULES}{Docs})) {
    require Docs;
    Docs->import();
    $Docs = Docs->new($db, $admin, \%conf);
  }

  $index = 2;
  ($table, $payments_list) = result_former({
    INPUT_DATA      => $Payments,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    HIDDEN_FIELDS   => 'ADMIN_DISABLE,PRIORITY,TAGS_COLORS',
    DEFAULT_FIELDS  => 'DATETIME,LOGIN,DSC,SUM,LAST_DEPOSIT,METHOD,EXT_ID',
    FUNCTION_FIELDS => $permissions{1}{2} ? 'del' : '',
    FUNCTION_INDEX  => $index,
    MULTISELECT     => $FORM{UID} && $permissions{0}{41} ? 'del:id:PAYMENTS' : '',
    FILTER_VALUES   => {
      ext_deposit      => sub {
        my $ext_deposit = shift;
        $ext_deposit //= 0;

        return ($ext_deposit < 0) ? $html->color_mark(format_sum($ext_deposit), $_COLORS[6]) : format_sum($ext_deposit);
      },
      ext_id           => sub {
        my $ext_id = shift;

        return convert($ext_id, { text2html => 1 });
      },
      ext_bill_deposit => sub {
        my $ext_bill_deposit = shift;

        return $ext_bill_deposit if !$conf{EXT_BILL_ACCOUNT};
        return $ext_bill_deposit < 0 ? $html->color_mark($ext_bill_deposit, $_COLORS[6]) : $ext_bill_deposit;
      },
      deleted          => sub {
        my $deleted = shift;
        $deleted //= 0;
        return $html->color_mark($bool_vals[ $deleted ], ($deleted == 1) ? $state_colors[ $deleted ] : '')
      },
      dsc              => sub {
        my ($dsc, $line) = @_;

        $dsc = convert($dsc, { text2html => 1 }) if $dsc;
        return ($dsc || q{}) . ($line->{inner_describe} ? $html->b("($line->{inner_describe})") : '');
      },
      deposit          => sub {
        my $deposit = shift;
        $deposit //= 0;

        return ($deposit < 0) ? $html->color_mark(format_sum($deposit), $_COLORS[6]) : format_sum($deposit);
      },
      last_deposit     => sub {
        my $last_deposit = shift;
        $last_deposit //= 0;

        return ($last_deposit < 0) ? $html->color_mark(format_sum($last_deposit), $_COLORS[6]) : format_sum($last_deposit);
      },
      method           => sub {
        my $method = shift;
        $method //= 0;
        $method = ($FORM{METHOD_NUM}) ? $method : ($PAYMENTS_METHODS->{ $method } || $method);
      },
      login_status     => sub {
        my $login_status = shift;
        $login_status //= 0;

        return ($login_status > 0) ?
          $html->color_mark($service_status[ $login_status ], $service_status_colors[ $login_status ]) :
          $service_status[$login_status];
      },
      bill_id          => sub {
        my $bill_id = shift;

        return ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? ($BILL_ACCOUNTS{ $bill_id } || q{--}) : $bill_id;
      },
      admin_name       => sub {
        my ($admin_name, $line) = @_;

        $admin_name = _status_color_state($admin_name, $line->{admin_disable});
        delete $line->{admin_disable};

        return $admin_name;
      },
      invoice_num       => sub {
        my ($invoice_num, $line) = @_;

        my $payment_sum = $line->{sum} || 0;
        my $i2p = '';

        if ($Docs) {
          my $i2p_list = $Docs->invoices2payments_list({ PAYMENT_ID => $line->{id}, COLS_NAME => 1 });
          
          if ($Docs->{TOTAL} && $Docs->{TOTAL} > 0) {
            foreach my $invoice (@{$i2p_list}) {
              my $invoiced_sum = $invoice->{invoiced_sum} || 0;
              $i2p .= "$lang{PAID}: $invoiced_sum $lang{INVOICE} #" . $html->button($invoice_num,
                "index=" . get_function_index( 'docs_invoices_list' ) . "&ID=$invoice->{invoice_id}&search=1" ) . $html->br();
              $payment_sum -= $invoiced_sum;
            }
          }
        }

        if ($payment_sum > 0) {
          $i2p .= sprintf( "%.2f", $payment_sum ) . ' ' . $html->color_mark($lang{UNAPPLIED}, $_COLORS[6] ) . ' (' . $html->button( $lang{APPLY},
            "index=" . get_function_index( 'docs_invoices_list' ) . "&UNINVOICED=1&PAYMENT_ID=$line->{id}&UID=$line->{uid}" ) . ')';
        }

        return $i2p;
      }
    },
    EXT_TITLES      => {
      id              => $lang{NUM},
      datetime        => $lang{DATE},
      dsc             => $lang{DESCRIBE},
      dsc2            => "$lang{DESCRIBE} 2",
      inner_describe2 => "$lang{INNER}",
      sum             => $lang{SUM},
      last_deposit    => $lang{OPERATION_DEPOSIT},
      deposit         => $lang{CURRENT_DEPOSIT},
      method          => $lang{PAYMENT_METHOD},
      ext_id          => 'EXT ID',
      reg_date        => "$lang{PAYMENTS} $lang{REGISTRATION}",
      ip              => 'IP',
      admin_name      => $lang{ADMIN},
      a_login         => "$lang{ADMIN} $lang{LOGIN}",
      invoice_num     => $lang{INVOICE},
      amount          => "$lang{ALT} $lang{SUM}",
      currency        => $lang{CURRENCY},
      after_deposit   => $lang{AFTER_OPERATION_DEPOSIT}
    },
    TABLE           => {
      width            => '100%',
      SHOW_FULL_LIST   => ($FORM{UID}) ? 1 : undef,
      caption          => $lang{PAYMENTS},
      qs               => $pages_qs,
      EXPORT           => 1,
      ID               => 'PAYMENTS',
      MENU             => "$lang{SEARCH}:search_form=1&index=2" . (($FORM{UID}) ? "&UID=$FORM{UID}&LOGIN=" . ($users->{LOGIN} || q{}) : q{}) . ":search",
      SHOW_COLS_HIDDEN => {
        TYPE_PAGE => $FORM{type}
      },
      SELECT_ALL          => $FORM{UID} && $permissions{0}{41} ? "PAYMENTS:del:$lang{SELECT_ALL}" : '',
      MULTISELECT_ACTIONS => $FORM{UID} && $permissions{0}{41} ? [
        {
          TITLE    => $lang{DEL},
          ICON     => 'fa fa-trash',
          ACTION   => "$SELF_URL?index=$index$pages_qs",
          PARAM    => 'del',
          CLASS    => 'text-danger',
          COMMENTS => "$lang{DEL}?"
        },
      ] : [],
    },
    MAKE_ROWS       => 1
  });

  if (!$admin->{MAX_ROWS}) {
    $Payments->{TOTAL_RECALCULATION_COUNT} //= 0;
    $Payments->{TOTAL_RECALCULATION_SUM} //= 0;
    my $total_recalculation = "$lang{RECALCULATE} $lang{TOTAL}: " .  $Payments->{TOTAL_RECALCULATION_COUNT} . $html->br()
      . "$lang{RECALCULATE} $lang{SUM}: " . format_sum($Payments->{TOTAL_RECALCULATION_SUM});
    my $total_without_recalculation = "$lang{TOTAL}: " . ($Payments->{TOTAL} - $Payments->{TOTAL_RECALCULATION_COUNT}) . $html->br()
      . (($Payments->{TOTAL_USERS} && $Payments->{TOTAL_USERS} > 1) ? "$lang{USERS}: " .  ($Payments->{TOTAL_USERS}) .$html->br() : q{})
      . "$lang{SUM}: " . format_sum($Payments->{SUM} - $Payments->{TOTAL_RECALCULATION_SUM});
    $table->addfooter(
      $FORM{UID} ? ('', '') : '',
      # "$lang{TOTAL}: " .  $Payments->{TOTAL} . $html->br()
      #   . (($Payments->{TOTAL_USERS} && $Payments->{TOTAL_USERS} > 1) ? "$lang{USERS}: " .  ($Payments->{TOTAL_USERS}) .$html->br() : q{})
      #   . "$lang{SUM}: " . format_sum($Payments->{SUM}),
      $total_without_recalculation,
      $total_recalculation
    );
  }

  print $table->show();

  # $table->{SKIP_FORMER}=1;
  #
  # my %i2p_hash = ();
  # if (in_array('Docs', \@MODULES)) {
  #
  #   our $Docs;
  #   load_module('Docs', $html);
  #   my @payment_id_arr = ();
  #   foreach my $p (@$payments_list) {
  #     push @payment_id_arr, $p->{id};
  #   }
  #
  #   my $i2p_list = $Docs->invoices2payments_list({
  #     PAYMENT_ID => join(';', @payment_id_arr),
  #     PAGE_ROWS  => ($LIST_PARAMS{PAGE_ROWS} || 25)*3,
  #     COLS_NAME  => 1
  #   });
  #
  #   foreach my $i2p (@$i2p_list) {
  #     push @{ $i2p_hash{$i2p->{payment_id}} }, ($i2p->{invoice_id} || '') .':'. ($i2p->{invoiced_sum} || '') .':'. ($i2p->{invoice_num} || '');
  #   }
  # }
  #
  # $pages_qs .= "&subf=2" if (!$FORM{subf});
  #
  # foreach my $line (@$payments_list) {
  #   my $delete = ($permissions{1}{2}) ? $html->button( $lang{DEL},
  #       "index=2&del=$line->{id}$pages_qs". (($pages_qs !~ /UID=/) ? "&UID=$line->{uid}" : q{} ),
  #       { MESSAGE => "$lang{DEL} [$line->{id}] ?", class => 'del' } ) : '';
  #
  #   my @fields_array = ();
  #   for (my $i = 0; $i < 1+$Payments->{SEARCH_FIELDS_COUNT}; $i++) {
  #     my $field_name = $Payments->{COL_NAMES_ARR}->[$i] || q{};
  #
  #     if ($conf{EXT_BILL_ACCOUNT} && $field_name eq 'ext_bill_deposit') {
  #       $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
  #     }
  #     elsif($field_name eq 'deleted') {
  #       if (defined($line->{deleted})){
  #         $line->{deleted} = $html->color_mark( $bool_vals[ $line->{deleted} ],
  #             ($line->{deleted} && $line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '' );
  #       }
  #     }
  #     elsif ($field_name eq 'ext_id' && $line->{ext_id}) {
  #       $line->{ext_id} = convert($line->{ext_id}, { text2html => 1 });
  #     }
  #     elsif($field_name eq 'login' && $line->{uid}) {
  #       $line->{login} = $html->button($line->{login}, "index=15&UID=$line->{uid}");
  #     }
  #     elsif($field_name eq 'dsc') {
  #       if ($line->{dsc}) {
  #         $line->{$field_name} = convert($line->{$field_name}, { text2html => 1 });
  #       }
  #
  #       $line->{dsc} = ($line->{dsc} || q{}) . $html->b("($line->{inner_describe})") if ($line->{inner_describe});
  #     }
  #     elsif($field_name =~ /deposit/ && defined($line->{$field_name})) {
  #       $line->{$field_name} = ($line->{$field_name} < 0) ? $html->color_mark( format_sum($line->{$field_name}), $_COLORS[6] ) :  format_sum($line->{$field_name});
  #     }
  #     elsif($field_name eq 'method') {
  #       $line->{method} = ($FORM{METHOD_NUM}) ? $line->{method} : (defined($line->{method}) && $PAYMENTS_METHODS->{ defined($line->{method}) }) ? $PAYMENTS_METHODS->{ $line->{method} } : $line->{method};
  #     }
  #     elsif($field_name eq 'login_status' && defined($line->{login_status})) {
  #       $line->{login_status} = ($line->{login_status} > 0) ? $html->color_mark($service_status[ $line->{login_status} ], $service_status_colors[ $line->{login_status} ]) : $service_status[$line->{login_status}];
  #     }
  #     elsif ($field_name eq 'bill_id') {
  #       $line->{bill_id} = ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{ $line->{bill_id} } : $line->{bill_id};
  #     }
  #     elsif($field_name eq 'invoice_num') {
  #       if (in_array('Docs', \@MODULES) && ! $FORM{xml}) {
  #         my $payment_sum = $line->{sum};
  #         my $i2p         = '';
  #
  #         if ($i2p_hash{$line->{id}}) {
  #           foreach my $val ( @{ $i2p_hash{$line->{id}} }  ) {
  #             my ($invoice_id, $invoiced_sum, $invoice_num)=split(/:/, $val);
  #             $i2p .= "$lang{PAID}: $invoiced_sum $lang{INVOICE} #" . $html->button( $invoice_num,
  #               "index=" . get_function_index( 'docs_invoices_list' ) . "&ID=$invoice_id&search=1" ) . $html->br();
  #             $payment_sum -= $invoiced_sum || 0;
  #           }
  #         }
  #         if ($payment_sum > 0) {
  #           $i2p .= sprintf( "%.2f", $payment_sum ) . ' ' . $html->color_mark( "$lang{UNAPPLIED}",
  #             $_COLORS[6] ) . ' (' . $html->button( $lang{APPLY},
  #             "index=" . get_function_index( 'docs_invoices_list' ) . "&UNINVOICED=1&PAYMENT_ID=$line->{id}&UID=$line->{uid}" ) . ')';
  #         }
  #
  #         $line->{invoice_num} = $i2p;
  #       }
  #     }
  #     elsif($field_name eq 'admin_name') {
  #       $line->{admin_name} = _status_color_state($line->{admin_name}, $line->{admin_disable});
  #       delete $line->{admin_disable};
  #     }
  #
  #     if ($Payments->{SEARCH_FIELDS_COUNT} == $i) {
  #       delete $line->{admin_disable};
  #     }
  #
  #     push @fields_array, $line->{$field_name};
  #   }
  #
  #   $table->addrow(@fields_array, $delete);
  # }
  #
  # if (!$admin->{MAX_ROWS}) {
  #   $table->addfooter(
  #      '',
  #      "$lang{TOTAL}: " .  $Payments->{TOTAL} . $html->br()
  #      . (($Payments->{TOTAL_USERS} && $Payments->{TOTAL_USERS} > 1) ? "$lang{USERS}: " .  ($Payments->{TOTAL_USERS}) .$html->br() : q{})
  #      . "$lang{SUM}: " . format_sum($Payments->{SUM})
  #   );
  # }
  #
  # print $table->show();
  return 1;
}

#**********************************************************
=head2 form_back_money($type, $sum, $attr) - Back money to bill account

  Arguments:
    $type,
    $sum
    $attr
      LOGIN


  Results:
    TRUE  or FALSE

=cut
#**********************************************************
sub form_back_money {
  my ($type, $sum, $attr) = @_;
  my $uid;

  if ($type eq 'log') {
    if (defined($attr->{LOGIN})) {
      my $list = $users->list({ LOGIN => $attr->{LOGIN}, COLS_NAME => 1 });

      if ($users->{TOTAL} < 1) {
        $html->message( 'err', $lang{USER}, "[$users->{errno}] $err_strs{$users->{errno}}" );
        return 0;
      }
      $uid = $list->[0]->{uid};
    }
    else {
      $uid = $attr->{UID};
    }
  }

  my $user = $users->info($uid);

  my $OP_SID = ($FORM{OP_SID}) ? $FORM{OP_SID} : mk_unique_value(16);

  print $html->form_main({
    HIDDEN => {
      index   => $index,
      subf    => $index,
      sum     => $sum,
      OP_SID  => $OP_SID,
      UID     => $uid,
      BILL_ID => $user->{BILL_ID}
    },
    SUBMIT => { bm => "$lang{BACK_MONEY} ?" }
  });

  return 1;
}

1;