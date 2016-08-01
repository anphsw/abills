#!/usr/bin/perl

=head1 NAME

 ABillS User Web interface

=cut


use strict;
use warnings;

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/modules/",
    $libpath . '/lib/',
    $libpath
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::Defs;
use Abills::Base;
use Users;
use Finance;
use Admins;
use Conf;
use POSIX qw(mktime strftime);
our (%LANG,
  %lang,
  @MONTHES,
  @WEEKDAYS
);

do "../libexec/config.pl";

$conf{web_session_timeout} = ($conf{web_session_timeout}) ? $conf{web_session_timeout} : '86400';

our $html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  }
);

our $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

if($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

do $libpath . "/language/$html->{language}.pl";
our $sid = $FORM{sid} || $COOKIES{sid} || '';    # Session ID
$html->{CHARSET} = $CHARSET if ($CHARSET);

our $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} ? $conf{USERS_WEB_ADMIN_ID} : $conf{SYSTEM_ADMIN_ID},
                 { DOMAIN_ID => $FORM{DOMAIN_ID},
                   IP        => $ENV{REMOTE_ADDR},
                   SHORT     => 1 });

our $Conf = Conf->new($db, $admin, \%conf);

$admin->{SESSION_IP} = $ENV{REMOTE_ADDR};
$conf{WEB_TITLE}     = $admin->{DOMAIN_NAME} if ($admin->{DOMAIN_NAME});

require Abills::Misc;
require Abills::Templates;
$html->{METATAGS} = templates('metatags_client');

my $uid    = 0;
my %OUTPUT = ();
my $login  = $FORM{user} || '';
my $passwd = $FORM{passwd} || '';
my $default_index;
our %module;
my %menu_args;

delete($conf{PASSWORDLESS_ACCESS}) if ($FORM{xml});

our $user = Users->new($db, $admin, \%conf);

if ($FORM{SHOW_MESSAGE}) {
  ($uid, $sid, $login) = auth("$login", "$passwd", "$sid", { PASSWORDLESS_ACCESS => 1 });

  $admin->{sid} = $sid;

  if($uid) {
    load_module('Msgs', $html);
    msgs_show_last({ UID => $uid });

    print $html->header();
    $OUTPUT{BODY} = "$html->{OUTPUT}";
    print $html->tpl_show(templates('form_client_start'), \%OUTPUT, { MAIN => 1,
                                                                      ID   => 'form_client_start' });

    exit;
  }
  else {
    $html->message( 'err', $lang{ERROR}, "IP not found" );
  }
}

my @service_status = ("$lang{ENABLE}", "$lang{DISABLE}", "$lang{NOT_ACTIVE}", "$lang{HOLD_UP}",
  "$lang{DISABLE}: $lang{NON_PAYMENT}", "$lang{ERR_SMALL_DEPOSIT}",
  "$lang{VIRUS_ALERT}" );

($uid, $sid, $login) = auth("$login", "$passwd", "$sid");

#Cookie section ============================================
$html->set_cookies('OP_SID', "$FORM{OP_SID}", "", $html->{web_path}) if ($FORM{OP_SID});
if ($sid) {
  $html->set_cookies('sid', "$sid", "", '/');
  $FORM{sid}=$sid;
  $COOKIES{sid}=$sid;
}
#===========================================================

if(($conf{PORTAL_START_PAGE} && !($uid > 0)) || $FORM{article} || $FORM{menu_category}){

  print "Content-Type: text/html\n\n";
  load_module('Portal', $html);
  my $wrong_passwd = 0;

  if($FORM{user} && $FORM{passwd}){
    $wrong_passwd = 1;
  }
  portal_s_page($wrong_passwd);
  exit;
}

if ($uid > 0) {
  $default_index = 10;

#  #Quick Amon Alive Update
#  # $ENV{HTTP_USER_AGENT} =~ /^AMon /
#  if ($FORM{ALIVE}) {
#    load_module('Ipn', $html);
#    print $html->header();
#    $LIST_PARAMS{LOGIN} = $user->{LOGIN};
#    ipn_user_activate();
#    $OUTPUT{BODY} = $html->{OUTPUT};
#    print $html->tpl_show(templates('form_client_start'), \%OUTPUT, { MAIN => 1,
#                                                                      ID   => 'form_client_start' });
#    exit;
#  }

  if ($FORM{REFERER} && $FORM{REFERER} =~ /$SELF_URL/ && $FORM{REFERER} !~ /index=1000/) {
    print "Location: $FORM{REFERER}\n\n";
    exit;
  }

  accept_rules() if ($conf{ACCEPT_RULES});

  fl();

  if (!$conf{PASSWORDLESS_ACCESS}) {
    $menu_names{1000}    = "$lang{LOGOUT}";
    $functions{1000}     = 'logout';
    $menu_items{1000}{0} = $lang{LOGOUT};
  }

  $html->{SID} = $sid;
  $OUTPUT{FORM_COLORS}=change_color();

  if ($FORM{get_index}) {
    $index = get_function_index($FORM{get_index});
    $FORM{index}=$index;
  }

  if (!$FORM{pdf} && -f '../Abills/templates/_form_client_custom_menu.tpl') {
    $OUTPUT{MENU} = $html->tpl_show(templates('form_client_custom_menu'), $user, { OUTPUT2RETURN => 1,
                                                                                   ID            => 'form_client_custom_menu'  });
  }
  else {
    (undef, $OUTPUT{MENU}) = $html->menu2(
      \%menu_items,
      \%menu_args,
      undef,
      {
        EX_ARGS         => "&sid=$sid",
        ALL_PERMISSIONS => 1,
        FUNCTION_LIST   => \%functions,
        SKIP_HREF       => 1
      }
    );
  }

  if ($html->{ERROR}) {
    $html->message( 'err', $lang{ERROR}, $html->{ERROR} );
    exit;
  }

  $OUTPUT{DATE}  = $DATE;
  $OUTPUT{TIME}  = $TIME;
  $OUTPUT{LOGIN} = $login;
  $OUTPUT{IP}    = $ENV{REMOTE_ADDR};
  $pages_qs      = "&UID=$user->{UID}&sid=$sid";
  $OUTPUT{STATE} = ($user->{DISABLE}) ? $html->color_mark( $lang{DISABLE}, $_COLORS[6] ) : $lang{ENABLE};
  $OUTPUT{STATE_CODE}=$user->{DISABLE};

  if ($COOKIES{lastindex}) {
    $index = int($COOKIES{lastindex});
    $html->set_cookies('lastindex', '', "Fri, 1-Jan-2038 00:00:01", $html->{web_path});
  }

  $LIST_PARAMS{UID}   = $user->{UID};
  $LIST_PARAMS{LOGIN} = $user->{LOGIN};

  $index = int($FORM{qindex}) if ($FORM{qindex} && $FORM{qindex} =~ /^\d+$/);
  print $html->header(\%FORM) if ($FORM{header});

  if ($FORM{qindex}) {

    if ($FORM{qindex} eq '100002'){
      form_events();
      exit ( 0 );
    }
    elsif ($FORM{qindex} eq '100001'){
      load_module("Msgs", $html);
      msgs_register_push_client({ UID => $user->{UID} });
      exit( 0 );
    }
    elsif($FORM{qindex} eq '30'){
      require "Abills/main/Address_mng.pm";
      form_address_sel();
    }
    else {
      if (defined($module{ $FORM{qindex} })) {
        load_module($module{ $FORM{qindex} }, $html);
      }

      _function( $FORM{qindex} );
    }

    print ($html->{OUTPUT} || q{});
    exit;
  }

  if (defined($module{$index})) {
    load_module($module{$index}, $html);
  }

  if (defined($functions{$index})) {
    if ($functions{$default_index} eq 'msgs_admin') {
      _function($default_index);
    }
    else {
   	  _function($index || 10 );
    }
  }
  else {
  	_function($default_index);
  }

  $OUTPUT{BODY} = $html->{OUTPUT};
  $html->{OUTPUT} = '';
  if ($conf{AMON_UPDATE} && $ENV{HTTP_USER_AGENT} =~ /AMon \[(\S+)\]/) {
    my $user_version = $1;
    my ($u_url, $u_version, $u_checksum) = split(/\|/, $conf{AMON_UPDATE}, 3);
    if ($u_version > $user_version) {
      $OUTPUT{BODY} = "<AMON_UPDATE url=\"$u_url\" version=\"$u_version\" checksum=\"$u_checksum\" />\n" . $OUTPUT{BODY};
    }
  }

  $OUTPUT{STATE} = (! $user->{DISABLE} && $user->{SERVICE_STATUS}) ? $service_status[$user->{SERVICE_STATUS}] : $OUTPUT{STATE};

  $OUTPUT{BODY} = $html->tpl_show(templates('form_client_main'), \%OUTPUT, { MAIN  => 1,
                                                                             ID    => 'form_client_main',
                                                                             SKIP_D=> 1
                                                                            });
}
else {
  form_login();
}

