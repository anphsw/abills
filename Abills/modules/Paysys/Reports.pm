#package Paysys::Reports;
use strict;
use warnings FATAL => 'all';

use Abills::Base qw(date_inc convert urldecode urlencode in_array);
use Paysys::Core;
use Payments;

our (
  %lang,
  @status,
  @status_color,
  $admin,
  $db,
  @MONTHES,
  @WEEKDAYS,
  %permissions
);

our Abills::HTML $html;
our Paysys $Paysys;
my $Paysys_Core = Paysys::Core->new($db, $admin, \%conf);

#**********************************************************
=head2 paysys_log() - Show paysys operations

=cut
#**********************************************************
sub paysys_log {
  if (form_purchase_module({
    HEADER          => $user->{UID},
    MODULE          => 'Paysys',
    REQUIRE_VERSION => 9.47
  })) {
    return 0;
  }

  my %PAY_SYSTEMS = ();

  my $merchants = $Paysys->merchant_settings_list({
    ID            => '_SHOW',
    MERCHANT_NAME => '_SHOW',
    LIST2HASH     => 'id,merchant_name',
  });

  my $connected_systems = $Paysys->paysys_connect_system_list({
    PAYSYS_ID => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 50,
  });

  foreach my $payment_system (@$connected_systems) {
    $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
  }

  if ($FORM{info}) {
    $Paysys->info({ ID => $FORM{info} });
    my @info_arr = split(/\n/, $Paysys->{INFO} || q{});
    my $table = $html->table({ width => '100%' });
    my $i = 0;
    foreach my $line (@info_arr) {
      my ($k, $v) = split(/,/, $line, 2);
      # json/xml value
      if (!$i && $k && $k eq 'DATA') {
        my $value = convert($Paysys->{INFO}, { text2html => 1 });
        $table->addrow($k, $value);
        last;
      }
      else {
        my $value = convert($v, { text2html => 1 });
        $table->addrow($k, $value);
      }
      $i++;
    }

    $Paysys->{INFO} = $table->show();
    $table = $html->table({
      width   => '500',
      caption => $lang{INFO},
      rows    => [
        [ "ID", $Paysys->{ID} ],
        [ "$lang{LOGIN}", $Paysys->{LOGIN} ],
        [ "$lang{DATE}", $Paysys->{DATETIME} ],
        [ "$lang{SUM}", $Paysys->{SUM} ],
        [ "$lang{COMMISSION}", $Paysys->{COMMISSION} ],
        [ "$lang{PAY_SYSTEM}", $PAY_SYSTEMS{ $Paysys->{SYSTEM_ID} } ],
        [ "$lang{TRANSACTION}", $Paysys->{TRANSACTION_ID} ],
        [ "$lang{USER} IP", $Paysys->{CLIENT_IP} ],
        [ "PAYSYS IP", $Paysys->{PAYSYS_IP} ],
        [ "$lang{INFO}", $Paysys->{INFO} ],
        [ "$lang{ADD_INFO}", $Paysys->{USER_INFO} ],
        [ "$lang{STATUS}", $status[ $Paysys->{STATUS} ] ],
      ],
      ID      => 'PAYSYS_INFO'
    });

    print $table->show();
  }
  elsif (defined($FORM{del}) && ($FORM{COMMENTS} || $FORM{is_js_confirmed})) {
    $Paysys->del($FORM{del});

    if (!$Paysys->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $FORM{del}");
    }
  }

  _error_show($Paysys);

  my %info = ();

  if ($FORM{search_form} && !$user->{UID}) {
    my %ACTIVE_SYSTEMS = %PAY_SYSTEMS;

    $info{PAY_SYSTEMS_SEL} = $html->form_select('PAYMENT_SYSTEM', {
      SELECTED => $FORM{PAYMENT_SYSTEM} || '',
      SEL_HASH => { '' => $lang{ALL}, %ACTIVE_SYSTEMS },
      NO_ID    => 1
    });

    $info{MERCHANTS_SEL} = $html->form_select('MERCHANT_ID', {
      SELECTED => $FORM{MERCHANT_ID} || '',
      SEL_HASH => { '' => $lang{ALL}, %{$merchants} },
      NO_ID    => 1,
    });

    $info{STATUS_SEL} = $html->form_select('STATUS', {
      SELECTED     => $FORM{STATUS} || '',
      SEL_ARRAY    => \@status,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { '' => $lang{ALL} }
    });

    $info{DATERANGE_PICKER} = $html->form_daterangepicker({
      NAME  => 'FROM_DATE/TO_DATE',
      VALUE => $FORM{'FROM_DATE_TO_DATE'},
    });

    form_search({
      SEARCH_FORM   => $html->tpl_show(_include('paysys_search', 'Paysys'),
        { %info, %FORM }, { OUTPUT2RETURN => 1
      }),
      ADDRESS_FORM  => 1,
      ARCHIVE_TABLE => 'paysys_log'
    });
  }

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'list',
    BASE_FIELDS     => 7,
    FUNCTION_FIELDS => 'status, del',
    EXT_TITLES      => {
      id             => 'ID',
      system_id      => $lang{PAY_SYSTEM},
      transaction_id => $lang{TRANSACTION},
      info           => $lang{INFO},
      sum            => $lang{SUM},
      contract_id    => $lang{CONTRACT_ID},
      fio            => $lang{FIO},
      uid            => 'UID',
      bill_id        => $lang{BILL_ID},
      ip             => "$lang{USER} IP",
      status         => $lang{STATUS},
      date           => $lang{DATE},
      month          => $lang{MONTH},
      datetime       => $lang{DATE},
      merchant_id    => $lang{MERCHANT},
      merchant_name  => $lang{MERCHANT_NAME2},
      login          => $lang{LOGIN},
      ext_id         => $lang{EXTERNAL_ID},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => "Paysys",
      qs      => $pages_qs,
      pages   => $Paysys->{TOTAL},
      ID      => 'PAYSYS_LOG',
      EXPORT  => 1,
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search;",
    },
  });

  foreach my $line (@$list) {
    $line->{transaction_id} = convert($line->{transaction_id} || q{}, { text2html => 1 });
    my $status = $line->{status} || 0;
    my $system_id = $line->{system_id} || 0;
    my @fields_array = ($line->{id},
      $html->button($line->{login}, "index=15&UID=". ($line->{uid} || q{})),
      $line->{datetime},
      $line->{sum},
      (($PAY_SYSTEMS{$system_id}) ? $PAY_SYSTEMS{$system_id} : "UNKNOWN: " . $system_id),
      $html->button($line->{transaction_id}, "index=2&EXT_ID=$line->{transaction_id}&search=1"),
      "$status:" . $html->color_mark($status[$status], $status_color[$status]),
    );

    if($Paysys->{SEARCH_FIELDS_COUNT}) {
      for (my $i = 7; $i < 7 + $Paysys->{SEARCH_FIELDS_COUNT}; $i++) {
        my $field = $Paysys->{COL_NAMES_ARR}->[$i] || q{};
        push @fields_array, $line->{$field};
      }
    }

    $table->addrow(
      @fields_array,
      $html->button($lang{INFO}, "index=$index&info=$line->{id}", { class => 'show' })
        . ' ' . ($user->{UID} ? '-' : $html->button($lang{DEL}, "index=$index&del=$line->{id}",
        { MESSAGE => "$lang{DEL} $line->{id}?", class => 'del' }))
    );
  }

  print $table->show();

  $table = $html->table({
    width => '100%',
    rows  => [ [ "$lang{TOTAL}:", $html->b($Paysys->{TOTAL}), "$lang{SUM}", $html->b($Paysys->{SUM}) ],
      [ "$lang{TOTAL} $lang{COMPLETE}:", $html->b($Paysys->{TOTAL_COMPLETE}), "$lang{SUM} $lang{COMPLETE}:",
        $html->b($Paysys->{SUM_COMPLETE}) ]
    ]
  });

  print $table->show() if (!$admin->{MAX_ROWS});

  return 1;
}

