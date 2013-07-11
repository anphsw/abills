# Misc functions


#**********************************************************
# load_module($string, \%HASH_REF);
#**********************************************************
sub load_module {
  my ($module, $attr) = @_;

  my $lang_file = '';
  $attr->{language} = 'english' if (! $attr->{language});

  foreach my $prefix (@INC) {
    my $realfilename = "$prefix/Abills/modules/$module/lng_$attr->{language}.pl";

    if (-f $realfilename) {
      $lang_file =  $realfilename;
      last;
    }
    elsif (-f "$prefix/Abills/modules/$module/lng_english.pl") {
      $lang_file = "$prefix/Abills/modules/$module/lng_english.pl";
    }
  }

  if ($lang_file ne '') {
    require $lang_file;
  }

   require "Abills/modules/$module/webinterface";

  return 0;
}




#**********************************************************
# Calls function for all registration modules if function exist
#
# cross_modules_call(function_sufix, attr)
#**********************************************************
sub cross_modules_call {
  my ($function_sufix, $attr) = @_;
  my $timeout = $attr->{timeout} || 3;

  $attr->{USER_INFO}->{DEPOSIT} += $attr->{SUM} if ($attr->{SUM});
  my %full_return  = ();
  my @skip_modules = ();
  eval {
    if ($silent) {
      #disable stdout output
      open($SAVEOUT, ">&", STDOUT) or die "XXXX: $!";
      #Reset out
      open STDIN,  '/dev/null';
      open STDOUT, '/dev/null';
      open STDERR, '/dev/null';
    }

    if ($attr->{SKIP_MODULES}) {
      $attr->{SKIP_MODULES} =~ s/\s+//g;
      @skip_modules = split(/,/, $attr->{SKIP_MODULES});
    }

    if ($silent) {
      local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required
      alarm $timeout;
    }

    foreach my $mod (@MODULES) {
      if (in_array($mod, \@skip_modules)) {
        next;
      }

      if ($attr->{DEBUG}) {
        print " $mod -> ". lc($mod).$function_sufix ."\n";
      }

      load_module("$mod", $html);
      my $function = lc($mod) . $function_sufix;
      my $return;
      if (defined(&$function)) {
        $return = $function->($attr);
      }

      $full_return{$mod} = $return;
    }
  };

  if ($silent) {
    # off disable stdout output
    open(STDOUT, ">&", $SAVEOUT);
  }

  return \%full_return;
}


#**********************************************************
# Get function index
#
# get_function_index($function_name, $attr)
#**********************************************************
sub get_function_index {
  my ($function_name, $attr) = @_;
  my $function_index = 0;

  foreach my $k (keys %functions) {
    my $v = $functions{$k};
    if ($v eq "$function_name") {
      $function_index = $k;
      if ($attr->{ARGS} && $attr->{ARGS} ne $menu_args{$k}) {
        next;
      }
      last;
    }
  }

  return $function_index;
}


#**********************************************************
# get_period_dates
# 
# get_period_dates
#
#   TYPE              0 - day, 1 - month  
#   START_DATE
#   ACCOUNT_ACTIVATE
#   PERIOD_ALIGNMENT
#**********************************************************
sub get_period_dates {
  my ($attr)=@_;
  
  my $START_PERIOD = $attr->{START_DATE} || $DATE;
  
  my ($start_date, $end_date);

  if ($attr->{ACCOUNT_ACTIVATE} && $attr->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
    $START_PERIOD = $attr->{ACCOUNT_ACTIVATE};
  }

  my ($start_y, $start_m, $start_d)=split(/-/, $START_PERIOD);

  if ($attr->{TYPE}) {
    if ($attr->{TYPE}==1) {
      my $days_in_month = ($start_m != 2 ? (($start_m % 2) ^ ($start_m > 7)) + 30 : (!($start_y % 400) || !($start_y % 4) && ($start_y % 25) ? 29 : 28));

      #start date
       $end_date   = "$start_y-$start_m-$days_in_month";
      if ($attr->{PERIOD_ALIGNMENT}) {
        $start_date = $START_PERIOD;
      }
      else {
        $start_date = "$start_y-$start_m-01";
        if ($attr->{ACCOUNT_ACTIVATE}) {
          my $end_date = strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $start_d, ($start_m - 1), ($start_y - 1900), 0, 0, 0) + 30 * 86400));
        }        
      }

      return " ($start_date-$end_date)";
    }
  }
  
  return '';
}


