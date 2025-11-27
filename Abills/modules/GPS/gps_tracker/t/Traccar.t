#!/usr/bin/perl


BEGIN {
  our $libpath = '../../../../../';
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'lib/');
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . 'Abills/');
  unshift(@INC, $libpath . 'Abills/modules/');
  unshift(@INC, $libpath . "Abills/mysql/");
}

use strict;
use warnings;
use Test::More;
use Abills::Fetcher;

my $host = q{http://127.0.0.1:8790};
my $device_id = q{76877541};

my $request =<< "END";
{"location":{"timestamp":"2025-10-27T08:31:14.997Z","coords":{"latitude":48.5303561,"longitude":25.0484728,"accuracy":25.88,"speed":-1,"heading":-1,"altitude":320.6},"is_moving":true,"odometer":0,"battery":{"level":1,"is_charging":false},"activity":{"type":"still"},"extras":{},"_":"&id=76877541&lat=48.5303561&lon=25.0484728&timestamp=2025-10-27T08:31:14.997Z&","manual":true},"device_id":"$device_id"}
END

$request =~ s/\"/\\\"/xg;

web_request($host,  {
  POST         => $request,
  CURL_OPTIONS => '-i',
  DEBUG        => 1,
});

done_testing();

1;
