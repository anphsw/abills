#!/usr/bin/perl

=head1 NAME

  Mac_auth test

=cut

use warnings;
use strict;
#use Test::Simple tests => 5;
#use Memoize;
use Benchmark qw/:all/;


BEGIN {
  our %conf;
  use FindBin '$Bin';
  unshift(@INC, $Bin . "/../libexec/");

  do "config.pl";

  unshift(@INC,
    $Bin . "/../lib/",
    $Bin . "/../Abills/$conf{dbtype}");
}

our (
  %conf,
  @MODULES
);

use Abills::Base qw(check_time parse_arguments mk_unique_value in_array);
use Abills::SQL;

my $begin_time = check_time();
my $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { %conf,
    db_engine => 'dbcore'
  });

require Abills::Misc;

my $count = 1000000;

my $plugin_name = 'Internet' . '::Base';

timethis($count, sub { _eval($plugin_name) });

timethis($count, sub { _load_module($plugin_name) });

sub _eval {
  my ($modname) = @_;

  if ($modname =~ /^[\w.]+$/) {
    print "Not module\n";
    return;
  }

  eval "require $modname";

  return 1;
}

sub _load_module {
  my ($modname) = @_;

  load_module($modname, { LOAD_PACKAGE => 1 });

  return 1;
}

1