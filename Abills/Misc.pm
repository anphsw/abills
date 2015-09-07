# Misc functions

use vars qw(
  @ISA
  @EXPORT 
  @EXPORT_OK
  $added 
  %conf
  $silent
  @MODULES
  $html
  %functions
  %menu_args
  $DATE
  $user
);


#**********************************************************
# load_pmodule($modulename, \%HASH_REF);
#**********************************************************
sub load_pmodule {
  my ($name, $attr) = @_;

  eval " require $name ";

  my $result = '';

if (!$@) {
  if ($attr->{IMPORT}) {
    $name->import( $attr->{IMPORT} );
  }
  else {
    $name->import();
  }
}
else {
  $result = "Content-Type: text/html\n\n" if ($user->{UID} || $attr->{HEADER});
  $result .= "Can't load '$name'\n".
        " Install Perl Module <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:soft:$name'>$name</a> \n".
        " Main Page <a href='http://abills.net.ua/wiki/doku.php/abills:docs:other:ru?&#ustanovka_perl_modulej'>Perl modules installation</a>\n".
        " or install from <a href='http://www.cpan.org'>CPAN</a>\n"; 

  $result .= "$@" if ($attr->{DEBUG});

  #print "Purchase this module http://abills.net.ua";
  if ($attr->{SHOW_RETURN}) {
    return $result;
  }
  elsif (! $attr->{RETURN} ) {
    print $result;
    die;
  }

  print $result;
}

  return 0;
}

#**********************************************************
# _function($index);
#**********************************************************
sub _error_show {
  my ($module, $attr)=@_;

  my $module_name = $attr->{MODULE_NAME} || $module->{MODULE} || '';
  my $id_prefix   = $attr->{ID_PREFIX}  || '';
  my $message     = $attr->{MESSAGE}  || '';

  if ($module->{errno}) {
    if ($attr->{ERROR_IDS}->{$module->{errno}}) {
      $html->message('err', "$module_name:$_ERROR", $message . $attr->{ERROR_IDS}->{$module->{errno}});
    }
    elsif ($module->{errno} == 15) {
      $html->message('err', "$module_name:$_ERROR", $message . " $ERR_SMALL_DEPOSIT");
    }
    elsif ($module->{errno} == 7) {
      $html->message('err', "$module_name:$_ERROR", $message . " $_EXIST");
      return 1;
    }
    elsif ($module->{errno} == 2) {
      $html->message('err', "$module_name:$_ERROR", $message . " $_NOT_EXIST");
      return 1;
    }
    else {
      my $error = ( $err_strs{$module->{errno}}) ?  $err_strs{$module->{errno}} : $module->{errstr};
      $html->message('err', "$module_name:$_ERROR", $message . "[$module->{errno}] $error", { ID => $attr->{ID} });
      return 1;
    }
  }

  return 0;
}

