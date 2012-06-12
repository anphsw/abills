#!/usr/bin/perl
# ABillS User Web interface
#

use vars qw($begin_time %LANG $CHARSET @MODULES $USER_FUNCTION_LIST
$UID $user $admin
$sid);

BEGIN {
  my $libpath = '../';

  $sql_type = 'mysql';
  unshift(@INC, $libpath . "Abills/$sql_type/");
  unshift(@INC, $libpath . "Abills/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();

  }
  else {
    $begin_time = 0;
  }
}

require "config.pl";
require "Abills/templates.pl";
use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Portal;

$html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  }
);

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};

require Admins;
Admins->import();
$admin = Admins->new($db, \%conf);

use Users;
use Dv;
use Tariffs;
use Finance;

$users = Users->new($db, $admin, \%conf);
$Dv = Dv->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Payments = Finance->payments($db, $admin, \%conf);

require "../language/russian.pl";
require "Misc.pm";

#$sid = $FORM{sid} || '';    # Session ID
$html->{CHARSET} = $CHARSET if ($CHARSET);

my $cookies_time = gmtime(time() + $conf{web_session_timeout}) . " GMT";

if ((length($COOKIES{sid}) > 1) && (!$FORM{passwd})) {
  $COOKIES{sid} =~ s/\"//g;
  $COOKIES{sid} =~ s/\'//g;
  $sid = $COOKIES{sid};
}
elsif ((length($COOKIES{sid}) > 1) && (defined($FORM{passwd}))) {
  $html->setCookie('sid', "", "$cookies_time", $web_path, $domain, $secure);
  $COOKIES{sid} = undef;
}

#Cookie section ============================================
if (defined($FORM{colors})) {
  my $cook_colors = (defined($FORM{default})) ? '' : $FORM{colors};
  $html->setCookie('colors', "$cook_colors", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure);
}

#Operation system ID
$html->setCookie('OP_SID',   "$FORM{OP_SID}",   "$cookies_time",            $web_path, $domain, $secure) if (defined($FORM{OP_SID}));
$html->setCookie('language', "$FORM{language}", "Fri, 1-Jan-2038 00:00:01", $web_path, $domain, $secure) if (defined($FORM{language}));

$html->{CHARSET} = $CHARSET if ($CHARSET);

load_module('Managers', $html);

%permissions = ();
my $error_msg = 0;
my %OUTPUT;    # Отвечает за генерацию шаблона
my $list          = '';
my $table_content = '';
my $users_total;                 # Всего учетных записей
my $mounth_contracts_added;      # Всего заключено договоров(текущий месяц год)
my $mounth_contracts_deleted;    # Всего разторгнуто договоров(текущий месяц год)
my $mounth_disabled_users;       # Всего временно отключившихся(текущий месяц год)
my $mounth_total_debtors;        # не оплативших текущий месяц
my $total_debtors;               # не оплативших 2 и более месяцев
my @service_status = ("$_ENABLE", "$_DISABLE", "$_NOT_ACTIVE", "$_HOLD_UP", "$_DISABLE: $_NON_PAYMENT", "$ERR_SMALL_DEPOSIT");
my @ref = ();    #ccылка на резултат запроса, для формирования отчета

if ($DATE && $DATE =~ /^(\d{1,4})\-(\d{2})\-(\d{2})$/) {
  $OUTPUT{YEAR}       = $1;
  $OUTPUT{MOUNTH}     = $2;
  $OUTPUT{DAY}        = $3;
  $OUTPUT{MOUNTH_STR} = $MONTHES[ $OUTPUT{MOUNTH} - 1 ];
}

my $content = '';
my $login   = $FORM{user} || '';
my $passwd  = $FORM{passwd} || '';

($aid, $sid, $login) = check_permissions("$login", "$passwd", "$sid");
my %uf_menus = ();

if ($sid) {
  $html->setCookie('sid', "$sid", "$cookies_time", $web_path, $domain, $secure);
  $COOKIES{sid} = $sid;
}

print "Content-Type: text/html\n\n";

if ($aid > 0) {
  if ($FORM{SHOW_REPORT}) {
    form_reports();
  }
  elsif ($index == 2) {
    form_payments();
  }
  else {
    form_main();
  }

  print $html->tpl_show(
    _include('managers_main', 'Managers'),
    {
      CONTENT => $content || $html->{OUTPUT},
      ADMIN_NAME => $admin->{A_FIO},
      FILTER     => $filter,
    }
  );
}
else {
  form_login();
  print $html->{OUTPUT};
}











#**********************************************************
#
#**********************************************************
sub form_reports_main {
  # Всего пользователей
  $users_total = $Dv->list(
    {
      COLS_NAME      => 1,
      ADDRESS_STREET => '*',
      ADDRESS_BUILD  => '*',
      ADDRESS_FLAT   => '*',
      CONTRACT_DATE  => '>=0000-00-00',
      REGISTRATION   => '>=0000-00-00',
    }
  );
  $OUTPUT{USER_TOTAL} = $Dv->{TOTAL};

  $mounth_contracts_added = $Dv->list(
    {
      ADDRESS_STREET => '*',
      ADDRESS_BUILD  => '*',
      ADDRESS_FLAT   => '*',
      CONTRACT_DATE  => '>=0000-00-00',
      COLS_NAME      => 1,
      REGISTRATION   => ">=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-01;<=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-$OUTPUT{DAY}",
    }
  );

  if (defined($attr->{DELETED})) {
    print "$_DELETED";
  }

  $OUTPUT{REGISTRATION_MOUNTH_TOTAL} = $Dv->{TOTAL};

  # Всего разторгнуто договоров(месяц год) -
  $mounth_contracts_deleted = $Dv->list(
    {
      ADDRESS_STREET => '*',
      ADDRESS_BUILD  => '*',
      ADDRESS_FLAT   => '*',
      CONTRACT_DATE  => '>=0000-00-00',
      COLS_NAME      => 1,
      ACTION_DATE    => ">=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-01;<=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-$OUTPUT{DAY}",
      ACTION_TYPE    => 12,
      DELETED        => 1,
      USER_STATUS    => 1,
    }
  );

  $OUTPUT{DISCONNECTED} = $Dv->{TOTAL};

  $mounth_disabled_users = $Dv->list(
    {
      ADDRESS_STREET => '*',
      ADDRESS_BUILD  => '*',
      ADDRESS_FLAT   => '*',
      CONTRACT_DATE  => '>=0000-00-00',
      COLS_NAME      => 1,
      ACTION_DATE    => ">=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-01;<=$OUTPUT{YEAR}-$OUTPUT{MOUNTH}-$OUTPUT{DAY}",
      ACTION_TYPE    => 9,
      REGISTRATION   => '>=0000-00-00',
    }
  );

  $OUTPUT{TEMPORARILY_DISCONNECTED} = $Dv->{TOTAL};

  #Всего должников:
  #не оплативших текущий месяц
  $mounth_total_debtors = $Dv->report_debetors(
    {
      COLS_NAME      => 1,
      ADDRESS_STREET => '*',
      ADDRESS_BUILD  => '*',
      ADDRESS_FLAT   => '*',
      CONTRACT_ID    => '*',
      CONTRACT_DATE  => '>=0000-00-00',
      REGISTRATION   => '>=0000-00-00',
    }
  );

  $OUTPUT{REPORT_DEBETORS} = $Dv->{TOTAL};

  #не оплативших 2 и более месяцев -
  $total_debtors = $Dv->report_debetors(
    {
      COLS_NAME      => 1,
      ADDRESS_STREET => '*',
      ADDRESS_BUILD  => '*',
      ADDRESS_FLAT   => '*',
      CONTRACT_ID    => '*',
      CONTRACT_DATE  => '>=0000-00-00',
      REGISTRATION   => '>=0000-00-00',
      PERIOD         => 2
    }
  );

  $OUTPUT{REPORT_DEBETORS2} = $Dv->{TOTAL};
}


#**********************************************************
#
#**********************************************************
sub form_main {

  form_reports_main();
############## SEARCH
  #					LOGIN           => $FORM{QUERY},
  #					COLS_NAME       => 1,
  #					ADDRESS_STREET  => '*',
  #					ADDRESS_BUILD   => '*',
  #					ADDRESS_FLAT    => '*',
  #					CONTRACT_ID     => '*',

  $LIST_PARAMS{LOGIN}          = '*';
  $LIST_PARAMS{ADDRESS_STREET} = '*';
  $LIST_PARAMS{ADDRESS_BUILD}  = '*';
  $LIST_PARAMS{ADDRESS_FLAT}   = '*';
  $LIST_PARAMS{CONTRACT_ID}    = '*';
  $LIST_PARAMS{PHONE}          = '*';
  $LIST_PARAMS{IP}             = '>=0.0.0.0';

  if ($index == 11) {
    dv_users();
  }
  else {
    $content = $html->tpl_show(_include('managers_main_content', 'Managers'), {%OUTPUT});
  }
}

#**********************************************************
#
#**********************************************************
sub form_reports {

  form_reports_main();

  my$table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'right' ],
        rows       => [ [ "$_TOTAL:", $html->b($Dv->{TOTAL}) ] ]
      }
    );
  $table->show();


  $table = $html->table(
    {
      width   => '100%',
      caption => "$_REPORTS",
      border  => 1,
      title   => [ "$_ONTRACT_ID", "$_FIO", "$_ADDRESS", "$_TARIF_PLAN", "$_STATUS", "$_CONTRACT $_DATE", 'дата фактического подключения', 'дата отключения' ],
      cols_align => [ 'left', 'right', 'right', 'right', 'center', 'center' ],
      pages      => $Dv->{TOTAL},
      ID         => 'REPORT_USERS',
    }
  );

  # Выбираем тип отчета
  if ($FORM{SHOW_REPORT} eq 'users_total') {
    $ref = \@$users_total;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_contracts_added') {
    $ref = \@$mounth_contracts_added;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_contracts_deleted') {
    $ref = \@$mounth_contracts_deleted;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_disabled_users') {
    $ref = \@$mounth_disabled_users;
  }
  elsif ($FORM{SHOW_REPORT} eq 'mounth_total_debtors') {
    $ref = \@$mounth_total_debtors;
  }
  elsif ($FORM{SHOW_REPORT} eq 'total_debtors') {
    $ref = \@$total_debtors;
  }

  foreach my $u (@$ref) {
    $table->addrow($u->{id}, 
      $u->{fio}, 
      $u->{address_street} . ' ' . $u->{address_build} . ' ' . $u->{address_flat}, 
      $u->{tp_name}, 
      $service_status[ $u->{dv_status} ], 
      $u->{contract_date}, 
      $u->{registration}, '-',);
  }
  $table->show();

  $filter = $html->tpl_show(_include('managers_filter_reports', 'Managers'), { undef, OUTPUT2RETURN => 1 });
}

#**********************************************************
# check_permissions()
#**********************************************************
sub check_permissions {
  my ($login, $password, $sid, $attr) = @_;

  if ($index == 1000) {
    $admin->online_del({ SID => $sid });
    return 0;
  }

  if ($conf{ADMINS_ALLOW_IP}) {
    $conf{ADMINS_ALLOW_IP} =~ s/ //g;
    my @allow_ips_arr = split(/,/, $conf{ADMINS_ALLOW_IP});
    my $allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $ENV{REMOTE_ADDR} }) {
      $admin->system_action_add("$login:$password DENY IP: $ENV{REMOTE_ADDR}", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  $login    =~ s/"/\\"/g;
  $login    =~ s/'/\''/g;
  $password =~ s/"/\\"/g;
  $password =~ s/'/\\'/g;

  my %PARAMS = (
    LOGIN     => "$login",
    PASSWORD  => "$password",
    SECRETKEY => $conf{secretkey},
    IP        => $ENV{REMOTE_ADDR} || '0.0.0.0'
  );

  if ($sid) {
    $admin->online_info({ SID => $sid });
    if ($admin->{TOTAL} > 0 && $ENV{REMOTE_ADDR} eq $admin->{IP}) {
      $admin->info($admin->{AID});
      return $admin->{AID}, $sid;
    }
  }

  $admin->info(0, {%PARAMS});

  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
    }
    return 0;
  }
  elsif ($admin->{DISABLE} == 1) {
    $admin->{errno}  = 2;
    $admin->{errstr} = 'DISABLED';
    return 0;
  }

  if (!$sid) {
    $sid = mk_unique_value(14);
  }

  $admin->online({ SID => $sid });
  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(/;/, $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split(/=/, $line);
      $admin->{WEB_OPTIONS}{$k} = $v;
    }
  }

  %permissions = %{ $admin->get_permissions() };
  return $admin->{AID}, $sid;
}