print $html->header();
$OUTPUT{BODY} = $html->{OUTPUT};

print $html->tpl_show(templates('form_client_start'), \%OUTPUT, { MAIN => 1,
                                                                  });

$html->fetch();

$html->test() if ($conf{debugmods} =~ /LOG_DEBUG/);

#**********************************************************
=head2 logout()

=cut
#**********************************************************
sub logout {

 return 1;
}

#**********************************************************
=head2 form_info($attr) User main information

=cut
#**********************************************************
sub form_info {
  $admin->{SESSION_IP} = $ENV{REMOTE_ADDR};
  my $Payments = Finance->payments($db, $admin, \%conf);

  my $tp_credit = 0;

  my ($sum, $days, $price, $month_changes, $payments_expr) = split(/:/, $conf{user_credit_change} || q{});
  if (in_array('Dv', \@MODULES) && defined($sum) && $sum =~ /\d+/ && $sum == 0) {
    load_module('Dv', $html);
    my $Dv = Dv->new($db, $admin, \%conf);
    $Dv->info($user->{UID});
    $tp_credit = $Dv->{USER_CREDIT_LIMIT};
  }

  if ($FORM{PRINT_CONTRACT}) {
    $FORM{UID} = $LIST_PARAMS{UID};
    load_module('Docs', $html);
    docs_contract();
    return 0;
  }

  #Credit functions
  elsif ($conf{user_credit_change}) {
    $month_changes = 0 if (!$month_changes);
    my $credit_date = POSIX::strftime("%Y-%m-%d", localtime(time + int($days) * 86400));

    if (in_array('Dv', \@MODULES) && $sum == 0) {
      $sum = $tp_credit if ($tp_credit > 0);
    }

    if ($month_changes) {
      my ($y, $m) = split(/\-/, $DATE);
      $admin->action_list(
        {
          UID       => $user->{UID},
          TYPE      => 5,
          AID       => $admin->{AID},
          FROM_DATE => "$y-$m-01",
          TO_DATE   => "$y-$m-31"
        }
      );

      if ($admin->{TOTAL} >= $month_changes) {
        $user->{CREDIT_CHG_BUTTON} = $html->color_mark("$lang{ERR_CREDIT_CHANGE_LIMIT_REACH}. $lang{TOTAL}: $admin->{TOTAL}/$month_changes", 'bg-danger');
        $sum = -1;
      }
    }
    $user->{CREDIT_SUM} = sprintf("%.2f", $sum);

    #PERIOD=days;MAX_CREDIT_SUM=sum;MIN_PAYMENT_SUM=sum;
    if ($payments_expr && $sum != -1) {
      my %params = (
        PERIOD          => 0,
        MAX_CREDIT_SUM  => 1000,
        MIN_PAYMENT_SUM => 1,
        PERCENT         => 100
      );
      my @params_arr = split(/;/, $payments_expr);

      foreach my $line (@params_arr) {
        my ($k, $v) = split(/=/, $line);
        $params{$k} = $v;
      }

      $Payments->list(
        {
          UID          => $user->{UID},
          PAYMENT_DAYS => ">$params{PERIOD}",
          SUM          => ">=$params{MIN_PAYMENT_SUM}"
        }
      );

      if ($Payments->{TOTAL} > 0) {
        $sum = $Payments->{SUM} / 100 * $params{PERCENT};
        if ($sum > $params{MAX_CREDIT_SUM}) {
          $sum = $params{MAX_CREDIT_SUM};
        }
      }
      else {
        $sum = 0;
      }
    }

    $user->group_info($user->{GID});

    if ($user->{TOTAL} > 0 && !$user->{ALLOW_CREDIT}) {
      $FORM{change_credit} = 0;
    }
    elsif ($user->{DISABLE}) {
    }
    elsif ($user->{CREDIT} < sprintf("%.2f", $sum)) {
      if ($FORM{change_credit}) {
        $user->change(
          $user->{UID},
          {
            UID         => $user->{UID},
            CREDIT      => $sum,
            CREDIT_DATE => $credit_date
          }
        );

        if (!$user->{errno}) {
          $html->message('info', "$lang{CHANGED}", " $lang{CREDIT}: $sum");
          if ($price && $price > 0) {
            my $Fees = Finance->fees($db, $admin, \%conf);
            $Fees->take($user, $price, { DESCRIBE => "$lang{CREDIT} $lang{ENABLE}" });
          }

          cross_modules_call(
            '_payments_maked',
            {
              USER_INFO => $user,
              SUM       => $sum,
              QUITE     => 1
            }
          );

          if ($conf{external_userchange}) {
            if (!_external($conf{external_userchange}, $user)) {
              return 0;
            }
          }

          $user->info($user->{UID});
        }
      }
      else {
        $user->{CREDIT_CHG_PRICE} = sprintf("%.2f", $price);
        $user->{CREDIT_SUM}       = sprintf("%.2f", $sum);
        $user->{CREDIT_CHG_BUTTON} = $html->button(
          "$lang{SET} $lang{CREDIT}",
          '#',
          {
            ex_params => "name=hold_up_window",

            #           BUTTON    => 1,
            class     => 'btn btn-xs btn-success open_credit_window',
            SKIP_HREF => 1
          }
        );
      }
    }
  }

  my $deposit = ($user->{CREDIT} == 0) ? $user->{DEPOSIT} + $tp_credit : $user->{DEPOSIT} + $user->{CREDIT};
  if ($deposit < 0) {
    form_neg_deposit($user);
  }

  $user->pi();

  if ($conf{user_chg_pi}) {
    $user->{ADDRESS_SEL} = $html->tpl_show(
      templates('form_address_search'),
      {
        ADDRESS_DISTRICT => $user->{ADDRESS_DISTRICT},
        DISTRICT_ID      => $user->{DISTRICT_ID},
        STREET_ID        => $user->{STREET_ID},
        ADDRESS_STREET   => $user->{ADDRESS_STREET},
        ADDRESS_BUILD    => $user->{LOCATION_ID},
        LOCATION_ID      => $user->{LOCATION_ID},
        ADDRESS_FLAT     => $user->{ADDRESS_FLAT}
      },
      { OUTPUT2RETURN => 1 }
    );

    if ($FORM{chg}) {
      my $user_pi = $user->pi();
      $user->{ACTION}     = 'change';
      $user->{LNG_ACTION} = $lang{CHANGE};

      require "Abills/main/Users_mng.pm";
      Users_mng->import();

      $user->{INFO_FIELDS} = form_info_field_tpl( { VALUES => $user_pi,  CALLED_FROM_CLIENT_UI => 1 } );
      $html->tpl_show(templates('form_chg_client_info'), $user);
      return 1;
    }
    elsif ($FORM{change}) {
      $user->pi_change({ %FORM, UID => $user->{UID} });
      if (!$user->{errno}) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
      }
    }
    elsif (!$user->{FIO}
      || !$user->{PHONE}
      || !$user->{ADDRESS_STREET}
      || !$user->{ADDRESS_BUILD}
      || !$user->{EMAIL})
    {
      # scripts for address
      $user->{ADDRESS_SEL} =~ s/<script src.+>.+<\/script>//g;
      $user->{ADDRESS_SEL} =~ s/\r\n||\n//g;
      my @script = $user->{ADDRESS_SEL} =~ /<script>(.+)<\/script>/;
      $user->{ADDRESS_SEL} =~ s/<script.+<\/script>//g;

      if (!$conf{CHECK_CHANGE_PI}) {
        $user->{PINFO}       = 1;
        $user->{ACTION}      = 'change';
        $user->{LNG_ACTION}  = $lang{CHANGE};
        $user->{MESSAGE_CHG} = $html->message('info', $lang{CHANGE}, "$lang{INFO_CHANGE_MSG}", { OUTPUT2RETURN => 1 });

        #mark or disable input
        $user->{FIO}   eq '' ? ($user->{FIO_HAS_ERROR}   = 'has-error') : ($user->{FIO_DISABLE}   = 'disabled');
        $user->{PHONE} eq '' ? ($user->{PHONE_HAS_ERROR} = 'has-error') : ($user->{PHONE_DISABLE} = 'disabled');
        $user->{EMAIL} eq '' ? ($user->{EMAIL_HAS_ERROR} = 'has-error') : ($user->{EMAIL_DISABLE} = 'disabled');
      }
      else {

        my @check_fields = split(/,[\r\n\s]?/, $conf{CHECK_CHANGE_PI});
        my @all_fields = ('FIO', 'PHONE', 'ADDRESS', 'EMAIL');

        $user->{PINFO}       = 0;
        $user->{ACTION}      = 'change';
        $user->{LNG_ACTION}  = $lang{CHANGE};
        $user->{MESSAGE_CHG} = $html->message('info', $lang{CHANGE}, "$lang{INFO_CHANGE_MSG}", { OUTPUT2RETURN => 1 });

        foreach my $field (@all_fields) {
          ($user->{$field} eq '') && in_array($field, \@check_fields) ? ($user->{ $field . "_HAS_ERROR" } = 'has-error' && $user->{PINFO} = 1) : ($user->{ $field . "_DISABLE" } = 'disabled' && $user->{ $field . "_HIDDEN" } = 'hidden');
        }
      }

      # template to modal
      $user->{TEMPLATE_BODY} = $html->tpl_show(templates('form_chg_client_info'), $user, { OUTPUT2RETURN => 1 });
      $user->{TEMPLATE_BODY} =~ s/\r\n||\n//g;

      # script to modal
      $user->{ADDRESS_FORM_INIT} = $script[0] || '';
      $user->{ADDRESS_FORM_INIT} =~ s/'/\"/g;
      $user->{ADDRESS_FORM_INIT} = '';
    }
  }

  if (!$conf{DOCS_SKIP_NEXT_PERIOD_INVOICE}) {
    if (in_array('Docs', \@MODULES)) {
      $FORM{ALL_SERVICES} = 1;
      load_module('Docs', $html);
      docs_invoice({ UID => $user->{UID}, USER_INFO => $user });
    }
  }

  $LIST_PARAMS{PAGE_ROWS} = 1;
  $LIST_PARAMS{DESC}      = 'desc';
  $LIST_PARAMS{SORT}      = 1;
  my $list = $Payments->list(
    {
      %LIST_PARAMS,
      DATETIME  => '_SHOW',
      SUM       => '_SHOW',
      COLS_NAME => 1
    }
  );

  $user->{PAYMENT_DATE} = $list->[0]->{datetime};
  $user->{PAYMENT_SUM}  = $list->[0]->{sum};
  if ($conf{EXT_BILL_ACCOUNT} && $user->{EXT_BILL_ID} > 0) {
    $user->{EXT_DATA} = $html->tpl_show(templates('form_ext_bill'), $user, { OUTPUT2RETURN => 1 });
  }

  $user->{STATUS} = ($user->{DISABLE}) ? $html->color_mark("$lang{DISABLE}", $_COLORS[6]) : $lang{ENABLE};
  $deposit = sprintf("%.2f", $user->{DEPOSIT});
  $user->{DEPOSIT} = ($deposit < $user->{DEPOSIT}) ? $deposit + 0.01 : $deposit;
  $sum = ($FORM{AMOUNT_FOR_PAY}) ? $FORM{AMOUNT_FOR_PAY} : ($user->{DEPOSIT} < 0) ? abs($user->{DEPOSIT} * 2) : 0;
  $pages_qs = "&SUM=$sum&sid=$sid";

  if (in_array('Docs', \@MODULES)) {
    my $fn_index = get_function_index('docs_invoices_list');
    $user->{DOCS_ACCOUNT} = $html->button("$lang{INVOICE_CREATE}", "index=$fn_index$pages_qs", { BUTTON => 2 });
  }

  if (in_array('Paysys', \@MODULES)) {
    my $fn_index = get_function_index('paysys_payment');
    $user->{PAYSYS_PAYMENTS} = $html->button("$lang{BALANCE_RECHARCHE}", "index=$fn_index$pages_qs", { BUTTON => 2 });
  }

  #Show users info field
  my $i = -1;
  foreach my $field_id (@{ $user->{INFO_FIELDS_ARR} }) {

    #$position, $type
    my (undef, undef, $name, $user_portal) = split(/:/, $user->{INFO_FIELDS_HASH}->{$field_id});
    $i++;
    next if ($user_portal == 0);

    my $extra = '';
    if ($field_id eq '_rating') {
      $extra = $html->button($lang{RATING}, "index=" . get_function_index('dv_rating_user'), { BUTTON => 1 });
    }

    $user->{INFO_FIELDS} .= $html->element('tr', $html->element('td', _translate($name), { OUTPUT2RETURN => 1 }) . $html->element('td', "$user->{INFO_FIELDS_VAL}->[$i] $extra", { OUTPUT2RETURN => 1 }), { OUTPUT2RETURN => 1 });

    #$user->{INFO_FIELDS} .= $html->element("<tr><td><strong>" . (eval "\"$name\"") . ":</strong></td><td valign='center'>$user->{INFO_FIELDS_VAL}->[$i] $extra</td></tr>\n";
  }

  if ($conf{user_chg_pi}) {
    $user->{FORM_CHG_INFO} = $html->form_main(
      {
        CONTENT => $html->form_input('chg', "$lang{CHANGE}", { TYPE => 'SUBMIT', OUTPUT2RETURN => 1 }),
        HIDDEN  => {
          sid   => $sid,
          index => "$index"
        },
        OUTPUT2RETURN => 1
      }
    );
    $user->{FORM_CHG_INFO} = $html->button($lang{CHANGE}, "index=$index&sid=$sid&chg=1", { class => 'btn btn-success', OUTPUT2RETURN => 1 });
  }
  $user->{ACCEPT_RULES} = $html->tpl_show(templates('form_accept_rules'), { FIO => $user->{FIO}, HIDDEN => "style='display:none;'", CHECKBOX => "checked" }, { OUTPUT2RETURN => 1 });
  if (in_array('Portal', \@MODULES)) {
    load_module('Portal', $html);
    $user->{NEWS} = portal_user_cabinet();
  }

  if ($conf{user_chg_passwd}) {
    $user->{CHANGE_PASSWORD} = $html->button($lang{CHANGE_PASSWORD}, "index=17&sid=$sid", { class => 'btn btn-xs btn-primary' });
  }
  $html->tpl_show(templates('form_client_info'), $user, { ID => 'form_client_info' });

  if (in_array('Dv', \@MODULES)) {
    load_module('Dv', $html);
    dv_user_info();
  }

  return 1;
}