#**********************************************************
=head2 paysys_reports()

=cut
#**********************************************************
sub paysys_reports {

  my $select = _paysys_select_connected_systems();
  my $selection_group = $html->element('div', $select, { class => 'input-group' });

  if ($permissions{4}) {
    my %debug_list = map { $_ => $_ } 1..9;

    my $debug_select = $html->form_select('DEBUG', {
      SELECTED => $FORM{DEBUG} || '',
      SEL_HASH => { %debug_list, '' => $lang{DEBUG} },
      NO_ID    => 1,
    });
    $selection_group .= $debug_select;
  }

  my $date_form = $html->form_daterangepicker({
    NAME => 'DATE_FROM/DATE_TO',
    DATE => $DATE
  });
  $date_form = $html->element('div', $date_form, { class => 'input-group float-left' });

  my $systems = $html->form_main({
    CONTENT => $date_form . $selection_group,
    HIDDEN  => { index => $index },
    SUBMIT  => { show => $lang{SHOW} },
    class   => 'form-main ml-auto flex-nowrap row w-100',
  });

  func_menu({ $lang{NAME} => $systems });

  if ($FORM{SYSTEM_ID}) {
    my $system_info = $Paysys->paysys_connect_system_info({
      ID               => $FORM{SYSTEM_ID},
      SHOW_ALL_COLUMNS => 1,
      COLS_NAME        => 1
    });

    my $Paysys_plugin = _configure_load_payment_module($system_info->{module}, 0, \%conf);
    my $Pay_plugin = $Paysys_plugin->new($db, $admin, \%conf, {
      CUSTOM_NAME => $system_info->{name},
      NAME        => $system_info->{name},
      CUSTOM_ID   => $system_info->{paysys_id},
      DATE        => $DATE
    });

    if ($Pay_plugin->can('report')) {
      if ($Pay_plugin->can('report_import') && ($FORM{IMPORT} || $FORM{FORCE_IMPORT}) && $FORM{IDS}) {
        _paysys_import_payments($Pay_plugin, \%FORM)
      }

      my $reg_payments = get_reg_payments({
        DATE_FROM            => $FORM{DATE_FROM},
        DATE_TO              => $FORM{DATE_TO},
        TRANSACTION_PREFIXES => ($Pay_plugin->{TRANSACTION_PREFIXES}) ? join(':*,', @{$Pay_plugin->{TRANSACTION_PREFIXES}}) . ':*' : '',
        EXT_ID               => $Pay_plugin->{SHORT_NAME}
      });

      my $report_data = $Pay_plugin->report({
        DEBUG        => $FORM{DEBUG},
        FORM         => \%FORM,
        LANG         => \%lang,
        HTML         => $html,
        INDEX        => $index,
        #OP_SID      => '',
        MONTHES      => \@MONTHES,
        WEEKDAYS     => \@WEEKDAYS,
        DATE         => $DATE,
        DATE_FROM    => $FORM{DATE_FROM},
        DATE_TO      => $FORM{DATE_TO},
        REG_PAYMENTS => $reg_payments
      });

      if ($report_data && ref $report_data eq 'HASH') {
        if ($report_data->{ERROR}) {
          $html->message('err', $lang{ERROR}, $report_data->{ERROR});
        }
        elsif ($report_data->{PAYMENTS}) {
          _paysys_report($report_data, $reg_payments, $Pay_plugin, \%FORM);
        }
        elsif ($report_data->{MESSAGE}) {
          $html->message('info', $lang{INFO}, $report_data->{MESSAGE});
        }
        else {
          $html->message('warn', $lang{INFO}, $lang{UNKNOWN_ERROR});
        }
      }
    }
    else {
      $html->message("warn", "No sub report", "This module doesnt have report sub");
    }
  }

  return 1;
}