#**********************************************************
#
#**********************************************************
sub user_ext_menu {
  my ($UID, $LOGIN, $attr) = @_;

  my $payments_menu = (defined($permissions{1})) ? '<li>' . $html->button($_PAYMENTS, "UID=$UID&index=2") . '</li>' : '';
  my $fees_menu     = (defined($permissions{2})) ? '<li>' . $html->button($_FEES,     "UID=$UID&index=3") . '</li>' : '';
  my $sendmail_manu = '<li>' . $html->button($_SEND_MAIL, "UID=$UID&index=31") . '</li>';

  my $second_menu    = '';
  my %userform_menus = (
    22 => $_LOG,
    21 => $_COMPANY,
    12 => $_GROUP,
    18 => $_NAS,
    20 => $_SERVICES,
    19 => $_BILL
  );

  $userform_menus{17} = $_PASSWD if ($permissions{0}{3});

  while (my ($k, $v) = each %uf_menus) {
    $userform_menus{$k} = $v;
  }

  #Make service menu
  my $service_menu       = '';
  my $service_func_index = 0;
  my $service_func_menu  = '';
  foreach my $key (sort keys %menu_items) {
    if (defined($menu_items{$key}{20})) {
      $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
      $service_menu .= '<li>' . $html->button($menu_items{$key}{20}, "UID=$UID&index=$key");
    }

    if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
      $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$UID&index=$key") . ' ';
    }
  }

  foreach my $k (sort { $b <=> $a } keys %userform_menus) {
    my $v   = $userform_menus{$k};
    my $url = "index=$k&UID=$UID";
    my $a   = (defined($FORM{$k})) ? $html->b($v) : $v;
    $second_menu .= "<li>" . $html->button($a, "$url") . '</li>';
  }

  my $ext_menu = qq{
<div id=quick_menu class=noprint>
<ul id=topNav>
  <li><a href="#"><img src='/img/user.png' border=0/></a>
  <ul>
    $payments_menu
    $fees_menu
    $sendmail_manu
    <li><a href='#'>Service >> </a>
      <ul>
       $service_menu
      </ul>
    </li>
    <li><a href='#'>$_OTHER >> </a>
      <ul>
        $second_menu
      </ul>
    </li> 
   </ul>
   </li> 
</ul>
</div>
};

  my $return = $ext_menu;
  if ($attr->{SHOW_UID}) {
    $return .= ' : ' . $html->button($html->b($LOGIN), "index=15&UID=${UID}") . " (UID: $UID) ";
  }
  else {
    $return .= $html->button($LOGIN, "index=15&UID=$UID" . (($attr->{EXT_PARAMS}) ? "&$attr->{EXT_PARAMS}" : ''), { TITLE => $attr->{TITLE} });
  }

  return $return;
}

#**********************************************************
# title_former
#**********************************************************
sub title_former {
  my ($attr) = @_;
  my @title = ();

  my $data = $attr->{INPUT_DATA};

  my %SEARCH_TITLES = (
    'disable'                           => "$_STATUS",
    'deposit'                           => "$_DEPOSIT",
    'credit'                            => "$_CREDIT",
    'id'                                => "$_LOGIN",
    'fio'                               => "$_FIO",
    'ext_deposit'                       => "$_EXTRA $_DEPOSIT",
    'last_payment'                      => "$_PAYMENTS $_DATE",
    'email'                             => 'E-Mail',
    'address_street'                    => $_ADDRESS,
    'pasport_date'                      => "$_PASPORT $_DATE",
    'pasport_num'                       => "$_PASPORT $_NUM",
    'pasport_grant'                     => "$_PASPORT $_GRANT",
    'address_build'                     => "$_ADDRESS_BUILD",
    'address_flat'                      => "$_ADDRESS_FLAT",
    'city'                              => "$_CITY",
    'zip'                               => "$_ZIP",
    'contract_id'                       => "$_CONTRACT_ID",
    'registration'                      => "$_REGISTRATION",
    'phone'                             => "$_PHONE",
    'comments'                          => "$_COMMENTS",
    'company_id'                        => '$_COMPANY_ID',
    'bill_id'                           => '$_BILLS',
    'activate'                          => "$_ACTIVATE",
    'expire'                            => "$_EXPIRE",
    'credit_date'                       => "$_CREDIT $_DATE",
    'reduction'                         => "$_REDUCTION",
    'domain_id'                         => 'DOMAIN ID',
    'build_number'                      => "$_BUILDS",
    'streets_name'                      => "$_STREETS",
    'district_name'                     => "$_DISTRICTS",
    'u.deleted'                         => "$_DELETED",
    'u.gid'                             => "$_GROUP",
    'builds.id'                         => 'Location ID',
    'uid'                               => 'UID',
    'if(company.id IS NULL,b.id,cb.id)' => "_BILL"
  );

  if ($data->{EXTRA_FIELDS}) {
    foreach my $line (@{ $data->{EXTRA_FIELDS} }) {
      if ($line->[0] =~ /ifu(\S+)/) {
        my $field_id = $1;
        my ($position, $type, $name, $user_portal) = split(/:/, $line->[1]);
        if ($type == 2) {
          $SEARCH_TITLES{ $field_id . '_list_name' } = eval "\"$name\"";
        }
        else {
          $SEARCH_TITLES{$field_id} = eval "\"$name\"";
        }
      }
    }
  }

  %SEARCH_TITLES = (%SEARCH_TITLES, %{ $attr->{EXT_TITLES} });

  my $base_fields  = $attr->{BASE_FIELDS};
  my @EX_TITLE_ARR = @{ $data->{COL_NAMES_ARR} };
  my @title        = ();

  for (my $i = 0 ; $i < $base_fields + $data->{SEARCH_FIELDS_COUNT} ; $i++) {
    $title[$i] = $SEARCH_TITLES{ $EX_TITLE_ARR[$i] } || "$_SEARCH";
  }
  foreach my $function_fld_name (split(/,/, $attr->{FUNCTION_FIELDS})) {
    $title[ $#title + 1 ] = '-';
  }
  return \@title;
}

#**********************************************************
# user_info
#**********************************************************
sub user_info {
  my ($UID) = @_;

  my $user_info = $users->info($UID, {%FORM});

  if ($users->{TOTAL} == 0 && !$FORM{UID}) {
    return 0;
  }

  my $deleted = ($user_info->{DELETED}) ? $html->color_mark($html->b($_DELETED), '#FF0000') : '';
  my $ext_menu = user_ext_menu($user_info->{UID}, $user_info->{LOGIN}, { SHOW_UID => 1 });

  $table = $html->table(
    {
      width      => '100%',
      rowcolor   => 'even',
      border     => 0,
      cols_align => ['left:noprint'],
      rows       => [ [ "$ext_menu" . $deleted ] ],
      class      => 'form',
    }
  );

  $user_info->{TABLE_SHOW} = $table->show();
  $LIST_PARAMS{UID}        = $user_info->{UID};
  $pages_qs                = "&UID=$user_info->{UID}";
  $pages_qs .= "&subf=$FORM{subf}" if (defined($FORM{subf}));

  return $user_info;
}

#**********************************************************
# form_users()
#**********************************************************
sub form_users {
  my ($attr) = @_;

  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract();
    return 0;
  }
  elsif ($FORM{SEND_SMS_PASSWORD}) {
    load_module('Sms', $html);
    $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    $users->pi({ UID => $FORM{UID} });
    if (
      sms_send(
        {
          NUMBER => $users->{PHONE},
          ,
          MESSAGE => "LOGIN: $users->{LOGIN} PASSWORD: $users->{PASSWORD}",
          UID     => $users->{UID}
        }
      )
    )
    {
      $html->message('info', "$_INFO", "$_PASSWD SMS $_SENDED");
    }
    return 0;
  }

  if ($attr->{USER_INFO}) {
    my $user_info = $attr->{USER_INFO};
    if ($users->{errno}) {
      $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
      return 0;
    }

    print "<table width=\"100%\" border=\"0\" cellspacing=\"1\" cellpadding=\"2\"><tr><td valign=\"top\" align=\"center\">\n";

    #Make service menu
    my $service_menu       = '';
    my $service_func_index = 0;
    my $service_func_menu  = '';
    foreach my $key (sort keys %menu_items) {
      if (defined($menu_items{$key}{20})) {
        $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
        $service_menu .= '<li class=umenu_item>' . $html->button($menu_items{$key}{20}, "UID=$user_info->{UID}&index=$key");
      }

      if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
        $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key") . ' ';
      }
    }

    form_passwd({ USER_INFO => $user_info }) if (defined($FORM{newpassword}));

    if ($FORM{change}) {
      if (!$permissions{0}{4}) {
        $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
        print "</td></table>\n";
        return 0;
      }
      elsif (!$permissions{0}{9} && $user_info->{CREDIT} != $FORM{CREDIT}) {
        $html->message('err', $_ERROR, "$_CHANGE $_CREDIT $ERR_ACCESS_DENY");
        $FORM{CREDIT} = undef;
      }
      elsif (!$permissions{0}{11} && $user_info->{REDUCTION} != $FORM{REDUCTION}) {
        $html->message('err', $_ERROR, "$_REDUCTION $ERR_ACCESS_DENY");
        $FORM{REDUCTION} = undef;
      }

      $user_info->change($user_info->{UID}, {%FORM});
      if ($user_info->{errno}) {
        $html->message('err', $_ERROR, "[$user_info->{errno}] $err_strs{$user_info->{errno}}");
        user_form();
        print "</td></table>\n";
        return 0;
      }
      else {
        $html->message('info', $_CHANGED, "$_CHANGED $users->{info}");
        if (defined($FORM{FIO})) {
          $users->pi_change({%FORM});
        }

        cross_modules_call('_payments_maked', { USER_INFO => $user_info, });

        #External scripts
        if ($conf{external_userchange}) {
          if (!_external($conf{external_userchange}, {%FORM})) {
            return 0;
          }
        }
        if ($attr->{REGISTRATION}) {
          print "</td></tr></table>\n";
          return 0;
        }
      }
    }
    elsif ($FORM{del_user} && $FORM{is_js_confirmed} && $index == 15 && $permissions{0}{5}) {
      user_del({ USER_INFO => $user_info });
      print "</td></tr></table>\n";
      return 0;
    }
    else {
      if (!$permissions{0}{4}) {
        @action = ();
      }
      else {
        @action = ('change', $_CHANGE);
      }

      user_form({ USER_INFO => $user_info });

      if ($conf{USER_ALL_SERVICES}) {

        foreach my $module (@MODULES) {
          $FORM{MODULE} = $module;
          my $service_func_index = 0;
          my $service_func_menu  = '';
          my $service_menu       = '';
          foreach my $key (sort keys %menu_items) {
            if (defined($menu_items{$key}{20})) {
              $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
              $service_menu .= '<li class=umenu_item>' . $html->button($menu_items{$key}{20}, "UID=$user_info->{UID}&index=$key");
            }

            if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
              $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key") . ' ';
            }
          }
          if ($service_func_index) {
            print "<TABLE width='100%' border=0>
        <TR><TH class=form_title>$module</TH></TR>
        <TR><TH class=odd><div id='rules'><ul><li class='center'>$service_func_menu</li></ul></div></TH></TR></TABLE>\n";

            $index = $service_func_index;
            if (defined($module{$service_func_index})) {
              load_module($module{$service_func_index}, $html);
            }

            $functions{$service_func_index}->({ USER_INFO => $user_info });
          }
        }

      }
      else {

        #===============
        #$service_func_index
        if ($functions{$service_func_index}) {
          $index = $service_func_index;
          if (defined($module{$service_func_index})) {
            load_module($module{$service_func_index}, $html);
          }

          print "<TABLE width='100%' border=0>
      <TR><TH class=form_title>$module{$service_func_index}</TH></TR>
      <TR><TH class=even><div id='rules'><ul><li class='center'>$service_func_menu</li></ul></div></TH></TR>
    </TABLE>\n";

          $functions{$service_func_index}->({ USER_INFO => $user_info });
        }

        #===============
      }
      user_pi({ %$attr, USER_INFO => $user_info });
    }

    my $payments_menu = (defined($permissions{1})) ? '<li class=umenu_item>' . $html->button($_PAYMENTS, "UID=$user_info->{UID}&index=2") . '</li>' : '';
    my $fees_menu     = (defined($permissions{2})) ? '<li class=umenu_item>' . $html->button($_FEES,     "UID=$user_info->{UID}&index=3") . '</li>' : '';
    my $sendmail_manu = '<li class=umenu_item>' . $html->button($_SEND_MAIL, "UID=$user_info->{UID}&index=31") . '</li>';

    my $second_menu    = '';
    my %userform_menus = (
      22 => $_LOG,
      21 => $_COMPANY,
      12 => $_GROUP,
      18 => $_NAS,
      20 => $_SERVICES,
      19 => $_BILL
    );

    $userform_menus{17} = $_PASSWD if ($permissions{0}{3});

    while (my ($k, $v) = each %uf_menus) {
      $userform_menus{$k} = $v;
    }

    foreach my $k (sort { $b <=> $a } keys %userform_menus) {
      my $v   = $userform_menus{$k};
      my $url = "index=$k&UID=$user_info->{UID}";
      my $a   = (defined($FORM{$k})) ? $html->b($v) : $v;
      $second_menu .= "<li class=umenu_item>" . $html->button($a, "$url") . '</li>';
    }

    my $full_delete = '';
    if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8} && ($user_info->{DELETED})) {
      $second_menu .= "<li class=umenu_item>" . $html->button($_UNDELETE, "index=15&del_user=1&UNDELETE=1&UID=$user_info->{UID}&is_js_confirmed=1") . '</li>';
      $full_delete = "&FULL_DELETE=1";
    }

    $second_menu .= "<li class=umenu_item>" . $html->button($_DEL, "index=15&del_user=1&UID=$user_info->{UID}$full_delete", { MESSAGE => "$_USER: $user_info->{LOGIN} / $user_info->{UID}" }) . '</li>' if (defined($permissions{0}{5}));

    print "
</td><td bgcolor='$_COLORS[3]' valign='top' width='180'>
<table width='100%' border='0' cellspacing='0' cellpadding='0'><tr><td>
<div class=l_user_menu>
<ul class=user_menu>
  $payments_menu
  $fees_menu
  $sendmail_manu
</ul>
</div>
</td></tr>
<tr><td>
  <div class=l_user_menu> 
  <ul class=user_menu>
   $service_menu
  </ul></div>
<div class=l_user_menu>
<ul class=user_menu>
 $second_menu
