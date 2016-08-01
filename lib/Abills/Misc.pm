
=head1 NAME

  Abills::Misc - ABillS misc functions

=cut

use strict;
no strict 'vars';
use warnings FATAL => 'all';
use Abills::Defs;
use Abills::Base qw(ip2int date_diff mk_unique_value convert in_array
  days_in_month startup_files cfg2hash urlencode cmd);
use Abills::Filters;
use POSIX qw(strftime mktime);
our $db;
our Abills::HTML $html;
our $admin;
our $base_dir;
our $added;
our %permissions;
our %menu_args;
our %module;
our %uf_menus;
our %DATA_HASH;
our %conf;
our %lang;
our %err_strs;

#our $user_pi;

#**********************************************************
=head2 load_pmodule($modulename, $attr); - Load perl module

  Arguments:
    $modulename   - Perl module name
    $attr
      IMPORT      - Function for import
      HEADER      - Add Content-Type header
      SHOW_RETURN - Result to return

  Returns:
    TRUE - Not loaded
    FALSE - Loaded

  Examples:

    load_pmodule('Simple::XML');

=cut
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
        " Install Perl Module <a href='http://abills.net.ua/wiki/doku.php/abills:docs:manual:soft:$name' target='_install'>$name</a> \n".
        " Main Page <a href='http://abills.net.ua/wiki/doku.php/abills:docs:other:ru?&#ustanovka_perl_modulej' target='_install'>Perl modules installation</a>\n".
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
=head2 load_module($modulename, $attr); - Load ABillS modules

  Arguments:
    $modulename   - Perl module name
    $attr         - Use $html
      IMPORT      - Make import
      LANG_ONLY   - Load language only
      HEADER      - Add Content-Type header
      SHOW_RETURN - Result to return
      language    - Language (Default: english)

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub load_module {
  my ($module, $attr) = @_;

  my $lang_file = '';
  $attr->{language} = 'english' if (! $attr->{language});

  foreach my $prefix ('../',@INC) {
    my $realfile_path = "$prefix/Abills/modules/$module/lng_";

    if (-f $realfile_path . $attr->{language}.'.pl') {
      if($attr->{language} ne 'english' && -f $realfile_path .'english.pl') {
         do $realfile_path .'english.pl';
      }
      $lang_file = $realfile_path . $attr->{language}.'.pl';
      last;
    }
    elsif (-f $realfile_path .'english.pl') {
      $lang_file = $realfile_path .'english.pl';
    }
  }

  if ($lang_file) {
    do $lang_file;
  }

  if ($attr->{CONFIG_ONLY}) {
    do "$module/config";
    return 1;
  }

  eval{ require "$module/webinterface" };

  if ($@) {
    print "Content-Type: text/html\n\n";
    print "Error: load module '$module'\n $!\n";
    print $@;

    print "INC: \n";
    print join(($html) ? $html->br() : "\n", @INC);
    if ($ENV{DEBUG}) {
      exit;
    }
    die;
  }

  return 1;
}

#**********************************************************
=head2 form_purchase_module($attr); - Load commercial modules

  Arguments:
    $attr
      MODULE          - Module name
      REQUIRE_VERSION - Required version
      HEADER          - Add Content-Type header
      SHOW_RETURN     - Result to return
      DEBUG           - Debug mode

=cut
#**********************************************************
sub form_purchase_module {
  my ($attr) = @_;

  my $module = $attr->{MODULE};

  eval { require $module.'.pm'; };

  if (!$@) {
    $module->import();
    my $module_version = $module->VERSION || 0;

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

        $html->message('err', "UPDATE", "Please update module '". $attr->{MODULE} . "' to version $attr->{REQUIRE_VERSION} or higher. http://abills.net.ua/ ($module_version)");
        return 1;
      }
    }
  }
  else {
    if ($attr->{HEADER}) {
      print "Content-Type: text/html\n\n";
    }

    print "<div class='alert alert-block alert-danger'><p>модуль '$attr->{MODULE}' не установлен в системе, по вопросам приобретения модуля обратитесь к разработчику
    <a href='http://abills.net.ua' target=_newa>ABillS.net.ua</a>
    </p>
    <p>
    Purchase this module '$attr->{MODULE}'. </p>
    <p>
    For more information visit <a href='http://abills.net.ua' target=_newa>ABillS.net.ua</a>
    </p>
    </div>";

    if ($attr->{DEBUG} || $FORM{DEBUG}) {
      print "<pre>\n";
      print $@;
      print "</pre>";
    }

    return 1;
  }

  return 0;
}

#**********************************************************
=head2 _error_show($modulename, $attr); - show functions errors

  Arguments:
    $modulename - Module object
    $attr       -
      MODULE_NAME  - Module name
      ID_PREFIX
      MESSAGE
      ERROR_IDS
      ID           - Error number
      SILENT_MODE  - Skip showin sql query for sql request

=cut
#**********************************************************
sub _error_show {
  my ($module, $attr)=@_;

  my $module_name = $attr->{MODULE_NAME} || $module->{MODULE} || '';
  #my $id_prefix   = $attr->{ID_PREFIX}  || '';
  my $message     = ($attr->{MESSAGE}) ?  "$attr->{MESSAGE}\n" :  '';

  if ($module->{errno}) {
    if ($attr->{ERROR_IDS}->{$module->{errno}}) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . $attr->{ERROR_IDS}->{$module->{errno}});
    }
    elsif ($module->{errno} == 15) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{ERR_SMALL_DEPOSIT}", $attr);
    }
    elsif ($module->{errno} == 7) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{EXIST}", $attr);
      return 1;
    }
    elsif ($module->{errno} == 10) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . " $lang{ERR_WRONG_NAME}", $attr);
      return 1;
    }
    elsif ($module->{errno} == 12) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . "$lang{ERR_WRONG_SUM}", $attr);
      return 1;
    }
    elsif ($module->{errno} == 699) {
      $html->message('err', "License $lang{ERROR}", "Update license ($module->{errstr})", { ID => '699' });
      return 1;
    }
    elsif ($module->{errno} == 14) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . "$lang{BILLS} $lang{NOT_EXIST}", $attr);
      return 1;
    }
    elsif ($module->{errno} == 2) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . "$lang{NOT_EXIST}", $attr);
      return 1;
    }
    elsif ($module->{errno} == 3) {
      $html->message('err', "$module_name:$lang{ERROR}", $message . "SQL Error: [$module->{errno}]\n",
        {
         EXTRA => ($attr->{SILENT_MODE}) ? " [$module->{sql_errno}] " . $module->{sql_errstr} : $html->tpl_show(templates('form_show_hide'),
         {
           CONTENT => "[$module->{sql_errno}] " . $module->{sql_errstr} . $html->br() . $html->br() . $html->pre($module->{sql_query}, { OUTPUT2RETURN => 1 }),
           NAME    => $lang{EXTRA},
           ID      => 'QUERIES',
          },
         { OUTPUT2RETURN => 1 })
        }
      );
      return 1;
    }
    else {
      my $error = ( $err_strs{$module->{errno}}) ?  $err_strs{$module->{errno}} : ($module->{errstr} || q{});
      $html->message('err', "$module_name:$lang{ERROR}", $message . "[$module->{errno}] $error", { ID => $attr->{ID} });
      return 1;
    }
  }

  return 0;
}

#**********************************************************
=head2 _function($index, $attr); - Exec function by index

  Arguments:
    $index         - Function index
    $attr
      IF_EXIST     - Run only if exists function
      ALL          - Show full log for errors
      DEBUG        - Debug mode

=cut
#**********************************************************
sub _function {
  my($index, $attr) = @_;

  if ($attr->{IF_EXIST} && $attr->{FN_NAME}) {
    my $fn = $attr->{FN_NAME};
    if (! defined(&{ $fn })) {
      return '';
    }

    return eval { &{ \&$fn }($attr) };
  }

  if ($FORM{qrcode}) {
    #eval { do "main/Qrcode.pm" };
    do "../../Abills/main/Qrcode.pm";
    qr_make( $SELF_URL, { PARAMS => \%FORM } );
    if (! $@){
      qr_make( $SELF_URL, { PARAMS => \%FORM } );
    }
    else {
      print $@;
    }
    return 1;
  }

  my $function_name = $functions{ $index } || '';
  if (! $function_name) {
    print "Content/type: text/html\n\n";
    print 'Function index: '. ($index || q{}) .' Function not exist!';
    return 0;
  }
  elsif(! defined( &{ $function_name } )) {
    print "Content/type: text/html\n\n";
    print "function: '". $function_name ."' defined in config but not exists\n\n";
    exit;
  }

  if($function_name eq 'null') {
    my @info_buttons = ();
    foreach my $key (sort keys %menu_items) {
      my $args_ =  $menu_args{$key} || q{};
      if($args_ && ! $FORM{$args_}) {
        next;
      }
      if (defined($menu_items{$key}{$index}) && $menu_items{$key}{$index} ne '' && $key != 10) {
        push @info_buttons, {
          ID     => mk_unique_value( 10 ),
          NUMBER => $html->button( $menu_items{$key}{$index}, "index=$key" ),
#          TEXT   => $html->button( $menu_items{$key}{$index}, "index=$key" ),
#            TEXT_COLOR => '#001a00',
#          COLOR  => '#AAAAAA',
          SIZE   => 4
        };
      }
    }

    $html->short_info_panels_row(\@info_buttons);
  }

  my $returns = eval { &{ \&$function_name }($attr) };

  if($@) {
    my $inputs = '';

    $attr->{ALL}=1;
    if ($attr->{ALL}) {
      $inputs = "\n========================\n";
      foreach my $key (sort keys %FORM) {
        next if ($key eq '__BUFFER');
        $inputs .= "$key -> ". ($FORM{$key} || '') ."\n";
      }
    }

    print "Content-Type: text/html\n\n";
    if(! $conf{SYS_ID}) {
      system_info();
    }
    my $sys_id = $conf{SYS_ID} || '';

    my $version = get_version();
    print << "[END]";
<form action='https://support.abills.net.ua/bugs.cgi' method='post'>
<input type=hidden name='FN_INDEX' value='$index'>
<input type=hidden name='FN_NAME' value='$function_name'>
<input type=hidden name='INPUTS' value='$inputs'>
<input type=hidden name='SYS_ID' value='$sys_id'>
<input type=hidden name='CUR_VERSION' value='$version'>

Critical Error:<br>
<textarea cols=120 rows=10 NAME=ERROR>
$@
$inputs
</textarea>
<br><input type=text name='COMMENTS' value='' placeholder='$lang{COMMENTS}' size=80>
<br>Notify after fix:<input type=checkbox name='NOTIFY' value=1>
<br><input type=text name='NOTIFY_EMAIL' value='' placeholder='E-mail' size=80>
<br><input type=submit name='add' value='Send to bug tracker' class='btn btn-danger'>
</form>
[END]

    die "Error functionm execute: '$function_name' $! // $@";
#    my $rr = `echo "$function_name" >> /tmp/fe`;
  }

  return $returns;
}

#**********************************************************
=head2 cross_modules_call($function_sufix, $attr); - Calls function for all registration modules if function exist

  Arguments:
    $function_sufix - Function sufix
    $attr           - Extra attributes
      SILENT       - silent mode without output (Default: enable)
      SKIP_MODULES - Skip modules
      timeout      - Max timeout for function execute
      DEBUG        - Debug mode
      USER_INFO    - User information hash
      HTML         - $html object

  Return:
    return all modules return hash

  Example:

    cross_modules_call('_payments_maked', {
        USER_INFO    => $user,
        SUM          => $sum,
        PAYMENT_ID   => $payments->{PAYMENT_ID},
        SKIP_MODULES => 'Paysys,Sqlcmd'
    });