#**********************************************************
=head2 _paysys_report()

  $Pay_plugin
  $attr

=cut
#**********************************************************
sub _paysys_import_payments {
  my ($Pay_plugin, $attr) = @_;

  my @ids = split(', ', $attr->{IDS});
  my $success_payments = 0;
  my $result = q{};
  my $result_err = q{};
  foreach my $transaction_id (@ids) {
    my $urlencoded_transaction_id = urlencode($transaction_id);
    if (!$FORM{"USER_$urlencoded_transaction_id"}) {
      $html->message('err', $lang{ERR}, "TRANSACTION: $transaction_id ERROR: $lang{UNKNOWN_UID}");
      next;
    }

    $FORM{"DESC_$urlencoded_transaction_id"} =~ s/\\\"/\"/gm if ($FORM{"DESC_$urlencoded_transaction_id"});
    my ($status) = $Pay_plugin->report_import({
      ID              => $transaction_id,
      UID             => $attr->{"USER_$urlencoded_transaction_id"} || '',
      SUM             => $attr->{"SUM_$urlencoded_transaction_id"} || '',
      DESC            => $attr->{"DESC_$urlencoded_transaction_id"} || '',
      DATE            => $attr->{"DATE_$urlencoded_transaction_id"} || '',
      MERCHANT_ID     => $attr->{"MERCHANT_$urlencoded_transaction_id"} || '0',
      FORCE_IMPORT    => $attr->{FORCE_IMPORT} ? 1 : 0,
      CURRENCY_ISO    => $attr->{CURRENCY_ISO} || 0,
      DATE_IMPORT_SEL => $attr->{DATE_IMPORT_SEL} || 0
    });

    if ($status == 0) {
      $success_payments++;
      $result .= $FORM{"USER_$urlencoded_transaction_id"} . " TRANSACTION: $transaction_id ID:  STATUS: Ok\n"
    }
    else {
      my $err_msg = "STATUS_$status";
      $result_err .= $FORM{"USER_$urlencoded_transaction_id"} . " TRANSACTION: $transaction_id ERROR STATUS: $status MESSAGE " . ($lang{$err_msg} || $lang{UNKNOWN}) . "\n";
    }
  }
  if ($result) {
    $html->message('info', $lang{INFO}, $result);
  }

  if ($result_err) {
    $html->message('err', $lang{INFO}, $result_err);
  }
}

#**********************************************************
=head2 _paysys_report()

  $report_data
    PAYMENTS: array           - all payments in this period
    TITLE: array              - column names
    NAME: string              - name of system
    IMPORT_FIELD: str         - name of field on which based import
    IMPORT_FIELDS: obj        - fields which need to use during import SUM/DESC/MERCHANT/etc...

    FIELDS?: array            - list of fields which need to be displayed
    COLUMN_FILTERS?: obj      - extra process filters on columns
    TRANSACTION_FORMAT?: obj  - custom transaction format
    FIELDS?: array            - sequence of fields for display
    SKIP_SYSTEM_PREFIX?: bool - skip payment system prefix during payment import and search
    TITLE2LANG?: bool         - convert column names to lang
    SKIP_UTF8_OFF?: bool      - skip utf-8 off for fields
    EDRPOU_CHECK?: str        - field in cvs which response for search company by EDRPOU
    MERCHANTS?: array         - custom merchants sel


  $reg_payments
  $Pay_plugin
  $attr