#**********************************************************
# _function($index);
#**********************************************************
sub _function {
  my($index, $attr) = @_;

  if (! $functions{$index}) {
    print "Content/type: text/html\n\n";
    print "Function not exist!";
    return 0;
  }

  my $function_name = $functions{ $index };
  my $returns = eval { $function_name->($attr) };

  if($@) {
    my $inputs = '';

    $attr->{ALL}=1;
    if ($attr->{ALL}) {
      $inputs = "\n========================\n";
      foreach my $key (sort keys %FORM) {
        next if ($key eq '__BUFFER');
        $inputs .= "$key -> $FORM{$key}\n";
      }
    }

    print "Content-Type: text/html\n\n";
    print << "[END]";
<form action='https://support.abills.net.ua/bugs.cgi' method='post'>
<input type=hidden name='FN_INDEX' value='$index'>
<input type=hidden name='FN_NAME' value='$function_name'>
<input type=hidden name='INPUTS' value='$inputs'>
<input type=hidden name='SYS_ID' value=''>

Critical Error:<br>
<textarea cols=100 rows=8 NAME=ERROR>
$@
$inputs
</textarea>
<br>$_COMMENTS:<input type=text name='COMMENTS' value='' size=80>
<br><input type=submit name='add' value='Send to bug tracker'>

</form>
[END]

    die "Error functionm execute: '$function_name' $!";
#    my $rr = `echo "$function_name" >> /tmp/fe`;
  }

  return $returns;
}


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

  if ($attr->{CONFIG_ONLY}) {
    require "Abills/modules/$module/config";
    return 0;
  }

  eval{ require "Abills/modules/$module/webinterface" };

  if ($@) {
    print "Content-Type: text/html\n\n";
    print "Error: load module '$module'\n $!\n";
    print $@;
    
    print @INC;
    die;
  }

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

  if ($attr->{SUM} && ! $added) {
    $attr->{USER_INFO}->{DEPOSIT} += $attr->{SUM} ;
    $added=1;
  }
  
  if (defined($attr->{SILENT})) {
    $silent=$attr->{SILENT};
  }
  
  my %full_return  = ();
  my @skip_modules = ();
  my $SAVEOUT;
  
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
          my $end_date = strftime('%Y-%m-%d', localtime((mktime(0, 0, 0, $start_d, ($start_m - 1), ($start_y - 1900), 0, 0, 0) + 30 * 86400)));
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

  my $debug = $attr->{DEBUG} || 0;

  require Finance;
  Finance->import();
  my $fees     = Finance->fees($Service->{db}, $admin, \%conf);
  my $payments = Finance->payments($Service->{db}, $admin, \%conf);
  my $users    = Users->new($Service->{db}, $admin, \%conf);

  $conf{START_PERIOD_DAY} = 1 if (!$conf{START_PERIOD_DAY});

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
          _error_show($payments) if (!$attr->{QUITE});
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
        $users,
        $Service->{TP_INFO}->{ACTIV_PRICE},
        {
          DESCRIBE => '$_ACTIVATE_TARIF_PLAN',
          DATE     => "$date $time"
        }
      );
      $total_sum{ACTIVATE} = $Service->{TP_INFO}->{ACTIV_PRICE};
      $html->message('info', $_INFO, "$_ACTIVATE_TARIF_PLAN") if ($html && ! $attr->{QUITE});
    }
  }

  my $message = '';
  #Current Month

  $DATE=$attr->{DATE} if ($attr->{DATE});

  my ($y, $m, $d)   = split(/-/, $DATE, 3);
  my $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28));

  my $TIME = "00:00:00";
  my %FEES_PARAMS = (
              DATE   => "$DATE $TIME",
              METHOD => ($Service->{TP_INFO}->{FEES_METHOD}) ? $Service->{TP_INFO}->{FEES_METHOD} : 1
            );

  if ($attr->{SHEDULER} && $users->{ACTIVATE} ne '0000-00-00') {
    undef $user;
    return \%total_sum;
  }

  #Get back month fee
  if (($Service->{TP_INFO}->{MONTH_FEE} && $Service->{TP_INFO}->{MONTH_FEE} > 0) ||
      ($Service->{TP_INFO_OLD}->{MONTH_FEE} && $Service->{TP_INFO_OLD}->{MONTH_FEE} > 0)
      ) {
    if ( $FORM{RECALCULATE} ) {
      my $rest_days     = 0;
      my $rest_day_sum2 = 0;
      $sum              = 0;

      if ($debug) {
        print "$Service->{TP_INFO_OLD}->{MONTH_FEE} ($Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) => $Service->{TP_INFO}->{MONTH_FEE} SHEDULE: $attr->{SHEDULER}\n";
      }

      if (($attr->{SHEDULER} && $conf{START_PERIOD_DAY} == $d)|| $Service->{TP_INFO_OLD}->{MONTH_FEE} == $Service->{TP_INFO}->{MONTH_FEE}) {
        if ($attr->{SHEDULER}) {
          undef $user;
        }
        return \%total_sum;
      }

      if ($users->{ACTIVATE} eq '0000-00-00') {
        if ($d != $conf{START_PERIOD_DAY}) {
          $rest_days     = $days_in_month - $d + 1;
          $rest_day_sum2 = (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) ? $Service->{TP_INFO_OLD}->{MONTH_FEE} /  $days_in_month * $rest_days : 0;
          $sum           = $rest_day_sum2;
          #PERIOD_ALIGNMENT
          $Service->{TP_INFO}->{PERIOD_ALIGNMENT}=1;
        }
        # Get back full month abon in 1 day of month 
        elsif (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) {
          $sum = $Service->{TP_INFO_OLD}->{MONTH_FEE}; 
        }
      }
      else {
        #If 
        if ( $attr->{SHEDULER} && date_diff($users->{ACTIVATE}, $DATE) >= 31 ) {
          if ($attr->{SHEDULER}) {
            undef $user;
          }
          
          return \%total_sum;
        }
        elsif (! $attr->{SHEDULER} && date_diff($users->{ACTIVATE}, $DATE) < 31) {
          $rest_days     = 30 - date_diff($users->{ACTIVATE}, $DATE);
          $rest_day_sum2 = (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) ? $Service->{TP_INFO_OLD}->{MONTH_FEE} /  30 * $rest_days : 0;
          $sum           = $rest_day_sum2;
        }
      }

      #Compensation
      if ($sum > 0) {
        $payments->add($users,
            {
             SUM      => abs($sum),
             METHOD   => 8,
             DESCRIBE => "$_TARIF_PLAN: $Service->{TP_INFO_OLD}->{NAME} ($Service->{TP_INFO_OLD}->{ID}) ($_DAYS: $rest_days)",
            }
        );

        if ($payments->{errno}) {
          _error_show($payments) if (!$attr->{QUITE});
        }
        else {
          $message .= "$_RECALCULATE\n$_RETURNED: ". sprintf("%.2f", abs($sum))."\n" if (!$attr->{QUITE});
        }
      }
    }

    my $sum   = $Service->{TP_INFO}->{MONTH_FEE} || 0;

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
      if ($attr->{SHEDULER}) {
        undef $user;
      }
      return \%total_sum;
    }

    if ($Service->{TP_INFO}->{PERIOD_ALIGNMENT} && !$Service->{TP_INFO}->{ABON_DISTRIBUTION}) {
      $FEES_DSC{EXTRA} = " $_MONTH_ALIGNMENT,";

      if ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        $days_in_month = ($active_m != 2 ? (($active_m % 2) ^ ($active_m > 7)) + 30 : (!($active_y % 400) || !($active_y % 4) && ($active_y % 25) ? 29 : 28));
        $d = $active_d;
      }

      my $calculation_days = ($d < $conf{START_PERIOD_DAY}) ? $conf{START_PERIOD_DAY} - $d : $days_in_month - $d + $conf{START_PERIOD_DAY};

      $sum = sprintf("%.2f", ($sum / $days_in_month) * $calculation_days);
    }

    if ($sum == 0) {
      if ($attr->{SHEDULER}) {
        undef $user;
      }

      return \%total_sum 
    }

    my $periods = 0;
    if (int($active_m) > 0 && int($active_m) < $m) {
      $periods = $m - $active_m;
      if (int($active_d) > int($d)) {
        $periods--;
      }
    }
    elsif (int($active_m) > 0 && (int($active_m) >= int($m) && int($active_y) < int($y))) {
      $periods = 12 - $active_m + $m;
      if (int($active_d) > int($d)) {
        $periods--;
      }
    }

    #Make reduction
    if ($users->{REDUCTION} && $users->{REDUCTION} > 0 && $Service->{TP_INFO}->{REDUCTION_FEE}) {
      $sum = $sum * (100 - $users->{REDUCTION}) / 100;
    }

    if ($Service->{TP_INFO}->{ABON_DISTRIBUTION}) {
      $sum = $sum / (($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28)));
      $FEES_DSC{EXTRA} = " - $_ABON_DISTRIBUTION";
    }

    if ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00' && ($Service->{OLD_STATUS} == 5)) {
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
        if ($users->{REDUCTION} > 0 && $Service->{TP_INFO}->{REDUCTION_FEE}) {
          $sum = $Service->{TP_INFO}->{MONTH_FEE} * (100 - $users->{REDUCTION}) / 100;
        }
        else {
          $sum = $Service->{TP_INFO}->{MONTH_FEE};
        }

        if ($Service->{ACCOUNT_ACTIVATE}) {
          $DATE          = $Service->{ACCOUNT_ACTIVATE};
          my $end_period = strftime('%Y-%m-%d', localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
          $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
          $users->change(
            $Service->{UID},
            {
              ACTIVATE => "$DATE",
              UID      => $Service->{UID}
            }
          );
          $Service->{ACCOUNT_ACTIVATE} = strftime('%Y-%m-%d', localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400)));
        }
        else {
          $DATE             = "$active_y-$m-01";
          $FEES_DSC{PERIOD} = "($active_y-$m-01-$active_y-$m-$days_in_month)";
        }
      }
      elsif ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        my $end_period = strftime('%Y-%m-%d', localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
        $Service->{ACCOUNT_ACTIVATE} = ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) ? undef : strftime('%Y-%m-%d', localtime((mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400)));

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
              ACTIVATE => ($conf{DV_CURDATE_ACTIVATE}) ? $DATE : $Service->{ACCOUNT_ACTIVATE}, #"$active_y-$m-$active_d",
              UID      => $Service->{UID}
            }
          );

          if ($conf{DV_CURDATE_ACTIVATE}) {
            ($active_y, $active_m, $active_d)=split(/-/, $DATE);
          } 
          else {
            ($active_y, $active_m, $active_d)=split(/-/, $Service->{ACCOUNT_ACTIVATE});
            $end_period = strftime('%Y-%m-%d', localtime((mktime(0, 0, 0, $active_d, ($active_m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
            $m = $active_m;
          }
        }
        else {
          $DATE = "$active_y-$m-$active_d";
        }

        $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
      }
      else {
        my $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28));
        my $start_date = ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) ? (($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') ? $Service->{ACCOUNT_ACTIVATE} : $DATE) : "$y-$m-01";
        $FEES_DSC{PERIOD} = ($Service->{TP_INFO}->{ABON_DISTRIBUTION}) ? '' : "($start_date-$y-$m-$days_in_month)";
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
          _error_show($fees) if (!$attr->{QUITE});
        }
        else {
          $html->message('info', $_INFO, $message. "\n $_SUM: ". sprintf("%.2f", $sum)) if ($html && !$attr->{QUITE});
        }
      }

      $m++;
    }
  }

  my $external_cmd = '_EXTERNAL_CMD';
  if ($service_name eq 'Internet') {
    $external_cmd = 'DV'.$external_cmd;
  }
  else {
    $external_cmd = uc($service_name).$external_cmd;
  }
  
  if ($conf{$external_cmd}) {
    if (!_external($conf{$external_cmd}, { %FORM, %$users, %$Service, %$attr })) {
      print "Error: external cmd '$conf{$external_cmd}'\n";
    }
  }
  
  #Undef ?
  if ($attr->{SHEDULER}) {
    undef $user;
  }

  return \%total_sum;
}