=cut
#**********************************************************
sub cross_modules_call {
  my ($function_sufix, $attr) = @_;
  my $timeout = $attr->{timeout} || 3;

  if ($attr->{HTML}) {
    $html = $attr->{HTML};
  }

  if ($attr->{SUM} && ! $added) {
    $attr->{USER_INFO}->{DEPOSIT} += $attr->{SUM};
    $added=1;
  }

  #Default silent mode (off)
  our $silent;

  if (defined($attr->{SILENT})) {
    $silent=$attr->{SILENT};
  }

  if ($attr->{DEBUG}) {
    print "Function:  $function_sufix Timout: $timeout Silent: ". ($silent || 'no') ."<br>\n";
  }

  my %full_return  = ();
  my @skip_modules = ();
  my $SAVEOUT;
  my $output_redirect = ($conf{CROSS_MODULES_DEBUG}) ? $conf{CROSS_MODULES_DEBUG} : '/dev/null';

  eval {
    if ($silent) {
      #disable stdout output
      open($SAVEOUT, ">&", \*STDOUT) or die "Save STDOUT: $!";
      #Reset out
      open STDIN,  '>',  '/dev/null';
      open STDOUT, '>>', $output_redirect;
      open STDERR, '>>', $output_redirect;
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
        print " $mod -> ". lc($mod).$function_sufix ."<br>\n";
      }

      load_module($mod, $html);
      my $function = lc($mod) . $function_sufix;
      my $return;
      if (defined(&$function)) {
        $return = &{ \&$function }($attr);
      }

      $full_return{$mod} = $return;
    }
  };

  if ($silent) {
    # off disable stdout output
    open(STDOUT, ">&", $SAVEOUT);
  }

  if($@) {
    print "Error: \n";
    print $@;
  }

  return \%full_return;
}


#**********************************************************
=head2 get_function_index($function_name, $attr) - Get function index

  Arguments:
    $function_name   - Function name
    $attr
      ARGS   - Extra arguments
        empty - show only with empty argv

  Returns:
    function index

=cut
#**********************************************************
sub get_function_index {
  my ($function_name, $attr) = @_;
  my $function_index = 0;

  foreach my $k (keys %functions) {
    my $v = $functions{$k};

    if ($v eq "$function_name") {
      $function_index = $k;
      if ($attr->{ARGS} && defined($menu_args{$k})) {
        if ($attr->{ARGS} eq 'empty' && $menu_args{$k} eq '') {
        }
        elsif ($attr->{ARGS} ne $menu_args{$k}) {
          next;
        }
      }
      last;
    }
  }

  return $function_index || 0;
}


#**********************************************************
=head2 get_period_dates($attr) - Get period  intervals

  Arguments:
    $attr
      TYPE              0 - day, 1 - month
      START_DATE
      ACCOUNT_ACTIVATE
      PERIOD_ALIGNMENT

  Returns:
    Return string of period

=cut
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
          $end_date = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $start_d, ($start_m - 1), ($start_y - 1900), 0, 0, 0) + 30 * 86400)));
        }
      }

      return " ($start_date-$end_date)";
    }
  }

  return '';
}

#**********************************************************
=head2 fees_dsc_former($attr) - Make fees describe

  Arguments:
    $attr
      SERVICE_NAME  - Service name

=cut
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
=head2 service_get_month_fee($Service, $attr) - Make month feee

  Arguments:
    $Service - Module object
    $attr
      SERVICE_NAME - Service name
      DATE         - date of fees
      SHEDULER     - execute from sheduler
      EXT_DESCRIBE - Extra decribe
      QUITE        - Quite mode
      DEBUG

    Extra config option:

     $conf{DV_CURDATE_ACTIVATE}=1; - Activate non payment service by cur date

  Returns:
    total_sum
      Hash of results
         [ ACTIVATE  => 0 ]
         [ MONTH_FEE => 0 ]

=cut
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
      $html->message('err', $lang{ERROR}, "Can't load 'Bonus_rating'. Purchase this module http://abills.net.ua") if (!$attr->{QUITE});
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
            DESCRIBE => "$lang{BONUS}: $lang{TARIF_PLAN}: $Service->{TP_ID}",
          }
        );
        if ($payments->{errno}) {
          _error_show($payments) if (!$attr->{QUITE});
        }
        else {
          $html->message('info', $lang{INFO}, "$lang{BONUS}: $bonus_sum") if (!$attr->{QUITE});
        }
      }
    }
  }

  my %FEES_METHODS = %{ get_fees_types() };
  if (! $users->{BILL_ID}) {
    $user  = $users->info($Service->{UID});
  }
  #Get active price
  if ($Service->{TP_INFO}->{ACTIV_PRICE} && $Service->{TP_INFO}->{ACTIV_PRICE} > 0) {
    my $date  = ($user->{ACTIVATE} ne '0000-00-00') ? $user->{ACTIVATE} : $DATE;
    my $time  = ($user->{ACTIVATE} ne '0000-00-00') ? '00:00:00' : $TIME;

    if (!$Service->{OLD_STATUS} || $Service->{OLD_STATUS} == 2) {
      $fees->take(
        $users,
        $Service->{TP_INFO}->{ACTIV_PRICE},
        {
          DESCRIBE => '$lang{ACTIVATE_TARIF_PLAN}',
          DATE     => "$date $time"
        }
      );
      $total_sum{ACTIVATE} = $Service->{TP_INFO}->{ACTIV_PRICE};
      $html->message('info', $lang{INFO}, "$lang{ACTIVATE_TARIF_PLAN}") if ($html && ! $attr->{QUITE});
    }
  }

  my $message = '';
  #Current Month

  $DATE=$attr->{DATE} if ($attr->{DATE});

  my ($y, $m, $d)   = split(/-/, $DATE, 3);
  my $days_in_month = days_in_month({ DATE => $DATE });

  my $TIME = "00:00:00";
  my %FEES_PARAMS = (
              DATE   => "$DATE $TIME",
              METHOD => ($Service->{TP_INFO}->{FEES_METHOD}) ? $Service->{TP_INFO}->{FEES_METHOD} : 1
            );

  if($Service->{PERSONAL_TP} && $Service->{PERSONAL_TP} > 0) {
    $Service->{TP_INFO}->{MONTH_FEE}=$Service->{PERSONAL_TP};
  }

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
      my $sum           = 0;

      if ($debug) {
        print "$Service->{TP_INFO_OLD}->{MONTH_FEE} ($Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION}) => $Service->{TP_INFO}->{MONTH_FEE} SHEDULE: $attr->{SHEDULER}\n";
      }

      if (($attr->{SHEDULER} && $conf{START_PERIOD_DAY} == $d)
        || ($Service->{TP_INFO_OLD}->{MONTH_FEE} && $Service->{TP_INFO_OLD}->{MONTH_FEE} == $Service->{TP_INFO}->{MONTH_FEE})) {
        if ($attr->{SHEDULER}) {
          undef $user;
        }
        return \%total_sum;
      }

      if ($users->{ACTIVATE} eq '0000-00-00') {
        if ($d != $conf{START_PERIOD_DAY}) {
          $rest_days     = $days_in_month - $d + 1;
          $rest_day_sum2 = (! $Service->{TP_INFO_OLD}->{ABON_DISTRIBUTION} && $Service->{TP_INFO_OLD}->{MONTH_FEE}) ? $Service->{TP_INFO_OLD}->{MONTH_FEE} /  $days_in_month * $rest_days : 0;
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
             DESCRIBE => "$lang{TARIF_PLAN}: $Service->{TP_INFO_OLD}->{NAME} ($Service->{TP_INFO_OLD}->{ID}) ($lang{DAYS}: $rest_days)",
            }
        );

        if ($payments->{errno}) {
          _error_show($payments) if (!$attr->{QUITE});
        }
        else {
          $message .= "$lang{RECALCULATE}\n$lang{RETURNED}: ". sprintf("%.2f", abs($sum))."\n" if (!$attr->{QUITE});
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
              TP_NAME         => $Service->{TP_INFO}->{NAME} || '',
              FEES_PERIOD_DAY => $lang{MONTH_FEE_SHORT},
              FEES_METHOD     => ($Service->{TP_INFO}->{FEES_METHOD} && $FEES_METHODS{$Service->{TP_INFO}->{FEES_METHOD}}) ? $FEES_METHODS{$Service->{TP_INFO}->{FEES_METHOD}} : 0,
            );

    my ($active_y, $active_m, $active_d) = split(/-/, $Service->{ACCOUNT_ACTIVATE} || $users->{ACTIVATE}, 3);

    if (int("$y$m$d") < int("$active_y$active_m$active_d")) {
      if ($attr->{SHEDULER}) {
        undef $user;
      }

      return \%total_sum if (! $attr->{REGISTRATION} );
    }

    if ($Service->{TP_INFO}->{PERIOD_ALIGNMENT} && !$Service->{TP_INFO}->{ABON_DISTRIBUTION}) {
      $FEES_DSC{EXTRA} = " $lang{MONTH_ALIGNMENT},";

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
      $FEES_DSC{EXTRA} = " - $lang{ABON_DISTRIBUTION}";
    }

    if ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
      if ($Service->{OLD_STATUS} && $Service->{OLD_STATUS} == 5) {
        if ( $conf{DV_CURDATE_ACTIVATE} ){
          $periods = 0;
        }
        #if activation in cure month curmonth
        elsif ( $periods == 0 || ($periods == 1 && $d < $active_d) ){
          $periods = -1;
        }
        else{
          $periods -= 1;
        }
      }
      #Skip previe month calculations disable / hold up
      elsif( in_array($Service->{OLD_STATUS}, [1,3]) )  {
        $periods = 0;
      }
    }

    $m = $active_m if ($active_m > 0);

    for (my $i = 0 ; $i <= $periods ; $i++) {

      if ($m > 12) {
        $m        = 1;
        $active_y = $active_y + 1;
      }

      $m = sprintf("%.2d", $m);

      $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($active_y % 400) || !($active_y % 4) && ($active_y % 25) ? 29 : 28));
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
          my $end_period = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
          $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
          $users->change(
            $Service->{UID},
            {
              ACTIVATE => $DATE,
              UID      => $Service->{UID}
            }
          );
          $Service->{ACCOUNT_ACTIVATE} = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400)));
        }
        else {
          $DATE             = "$active_y-$m-01";
          $FEES_DSC{PERIOD} = "($active_y-$m-01-$active_y-$m-$days_in_month)";
        }
      }
      elsif ($Service->{ACCOUNT_ACTIVATE} && $Service->{ACCOUNT_ACTIVATE} ne '0000-00-00') {
        my $end_period = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
        $Service->{ACCOUNT_ACTIVATE} = ($Service->{TP_INFO}->{PERIOD_ALIGNMENT}) ? undef : POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $active_d, ($m - 1), ($active_y - 1900), 0, 0, 0) + 31 * 86400)));

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
        # old status "Too small deposit"
        elsif ($Service->{OLD_STATUS} && $Service->{OLD_STATUS} == 5) {
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
            $end_period = POSIX::strftime('%Y-%m-%d', localtime((POSIX::mktime(0, 0, 0, $active_d, ($active_m - 1), ($active_y - 1900), 0, 0, 0) + 30 * 86400)));
            $m = $active_m;
          }
        }
        else {
          $DATE = "$active_y-$m-$active_d";
          if( in_array($Service->{OLD_STATUS}, [1,3]) ) {
            $DATE = strftime("%Y-%m-%d", localtime(time));
            $users->change(
              $Service->{UID},
              {
                ACTIVATE => $DATE,
                UID      => $Service->{UID}
              }
            );
          }
        }

        $FEES_DSC{PERIOD} = "($active_y-$m-$active_d-$end_period)";
      }
      else {
        $days_in_month = ($m != 2 ? (($m % 2) ^ ($m > 7)) + 30 : (!($y % 400) || !($y % 4) && ($y % 25) ? 29 : 28));
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
          $html->message('info', $lang{INFO}, $message. "\n $lang{SUM}: ". sprintf("%.2f", $sum)) if ($html && !$attr->{QUITE});
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
=head2 search_link($val, $attr); - forming search link

  Arguments:
    $val  - Function name
    $attr -
      PARAMS
      VALUES
      LINK_NAME

  Returns:
    Link

=cut
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

  my $result = $html->button( $attr->{LINK_NAME} || $val , "index=". get_function_index($params->[0]) . "&search_form=1&search=1".$ext_link );

  return $result;
}

