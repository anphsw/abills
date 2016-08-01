=head1 NAME

  Main Reports

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(in_array cfg2hash);

our(
  $html,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  %permissions,
  $db,
  $admin,
);

#**********************************************************
=head2 reports($attr) - Reports panel

  Attributes:
    $attr 
      FIELDS      - Show extra fields
      NO_TAGS     - Skip tag panel. Default if module tags showing is enable
      PERIOD_FORM - Show period form Drom date to date
      TIME_FORM   - Show Time form from hour to hour
      NO_GROUP    - Hide group select
      EX_INPUTS   - Extra inputs
      HIDDEN      - Add hidden fields
      EXT_TYPE    - Extra reports type hash_ref
      EX_PARAMS   - Extra params

  Results:

    TRUE or FALSE

=cut
#**********************************************************
sub reports{
  my ($attr) = @_;

  my $EX_PARAMS;
  my ($y, $m, $d);
  my $type = 'DATE';

  if ( $FORM{MONTH} ){
    $LIST_PARAMS{MONTH} = $FORM{MONTH};
    $pages_qs = "&MONTH=$LIST_PARAMS{MONTH}";
  }
  elsif ( $FORM{allmonthes} ){
    $type = 'MONTH';
    $pages_qs = "&allmonthes=1";
  }
  elsif ( !$FORM{FROM_DATE} ){
    ($y, $m, $d) = split( /-/, $DATE, 3 );
    $LIST_PARAMS{MONTH} = "$y-$m";
    $pages_qs = "&MONTH=$LIST_PARAMS{MONTH}";
  }

  if ( $FORM{ADMINS} ){
    $LIST_PARAMS{ADMINS} = $FORM{ADMINS};
    $pages_qs .= "&ADMINS=$LIST_PARAMS{ADMINS}";
  }
  elsif ( $FORM{LOCATION_ID} ){
    $LIST_PARAMS{LOCATION_ID} = $FORM{LOCATION_ID};
  }
  elsif ( $FORM{MONTH} ){
    $LIST_PARAMS{MONTH} = $FORM{MONTH};
  }
  elsif ( $FORM{TAGS} ){
    $LIST_PARAMS{TAGS} = $FORM{TAGS};
  }
  elsif ( $FORM{STREET_ID} ){
    $LIST_PARAMS{STREET_ID} = $FORM{STREET_ID};
  }
  elsif ( $FORM{COMPANY_NAME} ){
    $LIST_PARAMS{COMPANY_NAME} = $FORM{COMPANY_NAME};
  }

  if ( $LIST_PARAMS{UID} ){
    $pages_qs .= "&UID=$LIST_PARAMS{UID}";
  }
  else{
    if ( $FORM{GID} ){
      $LIST_PARAMS{GID} = $FORM{GID};
      $pages_qs .= "&GID=$FORM{GID}";
      delete $LIST_PARAMS{GIDS};
    }
  }

  my @rows = ();
  my $FIELDS = '';

  #Extra fields
  if ( $attr->{FIELDS} ){
    my %fields_hash = ();
    if ( defined( $FORM{FIELDS} ) ){
      my @fileds_arr = split( /, /, $FORM{FIELDS} );
      foreach my $line ( @fileds_arr ){
        $fields_hash{$line} = 1;
      }
    }

    if ($FORM{FIELDS}){
      $LIST_PARAMS{FIELDS} = $FORM{FIELDS};
      $pages_qs .= "&FIELDS=$FORM{FIELDS}";
    }

    my $table2 = $html->table( { width => '100%', rowcolor => 'static' } );
    my @arr = ();
    my $i = 0;

    foreach my $line ( sort keys %{ $attr->{FIELDS} } ){
      my (undef, $k, undef) = split( /:/, $line );
      push @arr, $html->form_input( "FIELDS", $k, { TYPE => 'checkbox', STATE =>
              (defined( $fields_hash{$k} )) ? 'checked' : undef } ) . " $attr->{FIELDS}{$line}";
      $i++;
      if ( $#arr > 1 ){
        $table2->addrow( @arr );
        @arr = ();
      }
    }

    if ( $#arr > -1 ){
      $table2->addrow( @arr );
    }

    $FIELDS .= $table2->show();
  }

  #SHow tags
  my $TAGS = '';
  if ( in_array( 'Tags', \@MODULES ) && !$attr->{NO_TAGS} ){
    load_module( 'Tags', $html );
    $TAGS = tags_search_form();
    $TAGS = $html->element( 'div', $TAGS, {
        class => 'well well-sm', #'navbar navbar-default form-inline'
      } ) if ($TAGS);
  }

  if ( $attr->{PERIOD_FORM} ){
    @rows = ("$lang{DATE}: " . $html->date_fld2( 'FROM_DATE',
      { MONTHES => \@MONTHES, FORM_NAME => 'report_panel', WEEK_DAYS => \@WEEKDAYS } ) . " - " . $html->date_fld2(
      'TO_DATE', { MONTHES => \@MONTHES, FORM_NAME => 'report_panel', WEEK_DAYS => \@WEEKDAYS } ));

    if ( $attr->{TIME_FORM} ){
      push @rows, '&nbsp;' . ("$lang{TIME}: " . $html->form_input( 'FROM_TIME',
          (($FORM{FROM_TIME}) ? $FORM{FROM_TIME} : '00:00:00'), { SIZE => 10 } ) . " - " . $html->form_input( 'TO_TIME',
          (($FORM{TO_TIME}) ? $FORM{TO_TIME} : '24:00:00'), { SIZE => 10 } ));

      $LIST_PARAMS{FROM_TIME} = $FORM{FROM_TIME};
      $LIST_PARAMS{TO_TIME} = $FORM{TO_TIME};

      if ( $FORM{FROM_TIME} && $FORM{TO_TIME} && ($FORM{FROM_TIME} ne '00:00:00' || $FORM{TO_TIME} ne '24:00:00') ){
        $pages_qs .= "&FROM_TIME=$FORM{FROM_TIME}&TO_TIME=$FORM{TO_TIME}";
      }
    }

    if ( !$attr->{NO_GROUP} ){
      push @rows, "$lang{GROUP}: " . sel_groups(), " $lang{TYPE}: "
          . $html->form_select(
          'TYPE',
          {
            SELECTED => $FORM{TYPE} || 'DAYS',
            SEL_HASH => {
              DAYS  => $lang{DAYS},
              USER  => $lang{USERS},
              HOURS => $lang{HOURS},
              %{ ($attr->{EXT_TYPE}) ? $attr->{EXT_TYPE}  : {} }
            },
            NO_ID    => 1
          }
        );
    }

    if ( $attr->{EX_INPUTS} ){
      foreach my $line ( @{ $attr->{EX_INPUTS} } ){
        push @rows, $line;
      }
    }

    push @rows, $html->form_input( 'show', $lang{SHOW}, { TYPE => 'submit', FORM_ID => 'report_panel' } );

    my %info = ();
    foreach my $val ( @rows ){
      $info{ROWS} .= $html->element( 'div', ($val || q{}), { class => 'form-group' } );
    }

    my $report_form = $html->element( 'div', $info{ROWS}, {
        class => 'well well-sm sticky',
      } );

    print $html->form_main(
        {
          CONTENT => $report_form . $FIELDS . $TAGS,
          HIDDEN  => {
            'index' => "$index",
             %{ ($attr->{HIDDEN}) ? $attr->{HIDDEN} : {} }
          },
          NAME    => 'report_panel',
          ID      => 'report_panel',
          class   => 'form-inline',
        }
      );

    if ( $FORM{show} ){
      $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
      $LIST_PARAMS{TYPE} = $FORM{TYPE};
      $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
      $LIST_PARAMS{FROM_DATE} = $FORM{FROM_DATE};
      $LIST_PARAMS{TO_DATE} = $FORM{TO_DATE};
    }
    elsif ( !$FORM{DATE} ){
      $LIST_PARAMS{FROM_DATE} = $html->{FROM_DATE};
      $LIST_PARAMS{TO_DATE} = $html->{TO_DATE};
    }
  }

  if ( $FORM{DATE} ){
    ($y, $m, $d) = split( /-/, $FORM{DATE}, 3 );
    my $hour = '';
    ($d, $hour)=split(/ /, $d);
    $LIST_PARAMS{DATE} = $FORM{DATE};
    $pages_qs .= "&DATE=$LIST_PARAMS{DATE}";

    if ( defined( $attr->{EX_PARAMS} ) ){
      my $EP = $attr->{EX_PARAMS};

      while (my ($k, $v) = each( %{$EP} )) {
        if ( $FORM{EX_PARAMS} && $FORM{EX_PARAMS} eq $k ){
          $EX_PARAMS .= ' ' . $html->b( $v );
          $LIST_PARAMS{$k} = 1;

          if ( $k eq 'HOURS' ){
            undef $attr->{SHOW_HOURS};
          }
        }
        else{
          $EX_PARAMS .= ' ' . $html->button( $v, "index=$index$pages_qs&EX_PARAMS=$k", { BUTTON => 1 } );
        }
      }
    }

    my $days = '';
    for ( my $i = 1; $i <= 31; $i++ ){
      $days .= ($d == $i) ? ' ' . $html->b( $i ) : ' ' . $html->button( $i,
          sprintf( "index=$index&DATE=%d-%02.f-%02.f&EX_PARAMS=". ($FORM{EX_PARAMS} || '')."%s%s%s", $y, $m, $i,
              (defined( $FORM{GID} )) ? "&GID=$FORM{GID}" : '', (defined( $FORM{UID} )) ? "&UID=$FORM{UID}" : '',
              ($FORM{FIELDS}) ? "&FIELDS=$FORM{FIELDS}" : '' ), { BUTTON => 1 } );
    }

    @rows = ([ " $lang{YEAR}:", $y ], [ " $lang{MONTH}:", $MONTHES[ $m - 1 ] ], [ " $lang{DAY}:", $days ]);

    if ( $attr->{SHOW_HOURS} ){
      my (undef, $h) = split( / /, $FORM{HOUR}, 2 );
      my $hours = '';
      for ( my $i = 0; $i < 24; $i++ ){
        $hours .= ($h == $i) ? $html->b( $i ) : ' ' . $html->button( $i,
            sprintf( "index=$index&HOUR=%d-%02.f-%02.f+%02.f&EX_PARAMS=$FORM{EX_PARAMS}$pages_qs", $y, $m, $d, $i ),
            { BUTTON => 1 } );
      }

      $LIST_PARAMS{HOUR} = $FORM{HOUR};

      push @rows, [ " $lang{HOURS} ", $hours ];
    }

    if ( $attr->{EX_PARAMS} ){
      push @rows, [ ' ', $EX_PARAMS ];
    }

    my $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'left' ],
        rows       => \@rows
      }
    );
    print $table->show();
  }

  return 1;
}

