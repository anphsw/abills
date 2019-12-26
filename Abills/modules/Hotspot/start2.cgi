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
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  do $Bin . '/../language/english.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../Abills',
    $Bin . '/../Abills/mysql',
    $Bin . '/../Abills/modules',
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
use Hotspot::HotspotBase;

our $db = Abills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin    = Admins->new($db, \%conf);
our $users    = Users->new($db, $admin, \%conf);
our $Internet = Internet->new($db, $admin, \%conf);
our $Tariffs  = Tariffs->new($db, \%conf, $admin);
our $Hotspot  = Hotspot->new($db, $admin, \%conf);

# print "Content-type:text/html\n\n";
parse_query();
get_cookies();
hotspot_init();

hotspot_radius_error() if ($FORM{error});
hotspot_pre_auth();
hotspot_auth();
hotspot_registration();

print "Content-type:text/html\n\n";
print "Ok";

exit;

1;