#**********************************************************
=head2 result_row_former($attr); - forming result from array_hash

  Arguments:
    $attr
      table - table object
      ROWS  - array_array
      ROW_COLORS - ref Array color

  Examples:

=cut
#**********************************************************
sub result_row_former {
  my ($attr)=@_;

#Array result former
  my %PRE_SORT_HASH = ();

  my $main_arr = $attr->{ROWS};
  my $ROW_COLORS = $attr->{ROW_COLORS};
  my $sort = $FORM{sort} || 1;
  for( my $i=0; $i<=$#{ $main_arr }; $i++ ) {
    $PRE_SORT_HASH{$i}=$main_arr->[$i]->[$sort-1];
  }

  my @sorted_ids = sort {
    if($FORM{desc}) {
      length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
      || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
    }
    else {
      length($PRE_SORT_HASH{$a} || 0) <=> length($PRE_SORT_HASH{$b} || 0)
      || ($PRE_SORT_HASH{$a} || q{}) cmp ($PRE_SORT_HASH{$b} || q{});
      #print "$PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b}<br>";
    }
  } keys %PRE_SORT_HASH;

  my Abills::HTML $table2 = $attr->{table};
  foreach my $line (@sorted_ids) {
    if($ROW_COLORS) {
      $table2->{rowcolor}=($ROW_COLORS->[$line]) ? $ROW_COLORS->[$line] : undef;
    }

    $table2->addrow(
      @{ $main_arr->[$line] },
    );
  }

  if ($attr->{TOTAL_SHOW}) {
    print $attr->{table}->show();

    my $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'left',  ],
        rows       => [ [ "$lang{TOTAL}:", $#{ $main_arr } + 1 ] ]
      }
    );

    print $table->show();
    return '';
  }

  return $attr->{table}->show();
}

#**********************************************************
=head2 result_former($attr) - Make result table from different source

  Arguments:
    $attr
      DEFAULT_FIELDS  - Default fields
      INPUT_DATA      - object
      FUNCTION        - object function name
      LIST            - get input date from list (array_hash)
      BASE_FIELDS     - count of default field for list

      DATAHASH        - get input date from json parse hash
      BASE_PREFIX     - Base prefix for data hash

      FUNCTION_FIELDS - function field forming
         change  - change field
         payment - payment field
         status  - status field
         del     - del field
      STATUS_VALS - Value for status fields (status,disable)
      EXT_TITLES  - Make extra title names and gum menu (hash)
        [ object_name => translate ]
      SKIP_USER_TITLE - don\'t show user titles in gum menu

      MAKE_ROWS   - Show result table
      MODULE      - Module name for user link
      FILTER_COLS - Use function filter for field
        filter_function:params:params:...
      SELECT_VALUE- Select value for field
      MULTISELECT - multiselect column
        [ id => value ]

      SKIP_PAGES  - Not show table pages
      TABLE       - Table information (HASH)
        width
        caption
        cols_align
        qs
        pages
        ID
        EXPORT
        MENU
      TOTAL         - Show table totals
      SHOW_MORE_THEN- Show table when rows more then SHOW_MORE_THEN

      MAP         - Make map result
      MAP_FIELDS  - Map fields
      MAP_ICON    - Icons for map points

      CHARTS      - Make charts. Columns coma delimeting for charts forming
      CHARTS_XTEXT- Charts x text

      OUTPUT2RETURN - Output to return

  Returns:
    ($table, $list)
    $table   - Table object
    $list    - result array list

  Examples:

=cut
#**********************************************************
sub result_former {
  my ($attr)=@_;

  my @cols = ();

  if ($FORM{MAP}) {
    if($attr->{MAP_FIELDS}) {
      $attr->{DEFAULT_FIELDS} = $attr->{MAP_FIELDS};
    }
    $LIST_PARAMS{'LOCATION_ID'}='_SHOW';
    $LIST_PARAMS{'PAGE_ROWS'}=1000001;
  }

  if($FORM{del_cols}) {
    $admin->settings_del($attr->{TABLE}->{ID});
    if ($attr->{DEFAULT_FIELDS}){
      $attr->{DEFAULT_FIELDS}=~s/[\n ]+//g;
      @cols = split(/,/, $attr->{DEFAULT_FIELDS});
    }
  }
  elsif ($FORM{show_columns}) {
    #print $FORM{del_cols};
    @cols = split(/,\s?/, $FORM{show_columns});
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
      if ($admin->{SETTING}){
        @cols = split( /, /, $admin->{SETTING} );
      }
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

    if (! $data) {
      print "No input objects data\n";
      return 0;
    }

    delete($data->{COL_NAMES_ARR});
    my $list = $data->$fn({ COLS_NAME => 1, %LIST_PARAMS, SHOW_COLUMNS => $FORM{show_columns} });
    _error_show($data);

    $data->{list} = $list;
  }
  elsif($attr->{LIST}) {
    $data->{list} = $attr->{LIST};
  }

  if ($data->{error}) {
    return;
  }

  #Make maps
  if($attr->{MAP} && ( ! $attr->{SHOW_MORE_THEN} || $data->{TOTAL} > $attr->{SHOW_MORE_THEN} )) {
    my @header_arr = ("$lang{MAIN}:index=$index".$attr->{TABLE}->{qs},
                      "$lang{MAP}:index=$index&&MAP=1".$attr->{TABLE}->{qs}
                     );
    print $html->table_header(\@header_arr, { TABS => 1 });

    if($FORM{MAP}) {
      if(in_array('Maps', \@MODULES)) {
        load_module('Maps', $html);

        my %USERS_INFO = ();
        foreach my $line (@{ $data->{list} }) {
          next unless ($line->{build_id} || $line->{location_id});
          push @{ $USERS_INFO{ $line->{build_id} || $line->{location_id} } }, $line;
        }

        maps_show_poins({ DATA                  => \%USERS_INFO,
                          MAP_FILTERS           => $attr->{MAP_FILTERS},
                          LOCATION_TABLE_FIELDS => $attr->{MAP_FIELDS},
                          POINT_TYPE            => $attr->{MAP_ICON},
                        });
        return -1, -1;
      }
    }
  }

  my @service_status_colors = ("#000000", "#FF0000", '#808080', '#0000FF', '#FF8000', '#009999');
  my @service_status        = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}", "$lang{HOLD_UP}",
    "$lang{DISABLE}: $lang{NON_PAYMENT}", "$lang{ERR_SMALL_DEPOSIT}",
    "$lang{VIRUS_ALERT}" );

  if ($attr->{STATUS_VALS}) {
    @service_status = @{ $attr->{STATUS_VALS} };
  }

  my %SEARCH_TITLES = (
    #'disable'       => "$lang{STATUS}",
    'login_status'  => "$lang{LOGIN} $lang{STATUS}",
    'deposit'       => "$lang{DEPOSIT}",
    'credit'        => "$lang{CREDIT}",
    'login'         => "$lang{LOGIN}",
    'fio'           => "$lang{FIO}",
    'last_payment'  => "$lang{LAST_PAYMENT}",
    'email'         => 'E-Mail',
    'pasport_date'  => "$lang{PASPORT} $lang{DATE}",
    'pasport_num'   => "$lang{PASPORT} $lang{NUM}",
    'pasport_grant' => "$lang{PASPORT} $lang{GRANT}",
    'contract_id'   => "$lang{CONTRACT_ID}",
    'contract_date' => "$lang{CONTRACT} $lang{DATE}",
    'registration'  => "$lang{REGISTRATION}",
    'phone'         => "$lang{PHONE}",
    'comments'      => "$lang{COMMENTS}",
    'company_id'    => "$lang{COMPANY} ID",
    'bill_id'       => "$lang{BILLS}",
    'activate'      => "$lang{ACTIVATE}",
    'expire'        => "$lang{EXPIRE}",
    'credit_date'   => "$lang{CREDIT} $lang{DATE}",
    'reduction'     => "$lang{REDUCTION}",
    'domain_id'     => 'DOMAIN ID',

    'district_name' => "$lang{DISTRICTS}",
    'address_full'  => "$lang{FULL} $lang{ADDRESS}",
    'address_street'=> "$lang{ADDRESS_STREET}",
    'address_build' => "$lang{ADDRESS_BUILD}",
    'address_flat'  => "$lang{ADDRESS_FLAT}",
    'address_street2'=> $lang{SECOND_NAME},
    'city'          => "$lang{CITY}",
    'zip'           => "$lang{ZIP}",

    'deleted'       => "$lang{DELETED}",
    'gid'           => "$lang{GROUP}",
    'group_name'    => "$lang{GROUP} $lang{NAME}",
#    'build_id'      => 'Location ID',
    'uid'           => 'UID',
  );


  if ($conf{ACCEPT_RULES}) {
    $SEARCH_TITLES{accept_rules}=$lang{ACCEPT_RULES};
  }