</ul></div>
</td></tr>
</table>
</td></tr></table>\n";
    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
      return 0;
    }

    if ($FORM{newpassword}) {
      if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
        $html->message('err', $_ERROR, "$ERR_SHORT_PASSWD $conf{PASSWD_LENGTH}");
      }
      elsif ($FORM{newpassword} eq $FORM{confirm}) {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
      elsif ($FORM{newpassword} ne $FORM{confirm}) {
        $html->message('err', $_ERROR, "$ERR_WRONG_CONFIRM");
      }
      else {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
    }

    $FORM{REDUCTION} = 100 if ($FORM{REDUCTION} && $FORM{REDUCTION} > 100);

    my $user_info = $users->add({%FORM});
    if ($users->{errno}) {
      if ($users->{errno} == 10) {
        $html->message('err', $_ERROR, "'$FORM{LOGIN}' $ERR_WRONG_NAME");
      }
      elsif ($users->{errno} == 7) {
        $html->message('err', $_ERROR, "'$FORM{LOGIN}' $_USER_EXIST");
      }
      else {
        $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
      }

      delete($FORM{add});

      #user_form();
      return 1;
    }
    else {
      $html->message('info', $_ADDED, "$_ADDED '$user_info->{LOGIN}' / [$user_info->{UID}]");
      if ($conf{external_useradd}) {
        if (!_external($conf{external_useradd}, {%FORM})) {
          return 0;
        }
      }

      $user_info = $users->info($user_info->{UID}, { SHOW_PASSWORD => 1 });
      $html->tpl_show(templates('form_user_info'), $user_info);
      $LIST_PARAMS{UID} = $user_info->{UID};
      $FORM{UID}        = $user_info->{UID};
      user_pi({ %$attr, REGISTRATION => 1 });

      #$index=get_function_index('form_payments');
      #form_payments({ USER => $user_info });
      if ($FORM{COMPANY_ID}) {
        form_companie_admins($attr);
      }
      return 0;
    }
  }

  #Multi user operations
  elsif ($FORM{MULTIUSER}) {
    my @multiuser_arr = split(/, /, $FORM{IDS});
    my $count         = 0;
    my %CHANGE_PARAMS = ();
    while (my ($k, $v) = each %FORM) {
      if ($k =~ /^MU_(\S+)/) {
        my $val = $1;
        $CHANGE_PARAMS{$val} = $FORM{$val};
      }
    }

    if (!defined($FORM{DISABLE})) {
      $CHANGE_PARAMS{UNCHANGE_DISABLE} = 1;
    }
    else {
      $CHANGE_PARAMS{DISABLE} = $FORM{MU_DISABLE} || 0;
    }

    if ($#multiuser_arr < 0) {
      $html->message('err', $_MULTIUSER_OP, "$_SELECT_USER");
    }
    elsif (scalar keys %CHANGE_PARAMS < 1) {

      #$html->message('err', $_MULTIUSER_OP, "$_SELECT_USER");
    }
    else {
      foreach my $uid (@multiuser_arr) {
        if ($FORM{DEL} && $FORM{MU_DEL}) {
          my $user_info = $users->info($uid);
          user_del({ USER_INFO => $user_info });

          if ($users->{errno}) {
            $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
          }
        }
        else {
          $users->change($uid, { UID => $uid, %CHANGE_PARAMS });
          if ($users->{errno}) {
            $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
            return 0;
          }
        }
      }
      $html->message('info', $_MULTIUSER_OP, "$_TOTAL: " . $#multiuser_arr + 1 . " IDS: $FORM{IDS}");
    }
  }

  if (!$permissions{0}{2}) {
    return 0;
  }

  if ($FORM{COMPANY_ID} && !$FORM{change}) {
    print $html->br($html->b("$_COMPANY:") . $FORM{COMPANY_ID});
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
  }

  if ($FORM{letter}) {
    $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
  }

  my @statuses = ($_ALL, $_ACTIV, $_DEBETORS, $_DISABLE, $_EXPIRE, $_CREDIT);
  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    push @statuses, $_DELETED,;
  }

  my $i            = 0;
  my $users_status = 0;
  foreach my $name (@statuses) {
    if (defined($FORM{USERS_STATUS}) && $FORM{USERS_STATUS} == $i && $FORM{USERS_STATUS} ne '') {
      $LIST_PARAMS{USER_STATUS} = 1;
      if ($i == 1) {
        $LIST_PARAMS{ACTIVE} = 1;
      }
      elsif ($i == 2) {
        $LIST_PARAMS{DEPOSIT} = '<0';
      }
      elsif ($i == 3) {
        $LIST_PARAMS{DISABLE} = 1;
      }
      elsif ($i == 4) {
        $LIST_PARAMS{EXPIRE} = "<$DATE,>0000-00-00";
      }
      elsif ($i == 5) {
        $LIST_PARAMS{CREDIT} = ">0";
      }
      elsif ($i == 6) {
        $LIST_PARAMS{DELETED} = 1;
      }

      $pages_qs   .= "&USERS_STATUS=$i";
      $status_bar .= ' ' . $html->b($name);
      $users_status = $i;
    }
    else {
      my $qs = $pages_qs;
      $qs =~ s/\&USERS_STATUS=\d//;
      $status_bar .= ' ' . $html->button("$name", "index=$index&USERS_STATUS=$i$qs");
    }
    $i++;
  }

  my $list = $users->list(
    {
      %LIST_PARAMS,
      FULL_LIST => 1,
      COLS_NAME => 1,
    }
  );

  if ($users->{errno}) {
    $html->message('err', $_ERROR, "[$users->{errno}] $err_strs{$users->{errno}}");
    return 0;
  }
  elsif ($users->{TOTAL} == 1) {
    $FORM{index} = 15;
    if (!$FORM{UID}) {
      $FORM{UID} = $list->[0]->{uid};
      if ($FORM{LOGIN} =~ /\*/ || $FORM{LOGIN} eq '') {
        delete $FORM{LOGIN};
        $ui = user_info($FORM{UID});
        print $ui->{TABLE_SHOW};
      }
    }

    form_users({ USER_INFO => $ui });
    return 0;
  }
  elsif ($users->{TOTAL} == 0) {
    $html->message('err', $_ERROR, "$_USER $_NOT_EXIST");
    return 0;
  }

  print $html->letters_list({ pages_qs => $pages_qs });

  my $TITLE = title_former(
    {
      INPUT_DATA      => $users,
      BASE_FIELDS     => 5,
      FUNCTION_FIELDS => 'payments, fees',
    }
  );

  #User list
  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$_USERS - " . $statuses[$users_status],
      title      => $TITLE,
      cols_align => [ 'left', 'left', 'right', 'right', 'center', 'right', 'center:noprint', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $users->{TOTAL},
      ID         => 'USERS_LIST',
      header     => ($permissions{0}{7})
      ? "<script language=\"JavaScript\" type=\"text/javascript\">
<!-- 
function CheckAllINBOX() {
  for (var i = 0; i < document.users_list.elements.length; i++) {
    if(document.users_list.elements[i].type == 'checkbox' && document.users_list.elements[i].name == 'IDS'){
      document.users_list.elements[i].checked =         !(document.users_list.elements[i].checked);
    }
  }
}
//-->
</script>\n
<a href=\"javascript:void(0)\" onClick=\"CheckAllINBOX();\" class=export_button>$_SELECT_ALL</a>\n$status_bar"
      : undef,
      EXPORT => ' XML:&xml=1;',
      MENU   => "$_ADD:index=" . get_function_index('form_wizard') . ':add' . ";$_SEARCH:index=" . get_function_index('form_search') . ":search"
    }
  );
  my $base_fields = 5;
  foreach my $line (@$list) {
    my $uid      = $line->{uid};
    my $payments = ($permissions{1}) ? $html->button($_PAYMENTS, "index=2&UID=$uid", { CLASS => 'payments' }) : '';
    my $fees     = ($permissions{2}) ? $html->button($_FEES, "index=3&UID=$uid", { CLASS => 'fees' }) : '';

    my @fields_array = ();
    for (my $i = $base_fields ; $i < $base_fields + $users->{SEARCH_FIELDS_COUNT} ; $i++) {
      if ($conf{EXT_BILL_ACCOUNT} && $users->{COL_NAMES_ARR}->[$i] eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, $_COLORS[6]) : $line->{ext_bill_deposit};
      }
      elsif ($users->{COL_NAMES_ARR}->[$i] eq 'deleted') {
        $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ], ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
      }
      push @fields_array, $table->td($line->{ $users->{COL_NAMES_ARR}->[$i] });
    }

    my $multiuser = ($permissions{0}{7}) ? $html->form_input('IDS', "$uid", { TYPE => 'checkbox', }) : '';
    $table->addtd(
      $table->td($multiuser . user_ext_menu($uid, $line->{id})),
      $table->td($line->{fio}),
      $table->td(($line->{deposit} + $line->{credit} < 0) ? $html->color_mark($line->{deposit}, $_COLORS[6]) : $line->{deposit}),
      $table->td($line->{credit}),
      $table->td($status[ $line->{disable} ], { bgcolor => $state_colors[ $line->{disable} ], align => 'center' }),
      @fields_array, $table->td($payments), $table->td($fees),
    );
  }

  my @totals_rows =
  ([ $html->button("$_TOTAL:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ], [ $html->button("$_EXPIRE:", "index=$index&USERS_STATUS=2"), $html->b($users->{TOTAL_EXPIRED}) ], [ $html->button("$_DISABLE:", "index=$index&USERS_STATUS=3"), $html->b($users->{TOTAL_DISABLED}) ]);

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    $users->{TOTAL} -= $users->{TOTAL_DELETED};
    $totals_rows[0] = [ $html->button("$_TOTAL:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ];
    push @totals_rows, [ $html->button("$_DELETED:", "index=$index&USERS_STATUS=4"), $html->b($users->{TOTAL_DELETED}) ],;
  }

  my $table2 = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => [@totals_rows]
    }
  );

  if ($permissions{0}{7}) {
    my $table3 = $html->table(
      {
        width      => '100%',
        caption    => "$_MULTIUSER_OP",
        cols_align => [ 'left', 'left' ],
        rowcolor   => $_COLORS[1],
        rows       => [
          [ $html->form_input('MU_GID', "1", { TYPE => 'checkbox', }) . $_GROUP, sel_groups() ],
          [ $html->form_input('MU_DISABLE',     "1", { TYPE => 'checkbox', }) . $_DISABLE,         $html->form_input('DISABLE',     "1", { TYPE => 'checkbox', }) . $_CONFIRM ],
          [ $html->form_input('MU_DEL',         "1", { TYPE => 'checkbox', }) . $_DEL,             $html->form_input('DEL',         "1", { TYPE => 'checkbox', }) . $_CONFIRM ],
          [ $html->form_input('MU_ACTIVATE',    "1", { TYPE => 'checkbox', }) . $_ACTIVATE,        $html->form_input('ACTIVATE',    "0000-00-00") ],
          [ $html->form_input('MU_EXPIRE',      "1", { TYPE => 'checkbox', }) . $_EXPIRE,          $html->form_input('EXPIRE',      "0000-00-00") ],
          [ $html->form_input('MU_CREDIT',      "1", { TYPE => 'checkbox', }) . $_CREDIT,          $html->form_input('CREDIT',      "0") ],
          [ $html->form_input('MU_CREDIT_DATE', "1", { TYPE => 'checkbox', }) . "$_CREDIT $_DATE", $html->form_input('CREDIT_DATE', "0000-00-00") ],
          [ '', $html->form_input('MULTIUSER', "$_CHANGE", { TYPE => 'submit' }) ],

        ]
      }
    );

    print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }) . ((!$admin->{MAX_ROWS}) ? $table2->show({ OUTPUT2RETURN => 1 }) : '') . $table3->show({ OUTPUT2RETURN => 1 }),
        HIDDEN => {
          index       => 11,
          FULL_DELETE => ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) ? 1 : undef,
        },
        NAME => 'users_list'
      }
    );

  }
  else {
    print $table->show();
    print $table2->show() if (!$admin->{MAX_ROWS});
  }
}

