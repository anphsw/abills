=head1 NAME

  Invoices managment

=cut
use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2ml mk_unique_value in_array days_in_month);
use Customers;
use Fees;
use Docs;

use Abills::Api::Handle;

our (
  $db,
  $admin,
  %conf,
  %lang,
  @units,
  @MONTHES,
  @WEEKDAYS,
  @MONTHES_LIT,
  %permissions,
  $users,

  @one,
  @ones,
  @onest,
  @twos,
  @fifth,
  @ten,
  @tens,
  @hundred,
  @money_unit_names,
);

our Abills::HTML $html;
my $Docs = Docs->new($db, $admin, \%conf);
my $Payments = Payments->new($db, $admin, \%conf);
my @service_status_colors = ($_COLORS[9], $_COLORS[6]);
my @service_status = ($lang{ENABLE}, $lang{DISABLE});
my $Fees = Fees->new($db, $admin, \%conf);

my $debug = $FORM{debug} || 0;

my $Api = Abills::Api::Handle->new($db, $admin, \%conf, {
  html    => $html,
  lang    => \%lang,
  cookies => \%COOKIES,
  direct  => 1
});

#**********************************************************
=head2 docs_invoice_company($attr)

=cut
#**********************************************************
sub docs_invoice_company {

  $FORM{ALL_SERVICES} = 1;

  docs_invoice();

  return 1;
}

#**********************************************************
=head2 docs_invoices_add_payments($attr) - add payments based on invoice

=cut
#**********************************************************
sub docs_invoices_add_payments {
  return 0 if (($user && $user->{UID}) || !$FORM{add_payment});

  my ($res) = $Api->api_call({
    METHOD => 'POST',
    PATH   => '/docs/invoices/payments/',
    PARAMS => \%FORM
  });

  return 0 if (_error_show($res));

  my ($total_count, $skip_count, $total_sum) = @{$res}{qw/total_count skip_count total_sum/};

  $html->message('info', $lang{INFO}, "$lang{ADD} $lang{PAYMENTS}\n$lang{SUM}: $total_sum"
    . "\n$lang{COUNT}: $total_count\n$lang{SKIP_PAY_ADD}: $skip_count");

  return 1;
}

#**********************************************************
=head2 docs_invoices_del_payments($attr) - del invoice

=cut
#**********************************************************
sub docs_invoices_del {
  return 0 if ($user->{UID} || (!$FORM{del_payment} && !$FORM{del}));

  my ($res) = $Api->api_call({
    METHOD => 'DELETE',
    PATH   => '/docs/invoices/',
    PARAMS => $FORM{del} ? { ID => $FORM{del} } : \%FORM
  });

  return 0 if (_error_show($res));

  my ($errors) = @{$res}{qw/errors/};

  if ($errors) {
    $html->message('err', $lang{ERROR}, "$lang{COUNT}: $errors");
  }
  else {
    my $parameter = $FORM{del} || $FORM{IDS} || '';
    $html->message('info', "$lang{INFO}", "$lang{DELETED} ID(s): [$parameter]");
  }
}

#**********************************************************
=head2 docs_invoices_del_payments($attr) - del payments based on invoice

  Arguments:
    $attr
      INVOICE_DATA


=cut
#**********************************************************
sub docs_invoice_add {
  my ($attr) = @_;

  my %invoice_create_info = ();
  if ($attr->{INVOICE_DATA}) {
    %invoice_create_info = %{$attr->{INVOICE_DATA}};
  }
  else {
    %invoice_create_info = %FORM;
  }

  if ($invoice_create_info{CUSTOMER} && $invoice_create_info{CUSTOMER} ne '-'){
    my $Users = Users->new($db, $admin, \%conf);
    my $users_pi = $Users->pi({ UID => $invoice_create_info{UID} });
    $invoice_create_info{CONTRACT_ID} = $users_pi->{CONTRACT_ID} || '';
    $invoice_create_info{CONTRACT_DATE} = $users_pi->{CONTRACT_DATE} || '';
    $invoice_create_info{INN} = $users_pi->{TAX_NUMBER} || '';
    $Docs->docs_customers_add(\%invoice_create_info);
  }
  if ($invoice_create_info{CUSTOMERS_LIST}){
    $Docs->docs_customers_info({ ID => $invoice_create_info{CUSTOMERS_LIST} });
    $invoice_create_info{CUSTOMER} = $Docs->{CUSTOMER} if ($Docs->{CUSTOMER});
  }

  $invoice_create_info{ORDER} .= ' ' . $invoice_create_info{ORDER2} if ($invoice_create_info{ORDER2});

  my $uid = $invoice_create_info{UID} || 0;

  $invoice_create_info{SUM} =~ s/\,/\./g if ($invoice_create_info{SUM});
  if ($invoice_create_info{OP_SID} && $invoice_create_info{OP_SID} eq ($COOKIES{OP_SID} || '')) {
    $html->message('err', "$lang{DOCS} : $lang{ERROR}", $lang{EXIST}, { ID => 511 });
    return 0;
  }
  #NO in
  elsif (!$invoice_create_info{IDS} && (!$invoice_create_info{SUM} || $invoice_create_info{SUM} !~ /^[0-9,\.]+$/ || $invoice_create_info{SUM} < 0.01)) {
    $html->message('err', "$lang{DOCS} :$lang{ERROR}", $lang{ERR_WRONG_SUM}, { ID => 512 });
    return 0;
  }
  elsif ($invoice_create_info{PREVIEW}) {
    docs_preview('invoice', \%invoice_create_info);
    return 1;
  }
  else {
    $FORM{ORDERS_AS_ARRAY} = 1;
    my ($add_result) = $Api->api_call({
      METHOD => 'POST',
      PATH   => ($user && $user->{UID}) ? '/user/docs/invoices/' : "/docs/invoices/",
      PARAMS => \%invoice_create_info, # %FORM
      #DEBUG  => 7
    });

    return 0 if _error_show($add_result, { MESSAGE => "$lang{DOCS}" });
    @{$Docs}{keys %{$add_result}} = values %{$add_result};

    if (!$Docs->{errno}) {
      $FORM{INVOICE_ID} = $Docs->{DOC_ID};
      $Docs->{CUSTOMER} ||= $Docs->{COMPANY_NAME} || $Docs->{FIO} || '-';

      my $orders_list = $Docs->{ORDERS};
      my $i = 0;

      foreach my $line (@{$orders_list}) {
        $i++;

        my $sum = sprintf("%.2f", $line->{counts} * $line->{price});
        if (!$FORM{pdf}) {
          $Docs->{ORDER} .= $html->tpl_show(
            _include('docs_invoice_order_row', 'Docs'),
            {
              %$Docs,
              NUMBER => $i,
              NAME   => $line->{orders},
              COUNT  => $line->{counts} || 1,
              UNIT   => $units[$line->{unit}] || 1,
              PRICE  => $line->{price},
              SUM    => $sum
            },
            { OUTPUT2RETURN => 1 }
          );
        }
      }

      $FORM{pdf} = $conf{DOCS_PDF_PRINT};

      if (!$attr->{QUITE}) {
        my $qs = "qindex=" . get_function_index('docs_invoices_list') . "&INVOICE_ID=$Docs->{DOC_ID}&UID=$uid";
        $html->message(
          'info',
          "$lang{INVOICE} $lang{CREATED}",
          "$lang{INVOICE} $lang{NUM}: [$Docs->{INVOICE_NUM}]\n $lang{DATE}: $Docs->{DATE}\n $lang{TOTAL} $lang{SUM}: " . sprintf("%.2f\n", $Docs->{TOTAL_SUM})
            . (($invoice_create_info{DOCS_CURRENCY} && $invoice_create_info{EXCHANGE_RATE} && $invoice_create_info{EXCHANGE_RATE} > 0) ? "$lang{ALT} $lang{SUM}: " . sprintf("%.2f",
            ($invoice_create_info{EXCHANGE_RATE} * $Docs->{TOTAL_SUM})) . "\n" : '')
            . $html->button("$lang{SEND} E-mail", "$qs&sendmail=$Docs->{DOC_ID}",
            { ex_params => 'target=_new', class => 'sendmail' })
            . ' '
            . $html->button($lang{PRINT}, "$qs&print=$Docs->{DOC_ID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
            { ex_params => 'target=_new', class => 'print' })
        );
      }

      $attr->{OUTPUT2RETURN} = 1 if ($FORM{SKIP_SEND_MAIL});
      $attr->{OUTPUT2RETURN} = 1 if (!$FORM{pdf});
      #TODO: add to API when will be rewrote docs_print function to package
      docs_invoice_print($Docs->{DOC_ID}, {
        GET_EMAIL_INFO => 1,
        SEND_EMAIL     => (defined($FORM{SEND_EMAIL})) ? $FORM{SEND_EMAIL} : $attr->{SEND_EMAIL},
        EMAIL          => $invoice_create_info{EMAIL},
        UID            => $uid,
        DOC_INFO       => $Docs,
        %{$attr}
      });

      return ($attr->{REGISTRATION}) ? 1 : $Docs->{DOC_ID};
    }
    else {
      if (!$invoice_create_info{QUICK}) {
        _error_show($Docs, { MESSAGE => $lang{INVOICE} });
      }
    }
  }
}

#**********************************************************
=head2 docs_invoices_list($attr) - Invoices list

  Arguments:
    $attr

  Results:

=cut
#**********************************************************
sub docs_invoices_list {
  my ($attr) = @_;

  if ($FORM{GET_FEES_INFO}) {
    require Control::Fees;
    my $fees_info = $Fees->fees_type_info({ ID => $FORM{ID} });
    my $info = {
      SUM  => $fees_info->{SUM},
      NAME => _translate(dynamic_types({ FEES_METHODS_STR => $fees_info->{DEFAULT_DESCRIBE} }))
    };
    my $json = JSON->new->utf8(0);
    print $json->encode($info);
    return 1;
  }

  if ($FORM{del_payment}) {
    docs_invoices_del();
  }

  if ($FORM{change}){
    $Docs->invoice_info($FORM{change});
    print $html->header();
    $html->tpl_show(_include('docs_invoice_change', 'Docs'), {
      INDEX => $index,
      ID    => $FORM{change},
      UID   => $FORM{UID} || '',
      %{$Docs}
    });

    return 1;
  }

  if ($attr->{USER_INFO}) {
    $FORM{UID} = $attr->{USER_INFO}->{UID};
    $LIST_PARAMS{UID} = $attr->{USER_INFO}->{UID};
  }

  if ($FORM{UNINVOICED}) {
    docs_uninvoiced();
  }
  elsif ( $FORM{SHOW_PAYMENTS} ){
    my @payments_ids_arr = ();
    my $i2p_list = $Docs->invoices2payments_list( { INVOICE_ID => $FORM{SHOW_PAYMENTS}, COLS_NAME => 1 } );
    foreach my $i2p ( @{ $i2p_list } ){
      push @payments_ids_arr, $i2p->{payment_id};
    }
    $FORM{ID} = join( ';', @payments_ids_arr );
    delete $FORM{UID};
    require Control::Payments;
    form_payments();
    return 0;
  }
  elsif ( $attr->{COMPANY} ){
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
    $index = $FORM{index};
  }
  elsif ( !$user->{UID} && $FORM{add_payment} ){
    docs_invoices_add_payments( \%FORM );
  }
  elsif ( $FORM{COMPANY_ID} && !$attr->{COMPANY} && !$FORM{qindex} && !$attr->{USER_INFO} ){
    $FORM{subf} = $FORM{index};
    $index = get_function_index('form_companies');
    require Control::Companies_mng;
    form_companies();
    return 0;
  }
  elsif ( $FORM{print} ){
    docs_invoice_print( $FORM{print}, { UID => $FORM{UID} } );
    return 0;
  }

  if ( $LIST_PARAMS{UID} || $FORM{UID} ){
    my $res = docs_invoice($attr);

    if ($res == 0) {
      return 1;
    }
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    docs_invoices_del();
  }
  elsif ($FORM{search_form} || $FORM{search}) {
    _docs_invoices_list_search();
  }

  if ($LIST_PARAMS{COMPANY_ID} || $FORM{CUSTOMER_TYPE}) {
    $LIST_PARAMS{COMPANY_ID} = $LIST_PARAMS{COMPANY_ID} || $FORM{CUSTOMER_TYPE};
  }

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = '2 desc, 1';
    $LIST_PARAMS{DESC} = 'DESC';
  }

  if ($FORM{print_list}) {
    return docs_invoice_list_print();
  }

  if ( !$user->{UID} ){
    if($attr->{USER_INFO}) {
      $LIST_PARAMS{UID} = $attr->{USER_INFO}->{UID};
    }

    $LIST_PARAMS{ORDERS_LIST} = $FORM{xml} if ($FORM{xml});
    $LIST_PARAMS{LOGIN} = '_SHOW' if (!$FORM{UID});
    $LIST_PARAMS{ALT_SUM} = ($conf{DOCS_CURRENCY}) ? '_SHOW' : undef;
  }
  else {
    delete $LIST_PARAMS{LOGIN};
    $LIST_PARAMS{CUSTOMER}='_SHOW';
    $LIST_PARAMS{ALT_SUM} = ($conf{DOCS_CURRENCY}) ? '_SHOW' : undef;
  }

  my @status_bar = (
    "$lang{ALL}:index=$index". (($FORM{UID}) ? "&UID=$FORM{UID}" : ''),
    "$lang{UNPAID}:index=$index&INVOICE_STATUS=1". (($FORM{UID}) ? "&UID=$FORM{UID}" : ''),
    "$lang{PAID}:index=$index&INVOICE_STATUS=2". (($FORM{UID}) ? "&UID=$FORM{UID}" : ''),
  );
  if ( $FORM{INVOICE_STATUS} ){
    $pages_qs .= '&INVOICE_STATUS='. $FORM{INVOICE_STATUS};
    $LIST_PARAMS{INVOICE_STATUS} = $FORM{INVOICE_STATUS};
  }

  my $PAYMENT_METHODS = get_payment_methods();
  my Abills::HTML $table;
  my $invoice_list;
  my %table_params = ();

  if ($user && $user->{UID}) {
    %table_params = (
      caption => $lang{INVOICES},
    );
  }
  else {
    %table_params = (
      caption     => $lang{INVOICES},
      SELECT_ALL  => "DOCS_INVOICES_LIST:IDS:$lang{SELECT_ALL}",
      MENU        => "$lang{SEARCH}:index=". ($index || 0) ."&search_form=1" . (($FORM{UID}) ? "&UID=$FORM{UID}" : '') . ":search",
    );
  }

  #TODO: use when will be fixed using default fields and order of fields
  # my ($invoices_list) = $Api->api_call({
  #   PATH   => ($user && $user->{UID}) ? '/user/docs/invoices/' : '/docs/invoices/',
  #   PARAMS => {
  #     %FORM,
  #     %LIST_PARAMS,
  #   }
  # });

  ($table, $invoice_list) = result_former( {
    INPUT_DATA      => $Docs,
    FUNCTION        => 'invoices_list',
    BASE_FIELDS     => (!$user->{UID}) ? 4 : 3,
    DEFAULT_FIELDS  =>
      ($FORM{UID}) ? 'INVOICE_NUM,DATE,CUSTOMER,PAYMENT_SUM' : 'INVOICE_NUM,DATE,PAYMENT_SUM',
    HIDDEN_FIELDS   => 'CURRENCY',
    FUNCTION_FIELDS =>
      (!$user->{UID}) ? (($conf{DOCS_INVOICE_ALT_TPL}) ? 'print,' : '') . 'print,payment,show,send,del' : 'print',
    MULTISELECT     => (!$user->{UID} && $FORM{UID}) ? 'UID:uid' : '',
    EXT_TITLES      => {
      invoice_num    => '#',
      date           => $lang{DATE},
      customer       => $lang{CUSTOMER},
      total_sum      => $lang{SUM},
      payment_id     => "$lang{PAYMENTS} ID",
      login          => $lang{USER},
      admin_name     => $lang{ADMIN},
      created        => $lang{CREATED},
      payment_method => $lang{PAYMENT_METHOD},
      ext_id         => "EXT ID",
      group_name     => "$lang{GROUP} $lang{NAME}",
      currency       => $lang{CURRENCY},
      alt_sum        => "$lang{ALT} $lang{SUM}",
      exchange_rate  => $lang{EXCHANGE_RATE},
      payment_sum    => $lang{PAYMENT_SUM},
      docs_deposit   => $lang{OPERATION_DEPOSIT},
      deposit        => $lang{CURRENT_DEPOSIT},
      sum_vat        => "$lang{SUM} $lang{VAT}",
      orders         => $lang{ORDERS},
      tracking_date_to     => "$lang{DOCS_SEND_INVOICE} $lang{TO} $lang{OF_CLIENT}",
      tracking_number_to   => "$lang{DOCS_TRACKING_NUMBER} $lang{TO} $lang{OF_CLIENT}",
      receive_date         => "$lang{DOCS_RECEIVE_INVOICE} $lang{BY_CLIENT}",
      tracking_date_from   => "$lang{DOCS_TRACKING_DATE} $lang{FROM} $lang{OF_CLIENT}",
      tracking_number_from => "$lang{DOCS_TRACKING_NUMBER} $lang{FROM} $lang{OF_CLIENT}",
    },
    TABLE  => {
      width       => '100%',
      qs          => $pages_qs,
      #LITE_HEADER => 1,
      ID          => 'DOCS_INVOICES_LIST',
      header      => $html->table_header(\@status_bar),
      EXPORT      => 1,
      %table_params
    },
  });

  my $invoice_list_fields = $Docs->{SEARCH_FIELDS_COUNT};
  my %i2p_hash = ();
  my @invoice_id_arr = ();

  foreach my $invoice ( @{$invoice_list} ){
    push @invoice_id_arr, $invoice->{id};
  }

  my $i2p_list = $Docs->invoices2payments_list({
    INVOICE_ID => join( ';', @invoice_id_arr ),
    COLS_NAME  => 1,
    PAGE_ROWS  => 100000
  });

  foreach my $i2p ( @{$i2p_list} ){
    push @{ $i2p_hash{($i2p->{invoice_id} || '')} }, "$i2p->{payment_id}:" . ($i2p->{invoiced_sum} || 0);
  }

  my %orders_hash = ();

  if ( $Docs->{ORDERS} ){
    %orders_hash = %{ $Docs->{ORDERS} };
  }

  foreach my $invoice ( @{$invoice_list} ){
    my @fields_array = ();

    if ( !$user->{UID} && !$FORM{qindex} ){
      push @fields_array, $html->form_input( 'IDS', $invoice->{id}, {
        TYPE    => 'checkbox',
        STATE   => (in_array( $invoice->{id}, [ split( /, /, $FORM{IDS} || '' ) ] )) ? 'checked' : undef,
        FORM_ID => 'DOCS_INVOICES_LIST',
      });
    }

    for ( my $i = 0; $i < ((!$user->{UID}) ? 4 : 3) + $invoice_list_fields; $i++ ){
      my $val = '';
      my $field_name = $Docs->{COL_NAMES_ARR}->[$i] || '';

      if ( $field_name eq 'date' ){
        $val = $html->button( "$invoice->{date}",
          "qindex=$index&print=$invoice->{id}"
            . ((! $FORM{UID}) ? "&UID=$invoice->{uid}" : q{})
            . $pages_qs . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
          , { ex_params => 'target=_new' } ),
      }
      elsif ( $field_name eq 'login_status' ){
        my $login_status = $invoice->{$field_name} || 0;
        $val = ($invoice->{$field_name} && $invoice->{$field_name} > 0) ? $html->color_mark($service_status[ $login_status ],
          $service_status_colors[ $login_status ] ) : $invoice->{$field_name};
      }
      elsif ( $field_name eq 'total_sum' ) {
        $val = sprintf("%.2f", $invoice->{total_sum});
      }
      elsif ( $field_name eq 'orders' ) {
        my $br = $html->br();
        $val = $invoice->{$field_name};
        $val =~ s/;;/$br/g;
      }
      elsif ( $field_name eq 'payment_sum' ){
        my $invoice_sum = $invoice->{total_sum};
        $val = '';

        #if ( $i2p_hash{$invoice->{id}} && !$user->{UID} ){
        if ( $i2p_hash{$invoice->{id}} ){
          foreach my $p2i_val ( @{ $i2p_hash{$invoice->{id}} } ){
            my ($payment_id, $invoiced_sum) = split( /:/, $p2i_val );

            $invoiced_sum = sprintf("%.2f", $invoiced_sum);
            if($user->{UID}) {
              $val .= $invoiced_sum;
            }
            else {
              $val .= $html->button($invoiced_sum,
                "index=" . get_function_index('form_payments') . "&ID=$payment_id&search=1");
            }
            $val .= $html->br();
            $invoice_sum -= $invoiced_sum;
          }
        }

        if ( $invoice_sum > 0 ){
          if (! $user->{UID}) {
            $val .= $html->color_mark(sprintf("%.2f", $invoice_sum),
              $_COLORS[6]) . $html->br() . ((!$user->{UID}) ? $html->button(
              "$lang{SEARCH} $lang{PAYMENTS}", "index=$index&UID=$invoice->{uid}&UNINVOICED=$invoice->{id}",
              { class => 'search' }) : '');
          }
          $table->{rowcolor}='bg-warning';
        }
      }
      elsif ( $field_name eq 'login' ){
        $val = $html->button( $invoice->{login},
          "index=11&UID=$invoice->{uid}" ) . (($invoice->{company_id}) ? $html->br() . $html->button(
          ($invoice->{company_name}) ? substr( $invoice->{company_name}, 0, 30 ) : '',
          "index=13&COMPANY_ID=$invoice->{company_id}", { class => 'small' } ) : '');
      }
      elsif ( $field_name =~ /deposit/ ){
        $val = ($invoice->{$field_name} && $invoice->{$field_name} < 0) ? $html->color_mark( $invoice->{$field_name},
          $_COLORS[6] )                    : $invoice->{$field_name};
      }
      elsif ( $field_name eq 'payment_method' ){
        $val = ($invoice->{payment_method} && $PAYMENT_METHODS->{ $invoice->{payment_method} }) ? $PAYMENT_METHODS->{ $invoice->{payment_method} } : $invoice->{payment_method};
      }
      elsif ( $field_name eq 'alt_sum' ){
        $val = _alt_sum_filter($invoice->{$field_name}, $invoice->{currency});
      }
      elsif ( $field_name eq 'send_date' || $field_name eq 'receive_date' ){
        $val = ($invoice->{$field_name} ne '0000-00-00') ? $invoice->{$field_name} : '';
      }
      else{
        $val = $invoice->{$field_name};
      }

      unless ( $field_name eq 'currency'){
        push @fields_array, $val;
      }
    }

    my @function_fields = ($html->button( $lang{PRINT},
      "qindex=$index&print=$invoice->{id}"
        . ((! $FORM{UID}) ? "&UID=$invoice->{uid}" : q{})
        . $pages_qs . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
      , { ex_params => 'target=_new', class => 'print' } )
    );

    if ( !$user->{UID} ){
      if ( $conf{DOCS_INVOICE_ALT_TPL} ){
        push @function_fields, $html->button('',
          "qindex=$index&print=$invoice->{id}&UID=$invoice->{uid}&alt_tpl=1" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : '') . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
          , { ex_params => 'target=_new', class => 'fas fa-print text-success', title => $lang{PRINT_EXT} } );
      }

      $invoice->{alt_sum} //= 0;
      my $payments_info = ($invoice->{currency} && $invoice->{currency} > 0 && !$conf{DOCS_PAYMENT_SYSTEM_CURRENCY}) ? "&SUM=$invoice->{alt_sum}&ISO=$invoice->{currency}" : "&SUM=$invoice->{total_sum}";

      if ($conf{DOCS_INVOICE_TERMO_PRINTER}) {
        push @function_fields, $html->button('',
          "qindex=$index&print=$invoice->{id}&UID=$invoice->{uid}&termo_printer_tpl=1" . (($users->{DOMAIN_ID}) ? "&DOMAIN_ID=$users->{DOMAIN_ID}" : '')
          , { ex_params => 'target=_new ', class => 'fas fa-print text-success', title => $lang{PRINT_TERMO_PRINTER} });
      }

      my $send_invoice_class = 'text-secondary';
      $send_invoice_class = 'text-primary' if ($invoice->{tracking_date_to} && $invoice->{tracking_date_to} ne '0000-00-00');
      $send_invoice_class = 'text-success' if ($invoice->{receive_date} && $invoice->{receive_date} ne '0000-00-00');

      push @function_fields,
        $html->button( $lang{PAYMENTS}, "index=2&INVOICE_ID=$invoice->{id}&UID=$invoice->{uid}$payments_info",
          { class => 'payments' } )
        , $html->button( $lang{INFO}, "index=$index&SHOW_ORDERS=$invoice->{id}&UID=$invoice->{uid}", {
          class           => 'show',
          NEW_WINDOW      => "$SELF_URL?qindex=$index&SHOW_ORDERS=$invoice->{id}&UID=$invoice->{uid}&header=1",
          NEW_WINDOW_SIZE => "640:600"
        } )
        , $html->button( $lang{SEND_MAIL},
          "qindex=" . get_function_index( 'docs_invoices_list' ) . "&sendmail=$invoice->{id}&UID=$invoice->{uid}",
          { ex_params => 'target=_new', class => 'sendmail' } )
        , $html->button( "$lang{DOCS_SEND_INVOICE}/$lang{DOCS_RECEIVE_INVOICE}",
          "qindex=" . get_function_index( 'docs_invoices_list' ) . "&change=$invoice->{id}&UID=$invoice->{uid}",
          { LOAD_TO_MODAL => 1, class => $send_invoice_class, ICON => 'fa fa-truck' } )
        , (($permissions{1} && $permissions{1}{2})  ? $html->button( $lang{DEL},
          "index=$index&del=$invoice->{id}&UID=$invoice->{uid}",
          { MESSAGE => "$lang{DEL} ID $invoice->{id} ?", class => 'del' } ) : '')
      ;

      if ( $FORM{xml} ){
        my $orders = '';
        my $i = 1;
        foreach my $order ( @{ $Docs->{ORDERS}{$invoice->{id}} } ){
          $orders .= "<orders>
                    <num>$i</num>
                    <order>". ($order->{orders} || '') ."</order>
                    <unit>". ($order->{unit} || '') ."</unit>
                    <counts>". ($order->{counts} || '') ."</counts>
                    <price>". ($order->{price} || '') ."</price>
                   </orders>";
          $i++;
        }
        push @fields_array, $orders;
      }
    }

    $table->addrow( @fields_array, join(' ', @function_fields) );
    delete $table->{rowcolor};
  }

  if ( $user && $user->{UID} ){
    printf $table->show();
  }
  else {
    my $payment_method = $html->form_select('METHOD', {
      SELECTED     => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : '',
      SEL_HASH     => get_payment_methods(),
      SORT_KEY_NUM => 1,
      NO_ID        => 1,
      FORM_ID      => 'DOCS_INVOICES_LIST',
      SEL_OPTIONS  => { '' => $lang{ALL} }
    });

    print $html->form_main({
      CONTENT => $table->show( { OUTPUT2RETURN => 1 } ) . (($FORM{json} && $payment_method) ? ",$payment_method" : $payment_method  ),
      HIDDEN  => {
        index => $index,
        pg    => $FORM{pg} || undef,
        sort  => $FORM{sort} || undef,
      },
      SUBMIT  => { 'add_payment' => "$lang{ADD} $lang{PAYMENTS}", 'del_payment' => $lang{DELETED_GROUP} },
      NAME    => 'DOCS_INVOICES_LIST',
      ID      => 'DOCS_INVOICES_LIST',
    });
  }

  if ($FORM{pg}) {
    $pages_qs .= "&pg=$FORM{pg}";
  }

  if (!$admin->{MAX_ROWS}) {
    my @total_result = ();

    push @total_result, [ "$lang{TOTAL}:", $html->b($Docs->{TOTAL_INVOICES} || 0) ];
    push @total_result,
      [ "$lang{USERS}:", $html->b($Docs->{TOTAL_USERS}) ] if ($Docs->{TOTAL_USERS} && $Docs->{TOTAL_USERS} > 1);

    if ($Docs->{TOTAL_INVOICES}) {
      push @total_result,
        [ (($user->{UID}) ? '' : $html->button("$lang{PRINT} $lang{LIST}",
          "qindex=" . $index . "&print_list=1$pages_qs" .
            (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { BUTTON => 1, ex_params => 'target=new' })) .
          (($conf{DOCS_INVOICE_ALT_TPL} && !$user->{UID})                                              ? $html->button(
            "$lang{PRINT_EXT_LIST}", "qindex=" . $index . "&print_list=1$pages_qs&alt_tpl=1" .
            (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { BUTTON => 1, ex_params => 'target=new' }) : ''),
          '' ],
        [ "$lang{SUM}:", $html->b(sprintf("%.2f", $Docs->{TOTAL_SUM} || 0)) ],
        [ "$lang{UNPAID}:", $html->b(sprintf("%.2f", ($Docs->{TOTAL_SUM} - ($Docs->{PAYMENT_SUM} || 0)))) ];
    }

    $table = $html->table({
      width => '100%',
      rows  => \@total_result,
      ID    => 'DOCS_INVOICE_TOTALS'
    });

    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 _docs_invoices_list_search($attr) - search form for invoices

  Arguments:

  Results:

=cut
#**********************************************************
sub _docs_invoices_list_search {
  return 0 if (!$FORM{search_form} && !$FORM{search});

  my $PAYMENTS_METHODS = get_payment_methods();

  my %info = ();
  $info{PAID_STATUS_SEL} = $html->form_select('PAID_STATUS', {
    SELECTED     => $FORM{PAID_STATUS},
    ARRAY_NUM_ID => 1,
    SEL_ARRAY    => [ $lang{ALL}, $lang{UNPAID}, $lang{PAID}, ],
    NO_ID        => 1
  });

  $info{PAYMENT_METHOD_SEL} = $html->form_select('PAYMENT_METHOD', {
    SELECTED => (defined($FORM{PAYMENT_METHOD}) && $FORM{PAYMENT_METHOD} ne '') ? $FORM{METHOD} : '',
    SEL_HASH => { '' => $lang{ALL}, %{$PAYMENTS_METHODS} },
    NO_ID    => 1,
    SORT_KEY => 1
  });

  $info{CUSTOMER_TYPE_SEL} = $html->form_select('CUSTOMER_TYPE', {
    SELECTED => $FORM{CUSTOMER_TYPE} || '',
    SEL_HASH => {
      ''   => $lang{ALL},
      '=0' => $lang{USERS},
      ">0" => $lang{COMPANIES}
    },
    NO_ID    => 1,
    SORT_KEY => 1
  });

  my $my_charges = $html->form_select('TYPE_FEES', {
    SELECTED     => '',
    SEL_HASH     => get_fees_types(),
    #        NO_ID       => 1,
    NORMAL_WIDTH => 1,
    SEL_OPTIONS  => { '' => '--' },
  });

  $my_charges =~ s/\n//g;
  $info{TYPES_FEES} = $my_charges;
  form_search( { SEARCH_FORM =>
    ($FORM{pdf}) ? '' : $html->tpl_show(_include('docs_invoice_search', 'Docs'), { %info, %FORM },
      { notprint => 1 }), SHOW_PERIOD => 1 });

  return 1;
}

#**********************************************************
=head2 docs_invoices_multi_create($attr)

=cut
#**********************************************************
sub docs_invoices_multi_create {
  my ($attr) = @_;

  if ( $FORM{create} ){
    if ($FORM{SUM} < 0.01) {
      $html->message('err', $lang{ERROR}, $lang{ERR_WRONG_SUM});
      return 0;
    }
    elsif (!$FORM{UIDS}) {
      $html->message('err', $lang{ERROR}, $lang{SELECT_USER});
      return 0;
    }

    my @uids_arr = split( /, /, $FORM{UIDS} );

    my $count = 0;
    my $total_sum = 0;

    delete $FORM{create};

    foreach my $uid ( @uids_arr ){
      $count++;
      $FORM{UID} = $uid;
      $FORM{ORDERS_AS_ARRAY} = 1;
      my ($add_result) = $Api->api_call({
        METHOD => 'POST',
        PATH   => "/docs/invoices/",
        PARAMS => \%FORM,
      });

      next if (_error_show($add_result));

      #TODO: add to API when will be rewrote docs_print function to package
      if (!$Docs->{errno} && $conf{DOCS_PDF_PRINT} && $FORM{SEND_EMAIL}) {
        $FORM{pdf} = 1;
        $FORM{print} = $Docs->{DOC_ID};

        docs_invoice({
          GET_EMAIL_INFO => 1,
          SEND_EMAIL     => 1,
          EMAIL          => $FORM{EMAIL},
          %{$attr}
        });
      }
    }

    $total_sum = $count * $FORM{SUM};
    $html->message( 'info', "$lang{INVOICE} $lang{CREATED}", "$lang{INVOICE} $lang{CREATED}\n $lang{COUNT}: $count \n $lang{SUM}: $total_sum" );
    return 0;
  }

  %LIST_PARAMS = (%LIST_PARAMS, %FORM);

  my ($result) = result_former({
    INPUT_DATA     => $users,
    FUNCTION       => 'list',
    DEFAULT_FIELDS => 'LOGIN,FIO',
    MULTISELECT    => 'UIDS:uid:multi_add',
    FUNCTION_INDEX => $index,
    TABLE          => {
      width      => '100%',
      caption    => $lang{USERS},
      qs         => $pages_qs,
      ID         => 'DOCS_INVOICE_USERS',
      SELECT_ALL => 'users_list:UIDS:$lang{SELECT_ALL}'
    },
    MAKE_ROWS      => 1,
    TOTAL          => 1,
    OUTPUT2RETURN  => 1
  });

  $Docs->{USERS_TABLE} = $result;
  $Docs->{DATE} = $DATE;
  $Docs->{SUM} = $FORM{SUM} || 0.00;

  $html->tpl_show( _include( 'docs_invoice_multi_add', 'Docs' ), $Docs );

  return 1;
}

#**********************************************************
=head2 docs_invoice($attr)

  Arguments:
    $attr
      INVOICE_DATA - Invoice date
      UID
      QUITE
      REGISTRATION

  Retunr:
    TRUE or FALSE

=cut
#**********************************************************
sub docs_invoice {
  my ($attr) = @_;

  $users = $user if ($user && $user->{UID});
  $Docs->invoice_defaults();
  $Docs->{DATE} = $DATE;

  my %invoice_create_info = ();
  if ( $attr->{INVOICE_DATA} ){
    %invoice_create_info = %{ $attr->{INVOICE_DATA} };
  }
  else {
    %invoice_create_info = %FORM;
  }

  if (!$invoice_create_info{UID}) {
    if ($LIST_PARAMS{UID}) {
      $invoice_create_info{UID} = $LIST_PARAMS{UID};
    }
    else {
      $invoice_create_info{UID} = $attr->{UID};
    }
  }

  my $uid = $invoice_create_info{UID} || 0;
  if ($invoice_create_info{create}) {
    return docs_invoice_add({
      %$attr,
      INVOICE_DATA => \%invoice_create_info
    });
  }
  elsif ($FORM{print}) {
    docs_invoice_print( $FORM{print}, { UID => $uid } );
    return 0;
  }
  elsif ($FORM{sendmail}) {
    my $res = docs_invoice_print($FORM{sendmail}, {
      UID            => $uid,
      SEND_EMAIL     => 1,
      GET_EMAIL_INFO => 1
    });

    if ($res) {
      $html->message( 'info', "$lang{INFO}", "$lang{SEND_REG} E-Mail" );
    }
    else{
      $html->message( 'info', "$lang{ERROR}", "$lang{SEND_REG} E-Mail  Error: $FORM{ERR_MESSAGE} " );
    }

    return 0;
  }
  elsif ($FORM{change} && $FORM{ID} && !($user && $user->{UID})) {
    my ($change_result) = $Api->api_call({
      METHOD => 'PUT',
      PATH   => "/docs/invoices/$FORM{ID}/",
      PARAMS => \%FORM,
    });

    if (!_error_show($change_result)) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED} N: [ " . ($FORM{ID} || q{}) . " ]");
    }
  }
  elsif (defined($FORM{chg}) && !($user && $user->{UID})) {
    $Docs->invoice_info($FORM{chg});
    if (!$Docs->{errno}) {
      $html->message('info', "$lang{INFO}", "$lang{CHANGING} N: [$FORM{chg}]");
    }
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS} && !($user && $user->{UID})) {
    docs_invoices_del();
  }
  elsif ($FORM{SHOW_ORDERS}) {
    $Docs->invoice_info($FORM{SHOW_ORDERS}, { UID => $uid });

    my $table = $html->table({
      width       => ($user && $user->{UID}) ? '600' : '100%',
      border      => 1,
      caption     => "$lang{INVOICE}: ". ($Docs->{INVOICE_NUM} || q{}) ." $lang{DATE}: $Docs->{DATE}",
      title_plain => [ '#', $lang{NAME}, $lang{COUNT}, $lang{PRICE}, $lang{SUM}, $lang{TAX} ],
      ID          => 'DOCS_INVOCE_ORDERS',
    });

    if ( $Docs->{TOTAL} > 0 ){
      my $orders_list = $Docs->{ORDERS};
      my $i=0;
      foreach my $order ( @{$orders_list} ){
        $i++;
        $table->addrow(
          $i,
          _translate($order->{orders}),
          $order->{counts},
          sprintf( "%.2f", $order->{price}),
          sprintf( "%.2f", $order->{counts} * $order->{price} ),
          sprintf( "%.2f", $order->{tax_sum})
        );
      }
    }

    print $table->show();
    return 0;
  }

  if (!$user || !$user->{UID}) {
    $Docs->{FORM_INVOICE_ID} = $html->tpl_show(templates('form_row'), {
      ID    => 'INVOICE_NUM',
      NAME  => $lang{NUM},
      VALUE => $html->form_input('INVOICE_NUM', '', { OUTPUT2RETURN => 1 }) },
      { OUTPUT2RETURN => 1 });

    $Docs->{DATE_FIELD} = $html->date_fld2('DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'invoice_add', WEEK_DAYS => \@WEEKDAYS });
  }
  else {
    $Docs->{DATE_FIELD} = $DATE;
    #$users = $user;
  }

  if ($conf{DOCS_FEES_METHOD_ORDERS}) {
    my %FEES_METHODS = %{get_fees_types()};
    my @orders = values %FEES_METHODS;

    $Docs->{SEL_ORDER} .= $html->form_select('ORDER', {
      SELECTED       => $FORM{ORDER} || '',
      SEL_ARRAY      => [ '', @orders ],
      NO_ID          => 1,
      MAIN_MENU      => get_function_index('form_fees_type'),
      MAIN_MENU_ARGV => "chg=" . ($FORM{ORDER} || '')
    });
  }
  else {
    $Docs->{SEL_ORDER} .= $html->form_select('ORDER', {
      SELECTED  => $FORM{ORDER},
      SEL_ARRAY => ($conf{DOCS_ORDERS}) ? $conf{DOCS_ORDERS} : [ $lang{INTERNET} ],
      NO_ID     => 1
    });
  }

  $users->pi({ UID => $users->{UID} || $uid });
  $Docs->{OP_SID} = mk_unique_value(16);
  $Docs->{CAPTION} = $lang{INVOICE};
  if (!$Docs->{MONTH}) {
    my ($year, $month, undef) = split(/-/, $DATE);
    $Docs->{MONTH} = $MONTHES[ int($month - 1) ];
    $Docs->{YEAR} = $year;
  }

  my $docs_customers_list = $Docs->docs_customers_list({
    UID       => $FORM{UID},
    CUSTOMER  => '_SHOW',
    IS_DOCS   => '_SHOW',
    DESC      => 'DESC',
    COLS_NAME => 1
  });

  my %customers_hash = ();
  if ($Docs->{TOTAL}) {
    foreach my $line (@$docs_customers_list) {
      if($line->{customer}){
        $customers_hash{$line->{id}} = (!$line->{is_docs}) ? "$line->{customer}:#f44336" : $line->{customer};
      }
    }
  }
  else {
    $Docs->{SHOW_ADD_CUSTOMER} = 1;
    $Docs->{CUSTOMER} = $users->{COMPANY_NAME} || $users->{FIO} || '';
  }

  $Docs->{CUSTOMERS_LIST} = $html->form_select('CUSTOMERS_LIST', {
    SELECTED    => '',
    SEL_HASH    => \%customers_hash,
    NO_ID       => 1,
    USE_COLORS  => 1,
  });

  if (!$FORM{pdf}) {
    docs_invoice_period({ %FORM, %$attr, UID => $uid });
  }

  return 1;
}

#**********************************************************
=head2 _docs_invoice_fees_taxes()

   Arguments:

   Returns:

=cut
#**********************************************************
sub _docs_invoice_fees_taxes {
  my %fees_tax = ();
  my $fees_type_list = $Fees->fees_type_list({
    COLS_NAME => 1,
    TAX       => '_SHOW',
    PAGE_ROWS => 10000
  });

  my $extra_fees_id = $FORM{EXTRA_INVOICE_ID} || '';
  foreach my $line (@$fees_type_list) {
    if ($line->{tax}) {
      $fees_tax{$line->{id}} = $line->{tax};
    }

    if ($extra_fees_id && $FORM{'FEES_TYPE_' . $extra_fees_id} eq $line->{id}) {
      $FORM{'SUM_' . $extra_fees_id} = $line->{sum};
      $FORM{'ORDER_' . $extra_fees_id} = $line->{name};
    }
  }

  return \%fees_tax;
}

#**********************************************************
=head2 docs_invoice_period($attr)

   Arguments:
     $attr
       REGISTRATION
       UID

   Returns:
     True or False

=cut
#**********************************************************
sub docs_invoice_period {
  my ($attr) = @_;

  my ($Y, $M, $D) = split( /-/, $DATE );

  my $uid = $attr->{UID} || 0;
  my $service_activate = $users->{ACTIVATE} || '0000-00-00';

  if ($attr->{REGISTRATION} || $FORM{ALL_SERVICES}) {
    if (!$users->{UID}) {
      $FORM{NEW_INVOICES} = 1;
    }
    else {
      $FORM{NEXT_PERIOD} = 1 if (!$FORM{NEXT_PERIOD});
    }

    my ($invoices) = $Api->api_call({
      METHOD => 'GET',
      PATH   => ($user && $user->{UID}) ? '/user/docs/invoices/period/' : "/docs/invoices/$uid/period/",
      PARAMS => { %FORM, EXTRA_INFO => 1 },
    });

    # invoice already created or service sum equal 0
    return 0 if ($invoices->{errno} && $invoices->{errno} != 1054019 && _error_show($invoices));

    if ($user && $user->{UID} && !$invoices->{TOTAL} && !$invoices->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ERR_NO_DATA} $lang{INVOICES}");
      return 1;
    }

    @{$Docs}{keys %{$invoices}} = values %{$invoices};

    my $total_sum         = 0;
    my $total_tax_sum     = 0;
    my $total_not_invoice = 0;
    my $num               = $invoices->{TOTAL} || 0;
    my $amount_for_pay    = 0;
    my $service_invoice   = '';
    my $service_info      = $invoices->{SERVICE_INFO};

    if ($Docs->{INVOICE_DATE}) {
      $service_activate = $Docs->{INVOICE_DATE};
    }
    elsif($FORM{NEXT_PERIOD} && $FORM{NEXT_PERIOD} > 1) {
      $html->message('warn', "Use user docs configuration for multiperiod ". $html->button($lang{CONFIGURATION}, 'index='. get_function_index('docs_user') ."&UID=$uid"  ));
    }

    $Docs->{DATE} = $html->date_fld2( 'DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'receipt_add', WEEK_DAYS => \@WEEKDAYS } );

    my %fees_tax = %{_docs_invoice_fees_taxes() || {}};

    my $table = $html->table({
      width       => '100%',
      caption     => ($users->{UID}) ? $lang{ACTIVATE_NEXT_PERIOD} : "$lang{INVOICE} $lang{PERIOD}: $Y-$M",
      title_plain => [ '#', $lang{DATE}, $lang{LOGIN}, $lang{DESCRIBE}, $lang{SUM}, ($user) ? undef : $lang{TAX} ],
      pages       => $Docs->{TOTAL},
      ID          => 'DOCS_INVOICE_ORDERS',
    });

    if (!$users->{UID} && $invoices->{NEW_INVOICES}) {
      foreach my $line (@{$invoices->{NEW_INVOICES}}) {
        $table->addrow(
          $html->form_input("ORDER_" . $line->{id}, $line->{dsc}, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
            . $html->form_input("SUM_" . $line->{id}, $line->{sum}, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
            . $html->form_input("FEES_ID_" . $line->{id}, $line->{id}, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
            . $html->form_input("IDS", $line->{id}, { TYPE => 'checkbox', STATE => 1, OUTPUT2RETURN => 1 })
            . $line->{num},
          $line->{date},
          $line->{login},
          $line->{dsc},
          $line->{sum},
          $line->{tax},
        );

        $total_not_invoice += $line->{sum};
      }
    }

    my $date = $DATE;
    if ($service_activate ne '0000-00-00') {
      $date = $service_activate;
      $FORM{FROM_DATE} = $service_activate;
    }
    ($Y, $M, $D) = split( /-/, $date );

    if ($FORM{NEXT_PERIOD}) {
      my $service_orders = $invoices->{SERVICE_ORDERS};
      foreach my $module (keys %$service_orders) {
        foreach my $doc_id (keys %{$service_orders->{$module}}) {
          my $invoice_info = $service_orders->{$module}->{$doc_id};
          $table->addrow(
            (
              (!$invoice_info->{current_invoice}) ? $html->form_input('ORDER_' . $invoice_info->{num}, $invoice_info->{order},
                { TYPE => 'hidden', OUTPUT2RETURN => 1 })
                . $html->form_input('SUM_' . $invoice_info->{num}, $invoice_info->{result_sum}, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
                . $html->form_input('IDS', $invoice_info->{num},
                { TYPE => ($users->{UID}) ? 'hidden' : 'checkbox', STATE => 'checked', OUTPUT2RETURN => 1 })
                . $invoice_info->{num}
                . $html->form_input('FEES_TYPE_' . $invoice_info->{num}, $invoice_info->{fees_type}, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
                : ''
            ),
            $invoice_info->{date},
            $invoice_info->{login},
            $invoice_info->{order} . (($invoice_info->{current_invoice}) ? ' ' . $html->color_mark($lang{EXIST}, $_COLORS[6]) : ''),
            $invoice_info->{result_sum},
            ($user) ? undef : $invoice_info->{tax_sum}
          );

          $total_tax_sum += $invoice_info->{tax_sum};
          $total_sum += $invoice_info->{result_sum};
        }
      }
    }

    my $user_deposit = 0;
    if ($users->{DEPOSIT} && $users->{DEPOSIT} =~ /^[0-9\-\.\,]+$/) {
      $user_deposit = sprintf('%.2f', ($users->{DEPOSIT} < int($users->{DEPOSIT})) ? int($users->{DEPOSIT})-1 : $users->{DEPOSIT});
    }

    if ($user_deposit != 0 && !$conf{DOCS_INVOICE_NO_DEPOSIT}) {
      $amount_for_pay = ($total_sum < $user_deposit) ? 0 : $total_sum - $user_deposit;
    }
    else {
      $amount_for_pay = $total_sum;
    }

    my $deposit_sum = '';
    # if ( $users->{UID}
    #   &&
    if (($user_deposit < 0)
      && !$conf{DOCS_INVOICE_NO_DEPOSIT} ){
      $deposit_sum = $html->form_input( 'SUM_' . ($num + 1), abs( $user_deposit ),{ TYPE => 'hidden', OUTPUT2RETURN => 1 } )
        . $html->form_input( 'ORDER_' . ($num + 1), $lang{DEBT}, { TYPE => 'hidden', OUTPUT2RETURN => 1 } )
        . $html->form_input( 'IDS', ($num + 1), { TYPE => 'hidden', OUTPUT2RETURN => 1 } );
    }

    #Add extra fields in admin iface
    if(! $user || ! $user->{UID}) {
      $num++;

      my $extra_result_sum = $FORM{'SUM_' . $num} || 0;
      my $extra_tax_sum    = 0;
      my $order            = $FORM{'ORDER_' . $num} || q{};

      if ($FORM{'FEES_TYPE_' . $num} && $fees_tax{$FORM{'FEES_TYPE_' . $num}}) {
        $extra_tax_sum = $extra_result_sum / 100 * $fees_tax{$FORM{'FEES_TYPE_' . $num}};
        $total_tax_sum += $extra_tax_sum;
      }

      $table->addrow(
        $html->form_input('SUM_' . $num, $extra_result_sum, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
          . $html->form_input('EXTRA_INVOICE_ID', $num, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
          . $html->form_input('ORDER_' . $num, $order, { TYPE => 'hidden', OUTPUT2RETURN => 1 })
          . $html->form_input('IDS', $num, { TYPE => ($users->{UID}) ? 'hidden' : 'checkbox', STATE => 'checked', OUTPUT2RETURN => 1 })
          . $num
        ,
        $DATE,
        $users->{LOGIN},
        docs_invoice_order_sel({ NAME => 'FEES_TYPE_' . $num }),
        sprintf("%.2f", $extra_result_sum),
        ($user) ? undef : sprintf("%.2f", $extra_tax_sum)
      );
      $total_sum += $total_not_invoice;
    }

    $table->{SKIP_FORMER} = 1;

    $table->addtd(
      $table->td("$lang{COUNT}: $num $lang{TOTAL} $lang{SUM}: ", { colspan => 4, class => 'bg-info' }),
      $table->td( sprintf( "%.2f", $total_sum ), { class => 'bg-info' } ),
      $table->td( ($user) ? undef : sprintf( "%.2f", $total_tax_sum), { class => 'bg-info' } )
    );

    $table->{extra} = " colspan='4' ";
    $table->addrow( $html->b( "$lang{DEPOSIT}:" ),
      $html->b( sprintf( "%.2f", ($user_deposit) ? $user_deposit : 0 ) ) . $deposit_sum || 0 );
    #$table->addrow( $html->b( "$lang{AMOUNT_FOR_PAY}:" ), $html->b( sprintf( "%.2f", $amount_for_pay ) ) );
    $table->addrow( $html->b( "$lang{RECOMMENDED_PAYMENT}:" ), $html->b( sprintf( "%.2f", $amount_for_pay ) ) );
    $FORM{AMOUNT_FOR_PAY} = sprintf( "%.2f", $amount_for_pay );

    $Docs->{PERIOD_DATE} = $html->form_daterangepicker({
      NAME      => 'FROM_DATE/TO_DATE',
      FORM_NAME => 'invoice_add',
      VALUE     => $FORM{'FROM_DATE_TO_DATE'},
    });

    $FORM{NEXT_PERIOD} = 0 if (!$FORM{NEXT_PERIOD} || $FORM{NEXT_PERIOD} < 0);
    if ( $attr->{REGISTRATION} ){
      return 1 if (!$attr->{ACTION});
      $Docs->{BACK} = $html->form_input( 'back', $lang{BACK}, { TYPE => 'submit' } );
      $Docs->{NEXT} = $html->form_input( $attr->{ACTION}, $attr->{LNG_ACTION}, { TYPE => 'submit' } );
    }

    if ( $user && $user->{UID} ){
      return 0 if (!$num);

      my $action = $html->form_input( 'make', "$lang{CREATE} $lang{INVOICE}", { TYPE => 'submit', OUTPUT2RETURN => 1 } );
      $table->{extra} = ' colspan=\'6\'';
      $table->addrow( $action );

      my $money_main_unit = q{};
      if ($conf{MONEY_UNIT_NAMES}) {
        $money_main_unit=(split(/;/, $conf{MONEY_UNIT_NAMES}))[0];
      }

      $service_invoice = $table->show({ OUTPUT2RETURN => 1 });
      my $title_form = ($users->{UID}) ? sprintf('%s: %.2f %s', $lang{ACTIVATE_NEXT_PERIOD}, $amount_for_pay, $money_main_unit) : "$lang{INVOICE} $lang{PERIOD}: $Y-$M";

      my $pre_info = q{};
      if ($service_info && $service_info->{distribution_fee} && $service_info->{distribution_fee} > 0 && $users->{REDUCTION} < 100 && defined($user_deposit)) {
        my $days_to_end = int($user_deposit / $service_info->{distribution_fee});
        $pre_info .= " ($lang{DAYS}: " . sprintf("%d", $days_to_end);
        if ($days_to_end > 0) {
          my ($Y1, $M1, $D1) = split(/-/, POSIX::strftime("%Y-%m-%d", localtime(time + 86400 * $days_to_end)));
          $pre_info .= " / $Y1-$M1-$D1";
        }
        $pre_info .= ')';
      }

      $html->tpl_show(_include('docs_user_invoices', 'Docs'), {
        index             => $index,
        UID               => $uid,
        DATE              => $DATE,
        create            => 1,
        CUSTOMER          => $Docs->{CUSTOMER},
        step              => $FORM{step},
        SERVICE_INVOICE   => $service_invoice,
        TITLE_INVOICE     => $title_form . $pre_info,
      });
    }
    else {
      $Docs->{ORDERS} = $table->show( { OUTPUT2RETURN => 1 } );
      $Docs->{ORDERS} .= $service_invoice;
      if (!$FORM{pdf}) {
        $html->tpl_show(_include('docs_receipt_add', 'Docs'),
          { %FORM,
            %{$attr},
            %{$Docs},
            %{$users} },
          { ID => 'docs_receipt_add' });
      }
    }

    delete $table->{SKIP_FORMER};
  }
  else {
    docs_invoice_add_form($attr);
  }

  return 1;
}

#**********************************************************
=head2 docs_invoice_add_form($attr)

   Arguments:
     $attr
       UID

   Returns:
     True or False

=cut
#**********************************************************
sub docs_invoice_add_form {
  my ($attr) = @_;

  $Docs->{ORDERS} = $html->tpl_show(_include('docs_invoice_orders', 'Docs'), {
    %{$Docs},
    %{$users},
    DATE => $DATE,
    TIME => $TIME,
    %FORM
  }, { OUTPUT2RETURN => 1 });

  my $myf = $html->form_select('TYPE_FEES_1', {
    SELECTED     => '',
    SEL_HASH     => get_fees_types(),
    NORMAL_WIDTH => 1,
    SEL_OPTIONS  => { '' => '--' },
  });

  $myf =~ s/\n//g;
  $Docs->{TYPES_FEES} = $myf;
  if ( $user && $user->{UID} ){
    $html->tpl_show( _include( 'docs_invoice_client_add', 'Docs' ), { %{$Docs}, %{$users}, %FORM } );
  }
  else{
    $html->tpl_show( _include( 'docs_invoice_add', 'Docs' ), {
      %{$attr},
      %{$Docs},
      %{$users},
      %FORM
    }, { ID => 'docs_invoice_add' } );
  }

  return 1;
}

#**********************************************************
=head2 docs_invoice_order_sel($attr)

  Arguments:
     NAME

  Resturns:
    $selct_obj

=cut
#**********************************************************
sub docs_invoice_order_sel {
  my ($attr) = @_;

  my $name = ($attr->{NAME}) ? $attr->{NAME} : 'FEES_TYPE';

  my $select_element = $html->form_select($name, {
    SELECTED     => ($FORM{$name}) ? $FORM{$name} : '',
    SEL_HASH     => get_fees_types(),
    SORT_KEY_NUM => 1,
    NO_ID        => 1,
    SEL_OPTIONS  => { 0 => '' },
  });

  return $select_element;
}

#**********************************************************
=head2 docs_invoice_print($invoice_id, $attr)

  Arguments:
   $invoice_id  - Invoice ID
   $attr        - Extra args
     UID
     DOC_INFO   - Docs object

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub docs_invoice_print {
  my ($invoice_id, $attr) = @_;

  if($attr->{DOC_INFO}) {
    $Docs = $attr->{DOC_INFO};
  }
  else {
    $Docs->invoice_info( $invoice_id, {
      UID          => $attr->{UID},
      GROUP_ORDERS => $conf{DOCS_INVOICE_GROUP_ORDERS}
    } );
  }

  if ( !$FORM{QUICK} ){
    _error_show( $Docs, {  MESSAGE => "$lang{INVOICE}: $invoice_id"} );
  }

  if($Docs->{errno}) {
    if($FORM{qindex}) {
      print "Content-Type: text/html\n\n";
      print "Wrong invoice number: $invoice_id";
    }
    return 0;
  }

  my %Doc = %{ $Docs };
  my $value_list=$Conf->config_list({
    CUSTOM    => 1,
    COLS_NAME => 1
  });

  foreach my $line (@$value_list){
    $Doc{"$line->{param}"}=$line->{value};
  }

  if (defined($conf{DOCS_VAT_INCLUDE})) {
    $Doc{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
      ($conf{DOCS_VAT_INCLUDE} && $conf{DOCS_VAT_INCLUDE} > 0) ? $Doc{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : 0 );

    $Doc{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $Doc{TOTAL_SUM} - $Doc{ORDER_TOTAL_SUM_VAT} );
    $Doc{VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} || 0);
  }

  $Doc{NUMBER}   = $Docs->{INVOICE_NUM};
  $Doc{A_FIO}    = $Docs->{A_FIO};
  $Doc{CUSTOMER} = $Docs->{COMPANY_NAME} || $Doc{FIO} || '-' if (!$Doc{CUSTOMER});
  $Doc{DEPOSIT}  = sprintf( "%.2f", $Doc{DEPOSIT} || 0);
  $Doc{DEBT}     = ($Doc{DEPOSIT} < 0) ? $Doc{DEPOSIT} : 0.00;
  $Doc{AVANCE}   = ($Doc{DEPOSIT} > 0) ? $Doc{DEPOSIT} : 0.00;
  my ($y, $m)    = split( /\-/, $Doc{DATE} );
  my $days_in_month = days_in_month( { DATE => $Doc{DATE} } );
  $Doc{INVOICE_PERIOD} = "$y-$m-01 $y-$m-$days_in_month";
  $Doc{MONTH_LAST_DAY} = "$y-$m-".  $days_in_month;

  if ( $FORM{CHECK_PEYMENT_ID} && $Doc{PAYMENT_ID} ){
    return 0;
  }

  if ( $Docs->{TOTAL} > 0 ){
    $Doc{FROM_DATE_LIT} = '';

    (undef, $Doc{TIME}) = split( / /, $Doc{CREATED}, 2 );
    $Doc{AMOUNT_FOR_PAY} = ($Doc{DEPOSIT} < 0) ? abs( $Doc{DEPOSIT} ) : 0 - $Doc{DEPOSIT};

    my $orders_list = $Doc{ORDERS};
    my $i = 0;
    $Doc{ORDER}         = '';
    $Doc{TOTAL_TAX_SUM} = 0;

    foreach my $document ( @$orders_list ){
      $i++;

      if (!$FORM{pdf}) {
        $Doc{ORDER} .= $html->tpl_show(
          _include('docs_invoice_order_row', 'Docs'),
          {
            %{$Docs},
            NUMBER => $i,
            NAME   => $document->{orders},
            COUNT  => $document->{counts} || 1,
            UNIT   => $units[$document->{unit}] || 1,
            PRICE  => $document->{price},
            SUM    => sprintf("%.2f", ($document->{count} || 1) * $document->{price})
          },
          { OUTPUT2RETURN => 1 }
        );
      }

      my $count = $document->{counts} || 1;
      my $sum = sprintf( "%.2f", $count * $document->{price} );

      $Doc{ 'LOGIN_' . $i }         = $document->{login};
      $Doc{ 'ORDER_NUM_' . $i }     = $i;
      $Doc{ 'ORDER_NAME_' . $i }    = $document->{orders};
      $Doc{ 'ORDER_COUNT_' . $i }   = $count;
      $Doc{ 'ORDER_PRICE_' . $i }   = $document->{price};
      $Doc{ 'ORDER_TAX_SUM_' . $i } = $document->{tax} || 0;

      $Doc{TOTAL_TAX_SUM}          += $Doc{ 'ORDER_TAX_SUM_' . $i };

      $Doc{ 'ORDER_SUM_' . $i }     = $sum;
      $Doc{ 'UNITS' . $i }          = $document->{units} || 1;
      $Doc{ 'ORDER_VAT_' . $i }     = ($conf{DOCS_VAT_INCLUDE}) ? sprintf( "%.2f",
        $document->{price} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) ) : 0;
      $Doc{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
        ($Doc{ 'ORDER_VAT_' . $i }) ? $document->{price} - $Doc{ 'ORDER_VAT_' . $i } : $Doc{ 'UNITS' . $i } );
      $Doc{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
        ($conf{DOCS_VAT_INCLUDE}) ? $sum - ($sum) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );

      # not charged service
      if ( $Doc{DEPOSIT} == 0 || $Doc{ 'ORDER_TAX_SUM_' . $i } == 0 ){
        $Doc{AMOUNT_FOR_PAY} += $Doc{ 'ORDER_COUNT_' . $i } * $Doc{ 'ORDER_PRICE_' . $i }
      }

      #alternative currancy sum
      if ( $Doc{EXCHANGE_RATE} > 0 ){
        $Doc{ 'ORDER_ALT_SUM_' . $i }   = sprintf( "%.2f", $Doc{ 'ORDER_SUM_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_PRICE_' . $i } = sprintf( "%.2f", $Doc{ 'ORDER_PRICE_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_VAT_' . $i }   = sprintf( "%.2f", $Doc{ 'ORDER_VAT_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $Doc{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } * $Doc{EXCHANGE_RATE} );
        $Doc{ 'ORDER_ALT_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $Doc{ 'ORDER_SUM_WITHOUT_VAT_' . $i } * $Doc{EXCHANGE_RATE} );
      }
    }

    $Doc{TOTAL_SUM}      = sprintf( "%.2f", $Doc{TOTAL_SUM} );
    $Doc{TOTAL_TAX_SUM}  = sprintf( "%.2f", $Doc{TOTAL_TAX_SUM});
    $Doc{AMOUNT_FOR_PAY} = sprintf( "%.2f", $Doc{AMOUNT_FOR_PAY} );
    $Doc{TOTAL_ORDERS}   = $#{ $orders_list } + 1;

    #Get payments
    my $i2p_list = $Docs->invoices2payments_list({ INVOICE_ID => $invoice_id,
      COLS_NAME  => 1
    });
    my $payments_total_sum = 0;
    $i = 1;
    foreach my $i2p ( @{ $i2p_list } ){
      my ($payment_day, undef) = split( / /, $i2p->{date} );
      $Doc{'PAYMENT_DATE_' . $i}     = $payment_day;
      $Doc{'PAYMENT_COMMENTS_' . $i} = $i2p->{dsc};
      $Doc{'PAYMENT_SUM_' . $i}      = $i2p->{invoiced_sum};
      $Doc{'PAYMENT_ID_' . $i}       = $i2p->{payment_id};
      $Doc{'PAYMENT_ALT_SUM_' . $i}  = sprintf( "%.2f", $Doc{EXCHANGE_RATE} * $i2p->{payment_sum} );
      $payments_total_sum += $payments_total_sum;
      $i++;
    }

    $Doc{PAYMENTS_TOTAL_SUM} = $payments_total_sum;
    $Doc{TOTAL_REST_SUM} = sprintf( "%.2f", $Doc{TOTAL_SUM} - $Doc{PAYMENTS_TOTAL_SUM} );

    #Get unpayments
    my $unpayment_list = $Docs->invoices_list( {
      UID       => $attr->{UID},
      UNPAIMENT => 1,
      PAGE_ROWs => 1000,
      COLS_NAME => 1
    } );

    $i = 1;
    my $unpayment_total_sum = 0;
    foreach my $unpayment ( @{$unpayment_list} ){
      $Doc{'UNPAYMENT_INVOICE_DATE_' . $i} = $unpayment->{date};
      $Doc{'UNPAYMENT_INVOICE_COMMENTS_' . $i} = $unpayment->{dsc};
      $Doc{'UNPAYMENT_INVOICE_SUM_' . $i} = sprintf( "%.2f",
        $unpayment->{total_sum} - ($unpayment->{payment_sum} || 0) );
      $Doc{'UNPAYMENT_INVOICE_NUM_' . $i} = $unpayment->{invoice_num};
      $Doc{'UNPAYMENT_INVOICE_ALT_SUM_' . $i} = sprintf( "%.2f",
        $Doc{EXCHANGE_RATE} * $Doc{'UNPAYMENT_INVOICE_SUM_' . $i} );
      $unpayment_total_sum += $Doc{'UNPAYMENT_INVOICE_SUM_' . $i};
      $i++;
    }

    $Doc{LAST_PAYMENT_SUM} = '0.00';
    $Doc{LAST_PAYMENT_DATE} = '';
    $orders_list = $Payments->list( {
      UID       => $attr->{UID},
      SUM       => '_SHOW',
      DATETIME  => '_SHOW',
      DESC      => 'DESC',
      PAGE_ROWS => 1,
      COLS_NAME => 1
    } );

    if ( $Payments->{TOTAL} > 0 ){
      $Doc{LAST_PAYMENT_SUM} = $orders_list->[0]->{sum};
      $Doc{LAST_PAYMENT_DATE} = $orders_list->[0]->{datetime};
    }

    $Doc{UNPAYMENT_TOTAL_SUM} = sprintf( "%.2f", $unpayment_total_sum );

    if ( $Doc{EXCHANGE_RATE} > 0 ){
      $Doc{TOTAL_ALT_SUM}      = sprintf( "%.2f", $Doc{TOTAL_SUM} * $Doc{EXCHANGE_RATE} );
      $Doc{AMOUNT_FOR_PAY_ALT} = sprintf( "%.2f", $Doc{AMOUNT_FOR_PAY} * $Doc{EXCHANGE_RATE} );
      $Doc{DEPOSIT_ALT}        = sprintf( "%.2f", $Doc{DEPOSIT} * $Doc{EXCHANGE_RATE} );
      $Doc{CHARGED_ALT_SUM}    = sprintf( "%.2f", $Doc{CHARGED_SUM} * $Doc{EXCHANGE_RATE} );
      $Doc{UNPAYMENT_TOTAL_ALT_SUM} = sprintf( "%.2f", $Doc{UNPAYMENT_TOTAL_SUM} * $Doc{EXCHANGE_RATE} );
      $Doc{TOTAL_REST_ALT_SUM} = sprintf( "%.2f", $Doc{TOTAL_REST_SUM} * $Doc{EXCHANGE_RATE} );
    }

    $attr->{SEND_EMAIL} = 0 if (!defined( $attr->{SEND_EMAIL} ));

    if ( $attr->{GET_EMAIL_INFO} && $attr->{SEND_EMAIL} || $attr->{SEND_VIBER}){
      delete $FORM{pdf};
      $attr->{EMAIL_MSG_TEXT} = $html->tpl_show( _include( 'docs_invoice_email', 'Docs' ), { %{$users}, %FORM,
        %{$attr}, %{$Docs}, %Doc }, { OUTPUT2RETURN => 1 } );
      $attr->{EMAIL_ATTACH_FILENAME} = 'invoice_' . $Doc{INVOICE_NUM} if (!$attr->{EMAIL_ATTACH_FILENAME});
      $attr->{EMAIL_MSG_SUBJECT} = "ABillS - $lang{INVOICE}: $Doc{INVOICE_NUM}" if (!$attr->{EMAIL_MSG_SUBJECT});
    }

    if ( $conf{DOCS_EXTRA_DEPOSIT} && $Doc{DEPOSIT} != 0 ){
      if ( $Doc{EXCHANGE_RATE} ){
        $Doc{DEPOSIT_ALT} = sprintf( "%.2f", ($Doc{DEPOSIT} + $Doc{CHARGED_SUM}) * $Doc{EXCHANGE_RATE} );
      }
    }

    $FORM{pdf} = $conf{DOCS_PDF_PRINT};
    $Doc{DOC_TYPE} = 1;

    my $docs_service_info = docs_module_info({ UID => $Docs->{UID} || $FORM{UID} });

    if ( $Doc{COMPANY_ID} ){
      my $Customer = Customers->new( $db, $admin, \%conf );
      my $Company  = $Customer->company();
      $Company->info( $Doc{COMPANY_ID} );
      delete $Company->{DEPOSIT};
      my $invoice_blank = ($FORM{alt_tpl}) ? 'invoice_company_alt' : ($FORM{termo_printer_tpl}) ? 'invoice_company_termo_printer' : 'invoice_company';

      my $sufix = ($Doc{PAYMENT_SUM} && $Doc{PAYMENT_SUM} == $Doc{TOTAL_SUM} && _include(
        'docs_' . $invoice_blank . '_paid', 'Docs', { CHECK_ONLY => 1 } )) ? '_paid' : '';

      return docs_print( "$invoice_blank$sufix", { %Doc,
        %{$Company},
        %{$docs_service_info},
        %{$attr},
        SUFIX   => ($Doc{VAT} > 0) ? 'vat' : '',
        ALT_TPL => $invoice_blank,
        #        OUTPUT2RETURN => 1
      } );
    }
    else{
      my $invoice_blank = ($FORM{alt_tpl}) ? 'invoice_alt' : ($FORM{termo_printer_tpl}) ? 'invoice_termo_printer' : 'invoice';
      my $sufix = ($Doc{PAYMENT_SUM} && $Doc{TOTAL_SUM} && $Doc{PAYMENT_SUM} == $Doc{TOTAL_SUM} && _include(
        'docs_' . $invoice_blank . '_paid', 'Docs', { CHECK_ONLY => 1 } )) ? '_paid' : '';

      return docs_print( "$invoice_blank$sufix", {
        %Doc,
        %{$attr},
        %{$docs_service_info},
        ALT_TPL => $invoice_blank,
        DOCS    => $Docs,
      } );
    }
  }
  else{
    if ( !$FORM{QUICK} ){
      print "Content-Type: text/html\n\n";
      _error_show( $Docs );
    }
  }

  return 1;
}

#**********************************************************
=head2 docs_summary() - Make multiuser documents

=cut
#**********************************************************
sub docs_summary {
  my $users_list = $users->list({
    FIO       => '_SHOW',
    CREDIT    => '_SHOW',
    DEPOSIT   => '<0',
    DISABLE   => 0,
    PAGE_ROWS => 1000000,
    COLS_NAME => 1
  });
  my @MULTI_ARR = ();

  if ($users->{TOTAL} && $users->{TOTAL} > 0) {
    foreach my $line (@{$users_list}) {
      push @MULTI_ARR, {
        FIO     => $line->{fio},
        DEPOSIT => $line->{deposit},
        CREDIT  => $line->{credit},
        SUM     => $line->{deposit},
        SUM_VAT => ($conf{DOCS_VAT_INCLUDE}) ? sprintf("%.2f",
          ($line->{deposit} || 0) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE})) : 0.00
      };
    }
  }

  $html->tpl_show( _include( "docs_multi_invoice", 'Docs', { pdf => $FORM{pdf} } ), { MULTI_PRINT => \@MULTI_ARR } );

  return 1;
}

#**********************************************************
=head2 docs_ununvoiced_apply() - apply uninvoiced payment

=cut
#**********************************************************
sub docs_ununvoiced_apply {
  $FORM{INVOICE_ID} ||= 'create';

  my ($res) = $Api->api_call({
    METHOD => 'PATCH',
    PATH   => '/docs/invoices/payments/',
    PARAMS => {
      %FORM,
      INVOICE_ID     => ($FORM{INVOICE_ID} && "$FORM{INVOICE_ID}" eq 'create') ? 0 : $FORM{INVOICE_ID},
      INVOICE_CREATE => ($FORM{INVOICE_ID} && "$FORM{INVOICE_ID}" eq 'create') ? 1 : 0,
    }
  });

  return 0 if (_error_show($res));

  $html->message('info', $lang{ADDED},
    "$lang{PAYMENTS}: $res->{payment_id} -> $lang{INVOICE}: $res->{invoice_id}\n$lang{SUM}: $FORM{SUM}");

  return 1;
}

#**********************************************************
=head2 docs_uninvoiced() - Uninvoices process

=cut
#**********************************************************
sub docs_uninvoiced {
  return 0 if ($user && $user->{UID});

  if ($FORM{apply}) {
    return docs_ununvoiced_apply();
  }

  my ($res) = $Api->api_call({
    METHOD => 'GET',
    PATH   => '/docs/invoices/',
    PARAMS => {
      %LIST_PARAMS,
      %FORM,
      UNINVOICED => 1,
      COLS_NAME  => 1,
    }
  });

  return 0 if (_error_show($res));

  my $payments_list = $res->{list};

  my $table = $html->table({
    width => '100%',
    title => [ '#', $lang{DATE}, $lang{DESCRIBE}, "$lang{PAYMENTS} $lang{SUM}", "$lang{INVOICES} $lang{SUM}", $lang{REST} ],
    qs    => $pages_qs,
    pages => $Docs->{TOTAL},
    ID    => 'UNINVOICED_PAYMENTS'
  });

  $pages_qs .= "&subf=2" if (!$FORM{subf});
  foreach my $payment (@{$payments_list}) {
    $table->{rowcolor} = ($FORM{PAYMENT_ID} && $FORM{PAYMENT_ID} == $payment->{id}) ? $_COLORS[0] : undef;
    $table->addrow(
      $html->form_input('PAYMENT_ID', $payment->{id}, { TYPE => 'radio',
        STATE                                                =>
          ($FORM{PAYMENT_ID} && $FORM{PAYMENT_ID} == $payment->{id}) ? 'checked' : undef
      }) .
        $html->b($payment->{id}),
      $payment->{date},
      ($payment->{dsc} || q{}) . (($payment->{inner_describe}) ? $html->br() . $html->b($payment->{inner_describe}) : ''),
      $payment->{payment_sum},
      $payment->{invoiced_sum} || '0.00',
      $payment->{remains}
    );
  }

  $Docs->{PAYMENTS_LIST} = $table->show({ OUTPUT2RETURN => 1 });

  my ($invoices) = $Api->api_call({
    METHOD => 'GET',
    PATH   => '/docs/invoices/',
    PARAMS => {
      UID       => $FORM{UID},
      UNPAIMENT => 1,
      PAGE_ROWS => 200,
      SORT      => 2,
      DESC      => 'DESC',
      COLS_NAME => 1
    }
  });

  return 0 if (_error_show($res));

  $Docs->{INVOICE_SEL} = $html->form_select('INVOICE_ID', {
    SELECTED         => $FORM{INVOICE_ID} || $FORM{UNINVOICED},
    SEL_LIST         => $invoices->{list},
    SEL_KEY          => 'id',
    SEL_VALUE        => 'invoice_num,date,total_sum,payment_sum',
    SEL_VALUE_PREFIX => "$lang{NUM}: ,$lang{DATE}: ,$lang{SUM}: ,$lang{PAYMENTS}: ",
    SEL_OPTIONS      => { 0 => '', %{(!$conf{PAYMENTS_NOT_CREATE_INVOICE}) ? { create => $lang{CREATE} } : {}} },
    NO_ID            => 1,
    MAIN_MENU        => get_function_index('docs_invoices_list'),
    MAIN_MENU_ARGV   => (($FORM{UID}) ? "UID=$FORM{UID}" : q{}) . "&INVOICE_ID=" . ($FORM{INVOICE_ID} || q{})
  });

  $html->tpl_show(_include('docs_payment2invoice', 'Docs'), { %{$Docs}, %FORM }, { ID => 'docs_payment2invoice' });

  return 0;
}

#**********************************************************
=head2 docs_invoice_list_print() - Uninvoices proccess

=cut
#**********************************************************
sub docs_invoice_list_print {

  print "Content-Type: text/html\n\n" if ($debug > 2);

  #Get payments
  my $i2p_list = $Docs->invoices2payments_list({
    %LIST_PARAMS,
    COLS_NAME => 1,
  });

  my %payments_list = ();
  my $i = 1;
  if($Docs->{TOTAL}) {
    foreach my $i2p (@{ $i2p_list }) {
      my $invoice_id = $i2p->{invoice_id} || 0;
      $payments_list{$invoice_id}{'PAYMENT_DATE_'.$i} = $i2p->{date};
      $payments_list{$invoice_id}{'PAYMENT_COMMENTS_'.$i} = $i2p->{dsc};
      $payments_list{$invoice_id}{'PAYMENT_SUM_'.$i} = $i2p->{payment_sum};
      $payments_list{$invoice_id}{'PAYMENT_ID_'.$i} = $i2p->{payment_id};
      $payments_list{$invoice_id}{'PAYMENT_ALT_SUM_'.$i} = sprintf( "%.2f", $i2p->{amount} || 0 );
      $i++;
    }
  }

  $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID} if ($FORM{COMPANY_ID});
  delete $FORM{DOMAIN_ID};
  my $invoices_list = $Docs->invoices_list( {
    ORDERS_LIST    => 1,
    REPRESENTATIVE => '_SHOW',
    DOCS_DEPOSIT   => '_SHOW',
    ADDRESS_FULL   => '_SHOW',
    ADDRESS_STREET => '_SHOW',
    ADDRESS_BUILD  => '_SHOW',
    ADDRESS_FLAT   => '_SHOW',
    PHONE          => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    CONTRACT_DATE  => '_SHOW',
    BILL_ID        => '_SHOW',
    EMAIL          => '_SHOW',
    FIO            => '_SHOW',
    CREATED        => '_SHOW',
    ALT_SUM        => '_SHOW',
    EXCHANGE_RATE  => '_SHOW',
    CURRENCY       => '_SHOW',
    DEPOSIT        => '_SHOW',
    %LIST_PARAMS,
    LOGIN          => (!$LIST_PARAMS{LOGIN}) ? '_SHOW' : $LIST_PARAMS{LOGIN},
    %FORM,
    COLS_UPPER     => 1,
    COLS_NAME      => 1,
  });
  my @MULTI_ARR = ();
  my $doc_num = 0;

  my $build_delimiter = $conf{BUILD_DELIMITER} || ', ';
  foreach my $d ( @{$invoices_list} ){
    $d->{AMOUNT_FOR_PAY} = ($d->{DEPOSIT} < 0) ? abs( $d->{DEPOSIT} ) : 0 - $d->{DEPOSIT};
    $d->{NUMBER} = $d->{INVOICE_NUM} || '-';
    my ($year, $month, $day) = split( /-/, $d->{DATE}, 3 );
    $d->{FROM_DATE_LIT} = "$day " . $MONTHES_LIT[ int( $month ) - 1 ] . " $year $lang{YEAR_SHORT}";
    $d->{DATE_EURO_STANDART} = "$day.$month.$year";
    $d->{FIO} = $d->{CUSTOMER} if ($d->{CUSTOMER});
    $d->{TOTAL_SUM} = sprintf( "%.2f", $d->{TOTAL_SUM} );
    $d->{A_FIO} = $d->{ADMIN_FIO};
    $d->{DEPOSIT} = sprintf( "%.2f", $d->{DOCS_DEPOSIT} );
    $d->{DOC_ID} = $d->{ID};
    $d->{AMOUNT_FOR_PAY} = ($d->{DEPOSIT} < 0) ? abs( $d->{DEPOSIT} ) : 0 - $d->{DEPOSIT};
    $FORM{COMPANY_ID} = $d->{COMPANY_ID};

    if ( $conf{DOCS_VAT_INCLUDE} ){
      $d->{ORDER_TOTAL_SUM_VAT} = sprintf( "%.2f",
        $d->{TOTAL_SUM} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) );
      $d->{TOTAL_SUM_WITHOUT_VAT} = sprintf( "%.2f", $d->{TOTAL_SUM} - $d->{ORDER_TOTAL_SUM_VAT} );
      $d->{TOTAL_SUM_VAT} = sprintf( "%.2f", $conf{DOCS_VAT_INCLUDE} );
    }

    $i = 0;

    foreach my $order ( @{ $Docs->{ORDERS}->{$d->{DOC_ID}} } ){
      $i++;
      $d->{ORDER} .= sprintf(
        "<tr><td align=right>%d</td><td>%s</td><td align=right>%d</td><td align=right>%d</td><td align=right>%.2f</td><td align=right>%.2f</td></tr>\n"
        , $i, $order->{orders}, $order->{unit}, $order->{counts}, $order->{price},
        ($order->{counts} * $order->{price}) ) if (!$conf{DOCS_PDF_PRINT});

      my $count = $order->{counts} || 1;
      my $sum = sprintf( "%.2f", $count * $order->{price} );

      $d->{ 'LOGIN_' . $i } = $d->{LOGIN};
      $d->{ 'ORDER_NUM_' . $i } = $i;
      $d->{ 'ORDER_NAME_' . $i } = $order->{orders};
      $d->{ 'ORDER_COUNT_' . $i } = $count;
      $d->{ 'ORDER_PRICE_' . $i } = $order->{price};
      $d->{ 'ORDER_SUM_' . $i } = $sum;

      $d->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
        ($conf{DOCS_VAT_INCLUDE}) ? $order->{price} - $order->{price} / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $order->{price} );
      $d->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
        ($conf{DOCS_VAT_INCLUDE}) ? $sum - ($sum) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $sum );

      if ( $order->{fees_id} == 0 ){
        $d->{AMOUNT_FOR_PAY} += $d->{ 'ORDER_COUNT_' . $i } * $d->{ 'ORDER_PRICE_' . $i }
      }

      if ( $d->{EXCHANGE_RATE} > 0 ){
        $d->{ 'ORDER_ALT_SUM_' . $i } = sprintf( "%.2f", $d->{ 'ORDER_SUM_' . $i } * $d->{EXCHANGE_RATE} );
        $d->{ 'ORDER_ALT_PRICE_' . $i } = sprintf( "%.2f", $d->{ 'ORDER_PRICE_' . $i } * $d->{EXCHANGE_RATE} );
        $d->{ 'ORDER_ALT_VAT_' . $i } = sprintf( "%.2f", ($d->{ 'ORDER_VAT_' . $i } || 0) * $d->{EXCHANGE_RATE} );
        $d->{ 'ORDER_ALT_PRICE_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $d->{ 'ORDER_PRICE_WITHOUT_VAT_' . $i } * $d->{EXCHANGE_RATE} );
        $d->{ 'ORDER_ALT_SUM_WITHOUT_VAT_' . $i } = sprintf( "%.2f",
          $d->{ 'ORDER_SUM_WITHOUT_VAT_' . $i } * $d->{EXCHANGE_RATE} );
      }
    }

    $d->{TOTAL_SUM} = sprintf( "%.2f", $d->{TOTAL_SUM} );
    $d->{AMOUNT_FOR_PAY} = sprintf( "%.2f", $d->{AMOUNT_FOR_PAY} );
    if ( $d->{EXCHANGE_RATE} > 0 ){
      $d->{TOTAL_ALT_SUM} = sprintf( "%.2f", $d->{TOTAL_SUM} * $d->{EXCHANGE_RATE} );
      $d->{AMOUNT_FOR_PAY_ALT} = sprintf( "%.2f", $d->{AMOUNT_FOR_PAY} * $d->{EXCHANGE_RATE} );
      $d->{DEPOSIT_ALT} = sprintf( "%.2f", $d->{DEPOSIT} * $d->{EXCHANGE_RATE} );
      $d->{CHARGED_ALT_SUM} = sprintf( "%.2f", ($d->{CHARGED_SUM} || 0) * $d->{EXCHANGE_RATE} );
    }

    if ($payments_list{$d->{ID}}) {
      $d = { %{$payments_list{$d->{ID}}}, %{$d} };
    }

    $d->{'TOTAL_SUM_WITHOUT_VAT'} = sprintf( "%.2f",
      ($conf{DOCS_VAT_INCLUDE}) ? $d->{TOTAL_SUM} - ($d->{TOTAL_SUM}) / ((100 + $conf{DOCS_VAT_INCLUDE}) / $conf{DOCS_VAT_INCLUDE}) : $d->{TOTAL_SUM} );
    $d->{'TOTAL_SUM_VAT'} = sprintf( "%.2f", $d->{TOTAL_SUM} - $d->{'TOTAL_SUM_WITHOUT_VAT'} );

    $d->{SUM_LIT} = int2ml("$d->{TOTAL_SUM}", {
      ONES             => \@ones,
      TWOS             => \@twos,
      FIFTH            => \@fifth,
      ONE              => \@one,
      ONEST            => \@onest,
      TEN              => \@ten,
      TENS             => \@tens,
      HUNDRED          => \@hundred,
      MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names,
      LOCALE           => $conf{LOCALE}
    });

    if ($d->{TOTAL_ALT_SUM}) {
      $d->{SUM_ALT_LIT} = int2ml("$d->{TOTAL_ALT_SUM}", {
        ONES             => \@ones,
        TWOS             => \@twos,
        FIFTH            => \@fifth,
        ONE              => \@one,
        ONEST            => \@onest,
        TEN              => \@ten,
        TENS             => \@tens,
        HUNDRED          => \@hundred,
        MONEY_UNIT_NAMES => $conf{MONEY_UNIT_NAMES} || \@money_unit_names,
        LOCALE           => $conf{LOCALE}
      });
    }

    push @MULTI_ARR, { %{$d}, DOC_NUMBER => sprintf( "%.6d", $doc_num ), };
    $doc_num++;
    print "UID: LOGIN: $d->{LOGIN} FIO: $d->{FIO} SUM: $d->{TOTAL_SUM}\n" if ($debug > 2);
  }

  print $html->header() if ($FORM{qindex});
  my $tpl = ($FORM{COMPANY_ID}) ? 'docs_invoice_company' : 'docs_invoice';
  $tpl .= '_alt' if ($FORM{alt_tpl});

  $html->tpl_show(
    _include( $tpl, 'Docs', { pdf => $FORM{pdf} } ),
    undef,
    {
      MULTI_DOCS => \@MULTI_ARR,
      debug      => $debug
    }
  );

  return 0;
}

1;