#**********************************************************
#
#**********************************************************
sub report_fees_month{
  $FORM{allmonthes} = 1;
  report_fees();
}

#**********************************************************
=head2 report_fees()

=cut
#**********************************************************
sub report_fees{

  if ( !$permissions{2} || !$permissions{2}{0} ){
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
    return 0;
  }

  my $FEES_METHODS = get_fees_types();
  my %METHODS_HASH = ();
  while (my ($k, $v) = each %$FEES_METHODS) {
    $METHODS_HASH{"$k:$k"} = "$v";
  }

  reports(
    {
      DATE          => $FORM{DATE},
      REPORT      => '',
      PERIOD_FORM => 1,
      FIELDS      => { %METHODS_HASH },
      EXT_TYPE    => {
        METHOD    => $lang{TYPE},
        ADMINS    => $lang{ADMINS},
        FIO       => $lang{FIO},
        COMPANIES => $lang{COMPANIES},
        PER_MONTH => $lang{PER_MONTH}
      }
    }
  );

  if ( defined( $FORM{FIELDS} ) && $FORM{FIELDS} >= 0 ){
    $LIST_PARAMS{METHODS} = $FORM{FIELDS};
  }

  $LIST_PARAMS{PAGE_ROWS} = 1000000;
  my $Fees = Finance->fees( $db, $admin, \%conf );
  my $graph_type = 'month_stats';
  our %DATA_HASH;
  my $table_fees;
  my $list;

  if ( $FORM{DATE} ){
    $graph_type = '';
    $LIST_PARAMS{DATE} = $FORM{DATE};
    form_fees();
    return 0;
  }
  else{
    my $type = ($FORM{TYPE}) ? $FORM{TYPE} : 'DATE';

    if ( $type ){
      $type = $type;
      $pages_qs .= "&TYPE=$type";
    }
    else {
      $graph_type = 'month_stats';
    }
    my $x_text = 'date';

    if ( $type eq 'PAYMENT_METHOD' ){
      $x_text = 'method';
    }
    elsif ( $type eq 'ADMINS' ){
      $x_text = 'admin_name';
    }
    elsif ( $type eq 'BUILD' ){
      $x_text = 'build';
    }
    elsif ( $type eq 'PER_MONTH' ){
      $x_text = 'month';
    }
    elsif ( $type eq 'DISTRICT' ){
      $x_text = 'district_name';
    }
    elsif ( $type eq 'STREET' ){
      $x_text = 'street_name';
    }
    elsif ( $type eq 'HOURS' ){
      $graph_type = 'hour_stats';
    }

    %CHARTS = (
      TYPES => {
        login_count => 'column',
        count       => 'column',
        sum         => 'line',
        arppu       => 'line',
        arpu        => 'line',
      }
    );

    ($table_fees, $list) = result_former( {
      INPUT_DATA      => $Fees,
      FUNCTION        => 'reports',
      BASE_FIELDS     => ($type =~ /MONTH/) ? 6 : 4,
      SKIP_USER_TITLE => 1,
      SELECT_VALUE    => {
        method => $FEES_METHODS,
        gid    => sel_groups( { HASH_RESULT => 1 } ),
      },
      CHARTS          => 'login_count,count,sum' . (($type =~ /MONTH/) ? ',arppu,arpu' : ''),
      CHARTS_XTEXT    => $x_text,
      EXT_TITLES      => {
#          arpu          => $lang{ARPU},
#          arpuu         => $lang{ARPPU},
        date          => $lang{DATE},
        month         => $lang{MONTH},
        login         => $lang{USER},
        fio           => $lang{FIO},
        hour          => $lang{HOURS},
        build         => $lang{ADDRESS_BUILD},
        district_name => $lang{DISTRICT},
        street_name   => $lang{ADDRESS_STREET},
        method        => $lang{PAYMENT_METHOD},
        admin_name    => $lang{ADMIN},
        login_count   => $lang{USERS},
        count         => $lang{COUNT},
        sum           => $lang{SUM}
      },
      FILTER_COLS     => {
        admin_name    => "search_link:report_fees:ADMIN_NAME,$type=1,$pages_qs",
        method        => "search_link:report_fees:METHOD,TYPE=USER,$pages_qs",
        login         => "search_link:from_users:UID,$type=1,$pages_qs",
        date          => "search_link:report_fees:DATE,DATE",
        build         => "search_link:report_fees:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
        district_name => "search_link:report_fees:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
        street_name   => "search_link:report_fees:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{REPORTS} - $lang{FEES}",
        qs      => $pages_qs,
        ID      => 'REPORTS_FEES',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
    });
  }

  if ( $graph_type ne '' ){
    print $html->make_charts(
        {
          PERIOD        => $graph_type,
          DATA          => \%DATA_HASH,
          TITLE         => $lang{PAYMENTS},
          TRANSITION    => 1,
          OUTPUT2RETURN => 1,
          %CHARTS
        }
      );
  }

  print $table_fees->show();

  my $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{USERS}: " . $html->b( $Fees->{USERS} ), "$lang{TOTAL}: " . $html->b( $Fees->{TOTAL} ),
        "$lang{SUM}: " . $html->b( $Fees->{SUM} ) ] ],
      rowcolor   => 'even'
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
#
#**********************************************************
sub report_payments_month{
  $FORM{allmonthes} = 1;
  report_payments();
}