#**********************************************************
# user_form()
#**********************************************************
sub user_form {
  my ($attr) = @_;

  $index = 15 if (!$attr->{ACTION} && !$attr->{REGISTRATION});

  if ($FORM{add} || $FORM{change}) {
    form_users($attr);
  }
  elsif (!$attr->{USER_INFO}) {
    my $user = Users->new($db, $admin, \%conf);
    $user_info = $user->defaults();

    if ($FORM{COMPANY_ID}) {
      use Customers;
      my $customers = Customers->new($db, $admin, \%conf);
      my $company = $customers->company->info($FORM{COMPANY_ID});
      $user_info->{COMPANY_ID} = $FORM{COMPANY_ID};
      $user_info->{EXDATA} = "<tr><td>$_COMPANY:</td><td>" . (($company->{COMPANY_ID} > 0) ? $html->button($company->{COMPANY_NAME}, "index=13&COMPANY_ID=$company->{COMPANY_ID}", { BUTTON => 1 }) : '') . "</td></tr>\n";
    }

    if ($admin->{GIDS}) {
      $user_info->{GID} = sel_groups();
    }
    elsif ($admin->{GID}) {
      $user_info->{GID} .= $html->form_input('GID', "$admin->{GID}", { TYPE => 'hidden' });
    }
    else {
      $FORM{GID} = $attr->{GID};
      delete $attr->{GID};
      $user_info->{GID} = sel_groups();
    }

    $user_info->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'), { %$attr, CREATE_BILL => ' checked' }, { OUTPUT2RETURN => 1 });
    $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill_add'), { CREATE_EXT_BILL => ' checked' }, { OUTPUT2RETURN => 1 }) if ($conf{EXT_BILL_ACCOUNT});

    if ($user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      $user_info->{DISABLE_MARK} = $html->color_mark($html->b($_DISABLE), $_COLORS[6]);
    }
    else {
      $user_info->{DISABLE} = '';
    }

    my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });
    $main_account .= $html->tpl_show(templates('form_password'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });

    $main_account =~ s/<FORM.+>//ig;
    $main_account =~ s/<\/FORM>//ig;
    $main_account =~ s/<input.+type=submit.+>//ig;
    $main_account =~ s/<input.+index.+>//ig;
    $main_account =~ s/user_form/users_pi/ig;

    user_pi({ MAIN_USER_TPL => $main_account, %$attr });
  }
  else {
    $user_info = $attr->{USER_INFO};
    $FORM{UID} = $user_info->{UID};
    $user_info->{COMPANY_NAME} = $html->color_mark("$_NOT_EXIST ID: $user_info->{COMPANY_ID}", $_COLORS[6]) if ($user_info->{COMPANY_ID} && !$user_info->{COMPANY_NAME});

    if ($permissions{1}) {
      $user_info->{PAYMENTS_BUTTON} = $html->button($_PAYMENTS, "index=2&UID=$LIST_PARAMS{UID}", { CLASS => 'payments rightAlignText' });
    }

    if ($permissions{2}) {
      $user_info->{FEES_BUTTON} = $html->button($_FEES, "index=3&UID=$LIST_PARAMS{UID}", { CLASS => 'fees rightAlignText' });
    }

    $user_info->{EXDATA} = $html->tpl_show(templates('form_user_exdata'), $user_info, { OUTPUT2RETURN => 1 });
    if ($conf{EXT_BILL_ACCOUNT} && $user_info->{EXT_BILL_ID}) {
      $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill'), $user_info, { OUTPUT2RETURN => 1 });
    }

    if ($user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      $user_info->{DISABLE_MARK} = $html->color_mark($html->b($_DISABLE), $_COLORS[6]);

      my $list = $admin->action_list(
        {
          UID       => $user_info->{UID},
          TYPE      => 9,
          PAGE_ROWS => 1,
          SORT      => 1,
          DESC      => 'DESC'
        }
      );
      if ($admin->{TOTAL} > 0) {
        $user_info->{DISABLE_COMMENTS} = $list->[0][3];
      }
    }
    else {
      $user_info->{DISABLE} = '';
    }

    $user_info->{ACTION}     = 'change';
    $user_info->{LNG_ACTION} = $_CHANGE;

    if ($permissions{5}) {
      my $info_field_index = get_function_index('form_info_fields');
      $user_info->{ADD_INFO_FIELD} = $html->button("$_ADD $_INFO_FIELDS", "index=$info_field_index", { CLASS => 'add rightAlignText', ex_params => ' target=_info_fields' });
    }

    if ($permissions{0}{3}) {
      $user_info->{PASSWORD} =
      ($FORM{SHOW_PASSWORD})
      ? "$_PASSWD: '$user_info->{PASSWORD}'"
      : $html->button("$_SHOW $_PASSWD", "index=$index&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1", { BUTTON => 1 }) . ' ' . $html->button("$_CHANGE $_PASSWD", "index=" . get_function_index('form_passwd') . "&UID=$LIST_PARAMS{UID}", { BUTTON => 1 });
    }

    if (in_array('Sms', \@MODULES)) {
      $user_info->{PASSWORD} .= ' ' . $html->button("$_SEND $_PASSWD SMS", "index=$index&header=1&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1&SEND_SMS_PASSWORD=1", { BUTTON => 1, MESSAGE => "$_SEND $_PASSWD SMS ?" });
    }

    if ($attr->{REGISTRATION}) {
      my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });
      $main_account =~ s/<FORM.+>//ig;
      $main_account =~ s/<\/FORM>//ig;
      $main_account =~ s/<input.+type=submit.+>//ig;
      $main_account =~ s/<input.+index.+>//ig;
      $main_account =~ s/user_form/users_pi/ig;
      user_pi({ MAIN_USER_TPL => $main_account, %$attr });
    }
    else {
      $html->tpl_show(templates('form_user'), $user_info);
    }
  }

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
# user_pi()
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  my $user;
  if ($attr->{USER_INFO}) {
    $user = $attr->{USER_INFO};
  }
  else {
    $user = $users->info($FORM{UID});
  }

  if ($FORM{ATTACHMENT}) {
    form_show_attach();
    return 0;
  }
  elsif ($FORM{address}) {
    form_address_sel();
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
      return 0;
    }

    my $user_pi = $user->pi_add({%FORM});
    if (!$user_pi->{errno}) {
      return 0 if ($attr->{REGISTRATION});
      $html->message('info', $_ADDED, "$_ADDED");
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $_ERROR, "$ERR_ACCESS_DENY");
      return 0;
    }

    my $user_pi = $user->pi_change({%FORM});
    if (!$user_pi->{errno}) {
      $html->message('info', $_CHAGED, "$_CHANGED");
    }
  }

  if ($user_pi->{errno}) {
    $html->message('err', $_ERROR, "[$user_pi->{errno}] $err_strs{$user_pi->{errno}}");
  }

  my $user_pi = $user->pi();

  if ($user_pi->{TOTAL} < 1 && $permissions{0}{1}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'add';
      $user_pi->{LNG_ACTION} = $_ADD;
    }
  }
  elsif ($permissions{0}{4}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'change';
      $user_pi->{LNG_ACTION} = $_CHANGE;
    }
    $user_pi->{ACTION} = 'change';
  }

  #Info fields
  my $i = 0;
  foreach my $field_id (@{ $user_pi->{INFO_FIELDS_ARR} }) {
    my ($position, $type, $name, $user_portal) = split(/:/, $user_pi->{INFO_FIELDS_HASH}->{$field_id});

    my $input = '';
    if ($type == 2) {
      $input = $html->form_select(
        "$field_id",
        {
          SELECTED          => $user_pi->{INFO_FIELDS_VAL}->[$i],
          SEL_MULTI_ARRAY   => $user->info_lists_list({ LIST_TABLE => $field_id . '_list' }),
          MULTI_ARRAY_KEY   => 0,
          MULTI_ARRAY_VALUE => 1,
          SEL_OPTIONS       => { 0 => '-N/S-' },
          NO_ID             => 1
        }
      );

    }
    elsif ($type == 4) {
      $input = $html->form_input(
        $field_id,
        1,
        {
          TYPE  => 'checkbox',
          STATE => ($user_pi->{INFO_FIELDS_VAL}->[$i]) ? 1 : undef
        }
      );
    }

    #'ICQ',
    elsif ($type == 8) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 10 });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i] ne '') {

        #
        $input .= " <a href=\"http://www.icq.com/people/about_me.php?uin=$user_pi->{INFO_FIELDS_VAL}->[$i]\"><img  src=\"http://status.icq.com/online.gif?icq=$user_pi->{INFO_FIELDS_VAL}->[$i]&img=21\" border=0></a>";
      }
    }

    #'URL',
    elsif ($type == 9) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 35 })
      . $html->button(
        "$_GO", "",
        {
          GLOBAL_URL => "$user_pi->{INFO_FIELDS_VAL}->[$i]",
          ex_params  => ' target=' . $user_pi->{INFO_FIELDS_VAL}->[$i],
          BUTTON     => 1
        }
      );
    }

    #'PHONE',
    #'E-Mail'
    #'SKYPE'
    elsif ($type == 12) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 20 });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i] ne '') {
        $input .=
        qq{  <script type="text/javascript" src="http://download.skype.com/share/skypebuttons/js/skypeCheck.js"></script>  <a href="skype:abills.support?call"><img src="http://mystatus.skype.com/smallclassic/$user_pi->{INFO_FIELDS_VAL}->[$i]" style="border: none;" width="114" height="20"/></a>};
      }
    }
    elsif ($type == 3) {
      $input = $html->form_textarea($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]");
    }
    elsif ($type == 13) {
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { TYPE => 'file' });
      if ($user_pi->{INFO_FIELDS_VAL}->[$i]) {
        $user_pi->attachment_info({ ID => $user_pi->{INFO_FIELDS_VAL}->[$i], TABLE => $field_id . '_file' });

        $input .= ' ' . $html->button("$user_pi->{FILENAME}, " . int2byte($user_pi->{FILESIZE}), "qindex=" . get_function_index('user_pi') . "&ATTACHMENT=$field_id:$user_pi->{INFO_FIELDS_VAL}->[$i]", { BUTTON => 1 });
      }
    }
    else {
      $user_pi->{INFO_FIELDS_VAL}->[$i] =~ s/\"/&quot;/g;
      $input = $html->form_input($field_id, "$user_pi->{INFO_FIELDS_VAL}->[$i]", { SIZE => 40 });
    }

    $user_pi->{INFO_FIELDS} .= "<tr><td>" . (eval "\"$name\"") . ":</td><td valign=center>$input</td></tr>\n";
    $i++;
  }

  if (in_array('Docs', \@MODULES)) {
    $user_pi->{PRINT_CONTRACT} = $html->button("$_PRINT", "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { ex_params => ' target=new', CLASS => 'print rightAlignText' });

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = "|$user_pi->{CONTRACT_SUFIX}";
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name, $tpl_name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $user_pi->{CONTRACT_TYPE} = " $_TYPE: "
      . $html->form_select(
        'CONTRACT_TYPE',
        {
          SELECTED => $FORM{CONTRACT_SUFIX},
          SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
          NO_ID    => 1
        }
      );
    }
  }

  if ($conf{ACCEPT_RULES}) {
    $user_pi->{ACCEPT_RULES} = ($user_pi->{ACCEPT_RULES}) ? $_YES : $html->color_mark($html->b($_NO), $_COLORS[6]);
  }

  $index = 30 if (!$attr->{MAIN_USER_TPL});
  $user_pi->{PASPORT_DATE} = $html->date_fld2(
    'PASPORT_DATE',
    {
      FORM_NAME => 'users_pi',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      DATE      => $user_pi->{PASPORT_DATE}
    }
  );

  $user_pi->{CONTRACT_DATE} = $html->date_fld2(
    'CONTRACT_DATE',
    {
      FORM_NAME => 'users_pi',
      WEEK_DAYS => \@WEEKDAYS,
      MONTHES   => \@MONTHES,
      DATE      => $user_pi->{CONTRACT_DATE}
    }
  );

  if ($conf{ADDRESS_REGISTER}) {
    my $add_address_index = get_function_index('form_districts');
    $user_pi->{ADD_ADDRESS_LINK} = $html->button("$_ADD $_ADDRESS", "index=$add_address_index", { CLASS => 'add rightAlignText' });
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address_sel'), $user_pi, { OUTPUT2RETURN => 1 });
  }
  else {
    my $countries = $html->tpl_show(templates('countries'), undef, { OUTPUT2RETURN => 1 });
    my @countries_arr = split(/\n/, $countries);
    my %countries_hash = ();
    foreach my $c (@countries_arr) {
      my ($id, $name) = split(/:/, $c);
      $countries_hash{ int($id) } = $name;
    }
    $user_pi->{COUNTRY_SEL} = $html->form_select(
      'COUNTRY_ID',
      {
        SELECTED => $user_pi->{COUNTRY_ID},
        SEL_HASH => { '' => '', %countries_hash },
        NO_ID    => 1
      }
    );
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(templates('form_pi'), { %$attr, UID => $LIST_PARAMS{UID}, %$user_pi, });
}