#  if (in_array('Dv', \@MODULES)) {
#    $SEARCH_TITLES{'dv_status'}="Internet $lang{STATUS}";
#  }

  if ($conf{EXT_BILL_ACCOUNT}) {
    $SEARCH_TITLES{'ext_deposit'}="$lang{EXTRA} $lang{DEPOSIT}";
  }

  my %ACTIVE_TITLES = ();

  if ($data->{EXTRA_FIELDS}) {
    foreach my $line (@{ $data->{EXTRA_FIELDS} }) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my (undef, undef, $name, undef) = split(/:/, $line->[1]);
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

  my $base_fields  = $attr->{BASE_FIELDS} || 0;
  my @EX_TITLE_ARR = ();
  if ($data->{COL_NAMES_ARR} && ref $data->{COL_NAMES_ARR} eq 'ARRAY'){
    @EX_TITLE_ARR = @{ $data->{COL_NAMES_ARR} };
  }
  my @title        = ();
  my $search_fields_count = $data->{SEARCH_FIELDS_COUNT} || 0;
  for (my $i = 0 ; $i < $base_fields+$search_fields_count ; $i++) {
    $title[$i]     = ($EX_TITLE_ARR[$i] && $SEARCH_TITLES{ $EX_TITLE_ARR[$i] }) || ($cols[$i] && $SEARCH_TITLES{$cols[$i]}) || $EX_TITLE_ARR[$i] || $cols[$i] || "$lang{SEARCH}";
    $ACTIVE_TITLES{($EX_TITLE_ARR[$i] || '')} = ($EX_TITLE_ARR[$i] && $FORM{uc($EX_TITLE_ARR[$i])}) || '_SHOW';
  }

  #data hash result former
  if(ref $attr->{DATAHASH} eq 'ARRAY') {
    @title = sort keys %{ $attr->{DATAHASH}->[0] };
    $data->{COL_NAMES_ARR} = \@title;
    @EX_TITLE_ARR = @title;
  }
  #if ($#cols> $#title) {
  elsif (! $data->{COL_NAMES_ARR}){
    if ($attr->{BASE_PREFIX}) {
      @cols = (split(/,/, $attr->{BASE_PREFIX}), @cols);
    }

    my $i = 0;
    for ($i = 0 ; $i <= $#cols+$base_fields; $i++) {
      if ($cols[$i]){
        $title[$i] = $SEARCH_TITLES{lc( $cols[$i] )} || $attr->{TABLE}->{SHOW_COLS}->{$cols[$i]} || $cols[$i];
        $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
      }
      else {
        $title[$i] = q{};
        $ACTIVE_TITLES{q{}} = q{};
      }
    }

    if ($#cols> -1) {
      $title[$i]     = $cols[$i];
      if ($cols[$i]){
        $ACTIVE_TITLES{$cols[$i]} = $cols[$i];
      }
    }

    if (! $data->{COL_NAMES_ARR}) {
      $data->{COL_NAMES_ARR}=\@cols; #\@title
    }
  }

  my @function_fields = split(/,\s?/, $attr->{FUNCTION_FIELDS} || '' );

  for(my $i=1; $i<=$#function_fields; $i++ ) {
    $title[$#title+$i]='-';
  }
  if ($attr->{TABLE} ) {

#    if ($attr->{TABLE}{SHOW_COLS} &&  $attr->{TABLE}{SHOW_COLS} eq 'clean') {
#      %SEARCH_TITLES = undef;
#      delete($attr->{TABLE}{SHOW_COLS});
#    }
    my $table = $html->table(
      {
        #cols_align => [ 'left', 'left', 'right', 'right', 'left', 'center', 'center:noprint', 'center:noprint' ],
        SHOW_COLS  => ($attr->{TABLE}{SHOW_COLS}) ? $attr->{TABLE}{SHOW_COLS} : \%SEARCH_TITLES,
        %{ $attr->{TABLE} },
        title      => \@title,
        pages      => (! $attr->{SKIP_PAGES}) ? $data->{TOTAL} : undef,
        FIELDS_IDS => $data->{COL_NAMES_ARR},
        ACTIVE_COLS=> \%ACTIVE_TITLES,
      }
     );

    $table->{COL_NAMES_ARR} = $data->{COL_NAMES_ARR};

    if ($attr->{MAKE_ROWS} && $data->{list}) {
      my $brake = $html->br();
      my $chart_num   = 0;

      if ( ref $data->{list} ne 'ARRAY' ){
        print "<br></hr> ERROR: " . q{ ref $data->{list} ne 'ARRAY' };
        return 0;
      }

      foreach my $line (@{ $data->{list} }) {
        my @fields_array = ();

        for (my $i = 0 ; $i < $base_fields + $search_fields_count ; $i++) {
          my $val       = '';
          my $cols_name = $data->{COL_NAMES_ARR}->[$i] || '';

          if ($cols_name eq 'login' && $line->{uid} && defined(&user_ext_menu)) {
            if (! $FORM{EXPORT_CONTENT}) {
              $val = user_ext_menu($line->{uid}, $line->{login}, { EXT_PARAMS => ($attr->{MODULE} ? "MODULE=$attr->{MODULE}": undef) });
            }
            else {
              $val = $line->{login};
            }
          }
          elsif($cols_name =~ /status$/ && (! $attr->{SELECT_VALUE} || ! $attr->{SELECT_VALUE}->{$cols_name})) {
            $val = ($line->{$cols_name} && $line->{$cols_name} > 0) ? $html->color_mark($service_status[ $line->{$cols_name} ], $service_status_colors[ $line->{$cols_name} ]) :
                ( defined $line->{$cols_name} ? $service_status[$line->{$cols_name}] : '');
          }
          elsif($cols_name =~ /deposit/) {
            $val = ($permissions{0}{12}) ? '--' : (($line->{deposit} || 0) + ($line->{credit} || 0) < 0) ? $html->color_mark($line->{deposit}, $_COLORS[6]) : $line->{deposit},
          }
          elsif($cols_name eq 'deleted') {
            $val = ($line->{deleted}) ? $html->color_mark($lang{DELETED}, 'text-danger') : '';
          }
          elsif($cols_name eq 'online') {
            $val = ($line->{online}) ? $html->color_mark('Online', '#00FF00') : '';
          }
          #use filter to cols
          elsif ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$cols_name}) {
            my ($filter_fn, @arr)=split(/:/, $attr->{FILTER_COLS}->{$cols_name});

            my %p_values = ();
            if ($arr[1] && $arr[1] =~ /,/) {
              foreach my $k ( split(/,/, $arr[1]) ) {
                if ($k =~ /(\S+)=(.*)/) {
                  $p_values{$1}=$2;
                }
                elsif (defined($line->{lc($k)})) {
                  $p_values{$k}=$line->{lc($k)};
                }
              }
            }

            $val = &{ \&$filter_fn }($line->{$cols_name}, { PARAMS => \@arr,
                                                            VALUES => \%p_values,
                                                            LINK_NAME => ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$cols_name}) ?
                                                                          $attr->{SELECT_VALUE}->{$cols_name}->{$line->{$cols_name}} : undef
                                                                        });
          }
          elsif ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$cols_name}) {
            my($value, $color) = split(/:/, $attr->{SELECT_VALUE}->{$cols_name}->{$line->{$cols_name}} || '');

            if($value && $color) {
              $value = $html->color_mark($value, $color);
            }

            $val = $value || $line->{$cols_name};
          }
          else {
            $val = $line->{ $cols_name  } || '';
            $val =~ s/\n/$brake/g;
          }

          if ($i==0 && $attr->{MULTISELECT}) {
            my($id, $value) = split(/:/, $attr->{MULTISELECT});
            my @multiselect_arr = ();
            if($FORM{$id}) {
              @multiselect_arr=split(/,\s?|;\s?/, $FORM{$id});
            }
            #$val = $html->form_input($id, $line->{$value}, { TYPE => 'checkbox' }) . ' '. $val;
            @fields_array = ($html->form_input($id, $line->{$value}, { TYPE => 'checkbox', STATE => in_array($line->{$value}, \@multiselect_arr) }), @fields_array);
          }

          push @fields_array, $val;
        }

        if($#function_fields > -1) {
          push @fields_array, @{ table_function_fields(\@function_fields, $line, $attr) };

          if ($FORM{chg} && $line->{id} && $FORM{chg} == $line->{id}) {
            $table->{rowcolor}='bg-success';
          }
          else {
            $table->{rowcolor}=undef;
          }
        }

        #make charts
        if($attr->{CHARTS}) {
          my @charts = split(/,\s?/, $attr->{CHARTS});
          if($line->{date}) {
            my (undef, undef, $dd)=split(/-/, $line->{date});
            #$CHARTS{PERIOD}=1 if (!$CHARTS{PERIOD});
            #$num = ($CHARTS{PERIOD}) ? $dd : $dd + 1;
            $chart_num = $dd || 0;
          }
          else {
            $chart_num++;
            if ($attr->{CHARTS_XTEXT}) {
              #$CHARTS{X_LINE}[$num-1] = $line->{$attr->{CHARTS_XTEXT}};
              if ($attr->{CHARTS_XTEXT} eq 'auto') {
                $attr->{CHARTS_XTEXT} = $data->{COL_NAMES_ARR}->[0];
              }

              $CHARTS{X_TEXT}[$chart_num-1] = ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$attr->{CHARTS_XTEXT}}) ?
                                           ($attr->{SELECT_VALUE}->{ $attr->{CHARTS_XTEXT} }->{ $line->{$attr->{CHARTS_XTEXT}} } || $line->{$attr->{CHARTS_XTEXT}}) : $line->{$attr->{CHARTS_XTEXT}};
            }
          }

          foreach my $c_val (@charts) {
            $DATA_HASH{$c_val}[$chart_num-1]=$line->{$c_val} || 0;
            $CHARTS{X_TEXT}[$chart_num-1] = $chart_num if (! $CHARTS{X_TEXT}[$chart_num-1]);
          }
        }

        $table->addrow(@fields_array);
      }
    }
    #Datahash
    elsif($attr->{DATAHASH} && ref $attr->{DATAHASH} eq 'ARRAY') {
      $data->{TOTAL}=0;
      $table->{sub_ref}=1;

      my %PRE_SORT_HASH = ();
      my $sort = $FORM{sort} || 1;
      for( my $i=0; $i<=$#{ $attr->{DATAHASH} }; $i++ ) {
        #if($EX_TITLE_ARR[$sort - 1]){
          $PRE_SORT_HASH{$i}=$attr->{DATAHASH}->[$i]->{ $EX_TITLE_ARR[$sort - 1] || q{} };
        #}
        #else {
        #  $PRE_SORT_HASH{$i}='';
        #}
      }

      my @sorted_ids = sort {
        if($FORM{desc}) {
          length($PRE_SORT_HASH{$b}) <=> length($PRE_SORT_HASH{$a})
          || $PRE_SORT_HASH{$b} cmp $PRE_SORT_HASH{$a};
        }
        else {
          length($PRE_SORT_HASH{$a}) <=> length($PRE_SORT_HASH{$b})
          || $PRE_SORT_HASH{$a} cmp $PRE_SORT_HASH{$b};
        }
      } keys %PRE_SORT_HASH;

      foreach my $row_num (@sorted_ids) {
        my @row = ();
        my $line = $attr->{DATAHASH}->[$row_num];

        for(my $i=0; $i<=$#EX_TITLE_ARR; $i++) {
          #use filter to cols
          my $field_name = $EX_TITLE_ARR[$i];
          my $col_data   = $line->{$field_name};
          if ($attr->{FILTER_COLS} && $attr->{FILTER_COLS}->{$field_name}) {
            my ($filter_fn, @arr)=split(/:/, $attr->{FILTER_COLS}->{$field_name});
            push @row, &{ \&$filter_fn }($col_data, { PARAMS => \@arr });
          }
          elsif ($attr->{SELECT_VALUE} && $attr->{SELECT_VALUE}->{$field_name}) {
            if($attr->{SELECT_VALUE}->{$field_name}->{$col_data}) {
              my($value, $color) = split(/:/, $attr->{SELECT_VALUE}->{$field_name}->{$col_data});
              push @row,  ($color) ? $html->color_mark($value, $color) : $value;
            }
            else {
              Encode::_utf8_off($col_data);
              push @row,  $col_data;
            }
          }
          elsif( ref $col_data eq 'ARRAY' ) {
            my $val = $col_data;
            my $col_values = '';
            foreach my $v (@$val) {
              if (ref $v eq 'HASH') {
                while (my ($k, $v2) = each %$v) {
                  Encode::_utf8_off($k);
                  Encode::_utf8_off($v2);
                  $col_values .= ' '. $html->b($k) ." - $v2" . $html->br();
                }
              }
              else {
                Encode::_utf8_off($v);
                $col_values .= $v . $html->br();
              }
            }
            push @row, $col_values;
          }
          elsif (ref $col_data eq 'HASH') {
            my $val = '';
            foreach my $key (sort keys %{ $col_data }) {
              my $val_ = $col_data->{$key} || q{};
              Encode::_utf8_off($val_);
              $val .= $html->b($key) .' : '. $val_ . $html->br();
            }
            push @row, $val;
          }
          else {
            Encode::_utf8_off($col_data);
            push @row, $col_data || q{};
          }
        }

        if($#function_fields > -1) {
          push @row, @{ table_function_fields(\@function_fields, $line, $attr) };
        }
        $table->addrow( @row );
        $data->{TOTAL}++;
      }
    }

    if ($attr->{TOTAL} && ( ! $attr->{SHOW_MORE_THEN} || $data->{TOTAL} > $attr->{SHOW_MORE_THEN} )) {
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
          @rows = [ "$lang{TOTAL}:", $html->b($data->{TOTAL}) ]
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
        if (! $attr->{SEARCH_FORMER} || (defined($data->{TOTAL}) && $data->{TOTAL} > -1)) {
          print $result || q{};
        }
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
=head2 table_function_fields($function_fields, $line, $attr) - Make function fields

  Attributes:
    $function_fields - Function fields name (array_ref)
      form_payments
      stats
      change
      cpmpany_id
      ex_info
      del
    $line            - erray_ref of list result
    $attr            - Extra attributes
      TABLE          - Table object hash_ref
      MODULE         - Module name

  Result:
    Arrya_ref of cols

=cut
#**********************************************************
sub table_function_fields {
  my ($function_fields, $line, $attr) = @_;

  my @fields_array = ();

  for (my $i = 0 ; $i <= $#{ $function_fields } ; $i++) {
    if ($function_fields->[$i] eq 'form_payments') {
      return [] if (!$line->{uid});
      push @fields_array, ($permissions{1}) ? $html->button($function_fields->[$i], "UID=$line->{uid}&index=2", { class => 'payments' }) : '-';
    }
    elsif ($function_fields->[$i] =~ /stats/) {
      push @fields_array, $html->button($function_fields->[$i],
        (($line->{uid}) ? "UID=$line->{uid}" : q{} ) ."&index=" . get_function_index($function_fields->[$i]), { class => 'stats' });
    }
    elsif ($function_fields->[$i] eq 'change') {
      push @fields_array, $html->button($lang{CHANGE}, "index=$index&chg=". ($line->{id} || q{})
          . (($line->{uid} && $attr->{TABLE} && $attr->{TABLE}{qs} && $attr->{TABLE}{qs} !~ /UID=/) ? "&UID=$line->{uid}" : '')
          . (($attr->{MODULE}) ? "&MODULE=$attr->{MODULE}" : '')
          . (($attr->{TABLE} && $attr->{TABLE}{qs}) ? $attr->{TABLE}{qs} : ''), { class => 'change' });
    }
    elsif ($function_fields->[$i] eq 'company_id') {
      push @fields_array,
      $html->button($lang{CHANGE}, "index=$index&COMPANY_ID=$line->{id}"
          . (($line->{uid} && $attr->{TABLE} && $attr->{TABLE}{qs} !~ /UID=/) ? "&UID=$line->{uid}" : '')
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
          . ($attr->{TABLE} && $attr->{TABLE}{qs} ? $attr->{TABLE}{qs} : ''), { class => 'change' });
    }
    elsif (in_array('Info', \@MODULES) && $function_fields->[$i] eq 'ex_info') {
      $html->button($lang{CHANGE}, "index=$index&COMPANY_ID=$line->{id}"
          . (($line->{uid} && $attr->{TABLE} && $attr->{TABLE}{qs} !~ /UID=/) ? "&UID=$line->{uid}" : undef)
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : undef)
          . ($attr->{TABLE} && $attr->{TABLE}{qs} ? $attr->{TABLE}{qs} : undef), { class => 'change' });
    }
    elsif ($function_fields->[$i] eq 'del') {
      push @fields_array,
      $html->button($lang{DEL},  "&index=$index&del=". ((exists $line->{id}) ? $line->{id} : '')
          . (($line->{uid} && $attr->{TABLE}{qs} !~ /UID=/) ? "&UID=$line->{uid}" : '')
          . ($attr->{MODULE} ? "&MODULE=$attr->{MODULE}" : '')
          . ((exists $attr->{TABLE} && $attr->{TABLE}{qs}) ? $attr->{TABLE}{qs} : ''),
        { class => 'del', MESSAGE => "$lang{DEL} ". ($line->{id} || q{-}) ."?" }
      );
    }
    else {
      my $qs            = '';
      my $functiom_name = $function_fields->[$i];
      my $button_name   = $function_fields->[$i];
      my $param         = '';
      my $ex_param      = '';

      my %button_params = ();

      if ($function_fields->[$i] =~ /([a-z0-0\_\-]{0,25}):([a-zA-Z\_0-9\{\}\$]+):([a-z0-9\-\_\;]+):?(\S{0,100})/) {
        $functiom_name = $1;
        $param         = $3;
        $ex_param      = $4;

        my $name = $2;
        if($name eq 'del') {
          $button_params{class}   = 'del';
          $button_params{MESSAGE} = "$lang{DEL} ";
        }
        elsif($name eq 'change') {
          $button_params{class}='change';
        }
        elsif($name eq 'add') {
          $button_params{class}='add';
        }
        else {
          $button_params{BUTTON}=1;
          $button_name   = _translate($name);
        }

        $qs .= 'index=' . (($functiom_name) ? get_function_index($functiom_name) : $index);
        $qs .= $ex_param;
      }
      else {
        $qs = "index=" . get_function_index($functiom_name);
      }

      if ($param) {
        foreach my $l (split(/;/, $param)) {
          if ( $line->{$l} ) {
            $qs .= '&' . uc($l) . "=$line->{$l}";
          }
        }
      }
      elsif ($line->{uid}) {
        $qs .= "&UID=$line->{uid}";
      }

      push @fields_array, $html->button($button_name, $qs, \%button_params);
    }
  }

  return \@fields_array;
}