#**********************************************************
# form search link
#**********************************************************
sub search_link {
  my ($val, $attr) = @_;

  my $params = $attr->{PARAMS};
  my $ext_link = '';
  if ($attr->{VALUES}) {
    foreach my $k ( keys %{ $attr->{VALUES} } ) {
      $ext_link .= "&$k=$attr->{VALUES}->{$k}"; 
    }
  }
  else {
    $ext_link .=  '&'. "$params->[1]=". $val;
  }
  
  my $result = $html->button("$val", "index=". get_function_index($params->[0]) . "&search_form=1&search=1".$ext_link );

  return $result;
}

#**********************************************************
# result_former
#**********************************************************
sub result_row_former {
  my ($attr)=@_;

#Array result former
  my %PRE_SORT_HASH = ();

  my $main_arr = $attr->{ROWS};

  for( my $i=0; $i<=$#{ $main_arr }; $i++ ) {
    $PRE_SORT_HASH{$i}=$main_arr->[$i]->[$FORM{sort}-1];
  }

  my @sorted_ids = sort {
    if($FORM{desc}) {
      length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
      || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
    }
    else {
      length($PRE_SORT_HASH{$a}) <=> length($PRE_SORT_HASH{$b})
      || $PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b};
      #print "$PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b}<br>";
    }
  } keys %PRE_SORT_HASH;

  foreach my $line (@sorted_ids) {
     $attr->{table}->addrow(
      @{ $main_arr->[$line] },
    );
  }

  if ($attr->{TOTAL_SHOW}) {
    print $attr->{table}->show();
    
    $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'left',  ],
        rows       => [ [ "$_TOTAL:", $#{ $main_arr } + 1 ] ]
      }
    );

    print $table->show();
    return '';
  }


  return $attr->{table}->show();
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
    _error_show($data);

    $data->{list} = $list;
  }

  if ($data->{error}) {
    return undef, undef;
  }

  my @service_status_colors = ("$_COLORS[9]", "$_COLORS[6]", '#808080', '#0000FF', '#FF8000', '#009999');
  my @service_status        = ("$_ENABLE", "$_DISABLE", "$_NOT_ACTIVE", "$_HOLD_UP", 
  "$_DISABLE: $_NON_PAYMENT", "$ERR_SMALL_DEPOSIT",
  "$_VIRUS_ALERT" );

  if ($attr->{STATUS_VALS}) {
    @service_status = @{ $attr->{STATUS_VALS} };
  }

  my %SEARCH_TITLES = (
    #'disable'       => "$_STATUS",
    'login_status'  => "$_LOGIN $_STATUS",
    'deposit'       => "$_DEPOSIT",
    'credit'        => "$_CREDIT",
    'login'         => "$_LOGIN",
    'fio'           => "$_FIO",
    'last_payment'  => "$_LAST_PAYMENT",
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
    'group_name'    => "$_GROUP $_NAME",
#    'build_id'      => 'Location ID',
    'uid'           => 'UID',
  );

  if (in_array('Dv', \@MODULES)) {
    $SEARCH_TITLES{'dv_status'}="Internet $_STATUS";
  }

  if ($conf{EXT_BILL_ACCOUNT}) {
    $SEARCH_TITLES{'ext_deposit'}="$_EXTRA $_DEPOSIT";
  }
  
  my %ACTIVE_TITLES = ();
  
  if ($data->{EXTRA_FIELDS}) {
    foreach my $line (@{ $data->{EXTRA_FIELDS} }) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my ($position, $type, $name, $user_portal) = split(/:/, $line->[1]);
        if ($name =~ /\$/) {
          $SEARCH_TITLES{ $field_id } = _translate($name);
        }
        else {
          $SEARCH_TITLES{ $field_id } = $name;
        }
      }
    }
  }

  if ($attr->{SKIP_USER_TITLE}) {
    %SEARCH_TITLES = %{ $attr->{EXT_TITLES} };
  }
  elsif($attr->{EXT_TITLES}) {
    %SEARCH_TITLES = ( %SEARCH_TITLES, %{ $attr->{EXT_TITLES}} );
  }

  my $base_fields  = $attr->{BASE_FIELDS};
  my @EX_TITLE_ARR = @{ $data->{COL_NAMES_ARR} };
  my @title        = ();

  for (my $i = 0 ; $i < $base_fields+$data->{SEARCH_FIELDS_COUNT} ; $i++) {
    $title[$i]     = $SEARCH_TITLES{ $EX_TITLE_ARR[$i] } || $SEARCH_TITLES{$cols[$i]} || $EX_TITLE_ARR[$i] || $cols[$i] || "$_SEARCH";
    $ACTIVE_TITLES{$EX_TITLE_ARR[$i]} = $FORM{uc($EX_TITLE_ARR[$i])} || '_SHOW';
  }

  #data hash result former
  if(ref $attr->{DATAHASH} eq 'ARRAY') {
    @title = keys %{ $attr->{DATAHASH}->[0] };
  }
  #if ($#cols> $#title) {
  elsif (! $data->{COL_NAMES_ARR}){
    if ($attr->{BASE_PREFIX}) {
      @cols = (split(/,/, $attr->{BASE_PREFIX}), @cols);
    }

    for (my $i = 0 ; $i <= $#cols+$base_fields; $i++) {
      $title[$i]   = $SEARCH_TITLES{lc($cols[$i])} || $cols[$i];
      $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
    }
    
    if ($#cols> -1) {
      $title[$i]     = $cols[$i];
      $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
    }

    if (! $data->{COL_NAMES_ARR}) {
      $data->{COL_NAMES_ARR}=\@cols; #\@title 
    }
  }

  my @function_fields = split(/,\s?/, $attr->{FUNCTION_FIELDS} || '' );
  
  foreach my $function_fld_name ( @function_fields ) {
    $title[$#title+1]='-';
  }
  
  if ($attr->{TABLE} ) {
    my $table = $html->table(
      {
        #cols_align => [ 'left', 'left', 'right', 'right', 'left', 'center', 'center:noprint', 'center:noprint' ],
        %{ $attr->{TABLE} },
        title      => \@title,
        pages      => (! $attr->{SKIP_PAGES}) ? $data->{TOTAL} : undef,
        SHOW_COLS  => $attr->{TABLE}{SHOW_COLS} ? $attr->{TABLE}{SHOW_COLS} : \%SEARCH_TITLES,
        FIELDS_IDS => $data->{COL_NAMES_ARR},
        ACTIVE_COLS=> \%ACTIVE_TITLES,
      }
     );
    
    $table->{COL_NAMES_ARR} = $data->{COL_NAMES_ARR};
    
    if ($attr->{MAKE_ROWS} && $data->{list}) {
      foreach my $line (@{ $data->{list} }) {
        my @fields_array = ();
        for (my $i = 0 ; $i < $data->{SEARCH_FIELDS_COUNT}+$base_fields ; $i++) {
          my $val = '';
          if ($data->{COL_NAMES_ARR}->[$i] eq 'login' && $line->{uid} && defined(&user_ext_menu)) {
            $val = user_ext_menu($line->{uid}, $line->{login}, { EXT_PARAMS => ($attr->{MODULE} ? "MODULE=$attr->{MODULE}": undef) }); 
          }
          elsif($data->{COL_NAMES_ARR}->[$i] =~ /status$/) {
            $val = ($line->{$data->{COL_NAMES_ARR}->[$i]} > 0) ? $html->color_mark($service_status[ $line->{$data->{COL_NAMES_ARR}->[$i]} ], $service_status_colors[ $line->{$data->{COL_NAMES_ARR}->[$i]} ]) : "$service_status[$line->{$data->{COL_NAMES_ARR}->[$i]}]";
          }
          elsif($data->{COL_NAMES_ARR}->[$i] =~ /deposit/) {
            $val = ($permissions{0}{12}) ? '--' : ($line->{deposit} + $line->{credit} < 0) ? $html->color_mark($line->{deposit}, $_COLORS[6]) : $line->{deposit},
          }
          elsif($data->{COL_NAMES_ARR}->[$i] eq 'online') {
            $val = ($line->{online}) ? $html->color_mark('Online', '#00FF00') : '';
          }
          elsif ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$data->{COL_NAMES_ARR}->[$i]}) {
            $val = $attr->{SELECT_VALUE}->{$data->{COL_NAMES_ARR}->[$i]}->{$line->{$data->{COL_NAMES_ARR}->[$i]}};
          }
          #use filter to cols
          elsif ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$data->{COL_NAMES_ARR}->[$i]}) {
            my ($filter_fn, @arr)=split(/:/, $attr->{FILTER_COLS}->{$data->{COL_NAMES_ARR}->[$i]});

            my %p_values = ();
            if ($arr[1] =~ /,/) {
              foreach my $k ( split(/,/, $arr[1]) ) {
                if ($k =~ /(\S+)=(.*)/) {
                  $p_values{$1}=$2;
                }
                elsif (defined($line->{lc($k)})) {
                  $p_values{$k}=$line->{lc($k)};
                }
              }
            }
            
            $val = $filter_fn->($line->{$data->{COL_NAMES_ARR}->[$i]}, { PARAMS => \@arr, VALUES => \%p_values });
          }
          else {
            $val = $line->{ $data->{COL_NAMES_ARR}->[$i]  };
            my $brake = $html->br();
            $val =~ s/\n/$brake/g;
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
              push @fields_array, ($permissions{1}) ? $html->button($function_fields[$i], "UID=$line->{uid}&index=2", { class=>'payments' }) : '-';
            }
            elsif($function_fields[$i] =~ /stats/) {
              push @fields_array, $html->button($function_fields[$i], "UID=$line->{uid}&index=".get_function_index($function_fields[$i]), { class=>'stats' });
            }
            elsif($function_fields[$i] eq 'change') {
              push @fields_array, $html->button($_CHANGE, "index=$index&chg=$line->{id}". (($line->{uid} && $attr->{TABLE}{qs} !~ /UID=/) ? "&UID=$line->{uid}": undef). 
              ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}": undef).
              ($attr->{TABLE}{qs} ? $attr->{TABLE}{qs} : undef), 
              { class=>'change' });
            }
            elsif($function_fields[$i] eq 'company_id') {
              push @fields_array, $html->button($_CHANGE, "index=$index&COMPANY_ID=$line->{id}". (($line->{uid} && $attr->{TABLE}{qs} !~ /UID=/) ? "&UID=$line->{uid}": undef). 
              ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}": undef).
              ($attr->{TABLE}{qs} ? $attr->{TABLE}{qs} : undef), 
              { class=>'change' });
            }
            elsif($function_fields[$i] eq 'del') {
              push @fields_array, $html->button($_DEL, "&index=$index&del=$line->{id}". (($line->{uid} && $attr->{TABLE}{qs} !~ /UID=/)? "&UID=$line->{uid}": undef) . 
              ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}": undef) .
              ($attr->{TABLE}{qs} ? $attr->{TABLE}{qs} : undef), 
               { class=>'del', MESSAGE => "$_DEL $line->{id}?" });
            }
            else {
              my $qs = '';
              my $functiom_name = $function_fields[$i];
              my $button_name   = $function_fields[$i];
              my $param         = '';

              if ($function_fields[$i] =~ /(\S{0,25}):(\S+):(\S+)/) {
                $functiom_name = $1;
                $param         = $3;
                $button_name   = _translate($2);
                $qs           .= 'index='. (($functiom_name) ? get_function_index($functiom_name) : $index);
              }
              else {
                $qs = "index=".get_function_index($functiom_name);
              }
              
              if ($param && $line->{$param}) {
                $qs .= '&'.uc($param) ."=$line->{$param}";
              }
              elsif ($line->{uid}) {
                $qs .= "&UID=$line->{uid}";
              }

              push @fields_array, $html->button($button_name, $qs, { BUTTON => 1 });
            }
            
            if ($FORM{chg} && $line->{id} && $FORM{chg} == $line->{id}) {
              $table->{rowcolor}='bg-success';
            }
            else {
              $table->{rowcolor}=undef;
            }
          }
        }

        $table->addrow(@fields_array);
      }
    }
    elsif($attr->{DATAHASH}) {
      $data->{TOTAL}=0;
      $table->{sub_ref}=1;

      for(my $row_num=0; $row_num<= $#{ $attr->{DATAHASH} }; $row_num++) {
        my @row = ();
        my $line = $attr->{DATAHASH}->[$row_num];

        for(my $i=0; $i<=$#title; $i++) {
          #use filter to cols
          if ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$title[$i]}) {
            my ($filter_fn, @arr)=split(/:/, $attr->{FILTER_COLS}->{$title[$i]});
            push @row, $filter_fn->($line->{$title[$i]}, { PARAMS => \@arr });
          }
          else {          
            push @row, $line->{$title[$i]};
          }
        }

        $table->addrow( @row );
        $data->{TOTAL}++;
      }
    }

    if ($attr->{TOTAL}) {
      my $result = $table->show();
      if (! $admin->{MAX_ROWS}) {
        my @rows = ();
        
        if ($attr->{TOTAL} =~ /;/) {
          my @total_vals = split(/;/, $attr->{TOTAL});
          foreach my $line (@total_vals) {
            my ($val_id, $name)=split(/:/, $line);
            push @rows, [ $name, $html->b($data->{$val_id}) ];
          }
        }
        else {
          @rows = [ "$_TOTAL:", $html->b($data->{TOTAL}) ]
        }
        
        $table = $html->table(
          {
            width      => '100%',
            cols_align => [ 'right', 'right' ],
            rows       => \@rows
          }
        );
        $result .= $table->show();
      }

      if ($attr->{OUTPUT2RETURN}) {
        return $result, $data->{list};
      }
      else {
        print $result if (! $attr->{SEARCH_FORMER} || $data->{TOTAL} > 1);
      }
    }
    #else {
      return ($table, $data->{list});
    #}
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