#**********************************************************
=head2 report_payments()

=cut
#**********************************************************
sub report_payments{
  if ( !$permissions{1} || !$permissions{1}{0} ){
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
    return 0;
  }

  my %METHODS_HASH = ();
  my $PAYMENT_METHODS = get_payment_methods();
  our %DATA_HASH    = ();

  while (my ($k, $v) = each %$PAYMENT_METHODS) {
    $METHODS_HASH{"$k:$k"} = $v;
  }

  if ( defined( $FORM{FIELDS} ) && $FORM{FIELDS} ne '' ){
    $LIST_PARAMS{METHOD} = $FORM{FIELDS};
    $LIST_PARAMS{METHOD} =~ s/ //g;
    $LIST_PARAMS{METHOD} =~ s/,/;/g;
  }
  elsif ( $FORM{METHOD} ){
    $LIST_PARAMS{METHOD} = $FORM{METHOD};
    $FORM{FIELDS} = $FORM{METHOD};
  }

  reports(
    {
      DATE        => $FORM{DATE},
      REPORT      => '',
      PERIOD_FORM => 1,
      FIELDS      => \%METHODS_HASH,
      EXT_TYPE    => {
        PAYMENT_METHOD => $lang{PAYMENT_METHOD},
        ADMINS         => $lang{ADMINS},
        FIO            => $lang{FIO},
        PER_MONTH      => $lang{PER_MONTH},
        DISTRICT       => $lang{DISTRICT},
        STREET         => $lang{STREET},
        BUILD          => $lang{BUILD},
        GID            => $lang{GROUPS},
      }
    }
  );

  $LIST_PARAMS{PAGE_ROWS} = 1000000;
  my $payments = Finance->payments( $db, $admin, \%conf );

  my $graph_type = '';
  my ($table, $list);

  if ( $FORM{DATE} || $FORM{search} ){
    $LIST_PARAMS{DATE} = $FORM{DATE};
    delete($LIST_PARAMS{MONTH});

    $FORM{index} = 2;
    delete( $FORM{search_form} );
    delete( $FORM{type} );

    form_payments();

    return 0;
  }
  else{
    my $type = $FORM{TYPE} || '';
    if ( $type ){
      $type = $type;
      $pages_qs .= "&TYPE=$type";
    }
    else {
      $graph_type = 'month_stats';
    }
    my $x_text = 'date';

    if ( $type eq 'PAYMENT_METHOD' ){
      $x_text = 'method';
    }
    elsif ( $type eq 'ADMINS' ){
      $x_text = 'admin_name';
    }
    elsif ( $type eq 'BUILD' ){
      $x_text = 'build';
    }
    elsif ( $type eq 'PER_MONTH' ){
      $x_text = 'month';
    }
    elsif ( $type eq 'DISTRICT' ){
      $x_text = 'district_name';
    }
    elsif ( $type eq 'STREET' ){
      $x_text = 'street_name';
    }
    elsif ( $type eq 'HOURS' ){
      $graph_type = 'hour_stats';
    }

    %CHARTS = (
      TYPES => {
        login_count => 'column',
        count       => 'column',
        sum         => 'line',
        arppu       => 'line',
        arpu        => 'line',
      }
    );

    ($table, $list) = result_former( {
      INPUT_DATA      => $payments,
      FUNCTION        => 'reports',
      BASE_FIELDS     => ($type =~ /MONTH/) ? 6 : 4,
      #DEFAULT_FIELDS  => 'ARPU',
      SKIP_USER_TITLE => 1,
      SELECT_VALUE    => {
        method => $PAYMENT_METHODS,
        gid    => sel_groups( { HASH_RESULT => 1 } ),
      },
      CHARTS          => 'login_count,count,sum' . (($type =~ /MONTH/) ? ',arppu,arpu' : ''),
      CHARTS_XTEXT    => $x_text,
      EXT_TITLES      => {
        arpu          => $lang{ARPU},
        arpuu         => $lang{ARPPU},
        date          => $lang{DATE},
        month         => $lang{MONTH},
        login         => $lang{USER},
        fio           => $lang{FIO},
        hour          => $lang{HOURS},
        build         => $lang{ADDRESS_BUILD},
        district_name => $lang{DISTRICT},
        street_name   => $lang{ADDRESS_STREET},
        method        => $lang{PAYMENT_METHOD},
        admin_name    => $lang{ADMIN},
        login_count   => $lang{USERS},
        count         => $lang{COUNT},
        sum           => $lang{SUM}
      },
      FILTER_COLS     => {
        admin_name    => "search_link:report_payments:ADMIN_NAME,$type=1,$pages_qs",
        method        => "search_link:report_payments:METHOD,TYPE=USER,$pages_qs",
        login         => "search_link:from_users:UID,$type=1,$pages_qs",
        date          => "search_link:report_payments:DATE,DATE",
        build         => "search_link:report_payments:LOCATION_ID,LOCATION_ID,TYPE=USER,$pages_qs",
        district_name => "search_link:report_payments:DISTRICT_ID,DISTRICT_ID,TYPE=USER,$pages_qs",
        street_name   => "search_link:report_payments:STREET_ID,STREET_ID,TYPE=USER,$pages_qs",
      },
      TABLE           => {
        width   => '100%',
        caption => "$lang{REPORTS}",
        qs      => $pages_qs,
        ID      => 'REPORTS_PAYMENTS',
        EXPORT  => 1,
      },
      MAKE_ROWS       => 1,
      SEARCH_FORMER   => 1,
    } );
  }

  print $html->make_charts(
      {
        PERIOD        => $graph_type,
        DATA          => \%DATA_HASH,
        TITLE         => $lang{PAYMENTS},
        TRANSITION    => 1,
        OUTPUT2RETURN => 1,
        %CHARTS
      }
    );

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{USERS}: " . $html->b( $payments->{TOTAL_USERS} ),
        "$lang{TOTAL}: " . $html->b( $payments->{TOTAL_OPERATION} ),
        "$lang{SUM}: " . $html->b( $payments->{TOTAL_SUM} ) ] ],
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_reports($information);

