#!/usr/bin/perl

=head1 NAME

  Paysys processing system
  Check payments incomming request

=cut

use strict;
use warnings;

BEGIN {
  our $libpath = '../';
  our $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/modules/",
    $libpath . "Abills/",
    $libpath . '/lib/');

  our $begin_time = 0;
  eval {require Time::HiRes;};
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::Defs;
do "../libexec/config.pl";

use Abills::Filters;
use Users;
use Paysys;
use Paysys::Init;
use Finance;
use Admins;
use Conf;

our $silent = 1;
our %lang;
our $debug = $conf{PAYSYS_DEBUG} || 0;
our $html = Abills::HTML->new({ CONF => \%conf });
our $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });
$admin->{DATE} = $DATE;

# if ($Paysys::VERSION < 9.13) {
#   print "Content=-Type: text/html\n\n";
#   print "Please update module 'Paysys' to version 9.13 or higher. http://abills.net.ua/";
#   return 0;
# }

# read conf for DB
our $Conf = Conf->new($db, $admin, \%conf);
do "../language/$html->{language}.pl";

delete $FORM{language};
require Abills::Misc;
require Abills::Templates;
load_module('Paysys', $html);
require Paysys::Paysys_Base;

#Check allow ips
if ($conf{PAYSYS_IPS}) {
  if ($ENV{REMOTE_ADDR} && !check_ip($ENV{REMOTE_ADDR}, $conf{PAYSYS_IPS})) {
    print "Content-Type: text/html\n\n";
    my $error = "Error: IP '$ENV{REMOTE_ADDR}' DENY by System";
    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "ABillS - Paysys", "IP '$ENV{REMOTE_ADDR}' DENY by System",
      "$conf{MAIL_CHARSET}", "2 (High)");
    mk_log($error);
    exit;
  }
}

if ($conf{PAYSYS_PASSWD}) {
  my ($user, $password) = split(/:/, $conf{PAYSYS_PASSWD});

  if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
    $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//i;
    my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));

    if ((!$REMOTE_PASSWD)
      || ($REMOTE_PASSWD && $REMOTE_PASSWD ne $password)
      || (!$REMOTE_USER)
      || ($REMOTE_USER && $REMOTE_USER ne $user)) {
      print "WWW-Authenticate: Basic realm=\"Billing system\"\n";
      print "Status: 401 Unauthorized\n";
      print "Content-Type: text/html\n\n";
      print "Access Deny";
      exit;
    }
  }
}

our $Paysys = Paysys->new($db, $admin, \%conf);
our $payments = Finance->payments($db, $admin, \%conf);
our $users = Users->new($db, $admin, \%conf);

#debug =========================================
if ($debug > 1) {
  mk_log('', { DATA => \%FORM });
}
#NEW SCHEME ====================================
paysys_new_scheme();
exit;


#**********************************************************
=head2 paysys_new_scheme()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_new_scheme {

  require Paysys::User_portal;

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
  });

  #test systems
  my $test_system = q{};
  if ($conf{PAYSYS_TEST_SYSTEM} || $FORM{PAYSYS_TEST_SYSTEM}) {
    my ($ips, $pay_system) = split(/:/, $conf{PAYSYS_TEST_SYSTEM});
    if (check_ip($ENV{REMOTE_ADDR}, $ips)) {
      $test_system = $FORM{PAYSYS_TEST_SYSTEM} || $pay_system;
    }
  }

  foreach my $connected_system (@$connected_systems_list){
    my $remote_ip = $ENV{REMOTE_ADDR};
    my $paysys_ip = $connected_system->{paysys_ip} || '';
    my $module    = $connected_system->{module};

    if ($test_system) {
      if ($test_system ne $module) {
        next;
      }
      $paysys_ip = $ENV{REMOTE_ADDR};
    }

    if(check_ip($remote_ip, $paysys_ip)){
      if($debug > 0) {
        mk_log('', { PAYSYS_ID => $module, DATA => \%FORM });
      }

      my $Paysys_plugin = _configure_load_payment_module($module);

      if($debug > 2) {
        mk_log("$module loaded", { PAYSYS_ID => $module });
      }

      my $Payment_system = $Paysys_plugin->new($db, $admin, \%conf, {
        CUSTOM_NAME => $connected_system->{name},
        CUSTOM_ID   => $connected_system->{paysys_id}
      });

      if($debug > 2) {
        mk_log("$module object created", { PAYSYS_ID => $module });
      }

      if ($Payment_system->can('proccess')) {
        $Payment_system->proccess(\%FORM);

        if($debug > 2) {
          mk_log("$module process ended", { PAYSYS_ID => $module });
        }
      }
      else {
        mk_log("$module don't have process statment", {
          HEADER    => 1,
          SHOW      => 1,
          PAYSYS_ID => $module
        });
      }

      return 1
    }
  }

  # payment function
  paysys_payment_gateway();

  return 1;
}