#**********************************************************
#
#**********************************************************
sub dirname {
  my ($x) = @_;
  if ($x !~ s@[/\\][^/\\]+$@@) {
    $x = '.';
  }

  return $x;
}

#**********************************************************
=head2 load_pmodule($file, $attr); - Make external operations

  Arguments:
    $file     - File for executions
    $attr     - Extra arguments

  Returns:
    1 - Susccess
    0 - Error

=cut
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
  if ($num && $num == 1) {
    $html->message('info', "_EXTERNAL $lang{ADDED}", "$message") if (!$attr->{QUITE});;
    return 1;
  }
  else {
    $html->message('err', "_EXTERNAL $lang{ERROR}", "[". ($num || '') ."] ". ($message || q{}) ." $error"); # if (!$attr->{QUITE});;
    return 0;
  }
}


#**********************************************************
=head2 get_fees_types($attr)

   Arguments:
     $attr

   Returns:
     \%FEES_METHODS

=cut
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
      $FORM{SUM}      = $line->[3] if ($line->[3] && $line->[3] > 0);
      $FORM{DESCRIBE} = $line->[2] if ($line->[2]);
    }
    my $sum_show = ($line->[3] && $line->[3] > 0) ? ($attr->{SHORT}) ? ":$line->[3]" : " ($lang{SERVICE} $lang{PRICE}: $line->[3])" : q{};

    $FEES_METHODS{ $line->[0] } = (($line->[1] && $line->[1] =~ /\$/) ? _translate($line->[1]) : ($line->[1] || '')) . $sum_show;
  }

  return \%FEES_METHODS;
}


#**********************************************************
=head2 get_payment_methods($attr)

  Arguments:
    $attr
      EXTRA_METHODS = Coma separated string

  Returns:
    \%PAYMENTS_METHODS

=cut
#**********************************************************
sub get_payment_methods {
  my ($attr) = @_;

  #Base methods
  my @PAYMENT_METHODS = ("$lang{CASH}", "$lang{BANK}", "$lang{EXTERNAL_PAYMENTS}", 'Credit Card', "$lang{BONUS}",
    "$lang{CORRECTION}", "$lang{COMPENSATION}",
    "$lang{MONEY_TRANSFER}", "$lang{RECALCULATE}");

  my %PAYMENTS_METHODS = ();

  my @PAYMENT_METHODS_ = @PAYMENT_METHODS;
  push @PAYMENT_METHODS_, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  for (my $i = 0 ; $i <= $#PAYMENT_METHODS_ ; $i++) {
    $PAYMENTS_METHODS{$i} = $PAYMENT_METHODS_[$i];
  }

  my %PAYSYS_PAYMENT_METHODS = ();
  if ($attr->{EXTRA_METHODS}) {
    %PAYSYS_PAYMENT_METHODS = %{ cfg2hash( $attr->{EXTRA_METHODS} ) };
  }
  else {
    %PAYSYS_PAYMENT_METHODS = %{ cfg2hash( $conf{PAYSYS_PAYMENTS_METHODS} ) };
  }

  while (my ($k, $v) = each %PAYSYS_PAYMENT_METHODS) {
    $PAYMENTS_METHODS{$k} = $v;
  }

  return \%PAYMENTS_METHODS;
}


