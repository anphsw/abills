#!/usr/bin/perl -w
# Sharing registration
#


use vars qw($begin_time %FORM %LANG $CHARSET 
  @MODULES
  @REGISTRATION
  $html
  $users
  $Bin
 );
BEGIN {
 my $libpath = '../';
 
 $sql_type='mysql';
 unshift(@INC, $libpath ."Abills/$sql_type/");
 unshift(@INC, $libpath);
 unshift(@INC, $libpath . 'libexec/');

 eval { require Time::HiRes; };
 if (! $@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();
   }
 else {
    $begin_time = 0;
  }
}


require "config.pl";
require "Abills/templates.pl";
require "Abills/defs.conf";

use Abills::Base;
use Abills::SQL;
use Abills::HTML;
use Users;
#use Paysys;
use Finance;
use Admins;
use Tariffs;
use Sharing;



$html = Abills::HTML->new({ CONF => \%conf });
my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd});
my $db = $sql->{db};
#Operation status
my $status = '';
#my $Paysys = Paysys->new($db, undef, \%conf);

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });
my $payments = Finance->payments($db, $admin, \%conf);
$users = Users->new($db, $admin, \%conf); 

print "Content-Type: text/html\n\n";
if (! defined( @REGISTRATION ) ) {

	exit;
}

$html->{language}=$FORM{language} if (defined($FORM{language}));
require "../language/$html->{language}.pl";


if ($FORM{module}) {
	my $m = $FORM{module};
	require "Abills/modules/$m/config";
	require "Abills/modules/$m/webinterface";
	$m = lc($m);
	my $function = $m . '_registration';
  $function->();
  
  exit;
}
elsif($#REGISTRATION == 0) {
	my $m = $REGISTRATION[0];
	require "Abills/modules/$m/config";
	require "Abills/modules/$m/webinterface";
	$m = lc($m);
	my $function = $m . '_registration';
  $function->();
  
  exit;
}

foreach my $m (@REGISTRATION) {
	#require "Abills/modules/$m/config";
	#require "Abills/modules/$m/webinterface";
  print $html->button($m, "module=$m");
}