=cut
#**********************************************************
sub _paysys_report {
  my ($report_data, $reg_payments, $Pay_plugin, $attr) = @_;

  my %settings = $Pay_plugin->get_settings();

  my $PAYSYSTEM_SHORT_NAME = $settings{SHORT_NAME} || $attr->{PAYSYSTEM_SHORT_NAME} || $Pay_plugin->{PAYSYSTEM_SHORT_NAME} || '--';
  my $PAYSYSTEM_NAME = $settings{NAME} || $attr->{PAYSYSTEM_NAME} || '--';
  my $PAYSYSTEM_ID = $settings{ID} || $attr->{PAYSYSTEM_ID} || '--';

  my $table = '';
  my $preview_list;
  my $credit = 0;
  my $debit = 0;

  if ($attr->{IMPORT_PREVIEW} && $attr->{IDS}) {
    $preview_list = _paysys_report_preview_list($report_data, $attr);
  }

  if ($report_data->{TITLE2LANG}) {
    my $title_lang = [];

    foreach my $col_name (@{$report_data->{TITLE}}) {
      push @{$title_lang}, ($lang{$col_name || ''} || $col_name);
    }

    $report_data->{TITLE} = $title_lang;
  }

  if ($report_data->{PAYMENTS}) {
    $table = $html->table({
      width      => '100%',
      caption    => $PAYSYSTEM_NAME,
      title      => $report_data->{TITLE},
      ID         => 'PAYSYS_REPORT_TABLE',
      DATA_TABLE => { lengthMenu => [ [ 50, 100, -1 ], [ 50, 100, $lang{ALL} ] ] },
      SELECT_ALL => $lang{SELECT_ALL},
    });

    my @fields;
    if ($report_data->{FIELDS}) {
      @fields = @{$report_data->{FIELDS}};
    }
    else {
      @fields = sort keys %{$report_data->{PAYMENTS}->[0]};
    }

    my @ids = split(', ', $attr->{IDS}) if ($attr->{IDS});

    foreach my $payment (@{$report_data->{PAYMENTS}}) {

      next if ($attr->{IDS} && !in_array($payment->{$report_data->{IMPORT_FIELD}}, \@ids));

      my @result_rows = ();
      foreach my $field (@fields) {
        next if (!$field);
        my $value = $payment->{$field};
        Encode::_utf8_off($value) if (!$report_data->{SKIP_UTF8_OFF});

        if ($field eq $report_data->{IMPORT_FIELD}) {
          if ($payment->{_DEPOSIT_PAYMENT}) {
            $debit += $payment->{$report_data->{IMPORT_FIELDS}->{SUM}} || 0;
            unshift @result_rows, '', '';
            $table->{rowcolor} = 'table-info';
            push @result_rows, $value;
            next;
          }

          $credit += $payment->{$report_data->{IMPORT_FIELDS}->{SUM}} || 0;
          my $ext_id = '';
          my $transaction = '';

          # check is already present payment from other payment system
          if ($report_data->{TRANSACTION_PREFIX_CHECK}) {
            $transaction = _paysys_report_transaction_prefix_check($payment, $report_data, $reg_payments);
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
                  $transaction .=  $format->{value} || '';
                }
              }
            }
            else {
              $transaction = $value || '';
            }
          }

          if (!$ext_id) {
            $ext_id = $report_data->{SKIP_SYSTEM_PREFIX} ? $transaction : "$PAYSYSTEM_SHORT_NAME:$transaction";
          }

          my $btn_class = 'btn btn-success';
          $table->{rowcolor} = 'table-success';
          my $input_filed = q{};
          my $ext_id_field = q{};

          if ($payment->{_SKIP_PAYMENT}) {
            $ext_id_field = $payment->{_SKIP_PAYMENT};
          }
          elsif (exists($reg_payments->{$ext_id})) {
            $value = $value . ' LOGIN:' . ($reg_payments->{$ext_id}->{login} || q{});
          }
          else {
            my $checkbox_status = 0;
            my $user_id = '';
            my $user_info = '';
            my $urlencoded_ext_id = urlencode($transaction);

            if ($attr->{IMPORT_PREVIEW} && $preview_list->{$urlencoded_ext_id}) {
              my $CHECK_FIELD = $report_data->{CHECK_FIELD} || 'UID';
              $checkbox_status = 1;
              if ($preview_list->{$urlencoded_ext_id}->{status}) {
                $ext_id_field = $html->button("$lang{USER_NOT_FOUND}: " . ($preview_list->{$urlencoded_ext_id}->{status} || q{}),
                  '',
                  { class => 'btn btn-xs btn-danger' });
                $table->{rowcolor} = 'table-warning';
                $user_id = $preview_list->{$urlencoded_ext_id}->{user_id};
              }
              else {
                $ext_id_field = $html->button("$lang{LOGIN}: " . ($preview_list->{$urlencoded_ext_id}->{login} || q{}),
                  "index=15&UID=$preview_list->{$urlencoded_ext_id}->{uid}",
                  { class => 'btn btn-xs btn-info' });
                $table->{rowcolor} = 'table-warning';
                $user_id = $preview_list->{$urlencoded_ext_id}->{$CHECK_FIELD};
                $user_info = "$lang{FIO}: " . ($preview_list->{$urlencoded_ext_id}->{fio} || q{}) . " LOGIN: " . ($preview_list->{$urlencoded_ext_id}->{login} || q{});
              }
            }

            $payment->{$report_data->{IMPORT_FIELDS}->{DESC}} =~ s/\"/\\\"/gm;

            if (!$user_id) {
              if ($report_data->{EDRPOU_CHECK}) {
                $user_id = _paysys_report_edrpou_check($payment->{EDRPOU}, $report_data);
              }

              if (!$user_id && $Pay_plugin->can('_search_user')) {
                $user_id = $Pay_plugin->_search_user($payment);
              }
            }

            my $inputs = '';
            foreach my $import_field (keys %{$report_data->{IMPORT_FIELDS}}) {
              $inputs .= $html->form_input("$import_field\_$transaction", $payment->{$report_data->{IMPORT_FIELDS}->{$import_field}}, { TYPE => 'hidden' });
            }

            $input_filed = $html->form_input('IDS', $transaction, { TYPE => 'checkbox', STATE => $checkbox_status })
              . $user_info
              . $html->form_input("USER_$transaction", $user_id, { TYPE => 'text', EX_PARAMS => "style='width:100%; min-width:120px'" })
              . $inputs;

            $btn_class = 'btn btn-danger';
            if ($user_id) {
              $table->{rowcolor} = 'table-warning';
            }
            else {
              $table->{rowcolor} = 'table-danger';
            }
          }

          if (!$ext_id_field) {
            $ext_id_field = $html->button($transaction, 'index=2&search=1&EXT_ID=' . $ext_id, { class => $btn_class, ex_params => "style='width:100%; min-height:50px; margin-top:12px;'" })
          }

          unshift(@result_rows, $ext_id_field);
          unshift(@result_rows, $input_filed);
        }

        push @result_rows, $value;
      }
      $table->addrow(@result_rows);
    }
  }

  my $system_info = $Paysys->paysys_connect_system_info({ PAYSYS_ID => $PAYSYSTEM_ID, COLS_NAME => 1 });
  my $merchants = $report_data->{MERCHANTS};

  if (!$merchants) {
    $merchants = $Paysys->merchant_settings_list({
      ID            => '_SHOW',
      MERCHANT_NAME => '_SHOW',
      SYSTEM_ID     => $system_info->{id},
      COLS_NAME     => 1,
    });
  }

  my $merchant_select = $html->form_select('MERCHANT_ID', {
    SELECTED    => $attr->{MERCHANT_ID} || q{0},
    SEL_LIST    => $merchants,
    SEL_KEY     => 'id',
    SEL_VALUE   => 'merchant_name',
    NO_ID       => 1,
    SEL_OPTIONS => { '0' => $lang{ALL} },
  });

  my $date_import_sel = $html->form_select('DATE_IMPORT_SEL', {
    SELECTED => '0',
    SEL_HASH => { '0' => $lang{PAYED_IMPORT_DATE}, '1' => $lang{CURRENT_IMPORT_DATE} },
    NO_ID    => 1,
  });

  my $Payments = Payments->new($db, $admin, \%conf);
  my $exchange_list = $Payments->exchange_list({ COLS_NAME => 1 });
  my $currency_sel = '';
  if ($exchange_list) {
    $currency_sel = $html->form_select('CURRENCY_ISO', {
      SELECTED    => $attr->{CURRENCY_ISO} || '',
      SEL_LIST    => $exchange_list,
      SEL_KEY     => 'iso',
      SEL_VALUE   => 'money,rate',
      NO_ID       => 1,
      SEL_OPTIONS => { '0' => $lang{NO_CURRENCY_SELECTED} },
    });
  }

  my $show_input = $html->form_input('show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 });

  my $header = $html->tpl_show(_include('paysys_reports_header', 'Paysys'), {
    MERCHANT_SEL => $merchant_select,
    BUTTON       => $show_input,
  }, { OUTPUT2RETURN => 1 });

  my $submit_buttons = { IMPORT => $lang{IMPORT} };
  $submit_buttons->{FORCE_IMPORT} = $lang{FORCE_IMPORT} if ($conf{PAYSYS_REPORTS_FORCE_IMPORT});
  $submit_buttons->{IMPORT_PREVIEW} = $lang{PREVIEW};

  my @params = ();
  push @params, $lang{DEPOSIT}, $debit if ($debit);
  push @params, $lang{CREDIT}, $credit if ($credit);

  $table->addfooter(@params);

  print $html->form_main({
    CONTENT => $header . ($table ? $table->show() : '') . $date_import_sel . $currency_sel,
    HIDDEN  => {
      index             => $index,
      SYSTEM_ID         => $attr->{SYSTEM_ID},
      IMPORT_TYPE       => $attr->{IMPORT_TYPE} || '',
      DATE_FROM         => $attr->{DATE_FROM},
      DATE_TO           => $attr->{DATE_TO},
      DATE_FROM_DATE_TO => $attr->{DATE_FROM_DATE_TO}
    },
    SUBMIT  => $submit_buttons,
    NAME    => 'FORM_PAYSYS_REPORT_FILTER',
    ID      => 'FORM_PAYSYS_REPORT_FILTER'
  });
}

