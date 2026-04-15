#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More;

use DBI;
use FindBin '$Bin';
use lib '../../../lib/';

BEGIN {
  diag('Modules initialise');
  subtest 'load_modules' => sub {

    use_ok('Abills::Init');
    use_ok('Abills::Experimental::MockDB');
    use_ok('Control::Services');
    use_ok('Abills::Base');
  };
}

our (
  %conf,
  $admin,
  $db
);

my $MockDB = Abills::Experimental::MockDB->connect();

$db = $MockDB->{db};
$admin->{db} = $MockDB->{db};

require Abills::Misc;

my Control::Services $Services;

$Services = new_ok('Control::Services' => [ $MockDB->{db}, $admin, \%conf ]);

my $argv = parse_arguments(\@ARGV);
my $user = get_test_user($argv);

my $services = $Services->get_user_services({
  uid => $user->{UID} || 1,
});

ok(exists $services->{Internet}, 'Internet exists');
ok(ref $services->{Internet} eq 'ARRAY', 'Internet is array');
ok(scalar @{$services->{Internet}} > 0, 'Internet has at least one element');

my $services_internet = $Services->get_user_services({
  uid     => $user->{UID} || 1,
  service => 'Internet'
});

is(ref $services_internet, 'ARRAY', '"list" is an array reference');

my $services_result = $Services->get_services({
  UID       => $user->{UID} || 1,
  REDUCTION => $user->{REDUCTION},
});

ok(exists $services_result->{list}, 'The "list" field exists');
is(ref $services_result->{list}, 'ARRAY', '"list" is an array reference');
ok(scalar @{$services_result->{list}} > 0, '"list" contains at least one element');

my $first = $services_result->{list}[0];
ok(exists $first->{MODULE_NAME}, 'The element contains MODULE_NAME field');
is($first->{MODULE_NAME}, 'Internet', 'MODULE_NAME equals "Internet"');


done_testing();

1;