#**********************************************************
# Make external operations
#**********************************************************
sub _external {
  my ($file, $attr) = @_;

  my $arguments = '';
  $attr->{LOGIN}      = $users->{LOGIN} || $attr->{LOGIN};
  $attr->{DEPOSIT}    = $users->{DEPOSIT};
  $attr->{CREDIT}     = $users->{CREDIT};
  $attr->{GID}        = $users->{GID};
  $attr->{COMPANY_ID} = $users->{COMPANY_ID};

  while (my ($k, $v) = each %$attr) {
    if ($k eq 'TABLE_SHOW') {
      
    }
    elsif ($k ne '__BUFFER' && $k =~ /[A-Z0-9_]/) {
      if ($v && $v ne '') {
        $arguments .= " $k=\"$v\"";  
      }
      else {
        $arguments .= " $k=\"\"";
      }
    }
  }

  #if (! -x $file) {
  #  $html->message('info', "_EXTERNAL $file", "$file not executable") if (!$attr->{QUITE});;
  #  return 0;
  #}

  my $result = `$file $arguments`;
  my $error = $!;
  my ($num, $message) = split(/:/, $result, 2);
  if ($num == 1) {
    $html->message('info', "_EXTERNAL $_ADDED", "$message") if (!$attr->{QUITE});;
    return 1;
  }
  else {
    $html->message('err', "_EXTERNAL $_ERROR", "[$num] $message $error"); # if (!$attr->{QUITE});;
    return 0;
  }
}