#**********************************************************
=head2 _paysys_report_preview_list()

  $report_data
    PAYMENTS: array           - all payments in this period
    TITLE: array              - column names
    NAME: string              - name of system
    IMPORT_FIELD: str         - name of field on which based import
    IMPORT_FIELDS: obj        - fields which need to use during import SUM/DESC/MERCHANT/etc...

    FIELDS?: array            - list of fields which need to be displayed
    COLUMN_FILTERS?: obj      - extra process filters on columns
    TRANSACTION_FORMAT?: obj  - extra process filters on columns

  $attr

=cut
#**********************************************************
sub _paysys_report_preview_list {
  my ($report_data, $attr) = @_;
  my %preview_list = ();

  my @ids = split(', ', $attr->{IDS});
  foreach my $transaction_id (@ids) {
    my $urlencoded_transaction_id = urlencode($transaction_id);
    my $user_id = $attr->{"USER_$urlencoded_transaction_id"};
    my ($result_code, $user) = $Paysys_Core->paysys_check_user({
      CHECK_FIELD => $report_data->{CHECK_FIELD} || 'UID',
      USER_ID     => $attr->{"USER_$urlencoded_transaction_id"}
    });

    my $result;
    if ($result_code) {
      $result = {
        status  => "$lang{RESULT} $lang{CODE} $result_code $lang{USER}: $user_id",
        user_id => $user_id
      };
    }
    else {
      $result = $user;
    }
    $preview_list{$urlencoded_transaction_id} = $result;
  }

  return \%preview_list;
}