=cut
#**********************************************************
sub form_reports{
  #my ($information) = @_;

  require Abills::main::Quick_reports;
  my $reports = form_quick_reports();

  if ( !$reports ){
    return 0;
  }

  print $html->form_main( { CONTENT => $reports,
        HIDDEN                      => {
          AWEB_OPTIONS => 1,
          index        => $index,
        },
        SUBMIT                      => { change => "$lang{CHANGE}" }
      } );

  return 1;
}

#**********************************************************
=head2 form_system_changes();

=cut
#**********************************************************
sub form_system_changes{

  my %search_params = ();

  my %action_types = (
    0  => 'Unknown',
    1  => "$lang{ADDED}",
    2  => "$lang{CHANGED}",
    3  => "$lang{CHANGED} $lang{TARIF_PLAN}",
    4  => "$lang{CHANGED} $lang{STATUS}",
    5  => '-',
    6  => "$lang{INFO}",
    7  => '-',
    8  => "$lang{ENABLE}",
    9  => "$lang{DISABLE}",
    10 => "$lang{DELETED}",
    11 => "$lang{ERR_WRONG_PASSWD}",
    13 => "Online $lang{DEL}",
    27 => "$lang{SHEDULE} $lang{ADDED}",
    28 => "$lang{SHEDULE} $lang{DELETED}",
    29 => "$lang{SHEDULE} $lang{EXECUTED}",
    41 => "$lang{CHANGED} $lang{EXCHANGE_RATE}",
    42 => "$lang{DELETED} $lang{EXCHANGE_RATE}",
    50 => "DENY IP",
    60 => "$lang{TPL_CHANGED}",
    61 => "$lang{TPL_DELETED}",
    62 => "$lang{FILE_ADDED}",
    63 => "$lang{FILE_DELETED}"
  );

  if ( $permissions{4}{3} && $FORM{del} && $FORM{COMMENTS} ){
    $admin->system_action_del( $FORM{del} );
    if ( !_error_show( $admin ) ){
      $html->message( 'info', $lang{DELETED}, "$lang{DELETED} [$FORM{del}]" );
    }
  }
  elsif ( $FORM{AID} && !defined( $LIST_PARAMS{AID} ) ){
    $FORM{subf} = $index;
    form_admins();
    return 0;
  }

  if ( !defined( $FORM{sort} ) ){
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  %search_params = %FORM;
  $search_params{MODULES_SEL} = $html->form_select(
    'MODULE',
    {
      SELECTED      => $FORM{MODULE},
      SEL_ARRAY     => [ '', @MODULES ],
      OUTPUT2RETURN => 1
    }
  );

  $search_params{TYPE_SEL} = $html->form_select(
    'TYPE',
    {
      SELECTED      => $FORM{TYPE},
      SEL_HASH      => { '' => $lang{ALL}, %action_types },
      SORT_KEY      => 1,
      OUTPUT2RETURN => 1
    }
  );

  form_search(
    {
      HIDDEN_FIELDS       => $LIST_PARAMS{AID},
        SEARCH_FORM       =>
        $html->tpl_show( templates( 'form_history_search' ), \%search_params, { OUTPUT2RETURN => 1 } ),
        PLAIN_SEARCH_FORM => 1
    }
  );

  my $list = $admin->system_action_list( { %LIST_PARAMS } );
  my $table = $html->table(
    {
      width      => '100%',
      title      => [ '#', $lang{DATE}, $lang{CHANGED}, $lang{ADMIN}, 'IP', "$lang{MODULES}", "$lang{TYPE}", '-' ],
      cols_align => [ 'right', 'left', 'right', 'left', 'left', 'right', 'left', 'left', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $admin->{TOTAL},
      ID         => 'ADMIN_SYSTEM_ACTIONS',
      EXPORT     => 1,
    }
  );

  foreach my $line ( @{$list} ){
    my $delete = ($permissions{4}{3}) ? $html->button( $lang{DEL}, "index=$index$pages_qs&del=$line->[0]",
        { MESSAGE => "$lang{DEL} [$line->[0]] ?", class => 'del' } ) : '';

    $table->{rowcolor} = undef;
    my $color = undef;
    if ( in_array( $line->[6], [ 10, 28, 13, 61, 63 ] ) ){
      $color = 'red';
    }
    elsif ( in_array( $line->[6], [ 1, 7 ] ) ){
      $table->{rowcolor} = $_COLORS[3];
    }

    $table->addrow( $html->b( $line->[0] ),
      $html->color_mark( $line->[1], $color ),
      $html->color_mark( $line->[2], $color ),
      $line->[3],
      $line->[4],
      $line->[5],
      $html->color_mark( $action_types{ $line->[6] }, $color ),
      $delete
    );
  }

  print $table->show();
  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b( $admin->{TOTAL} ) ] ]
    }
  );
  print $table->show();

  return 1;
}