#**********************************************************
# get_fees_types
#
# return $Array_ref
#**********************************************************
sub get_fees_types {
  my ($attr) = @_;

  require Finance;
  Finance->import();

  my %FEES_METHODS = ();

  my $Fees         = Finance->fees($db, $admin, \%conf);
  my $list         = $Fees->fees_type_list({ PAGE_ROWS => 10000 });
  foreach my $line (@$list) {
    if ($FORM{METHOD} && $FORM{METHOD} == $line->[0]) {
      $FORM{SUM}      = $line->[3] if ($line->[3] > 0);
      $FORM{DESCRIBE} = $line->[2] if ($line->[2]);
    }

    $FEES_METHODS{ $line->[0] } = (($line->[1] =~ /\$/) ? _translate($line->[1]) : $line->[1]) . (($line->[3] > 0) ? (($attr->{SHORT}) ? ":$line->[3]" : " ($_SERVICE $_PRICE: $line->[3])") : '');
  }

  return \%FEES_METHODS;
}


#**********************************************************
# Make log file for paysys request
# mk_log(message, HASH_REF);
#   PAYSYS_ID -
#   REQUEST   -
#   REPLY     -
#   SHOW      - 
#**********************************************************
sub mk_log {
  my ($message, $attr) = @_;
  my $paysys = $attr->{PAYSYS_ID} || '';
  my $paysys_log_file = 'paysys_check.log';

  if (open(my $fh, ">>$paysys_log_file")) {
    if ($attr->{SHOW}) {
      print "$message";
    }
    
    print $fh "\n$DATE $TIME $ENV{REMOTE_ADDR} $paysys =========================\n";

    if ($attr->{REQUEST}) {
      print $fh "$attr->{REQUEST}\n=======\n";
    }

    print $fh $message;
    close($fh);
  }
  else {
    print "Content-Type: text/plain\n\n";
    print "Can't open log file '$paysys_log_file' $!\n";
    print "Error:\n";
    print "================\n$message================\n";
  }
}