#**********************************************************
=head2 form_login()

=cut
#**********************************************************
sub form_login {
  my %first_page = ();

  if ($conf{tech_works}) {
    $html->message( 'info', $lang{INFO}, "$conf{tech_works}" );
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

  if (! $FORM{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER}	=~ /$SELF_URL/) {
    $ENV{HTTP_REFERER} =~ s/sid=[a-z0-9\_]+//g;
    $FORM{REFERER} = $ENV{HTTP_REFERER};
  }
  elsif($ENV{QUERY_STRING})  {
    $ENV{QUERY_STRING} =~ s/sid=[a-z0-9\_]+//g;
    $FORM{REFERER} = $ENV{QUERY_STRING};
  }

  $first_page{TITLE} = $lang{USER_PORTAL};
  if($conf{HOLIDAY_SHOW_BACKGROUND}){
    $first_page{BACK_IMG} = user_login_background();
  }


  if ($conf{AUTH_VK_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK}=$html->element('li',
      $html->button('', "external_auth=Vk", { class => 'icon-vk', ICON => 'fa fa-vk'} ),
      { OUTPUT2RETURN => 1 }
    )
  }

  if ($conf{AUTH_FACEBOOK_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK}.=$html->element('li',
      $html->button('', "external_auth=Facebook", { class => 'icon-facebook', ICON => 'fa fa-facebook'}),
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($conf{AUTH_GOOGLE_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK}.=$html->element('li',
      $html->button('', "external_auth=Google", { class => 'icon-google', ICON => 'fa fa-google'}),
      { OUTPUT2RETURN => 1 }
    );
  }

  if ($conf{AUTH_INSTAGRAM_ID}) {
    $first_page{SOCIAL_AUTH_BLOCK}.=$html->element('li',
      $html->button('', "external_auth=Instagram", { class => 'icon-instagram', ICON => 'fa fa-instagram'}),
      { OUTPUT2RETURN => 1 }
    );
  }

  $OUTPUT{BODY} = $html->tpl_show(templates('form_client_login'),
   \%first_page,
   { MAIN => 1,
     ID   => 'form_client_login'
   });
}

#**********************************************************
=head2 auth($user_name, $password, $session_id, $attr)

=cut
#**********************************************************
sub auth {
  my ($user_name, $password, $session_id, $attr) = @_;

  my $ret                  = 0;
  my $res                  = 0;
  my $REMOTE_ADDR          = $ENV{'REMOTE_ADDR'} || '';
  #my $HTTP_X_FORWARDED_FOR = $ENV{'HTTP_X_FORWARDED_FOR'} || '';
  #my $ip                   = "$REMOTE_ADDR/$HTTP_X_FORWARDED_FOR";
  $uid                     = 0;
  use Abills::Auth::Core;
  my $Auth;
  if($FORM{external_auth}) {
    $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => $FORM{external_auth}});

    $Auth->check_access(\%FORM);

    if($Auth->{auth_url}) {
      print "Location: $Auth->{auth_url}\n\n";
      exit;
    }
    elsif($Auth->{USER_ID}) {
      $user->list({ $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
                    LOGIN                => '_SHOW',
                    COLS_NAME            => 1
                  });

      if($user->{TOTAL}) {
        $uid = $user->{list}->[0]->{uid};
        $user->{LOGIN} = $user->{list}->[0]->{login};
        $user->{UID} = $uid;
        $res = $uid;
      }
      else {
        if(! $sid) {
          $html->message( 'err', $lang{ERROR}, $lang{ERR_UNKNOWN_SN_ACCOUNT});
          return 0;
        }
      }
    }
    else {
      $html->message('err', $lang{ERROR}, $lang{ERR_SN_ERROR});
      return 0;
    }
  }

  if (!$conf{PASSWORDLESS_ACCESS}) {
    if($ENV{USER_CHECK_DEPOSIT}) {
      $conf{PASSWORDLESS_ACCESS} = $ENV{USER_CHECK_DEPOSIT};
    }
    elsif($attr->{PASSWORDLESS_ACCESS}) {
      $conf{PASSWORDLESS_ACCESS}=1;
    }
  }

  #Passwordless Access
  if ($conf{PASSWORDLESS_ACCESS}) {
    require Dv_Sessions;
    Dv_Sessions->import();
    my $sessions = Dv_Sessions->new($db, $admin, \%conf);

    my $list = $sessions->online({ USER_NAME         => '_SHOW',
                                   FRAMED_IP_ADDRESS => "$REMOTE_ADDR",
                                  });

    if ($sessions->{TOTAL} == 1) {
      $user_name = $list->[0]->{user_name};
      $ret       = $list->[0]->{uid};
      $session_id= mk_unique_value(14);
      $user->info($ret);

      $user->{REMOTE_ADDR} = $REMOTE_ADDR;
      return ($ret, $session_id, $user_name);
    }
    else {
      require Dv;
      Dv->import();
      my $Dv = Dv->new($db, $admin, \%conf);
      $Dv->info(0, { IP => "$REMOTE_ADDR" });

      if ($Dv->{TOTAL} == 1) {
        $user_name = $Dv->{LOGIN} || '';
        $ret       = $Dv->{UID};
        $session_id= mk_unique_value(14);
        $user->info($ret);
        $user->{REMOTE_ADDR} = $REMOTE_ADDR;
        return ($ret, $session_id, $user->{LOGIN});
      }
    }
  }

  if ($index == 1000) {
    $user->web_session_del({ SID => $session_id });
    return 0;
  }
  elsif ($sid) {
    $user->web_session_info({ SID => $session_id });

    if ($user->{TOTAL} < 1) {
      #$html->message('err', "$lang{ERROR}", "$lang{NOT_LOGINED}");
      #return 0;
    }
    elsif ($user->{errno}) {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERROR}" );
      #return 0;
    }
    elsif ( $conf{web_session_timeout} < $user->{SESSION_TIME} ){
      $html->message( 'info', "$lang{INFO}", 'Session Expire' );
      $user->web_session_del({ SID => $session_id });
      return 0;
    }
    elsif ($user->{REMOTE_ADDR} ne $REMOTE_ADDR) {
      $html->message( 'err', "$lang{ERROR}", 'WRONG IP' );
      $user->web_session_del({ SID => $session_id });
      return 0;
    }
    else {
      $user->info($user->{UID});
      $admin->{DOMAIN_ID}=$user->{DOMAIN_ID};
      $user->web_session_update({ SID => $session_id });
      #Add social id
      if ($Auth->{USER_ID}) {
        $user->pi_change( { $Auth->{CHECK_FIELD} => $Auth->{USER_ID},
                            UID                  => $user->{UID}
        } );
      }

      return ($user->{UID}, $session_id, $user->{LOGIN});
    }
  }

  if ($user_name && $password) {
    if ($conf{wi_bruteforce}) {
      $user->bruteforce_list(
        {
          LOGIN    => $user_name,
          PASSWORD => $password,
          CHECK    => 1
        }
      );

      if ($user->{TOTAL} > $conf{wi_bruteforce}) {
        $OUTPUT{BODY} = $html->tpl_show(templates('form_bruteforce_message'), undef);
        return 0;
      }
    }

    #check password from RADIUS SERVER if defined $conf{check_access}
    if ($conf{check_access}) {
      $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'Radius'});

      $res = $Auth->check_access({
          LOGIN    => $user_name,
          PASSWORD => $password
      });

#      $res = auth_radius($user_name, "$password");
    }
    #check password direct from SQL
    else {
      $res = auth_sql($user_name, $password) if ($res < 1);
    }
  }
  elsif ($user_name && !$password) {
    $html->message( 'err', "$lang{ERROR}", "$lang{ERR_WRONG_PASSWD}" );
  }

  #Get user ip
  if (defined($res) && $res > 0) {
    $user->info($user->{UID} || 0, {  LOGIN     => ($user->{UID}) ? undef : $user_name,
                                      DOMAIN_ID => $FORM{DOMAIN_ID}
                                    });

    if ($user->{TOTAL} > 0) {
      $session_id          = mk_unique_value(16);
      $ret                 = $user->{UID};
      $user->{REMOTE_ADDR} = $REMOTE_ADDR;
      $admin->{DOMAIN_ID}  = $user->{DOMAIN_ID};
      $user->web_session_add(
        {
          UID         => $user->{UID},
          SID         => $session_id,
          LOGIN       => $login,
          REMOTE_ADDR => $REMOTE_ADDR,
          EXT_INFO    => $ENV{HTTP_USER_AGENT},
          COORDX      => $FORM{coord_x} || '',
          COORDY      => $FORM{coord_y} || ''
        }
      );
    }
    else {
      $html->message( 'err', "$lang{ERROR}", "$lang{ERR_WRONG_PASSWD}" );
    }
  }
  else {
    $user->bruteforce_add(
      {
        LOGIN       => $login,
        PASSWORD    => $password,
        REMOTE_ADDR => $REMOTE_ADDR,
        AUTH_STATE  => $ret
      }
    );

    $OUTPUT{MESSAGE} = $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PASSWD},
      { OUTPUT2RETURN => 1 } ) if ($login || $password);
    $ret = 0;
  }

  return ($ret, $session_id, $login);
}

