#!/usr/bin/perl

=head NAME

  Global Api test

=cut

use strict;
use warnings;

use Test::More;

BEGIN {
  use FindBin '$Bin';
  our $libpath = '/usr/abills/';

  if ($Bin =~ m/\/abills(\/)/) {
    $libpath = substr($Bin, 0, $-[1]);
    $libpath .= '/';
  }

  unshift(@INC, $libpath . 'lib/');
}

use Abills::Api::Tests::Init qw(test_runner folder_list help $db $admin %conf @MODULES);
use Abills::Base qw(parse_arguments in_array cmd);

my $argv = parse_arguments(\@ARGV);

my $module = $argv->{MODULE} || '';

start();

#*******************************************************************
=head2 start() -

=cut
#*******************************************************************
sub start {
  my $modules = get_modules();

  if ($module) {
    if (!$modules->{$module}) {
      print "Skip. Module did not enabled or does not exists or has not got test\n";
    }
    else {
      $modules = { $module => $modules->{$module} };
    }
  }

  execute_tests($modules);
}

#*******************************************************************
=head2 execute_tests() -

=cut
#*******************************************************************
sub execute_tests {
  my ($modules) = shift;

  foreach my $mod (sort keys %{$modules}) {
    if ($modules->{$mod}->{own_test}) {
      next if ($argv->{SKIP_OWN_TESTS});
      my $result = cmd("perl $modules->{$mod}->{path}Api.t", {
        PARAMS => $argv,
        ARGV   => 1
      });

      print "------------------RUN TEST $modules->{$mod}->{name}------------------\n";
      print $result;
      print "------------------FINISH TEST $modules->{$mod}->{name}------------------\n\n";
    }
    else {
      test_runner({
        path => $modules->{$mod}->{path},
        argv => $argv,
      });
    }
  }
}

#*******************************************************************
=head2 get_modules() -

=cut
#*******************************************************************
sub get_modules {
  my $core_modules = _core_modules_tests();
  my $modules = _modules_tests();

  my %modules = (%$core_modules, %$modules);

  return \%modules;
}

#*******************************************************************
=head2 _core_modules_tests() -

=cut
#*******************************************************************
sub _core_modules_tests {
  my $dir = $libpath . "t/Api";
  opendir(my $dh, $dir) or die "Cannot open directory $dir: $!";
  my @modules = readdir($dh);
  closedir($dh);

  @modules = grep {!in_array($_, [ 'Makefile', 'Api.t', 'Global.t', '.', '..' ])} @modules;
  my %modules = ();

  foreach my $mod (@modules) {
    $modules{$mod} = {
      path     => $libpath . "t/Api/$mod/",
      own_test => -f $libpath . "t/Api/$mod/Api.t" ? 1 : 0,
      name     => $mod
    };
  }

  return \%modules;
}

#*******************************************************************
=head2 _modules_tests() -

=cut
#*******************************************************************
sub _modules_tests {
  my %modules = ();

  foreach my $mod (@MODULES) {
    next if (!-d $libpath . "Abills/modules/$mod/t/schemas");
    $modules{$mod} = {
      path     => $libpath . "Abills/modules/$mod/t/",
      own_test => -f $libpath . "Abills/modules/$mod/t/Api.t" ? 1 : 0,
      name     => $mod
    };
  }

  return \%modules;
}

done_testing();

1;
