#!/usr/bin/perl
use strict;
use warnings;
use utf8;

use Test::More;

use Abills::Base qw/_bp/;
#BEGIN {
#  use FindBin '$Bin';
#  use lib $Bin . '/../';
#}

plan tests => 11;

my $BP_ARGS = { TO_CONSOLE => 1 };

our ($db, $admin, %conf);
require_ok 'libexec/config.pl';
require_ok('/usr/abills/Abills/mysql/Cams.pm');
Cams->import();

open(my $null_fh, '>', '/dev/null') or die('Open /dev/null');
select $null_fh;
#admin interface
$ENV{'REQUEST_METHOD'} = "GET";
$ENV{'QUERY_STRING'} = "user=abills&passwd=abills";
require_ok( "../cgi-bin/admin/index.cgi" );
select STDOUT;

require '/usr/abills/Abills/mysql/Cams.pm';

my $Cams = new_ok('Cams' => [ $db, $admin, \%conf ]);

my %test_stream = (
  NAME     => 'Test stream',
  IP       => '192.168.1.21',
  LOGIN    => 'admin',
  PASSWORD => 'password',
  URL      => '',
);

#
# DB logic tests
#
#
##  Users<->streams tests

my %test_tp = (
  NAME          => 'Test TP',
  STREAMS_COUNT => 1,
);
# Check not added without Abon ID

$Cams->tp_add(\%test_tp);
ok($Cams->{errno}, 'Not adding without Abon ID');


# Enable service for user
my $test_uid = 2;



# /*
# *  Streams
# */
my $new_stream_id = $Cams->streams_add( \%test_stream );
ok ($new_stream_id > 0, 'INSERT_ID ' . $new_stream_id . ' > 0');

my $db_test_stream = $Cams->streams_info( $new_stream_id );
ok(ref $db_test_stream eq 'HASH', 'Got hashref');

is( $test_stream{PASSWORD}, $db_test_stream->{password}, 'Password encode / decode works' );

my $db_streams_list = $Cams->streams_list( { SHOW_ALL_COLUMNS => 1 } );
my %streams_by_id = ();
map { $streams_by_id{$_->{id}} = $_ } @{$db_streams_list};

is($new_stream_id, $streams_by_id{$new_stream_id}->{id}, 'Simple check for list correct');

# Delete test_streams
$Cams->streams_del( { ID => $new_stream_id } );
ok (!$Cams->{errno}, 'Deleted without error');

# Check deleted
my $should_be_deleted_test_stream = $Cams->streams_info( $new_stream_id );
ok(!$should_be_deleted_test_stream, 'No deleted stream');




1;