#**********************************************************
=head2 _paysys_report_edrpou_check($edrpou)

  Arguments:
    $merchant
    $attr

  Returns:

=cut
#**********************************************************
sub _paysys_report_edrpou_check {
  my ($edrpou, $report_data) = @_;

  require Companies;
  Companies->import();
  my $Companies = Companies->new($db, $admin, \%conf);

  my $CHECK_FIELD = $report_data->{CHECK_FIELD} || 'UID';
  my $check_field = (length($edrpou) == 8) ? 'EDRPOU' : 'TAX_NUMBER';
  my $company = $Companies->list({
    COMPANY_ADMIN => '_SHOW',
    COLS_NAME     => 1,
    $check_field  => $edrpou,
  });

  my $uid = (!$Companies->{errno} && scalar @{$company}) ? ($company->[0]->{company_admin} || $company->[0]->{uid}) : '';

  return $uid if (($uid || length($edrpou) == 8) && $CHECK_FIELD eq 'UID');

  my $Users = Users->new($db, $admin, \%conf);
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
=head2 _paysys_report_transaction_prefix_check($payment, $report_data, $reg_payments)

=cut
#**********************************************************
sub _paysys_report_transaction_prefix_check {
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
=head2 _paysys_get_exchange_rates() - get user exchange rates

  Returns:
    @exchange_rates

=cut
#**********************************************************
sub _paysys_get_exchange_rates {
  if (defined($conf{PAYSYS_EXCHANGE_RATES})) {
    return split(/,\s?/, $conf{PAYSYS_EXCHANGE_RATES});
  }
  else {
    return ('USD', 'EUR', 'UAH', 'GBP', 'KZT');
  };
}

#**********************************************************
=head2 paysys_uah_exchange_rates($attr) - get exchange rates from nbu

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_uah_exchange_rates {
  my $uah_data = web_request(
    "https://bank.gov.ua/NBU_Exchange/exchange?json",
    {
      CURL        => 1,
      JSON_RETURN => 1,
    }
  );

  my $uah_table = $html->table({
    width   => '100%',
    caption => "$lang{EXCHANGE_RATE} $lang{NBU}",
    title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{UNITS} ],
    ID      => 'UAH_CURRENCY',
  });

  my @val = _paysys_get_exchange_rates();

  if (ref $uah_data eq 'ARRAY') {
    foreach my $uinfo (@{$uah_data}) {
      foreach my $keys (@val) {
        if ($uinfo->{CurrencyCodeL} eq $keys) {
          $uah_table->addrow(
            $html->b("$uinfo->{CurrencyCodeL} / UAH"),
            sprintf('%.4f', $uinfo->{Amount}),
            sprintf('%.d', $uinfo->{Units})
          );
        }
      }
    }
  }

  return $uah_table->show();
}

#**********************************************************
=head2 paysys_rub_exchange_rates() - get exchange rates from nbr

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_rub_exchange_rates {
  my $rub_data = web_request(
    "https://www.cbr-xml-daily.ru/daily_json.js",
    {
      CURL        => 1,
      JSON_RETURN => 1,
    }
  );

  my $rub_table = $html->table({
    width   => '100%',
    caption => "$lang{EXCHANGE_RATE} $lang{CBR}",
    title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{UNITS} ],
    ID      => 'RUB_CURRENCY',
  });

  my @val = _paysys_get_exchange_rates();

  if (ref $rub_data eq 'HASH') {
    foreach my $rinfo ($rub_data->{Valute}) {
      foreach my $keys (@val) {
        if (defined($rinfo->{$keys})) {
          $rub_table->addrow(
            $html->b("$rinfo->{$keys}{CharCode} / RUB"),
            sprintf('%.4f', $rinfo->{$keys}{Value}),
            sprintf('%.d', $rinfo->{$keys}{Nominal})
          );
        }
      }
    }
  }

  return $rub_table->show();
}