#**********************************************************
=head2 auth_sql($login, $password) - Authentification from SQL DB

=cut
#**********************************************************
sub auth_sql {
  my ($user_name, $password) = @_;
  my $ret = 0;

  $conf{WEB_AUTH_KEY}='LOGIN' if(! $conf{WEB_AUTH_KEY});

  if ($conf{WEB_AUTH_KEY} eq 'LOGIN') {
    $user->info(
      0,
      {
        LOGIN    => $user_name,
        PASSWORD => $password,
        DOMAIN_ID=> $FORM{DOMAIN_ID}
      }
    );
  }
  else {
    my @a_method = split(/,/, $conf{WEB_AUTH_KEY});
    foreach my $auth_param (@a_method) {
      $user->list({ $auth_param => "$login",
                  PASSWORD  => "$password",
                  DOMAIN_ID => $FORM{DOMAIN_ID},
                  COLS_NAME => 1
                 });

      if ($user->{TOTAL}) {
        $user->info($user->{list}->[0]->{uid});
        last;
      }
    }
  }

  if ($user->{TOTAL} < 1) {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_PASSWD}" );
  }
  elsif (_error_show($user)) {
  }
  else {
    $ret = $user->{UID} || $user->{list}->[0]->{uid};
  }

  $admin->{DOMAIN_ID}=$user->{DOMAIN_ID};

  return $ret;
}

