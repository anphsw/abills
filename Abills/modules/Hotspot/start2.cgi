#!/usr/bin/perl

use strict;
use warnings;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  %FORM,
  %COOKIES,
);

BEGIN {
  our $libpath = '../';
  eval { do "$libpath/libexec/config.pl" };
  our %conf;

  if (!%conf) {
    print "Content-Type: text/plain\n\n";
    print "Error: Can't load config file 'config.pl'\n";
    print "Create ABillS config file /usr/abills/libexec/config.pl\n";
    exit;
  }

  my $sql_type = $conf{dbtype} || 'mysql';
  unshift(@INC,
    $libpath . 'Abills/modules/',
    $libpath . "Abills/$sql_type/",
    $libpath . '/lib/',
    $libpath . 'Abills/',
    $libpath
  );
}

if (!$ENV{'REQUEST_METHOD'}) {
  print "Execute from console.\n";
  exit;
}

use Abills::Base qw/_bp/;
use Abills::SQL;
use Admins;
use Users;
use Internet;
use Tariffs;
use Hotspot;

require Abills::Templates;
require Abills::Misc;

our $html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
    METATAGS => templates('metatags'),
    COLORS   => $conf{UI_COLORS},
    STYLE    => 'default',
  }
);
$html->{show_header} = 1;

do "../language/english.pl";
if (-f "../language/$html->{language}.pl") {
  do "../language/$html->{language}.pl";
}

our $db = Abills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin    = Admins->new($db, \%conf);
our $users    = Users->new($db, $admin, \%conf);
our $user     = Users->new($db, $admin, \%conf);
our $Internet = Internet->new($db, $admin, \%conf);
our $Tariffs  = Tariffs->new($db, \%conf, $admin);
our $Hotspot  = Hotspot->new($db, $admin, \%conf);
Conf->new($db, $admin, \%conf);

require Hotspot::HotspotBase;

# print "Content-type:text/html\n\n";
hotspot_init();

hotspot_radius_error() if ($FORM{error});
hotspot_pre_auth();
hotspot_auth();
hotspot_registration();

print "Content-type:text/html\n\n";
print "Ok";

exit;

1;