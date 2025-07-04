#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

use FindBin '$Bin';
use lib '../../../lib/';

our (
  %conf
);

use Abills::Base qw(show_hash parse_arguments);
use Abills::Init;
our Users $users;

require_ok( 'Control::Services' );

my $argv = parse_arguments(\@ARGV);
my $user_info = get_test_user($argv);
my $modules = $argv->{MODULES};
my $service_result = get_services($user_info, { MODULES => $modules });

show_hash($service_result, { DELIMITER => "\n" });

1;