#**********************************************************
=head2 paysys_payment_gateway()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_payment_gateway {
  # load header
  $html->{METATAGS} = templates('metatags');
  $html->{WEB_TITLE} = 'Payment Gateway';

  print $html->header();

  my ($result, $user_info) = paysys_check_user({
    CHECK_FIELD => $conf{PAYSYS_GATEWAY_IDENTIFIER} || 'UID',
    USER_ID     => $FORM{IDENTIFIER},
  });

  my %TEMPLATES_ARGS = ();

  if ($FORM{PAYMENT_SYSTEM}) {
    my $payment_system_info = $Paysys->paysys_connect_system_info({
      PAYSYS_ID => $FORM{PAYMENT_SYSTEM},
      MODULE    => '_SHOW',
      COLS_NAME => '_SHOW'
    });

    if($Paysys->{errno}){
      print $html->message('err', $lang{ERROR}, 'Payment system not exist');
    }
    else{
      my $Module = _configure_load_payment_module($payment_system_info->{module});
      my $Paysys_Object = $Module->new($db, $admin, \%conf, { HTML => $html });

      print $Paysys_Object->user_portal($user_info, { %FORM });
    }

    return 1;
  }

  if($result == 0){
    #SHOW TEMPLATE WITH PAYMENT SYSTEMS SELECT
    $TEMPLATES_ARGS{IDENTIFIER} = $FORM{IDENTIFIER};
    my $connected_systems = $Paysys->paysys_connect_system_list({
      PAYSYS_ID => '_SHOW',
      NAME      => '_SHOW',
      MODULE    => '_SHOW',
      STATUS    => 1,
      COLS_NAME => 1,
    });

    $TEMPLATES_ARGS{OPERATION_ID} = mk_unique_value(8, { SYMBOLS => '0123456789' });
    if (in_array('Maps', \@MODULES)) {
      #      $TEMPLATES_ARGS{MAP} = paysys_maps();
    }

    my $count = 1;
    foreach my $payment_system (@$connected_systems) {
      my $Module = _configure_load_payment_module($payment_system->{module});

      if ($Module->can('user_portal')) {
        $TEMPLATES_ARGS{PAY_SYSTEM_SEL} .= _paysys_system_radio({
          NAME    => $payment_system->{name},
          MODULE  => $payment_system->{module},
          ID      => $payment_system->{paysys_id},
          CHECKED => $count == 1 ? 'checked' : '',
        });
        $count++;
      }
    }

    $html->tpl_show(_include('paysys_main', 'Paysys'), \%TEMPLATES_ARGS,
      { OUTPUT2RETURN => 0});

    return 1;
  }
  elsif($result == 1){
    $html->message("err", $lang{USER_NOT_EXIST});
  }
  elsif($result == 11){
    $html->message("err", "Paysys" . $lang{DISABLE});
  }

  $html->tpl_show(_include('paysys_gateway', 'Paysys'), \%TEMPLATES_ARGS, { });

  return 1;
}

1;
