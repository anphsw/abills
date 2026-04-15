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
    $libpath . '/lib/',
    $libpath);

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
use Abills::Base qw(decode_base64 check_ip in_array escape_for_sql json_former xml_former);
use Users;
use Paysys;
use Paysys::Init;
use Paysys::Core;
use Finance;
use Admins;
use Conf;

our $silent = 1;
our %lang;
our $debug = $conf{PAYSYS_DEBUG} || 0;
our $html = Abills::HTML->new({ CONF => \%conf });
our $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { %conf,
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef
  });

our $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} });
$admin->{DATE} = $DATE;

my $path_paysys_id = 0;
my $path_merchant_id = 0;

if ($ENV{REQUEST_URI} && !$ENV{PATH_INFO}) {
  $ENV{PATH_INFO} = $ENV{REQUEST_URI};
  $ENV{PATH_INFO} =~ s/\/paysys_check.cgi//x;
}

if ($ENV{PATH_INFO}) {
  # Handle multidoms domain ID (legacy format: /{domain_id})
  if (in_array('Multidoms', \@MODULES) && $conf{MULTIDOMS_DOMAIN_ID}) {
    if ($ENV{PATH_INFO} =~ /(?<=\/)\d+/xm) {
      my ($domain) = $ENV{PATH_INFO} =~ /(?<=\/)\d+/xgm;
      $ENV{PATH_INFO} =~ s/^\/\d+//xm;

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

        #TODO remove and make as attr for Paysys::Core
        $ENV{DOMAIN_ID} = $domain if ($domains_list);
      }
    }
  }

  $path_paysys_id = _path_param($ENV{PATH_INFO}, 'paysys_id');
  $path_merchant_id = _path_param($ENV{PATH_INFO}, 'merchant_id');
}

# read conf for DB
our $Conf = Conf->new($db, $admin, \%conf);
do "../language/$html->{language}.pl";

delete $FORM{language};
require Abills::Misc;
use Abills::Templates;
load_module('Paysys', $html);
require Paysys::Paysys_Base;

my $REMOTE_ADDR = $ENV{REMOTE_ADDR} || '0.0.0.0';

if ($conf{AUTH_X_FORWARDED} && $conf{AUTH_X_DOMAIN} && in_array($ENV{HTTP_HOST}, [ split(',\s?', $conf{AUTH_X_DOMAIN}) ])) {
  $REMOTE_ADDR = $ENV{$conf{AUTH_X_FORWARDED}} if ($ENV{$conf{AUTH_X_FORWARDED}});
}

my $Paysys_Core = Paysys::Core->new($db, $admin, \%conf, {
  REMOTE_ADDR => $REMOTE_ADDR,
});

#@deprecated Check allow ips
if ($conf{PAYSYS_IPS}) {
  if ($REMOTE_ADDR && !check_ip($REMOTE_ADDR, $conf{PAYSYS_IPS})) {
    print "Content-Type: text/html\n\n";
    my $error = "Error: IP '$REMOTE_ADDR' DENY by System";
    sendmail("$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "ABillS - Paysys", "IP '$REMOTE_ADDR' DENY by System",
      "$conf{MAIL_CHARSET}", "2 (High)");
    $Paysys_Core->mk_log($error);
    exit;
  }
}