#**********************************************************
#
#**********************************************************
sub get_payment_methods () {
  my ($attr) = @_;

  my %PAYMENTS_METHODS = ();

  my @PAYMENT_METHODS_ = @PAYMENT_METHODS;
  push @PAYMENT_METHODS_, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  for (my $i = 0 ; $i <= $#PAYMENT_METHODS_ ; $i++) {
    $PAYMENTS_METHODS{"$i"} = "$PAYMENT_METHODS_[$i]";
  }

  my %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

  while (my ($k, $v) = each %PAYSYS_PAYMENT_METHODS) {
    $PAYMENTS_METHODS{$k} = $v;
  }

  return \%PAYMENTS_METHODS;
}


#**********************************************************
#
# form_purchase_module($attr)
#**********************************************************
sub form_purchase_module {
  my ($attr) = @_;

  my $module = $attr->{MODULE};

  eval { require $module.'.pm'; };

  if (!$@) {
    $module->import();
    my $mod_version = $module."::VERSION";
    my $module_version = ${ $mod_version } || 0;

    if ($attr->{DEBUG}) {
      if ($attr->{HEADER}) {
         print "Content-Type: text/html\n\n";
      }
      print "Version: $module_version";
    }

    if ($attr->{REQUIRE_VERSION}) {
      if ($module_version < $attr->{REQUIRE_VERSION}) {
         if ($attr->{HEADER}) {
           print "Content-Type: text/html\n\n";
        }

        $html->message('info', "UPDATE", "Please update module '". $attr->{MODULE} . "' to version $attr->{REQUIRE_VERSION} or higher. http://abills.net.ua/");
        return 1;
      }
    }
  }
  else {
    if ($attr->{HEADER}) {
      print "Content-Type: text/html\n\n";
    }

    print "<div><p>модуль '$attr->{MODULE}' не установлен в системе, по вопросам приобретения модуля обратитесь к разработчику
    <a href='http://abills.net.ua' target=_newa>ABillS.net.ua</a>
    </p>
    <p>
    Purchase this module '$attr->{MODULE}'. </p>
    <p>
    For more information visit <a href='http://abills.net.ua' target=_newa>ABillS.net.ua</a>
    </p>
    </div>";

    if ($attr->{DEBUG}) {
      print "<p>";
      print $@;
      print "</p>";
    }

    return 1;
  }

  return 0;
}