#**********************************************************
=head2 form_passwd($attr) - User password form

=cut
#**********************************************************
sub form_passwd {
  #my ($attr) = @_;
  #my $hidden_inputs;

  $conf{PASSWD_SYMBOLS} = 'abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ' if (!$conf{PASSWD_SYMBOLS});
  $conf{PASSWD_LENGTH}  = 6 if (! $conf{PASSWD_LENGTH});

  my $user_pi = $user->pi({ UID => $user->{UID} });

  if (! $FORM{newpassword}) {
    if ( $FORM{unreg} ) {
      my $change_field = '_' . uc $FORM{unreg};
      if ( defined ($user_pi->{$change_field}) ) {
        $user->pi_change( { UID => $user->{UID}, $change_field => '' } );
        undef $user_pi->{$change_field};
      }
    }
  }
  elsif (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
    $html->message( 'err', $lang{ERROR}, $lang{ERR_SHORT_PASSWD} );
  }
  elsif ($FORM{newpassword} !~ /^[$conf{PASSWD_SYMBOLS}]*$/) {
    $html->message( 'err', $lang{ERROR}, $lang{ERR_SYMBOLS_PASSWD} );
  }
  elsif ($FORM{newpassword} eq $FORM{confirm}) {
    my %INFO = (
      PASSWORD => $FORM{newpassword},
      UID      => $user->{UID},
      DISABLE  => $user->{DISABLE}
    );

    $user->change($user->{UID}, \%INFO);

    if (! _error_show($user)) {
      $html->message( 'info', $lang{INFO}, "$lang{CHANGED}" );
    }
    return 0;
  }
  elsif ($FORM{newpassword} ne $FORM{confirm}) {
    $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_CONFIRM} );
  }

  my %password_form = ();
  $password_form{PW_CHARS}     = $conf{PASSWD_SYMBOLS} || 'abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ';
  $password_form{PW_LENGTH}    = $conf{PASSWD_LENGTH}  || 6;
  $password_form{ACTION}       = 'change';
  $password_form{LNG_ACTION}   = $lang{CHANGE};
  $password_form{GEN_PASSWORD} = mk_unique_value(8);

  if ( $conf{AUTH_VK_ID} ) {
    my $registered_class = '';
    my $unreg_button = '';

    if ($user_pi->{_VK}){
      $registered_class = 'icon-registered';
      $unreg_button = $html->button('', "index=$index&sid=$sid&unreg=Vk", {
          ICON => 'glyphicon glyphicon-remove',
          class => 'icon-vk icon-unreg'
        });
    }
    $password_form{SOCIAL_AUTH_BLOCK} = $html->element( 'li',
      $html->button( '', "external_auth=Vk", {
          class      => "icon-vk $registered_class",
          ICON       => 'fa fa-vk',

        } ) . $unreg_button, { OUTPUT2RETURN => 1 }
    )
  }

  if ( $conf{AUTH_FACEBOOK_ID} ) {
    my $registered_class = '';
    my $unreg_button = '';

    if ($user_pi->{_FACEBOOK}){
      $registered_class = 'icon-registered';
      $unreg_button = $html->button('', "index=$index&sid=$sid&unreg=Facebook", {
          ICON => 'glyphicon glyphicon-remove',
          class => 'icon-instagram icon-unreg'

        });
    }

    $password_form{SOCIAL_AUTH_BLOCK} .= $html->element( 'li',
      $html->button( '', "external_auth=Facebook", {
          class      => "icon-facebook $registered_class",
          ICON       => 'fa fa-facebook',
          GLOBAL_URL => "https://www.facebook.com/dialog/oauth?client_id=$conf{AUTH_FACEBOOK_ID}&response_type=code"
            . '&redirect_uri=' . $conf{AUTH_FACEBOOK_URL} . '&state=facebook&scope=public_profile,email,user_birthday,user_likes,user_friends'
        } ) . $unreg_button, { OUTPUT2RETURN => 1 }
    );
  }

  if ( $conf{AUTH_GOOGLE_ID} ) {
    my $registered_class = '';
    my $unreg_button = '';

    if ($user_pi->{_GOOGLE}){
      $registered_class = 'icon-registered';
      $unreg_button = $html->button('', "index=$index&sid=$sid&unreg=Google", {
          ICON => 'glyphicon glyphicon-remove',
          class => 'icon-google icon-unreg',
      });
    }
    my $client_id = $conf{AUTH_GOOGLE_ID} || q{};
    my $redirect_uri = $conf{AUTH_GOOGLE_URL} || q{};

    $password_form{SOCIAL_AUTH_BLOCK} .= $html->element( 'li',
      $html->button( '', "external_auth=Google", {
        class => "icon-google $registered_class",
        ICON  => 'fa fa-google',
        GLOBAL_URL => join('',
            "https://accounts.google.com/o/oauth2/v2/auth?",
            "&response_type=code",
            "&client_id=$client_id",
            "&redirect_uri=$redirect_uri",
            "&scope=profile",
            "&access_type=offline",
            "&state=google",
        )
      }) . $unreg_button,
      { OUTPUT2RETURN => 1 }
    );
  }

  if ( $conf{AUTH_INSTAGRAM_ID} ) {
    my $registered_class = '';
    my $unreg_button = '';

    my $client_id = $conf{AUTH_INSTAGRAM_ID} || q{};
    my $redirect_uri = $conf{AUTH_INSTAGRAM_URL} || q{};

    if ($user_pi->{_INSTAGRAM}){
      $registered_class = 'icon-registered';
      $unreg_button = $html->button('', "index=$index&sid=$sid&unreg=Instagram", {
          ICON => 'glyphicon glyphicon-remove',
          class => 'icon-instagram icon-unreg'
        });
    }

    $password_form{SOCIAL_AUTH_BLOCK} .= $html->element( 'li',
      $html->button( '', "external_auth=Instagram", {
          class => "icon-instagram $registered_class",
          ICON  => 'fa fa-instagram',
          GLOBAL_URL => join('',
            "https://api.instagram.com/oauth/authorize?",
            "&response_type=code",
            "&client_id=$client_id",
            "&redirect_uri=$redirect_uri",
            "&state=instagram"
            ),
        } ) . $unreg_button, { OUTPUT2RETURN => 1 }
    );
  }

  $html->tpl_show(templates('form_password'), \%password_form);

  return 1;
}

#**********************************************************
=head2 accept_rules()

=cut
#**********************************************************
sub accept_rules {
  $user->pi({ UID => $user->{UID} });
  if ($FORM{ACCEPT} && $FORM{accept}) {
    if ($user->{TOTAL} == 0) {
      $user->pi_add({ UID => $user->{UID}, ACCEPT_RULES => 1 });
    }
    else {
      $user->pi_change({ UID => $user->{UID}, ACCEPT_RULES => 1 });
    }

    return 0;
  }

  if ($user->{ACCEPT_RULES}) {
    return 0;
  }

  $html->tpl_show(templates('form_accept_rules'), $user);

  print $html->header();
  $OUTPUT{BODY} = $html->{OUTPUT};
  print $OUTPUT{BODY};
  exit;
}

#**********************************************************
=head2 reports($attr) -  Report main interface

