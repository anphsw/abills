#!/usr/bin/perl
#use strict;
use warnings;

use Test::More qw/no_plan/;
use Abills::Base qw/mk_unique_value/;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=abills&passwd=abills";

use vars qw(
  $sql_type
  $global_begin_time
  %conf
  @MODULES
  %functions
  %FORM
  $users
  $db
  $admin
 );

require_ok( "../libexec/config.pl" );

open ( my $HOLE, '>>', '/dev/null' );
disable_output();
require_ok( "../cgi-bin/admin/index.cgi" );
require_ok( "../Abills/modules/Hotspot/webinterface" );
enable_otput();

#Initialization
require_ok( 'Hotspot' );

my $Hotspot = Hotspot->new( $db, $admin, \%conf );

#$Hotspot->{debug} = 1;

my $test_session_id = mk_unique_value(32);
my $test_browser_name = 'Test';


visit_add();
visit_list($test_session_id);

login_add();
login_list_info($test_session_id);

sub visit_add{
  print_header("VISIT_ADD");
  $Hotspot->visits_add({
      ID => $test_session_id,
      BROWSER => $test_browser_name
    });
  ok(!$Hotspot->{errno}, 'Successfully added new user')
}

sub visit_list{
  print_header("VISIT_LIST");
  my ($session_id) = @_;
  my $visits_list = $Hotspot->visits_list({
      ID => $session_id,
      SHOW_ALL_COLUMNS => 1,
    });

  ok(!$Hotspot->{errno}, 'Got visits list without errors');
  ok(scalar @$visits_list > 0, 'Got non-empty visits list');

  my $visit = $visits_list->[0];

  ok(ref $visit eq 'HASH', 'Got hash inside list');
  ok( exists $visit->{FIRST_SEEN}, 'Has FIRST_SEEN field' );
  ok($visit->{FIRST_SEEN} && $visit->{FIRST_SEEN} ne '0000-00-00 00:00:00', "Has first seen and it's non-empty" );

};

sub login_add{
  print_header("LOGIN_ADD");
  $Hotspot->logins_add( {
      VISIT_ID => $test_session_id,
      UID      => 2,
    });

  ok(!$Hotspot->{errno}, 'Added login without errors');
}

sub login_list_info {
  my ($session_id) = @_;

  print_header("LOGIN_LIST_INFO");

  # Try to search
  my $logins_list = $Hotspot->logins_list({ VISIT_ID => $session_id, SHOW_ALL_COLUMNS => 1, });
  ok(scalar @$logins_list > 0, 'Got non-empty visits list');

  my $login = $logins_list->[0];

  ok(ref $login eq 'HASH', 'Got hash inside list');
  ok(exists $login->{VISIT_ID}, 'Has visit_id in result');

  # Check info
  my $login2 = $Hotspot->logins_info_for_session($session_id);
  ok(ref $login2 eq 'HASH', 'Got hash inside info list');
  ok(exists $login2->{VISIT_ID}, 'Has visit_id in result');

  # Check found result has same session id as info
  ok ($login->{VISIT_ID} eq $login2->{VISIT_ID}, 'found result has same session id as info');

  #Check browser is correct
  ok($login2->{BROWSER} eq $test_browser_name, 'Browser is ok');

}

sub disable_output{
  select $HOLE;
}

sub enable_otput{
  select STDOUT;
}

sub print_header {
  print "###########################################\n";
  print "     " . shift . "\n";
  print "###########################################\n";
}