#**********************************************************
# Check ip
#**********************************************************
sub check_ip {
  my ($require_ip, $ips) = @_;

  $ips =~ s/ //g;
  my $mask           = 0b0000000000000000000000000000001;
  my @ip_arr         = split(/,/, $ips);
  my $require_ip_num = ip2int($require_ip);

  foreach my $ip (@ip_arr) {
    if ($ip =~ /^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/) {
      if ($require_ip eq "$ip") {
        return 1;
      }
    }
    elsif ($ip =~ /^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d+)/) {
      $ip = $1;
      my $bit_mask = $2;
      my $first_ip = ip2int($ip);
      my $last_ip  = ip2int($ip) + sprintf("%d", $mask << (32 - $bit_mask));

      if ($require_ip_num >= $first_ip && $require_ip_num <= $last_ip) {
        return 1;
      }
    }
  }

  return 0;
}

#**********************************************************
#
#**********************************************************
sub _translate {
  my ($text) = @_;

  if ($text =~ /\"/) {
    return $text;
  }

  $text = eval "\"$text\"";

  return $text;
}

#**********************************************************
#
#**********************************************************
sub web_request {
 my ($request, $attr)=@_;

my $res;
my $host='';
my $port=80;
my $debug = $attr->{DEBUG} || 0;

if ($request =~ /^https/ || $attr->{CURL}) {
  my $CURL = $conf{FILE_CURL} || `which curl` || '/usr/local/bin/curl';
  chomp($CURL);
  my $result ='';
  my $request_url    = $request;
  my $request_params = '';
  my $curl_options   = $attr->{CURL_OPTIONS} || '';
  my $curl_file      = $CURL;

  if ($CURL =~ /(\S+)/) {
    $curl_file = $1;
  }

  if (! -f $curl_file) {
    print "'curl' not found. use \$conf{FILE_CURL}\n";
    return 0;
  }

  if ($attr->{AGENT}) {
    $curl_options .= qq{ -A "$attr->{AGENT}" };
  }

  my @request_params_arr = ();
  if ($attr->{REQUEST_PARAMS}) {
    foreach my $k ( keys %{ $attr->{REQUEST_PARAMS} } ) {
      next if (! $k || ! defined($attr->{REQUEST_PARAMS}->{$k}));
      $attr->{REQUEST_PARAMS}->{$k} =~ s/ /+/g;
      $attr->{REQUEST_PARAMS}->{$k} =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
      push @request_params_arr, "$k=$attr->{REQUEST_PARAMS}->{$k}";
    }
  }
  elsif($attr->{POST}) {
    @request_params_arr = ( $attr->{POST} );
  }

  if ($#request_params_arr > -1 ) {
    $request_params = join('&', @request_params_arr);
    if ($attr->{GET}) {
      $request_url .= "?". $request_params;
      $request_params = '';
    }
    else {
      $request_params = "-d \"$request_params\" ";
    }
  }

  $request_url    =~ s/ /%20/g;
  $request_url    =~ s/"/\\"/g;

  my $request_cmd =  qq{$CURL $curl_options -s "$request_url" $request_params };

  $result = `$request_cmd` if ($debug < 7);

  if ($debug) {
    print "<br>DEBUG: $debug COUNT:". (($attr->{REQUEST_COUNT}) ? $attr->{REQUEST_COUNT} : 0 )  ."=====REQUEST=====<br>\n";
    print "<textarea cols=90 rows=10>$request_cmd</textarea><br>\n";
    print "=====RESPONCE=====<br>\n";
    print "<textarea cols=90 rows=15>$result</textarea>\n";
  }

  if ($attr->{JSON_RETURN}) {
    my $json = $attr->{JSON_RETURN};
    my $perl_scalar = $json->decode( $result );

    if($perl_scalar->{status} && $perl_scalar->{status} eq 'error') {
      $self->{errno}=1;
      $self->{errstr}="$perl_scalar->{message}";
    }
  }

  return $result;
}

require Socket;
Socket->import();
require IO::Socket;
IO::Socket->import();
require IO::Select;
IO::Select->import();

$request =~ /http:\/\/([a-zA-Z.-]+)\/(.+)/;
$host    = $1; 
$request = '/'.$2;

if ($host =~ /:/) {
  ($host, $port)=split(/:/, $host, 2);
}

$request =~ s/ /%20/g;
$request = "GET $request HTTP/1.0\r\n";
$request .= ($attr->{'User-Agent'}) ? $attr->{'User-Agent'} : "User-Agent: Mozilla/4.0 (compatible; MSIE 5.5; Windows 98;Win 9x 4.90)\r\n"; 
$request .= "Accept: text/html, image/png, image/x-xbitmap, image/gif, image/jpeg, */*\r\n";
$request .= "Accept-Language: ru\r\n";
$request .= "Host: $host\r\n";
$request .= "Content-type: application/x-www-form-urlencoded\r\n";
$request .= "Referer: $attr->{'Referer'}\r\n" if ($attr->{'Referer'});
# $request .= "Connection: Keep-Alive\r\n";
$request .= "Cache-Control: no-cache\r\n";
$request .= "Accept-Encoding: *;q=0\r\n";
$request .= "\r\n";
 
print $request if ($attr->{debug});

my $timeout = defined($attr->{'TimeOut'}) ? $attr->{'TimeOut'} : 5;
my  $socket = new IO::Socket::INET(
        PeerAddr => $host,
        PeerPort => $port,
        Proto    => 'tcp',
        TimeOut  => $timeout
); # or log_print('LOG_DEBUG', "ERR: Can't connect to '$host:$port' $!");
  
if (! $socket) {
  return '';
}

$socket->send("$request");
  while(<$socket>) {
    $res .= $_;
  }
  my ($header, $content) = split(/\n\n/, $res); 
close($socket);

#print $header;
if ($header =~ /HTTP\/1.\d 302/ ) {
  $header =~ /Location: (.+)\r\n/;

  my $new_location = $1;
  if ($new_location !~ /^http:\/\//) {
    $new_location="http://$host".$new_location;
  }

  $res = web_request($new_location, { Referer => "$request" });
}

if ($res =~ /\<meta\s+http-equiv='Refresh'\s+content='\d;\sURL=(.+)'\>/ig) {
  my $new_location = $1;
  if ($new_location !~ /^http:\/\//) {
    $new_location="http://$host".$new_location;
  }

  $res = web_request($new_location, { Referer => "$new_location" });
}

if ($debug > 2) {
  print "<br>Plain request:<textarea cols=80 rows=8>$request\n\n$res</textarea><br>\n";  
}

if ($attr->{BODY_ONLY}) {
  (undef, $res)= split(/\r?\n\r?\n/, $res, 2);
}

  return $res;
}