=cut
#**********************************************************
sub reports {
  my ($attr) = @_;

  my $EX_PARAMS;
  my ($y, $m, $d);
  my $type = 'DATE';

  if ($FORM{MONTH}) {
    $LIST_PARAMS{MONTH} = $FORM{MONTH};
    $pages_qs = "&MONTH=$LIST_PARAMS{MONTH}";
  }
  elsif ($FORM{allmonthes}) {
    $type     = 'MONTH';
    $pages_qs = "&allmonthes=1";
  }
  else {
    ($y, $m, $d) = split(/-/, $DATE, 3);
    $LIST_PARAMS{MONTH} = "$y-$m";
    $pages_qs = "&MONTH=$LIST_PARAMS{MONTH}";
  }

  if ($LIST_PARAMS{UID}) {
    $pages_qs .= "&UID=$LIST_PARAMS{UID}";
  }
  else {
    if ($FORM{GID}) {
      $LIST_PARAMS{GID} = $FORM{GID};
      $pages_qs = "&GID=$FORM{GID}";
      delete $LIST_PARAMS{GIDS};
    }
  }

  my @rows = ();
  my $FIELDS = '';

  if ($attr->{FIELDS}) {
    my %fields_hash = ();
    if (defined($FORM{FIELDS})) {
      my @fileds_arr = split(/, /, $FORM{FIELDS});
      foreach my $line (@fileds_arr) {
        $fields_hash{$line} = 1;
      }
    }

    $LIST_PARAMS{FIELDS} = $FORM{FIELDS};
    $pages_qs = "&FIELDS=$FORM{FIELDS}";

    my $table2 = $html->table({ width => '100%' });
    my @arr    = ();
    my $i      = 0;

    foreach my $line (sort keys %{ $attr->{FIELDS} }) {
      my (undef, $k) = split(/:/, $line);

      push @arr, $html->form_input("FIELDS", $k, { TYPE => 'checkbox', STATE => (defined($fields_hash{$k})) ? 'checked' : undef, OUTPUT2RETURN => 1 }) . " $attr->{FIELDS}{$line}";
      $i++;
      if ($#arr > 1) {
        $table2->addrow(@arr);
        @arr = ();
      }
    }

    if ($#arr > -1) {
      $table2->addrow(@arr);
    }
    $FIELDS .= $table2->show({ OUTPUT2RETURN => 1 });
  }

  if ($attr->{PERIOD_FORM}) {
    @rows =
      ("$lang{DATE}: " . $html->date_fld2( 'FROM_DATE',
        { DATE => $FORM{FROM_DATE}, MONTHES => \@MONTHES, FORM_NAME => 'form_reports', WEEK_DAYS =>
          \@WEEKDAYS } ) . " - " . $html->date_fld2( 'TO_DATE',
        { MONTHES => \@MONTHES, FORM_NAME => 'form_reports', WEEK_DAYS => \@WEEKDAYS } ));

    if (!$attr->{NO_GROUP}) {
      push @rows, "$lang{TYPE}:",
      $html->form_select(
        'TYPE',
        {
          SELECTED => $FORM{TYPE},
          SEL_HASH => {
            DAYS  => $lang{DAYS},
            USER  => $lang{USERS},
            HOURS => $lang{HOURS},
            ($attr->{EXT_TYPE}) ? %{ $attr->{EXT_TYPE} } : ''
          },
          NO_ID => 1
        }
      );
    }

    if ($attr->{EX_INPUTS}) {
      foreach my $line (@{ $attr->{EX_INPUTS} }) {
        push @rows, $line;
      }
    }

    my $table = $html->table(
      {
        width    => '100%',
        rowcolor => $lang{COLORS}[1],
        rows     => [
          [
            @rows,
            ($attr->{XML})
              ? $html->form_input('NO_MENU', 1, { TYPE => 'hidden' }) . $html->form_input('xml', 1, { TYPE => 'checkbox', OUTPUT2RETURN => 1 }) . "XML"
              : '' . $html->form_input( 'show', $lang{SHOW}, { TYPE => 'submit', OUTPUT2RETURN => 1 } )
          ]
        ],
      }
    );

    print $html->form_main(
      {
        CONTENT => $table->show({ OUTPUT2RETURN => 1 }) . $FIELDS,
        NAME    => 'form_reports',
        HIDDEN  => {
          'index' => "$index",
          ($attr->{HIDDEN}) ? %{ $attr->{HIDDEN} } : undef
        }
      }
    );

    if (defined($FORM{show})) {
      $pages_qs .= "&show=1&FROM_DATE=$FORM{FROM_DATE}&TO_DATE=$FORM{TO_DATE}";
      $LIST_PARAMS{TYPE}     = $FORM{TYPE};
      $LIST_PARAMS{INTERVAL} = "$FORM{FROM_DATE}/$FORM{TO_DATE}";
    }
  }

  if (defined($FORM{DATE})) {
    ($y, $m, $d) = split(/-/, $FORM{DATE}, 3);

    $LIST_PARAMS{DATE} = "$FORM{DATE}";
    $pages_qs .= "&DATE=$LIST_PARAMS{DATE}";

    if (defined($attr->{EX_PARAMS})) {
      my $EP = $attr->{EX_PARAMS};
      while (my ($k, $v) = each(%$EP)) {
        if ($FORM{EX_PARAMS} eq $k) {
          $EX_PARAMS .= ' ' . $html->b($v);
          $LIST_PARAMS{$k} = 1;
          if ($k eq 'HOURS') {
            undef $attr->{SHOW_HOURS};
          }
        }
        else {
          $EX_PARAMS .= $html->button($v, "index=$index$pages_qs&EX_PARAMS=$k", { BUTTON => 1 }) . ' ';
        }
      }
    }

    my $days = '';
    for (my $i = 1 ; $i <= 31 ; $i++) {
      $days .= ($d == $i) ? ' ' . $html->b($i) : ' '
      . $html->button(
        $i,
        sprintf("index=$index&DATE=%d-%02.f-%02.f&EX_PARAMS=$FORM{EX_PARAMS}%s%s", $y, $m, $i, (defined($FORM{GID})) ? "&GID=$FORM{GID}" : '', (defined($FORM{UID})) ? "&UID=$FORM{UID}" : ''),
        { BUTTON => 1 }
      );
    }

    @rows = ([ "$lang{YEAR}:", $y ], [ "$lang{MONTH}:", $MONTHES[ $m - 1 ] ], [ "$lang{DAY}:", $days ]);

    if ($attr->{SHOW_HOURS}) {
      my (undef, $h) = split(/ /, $FORM{HOUR}, 2);
      my $hours = '';
      for (my $i = 0 ; $i < 24 ; $i++) {
        $hours .= ($h == $i) ? $html->b($i) : ' ' . $html->button($i, sprintf("index=$index&HOUR=%d-%02.f-%02.f+%02.f&EX_PARAMS=$FORM{EX_PARAMS}$pages_qs", $y, $m, $d, $i), { BUTTON => 1 });
      }
      $LIST_PARAMS{HOUR} = "$FORM{HOUR}";
      push @rows, [ "$lang{HOURS}", $hours ];
    }

    if ($attr->{EX_PARAMS}) {
      push @rows, [ ' ', $EX_PARAMS ];
    }

    my $table = $html->table(
      {
        width      => '100%',
        rowcolor   => $_COLORS[1],
        cols_align => [ 'right', 'left' ],
        rows       => [@rows]
      }
    );
    print $table->show();
  }

  return 1;
}


#**********************************************************
=head2 form_finance

=cut
#**********************************************************
sub form_finance {

  my @PAYMENT_METHODS = ("$lang{CASH}", "$lang{BANK}", "$lang{EXTERNAL_PAYMENTS}", 'Credit Card', "$lang{BONUS}",
    "$lang{CORRECTION}", "$lang{COMPENSATION}", "$lang{MONEY_TRANSFER}");
  push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  my $Payments = Finance->payments($db, $admin, \%conf);

  if (!$FORM{sort}) {
    $LIST_PARAMS{sort} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list  = $Payments->list({ %LIST_PARAMS,
                                DATETIME  => '_SHOW',
                                PAGE_ROWS => 10,
                                COLS_NAME => 1
                              });

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{PAYMENTS}",
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{DEPOSIT} ],
      cols_align  => [ 'right', 'left', 'left', 'right', 'right', 'left', 'right', 'right', 'left', 'left' ],
      qs          => $pages_qs,
      #pages       => $Payments->{TOTAL},
      ID          => 'PAYMENTS'
    }
  );

  foreach my $line (@$list) {
    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      $line->{sum},
      $line->{last_deposit},
    );
  }

  print $table->show();

  my $FEES_METHODS = get_fees_types();

  my $Fees  = Finance->fees($db, $admin, \%conf);
  $list  = $Fees->list({%LIST_PARAMS,
                        DSC       => '_SHOW',
                        DATETIME  => '_SHOW',
                        SUM       => '_SHOW',
                        DEPOSIT   => '_SHOW',
                        METHOD    => '_SHOW',
                        LAST_DEPOSIT => '_SHOW',
                        PAGE_ROWS => 10,
                        COLS_NAME => 1
                      });

  $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{FEES}",
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{DEPOSIT}, $lang{TYPE} ],
      cols_align  => [ 'right', 'left', 'right', 'right', 'left', 'left', 'left', 'right', 'right' ],
      qs          => $pages_qs,
      #pages       => $Fees->{TOTAL},
      ID          => 'FEES'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->{datetime}, $line->{dsc}, $line->{sum}, $line->{last_deposit}, $FEES_METHODS->{ $line->{method} });
  }

  print $table->show();

  return 1;
}