#**********************************************************
# user_dv
#**********************************************************
sub dv_users {
  my ($attr) = @_;

  $Dv->{UID} = $FORM{UID} || $LIST_PARAMS{UID};
  undef $Dv->{errno};
  if ($FORM{payment_add}) {
    $FORM{COMMENTS} = $FORM{PAYMENT_COMMENT};
    $FORM{add}      = 1;
    my $user = $users->info($Dv->{UID});
    form_payments({ USER_INFO => $user });
    return 0;
  }

  elsif ($FORM{SEARCH}) {    # and $FORM{QUERY} ne '') {
    $pages_qs .= "&SEARCH=1";
    if ($FORM{TYPE} eq 'login') {
      $LIST_PARAMS{LOGIN} = "$FORM{QUERY}*";
    }
    elsif ($FORM{TYPE} eq 'address') {
      if ($FORM{QUERY} =~ /^(\w+).?(\d+)?.?(\d+)?$/) {
        $LIST_PARAMS{ADDRESS_STREET} = $1 || '*';
        $LIST_PARAMS{ADDRESS_BUILD}  = $2 || '*';
        $LIST_PARAMS{ADDRESS_FLAT}   = $3 || '*';
      }
      else {

      }
    }
    elsif ($FORM{TYPE} eq 'contract_id') {
      $LIST_PARAMS{CONTRACT_ID} = "$FORM{QUERY}*";
    }
    elsif ($FORM{TYPE} eq 'phone') {
      $LIST_PARAMS{PHONE} = "$FORM{QUERY}*";
    }
    elsif ($FORM{TYPE} eq 'ip') {
      $LIST_PARAMS{IP} = "$FORM{QUERY}";
    }
    else {
      $error_msg = 1;
    }

    $pages_qs .= "&TYPE=$FORM{TYPE}&QUERY=$FORM{QUERY}";
    $list = $Dv->list({ %LIST_PARAMS, COLS_NAME => 1 });

    if ($Dv->{errno}) {
      $html->message('err', $_ERROR, "[$Dv->{errno}] $err_strs{$Dv->{errno}}");
      return 0;
    }

    my $table = $html->table(
      {
        width      => '100%',
        caption    => "$_SEARCH",
        border     => 1,
        title      => [ '-', $_CONTRACT_ID, $_FIO, $_ADDRESS, $_TARIF_PLAN, $_BALANCE, $_STATUS, '-' ],
        cols_align => [ 'left', 'left', 'right', 'right', 'left', 'center', 'center:noprint', 'center:noprint' ],
        qs         => $pages_qs,
        pages      => $Dv->{TOTAL},
        ID         => 'SEARCH',
        header     => $status_bar
      }
    );

    foreach my $line (@$list) {
      $table->addrow(
        $html->form_input('UID', $line->{uid}, { TYPE => 'checkbox', OUTPUT2RETURN => 1 }) . $line->{id},
        $line->{contract_id},
        $line->{fio},
        $line->{address_street} . ' ' . $line->{address_build} . ' ' . $line->{address_flat},
        $line->{tp_name},
        $line->{deposit},
        $service_status[ $line->{dv_status} ],
        $html->button("$_GO", "index=11&UID=$line->{uid}", { BUTTON => 1 }),
      );
    }

    $OUTPUT{RESULT_TABLE} = $table->show({ OUTPUT2RETURN => 1 });
    $OUTPUT{RESULT_TOTAL} = $Dv->{TOTAL};

    $content = $html->tpl_show(_include('managers_main_content', 'Managers'), {%OUTPUT});
    return 0;
  }

  elsif ($FORM{REGISTRATION_INFO}) {

    # Info
    load_module('Docs', $html);
    my $users = Users->new($db, $admin, \%conf);
    $Dv = $Dv->info($Dv->{UID});
    my $pi = $users->pi({ UID => $Dv->{UID} });
    my $user = $users->info($Dv->{UID}, { SHOW_PASSWORD => $permissions{0}{3} });
    $pi->{ADDRESS_FULL} = "$pi->{ADDRESS_STREET} $pi->{ADDRESS_BUILD}, $pi->{ADDRESS_FLAT}";

    ($Dv->{Y}, $Dv->{M}, $Dv->{D}) = split(/-/, (($pi->{CONTRACT_DATE}) ? $pi->{CONTRACT_DATE} : $DATE), 3);
    $pi->{CONTRACT_DATE_LIT} = "$Dv->{D} " . $MONTHES_LIT[ int($Dv->{M}) - 1 ] . " $Dv->{Y} $_YEAR";

    $Dv->{MONTH_LIT} = $MONTHES_LIT[ int($Dv->{M}) - 1 ];
    if ($Dv->{Y} =~ /(\d{2})$/) {
      $Dv->{YY} = $1;
    }

    if ($FORM{pdf}) {
      print $html->header();
      $html->tpl_show(
        _include('dv_user_info', 'Dv', { pdf => 1 }),
        {
          %$user,
          %$pi,
          DATE => $DATE,
          TIME => $TIME,
          %$Dv,
        }
      );
    }
    else {
      $html->tpl_show(templates('form_user_info'), { %$user, %$pi, DATE => $DATE, TIME => $TIME });
      $html->tpl_show(_include('dv_user_info', 'Dv'), $dv);
    }
    return 0;
  }
  elsif ($FORM{add}) {
    dv_wizard_user();
    return 0;
  }
  elsif ($FORM{change}) {

    #    if ($FORM{IP} eq '0.0.0.0' && $FORM{STATIC_IP_POOL}) {
    #      $FORM{IP} = dv_get_static_ip($FORM{STATIC_IP_POOL});
    #    }

    #    if ($FORM{IP} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ && $FORM{IP} ne '0.0.0.0') {
    #      my $list = $Dv->list({ IP => $FORM{IP} });
    #      if ($Dv->{TOTAL} > 0 && $list->[0][ 6 + $Dv->{SEARCH_FIELDS_COUNT} ] != $FORM{UID}) {
    #        $html->message('err', $_ERROR, "IP: $FORM{IP} $_EXIST. $_LOGIN: " . $html->button("$list->[0][0]", "index=15&UID=" . $list->[0][ 6 + $Dv->{SEARCH_FIELDS_COUNT} ]));
    #        return 0;
    #      }
    #    }

    my @uids_arr = split(/, /, $FORM{UID});

    foreach my $uid (@uids_arr) {
      $FORM{UID} = $uid;
      $Dv->change({%FORM});

      #    $users->{debug}=1;
      $users->change($Dv->{UID}, {%FORM});
      $users->pi_change({%FORM});
    }

    #    if ($FORM{STATUS} == 0) {
    #      my $Shedule = Shedule->new($db, $admin, \%conf);
    #      my $list = $Shedule->list(
    #        {
    #          UID    => $FORM{UID},
    #          MODULE => 'Dv',
    #          TYPE   => 'status',
    #          ACTION => '0'
    #        }
    #      );
    #
    #      if ($Shedule->{TOTAL} == 1) {
    #        $Shedule->del(
    #          {
    #            UID => $FORM{UID},
    #            IDS => $list->[0][14]
    #          }
    #        );
    #      }
    #    }

    if (!$Dv->{errno}) {
      $Dv->{ACCOUNT_ACTIVATE} = $attr->{USER_INFO}->{ACTIVATE};
      if (!$FORM{STATUS} && ($FORM{GET_ABON} || !$FORM{TP_ID})) {

        #  dv_get_month_fee($Dv);
      }

      $html->message('info', "Internet", "$_CHANGED");
      return 0 if ($attr->{REGISTRATION});
    }
  }
  elsif ($FORM{del}) {
    my @uids_arr = split(/, /, $FORM{UID});
    foreach my $uid (@uids_arr) {
      $users->{UID} = $uid;
      $users->del({ UID => $uid });
      if (!$users->{errno}) {
        $html->message('info', $_INFO, "$_DELETED");
        return 0;
      }
    }
  }

  if ($Dv->{errno}) {
    if ($Dv->{errno} == 15) {
      $html->message('err', "Internet:$_ERROR", "$ERR_SMALL_DEPOSIT");
    }
    elsif ($Dv->{errno} == 7) {
      $html->message('err', "Internet:$_ERROR", "$_SERVISE $_EXIST");
      return 1 if ($attr->{REGISTRATION});
    }
    else {
      $html->message('err', "$Dv->{errno} $Dv->{err_str} Internet:$_ERROR", "[$Dv->{errno}] $err_strs{$Dv->{errno}}");
      return 1 if ($attr->{REGISTRATION});
    }
  }

  if ($Dv->{UID}) {
    $list = $Dv->list(
      {
        UID            => $Dv->{UID},
        ADDRESS_STREET => '*',
        ADDRESS_BUILD  => '*',
        ADDRESS_FLAT   => '*',
        CONTRACT_DATE  => '>=0000-00-00',
        CONTRACT_ID    => '*',
        COLS_NAME      => 1,
        COLS_UPPER     => 1,
        PHONE          => '*',
        COMMENTS       => '*'
      }
    );
  }

  $OUTPUT{TP_SEL} = $html->form_select(
    ($Dv->{TP_ID}) ? 'TP_ID' : '4.TP_ID',
    {
      SELECTED => $Dv->{TP_ID} || $FORM{'4.TP_ID'},
      SEL_MULTI_ARRAY   => $Tariffs->list({ MODULE => 'Dv' }),
      MULTI_ARRAY_KEY   => 0,
      MULTI_ARRAY_VALUE => 1,
    }
  );

  if (!$FORM{NEW_USER} && $Dv->{TOTAL} > 0) {
    my $payments_list = $Payments->list(
      {
        UID       => $Dv->{UID},
        COLS_NAME => 1,
        PAGE_ROWS => 6,
        SORT      => 1,
        DESC      => 'desc'
      }
    );

    my $table = $html->table(
      {
        width       => '100%',
        title_plain => [ '#', "$_DATE", "$_SUM", "$_ADMIN", "$_COMMENTS" ],
        cols_align => [ 'right', 'right', 'left', 'left' ],
        pages      => $payments->{TOTAL},
        ID         => 'PAYMENTS'
      }
    );

    foreach my $payment (@$payments_list) {
      $table->addrow($payment->{id}, $payment->{date}, $payment->{sum}, $payment->{admin_name}, $payment->{dsc});
    }

    $OUTPUT{PAYMENT_LIST} = $table->show({ OUTPUT2RETURN => 1 });

    $html->tpl_show(_include('managers_edit_user', 'Managers'), { %OUTPUT, %{ $list->[0] } });

    return 0;

    if ($permissions{0}{10}) {
      $Dv->{CHANGE_TP_BUTTON} = $html->button($_CHANGE, 'UID=' . $Dv->{UID} . '&index=' . get_function_index('dv_chg_tp'), { CLASS => 'change rightAlignText' });
    }

    # Get next payment period
    if (
         $Dv->{MONTH_ABON} > 0
      && !$Dv->{STATUS}
      && !$users->{DISABLE}
      && ( $users->{DEPOSIT} + $users->{CREDIT} > 0
        || $Dv->{POSTPAID_ABON}
        || $Dv->{PAYMENT_TYPE} == 1)
    )
    {

      if ($Dv->{ABON_DISTRIBUTION} && $Dv->{MONTH_ABON} > 0) {
        my $days_to_fees = int(($users->{DEPOSIT} + $users->{CREDIT}) / ($Dv->{MONTH_ABON} / 30));

        $Dv->{NEXT_FEES_WARNING} = "$_SERVICE_ENDED";
        $Dv->{NEXT_FEES_WARNING} =~ s/\%DAYS\%/$days_to_fees/g;
        if ($days_to_fees < 5) {
          $Dv->{NEXT_FEES_WARNING} = $html->color_mark($Dv->{NEXT_FEES_WARNING}, "red");
        }
      }
      else {
        $Dv->{NEXT_FEES_WARNING} = "$_ABON";
        if ($users->{ACTIVATE} ne '0000-00-00') {
          my ($Y, $M, $D) = split(/-/, $users->{ACTIVATE}, 3);
          $M--;
          $Dv->{ABON_DATE} = strftime("%Y-%m-%d", localtime((mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400)));
        }
        else {
          my ($Y, $M, $D) = split(/-/, $DATE, 3);
          if ($conf{START_PERIOD_DAY} && $conf{START_PERIOD_DAY} > $D) {
          }
          else {
            $M++;
          }

          if ($M == 13) {
            $M = 1;
            $Y++;
          }
          if ($conf{START_PERIOD_DAY}) {
            $D = $conf{START_PERIOD_DAY};
          }
          else {
            $D = '01';
          }
          $Dv->{ABON_DATE} = sprintf("%d-%02d-%02d", $Y, $M, $D);
        }
      }
    }

    $Dv->{NETMASK_COLOR} = ($Dv->{NETMASK} ne '255.255.255.255') ? $_COLORS[0] : $_COLORS[1];
    my $shedule_index = get_function_index('dv_sheduler');
    $Dv->{SHEDULE} = $html->button("$_SHEDULE", "UID=$FORM{UID}&Shedule=status&index=" . (($shedule_index) ? $shedule_index : $index + 4), { CLASS => 'shedule rightAlignText' });

    $list = $admin->action_list({ TYPE => '4;14', UID => $FORM{UID}, PAGE_ROWS => 1, DESC => 'desc' });
    if ($admin->{TOTAL} > 0) {
      $list->[0]->[2] =~ /(\d{4}-\d{2}-\d{2})/;
      my $status_date = $1;

      my ($from_year, $from_month, $from_day) = split(/-/, $status_date, 3);
      my ($to_year,   $to_month,   $to_day)   = split(/-/, $DATE,        3);
      my $from_seltime = POSIX::mktime(0, 0, 0, $from_day, ($from_month - 1), ($from_year - 1900));
      my $to_seltime   = POSIX::mktime(0, 0, 0, $to_day,   ($to_month - 1),   ($to_year - 1900));

      my $days = int(($to_seltime - $from_seltime) / 86400);

      $Dv->{STATUS_INFO} = "$_FROM: $status_date ($_DAYS: $days)";
      if ($conf{DV_REACTIVE_PERIOD}) {
        my ($period, $sum) = split(/:/, $conf{DV_REACTIVE_PERIOD});
        $Dv->{STATUS_DAYS}  = $days if ($period < $days);
        $Dv->{REACTIVE_SUM} = $sum  if ($period < $days);
      }
    }

    $Dv->{CALLBACK} = ($Dv->{CALLBACK} == 1) ? ' checked' : '';
    $Dv->{REGISTRATION_INFO} = $html->button("$_REGISTRATION", "index=$index&UID=$Dv->{UID}&REGISTRATION_INFO=1", { BUTTON => 1 });

    if ($conf{DOCS_PDF_PRINT}) {
      $Dv->{REGISTRATION_INFO_PDF} = $html->button("PDF", "qindex=$index&UID=$Dv->{UID}&REGISTRATION_INFO=1&pdf=1", { ex_params => 'target=_new', BUTTON => 1 });
    }
  }

  $Dv->{STATUS_SEL} = $html->form_select(
    'STATUS',
    {
      SELECTED => $Dv->{STATUS} || $FORM{STATUS},
      SEL_ARRAY    => \@service_status,
      STYLE        => \@service_status_colors,
      ARRAY_NUM_ID => 1
    }
  );

  if ($Dv->{STATUS} > 0) {
    $Dv->{STATUS_COLOR} = $service_status_colors[ $Dv->{STATUS} ];
  }

  $OUTPUT{GROUP_SEL} = $html->form_select(
    '1.GID',
    {
      SELECTED          => $FORM{'1.GID'},
      SEL_MULTI_ARRAY   => $users->groups_list({ GIDS => ($admin->{GIDS}) ? $admin->{GIDS} : undef }),
      MULTI_ARRAY_KEY   => 0,
      MULTI_ARRAY_VALUE => 1,
      SEL_OPTIONS       => ($admin->{GIDS}) ? undef : { '' => "$_ALL" },
    }
  );

  $html->tpl_show(_include('managers_add_user', 'Managers'), {%OUTPUT});
  return 0;
}