#**********************************************************
=head2 check_ip($require_ip, $ips) - Check ip

  Arguments:
    $require_ip - Required IP
    $ips        - IP list commas separated

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub check_ip {
  my ($require_ip, $ips) = @_;

  if(! $require_ip) {
    return 0;
  }

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
=head2 _translate($text) - translate string

  Arguments:
    $text   - text for translate
  Returns:
      translated string

=cut
#**********************************************************
sub _translate {
  my ($text) = @_;

  return '' unless $text;

  if ( $text =~ /\"/ ){
    return $text;
  }
  #elsif($text =~ /\$lang\{(\S+)\}/) {
  else {
    while($text =~ /\$lang\{(\S+)\}/g) {
      my $marker = $1;
      if($lang{$marker}) {
        $text =~ s/\$lang\{$marker\}/$lang{$marker}/;
      }
    }
  }

  while( $text =~ m/\$\_?([A-Z0-9\_]+)/g ) {
    my $text_marker = $1;
    if ($lang{$text_marker}) {
      $text =~ s/\$\_?$text_marker/$lang{$text_marker}/g;
    }
  }

  #my $sub_text = $1;
#  if ($text =~ s/\$\_(\S+)/$lang{$1}/){
#    #$text = $lang{$sub_text};
#    #print $text;
#  }
#  else {
#    $text = eval "\"$text\"";
#  }

  return $text || q{};
}

#**********************************************************
=head2 web_request($request, $attr); - make web request

  Arguments:
    $request        - request URL
    $attr           - Attributes
      REQUEST_PARAMS - Request params hash
        [Param name] => [ value ]
      REQUEST_PARAMS_JSON - Request params hash converted to json request string
        [Param name] => [ value ]
      POST           - POST string (When not specified REQUEST_PARAMS)
      GET            - GET request mode
      JSON_RETURN    - agregate result as JSON, return JSON hash result
      AGENT          - Agent info
      CURL_OPTIONS   - curl options
      HEADERS        - curl -H option (ARRAY_ref)
      BIN_DATA       - Send data througth file
      COOKIE         - Use cookies
      TIMEOUT        - Request timeout (Default: 30 sec)
      DEBUG          - Debug mode
      DEBUG2FILE     - Write debug to file

  Returns:
      result string
      or
      hash on JSON_RETURN mode

=cut
#**********************************************************
sub web_request {
  my ($request, $attr) = @_;

  my $res;
  my $host = '';
  my $port = 80;
  my $debug = $attr->{DEBUG} || 0;

  my @request_params_arr = ();
  if ($attr->{REQUEST_PARAMS}) {
    foreach my $k (keys %{ $attr->{REQUEST_PARAMS} }) {
      next if (!$k || !defined($attr->{REQUEST_PARAMS}->{$k}));
      if (ref $attr->{REQUEST_PARAMS}->{$k} eq 'ARRAY') {
        foreach my $val (@{ $attr->{REQUEST_PARAMS}->{$k} }) {
          $val = urlencode($val);
          push @request_params_arr, "$k=$val";
        }
      }
      else {
        $attr->{REQUEST_PARAMS}->{$k} = urlencode($attr->{REQUEST_PARAMS}->{$k});
        push @request_params_arr, "$k=$attr->{REQUEST_PARAMS}->{$k}";
      }
    }
  }

  if ($request =~ /^https/ || $attr->{CURL}) {
    my $CURL = $attr->{FILE_CURL} || $conf{FILE_CURL} || `which curl` || '/usr/local/bin/curl';
    chomp($CURL);
    my $result = '';
    my $request_url = $request;
    my $request_params = '';
    my $curl_options = $attr->{CURL_OPTIONS} || '';
    my $curl_file = $CURL;

    if ($CURL =~ /(\S+)/) {
      $curl_file = $1;
    }

    if (!-f $curl_file) {
      print "'curl' not found. use \$conf{FILE_CURL}\n";
      return 0;
    }

    if ($attr->{AGENT}) {
      $curl_options .= qq{ -A "$attr->{AGENT}" };
    }

    if ($attr->{HEADERS}) {
      foreach my $key (@{ $attr->{HEADERS} }) {
        $curl_options .= qq{ -H "$key" };
      }
    }

    if ($attr->{COOKIE}) {
      my $cookie_file = '/tmp/cookie.';
      $curl_options .= qq{ --cookie $cookie_file --cookie-jar $cookie_file };
    }

    if ($attr->{BIN_DATA}) {
      if ($attr->{TPL_DIR}) {
        $conf{TPL_DIR} = $attr->{TPL_DIR};
      }

      my $ret = file_op({ FILENAME => "$conf{TPL_DIR}/tmp_.bin",
          PATH                     => "$conf{TPL_DIR}",
          WRITE                    => 1,
          CONTENT                  => $attr->{BIN_DATA}
        });

      if (!$ret) {
        print "Can't open file $conf{TPL_DIR}/tmp_.bin \n";
      }

      $curl_options .= " --data \"\@$conf{TPL_DIR}/tmp_.bin\"";
    }

    if ($attr->{REQUEST_PARAMS_JSON}) {
      foreach my $k (keys %{ $attr->{REQUEST_PARAMS_JSON} }) {
        next if (!$k || !defined($attr->{REQUEST_PARAMS_JSON}->{$k}));
        if (ref $attr->{REQUEST_PARAMS_JSON}->{$k} eq 'ARRAY') {
          foreach my $val (@{ $attr->{REQUEST_PARAMS_JSON}->{$k} }) {
            $val = urlencode($val);
            push @request_params_arr, qq{ \\\"$k\\\" : \\\"$val\\\" };
          }
        }
        else {
          $attr->{REQUEST_PARAMS}->{$k} = urlencode($attr->{REQUEST_PARAMS_JSON}->{$k});
          push @request_params_arr, qq{ \\\"$k\\\" : \\\"$attr->{REQUEST_PARAMS_JSON}->{$k}\\\" };
        }
      }

      $request_params = '-d "{'.join(',', @request_params_arr).'}"';

      @request_params_arr = ();
    }
    elsif ($attr->{POST}) {
      @request_params_arr = ( $attr->{POST} );
    }

    if ($#request_params_arr > -1) {
      $request_params = join('&', @request_params_arr);
      if ($attr->{GET}) {
        $request_url .= "?".$request_params;
        $request_params = '';
      }
      #POST request string
      else {
        $request_params = "-d \"$request_params\" ";
      }
    }

    $request_url =~ s/ /%20/g;
    $request_url =~ s/"/\\"/g;
    $request_url =~ s/\`/\\\`/g;

    my $request_cmd = qq{$CURL $curl_options -s "$request_url" $request_params };

    #$result = `$request_cmd` if ($debug < 7);
    $result = cmd($request_cmd, { timeout => defined($attr->{'TIMEOUT'}) ? $attr->{'TIMEOUT'} : 30 }) if ($debug < 7);

    if ($? != 0) {
      $result = 'Timeout '.$?;
    }

    if ($debug) {
      my $request_ = (($attr->{REQUEST_COUNT}) ? $attr->{REQUEST_COUNT} : 0 );
      if($attr->{DEBUG2FILE}) {
        if(open(my $fh, '>>', $attr->{DEBUG2FILE})) {
          print $fh "===============================\n";
          print $fh "($request_) " . $request_cmd ."\n";
          print $fh "$result\n";
          close($fh);
        }
      }
      else {
        print "<br>DEBUG: $debug COUNT:".$request_."=====REQUEST=====<br>\n";
        print "<textarea cols=90 rows=10>$request_cmd</textarea><br>\n";
        print "=====RESPONCE=====<br>\n";
        print "<textarea cols=90 rows=15>$result</textarea>\n";
      }
    }

    if ($attr->{CLEAR_COOKIE}) {
      unlink "/tmp/cookie.";
    }

    if ($result eq 'Timeout') {
      return $result;
    }

    if ($attr->{JSON_RETURN} && $result) {
      my $json = $attr->{JSON_RETURN};
      if ($json == 1) {
        load_pmodule('JSON');
        $json = JSON->new->allow_nonref;
      }

      my $perl_scalar;

      eval { $perl_scalar = $json->decode( $result );  };

      #Syntax oerror
      if ($@) {
        $perl_scalar->{errno} = 2;
        $perl_scalar->{errstr} = $@;
      }
      #Else other error
      elsif (ref $perl_scalar eq 'HASH' && $perl_scalar->{status} && $perl_scalar->{status} eq 'error') {
        $perl_scalar->{errno} = 1;
        $perl_scalar->{errstr} = "$perl_scalar->{message}";
      }

      return $perl_scalar;
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
  $request = '/'.($2 || '');

  if ($host =~ /:/) {
    ($host, $port) = split(/:/, $host, 2);
  }

  if ( $#request_params_arr > -1) {
    $request .= '?' . join('&', @request_params_arr);
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

  my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'tcp',
    TimeOut  => defined($attr->{'TIMEOUT'}) ? $attr->{'TIMEOUT'} : 5
  ); # or log_print('LOG_DEBUG', "ERR: Can't connect to '$host:$port' $!");

  if (!$socket) {
    return '';
  }

  $socket->send( "$request" );
  while(<$socket>) {
    $res .= $_;
  }
  close($socket);

  # my ($header, $content)
  my ($header) = split(/\n\n/, $res);

  #print $header;
  if ($header =~ /HTTP\/1.\d 302/) {
    $header =~ /Location: (.+)\r\n/;

    my $new_location = $1;
    if ($new_location !~ /^http:\/\//) {
      $new_location = "http://$host".$new_location;
    }

    $res = web_request($new_location, { Referer => "$request" });
  }

  if ($res =~ /\<meta\s+http-equiv='Refresh'\s+content='\d;\sURL=(.+)'\>/ig) {
    my $new_location = $1;
    if ($new_location !~ /^http:\/\//) {
      $new_location = "http://$host".$new_location;
    }

    $res = web_request($new_location, { Referer => "$new_location" });
  }

  if ($debug > 2) {
    print "<br>Plain request:<textarea cols=80 rows=8>$request\n\n$res</textarea><br>\n";
  }

  if ($attr->{BODY_ONLY}) {
    (undef, $res) = split(/\r?\n\r?\n/, $res, 2);
  }

  return $res;
}


#**********************************************************
=head2 snmp_get($attr); - Set SNMP value

  Arguments:
    $attr
      SNMP_COMMUNITY
      OID             - oid
      WALK            - walk mode
      SILENT          - DOn't generate exception
      DEBUG
  Returns:
      result string
      ot result array for WALK mode
=cut
#**********************************************************
sub snmp_get {
  my ($attr) = @_;
  my $value;

  #$SNMP_util::Max_log_level      = 'none';
  $SNMP_Session::suppress_warnings= 2;
  $SNMP_Session::errmsg           = undef;

  my $debug = 0;
  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my ($snmp_community, $port)=split(/:/, $attr->{SNMP_COMMUNITY});
  $snmp_community.=':'.$port if ($port && ! in_array($port, [ 22, 1700, 3977 ]));

  if ($debug > 2) {
    print "$attr->{SNMP_COMMUNITY} -> $attr->{OID} <br>";
  }

  if ($debug > 5) {
    return '';
  }

  if ($attr->{WALK}) {
    my $timeout   = $attr->{TIMEOUT} || 0;
    my @value_arr = ();

    eval {
      local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required

      if ($timeout) {
        alarm $timeout;
      }

      @value_arr = SNMP_util::snmpwalk($snmp_community, $attr->{OID});
      alarm 0;
    };

    if ($@) {
      die unless $@ eq "alarm\n";                  # propagate unexpected errors
      print "timed out ($timeout): $attr->{OID}\n";
    }
    else {
      print "NO errors\n" if ($debug>2);
    }

    $value = \@value_arr;
  }
  else {
    $value = SNMP_util::snmpget($snmp_community, $attr->{OID});
  }

  if ($SNMP_Session::errmsg) {
    $html->message('err', $lang{ERROR}, "OID: $attr->{OID}\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n");
  }

  return $value;
}


#**********************************************************
=head2 snmp_set($attr); - Set SNMP value

  Arguments:
    $attr
      SNMP_COMMUNITY  - {community_name}@{ip_address}[:port]
      OID             - array ( OID, type, value, OID, type, value, ...)
      DEBUG

=cut
#**********************************************************
sub snmp_set {
  my ($attr) = @_;
  #my $value;
  my $result = 1;

  #$SNMP::Util::Max_log_level      = 'none';
  $SNMP_Session::suppress_warnings= 2;
  $SNMP_Session::errmsg = undef;
  my $debug = 0;
  if ($attr->{DEBUG}) {
    $debug = $attr->{DEBUG};
  }

  my ($snmp_community, $port)=split(/:/, $attr->{SNMP_COMMUNITY});
  $snmp_community.=':'.$port if ($port && ! in_array($port, [ 22, 1700, 3977 ]));

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

  if (! SNMP_util::snmpset($snmp_community, @{ $attr->{OID} })) {
    print "Set Error: \n$info\n";
    $result = 0;
  }

  if ($SNMP_Session::errmsg) {
    my $message = "OID: $info\n\n $SNMP_Session::errmsg\n\n$SNMP_Session::suppress_warnings\n";
    if ($html) {
      $html->message('err', $lang{ERROR}, $message);
    }
    else {
      print $message;
    }
  }

  return $result;
}

#**********************************************************
=head2 get_oui_info($mac); - Get MAC information
  Arguments:
    $mac - mac

  Returns:
    vendor string
=cut
#**********************************************************
sub get_oui_info {
  my ($mac) = @_;

  my $result = '';
  $mac =~ s/[\-:\.]//g;
  $mac = uc($mac);
  $mac =~ /^([0-9A-F]{6})/;
  my $mac_prefix = $1;

  my $content = '';
  open(my $fh, '<', "$base_dir/misc/oui.txt") or die "Can't open file 'oui.txt' $!";
    while(<$fh>) {
      $content .= $_;
    }
  close($fh);

  my @content_arr = split(/\n\n/, $content);
  my %vendors_hash = ();
  foreach my $section (@content_arr) {
    my @rows = split(/\n/, $section);
    if ($#rows > 0){
      $rows[1] =~ /([A-F0-9]{6})\s+\(base 16\)\s+(.+)/;
      $vendors_hash{$1} = $2;
    }
  }

  $result = $vendors_hash{$mac_prefix} || '';

  return $result;
}

#**********************************************************
=head2 host_diagnostic($ip, $attr); - Diagnostic host activity

  Diagnostic methods:
    ping (Default)
  Arguments:
    IP      - IP address of host
    QUITE   - Quite mode
    TIMEOUT - Timeout
    $attr   -
  Return:
    Active or disable  (TRUE or FALSE)

=cut
#**********************************************************
sub host_diagnostic {
  my($ip, $attr) = @_;
  #my $timeout  = $attr->{TIMEOUT} || 3;

  if ($ip && $ip =~ /^$IPV4$/){
    my $pathes = startup_files( { TPL_DIR => $conf{TPL_DIR} } );
    my $PING = $pathes->{PING} || 'ping';

    my $res = cmd( "$PING -c 5 $ip" );
    if ( !$attr->{QUITE} ){
      $html->message( 'info', $lang{INFO}, "$PING -c 5 $ip\nResult:\n" .
        $html->pre( $res, { OUTPUT2RETURN => 1 } ) );
    }

    if($attr->{RETURN_RESULT}){
      return $res ne '' ? 1 : 0;
    }
  }
  else {
    $html->message('err', $lang{ERROR}, "$lang{WRONG_DATA} '". (($ip) ? $ip : '') . "' ($IPV4)");
  }

  return 1;
}

#**********************************************************
=head2 file_op($attr) File operations

  Secure file operation function, with warnings

  Arguments:

    FILENAME   - Filename
    PATH       - File folder (Default path $conf{TPL_DIR})
    WRITE      - Enable write mode (Default: 0 - read mode)
    CREATE     - Create file if not exists skip if exists
    CONTENT    - file content for writing
    SKIP_CHECK - Skip checking file exist for read mode
    ROWS       - After reading return array of rows for text file only

  Returns:
    File content for reading
    TRUE OR FALSE for wrinting

  Examples:

open image file and print content

    print file_op({ FILENAME => "$conf{TPL_DIR}/if_image/image_file.jpg",
                    PATH     => "$conf{TPL_DIR}/if_image"
    });

=cut
#**********************************************************
sub file_op {
  my ($attr) = @_;
  my $content = '';

  my $filename = $attr->{FILENAME} || 'unknown';
  my $path     = $attr->{PATH} || '';
  #my $write    = $attr->{WRITE} || '';

  if (! $path) {
    $path=$filename;
    if ($path !~ s@[/\\][^/\\]+$@@) {
      $path = '.';
    }

    if ($path eq $conf{TPL_DIR}) {
      $filename =~ s/$path\/?//;
    }
  }
  else {
    $filename =~ s/$path\/?//;
  }
  if ($filename !~ /^([-\@\w\.]{0,12}\/?[-\@\w\.]+)$/) {
    $html->message('err', $lang{ERROR}, "Security error '$filename'.\n");
    return 0;
  }

  $filename = $path .'/'. $filename;

  if ($attr->{WRITE}) {
    if ($attr->{CREATE} && -f $filename) {
      $html->message('err', $lang{ERROR}, "$lang{EXIST} '$filename' \n $!");
      return 0;
    }

    $content = $attr->{CONTENT} || '';
    if (open(my $fh, '>', "$filename")) {
      print $fh $content;
      close($fh);
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} '$filename'") if ($html);
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't open file '$filename'\n $!") if ($html);
      return 0;
    }
  }
  else {
    if (! -f $filename) {
      if (! $attr->{SKIP_CHECK}) {
        $html->message('err', $lang{ERROR}, "$lang{NOT_EXIST} '$filename' \n $!");
      }
    }
    elsif (open(my $fh, '<', "$filename")) {
      while (<$fh>) {
        $content .= $_;
      }
      close($fh);

      if ($attr->{ROWS}) {
        my @rows = split(/[\r\n]+/, $content);
        return \@rows;
      }
    }
    else {
      $html->message('err', $lang{ERROR}, "Can't open file '$filename' $!");
      return ;
    }
  }

  return $content;
}

#**********************************************************
=head2 upload_file($file, $attr) - Upload file to server

  Attributes:
    $file      - HTML file field object
    $attr      - Attributes
       PREFIX                   - Upload folder (Defauls: $conf{TPL_DIR})
       SAFE_FILENAME_CHARACTERS - Check file symbols
       FILE_NAME                - Filename for saving
       EXTENTIONS               - Allow extensions (String - comma separated)
       REWRITE                  - Allow rewrite file

  Retursn:
    TRUE or FALSE

  Examples:
    upload_file($FORM{FILENAME});

=cut
#**********************************************************
sub upload_file {
  my ($file, $attr) = @_;

  my $safe_filename_characters = ($attr->{SAFE_FILENAME_CHARACTERS}) ? $attr->{SAFE_FILENAME_CHARACTERS} : "a-zA-Z0-9_.-";
  my $file_name = ($attr->{FILE_NAME}) ? $attr->{FILE_NAME} : $file->{filename};

  if(! $file_name) {
    $html->message('err', $lang{ERROR}, "Select upload file");
    return 0;
  }

  $file_name =~ tr/ /_/;
  $file_name =~ s/[^$safe_filename_characters]//g;

  if ($attr->{EXTENTIONS}) {
    my @ext_arr = split(/,\s?/, $attr->{EXTENTIONS});
    if ($file_name =~ /\.([a-z0-9\_]+)$/i) {
      my $file_extension = $1;
      if (! in_array($file_extension, \@ext_arr)) {
        $html->message('err', $lang{ERROR}, "$lang{ERROR} Wrong extension\n $lang{FILE}: '$file_name'");
        return 0;
      }
    }
    else {
      $html->message('err', $lang{ERROR}, "$lang{ERROR} Wrong filename\n $lang{FILE}: '$file_name'");
      return 0;
    }
  }

  my $dir = ($attr->{PREFIX}) ? "$conf{TPL_DIR}/" . $attr->{PREFIX} : $conf{TPL_DIR};

  if (!-d $dir) {
    if(! mkdir($dir)) {
      $html->message('err', $lang{ERROR}, "$lang{ERROR} '$dir'  '$!'");
      return 0;
    }
  }

  if (!$attr->{REWRITE} && -f "$dir/$file_name") {
    $html->message('err', $lang{ERROR}, "$lang{EXIST} '$file_name'");
  }
  elsif (open( my $fh, '>', "$dir/$file_name")) {
    binmode $fh;
    print $fh $file->{Contents};
    close($fh);
    $html->message('info', $lang{INFO}, "$lang{ADDED}: '$file_name' $lang{SIZE}: $file->{Size}");
  }
  else {
    $html->message('err', $lang{ERROR}, "$lang{ERROR} '$dir/$file_name'  '$!'");
    return 0;
  }

  return 1;
}

#**********************************************************
=head2 sel_groups($attr) - show select user group

  Attributes:
    $attr
      GID
      HASH_RESULT     - Return results as hash
      SKIP_MUULTISEL  - Skip multiselect

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_groups {
  my ($attr) = @_;

  my $GROUPS_SEL = '';
  if ($admin->{GID} && $admin->{GID} !~ /,/) {
    $users->group_info($admin->{GID});
    $GROUPS_SEL = "$admin->{GID}:$users->{NAME}";
    $GROUPS_SEL .= $html->form_input('GID', $admin->{GID}, { TYPE => 'hidden' });
  }
  elsif($attr->{HASH_RESULT}) {
    my %group_hash = ();
    my $list = $users->groups_list({ GIDS => ($admin->{GID}) ? $admin->{GID} : undef, COLS_NAME => 1 });
    foreach my $line (@$list) {
      $group_hash{$line->{gid}} = "($line->{gid}) $line->{name}";
    }

    return \%group_hash;
  }
  else {
    my $gid = $attr->{GID} || $FORM{GID};

    $GROUPS_SEL = $html->form_select(
      'GID',
      {
        SELECTED    => $gid,
        SEL_LIST    => $users->groups_list({ GIDS => ($admin->{GID}) ? $admin->{GID} : undef, COLS_NAME => 1 }),
        SEL_KEY     => 'gid',
        SEL_VALUE   => 'name',
        SEL_OPTIONS => ($admin->{GID}) ? undef : { '' => "$lang{ALL}" },
        MAIN_MENU   => get_function_index('form_groups'),
        MAIN_MENU_AGRV => $gid ? "GID=$gid" : '',
        EX_PARAMS   => ($attr->{SKIP_MUULTISEL}) ? undef : 'multiple="multiple"'
      }
    );
  }

  return $GROUPS_SEL;
}

#**********************************************************
=head2 sel_status($attr) - show select user group
  Attributes:
    $attr
      STATUS       - Status ID
      HASH_RESULT  - Return results as hash
      NAME         - Select element name
      COLORS       - Status colors
      ALL          - Show all item

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_status {
  my ($attr) = @_;

  my $select_name = $attr->{NAME} || 'STATUS';

  require Service;
  Service->import();
  my $Service = Service->new($db, $admin, \%conf);
  my $list = $Service->status_list({ NAME => '_SHOW', COLOR => '_SHOW', COLS_NAME => 1 });
  my %hash  = ();
  my @style = ();

  foreach my $line (@$list) {
    my $color = $line->{color} || '';
    $hash{$line->{id}} = ((exists $line->{name}) ? _translate($line->{name}) : '');
    if ($attr->{HASH_RESULT}){
      $hash{$line->{id}} .= ":$color";
    }
    $style[$line->{id}] = '#'.$color;
  }

  my $SERVICE_SEL = '';
  if ($attr->{COLORS}) {
    return \@style;
  }
  elsif($attr->{HASH_RESULT}) {
    return \%hash;
  }
  else {
    my $status_id = (defined($attr->{$select_name})) ? $attr->{$select_name} : $FORM{$select_name};

    $SERVICE_SEL = $html->form_select(
      $select_name,
      {
        SELECTED       => $status_id,
        SEL_HASH       => \%hash,
        STYLE          => \@style,
        SORT_KEY_NUM   => 1,
        NO_ID          => 1,
        SEL_OPTIONS    => ($attr->{ALL}) ? { '' => "$lang{ALL}" } : undef,
        #MAIN_MENU      => get_function_index('form_status'),
        #MAIN_MENU_AGRV => "chg=$status_id"
      }
    );
  }

  return $SERVICE_SEL;
}

#**********************************************************
=head2 address_list_tree_menu($attr) - get collapsible tree menu to choose address

  Arguments:
    $attr
      STREETS - if given will not display BUILD level
      NAME    - Name for a first level. Default is $lang{ADDRESS}
      OUTPUT2RETURN

  Returns:
    if $attr->{OUTPUT2RETURN} returns HTML code for menu
    else returns 1

  Example:
    address_list_tree_menu({ STREETS=> 1 });

=cut
#**********************************************************
sub address_list_tree_menu{
  my ($attr) = @_;

  # We are avoiding save of $users object using chaining call
  # You can read this as :
  #   my $users = Users->new($db, \%conf);
  #   my ($list, $parentness_hash) = $users->adress_parentness(\&in_array);
  #

  my ($list, $parentness_hash) = Address->new($db, $admin, \%conf)->address_parentness(\&in_array, $attr);

  #Now build a tree menu for this structure
  my $level_name_keys = ['DISTRICT_NAME','STREET_NAME', 'BUILD_NAME'];
  my $level_id_keys = ['DISTRICT_ID','STREET_ID', 'BUILD_ID'];

  my $checkbox_name = ($attr->{STREETS}) ? "STREET_ID" : "BUILD_ID";
  my $first_level_name = ($attr->{NAME}) ? $attr->{NAME} : $lang{ADDRESS};

  my $menu = $html->tree_menu($list, $first_level_name,
    {
      PARENTNESS_HASH => $parentness_hash,

      CHECKBOX => 1,
      NAME => $checkbox_name,

      LEVEL_LABEL_KEYS => $level_name_keys,
      LEVEL_VALUE_KEYS  => $level_id_keys,
      LEVEL_ID_KEYS  => $level_id_keys,
      LEVEL_CHECKBOX_NAME => $level_id_keys,

    }
  );

  unless($attr->{OUTPUT2RETURN}){
    print $menu;
    return 1;
  }

  return $menu;
}

#**********************************************************
=head2 import_former() - Multi address form

  Arguments:
    UPLOAD_FILE
    IMPORT_DELIMITER
    IMPORT_FIELDS
    IMPORT_TYPE
       CSV
       XML
       JSON
    UPLOAD_PRE
    ENCODE

  Results:
    \@import_data_hash

=cut
#**********************************************************
sub import_former {
  my ($attr) = @_;

  my @import_data = ();

  if($attr->{IMPORT_TYPE} && $attr->{IMPORT_TYPE} eq 'JSON') {
    load_pmodule('JSON');
    my $json = JSON->new->allow_nonref;

    my $perl_scalar;

    eval { $perl_scalar = $json->decode( $attr->{UPLOAD_FILE}{Contents} );  };

    #Syntax oerror
    if ( $@ ) {
      $html->message('err', $lang{ERROR}, "Json Error". $html->pre($@));
    }
    #Else other error
    #elsif(ref $perl_scalar eq 'HASH' && $perl_scalar->{status} && $perl_scalar->{status} eq 'error') {
    #  $perl_scalar->{errno}=1;
    #  $perl_scalar->{errstr}="$perl_scalar->{message}";
    #}

    if($perl_scalar->{DATA_1}) {
      foreach my $info_line (@{ $perl_scalar->{DATA_1} }) {
        foreach my $key ( keys %$info_line ) {
          $info_line->{ uc($key) } = $info_line->{$key};
          delete( $info_line->{$key} );
        }
        push @import_data, $info_line;
      }
    }

    return \@import_data;
  }

  my $delimiter   = $attr->{IMPORT_DELIMITER} || "\t";
  my @cols_names  = split(/,\s?/, $attr->{IMPORT_FIELDS});
  my @rows        = split(/[\r\n]+/, $attr->{UPLOAD_FILE}{Contents});

  my %user_info = ();
  foreach my $line (@rows) {
    next if (! $line || $line =~ /^\s+$/);
    if ($attr->{ENCODE}) {
      $line = convert($line, { $attr->{ENCODE} => 1 });
    }

    my @cols = split(/$delimiter/, $line);
    %user_info = ();

    for(my $i=0; $i<=$#cols; $i++) {
      my $key = ($cols_names[$i]) ? $cols_names[$i] : $i;
      $user_info{ $key }=$cols[$i];
    }

    $user_info{ 'MAIN_ID' }=$cols_names[0];

    push @import_data, { %user_info };
  }

  return \@import_data;
}

#**********************************************************
=head2 mk_menu($menu) - Multi address form

  Arguments:
    $menu
    $attr
      USER_FUNCTION_LIST
      CUSTOM

  Results:

=cut
#**********************************************************
sub mk_menu {
  my($menu, $attr) = @_;

  my $maxnumber=0;
  my $default_index=0;

  foreach my $line (@{ $menu }) {
    my ($ID, $PARENT, $NAME, $FUNTION_NAME, $ARGS) = split(/:/, $line);
    $menu_items{$ID}{$PARENT || 0} = $NAME;
    $menu_names{$ID} = $NAME;
    $functions{$ID}  = $FUNTION_NAME if ($FUNTION_NAME );
    $menu_args{$ID}  = $ARGS         if (defined($ARGS) && $ARGS ne '');
    $maxnumber       = $ID           if (! defined($maxnumber) || $maxnumber < $ID);
  }

  if($attr->{CUSTOM}) {
    return 1;
  }

  #Add modules
  foreach my $m (@MODULES) {
    next if ($admin->{MODULES} && !$admin->{MODULES}{$m});
    load_module($m, { %$html, CONFIG_ONLY => 1 });

    my %module_fl = ();
    my @sordet_module_menu = ();

    if ($attr->{USER_FUNCTION_LIST}){
      @sordet_module_menu = sort keys %USER_FUNCTION_LIST;
    }
    else {
      @sordet_module_menu = sort keys %FUNCTIONS_LIST;
    }

    foreach my $line (@sordet_module_menu) {
      $maxnumber++;
      my ($ID, $SUB, $NAME, $FUNTION_NAME, $ARGS) = split(/:/, $line, 5);
      $ID = int($ID);
      my $v = '';

      if ($attr->{USER_FUNCTION_LIST}){
        $v = $USER_FUNCTION_LIST{$line};
      }
      else{
        $v = $FUNCTIONS_LIST{$line};
      }

      $module_fl{$ID} = $maxnumber;

      if ($ARGS) {
        if ($index < 1 && $ARGS eq 'defaultindex') {
          $default_index = $maxnumber;
          $index         = $default_index;
        }
        elsif ($ARGS ne 'defaultindex') {
          $menu_args{$maxnumber} = $ARGS;
        }

        $menu_args{$maxnumber} = $ARGS;
      }
      if ($SUB > 0) {
        my $sub_id = $module_fl{$SUB} || 0;
        $menu_items{$maxnumber}{ $sub_id } = $NAME;
      }
      else {
        $menu_items{$maxnumber}{$v} = $NAME;
        if ($SUB == -1) {
          $uf_menus{$maxnumber} = $NAME;
        }
      }

      #make user service list
#      if ($SUB == 0 && $FUNCTIONS_LIST{$line} == 11) {
#        $USER_SERVICES{$maxnumber} = "$NAME";
#      }

      $menu_names{$maxnumber} = $NAME;
      $functions{$maxnumber}  = $FUNTION_NAME if ($FUNTION_NAME ne '');
      $module{$maxnumber}     = $m;
    }
    %USER_FUNCTION_LIST = ();
    %FUNCTIONS_LIST = ();
  }

  return 1;
}

#**********************************************************
=head2 custom_menu($attr)

=cut
#**********************************************************
sub custom_menu {
  my ($attr) = @_;

  my $tpl_name = $attr->{TPL_NAME} || 'admin_menu';
  my @menu = ();
  my $menu_content = $html->tpl_show(templates($tpl_name), {  }, { ID            => $tpl_name,
                                                                   SKIP_ERRORS   => 1,
                                                                   OUTPUT2RETURN => 1
                                                                  });

  if (! $menu_content || $FORM{json}) {
    return \@menu;
  }

  my @rows = split(/\n/, $menu_content);

  foreach my $line (@rows) {
    $line =~ s/^[\s\r]+//g;
    if($line =~ /^#/
      || $line =~ /^\s{0,100}$/
      || $line =~ /^</) {
      next;
    }
    push @menu, $line;
  }

  return \@menu;
}

#**********************************************************
=head2 get_version();

  get billing version

=cut
#**********************************************************
sub get_version {

  my $version = '';

  if (-f $base_dir.'/VERSION') {
    if (open(my $fh, '<', $base_dir."/VERSION")) {
      $version = <$fh>;
      close($fh);
    }
  }

  chomp($version);

  return $version;
}

#**********************************************************
=head2 system_info();


=cut
#**********************************************************
sub system_info {

  if (! $conf{SYS_ID}) {
    $conf{SYS_ID} = mk_unique_value(32);
    eval{ use Digest::MD5; };
    if(! $@) {
      my $md5 = Digest::MD5->new();
      $md5->add( $conf{SYS_ID} );
      $conf{SYS_ID} = $md5->hexdigest();
    }

    $Conf->config_add({
        PARAM => 'SYS_ID',
        VALUE => $conf{SYS_ID} || q{}
      });
  }

  my $version     = get_version();
  my $request_url = 'http://abills.net.ua/misc/update.php';
  my @info        = ('users', 'nas', 'tarif_plans', 'admins');
  my @info_data   = ();

  foreach my $key ( @info  ) {
    $admin->query2( "SELECT count(*) FROM `$key`;" );
    push @info_data, ($admin->{list}->[0]->[0] || 0);
  }

  web_request($request_url, {
      REQUEST_PARAMS => {
        sign => $conf{SYS_ID},
        v    => $version,
        info => join('_', @info_data)
      },
    });

  return $version;
}

#**********************************************************
=head2 get_files_in($directory_path, $filter)

  Arguments:
     $directory_path
     $filter  - (optional) filters list by regexp

  Returns:
    array_ref

=cut
#**********************************************************
sub _get_files_in{
  my ($directory_path, $filter) = @_;
  # Read files in dir

  opendir my $fh, $directory_path or do {
    $html->message( 'err', 'ERROR', "Can't open dir '$directory_path' $!\n" );
    return 0;
  };

  my @contents = grep !/^\.\.?$/, readdir $fh;
  closedir $fh;

  if ( $filter && $filter ne '' ) {
    @contents = grep /$filter/, @contents;
  }

  return \@contents;
}

#**********************************************************
=head2 md5_of($file)

=cut
#**********************************************************
sub _md5_of{
  my ($filepath) = @_;

  load_pmodule( "Digest::MD5" );
  my $md5 = Digest::MD5->new();

  my $CRC = '';

  if ( open( my $o_fh, '<', $filepath ) ) {
    $md5->addfile( $o_fh );
    $CRC = $md5->hexdigest();
  }
  else {
    $html->message( 'err', $lang{ERROR}, "Can't open file '$filepath' $!\n" );
  };

  return $CRC;
}

#**********************************************************
=head2 _show_result($Module, $message) - shows error or success message

  Arguments:
    $Module  - Module DB object
    $message - message to show if no error

  Returns:
    boolean - 1 if success

=cut
#**********************************************************
sub _show_result {
  my ($Module, $caption, $message) =  @_;

  return 0 if (_error_show($Module));

  $html->message('info', $caption, $message);

  return 1;
}

#**********************************************************
=head2 _stats_for_file($file)

  Arguments:
    $file - path to file

  Returns:
    hash_ref
     file    - name of file with stats
     dev     - number of filesystem
     ino     - inode number
     mode    - file mode  (type and permissions)
     nlink   - number of (hard) links to the file
     uid     - numeric user ID of file's owner
     gid     - numeric group ID of file's owner
     rdev    - the device identifier (special files only)
     size    - total size of file, in bytes
     atime   - last access time in seconds since the epoch
     mtime   - last modify time in seconds since the epoch
     ctime   - inode change time in seconds since the epoch (*)
     blksize - preferred I/O size in bytes for interacting with the file (may vary from file to file)
     blocks  - actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)

=cut
#**********************************************************
sub _stats_for_file {
  my ($file) = @_;

  my ($dev, $ino, $mode, $nlink, $uid, $gid, $rdev, $size, $atime, $mtime, $ctime, $blksize, $blocks) = stat( $file );

  return {
    file    => $file,
    dev     => $dev,     # number of filesystem
    ino     => $ino,     # inode number
    mode    => $mode,    # file mode  (type and permissions)
    nlink   => $nlink,   # number of (hard) links to the file
    uid     => $uid,     # numeric user ID of file's owner
    gid     => $gid,     # numeric group ID of file's owner
    rdev    => $rdev,    # the device identifier (special files only)
    size    => $size,    # total size of file, in bytes
    atime   => $atime,   # last access time in seconds since the epoch
    mtime   => $mtime,   # last modify time in seconds since the epoch
    ctime   => $ctime,   # inode change time in seconds since the epoch (*)
    blksize => $blksize, # preferred I/O size in bytes for interacting with the file (may vary from file to file)
    blocks  => $blocks,  # actual number of system-specific blocks allocated on disk (often, but not always, 512 bytes each)
  }
}

1