#**********************************************************
# form_fees
#**********************************************************
sub form_fees {

  if (!$FORM{sort}) {
    $LIST_PARAMS{SORT} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $FEES_METHODS = get_fees_types();

  my $Fees  = Finance->fees($db, $admin, \%conf);
  my $list  = $Fees->list({%LIST_PARAMS,
                           DSC       => '_SHOW',
                           DATETIME  => '_SHOW',
                           SUM       => '_SHOW',
                           DEPOSIT   => '_SHOW',
                           METHOD    => '_SHOW',
                           LAST_DEPOSIT => '_SHOW',
                           COLS_NAME => 1 });

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{FEES}",
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{DEPOSIT}, $lang{TYPE} ],
      cols_align  => [ 'right', 'left', 'right', 'right', 'left', 'left', 'left', 'right', 'right' ],
      qs          => $pages_qs,
      pages       => $Fees->{TOTAL},
      ID          => 'FEES'
    }
  );

  foreach my $line (@$list) {
    $table->addrow($line->{datetime}, $line->{dsc}, $line->{sum}, $line->{last_deposit}, $FEES_METHODS->{ $line->{method} });
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b( $Fees->{TOTAL} ), "$lang{SUM}:", $html->b( $Fees->{SUM} ) ] ],
      rowcolor   => $_COLORS[2]
    }
  );
  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_payments_list()

=cut
#**********************************************************
sub form_payments_list {
  my @PAYMENT_METHODS = ("$lang{CASH}", "$lang{BANK}", "$lang{EXTERNAL_PAYMENTS}", 'Credit Card', "$lang{BONUS}",
    "$lang{CORRECTION}", "$lang{COMPENSATION}", "$lang{MONEY_TRANSFER}");
  push @PAYMENT_METHODS, @EX_PAYMENT_METHODS if (@EX_PAYMENT_METHODS);

  my $Payments = Finance->payments($db, $admin, \%conf);

  if (!$FORM{sort}) {
    $LIST_PARAMS{sort} = 1;
    $LIST_PARAMS{DESC} = 'DESC';
  }

  my $list  = $Payments->list({%LIST_PARAMS,
                               DATETIME  => '_SHOW',
                               COLS_NAME => 1});

  my $table = $html->table(
    {
      width       => '100%',
      caption     => "$lang{PAYMENTS}",
      title_plain => [ $lang{DATE}, $lang{DESCRIBE}, $lang{SUM}, $lang{DEPOSIT} ],
      cols_align  => [ 'right', 'left', 'left', 'right', 'right', 'left', 'right', 'right', 'left', 'left' ],
      qs          => $pages_qs,
      pages       => $Payments->{TOTAL},
      ID          => 'PAYMENTS'
    }
  );

  foreach my $line (@$list) {
    $table->addrow(
      $line->{datetime},
      $line->{dsc},
      $line->{sum},
      $line->{last_deposit},
    );
  }

  print $table->show();

  $table = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right', 'right', 'right' ],
      rows       => [ [ "$lang{TOTAL}:", $html->b( $Payments->{TOTAL} ), "$lang{SUM}:", $html->b( $Payments->{SUM} ) ] ]
      ,
      rowcolor   => $_COLORS[2]
    }
  );

  print $table->show();

  return 1;
}

#**********************************************************
=head2 form_period($period, $attr)

=cut
#**********************************************************
sub form_period {
  my ($period, $attr) = @_;

  my @periods = ("$lang{NEXT_PERIOD}", "$lang{DATE}");
  $attr->{TP}->{date_fld} = $html->date_fld2('DATE', { FORM_NAME => 'user', MONTHES => \@MONTHES, WEEK_DAYS => \@WEEKDAYS, NEXT_DAY => 1 });
  my $form_period = '';
  $form_period .= "<label class='control-label col-md-2'>$lang{DATE}:</label>";
  $period = 1;

  $form_period .= "<div class='col-md-10'>";

  for (my $i = $#periods ; $i > -1 ; $i--) {
    my $t = $periods[$i];
    $form_period .= "<div class='row'><div class='control-element col-md-1'>" . $html->form_input(
      'period', "$i",
      {
        TYPE          => "radio",
        STATE         => ($i eq $period) ? 1 : undef,
        OUTPUT2RETURN => 1
      }
    );
      $form_period .= "</div>"; #control-element (radio)
    if ($i ==0){
        if ($attr->{ABON_DATE}){
            $form_period .= "<div class='col-md-11 text-left'><span class='control-element'>" . $t . "</span> ($attr->{ABON_DATE}) </div>";
        } else {
          $form_period .= "<div class='col-md-11 control-element text-left'>" . "$lang{NOW}" . "</div>";
        }
    } else {
        $form_period .= "<div class='control-element col-md-2'>" . $t . "</div><div class='col-md-4'> $attr->{TP}->{date_fld} </div><div class='col-md-4'></div>";
    }
      $form_period .= "</div>"; #row
  }

  $form_period .= "</div>";
  return $form_period;
}

#**********************************************************
# transfer funds between users accounts
#**********************************************************
sub form_money_transfer {
  my $deposit_limit  = 0;
  my $transfer_price = 0;
  my $no_companies   = q{};

  $admin->{SESSION_IP} = $ENV{REMOTE_ADDR};

  if ($conf{MONEY_TRANSFER} =~ /:/) {
    ($deposit_limit, $transfer_price, $no_companies) = split(/:/, $conf{MONEY_TRANSFER});

    if ($no_companies eq 'NO_COMPANIES' && $user->{COMPANY_ID}) {
      $html->message( 'info', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}" );
      return 0;
    }
  }
  $transfer_price = sprintf("%.2f", $transfer_price);

  if ($FORM{s2} || $FORM{transfer}) {
    $FORM{SUM} = sprintf("%.2f", $FORM{SUM});

    if ($user->{DEPOSIT} < $FORM{SUM} + $deposit_limit + $transfer_price) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_SMALL_DEPOSIT}" );
    }
    elsif (!$FORM{SUM}) {
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_SUM}" );
    }
    elsif (!$FORM{RECIPIENT}) {
      $html->message( 'err', $lang{ERROR}, "$lang{SELECT_USER}" );
    }
    elsif ($FORM{RECIPIENT} == $user->{UID}) {
      $html->message( 'err', $lang{ERROR}, "$lang{USER_NOT_EXIST}" );
    }
    else {
      my $user2 = Users->new($db, $admin, \%conf);
      $user2->info(int($FORM{RECIPIENT}));
      if ($user2->{TOTAL} < 1) {
        $html->message( 'err', $lang{ERROR}, "$lang{USER_NOT_EXIST}" );
      }
      else {
        $user2->pi({ UID => $user2->{UID} });

        if (!$FORM{ACCEPT} && $FORM{transfer}) {
          $html->message( 'err', $lang{ERROR}, "$lang{ERR_ACCEPT_RULES}" );
          $html->tpl_show(templates('form_money_transfer_s2'), { %$user2, %FORM });
        }
        elsif ($FORM{transfer}) {

          #Fees
          my $Fees = Finance->fees($db, $admin, \%conf);
          $Fees->take(
            $user,
            $FORM{SUM},
            {
              DESCRIBE => "$lang{USER}: $user2->{UID}",
              METHOD   => 4
            }
          );

          if (! _error_show($Fees)) {
            $html->message( 'info', $lang{FEES},
              "$lang{TAKE} SUM: $FORM{SUM}" . (($transfer_price > 0) ? " $lang{COMMISSION} $lang{SUM}: $transfer_price" : '') );
            my $Payments = Finance->payments($db, $admin, \%conf);
            $Payments->add(
              $user2,
              {
                DESCRIBE       => "$lang{USER}: $user->{UID}",
                INNER_DESCRIBE => "$Fees->{INSERT_ID}",
                SUM            => $FORM{SUM},
                METHOD         => 7
              }
            );

            if (! _error_show($Payments)) {
              my $message = "# $Payments->{INSERT_ID} $lang{MONEY_TRANSFER} $lang{SUM}: $FORM{SUM}";
              if ($transfer_price > 0) {
                #$Fees = Finance->fees($db, $admin, \%conf);
                $Fees->take(
                  $user,
                  $transfer_price,
                  {
                    DESCRIBE => "$lang{USER}: $user2->{UID} $lang{COMMISSION}",
                    METHOD   => 4,
                  }
                );
                if (!$Fees->{errno}) {
                  #$message .= " $lang{COMMISSION} $lang{SUM}: $transfer_price";
                }
              }

              $html->message( 'info', $lang{PAYMENTS}, $message );
              $user2->{PAYMENT_ID} = $Payments->{INSERT_ID};
              cross_modules_call('_payments_maked', { USER_INFO => $user2, QUITE => 1 });
            }
          }

          #Payments
          $html->tpl_show(templates('form_money_transfer_s3'), { %FORM, %$user2 });
        }
        elsif ($FORM{s2}) {
          $user2->{COMMISSION} = "$lang{COMMISSION}: $transfer_price";
          $html->tpl_show(templates('form_money_transfer_s2'), { %$user2, %FORM });
        }
        return 0;
      }
    }
  }

  $html->tpl_show(templates('form_money_transfer_s1'), \%FORM);

  return 1;
}

