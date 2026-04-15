#!/usr/bin/perl

=head NAME

  Global Api test

=cut

use strict;
use warnings;
use Test::More;

BEGIN {
  use FindBin '$Bin';
  # why its not our?
  my $libpath = '/usr/abills/';

  if ($Bin =~ m/\/abills(\/)/x) {
    $libpath = substr($Bin, 0, $-[1]);
    $libpath .= '/';
  }

  unshift(@INC, $libpath . 'lib/');
}

use Abills::Api::Tests::Init qw(test_runner folder_list help $db $admin %conf @MODULES);
use Abills::Base qw(parse_arguments in_array cmd);

my $argv = parse_arguments(\@ARGV);

$argv->{DEBUG} //= 0;

start($argv);

#*******************************************************************
=head2 start() -

=cut
#*******************************************************************
sub start {
  my ($attr) = @_;

  my $module = $attr->{MODULE} || '';
  my $modules = get_modules();

  if ($module) {
    if (!$modules->{$module}) {
      print "Skip. Module did not enabled or does not exists or has not got test\n";
    }
    else {
      $modules = { $module => $modules->{$module} };
    }
  }

  return execute_tests($modules, $attr);
}

#*******************************************************************
=head2 execute_tests($modules) -

  Arguments:
    $modules
    $attr
  Results:
    TRUE or FALSE

=cut
#*******************************************************************
sub execute_tests {
  my ($modules, $attr) = @_;

  my $is_silent = ($attr->{EXECUTABLE_TESTS} && !$attr->{DEBUG}) ? 1 : 0;

  foreach my $mod (sort keys %{$modules}) {
    if ($modules->{$mod}->{own_test}) {
      next if ($attr->{SKIP_OWN_TESTS});
      my $result = cmd("perl $modules->{$mod}->{path}Api.t", {
        PARAMS => $attr,
        ARGV   => 1
      });

      if ($is_silent && $result =~ /Skip test runner, no tests for execute/gm) {
        next;
      }

      test_info({
        TEST_NAME => $modules->{$mod}->{name},
        TEST_CMD  => "$modules->{$mod}->{path}Api.t",
        RESULT    => $result,
        DEBUG     => $attr->{DEBUG}
      });
    }
    else {
      test_runner({
        path   => $modules->{$mod}->{path},
        argv   => $attr,
        silent => $is_silent
      });
    }
  }

  return 1;
}

#*******************************************************************
=head2 get_modules($attr) -

  Arguments:
    $attr
      TEST_NAME
      TEST_CMD
      RESULT
      DEBUG
  Results:
    TRUE or FALSE

=cut
#*******************************************************************
sub test_info {
  my ($attr) = @_;

  print "------------------RUN TEST $attr->{TEST_NAME}-----------------+\n";
  print "________________________COMMAND: perl $attr->{TEST_CMD}________________________________\n" if ($attr->{DEBUG} > 2);
  print $attr->{RESULT} || q{};
  print "------------------FINISH TEST $attr->{TEST_NAME}------------------\n\n";

  return 1;
}


#*******************************************************************
=head2 get_modules() -

  Arguments:
  Results:
    \%modules

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

  Arguments:

  Results:
    \%modules

=cut
#*******************************************************************
sub _core_modules_tests {
  $libpath //= '/usr/abills/';

  my $dir = $libpath . "t/Api";

  opendir(my $dh, $dir) or die "Cannot open directory $dir: $!";
  my @modules = readdir($dh);
  closedir($dh);

  @modules = grep {!in_array($_, [ 'Makefile', 'Api.t', 'Global.t', '.', '..' ])} @modules;
  my %modules = ();

  foreach my $mod (@modules) {
    my $test_start_file = $libpath . "t/Api/$mod/Api.t";
    $modules{$mod} = {
      path     => $libpath . "t/Api/$mod/",
      own_test => (-f $test_start_file) ? 1 : 0,
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
  $libpath //= '/usr/abills/';

  my %modules = ();

  foreach my $mod (@MODULES) {
    my $schemas_dir = $libpath . "Abills/modules/$mod/t/schemas";
    my $test_start_file = $libpath . "Abills/modules/$mod/t/Api.t";
    next if (!-d $schemas_dir);
    $modules{$mod} = {
      path     => $libpath . "Abills/modules/$mod/t/",
      own_test => (-f $test_start_file) ? 1 : 0,
      name     => $mod
    };
  }

  return \%modules;
}

done_testing();

1;