#**********************************************************
#
#**********************************************************
sub snmp_get {
  my ($attr) = @_;
  my $value;

  $SNMP::Util::Max_log_level      = 'none'; 
  $SNMP_Session::suppress_warnings= 2;
  $SNMP_Session::errmsg = undef;

  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my ($snmp_community, $port)=split(/:/, $attr->{SNMP_COMMUNITY});

  if ($debug > 2) {
    print "$attr->{SNMP_COMMUNITY} -> $attr->{OID} <br>";
  }

  if ($debug > 5) {
    return '';
  }

  if ($attr->{WALK}) {
    my @value_arr = snmpwalk($snmp_community, $attr->{OID});
    $value = \@value_arr;
  }
  else {
    $value = snmpget($snmp_community, $attr->{OID});
  }
  
  if ($SNMP_Session::errmsg) {
    $html->message('err', $_ERROR, "OID: $attr->{OID}\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n");
  }
  
  return $value;
}


#**********************************************************
#
#**********************************************************
sub snmp_set {
  my ($attr) = @_;
  my $value;
  my $result = 1;

  $SNMP::Util::Max_log_level      = 'none'; 
  $SNMP_Session::suppress_warnings= 2;
  $SNMP_Session::errmsg = undef;

  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my ($snmp_community, $port)=split(/:/, $attr->{SNMP_COMMUNITY});

  my $info = '';
  for(my $i=0; $i<= $#{ $attr->{OID} }; $i+=3) {
    $info .= ' '. $attr->{OID}->[$i] .' '.$attr->{OID}->[$i+1] .' -> '.  $attr->{OID}->[$i+2]. "\n";
  }

  if ($debug > 2) {
    print "$attr->{SNMP_COMMUNITY} ->\n$info <br>";
  }

  if ($debug > 5) {
    return '';
  }

  if (! snmpset($snmp_community, @{ $attr->{OID} })) {
    print "Set Error: \n$info\n";
    $result = 0;
  }

  if ($SNMP_Session::errmsg) {
    my $message = "OID: $info\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n";
    if ($html) {
      $html->message('err', $_ERROR, $message);
    }
    else {
      print $message; 
    }
  }

  return $result;
}


1