#**********************************************************
=head1 form_neg_deposit($user, $attr)

=cut
#**********************************************************
sub form_neg_deposit {
  my ($user_) = @_;

  $user_->{TOTAL_DEBET} = 0;
  my $cross_modules_return = cross_modules_call('_docs', { UID          => $LIST_PARAMS{UID},
                                                           REDUCTION    => $user_->{REDUCTION},
                                                           PAYMENT_TYPE => 0 });
  foreach my $module (sort keys %$cross_modules_return) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{ $cross_modules_return->{$module} } == -1);
      foreach my $line (@{ $cross_modules_return->{$module} }) {
        # $name, $describe
        my (undef, undef, $sum) = split(/\|/, $line);
        $user_->{TOTAL_DEBET}+=$sum;

        if ($user_->{REDUCTION} && $module ne 'Abon') {
          $user_->{TOTAL_DEBET} = sprintf("%.2f", $user_->{TOTAL_DEBET} * (100 - $user_->{REDUCTION}) / 100);
        }
      }
    }
  }

  $user_->{TOTAL_DEBET} = ($user_->{DEPOSIT} < 0) ? $user_->{TOTAL_DEBET} + abs($user_->{DEPOSIT}) :  $user_->{TOTAL_DEBET} - $user_->{DEPOSIT};

  if ($user_->{TOTAL_DEBET} > int($user_->{TOTAL_DEBET})) {
    $user_->{TOTAL_DEBET} = sprintf("%.2f", int($user_->{TOTAL_DEBET})+1);
  }

  #use dv warning expr
  if ($conf{PORTAL_EXTRA_WARNING}) {
    if ($conf{PORTAL_EXTRA_WARNING}=~/CMD:(.+)/) {
      $user_->{EXTRA_WARNING} = cmd($1, {
           PARAMS => {
               language => $html->{language},
               %{ $user_ },
           }
         });
    }
  }

  $user_->{TOTAL_DEBET} = sprintf("%.2f", $user_->{TOTAL_DEBET});
  $pages_qs = "&SUM=$user_->{TOTAL_DEBET}&sid=$sid";

  if (in_array('Docs', \@MODULES)) {
    my $fn_index = get_function_index('docs_invoices_list');
    $user_->{DOCS_BUTTON} = $html->button( "$lang{INVOICE_CREATE}", "index=$fn_index$pages_qs", { BUTTON => 2 } );
  }

  if (in_array('Paysys', \@MODULES)) {
    my $fn_index = get_function_index('paysys_payment');
    $user_->{PAYMENT_BUTTON} = $html->button( "$lang{BALANCE_RECHARCHE}", "index=$fn_index$pages_qs", { BUTTON => 2 } );
  }

  if (in_array('Cards', \@MODULES)) {
    my $fn_index = get_function_index('cards_user_payment');
    $user_->{CARDS_BUTTON} = $html->button( "$lang{ICARDS}", "index=$fn_index$pages_qs", { BUTTON => 2 } );
  }

  $html->tpl_show(templates('form_neg_deposit'), $user_, { ID => 'form_neg_deposit' });

  return 1;
}


#**********************************************************
=head2 change_color()

=cut
#**********************************************************
sub change_color {

  if (! $html->{HTML_STYLE}) {
    $html->{HTML_STYLE} = 'default_adm';
  }

  my $colors_dir  = "styles/$html->{HTML_STYLE}/colors/";
  my $output      = '';
  my @contents    = ();
  my @show_colors = ();

  if (opendir my $fh, "$colors_dir") {
    @contents = grep !/^\.\.?$/, readdir $fh;
    closedir $fh;
    $output = '<ul>';
    foreach my $key (@contents) {
      my ($name, undef)=split(/\./, $key);
      push @show_colors, $name;
      $output .= "<li data-path='styles/$html->{HTML_STYLE}/colors/$key' onclick='changeTheme(this)'>$name</li>";
    }
    $output .= '</ul>';
  }
  else {
    $html->message( 'err', $lang{ERROR}, "Can't open dir '$colors_dir'. $!" );
    return 0;
  }

  if ($FORM{COLORS}) {
    $html->{COLORS} = $FORM{COLORS};
    $html->set_cookies('COLORS', $FORM{COLORS}, "Fri, 1-Jan-2038 00:00:01", $html->{web_path});
  }
  elsif($COOKIES{COLORS}) {
    $html->{COLORS} = $COOKIES{COLORS};
  }

  return $output;
}

#**********************************************************
=head2 user_login_background($attr)

=cut
#**********************************************************
sub user_login_background {
#  my ($attr) = @_;

  require Tariffs;
  Tariffs->import();
  my $holidays = Tariffs->new($db, \%conf, $admin);
  my $holiday_path = "/images/holiday/";
  my $list  = $holidays->holidays_list({COLS_NAME => 1});

  my (undef,$m,$d) = split('-', $DATE);

  foreach my $line (@$list){
    if($line->{day} eq "$m-$d" and $line->{file} ne ''){
      my $image = $holiday_path . $line->{file};
      return $image;
    }
  }

  if($m == 12 || $m < 3) {
    my $image = "/images/holiday/winter.jpg";
    return $image;
  }
  elsif($m >= 3 && $m < 6) {
    my $image = "/images/holiday/spring.jpg";
    return $image;
  }
  elsif($m >= 6 && $m < 9) {
    my $image = "/images/holiday/summer.jpg";
    return $image;
  }
  else {
    my $image = "/images/holiday/autumn.jpg";
    return $image;
  }
}

#**********************************************************
=head2 form_events($attr) - Show system events

=cut
#**********************************************************
sub form_events {
  #my ($attr) =@_;

  my @result_array = ();

  $FORM{even_show}=1;

  if ($FORM{even_show}) {
    print "Content-Type: text/html\n\n";
    my $cross_modules_return = cross_modules_call('_events', {
        UID              => $user->{UID},
        CLIENT_INTERFACE => 1
      });

    foreach my $module (sort keys %$cross_modules_return) {
      my $result = $cross_modules_return->{$module};
      if ($result && $result ne ''){
        push (@result_array, $result);
      }
    }
  }

  print "[ " . join(", ", @result_array) . " ]";

  return 1;
}

#**********************************************************
=head2 fl() - Show system events

=cut
#**********************************************************
sub fl {
  my $custom_menu = custom_menu({ TPL_NAME => 'client_menu' });

  if($#{ $custom_menu } > -1) {
    mk_menu($custom_menu, { CUSTOM => 1 });
    return 1;
  }

  my @m = ("10:0:$lang{USER_INFO}:form_info:::",);
  if ( $conf{user_finance_menu} ){
    push @m, "40:0:$lang{FINANCES}:form_finance:::";
    push @m, "41:40:$lang{PAYMENTS}:form_payments_list:::";
    push @m, "42:40:$lang{FEES}:form_fees:::";
    if ( $conf{MONEY_TRANSFER} ){
      push @m, "43:40:$lang{MONEY_TRANSFER}:form_money_transfer:::";
    }
  }

  # Should be 17 or you should change it at "CHANGE_PASSWORD" button in form_info()
  push @m, "17:0:$lang{PASSWD}:form_passwd:::" if ($conf{user_chg_passwd});

  mk_menu( \@m, { USER_FUNCTION_LIST => 1 } );
  return 1;
}

1