#*******************************************************************
#
#*******************************************************************
sub dv_wizard_user {
  my ($attr) = @_;

  my $fees = Finance->fees($db, $admin, \%conf);
  $FORM{DV_WIZARD} = 1;

  if ($FORM{print}) {
    require "Abills/modules/Docs/webinterface";
    if ($FORM{PRINT_CONTRACT}) {
      docs_contract({%$Dv});
    }
    else {
      docs_invoice();
    }
    return 0;
  }

  my %add_values = ();

  if ($FORM{add}) {
    foreach my $k (sort %FORM) {
      if ($k =~ m/^[0-9]+\.[_a-zA-Z0-9]+$/) {
        $k =~ s/%22//g;
        my ($id, $main_key) = split(/\./, $k, 2);
        $add_values{$id}{$main_key} = $FORM{$k};
      }
    }

    # Password
    $add_values{1}{GID} = $admin->{GID} if ($admin->{GID});

    my $user = $users->add({ %{ $add_values{1} }, CREATE_EXT_BILL => ((defined($FORM{'5.EXT_BILL_DEPOSIT'}) || $FORM{'1.CREATE_EXT_BILL'}) ? 1 : 0) });
    my $message = '';
    if (!$user->{errno}) {
      $UID  = $user->{UID};
      $user = $user->info($UID);

      #2
      if (defined($FORM{'2.newpassword'})) {#  && $FORM{'2.newpassword'} ne '') {
        if (length($FORM{'2.newpassword'}) < $conf{PASSWD_LENGTH}) {
          $html->message('err', "$_PASSWD : $_ERROR", "$ERR_SHORT_PASSWD");
        }
        #elsif ($FORM{'2.newpassword'} eq $FORM{'2.confirm'}) {
          $add_values{2}{PASSWORD} = $FORM{'2.newpassword'};
          $add_values{2}{UID}      = $UID;
          $add_values{2}{DISABLE}  = $FORM{'1.DISABLE'};
        #}
        #elsif ($FORM{'2.newpassword'} ne $FORM{'2.confirm'}) {
        #  $html->message('err', "$_PASSWD : $_ERROR", "$err_strs{5}");
        #}

        $user->change($UID, { %{ $add_values{2} } });

        if ($conf{external_useradd}) {
          if (!_external($conf{external_useradd}, { LOGIN => $add_values{1}{LOGIN}, %{ $add_values{2} } })) {
            return 0;
          }
        }
      }

      #3 personal info
      $user->pi_add({ UID => "$UID", %{ $add_values{3} } });

      #5 Payments section
      if ($FORM{'5.SUM'}) {
        if ($FORM{'5.SUM'} + 0 > 0) {
          my $er = ($FORM{'5.ER'}) ? $Payments->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
          $Payments->add($user, { %{ $add_values{5} }, ER => $er->{ER_RATE} });

          if ($Payments->{errno}) {
            $html->message('err', "$_PAYMENTS : $_ERROR", "[$Payments->{errno}] $err_strs{$Payments->{errno}}");
            return 0;
          }
          else {
            $message = "$_PAYMENTS $_SUM: $FORM{'5.SUM'} $er->{ER_SHORT_NAME}\n";
          }
        }
        elsif ($FORM{'5.SUM'} + 0 < 0) {
          my $er = ($FORM{'5.ER'}) ? $Payments->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
          $fees->take($user, abs($FORM{'5.SUM'}), { DESCRIBE => 'MIGRATION', ER => $er->{ER_RATE} });

          if ($fees->{errno}) {
            $html->message('err', "$_ERROR : $_FEES", "[$fees->{errno}] $err_strs{$fees->{errno}}");
            return 0;
          }
          else {
            $message = "$_FEES $_SUM: $FORM{'5.SUM'} $er->{ER_SHORT_NAME}\n";
          }
        }
      }

      # Ext bill add
      if ($FORM{'5.EXT_BILL_DEPOSIT'}) {
        $add_values{5}{SUM} = $FORM{'5.EXT_BILL_DEPOSIT'};

        # if Bonus $conf{BONUS_EXT_FUNCTIONS}
        if (in_array('Bonus', \@MODULES) && $conf{BONUS_EXT_FUNCTIONS}) {
          require "Abills/modules/Bonus/webinterface";
          my $Bonus = Bonus->new($db, $admin, \%conf);

          my $sum = $FORM{'5.EXT_BILL_DEPOSIT'};
          %FORM      = %{ $add_values{8} };
          $FORM{UID} = $UID;
          $FORM{SUM} = $sum;
          $FORM{add} = $UID;
          if ($FORM{SUM} < 0) {
            $FORM{ACTION_TYPE} = 1;
            $FORM{SUM}         = abs($FORM{SUM});
          }
          $FORM{SHORT_REPORT} = 1;
          bonus_user_log({ USER_INFO => $user });
        }
        else {
          if ($FORM{'5.EXT_BILL_DEPOSIT'} + 0 > 0) {
            my $er = ($FORM{'5.ER'}) ? $Payments->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
            $Payments->add(
              $user,
              {
                %{ $add_values{5} },
                BILL_ID => $user->{EXT_BILL_ID},
                ER      => $er->{ER_RATE}
              }
            );

            if ($Payments->{errno}) {
              $html->message('err', "$_PAYMENTS : $_ERROR", "[$Payments->{errno}] $err_strs{$Payments->{errno}}");
              return 0;
            }
            else {
              $message = "$_SUM: $FORM{'5.SUM'} $er->{ER_SHORT_NAME}\n";
            }
          }
          elsif ($FORM{'5.EXT_BILL_DEPOSIT'} + 0 < 0) {
            my $er = ($FORM{'5.ER'}) ? $Payments->exchange_info($FORM{'5.ER'}) : { ER_RATE => 1 };
            $fees->take(
              $user,
              abs($FORM{'5.EXT_BILL_DEPOSIT'}),
              {
                BILL_ID  => $user->{EXT_BILL_ID},
                DESCRIBE => 'MIGRATION',
                ER       => $er->{ER_RATE}
              }
            );

            if ($fees->{errno}) {
              $html->message('err', "$_ERROR : $_FEES", "[$fees->{errno}] $err_strs{$fees->{errno}}");
              return 0;
            }
            else {
              $message = "$_SUM: $FORM{'5.EXT_BILL_DEPOSIT'} $er->{ER_SHORT_NAME}\n";
            }
          }
        }
      }

      #4 Dv
      # Make Dv service only with TP
      if ($add_values{4}{TP_ID}) {
        if ($add_values{4}{IP} =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/ && $add_values{4}{IP} ne '0.0.0.0') {
          my $list = $Dv->list({ IP => $add_values{4}{IP} });
          if ($Dv->{TOTAL} > 0 && $list->[0][ 6 + $Dv->{SEARCH_FIELDS_COUNT} ] != $FORM{UID}) {
            $html->message('err', $_ERROR, "IP: $FORM{IP} $_EXIST. \n $_LOGIN: " . $html->button("$list->[0][0]", "index=15&UID=" . $list->[0][ 6 + $Dv->{SEARCH_FIELDS_COUNT} ]));
            return 0;
          }
        }

        my $user_fees;
        $Dv->add({ UID => $UID, %{ $add_values{4} } });
        if ($Dv->{errno}) {
          if ($Dv->{errno} == 15) {
          	$html->message('err', "Dv:$_ERROR", "Dv Modules $ERR_SMALL_DEPOSIT");
          }
          else {
            $html->message('err', "Dv:$_ERROR", "Dv Modules [$Dv->{errno}] $err_strs{$Dv->{errno}}");
          }
          return 0;
        }
#        elsif (! $FORM{SERIAL}) {
#          if (!$add_values{4}{STATUS} && $Dv->{TP_INFO}->{MONTH_FEE} > 0) {
#            $Dv->{UID}              = $UID;
#            $Dv->{ACCOUNT_ACTIVATE} = $add_values{1}{ACTIVATE};
#            $user_fees              = dv_get_month_fee($Dv);
#          }
#        }
      }

#      # Add E-Mail account
#      my $Mail;
#      if (in_array('Mail', \@MODULES) && $FORM{'6.USERNAME'}) {
#        require "Abills/modules/Mail/webinterface";
#        $Mail = Mail->new($db, $admin, \%conf);
#
#        $FORM{'6.newpassword'} = $FORM{'6.PASSWORD'} if ($FORM{'6.PASSWORD'});
#
#        $Mail->mbox_add(
#          {
#            UID => "$UID",
#            %{ $add_values{6} },
#            PASSWORD => $FORM{'6.newpassword'},
#          }
#        );
#        $Mail->{PASSWORD} = $FORM{'6.newpassword'};
#
#        if ($Mail->{errno}) {
#          $html->message('err', "E-MAIL : $_ERROR", "[$Mail->{errno}] $err_strs{$Mail->{errno}}");
#          return 0;
#        }
#        elsif ($FORM{'6.SEND_MAIL'}) {
#          my $message = $html->tpl_show(_include('mail_test_msg', 'Mail'), $Mail, { OUTPUT2RETURN => 1 });
#          sendmail("$conf{ADMIN_MAIL}", "$Mail->{USER_EMAIL}", "Test mail", "$message", "$conf{MAIL_CHARSET}", "");
#        }
#
#        $Mail = $Mail->mbox_info({ MBOX_ID => $Mail->{MBOX_ID} });
#        $Mail->{EMAIL_ADDR} = $Mail->{USERNAME} . '@' . $Mail->{DOMAIN};
#      }
#
#      # Msgs
#      if (in_array('Msgs', \@MODULES) && $add_values{7} && $FORM{'7.SUBJECT'}) {
#        require "Abills/modules/Msgs/webinterface";
#        $FORM{INNER_MSG} = 1;
#        my $Msgs = Msgs->new($db, $admin, \%conf);
#
#        %FORM      = %{ $add_values{7} };
#        $FORM{UID} = $UID;
#        $FORM{add} = $UID;
#        msgs_admin_add({ SEND_ONLY => 1 });
#      }
#
#      # Abon
#      if (in_array('Abon', \@MODULES) && $add_values{9}) {
#        require "Abills/modules/Abon/webinterface";
#        %FORM         = %{ $add_values{9} };
#        $FORM{UID}    = $UID;
#        $FORM{change} = $UID;
#        abon_user({ QUITE => 1 });
#      }

      #Fees wizard form
      if ($add_values{10}) {
        %FORM      = %{ $add_values{10} };
        $FORM{UID} = $UID;
        $FORM{add} = $UID;
        form_fees_wizard({ USER_INFO => $user });
      }

      # Info
      my $dv = $Dv->info($UID);
      my $pi = $user->pi({ UID => $UID });
      $user = $user->info($UID, { SHOW_PASSWORD => 1 });

      if (!$attr->{SHORT_REPORT}) {
        $FORM{ex_message} = $message;
        if (in_array('Docs', \@MODULES)) {
          $message .= "$_CONTRACT: $pi->{CONTRACT_SUFIX}$pi->{CONTRACT_ID}" . $html->button("$_PRINT $_CONTRACT", "qindex=$index&UID=$UID&PRINT_CONTRACT=$UID&print=1" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''), { ex_params => 'target=_new', CLASS => 'print' });
        }

        $html->message('info', $_ADDED, "LOGIN: $add_values{1}{LOGIN}\nUID: $UID\n$message");
        $html->tpl_show(templates('form_user_info'), { %$user, %$pi, DATE => $DATE, TIME => $TIME });
        $dv->{STATUS} = $service_status[ $dv->{STATUS} ];
        $html->tpl_show(_include('dv_user_info', 'Dv'), $dv);
        $html->tpl_show(_include('mail_user_info', 'Mail'), $Mail) if ($Mail);

        #If docs module enable make account
        if (in_array('Docs', \@MODULES) && $FORM{'4.NO_ACCOUNT'}) {
          $LIST_PARAMS{UID} = $UID;

          if ($user_fees->{MONTH_FEE} + $user_fees->{ACTIVATE} > 0) {
            require "Abills/modules/Docs/lng_$html->{language}.pl";
            require "Abills/modules/Docs/webinterface";

            $FORM{DATE}     = $DATE;
            $FORM{CUSTOMER} = $pi->{FIO} || '-';
            $FORM{PHONE}    = $pi->{PHONE};
            $FORM{UID}      = $UID;

            $FORM{'IDS'}     = '1, 2';
            $FORM{'ORDER_1'} = "$_DV";
            $FORM{'COUNT_1'} = 1;
            $FORM{'UNIT_1'}  = 0;
            $FORM{'SUM_1'}   = $user_fees->{MONTH_FEE};

            if ($tariffs->{ACTIV_PRICE}) {
              $FORM{'ORDER_2'} = "$_ACTIVATE";
              $FORM{'COUNT_2'} = 1;
              $FORM{'UNIT_2'}  = 0;
              $FORM{'SUM_2'}   = $user_fees->{MONTH_FEE};
            }

            $FORM{'create'} = 1;
            docs_invoice();
          }
        }
      }

      return $UID;
    }
    else {
      if ($users->{errno} == 7) {
        $html->message('err', "$_ERROR", "$_LOGIN: '$add_values{1}{LOGIN}' $_USER_EXIST");
      }
      else {
        $html->message('err', "[$users->{errno}] $err_strs{$users->{errno}}", "$_LOGIN: '$add_values{1}{LOGIN}'");
      }
      return 0 if ($attr->{SHORT_REPORT});
    }

  }

  #
  #  foreach my $k (keys %FORM) {
  #    next if ($k eq '__BUFFER');
  #    my $val = $FORM{$k};
  #    if ($k =~ /\d+\.([A-Z0-9\_]+)/ig) {
  #      my $key = $1;
  #      $FORM{"$key"} = $val;
  #    }
  #  }
  #
  #  my $users_defaults = $users->defaults();
  #  $users_defaults->{DISABLE} = ($users_defaults->{DISABLE} == 1) ? ' checked' : '';
  #  $users_defaults->{GID} = sel_groups();
  #
  #  #Info fields
  #
  #  if (!$attr->{NO_EXTRADATA}) {
  #    $users_defaults->{EXDATA} = $user_info->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'), { CREATE_BILL => ' checked' }, { OUTPUT2RETURN => 1 });
  #    $users_defaults->{EXDATA} .= $html->tpl_show(templates('form_ext_bill_add'), { CREATE_EXT_BILL => ' checked' }, { OUTPUT2RETURN => 1 }) if ($conf{EXT_BILL_ACCOUNT});
  #  }
  #
  #  my $dv_defaults = $Dv->defaults();
  #  $dv_defaults->{STATUS_SEL} = $html->form_select(
  #    'STATUS',
  #    {
  #      SELECTED => $FORM{STATUS} || undef,
  #      SEL_ARRAY    => \@service_status,
  #      STYLE        => \@service_status_colors,
  #      ARRAY_NUM_ID => 1
  #    }
  #  );
  #
  #  $dv_defaults->{TP_ID} = $html->form_select(
  #    'TP_ID',
  #    {
  #      SELECTED          => $FORM{TP_ID},
  #      SEL_MULTI_ARRAY   => $tariffs->list({ MODULE => 'Dv' }),
  #      MULTI_ARRAY_KEY   => 0,
  #      MULTI_ARRAY_VALUE => 1,
  #    }
  #  );
  #  delete($FORM{TP_ID});
  #  $dv_defaults->{CALLBACK} = '';
  #
  #  my $password_form;
  #  $password_form->{GEN_PASSWORD} = mk_unique_value(8);
  #  $password_form->{PW_CHARS}     = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
  #  $password_form->{PW_LENGTH}    = $conf{PASSWD_LENGTH} || 6;
  #
  #  #Info fields
  #  my %pi_form = ();
  #
  #  my $i = 0;
  #
  #  my $list = $users->config_list({ PARAM => 'ifu*', SORT => 2 });
  #
  #  foreach my $line (@$list) {
  #    my $field_id = '';
  #    if ($line->[0] =~ /ifu(\S+)/) {
  #      $field_id = "3." . $1;
  #      my ($position, $type, $name, $user_portal) = split(/:/, $line->[1]);
  #
  #      my $input = '';
  #      if ($type == 2) {
  #        my $table_name = $field_id;
  #        $table_name =~ s/3\.//;
  #
  #        $input = $html->form_select(
  #          "$field_id",
  #          {
  #            SELECTED          => $FORM{$field_id},
  #            SEL_MULTI_ARRAY   => $users->info_lists_list({ LIST_TABLE => $table_name . '_list' }),
  #            MULTI_ARRAY_KEY   => 0,
  #            MULTI_ARRAY_VALUE => 1,
  #            SEL_OPTIONS       => { 0 => '-N/S-' },
  #            NO_ID             => 1
  #          }
  #        );
  #
  #      }
  #      elsif ($type == 4) {
  #        $input = $html->form_input($field_id, 1, { TYPE => 'checkbox', STATE => ($FORM{$field_id}) ? 1 : undef });
  #      }
  #      elsif ($type == 3) {
  #        $input = $html->form_textarea($field_id, "$users->{INFO_FIELDS_VAL}->[$i]");
  #      }
  #      elsif ($type == 13) {
  #        $input = $html->form_input($field_id, "$users->{INFO_FIELDS_VAL}->[$i]", { TYPE => 'file' });
  #      }
  #      else {
  #        $input = $html->form_input($field_id, "", { SIZE => 40 });
  #      }
  #
  #      $pi_form{INFO_FIELDS} .= "<tr><td>$name:</td><td>$input</td></tr>\n";
  #      $i++;
  #    }
  #  }
  #
  #  if ($conf{DOCS_CONTRACT_TYPES}) {
  #
  #    #PREFIX:SUFIX:NAME;
  #
  #    $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
  #    my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});
  #
  #    my %CONTRACTS_LIST_HASH = ();
  #    foreach my $line (@contract_types_list) {
  #      my ($prefix, $sufix, $name, $tpl_name) = split(/:/, $line);
  #      $prefix =~ s/ //g;
  #      $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
  #    }
  #
  #    $pi_form{CONTRACT_TYPE} = " $_TYPE: "
  #    . $html->form_select(
  #      'CONTRACT_TYPE',
  #      {
  #        SELECTED => '',
  #        SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
  #        NO_ID    => 1
  #      }
  #    );
  #  }
  #
  #  $pi_form{PASPORT_DATE} = $html->date_fld2(
  #    'PASPORT_DATE',
  #    {
  #      FORM_NAME => 'user_form',
  #      WEEK_DAYS => \@WEEKDAYS,
  #      MONTHES   => \@MONTHES,
  #      DATE      => $user_pi->{PASPORT_DATE}
  #    }
  #  );
  #
  #  $pi_form{CONTRACT_DATE} = $html->date_fld2(
  #    'CONTRACT_DATE',
  #    {
  #      FORM_NAME => 'user_form',
  #      WEEK_DAYS => \@WEEKDAYS,
  #      MONTHES   => \@MONTHES,
  #      DATE      => $user_pi->{CONTRACT_DATE}
  #    }
  #  );
  #
  #  if ($conf{ADDRESS_REGISTER}) {
  #    $pi_form{ADDRESS_TPL} = $html->tpl_show(templates('form_address_sel'), $user_pi, { OUTPUT2RETURN => 1 });
  #  }
  #  else {
  #    $pi_form{ADDRESS_TPL} = $html->tpl_show(templates('form_address'), undef, { OUTPUT2RETURN => 1 });
  #  }
  #
  #  $dv_defaults->{JOIN_SERVICE} = '';
  #  $list = $Nas->ip_pools_list({ STATIC => 1 });
  #
  #  $dv_defaults->{STATIC_IP_POOL} = $html->form_select(
  #    'STATIC_IP_POOL',
  #    {
  #      SELECTED          => $FORM{STATIC_POOL},
  #      SEL_MULTI_ARRAY   => [ [ '', '' ], @$list ],
  #      MULTI_ARRAY_KEY   => 8,
  #      MULTI_ARRAY_VALUE => '1',
  #      NO_ID             => 1
  #    }
  #  );
  #
  #  my %tpls = (
  #    "01:$_LOGIN::"  => $html->tpl_show(templates('form_user'),     { %$users_defaults, %FORM }, { OUTPUT2RETURN => 1, ID => 'FORM_USER' }),
  #    "02:$_PASSWD::" => $html->tpl_show(templates('form_password'), { %$password_form,  %FORM }, { OUTPUT2RETURN => 1, ID => 'FORM_PASSWORD' }),
  #    "03:$_INFO::"   => $html->tpl_show(templates('form_pi'),       { %pi_form,         %FORM }, { OUTPUT2RETURN => 1, ID => 'FORM_PI' }),
  #    "04:Internet::" => $html->tpl_show(_include('dv_user', 'Dv'), { %$dv_defaults, %FORM }, { OUTPUT2RETURN => 1, ID => 'DV_USER' }),
  #  );
  #
  #  #Payments
  #  if ($permissions{1} && $permissions{1}{1}) {
  #    $Payments->{SEL_METHOD} = $html->form_select(
  #      'METHOD',
  #      {
  #        SELECTED => $FORM{METHOD} || undef,
  #        SEL_ARRAY    => \@PAYMENT_METHODS,
  #        ARRAY_NUM_ID => 1
  #      }
  #    );
  #    $Payments->{SUM}    = '0.00';
  #    $payments->{SEL_ER} = $html->form_select(
  #      'ER',
  #      {
  #        SELECTED          => undef,
  #        SEL_MULTI_ARRAY   => [ [ '', '', '', '', '' ], @{ $Payments->exchange_list() } ],
  #        MULTI_ARRAY_KEY   => 4,
  #        MULTI_ARRAY_VALUE => '1,2',
  #        NO_ID             => 1
  #      }
  #    );
  #
  #    $tpls{"05:$_PAYMENTS::"} = $html->tpl_show(templates('form_payments'), $payments, { OUTPUT2RETURN => 1, ID => 'FORM_PAYMENTS' });
  #  }
  #
  #  #If mail module added
  #  if (in_array('Mail', \@MODULES)) {
  #    require "Abills/modules/Mail/webinterface";
  #    my $Mail = Mail->new($db, $admin, \%conf);
  #
  #    $Mail->{PASSWORD} = qq{
  #	<tr><td>$_PASSWD:</td><td><input type="password" id="text_pma_pw_mail" name="newpassword" title="$_PASSWD" onchange="pred_password.value = 'userdefined';" /></td></tr>
  #  <tr><td>$_CONFIRM_PASSWD:</td><td><input type="password" name="confirm" id="text_pma_pw2_mail" title="$_CONFIRM" onchange="pred_password.value = 'userdefined';" /></td></tr>
  #  <tr><td>  <input type="button" id="button_generate_password_mail" value="$_GET $_USER $_PASSWD" onclick="CopyInputField('text_pma_pw', 'generated_pw_mail');" />
  #          <input type="button" id="button_copy_password_mail" value="Copy" onclick="CopyInputField('generated_pw_mail', 'text_pma_pw_mail'); CopyInputField('generated_pw_mail', 'text_pma_pw2_mail')" />
  #    </td><td><input type="text" name="generated_pw" id="generated_pw_mail" /></td></tr>
  #     };
  #
  #    $Mail->{SEND_MAIL} = 'checked';
  #
  #    $Mail->{DOMAINS_SEL} = $html->form_select(
  #      'DOMAIN_ID',
  #      {
  #        SELECTED          => $Mail->{DOMAIN_ID},
  #        SEL_MULTI_ARRAY   => $Mail->domain_list(),
  #        MULTI_ARRAY_KEY   => 8,
  #        MULTI_ARRAY_VALUE => 0,
  #        SEL_OPTIONS       => { 0 => '-N/S-' },
  #        NO_ID             => 1
  #      }
  #    );
  #
  #    $tpls{"06:E-Mail::"} = $html->tpl_show(_include('mail_box', 'Mail'), $Mail, { OUTPUT2RETURN => 1, ID => 'MAIL_BOX' });
  #  }
  #
  #  #If msgs module added
  #  if (in_array('Msgs', \@MODULES) && !defined($FROM{CARDS_FORM})) {
  #    require "Abills/modules/Msgs/webinterface";
  #    my $Msgs = Msgs->new($db, $admin, \%conf);
  #    $FORM{UID} = -1;
  #    $tpls{"07:$_MESSAGE::"} = msgs_admin_add({ OUTPUT2RETURN => 1 });
  #  }
  #
  #  $tpls{"10:$_FEES::"} = form_fees_wizard({ OUTPUT2RETURN => 1 });
  #
  #  if ($attr->{TPLS}) {
  #    while (my ($k, $v) = each %{ $attr->{TPLS} }) {
  #      $tpls{$k} = $v;
  #    }
  #  }
  #
  #  my $wizard;
  #
  #  my $template         = '';
  #  my @sorted_templates = sort keys %tpls;
  #
  #  foreach my $key (@sorted_templates) {
  #    my ($n, $descr, $pre, $post) = split(/:/, $key, 4);
  #    $n = int($n);
  #    $template .= "<tr class='title_color'><th>$descr</th></tr>\n";
  #    my $sub_tpl .= $html->tpl_show($tpls{"$key"}, $wizard, { OUTPUT2RETURN => 1, ID => "$descr" });
  #    $sub_tpl =~ s/(<input .*?UID.*?>)//gi;
  #    $sub_tpl =~ s/(<input .*?index.*?>)//gi;
  #    $sub_tpl =~ s/name=[\'\"]?([A-Z_0-9]+)[\'\"]? /name=$n.$1 /ig;
  #    my $class = ($n % 2) ? 'odd' : 'even';
  #    $template .= "<tr><th class=$class align=center>" . $sub_tpl . "</th></tr>\n";
  #  }
  #
  #  $template =~ s/(<form .*?>)//gi;
  #  $template =~ s/<\/form>//ig;
  #  $template =~ s/(<input .*?type=submit.*?>)//gi;
  #  $template =~ s/<hr>//gi;
  #
  #  $template = "<table width=\"100%\">$template</table>";
  #  if ($attr->{OUTPUT2RETURN}) {
  #    return $template;
  #  }
  #
  #  print $html->form_main(
  #    {
  #      CONTENT => $template,
  #      HIDDEN  => { index => "$index" },
  #      SUBMIT  => { add => "$_ADD" },
  #      NAME    => 'user_form',
  #      ENCTYPE => 'multipart/form-data'
  #    }
  #  );

}