#**********************************************************
=head2 paysys_kgs_exchange_rates() - get exchange rates from nbkr

  Arguments:


  Returns:
    $table

=cut
#**********************************************************
sub paysys_kgs_exchange_rates {

  my $kgs_xml_data = web_request(
    "http://www.nbkr.kg/XML/daily.xml",
    {
      CURL        => 1,
    }
  );

  load_pmodule('XML::Simple');

  my $kgs_data = XML::Simple::XMLin("$kgs_xml_data", forcearray => 1);

  if ($@) {
    return 0;
  }

  my $kgs_table = $html->table({
    width   => '100%',
    caption => "$lang{EXCHANGE_RATE} $lang{NBKR}",
    title   => [ $lang{CURRENCY}, $lang{CURRENCY_BUY}, $lang{UNITS} ],
    ID      => 'NBKR_CURRENCY',
  });

  my @val = _paysys_get_exchange_rates();

  foreach my $currency (sort @ {$kgs_data->{Currency} }){
    foreach my $keys (@val) {
      if ($currency->{ISOCode} eq $keys) {
        $kgs_table->addrow($html->b("$currency->{ISOCode} / KGS"), $currency->{Value}->[0], $currency->{Nominal}->[0]);
      }
    }
  }

  return $kgs_table->show();
}