#**********************************************************
#
#**********************************************************
sub fees_dsc_former {
  my ($attr)=@_;
  
  $conf{DV_FEES_DSC}='%SERVICE_NAME%: %FEES_PERIOD_MONTH%%FEES_PERIOD_DAY% %TP_NAME% (%TP_ID%)%EXTRA%%PERIOD%' if (! $conf{DV_FEES_DSC});
  if (! $attr->{SERVICE_NAME}) {
  	$attr->{SERVICE_NAME}='Internet';
  }
  my $text = $conf{DV_FEES_DSC};

  while ($text =~ /\%(\w+)\%/g) {
    my $var       = $1;
    if(! defined($attr->{$var})) {
      $attr->{$var}='';
    }
    $text =~ s/\%$var\%/$attr->{$var}/g;
  }
  
  return $text;
}


#**********************************************************
#
# Make month feee
#**********************************************************
sub service_get_month_fee {
  my ($Service, $attr) = @_;

  use Finance;
  my $fees     = Finance->fees($Service->{db}, $admin, \%conf);
  my $payments = Finance->payments($Service->{db}, $admin, \%conf);
  my $users    = Users->new($Service->{db}, $admin, \%conf);

  my %total_sum = (
    ACTIVATE  => 0,
    MONTH_FEE => 0
  );
  my $service_name = $attr->{SERVICE_NAME} || 'Internet';

  $users = $user if ($user->{UID});

  #Make bonus
  if ($conf{DV_BONUS} && $service_name eq 'Internet') {
    eval { require Bonus_rating; };
    if (!$@) {
      Bonus_rating->import();
    }
    else {
      $html->message('err', $_ERROR, "Can't load 'Bonus_rating'. Purchase this module http://abills.net.ua") if (!$attr->{QUITE});
      return 0;
    }

    my $Bonus_rating = Bonus_rating->new($Service->{db}, $admin, \%conf);
    $Bonus_rating->info($Service->{TP_INFO}->{TP_ID});


    if ($Bonus_rating->{TOTAL} > 0) {
      my $bonus_sum = 0;
      if ($FORM{add} && $Bonus_rating->{ACTIVE_BONUS} > 0) {
        $bonus_sum = $Bonus_rating->{ACTIVE_BONUS};
      }
      elsif ($Bonus_rating->{CHANGE_BONUS} > 0) {
        $bonus_sum = $Bonus_rating->{CHANGE_BONUS};
      }

      if ($bonus_sum > 0) {
        if (!$users->{BILL_ID}) {
          $users->info($Service->{UID});
        }
        my $u = $users;
        $u->{BILL_ID} = ($Bonus_rating->{EXT_BILL_ACCOUNT}) ? $users->{EXT_BILL_ID} : $users->{BILL_ID};

        $payments->add($u,
          {
            SUM      => $bonus_sum,
            METHOD   => 4,
            DESCRIBE => "$_BONUS: $_TARIF_PLAN: $Service->{TP_ID}",
          }
        );
        if ($payments->{errno}) {
          $html->message('err', $_ERROR, "[$payments->{errno}] $payments->{errstr}") if (!$attr->{QUITE});
        }
        else {
          $html->message('info', $_INFO, "$_BONUS: $bonus_sum") if (!$attr->{QUITE});
        }
      }
    }
  }

  my %FEES_METHODS = %{ get_fees_types() };
  if (! $users->{BILL_ID}) {
    $user  = $users->info($Service->{UID});
  }
  #Get active price
  if ($Service->{TP_INFO}->{ACTIV_PRICE} > 0) {
    my $date  = ($user->{ACTIVATE} ne '0000-00-00') ? $user->{ACTIVATE} : $DATE;
    my $time  = ($user->{ACTIVATE} ne '0000-00-00') ? '00:00:00' : $TIME;

    if (!$Service->{OLD_STATUS} || $Service->{OLD_STATUS} == 2) {
      $fees->take(
        $user,
        $Service->{TP_INFO}->{ACTIV_PRICE},
        {
          DESCRIBE => "$_ACTIVATE $_TARIF_PLAN",
          DATE     => "$date $time"
        }
      );
      $total_sum{ACTIVATE} = $Service->{TP_INFO}->{ACTIV_PRICE};
      $html->message('info', $_INFO, "$_ACTIVATE $_TARIF_PLAN") if ($html);
    }
  }

  my $message = '';
  #Current Month
  my ($y, $m, $d)   = split(/-/, $DATE, 3);
  my $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28));

  if ( $FORM{RECALCULATE} ) {

    my $rest_days     = $days_in_month - $d + 1;
    #my $rest_day_sum1 = (! $Service->{TP_INFO}->{ABON_DISTRIBUTION}) ? $Service->{TP_INFO}->{MONTH_FEE} /  $days_in_month * $rest_days : 0;
    my $rest_day_sum2 = (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) ? $Service->{TP_INFO_OLD}->{MONTH_FEE} /  $days_in_month * $rest_days : 0;
    $sum              = $rest_day_sum2; # sprintf("%.5f", $rest_day_sum1 - $rest_day_sum2);

    #PERIOD_ALIGNMENT
    $Service->{TP_INFO}->{PERIOD_ALIGNMENT}=1;
    #Compensation
    if ($sum > 0) {
      $payments->add($users,
          {
           SUM      => abs($sum),
           METHOD   => 8,
           DESCRIBE => "$_TARIF_PLAN: $Service->{TP_INFO_OLD}->{NAME} ($Service->{TP_INFO_OLD}->{ID})",
          }
      );
              
      if ($payments->{errno}) {
        $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");
      }
      else {
    	  $message .= "$_RECALCULATE\n$_RETURNED: ". sprintf("%.2f", abs($sum))."\n";
      }
    }
  }

  my $TIME = "00:00:00";
  my %FEES_PARAMS = (
              DATE   => "$DATE $TIME",
              METHOD => ($Service->{TP_INFO}->{FEES_METHOD}) ? $Service->{TP_INFO}->{FEES_METHOD} : 1
            );

  #Get month fee
  if ($Service->{TP_INFO}->{MONTH_FEE} > 0) {    
    my $sum   = $Service->{TP_INFO}->{MONTH_FEE};

    if ($Service->{TP_INFO}->{EXT_BILL_ACCOUNT}) {
      if ($user->{EXT_BILL_ID}) {
        if (!$conf{BONUS_EXT_FUNCTIONS} || ($conf{BONUS_EXT_FUNCTIONS} && $user->{EXT_BILL_DEPOSIT} > 0)) {
          $user->{MAIN_BILL_ID} = $user->{BILL_ID};
          $user->{BILL_ID}      = $user->{EXT_BILL_ID};
        }
      }
    }

    my %FEES_DSC = (
              SERVICE_NAME    => $service_name,
              MODULE          => $service_name.':',
              TP_ID           => $Service->{TP_INFO}->{ID},
              TP_NAME         => "$Service->{TP_INFO}->{NAME}",
              FEES_PERIOD_DAY => $_MONTH_FEE_SHORT,
              FEES_METHOD     => $FEES_METHODS{$Service->{TP_INFO}->{FEES_METHOD}},
            );

    my ($active_y, $active_m, $active_d) = split(/-/, $Service->{ACCOUNT_ACTIVATE} || $users->{ACTIVATE}, 3);

    if (int("$y$m$d") < int("$active_y$active_m$active_d")) {
      return \%total_sum;
    }

    if ($Service->{TP_INFO}->{PERIOD_ALIGNMENT} && !$Service->{TP_INFO}->{ABON_DISTRIBUTION}) {
      $FEES_DSC{EXTRA} = " $_MONTH_ALIGNMENT,";

      if ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        $days_in_month = ($active_m != 2 ? (($active_m % 2) ^ ($active_m > 7)) + 30 : (!($active_y % 400) || !($active_y % 4) && ($active_y % 25) ? 29 : 28));
        $d = $active_d;
      }
      $conf{START_PERIOD_DAY} = 1 if (!$conf{START_PERIOD_DAY});
      my $calculation_days = ($d < $conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} - $d : $days_in_month - $d + $conf{START_PERIOD_DAY};

      $sum = sprintf("%.2f", ($sum / $days_in_month) * $calculation_days);
    }

    return \%total_sum if ($sum == 0);

    my $periods = 0;
    if (int($active_m) > 0 && int($active_m) < $m) {
      $periods = $m - $active_m;
      if (int($active_d) > int($d)) {
        $periods--;
      }
      #$active_m++;
    }
    elsif (int($active_m) > 0 && (int($active_m) >= int($m) && int($active_y) < int($y))) {
      $periods = 12 - $active_m + $m;
      if (int($active_d) > int($d)) {
        $periods--;
      }
    }

    #Make reduction
    if ($user->{REDUCTION} > 0 && $Service->{TP_INFO}->{REDUCTION_FEE}) {
      $sum = $sum * (100 - $users->{REDUCTION}) / 100;
    }

    if ($Service->{TP_INFO}->{ABON_DISTRIBUTION}) {
      $sum = $sum / (($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28)));
      $FEES_DSC{EXTRA} = " - $_ABON_DISTRIBUTION";
    }

    if ($Service->{ACCOUNT_ACTIVATE} ne '0000-00-00' && ($Service->{OLD_STATUS} == 5)) {
      if ($conf{DV_CURDATE_ACTIVATE}) {
        $periods = 0;        
      }
      #if activation in cure month curmonth
      elsif ($periods == 0 || ($periods == 1 && $d < $active_d)) {
        $periods = -1;
      }
      else {
        $periods -= 1;
      }
    }
    
    $m = $active_m if ($active_m > 0);

    for (my $i = 0 ; $i <= $periods ; $i++) {
      if ($m > 12) {
        $m        = 1;
        $active_y = $active_y + 1;
      }

      $m = sprintf("%.2d", $m);

      my $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($active_y % 400) || !($active_y % 4) && ($active_y % 25) ? 29 : 28));
      if ($i > 0) {
        $FEES_DSC{EXTRA} = '';
      	$message         = '';
        if ($user->{REDUCTION} > 0 && $Service->{TP_INFO}->{REDUCTION_FEE}) {
          $sum = $Service->{TP_INFO}->{MONTH_FEE} * (100 - $users->{REDUCTION}) / 100;
        }
        else {
        	$sum = $Service->{TP_INFO}->{MONTH_FEE};
        }

        if ($Service->{ACCOUNT_ACTIVATE}) {
          $DATE          = $Service->{ACCOUNT_ACTIVATE};
          my $end_period = strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400));
          $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
          $users->change(
            $Service->{UID},
            {
              ACTIVATE => "$DATE",
              UID      => $Service->{UID}
            }
          );
          $Service->{ACCOUNT_ACTIVATE} = strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400));
        }
        else {
          $DATE             = "$active_y-$m-01";
          $FEES_DSC{PERIOD} = "($active_y-$m-01-$active_y-$m-$days_in_month)";
        }
      }
      elsif ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        my $end_period = strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400));

        if ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) {
          $users->change(
            $Service->{UID},
            {
              ACTIVATE => '0000-00-00',
              UID      => $Service->{UID}
            }
          );
          $end_period  = "$y-$m-$days_in_month";
        }
        elsif ($Service->{OLD_STATUS} == 5) {
          $users->change(
            $Service->{UID},
            {
              ACTIVATE => ($conf{DV_CURDATE_ACTIVATE}) ? $DATE : "$active_y-$m-$active_d",
              UID      => $Service->{UID}
            }
          );
          if ($conf{DV_CURDATE_ACTIVATE}) {
            ($active_y, $active_m, $active_d)=split(/-/, $DATE);
          }
        }
        else {
          $DATE = "$active_y-$m-$active_d";
        }

        $Service->{ACCOUNT_ACTIVATE} = ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) ? undef : strftime "%Y-%m-%d", localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400));
        $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
      }
      else {
        my $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($active_y % 400) || !($active_y % 4) && ($active_y % 25) ? 29 : 28));
        my $start_date = ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) ? (($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') ? $Service->{ACCOUNT_ACTIVATE} : $DATE) : "$y-$m-01";
        $FEES_DSC{PERIOD} = "($start_date-$y-$m-$days_in_month)";
      }

      $FEES_PARAMS{DESCRIBE} = fees_dsc_former(\%FEES_DSC);
      $FEES_PARAMS{DESCRIBE}.= $attr->{EXT_DESCRIBE} if ($attr->{EXT_DESCRIBE});
      $message              .= $FEES_PARAMS{DESCRIBE};

      if ($conf{EXT_BILL_ACCOUNT}) {
        if ($user->{EXT_BILL_DEPOSIT} < $sum && $user->{MAIN_BILL_ID}) {
          $sum = $sum - $user->{EXT_BILL_DEPOSIT};
          $fees->take($users, $user->{EXT_BILL_DEPOSIT}, \%FEES_PARAMS);
          $user->{BILL_ID}      = $user->{MAIN_BILL_ID};
          $user->{MAIN_BILL_ID} = undef;
        }
      }

      if ($sum > 0) {
        $fees->take($users, $sum, \%FEES_PARAMS);
        $total_sum{MONTH_FEE} += $sum;
        if ($fees->{errno}) {
          $html->message('err', $_ERROR, "[$fees->{errno}] $fees->{errstr}") if (!$attr->{QUITE});
        }
        else {
          $html->message('info', $_INFO, $message. "\n $_SUM: ". sprintf("%.2f", $sum)) if ($html && !$attr->{QUITE});
        }
      }

      $m++;
    }
  }

  return \%total_sum;
}