#**********************************************************
# form_payments
#**********************************************************
sub form_payments () {
  my ($attr) = @_;

  use Finance;
  my $payments = Finance->payments($db, $admin, \%conf);

  %PAYMENTS_METHODS = ();
  my %BILL_ACCOUNTS = ();

  if ($FORM{print}) {
    load_module('Docs', $html);
    if ($FORM{INVOICE_ID}) {
      docs_invoice({%FORM});
    }
    else {
      docs_receipt({%FORM});
    }
    exit;
  }

  if ($attr->{USER_INFO}) {
    my $user = $attr->{USER_INFO};
    $payments->{UID} = $user->{UID};

    if ($conf{EXT_BILL_ACCOUNT}) {
      $BILL_ACCOUNTS{ $user->{BILL_ID} }     = "$_PRIMARY : $user->{BILL_ID}"   if ($user->{BILL_ID});
      $BILL_ACCOUNTS{ $user->{EXT_BILL_ID} } = "$_EXTRA : $user->{EXT_BILL_ID}" if ($user->{EXT_BILL_ID});
    }

    if (in_array('Docs', \@MODULES)) {
      $FORM{QUICK} = 1;
      load_module('Docs', $html);
    }

    if (!$attr->{REGISTRATION}) {
      if ($user->{BILL_ID} < 1) {
        form_bills({ USER_INFO => $user });
        return 0;
      }
    }

    if (defined($FORM{OP_SID}) and $FORM{OP_SID} eq $COOKIES{OP_SID}) {
      $html->message('err', $_ERROR, "$_EXIST");
    }
    elsif ($FORM{add} && $FORM{SUM}) {
      $FORM{SUM} =~ s/,/\./g;
      if ($FORM{SUM} !~ /[0-9\.]+/) {
        $html->message('err', $_ERROR, "$ERR_WRONG_SUM");
        return 1 if ($attr->{REGISTRATION});
      }
      else {
        $FORM{CURRENCY} = $conf{SYSTEM_CURRENCY};

        if ($FORM{ER}) {
          if ($FORM{DATE}) {
            my $list = $payments->exchange_log_list(
              {
                DATE      => "<=$FORM{DATE}",
                ID        => $FORM{ER},
                SORT      => 'date',
                DESC      => 'desc',
                PAGE_ROWS => 1
              }
            );
            $FORM{ER}       = $list->[0]->[2] || 1;
            $FORM{CURRENCY} = $list->[0]->[4] || 0;
          }
          else {
            my $er = $payments->exchange_info($FORM{ER});
            $FORM{ER}       = $er->{ER_RATE};
            $FORM{CURRENCY} = $er->{ISO};
          }
        }

        if ($FORM{ER} && $FORM{ER} != 1) {
          $FORM{PAYMENT_SUM} = sprintf("%.2f", $FORM{SUM} / $FORM{ER});
        }
        else {
          $FORM{PAYMENT_SUM} = $FORM{SUM};
        }

        #Make pre payments functions in all modules
        cross_modules_call('_pre_payment', {%$attr});

        if (!$conf{PAYMENTS_NOT_CHECK_INVOICE_SUM} && ($FORM{INVOICE_SUM} && $FORM{INVOICE_SUM} != $FORM{PAYMENT_SUM})) {
          $html->message('err', "$_PAYMENTS: $ERR_WRONG_SUM", " $_INVOICE $_SUM: $Docs->{TOTAL_SUM}\n $_PAYMENTS $_SUM: $FORM{SUM}");
        }
        else {
          $payments->add($user, { %FORM, INNER_DESCRIBE => $FORM{INNER_DESCRIBE} . (($FORM{DATE} && $COOKIES{hold_date}) ? " $DATE $TIME" : '') });

          if ($payments->{errno}) {
            if ($payments->{errno} == 12) {
              $html->message('err', $_ERROR, "$ERR_WRONG_SUM");
            }
            elsif ($payments->{errno} == 14) {
              $html->message('err', $_ERROR, "$_BILLS $_NOT_EXIST");
            }
            else {
              $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");
            }
            return 1 if ($attr->{REGISTRATION});
          }
          else {
            $FORM{SUM} = $payments->{SUM};
            $html->message('info', $_PAYMENTS, "$_ADDED $_SUM: $FORM{SUM} $er->{ER_SHORT_NAME}");

            if ($conf{external_payments}) {
              if (!_external($conf{external_payments}, {%FORM})) {
                return 0;
              }
            }

            #Make cross modules Functions
            $attr->{USER_INFO}->{DEPOSIT} += $FORM{SUM};
            $FORM{PAYMENTS_ID} = $payments->{PAYMENT_ID};
            cross_modules_call('_payments_maked', { %$attr, PAYMENT_ID => $payments->{PAYMENT_ID} });
          }
        }
      }
    }
    elsif ($FORM{del} && $FORM{is_js_confirmed}) {
      if (!defined($permissions{1}{2})) {
        $html->message('err', $_ERROR, "[13] $err_strs{13}");
        return 0;
      }

      $payments->del($user, $FORM{del});
      if ($payments->{errno}) {
        $html->message('err', $_ERROR, "[$payments->{errno}] $err_strs{$payments->{errno}}");
      }
      else {
        $html->message('info', $_PAYMENTS, "$_DELETED ID: $FORM{del}");
      }
    }

    return 0 if ($attr->{REGISTRATION} && $FORM{add});

    #exchange rate sel

    my $er_list   = $payments->exchange_list({%FORM});
    my %ER_ISO2ID = ();
    foreach my $line (@$er_list) {
      $ER_ISO2ID{ $line->[3] } = $line->[5];
    }

    if (!$FORM{ER} && $FORM{ISO}) {
      $FORM{ER} = $ER_ISO2ID{ $FORM{ISO} };
    }

    $payments->{SEL_ER} = $html->form_select(
      'ER',
      {
        SELECTED          => $FORM{ER},
        SEL_MULTI_ARRAY   => [ [ '', '', '', '', '', '' ], @{$er_list} ],
        MULTI_ARRAY_KEY   => 5,
        MULTI_ARRAY_VALUE => '1,2',
        NO_ID             => 1,
        MAIN_MENU         => get_function_index('form_exchange_rate'),
        MAIN_MENU_AGRV    => "chg=$FORM{ER}"
      }
    );

    push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

    for (my $i = 0 ; $i <= $#PAYMENT_METHODS ; $i++) {
      $PAYMENTS_METHODS{"$i"} = "$PAYMENT_METHODS[$i]";
    }

    my %PAYSYS_PAYMENT_METHODS = %{ cfg2hash($conf{PAYSYS_PAYMENTS_METHODS}) };

    while (my ($k, $v) = each %PAYSYS_PAYMENT_METHODS) {
      $PAYMENTS_METHODS{$k} = $v;
    }

    $payments->{SEL_METHOD} = $html->form_select(
      'METHOD',
      {
        SELECTED => (defined($FORM{METHOD}) && $FORM{METHOD} ne '') ? $FORM{METHOD} : 0,
        SEL_HASH => \%PAYMENTS_METHODS,
        NO_ID    => 1,

        #SORT_KEY     => 1
      }
    );

    if ($permissions{1} && $permissions{1}{1}) {
      $payments->{OP_SID} = mk_unique_value(16);

      if ($conf{EXT_BILL_ACCOUNT}) {
        $payments->{EXT_DATA} = "<tr><td colspan=2>$_BILL:</td><td>"
        . $html->form_select(
          'BILL_ID',
          {
            SELECTED => $FORM{BILL_ID} || $attr->{USER_INFO}->{BILL_ID},
            SEL_HASH => \%BILL_ACCOUNTS,
            NO_ID    => 1
          }
        ) . "</td></tr>\n";
      }

      if ($permissions{1}{4}) {
        if ($COOKIES{hold_date}) {
          ($DATE, $TIME) = split(/ /, $COOKIES{hold_date}, 2);
        }

        if ($FORM{DATE}) {
          ($DATE, $TIME) = split(/ /, $FORM{DATE});
        }

        my $date_field = $html->date_fld2('DATE', { DATE => $DATE, TIME => $TIME, MONTHES => \@MONTHES, FORM_NAME => 'user', WEEK_DAYS => \@WEEKDAYS });
        $payments->{DATE} = "<tr><td colspan=2>$_DATE:</td><td>$date_field  $_HOLD: <input type=checkbox name=hold_date value=1 " . (($COOKIES{hold_date}) ? 'checked' : '') . "> </td></tr>\n";
      }

      if (in_array('Docs', \@MODULES)) {
        $payments->{INVOICE_SEL} = $html->form_select(
          "INVOICE_ID",
          {
            SELECTED                 => $FORM{INVOICE_ID},
            SEL_MULTI_ARRAY          => $Docs->invoices_list({ UID => $user->{UID}, PAYMENT_ID => 0, PAGE_ROWS => 100, SORT => 2, DESC => 'DESC' }),
            MULTI_ARRAY_KEY          => 13,
            MULTI_ARRAY_VALUE        => '0,1,3',
            MULTI_ARRAY_VALUE_PREFIX => "$_NUM: ,$_DATE: ,$_SUM:",
            SEL_OPTIONS => { 0 => '', (!$conf{PAYMENTS_NOT_CREATE_INVOICE}) ? (create => $_CREATE) : undef },
            NO_ID       => 1,
            MAIN_MENU   => get_function_index('docs_invoices_list'),
            MAIN_MENU_AGRV => "UID=$FORM{UID}&INVOICE_ID=$FORM{INVOICE_ID}"
          }
        );

        $payments->{DOCS_INVOICE_RECEIPT_ELEMENT} = $html->tpl_show(_include('docs_create_invoice_receipt', 'Docs'), {%$payments}, { OUTPUT2RETURN => 1 });
      }

      if ($attr->{ACTION}) {
        $payments->{ACTION}     = $attr->{ACTION};
        $payments->{LNG_ACTION} = $attr->{LNG_ACTION};
      }
      else {
        $payments->{ACTION}     = 'add';
        $payments->{LNG_ACTION} = $_ADD;
      }

      $html->tpl_show(templates('form_payments'), { %FORM, %$attr, %$payments });

      #return 0 if ($attr->{REGISTRATION});
    }
  }
  elsif ($FORM{AID} && !defined($LIST_PARAMS{AID})) {
    $FORM{subf} = $index;
    form_admins();
    return 0;
  }

  #  elsif ($FORM{UID}) {
  #    $index = get_function_index('form_payments');
  #    form_users();
  #    return 0;
  #  }
  #  elsif ($index != 7) {
  #    $FORM{type} = $FORM{subf} if ($FORM{subf});
  #    form_search(
  #      {
  #        HIDDEN_FIELDS => {
  #          subf => ($FORM{subf}) ? $FORM{subf} : undef,
  #          COMPANY_ID => $FORM{COMPANY_ID}
  #        },
  #        ID => 'SEARCH_PAYMENTS'
  #      }
  #    );
  #  }

  #return 0 if (!$permissions{1}{0});

  if (!defined($FORM{sort})) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = DESC;
  }

  $LIST_PARAMS{ID} = $FORM{ID} if ($FORM{ID});

  my @caption = ('ID', $_LOGIN, $_DATE, $_DESCRIBE, $_SUM, $_DEPOSIT, $_PAYMENT_METHOD, 'EXT ID', "$_BILL", $_ADMINS, 'IP');

  if ($conf{SYSTEM_CURRENCY}) {
    push @caption, "$_ALT $_SUM", "$_CURRENCY";
  }

  push @caption, '-';

  my $payments_list = $payments->list({ %LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$_PAYMENTS",
      border     => 1,
      title      => \@caption,
      cols_align => [ 'right', 'left', 'right', 'right', 'left', 'left', 'right', 'right', 'left', 'left', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $payments->{TOTAL},

      #EXPORT     => ' XML:&xml=1',
      ID => 'PAYMENTS'
    }
  );

  my $pages_qs .= "&subf=2" if (!$FORM{subf});
  foreach my $payment (@$payments_list) {
    my $delete = ($permissions{1}{2}) ? $html->button($_DEL, "index=2&del=$payment->{id}&UID=$payment->{uid}$pages_qs", { MESSAGE => "$_DEL [$payment->{id}] ?", CLASS => 'del' }) : '';

    my @rows = (
      $html->b($payment->{id}),
      $html->button($payment->{login}, "index=15&UID=$payment->{uid}"),
      $payment->{date}, $payment->{dsc} . (($payment->{inner_describe}) ? $html->br() . $html->b($payment->{inner_describe}) : ''),
      $payment->{sum}, "$payment->{last_deposit}", $PAYMENTS_METHODS{ $payment->{method} },
      "$payment->{ext_id}", ($conf{EXT_BILL_ACCOUNT} && $attr->{USER_INFO}) ? $BILL_ACCOUNTS{ $payment->{bill_id} } : "$payment->{bill_id}",
      "$payment->{admin_name}", "$payment->{ip}"
    );

    if ($conf{SYSTEM_CURRENCY}) {
      push @rows, $payment->{amount}, $payment->{currency};
    }

    push @rows, $delete;
    $table->addrow(@rows);
  }

  print $table->show();

  if (!$admin->{MAX_ROWS}) {
    $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'right', 'right', 'right', 'right', 'right' ],
        rows       => [ [ "$_TOTAL:", $html->b($payments->{TOTAL}), "$_USERS:", $html->b($payments->{TOTAL_USERS}), "$_SUM", $html->b($payments->{SUM}) ] ],
        rowcolor   => 'even'
      }
    );
    print $table->show();
  }

}