#**********************************************************
=head2 reports_webserver()

=cut
#**********************************************************
sub report_webserver{
  my $web_error_log = $conf{WEB_SERVER_ERROR_LOG} || "/var/log/httpd/abills-error.log";

  my $table = $html->table(
    {
      caption     => 'WEB server info',
      width       => '600',
      title_plain => [ "$lang{NAME}", "$lang{VALUE}", "-" ],
      cols_align  => [ 'left', 'left', 'center' ],
      ID          => 'WEBSERVER_INFO'
    }
  );

  foreach my $k ( sort keys %ENV ){
    $table->addrow( $k, $ENV{$k}, '' );
  }
  print $table->show();

  $table = $html->table(
    {
      caption     => $web_error_log || '/var/log/httpd/abills-error.log',
      width       => '100%',
      title_plain => [ "$lang{DATE}", "$lang{ERROR}", "CLIENT", "LOG" ],
      cols_align  => [ 'left', 'left', 'left', 'left' ],
      ID          => 'WEBSERVER_LOG'
    }
  );

  if ( -f $web_error_log ){
    open( my $fh, '|-', "/usr/bin/tail -100 $web_error_log" ) or print $html->message( 'err', $lang{ERROR},
        "Can't open file $!" );
    while (<$fh>) {
      if ( /\[(.+)\] \[(\S+)\] \[client (.+)\] (.+)/ ){
        $table->addrow( $1, $2, $3, $4 );
      }
      else{
        $table->addrow( '', '', '', $_ );
      }
    }
    close( $fh );

    print $table->show();
  }

  return 1;
}


