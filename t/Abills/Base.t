#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 20;

our $libpath;

BEGIN {
  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../';
  if ( $Bin =~ m/\/abills(\/)/x ) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  unshift @INC, $libpath . '/lib';
  unshift @INC, $libpath . '/Abills/modules';
  unshift @INC, $libpath . '/Abills/mysql';
}

use Abills::Base qw(date_format date_diff);
use Abills::Init qw($DATE $TIME);

is(date_diff('2018-03-01', '2018-03-02'), 1, '2018-03-01 - 2018-03-02 = 1');
is(date_diff('2018-03-01', '2018-03-24'), 23, '2018-03-01 - 2018-03-31 = 31');
is(date_diff('2018-03-26', '2018-04-01'), 6, '2018-03-26 - 2018-04-01 = 6');

### date_format old functionality

my $test_date = '2025-12-12';
my $test_time = '23:05:05';
my $test_format = '%d.%m.%Y %H:%M:%S';

is(date_format("$test_date $test_time", $test_format), '12.12.2025 23:05:05', 'Custom format date time');
is(date_format("$test_date $test_time", $test_format), date_legacy("$test_date $test_time", $test_format), 'New date format returns the same like legacy 1');

is(date_format("$test_date", $test_format), '12.12.2025 00:00:00', 'Custom format date');
is(date_format("$test_date", $test_format), date_legacy("$test_date", $test_format), 'New date format returns the same like legacy 2 ');

is(date_format('', '%Y-%m-%d %H:%M:%S'), "$DATE $TIME", 'Fallback current date');
is(date_format('', $test_format), date_legacy('', $test_format), 'New date format returns the same like legacy 3');

### date_format new functionality

my $default_date_format = '%Y-%m-%d %H:%M:%S';

# dates
is(date_format('2025.12.12', $default_date_format), '2025-12-12 00:00:00', '2025.12.12 -> 2025-12-12 00:00:00');
is(date_format('2025/12/12', $default_date_format), '2025-12-12 00:00:00', '2025/12/12 -> 2025-12-12 00:00:00');
is(date_format('2025\12\12', $default_date_format), '2025-12-12 00:00:00', '2025\12\12 -> 2025-12-12 00:00:00');
is(date_format('2025\9\12', $default_date_format), '2025-09-12 00:00:00', '2025\9\12 -> 2025-09-12 00:00:00');
is(date_format('20251212', $default_date_format), '2025-12-12 00:00:00', '20251212 -> 2025-12-12 00:00:00');
is(date_format('12122025', $default_date_format), '2025-12-12 00:00:00', '12122025 -> 2025-12-12 00:00:00');

is(date_format('251212 12:12:12', $default_date_format, '%y%m%d %H:%M:%S'), '2025-12-12 12:12:12', '251212 -> 2025-12-12 12:12:12');

# times
is(date_format('2025.12.12 10', $default_date_format), '2025-12-12 10:00:00', '2025.12.12 10 -> 2025-12-12 10:00:00');
is(date_format('2025.12.12 10:12', $default_date_format), '2025-12-12 10:12:00', '2025.12.12 10:12 -> 2025-12-12 10:12:00');
is(date_format('2025.12.12 9:12', $default_date_format), '2025-12-12 09:12:00', '2025.12.12 9:12 -> 2025-12-12 09:12:00');
is(date_format('2025.12.12 10:12:05', $default_date_format), '2025-12-12 10:12:05', '2025.12.12 10:12:05 -> 2025-12-12 10:12:05');

done_testing;

#TODO: delete in next year and relevant test cases
sub date_legacy {
  my ($date, $format) = @_;
  my $year   = 0;
  my $month  = 0;
  my $day    = 0;
  my $hour   = 0;
  my $min    = 0;
  my $sec    = 0;

  if ($date =~ m/(\d{4})\-(\d{2})\-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})/x) {
    $year   = $1 - 1900;
    $month  = $2 - 1;
    $day    = $3;
    $hour   = $4;
    $min    = $5;
    $sec    = $6;
  }
  elsif ($date =~ m/^(\d{4})\-(\d{2})\-(\d{2})$/x) {
    $year   = $1 - 1900;
    $month  = $2 - 1;
    $day    = $3;
  }
  else {
    ($sec, $min, $hour, $day, $month, $year) = (localtime time)[ 0, 1, 2, 3, 4, 5 ];
    $year = "0$year"  if ($year < 10);
    $day  = "0$day"   if ($day < 10);
    $month= "0$month" if ($month < 10);
    $hour = "0$hour"  if ($hour < 10);
    $min  = "0$min"   if ($min < 10);
    $sec  = "0$sec"   if ($sec < 10);
  }

  $date = POSIX::strftime( $format,
    localtime(POSIX::mktime($sec, $min, $hour, $day, $month, $year) ) );

  return $date;
}

1;