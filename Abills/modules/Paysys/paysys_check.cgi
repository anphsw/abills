#!/usr/bin/perl

=head1 NAME

  Paysys processing system
  Check payments incoming request

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
use Abills::Base qw(decode_base64 check_ip in_array);
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

if (in_array('Multidoms', \@MODULES) && $conf{MULTIDOMS_DOMAIN_ID}) {
  if ($ENV{PATH_INFO} && $ENV{PATH_INFO} =~ /(?<=\/)\d+/) {
    my ($domain) = $ENV{PATH_INFO} =~ /(?<=\/)\d+/gm;
    $ENV{PATH_INFO} =~ s/^\/\d+//;

    eval {
      require Multidoms;
      Multidoms->import();
    };

    if ($domain && !$@) {
      my $Domains = Multidoms->new($db, $admin, \%conf);
      my $domains_list = $Domains->multidoms_domains_list({
        COLS_NAME => 1,
        ID        => $domain
      });

      $ENV{DOMAIN_ID} = $domain if ($domains_list);
    }
  }
};

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

our Paysys $Paysys = Paysys->new($db, $admin, \%conf);
our Finance $payments = Finance->payments($db, $admin, \%conf);
our Users $users = Users->new($db, $admin, \%conf);

#debug =========================================
if ($debug > 1) {
  mk_log('', { DATA => \%FORM });
}
#NEW SCHEME ====================================
paysys_new_scheme();


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
    SORT             => 'pc.paysys_id',
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAGE_ROWS        => 50,
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
    my $id        = $connected_system->{paysys_id};

    if ($test_system) {
      if ($test_system ne $module) {
        next;
      }
      $paysys_ip = $ENV{REMOTE_ADDR};
    }

    next if ($conf{PAYSYS_PAYSYS_ID_CHECK} && $ENV{HTTP_PAYSYSID} && !($ENV{HTTP_PAYSYSID} eq $id));

    my $allowed = 0;

    # Revenucat only header AUTH
    if ($conf{PAYSYS_BEARER_TOKEN_AUTH} && $ENV{HTTP_CGI_AUTHORIZATION} && $paysys_ip =~ /BEARER_TOKEN/) {
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/Bearer\s+//i;

      my $bearer = $conf{$paysys_ip} || '--';

      $allowed = 1 if ($ENV{HTTP_CGI_AUTHORIZATION} eq $bearer);
    }

    if ($conf{PAYSYS_ALLOW_DOMAIN} && $paysys_ip =~ /domain/) {
      my ($domain) = $paysys_ip =~ /(?<=domain: ).*/g;

      require Socket;
      Socket->import();

      my @addresses = gethostbyname($domain) or next;
      @addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];

      $paysys_ip = join(', ', @addresses);
    }

    if (check_ip($remote_ip, $paysys_ip) || $allowed){
      if ($debug > 0) {
        mk_log('', { PAYSYS_ID => $id, DATA => \%FORM });
      }

      my $Paysys_plugin = _configure_load_payment_module($module, 0, \%conf);

      if ($debug > 2) {
        mk_log("$module loaded", { PAYSYS_ID => $id });
      }

      my $Payment_system = $Paysys_plugin->new($db, $admin, \%conf, {
        CUSTOM_NAME => $connected_system->{name},
        CUSTOM_ID   => $connected_system->{paysys_id}
      });

      if ($debug > 2) {
        mk_log("$module object created", { PAYSYS_ID => $id });
      }

      if ($Payment_system->can('proccess')) {
        $Payment_system->proccess(\%FORM);

        if ($debug > 2) {
          mk_log("$module process ended", { PAYSYS_ID => $id });
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

  if ($debug > 1) {
    mk_log('', { REPLY => 1 });
  }

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
  $html->{WEB_TITLE} = $lang{MAKE_PAYMENT};

  print $html->header();

  if ($html->{TYPE} && $html->{TYPE} eq 'xml') {
    print qq{  <info>Welcome to xml payment gateway</info>
  <error>403</error>};
    return 1;
  }

  my ($result, $user_info) = paysys_check_user({
    CHECK_FIELD => $conf{PAYSYS_GATEWAY_IDENTIFIER} || 'UID',
    USER_ID     => $FORM{IDENTIFIER},
  });

  my %TEMPLATES_ARGS = ();

  if ($result == 0) {
    my $user = Users->new($db, $admin, \%conf);
    $user->info($user_info->{UID});

    paysys_payment({ USER_INFO => $user, PAYMENTS_PORTAL => 1 });

    return 1;
  }
  elsif ($result == 1) {
    $html->message('err', $lang{USER_NOT_EXIST});
  }
  elsif ($result == 11) {
    $html->message('err', 'Paysys ' . $lang{DISABLE});
  }

  $TEMPLATES_ARGS{IDENTIFIER_TEXT} = $lang{ENTER} . ' ' . ($lang{$conf{PAYSYS_GATEWAY_IDENTIFIER} || q{}} || 'UID');

  $html->tpl_show(_include('paysys_gateway', 'Paysys'), \%TEMPLATES_ARGS, { });

  return 1;
}

1;