#**********************************************************
=head2 report_bruteforce() User portal brute force

=cut
#**********************************************************
sub report_bruteforce{

  if ( $FORM{del} && $FORM{COMMENTS} && $permissions{0}{5} ){
    $users->bruteforce_del( {
        SID  => $FORM{del},
        DATE => ($FORM{del} eq 'all') ? $DATE : undef
      } );

    $html->message( 'info', $lang{INFO}, "$lang{DELETED} # $FORM{del}" );
  }

  $LIST_PARAMS{LOGIN} = $FORM{LOGIN} if ($FORM{LOGIN});

  result_former( {
    INPUT_DATA        => $users,
    FUNCTION        => 'bruteforce_list',
    BASE_FIELDS     => 5,
    EXT_TITLES      => {
      login    => $lang{LOGIN},
      password => $lang{PASSWD},
      datetime => $lang{DATE},
      count    => $lang{COUNT},
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{BRUTE_ATACK},
      qs      => $pages_qs,
      header  => defined( $permissions{0}{5} )                                  ? $html->button(
        "$lang{DEL} $lang{ALL}", "index=$index&del=all",
        { MESSAGE => "$lang{DEL} $lang{ALL}?", class => 'btn btn-default' } ) : '',
      ID      => 'FORM_BRUTEFORCE',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 report_ui_last_sessions() User portal last sessions

=cut
#**********************************************************
sub report_ui_last_sessions{

  if ( $FORM{del} && $FORM{COMMENTS} && $permissions{0}{5} ){
    $users->web_session_del( { sid => $FORM{del},
        ALL                        => ($FORM{del} eq 'all') ? 'all' : undef
      } );
    $html->message( 'info', $lang{INFO}, "$lang{DELETED} # $FORM{del}" );
  }

  if ( $FORM{ACTIVE} ){
    $LIST_PARAMS{ACTIVE} = $FORM{ACTIVE};
  }

  $users->web_sessions_list( { ACTIVE => 300, CHECK => 1, COLS_NAME => 1 } );

  my $table2 = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => [ [ $html->button( "$lang{ACTIV}", "index=$index&&ACTIVE=300" ) . ':', $users->{TOTAL} ] ],
    }
  );

  print $table2->show();

  $LIST_PARAMS{LOGIN} = $FORM{LOGIN} if ($FORM{LOGIN});
  delete( $users->{COL_NAMES_ARR} );

  result_former( {
    INPUT_DATA        => $users,
    FUNCTION        => 'web_sessions_list',
    BASE_FIELDS     => 5,
    FILTER_COLS     => {
    },
    EXT_TITLES      => {
      login    => $lang{LOGIN},
      datetime => $lang{DATE},
      ext_info => 'Browser',
      coordx   => 'coord x',
      coordy   => 'coord y',
    },
    SKIP_USER_TITLE => 1,
    TABLE           => {
      width   => '100%',
      caption => $lang{SESSIONS},
      qs      => $pages_qs,
      header  => defined( $permissions{0}{5} ) ? $html->button(
          "$lang{DEL} $lang{ALL}", "index=$index&del=all",
          { MESSAGE => "$lang{DEL} $lang{ALL}?", class => 'btn btn-default' } ) : '',
      ID      => 'FORM_BRUTEFORCE',
      EXPORT  => 1,
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  } );

  return 1;
}


1