#**********************************************************
=head2 paysys_start_page($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub paysys_start_page {
  my %START_PAGE_F = (
    # 'paysys_rub_exchange_rates' => "$lang{EXCHANGE_RATE} $lang{CBR}",
    'paysys_uah_exchange_rates' => "$lang{EXCHANGE_RATE} $lang{NBU}",
    'paysys_kgs_exchange_rates' => "$lang{EXCHANGE_RATE} $lang{NBKR}"
  );

  return \%START_PAGE_F;
}

#**********************************************************
=head2 paysys_select_connected_systems($attr)

  Arguments:
    $attr

  Results:
    Select_form

=cut
#**********************************************************
sub _paysys_select_connected_systems {
  my ($attr) = @_;

  my %systems = ();
  my $systems_list = $Paysys->paysys_connect_system_list({
    STATUS    => 1,
    ID        => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 9999
  });

  foreach my $system (@{$systems_list}) {
    my $Paysys_plugin = _configure_load_payment_module($system->{module}, 0, \%conf);
    next if (!$Paysys_plugin->can('report'));
    $systems{$system->{id}} = $system->{name}
  }

  return $html->form_select('SYSTEM_ID', {
    SELECTED    => $attr->{SYSTEM_ID} || $FORM{SYSTEM_ID} || '',
    SEL_HASH    => \%systems,
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' },
  });
}

#**********************************************************
=head2 paysys_users() - Import fees from_file

=cut
#**********************************************************
sub paysys_users {

  result_former({
    INPUT_DATA      => $Paysys,
    FUNCTION        => 'user_list',
    FUNCTION_PARAMS => {
      ONLY_SUBSCRIBES => 1
    },
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'LOGIN,FIO,DEPOSIT,CREDIT,PAYSYS_ID,DATE,SUBSCRIBE_DATE_START,SUM',
    EXT_TITLES      => {
      paysys_id            => 'PAYSYS ID',
      date                 => $lang{DATE},
      sum                  => $lang{SUM},
      subscribe_date_start => $lang{START},
    },
    TABLE           => {
      width   => '100%',
      caption => "$lang{USERS} - $lang{SUBSCRIBES}",
      qs      => $pages_qs,
      ID      => 'PAYSYS_USERS_LIST',
      header  => '',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Paysys',
    TOTAL           => 1,
  });

  return 1;
}

#**********************************************************
=head2 paysys_request_log() - Show paysys requests on script paysys_check.cgi

=cut
#**********************************************************
sub paysys_request_log {
  if ($FORM{search_form} && !$user->{UID}) {
    if($FORM{FROM_DATE_TO_DATE}){
      ($FORM{FROM_DATE}, $FORM{TO_DATE}) = $FORM{"FROM_DATE_TO_DATE"} =~/(.+)\/(.+)/;
    }
    $FORM{SYSTEM_ID} = $FORM{PAYMENT_SYSTEM};
    my %PAY_SYSTEMS = ();

    my $connected_systems = $Paysys->paysys_connect_system_list({
      PAYSYS_ID => '_SHOW',
      NAME      => '_SHOW',
      MODULE    => '_SHOW',
      COLS_NAME => 1,
    });

    foreach my $payment_system (@$connected_systems) {
      $PAY_SYSTEMS{$payment_system->{paysys_id}} = $payment_system->{name};
    }

    my %ACTIVE_SYSTEMS = %PAY_SYSTEMS;
    $ACTIVE_SYSTEMS{'0'} = $lang{UNKNOWN};
    my %info = ();

    $info{PAY_SYSTEMS_SEL} = $html->form_select(
      'PAYMENT_SYSTEM',
      {
        SELECTED => $FORM{PAYMENT_SYSTEM} || '',
        SEL_HASH => { '' => $lang{ALL}, %ACTIVE_SYSTEMS },
        NO_ID    => 1
      }
    );

    $info{STATUS_SEL} = $html->form_select(
      'STATUS',
      {
        SELECTED     => $FORM{STATUS} || '',
        SEL_ARRAY    => [$lang{SUCCESS}, $lang{ERROR}],
        ARRAY_NUM_ID => 1,
        SEL_OPTIONS  => { '' => $lang{ALL} }
      }
    );

    $info{REQUEST_TYPE_SEL} = $html->form_select('REQUEST_TYPE', {
      SELECTED     => $FORM{REQUEST_TYPE} || '',
      SEL_ARRAY    => [ 'Unknown', 'Presearch', 'Search', 'Check', 'Pay', 'Confirm', 'Cancel', 'Status' ],
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { '' => $lang{ALL} }
    });

    $info{DATERANGE_PICKER} = $html->form_daterangepicker({
      NAME  => 'FROM_DATE/TO_DATE',
      VALUE => $FORM{'FROM_DATE_TO_DATE'},
    });

    form_search({
      SEARCH_FORM => $html->tpl_show(_include('paysys_search_log', 'Paysys'),
        { %info, %FORM }, { OUTPUT2RETURN => 1
      }),
      ARCHIVE_TABLE => 'paysys_requests'
    });
  }

  if ($FORM{del}) {
    $Paysys->log_del($FORM{del});

    if ($Paysys->{errno}) {
      $html->message('err', $lang{ERROR}, "$Paysys->{errno} $Paysys->{errstr}");
    }
    else {
      $html->message('info', $lang{INFO}, "$lang{DELETED} # $FORM{del}");
    }
  }

  my ($table) = result_former({
    INPUT_DATA        => $Paysys,
    FUNCTION          => 'log_list',
    BASE_FIELDS       => 0,
    FUNCTION_FIELDS   => 'del',
    DEFAULT_FIELDS    => 'ID,SYSTEM_ID,LOGIN,EXT_ID,TRANSACTION_ID,SUM,DATETIME',
    FILTER_COLS       => {
      transaction_id => '_paysys_log_filter::transaction_id,id',
      request        => '_paysys_log_filter::',
      response       => '_paysys_log_filter::',
      system_id      => '_paysys_log_filter::system_id,paysys_name',
      status         => '_paysys_log_filter::id,status',
      request_type   => '_paysys_log_filter::id,request_type',
    },
    EXT_TITLES        => {
      id             => 'ID',
      login          => $lang{LOGIN},
      request        => $lang{REQUEST},
      response       => $lang{RESPONSE},
      http_method    => "HTTP $lang{METHOD}",
      datetime       => $lang{DATE},
      ip             => 'IP',
      error          => $lang{ERROR},
      status         => $lang{STATUS},
      system_id      => $lang{PAY_SYSTEM},
      ext_id         => $lang{EXTERNAL_ID},
      transaction_id => "$lang{TRANSACTION} ID",
      sum            => $lang{SUM},
      request_type   => "$lang{REQUEST} $lang{TYPE}",
    },
    SKIP_USER_TITLE   => 1,
    SKIP_STATUS_CHECK => 1,
    TABLE             => {
      width   => '100%',
      caption => $lang{LOG_REQUESTS},
      qs      => $pages_qs,
      ID      => 'PAYSYS_REQUEST_LOG',
      pages   => $Paysys->{TOTAL},
      MENU    => "$lang{SEARCH}:index=$index&search_form=1:search;",
      EXPORT  => 1,
    },
    MODULE            => 'Paysys',
    MAKE_ROWS         => 1,
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 _extreceipt_payment_filter()

=cut
#**********************************************************
sub _paysys_log_filter {
  my ($string, $values) = @_;

  if (defined $values->{VALUES}->{status}) {
    $values->{VALUES}->{status} ? return $lang{ERROR} : return $lang{SUCCESS};
  }
  elsif (defined $values->{VALUES}->{request_type}) {
    my %statuses = (
      0 => 'Unknown',
      1 => 'Presearch',
      2 => 'Search',
      3 => 'Check',
      4 => 'Pay',
      5 => 'Confirm',
      6 => 'Cancel',
      7 => 'Status',
    );

    return $statuses{$values->{VALUES}->{request_type} || 0};
  }
  elsif (defined $values->{VALUES}->{transaction_id}) {
    return $html->button($string, 'index=' . get_function_index('paysys_log') . "&search_form=1&search=1&ID=$values->{VALUES}->{transaction_id}");
  }
  elsif (defined $values->{VALUES}->{system_id}) {
    return $values->{VALUES}->{paysys_name} || $lang{UNKNOWN};
  }
  elsif ($string) {
    $string =~ s/</&lt;/gm;
    $string =~ s/>/&gt;/gm;
    $string = '<pre>' . $string . '</pre>';
  }

  return $string;
}

1;