#**********************************************************
# result_former
#**********************************************************
sub result_former {
  my ($attr)=@_;

  my @cols = ();

  if($FORM{del_cols}) {
  	$admin->settings_del($attr->{TABLE}->{ID});
    if ($attr->{DEFAULT_FIELDS}){
    	$attr->{DEFAULT_FIELDS}=~s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
  }
  elsif ($FORM{show_columns}) {
	  print $FORM{del_cols};
  	@cols = split(/, /, $FORM{show_columns});
    $admin->settings_add({
    	  SETTING => $FORM{show_columns},
    	  OBJECT  => $attr->{TABLE}->{ID}
    	});
  }  
  else {
  	$admin->settings_info($attr->{TABLE}->{ID});
    if ($admin->{TOTAL} == 0 && $attr->{DEFAULT_FIELDS}){
    	$attr->{DEFAULT_FIELDS}=~s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
    else {
      @cols = split(/, /, $admin->{SETTING});
    }
  }

  foreach my $line (@cols) {
  	if (! defined($LIST_PARAMS{$line}) || $LIST_PARAMS{$line} eq '') {
  		$LIST_PARAMS{$line}='_SHOW';
  	}
  } 	

  my $data = $attr->{INPUT_DATA};
  if ($attr->{FUNCTION}) {
  	my $fn   = $attr->{FUNCTION};
  	my $list = $data->$fn({ COLS_NAME => 1, %LIST_PARAMS, SHOW_COLUMNS => $FORM{show_columns} });
	  $data->{list} = $list;
  }

  if ($data->{error}) {
  	return undef, undef;
  }

  my @service_status_colors = ("$_COLORS[9]", "$_COLORS[6]", '#808080', '#0000FF', '#FF8000', '#009999');
  my @service_status        = ("$_ENABLE", "$_DISABLE", "$_NOT_ACTIVE", "$_HOLD_UP", 
  "$_DISABLE: $_NON_PAYMENT", "$ERR_SMALL_DEPOSIT",
  "$_VIRUS_ALERT" );

  %SEARCH_TITLES = (
    'disable'       => "$_STATUS",
    'login_status'  => "$_LOGIN $_STATUS",
    'deposit'       => "$_DEPOSIT",
    'credit'        => "$_CREDIT",
    'login'         => "$_LOGIN",
    'fio'           => "$_FIO",
    'ext_deposit'   => "$_EXTRA $_DEPOSIT",
    'last_payment'  => "$_PAYMENTS $_DATE",
    'email'         => 'E-Mail',
    'pasport_date'  => "$_PASPORT $_DATE",
    'pasport_num'   => "$_PASPORT $_NUM",
    'pasport_grant' => "$_PASPORT $_GRANT",
    'contract_id'   => "$_CONTRACT_ID",
    'registration'  => "$_REGISTRATION",
    'phone'         => "$_PHONE",
    'comments'      => "$_COMMENTS",
    'company_id'    => "$_COMPANY ID",
    'bill_id'       => "$_BILLS",
    'activate'      => "$_ACTIVATE",
    'expire'        => "$_EXPIRE",
    'credit_date'   => "$_CREDIT $_DATE",
    'reduction'     => "$_REDUCTION",
    'domain_id'     => 'DOMAIN ID',

    'district_name' => "$_DISTRICTS",
    'address_full'  => "$_FULL $_ADDRESS",
    'address_street'=> "$_ADDRESS_STREET",
    'address_build' => "$_ADDRESS_BUILD",
    'address_flat'  => "$_ADDRESS_FLAT",

    'city'          => "$_CITY",
    'zip'           => "$_ZIP",

    'deleted'       => "$_DELETED",
    'gid'           => "$_GROUP",
    'group_name'   => "$_GROUP $_NAME",
#    'build_id'      => 'Location ID',
    'uid'           => 'UID',
  );
  
  %ACTIVE_TITLES = ();
  
  if ($data->{EXTRA_FIELDS}) {
    foreach my $line (@{ $data->{EXTRA_FIELDS} }) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my ($position, $type, $name, $user_portal) = split(/:/, $line->[1]);
        if ($type == 2) {
          $SEARCH_TITLES{ $field_id . '_list_name' } = eval "\"$name\"";
        }
        else {
          $SEARCH_TITLES{ $field_id } = eval "\"$name\"";
        }
      }
    }
  }

  %SEARCH_TITLES = ( %SEARCH_TITLES, %{ $attr->{EXT_TITLES} } );

  my $base_fields  = $attr->{BASE_FIELDS};
  my @EX_TITLE_ARR = @{ $data->{COL_NAMES_ARR} };
  my @title        = ();

  for (my $i = 0 ; $i < $base_fields+$data->{SEARCH_FIELDS_COUNT} ; $i++) {
    $title[$i]     = $SEARCH_TITLES{ $EX_TITLE_ARR[$i] } || $EX_TITLE_ARR[$i] || "$_SEARCH";
    $ACTIVE_TITLES{$EX_TITLE_ARR[$i]} = $FORM{uc($EX_TITLE_ARR[$i])} || '_SHOW';
  }

  my @function_fields = split(/,/, $attr->{FUNCTION_FIELDS} || '' );
  
  foreach my $function_fld_name ( @function_fields ) {
    $title[$#title+1]='-';
  }
  
  if ($attr->{TABLE} ) {
    my $table = $html->table(
      {
        width      => $attr->{TABLE}{width},
        caption    => $attr->{TABLE}{caption},
        border     => $attr->{TABLE}{border},
        title      => \@title,
        cols_align => [ 'left', 'left', 'right', 'right', 'left', 'center', 'center:noprint', 'center:noprint' ],
        qs         => $attr->{TABLE}{qs},
        pages      => (! $attr->{SKIP_PAGES}) ? $data->{TOTAL} : undef,
        ID         => $attr->{TABLE}{ID},
        header     => $attr->{TABLE}{header},
        SHOW_COLS  => \%SEARCH_TITLES,
        ACTIVE_COLS=> \%ACTIVE_TITLES,
        EXPORT     => $attr->{TABLE}{EXPORT},
        MENU       => $attr->{TABLE}{MENU},
        SELECT_ALL => $attr->{TABLE}{SELECT_ALL},
      }
     );
    
    if ($attr->{MAKE_ROWS}) {
      foreach my $line (@{ $data->{list} }) {
        my @fields_array = ();
        for (my $i = 0 ; $i < $data->{SEARCH_FIELDS_COUNT}+$base_fields ; $i++) {
          my $val = '';
      
          if ($data->{COL_NAMES_ARR}->[$i] eq 'login' && $line->{uid}) {
      	    $val = user_ext_menu($line->{uid}, $line->{login}, { EXT_PARAMS => ($attr->{MODULE} ? "MODULE=$attr->{MODULE}": undef) }); 
          }
          elsif($data->{COL_NAMES_ARR}->[$i] =~ /status/) {
      	    $val = ($line->{$data->{COL_NAMES_ARR}->[$i]} > 0) ? $html->color_mark($service_status[ $line->{$data->{COL_NAMES_ARR}->[$i]} ], $service_status_colors[ $line->{$data->{COL_NAMES_ARR}->[$i]} ]) : "$service_status[$line->{$data->{COL_NAMES_ARR}->[$i]}]";
          }
          elsif($data->{COL_NAMES_ARR}->[$i] =~ /deposit/) {
            $val = ($permissions{0}{12}) ? '--' : ($line->{deposit} + $line->{credit} < 0) ? $html->color_mark($line->{deposit}, $_COLORS[6]) : $line->{deposit},
          }
          elsif($data->{COL_NAMES_ARR}->[$i] eq 'online') {
            $val = ($line->{online}) ? $html->color_mark('Online', '#00FF00') : '';
          }
          else {
      	    $val = $line->{ $data->{COL_NAMES_ARR}->[$i]  };
          }

          if ($i==0 && $attr->{MULTISELECT}) {
          	my($id, $value) = split(/:/, $attr->{MULTISELECT});
          	$val = $html->form_input($id, $line->{$value}, { TYPE => 'checkbox' }) . ' '. $val;
          }

          push @fields_array, $val;
        }

        if($#function_fields > -1) {
        	for($i=0; $i<=$#function_fields; $i++) {
        		if($function_fields[$i] eq 'form_payments') {
        			push @fields_array, ($permissions{1}) ? $html->button($function_fields[$i], "UID=$line->{uid}&index=2", { CLASS=>'payments' }) : '-';
        		}
        		elsif($function_fields[$i] =~ /stats/) {
        			push @fields_array, $html->button($function_fields[$i], "UID=$line->{uid}&index=".get_function_index($#function_fields), { CLASS=>'stats' });
        		}
        		elsif($function_fields[$i] eq 'change') {
        			push @fields_array, $html->button($_CHANGE, "index=$index&chg=$line->{id}". ($line->{uid} ? "&UID=$line->{uid}": undef). ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}": undef), { CLASS=>'change' });
        		}
        		elsif($function_fields[$i] eq 'del') {
        			push @fields_array, $html->button($_DEL, "&index=$index&del=$line->{id}". ($line->{uid} ? "&UID=$line->{uid}": undef) . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}": undef), { CLASS=>'del', MESSAGE => "$_DEL $line->{id}?" });
        		}
        		else {
        		  push @fields_array, $html->button($function_fields[$i], "UID=$line->{uid}&index=".get_function_index($#function_fields), { BUTTON => 1 });
        		}
        	}
        }

        $table->addrow(@fields_array);
      }
    }
    
    if ($attr->{TOTAL}) {
  	  my $result = $table->show();
      if (! $admin->{MAX_ROWS}) {
        $table = $html->table(
          {
            width      => '100%',
            cols_align => [ 'right', 'right' ],
            rows       => [ [ "$_TOTAL:", $html->b($data->{TOTAL}) ] ]
          }
        );
        $result .= $table->show();
      }

      if ($attr->{OUTPUT2RETURN}) {
      	return $result, $data->{list};
      }
      else {
      	print $result;
      }
    }
    else {
      return ($table, $data->{list});
    }
  }
  else {
    return \@title;	
  }
}

#**********************************************************
#
#**********************************************************
sub dirname {
  my ($x) = @_;
  if ($x !~ s@[/\\][^/\\]+$@@) {
    $x = '.';
  }
  $x;
}

1