#**********************************************************
# form_login
#**********************************************************
sub form_login {
  my %first_page = ();

  if ($conf{tech_works}) {
    $html->message('info', $_INFO, "$conf{tech_works}");
    return 0;
  }

  #Make active lang list
  if ($conf{LANGS}) {
    $conf{LANGS} =~ s/\n//g;
    my (@lang_arr) = split(/;/, $conf{LANGS});
    %LANG = ();
    foreach my $l (@lang_arr) {
      my ($lang, $lang_name) = split(/:/, $l);
      $lang =~ s/^\s+//;
      $LANG{$lang} = $lang_name;
    }
  }

  my %QT_LANG = (
    byelorussian => 22,
    bulgarian    => 20,
    english      => 31,
    french       => 37,
    polish       => 90,
    russian      => 96,
    ukraine      => 129,
  );

  $first_page{SEL_LANGUAGE} = $html->form_select(
    'language',
    {
      EX_PARAMS  => 'onChange="selectLanguage()"',
      SELECTED   => $html->{language},
      SEL_HASH   => \%LANG,
      NO_ID      => 1,
      EXT_PARAMS => { qt_locale => \%QT_LANG }
    }
  );
  
  $first_page{TITLE}="Manager Form";
  
  $OUTPUT{BODY} = $html->tpl_show(templates('form_client_login'), \%first_page);
}

1