#@deprecated CGI Auth for modules
if ($conf{PAYSYS_PASSWD}) {
  my ($user, $password) = split(/:/x, $conf{PAYSYS_PASSWD});

  if (defined($ENV{HTTP_CGI_AUTHORIZATION})) {
    $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//xi;
    my ($REMOTE_USER, $REMOTE_PASSWD) = split(/:/x, decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));

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

Abills::Templates::template_init({
  #BIN   => $Bin,
  LIBPATH => $libpath,
  ADMIN   => $admin,
  HTML    => $html,
  FORM    => \%FORM,
  LANG    => \%lang,
  CONF    => \%conf
});


#debug =========================================
if ($debug > 1) {
  $Paysys_Core->mk_log('', { DATA => \%FORM });
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

  my $connected_systems_list = $Paysys->paysys_connect_system_list({
    SORT             => 'pc.paysys_id',
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    PAGE_ROWS        => 50,
  });

  #test systems
  my $test_system = q{};
  #@deprecated use PAYSYS_TEST_SYSTEM_IPS as main option
  if ($conf{PAYSYS_TEST_SYSTEM} || $FORM{PAYSYS_TEST_SYSTEM}) {
    my ($ips, $pay_system) = split(/:/x, $conf{PAYSYS_TEST_SYSTEM});
    if (check_ip($REMOTE_ADDR, $ips)) {
      $test_system = $FORM{PAYSYS_TEST_SYSTEM} || $pay_system;
    }
  }
  # strange solution, because system do not parse query params if POST request
  elsif ($conf{PAYSYS_TEST_SYSTEM_IPS} && $ENV{HTTP_X_PAYMENT_SYSTEM} && check_ip($REMOTE_ADDR, $conf{PAYSYS_TEST_SYSTEM_IPS})) {
    $test_system = $ENV{HTTP_X_PAYMENT_SYSTEM};
  }

  foreach my $connected_system (@$connected_systems_list) {
    my $paysys_ip = $connected_system->{paysys_ip} || '';
    my $module = $connected_system->{module};
    my $id = $connected_system->{paysys_id};

    if ($test_system) {
      if ($test_system ne $module) {
        next;
      }
      $paysys_ip = $REMOTE_ADDR;
    }

    next if ($conf{PAYSYS_PAYSYS_ID_CHECK} && $ENV{HTTP_PAYSYSID} && !($ENV{HTTP_PAYSYSID} eq $id));

    my $allowed = 0;

    # Revenucat only header AUTH
    if ($conf{PAYSYS_BEARER_TOKEN_AUTH} && $ENV{HTTP_CGI_AUTHORIZATION} && $paysys_ip =~ /BEARER_TOKEN/) {
      $ENV{HTTP_CGI_AUTHORIZATION} =~ s/Bearer\s+//xi;

      my $bearer = $conf{$paysys_ip} || '--';

      $allowed = 1 if ($ENV{HTTP_CGI_AUTHORIZATION} eq $bearer);
    }

    if ($conf{PAYSYS_ALLOW_NON_IP_AUTH}) {
      $allowed = 1 if ($path_paysys_id == $id);
    }

    if ($conf{PAYSYS_ALLOW_DOMAIN} && $paysys_ip =~ /domain/) {
      my ($domain) = $paysys_ip =~ /(?<=domain: ).*/mxg;

      require Socket;
      Socket->import();

      my @addresses = gethostbyname($domain) or next;
      @addresses = map {inet_ntoa($_)} @addresses[4 .. $#addresses];

      $paysys_ip = join(', ', @addresses);
    }

    if (check_ip($REMOTE_ADDR, $paysys_ip) || $allowed) {
      if ($debug > 0) {
        $Paysys_Core->mk_log('', { PAYSYS_ID => $id, DATA => \%FORM });
      }

      my $Paysys_plugin = _configure_load_payment_module($module, 0, \%conf);

      if ($debug > 2) {
        $Paysys_Core->mk_log("$module loaded", { PAYSYS_ID => $id });
      }

      my $Payment_system = $Paysys_plugin->new($db, $admin, \%conf, {
        CUSTOM_NAME  => $connected_system->{name},
        CUSTOM_ID    => $connected_system->{paysys_id},
        SUBSYSTEM_ID => $connected_system->{subsystem_id},
        REMOTE_ADDR  => $REMOTE_ADDR,
      });

      # if defined from path params and do not supports own validation on module
      if ($conf{PAYSYS_ALLOW_NON_IP_AUTH} && $allowed) {
        my $own_validation = $Payment_system->{OWN_VALIDATION} || 0;

        return 1 if (!$own_validation);
      }

      if ($debug > 2) {
        $Paysys_Core->mk_log("$module object created", { PAYSYS_ID => $id });
      }

      if ($Payment_system->can('proccess')) {
        $Payment_system->{MERCHANT_ID} = $path_merchant_id || 0;

        $Payment_system->proccess(\%FORM);

        if ($debug > 2) {
          $Paysys_Core->mk_log("$module process ended", { PAYSYS_ID => $id });
        }
      }
      else {
        $Paysys_Core->mk_log("$module don't have process statement", {
          SHOW        => 1,
          PAYSYS_ID   => $module,
          REMOTE_ADDR => $REMOTE_ADDR
        });
      }

      return 1
    }
  }

  return paysys_payment_gateway();
}

#**********************************************************
=head2 paysys_web_gateway()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_payment_gateway {

  my $user_agent = $ENV{HTTP_USER_AGENT} || '';
  my $is_browser = 0;

  my $DESKTOP_RE = qr{Mozilla|Chrome|Safari|Firefox|Edge|Opera}xi;
  my $MOBILE_RE  = qr{Mobile|Android|iPhone|iPad}xi;

  if ($user_agent =~ qr/$DESKTOP_RE|$MOBILE_RE/x) {
    $is_browser = 1;
  }

  if ($is_browser) {
    paysys_web_gateway();
  }
  else {
    my ($headers, $body) = paysys_payment_gateway_401();

    print join("\n", @$headers);
    print $body;
  }

  if ($debug > 1) {
    $Paysys_Core->mk_log('', { REPLY => 1 });
  }

  return 1;
}

#**********************************************************
=head2 paysys_payment_gateway_401()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_payment_gateway_401 {
  my $accept_header = $ENV{HTTP_ACCEPT} || '';

  my %response = (
    error   => 'Unauthorized request',
    message => 'HTML response is disabled for non-browser requests',
  );

  my $content_type = 'json';
  my $response = '';

  if ($accept_header =~ /xml/xi) {
    $content_type = 'xml';
    $response = xml_former(\%response, { PRETTY => 1, ROOT_NAME => 'response' });
  }
  else {
    $response = json_former(\%response, { PRETTY => 1, ROOT_NAME => 'response' });
  }

  my @headers = (
    "Status: 401",
    "Content-Type: application/$content_type\n\n",
  );

  return (\@headers, $response);
}

#**********************************************************
=head2 paysys_web_gateway()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub paysys_web_gateway {

  require Paysys::User_portal;

  # load header
  $html->{METATAGS} = templates('metatags_client');
  $html->{WEB_TITLE} = $lang{MAKE_PAYMENT};

  print $html->header();

  if ($html->{TYPE} && $html->{TYPE} eq 'xml') {
    my $res = << "XML";
<response>
<info>Welcome to xml payment gateway</info>
<error>403</error>
</response>
XML

    print $res;
    return 1;
  }

  my ($result, $user_info) = $Paysys_Core->paysys_check_user({
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

  $html->tpl_show(_include('paysys_gateway', 'Paysys'), \%TEMPLATES_ARGS, {});

  return 1;
}

#**********************************************************
=head2 _path_param()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub _path_param {
  my ($path, $name) = @_;

  my ($value) = $path =~ m{/\Q$name\E/([^/]+)}x
    or return 0;

  return escape_for_sql(int($value));
}

1;
