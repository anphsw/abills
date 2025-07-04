package Abills::Init;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Abills::Init

=head2 SYNOPSIS

  This package contains boilerplate code to use in scripts to load %config init $db and $admin objects

=head2 USAGE

 Of course to init this you need to know libraries location, so you can use this code to load
 
 BEGIN {
    our $Bin;
    use FindBin '$Bin';
    if ( $Bin =~ m/\/abills(\/)/ ){
      my $libpath = substr($Bin, 0, $-[1]);
      unshift (@INC, "$libpath/lib");
    }
    else {
      die " Should be inside /usr/abills dir \n";
    }
  }
  
  use Abills::Init qw/$db $admin %conf/;
 
=cut

our $libpath;
BEGIN {
  our $Bin;
  use FindBin '$Bin';

  $libpath = $Bin . '/../'; #assuming we are in /usr/abills/whatever
  if ($Bin =~ m/\/abills(\/)/x) {
    $libpath = substr($Bin, 0, $-[1]);
  }

  die "No \$libpath \n" if (!$libpath);

  unshift(@INC,
    "$libpath",
    "$libpath/Abills",
    "$libpath/lib",
    "$libpath/Abills/modules",
    "$libpath/Abills/mysql"
  );
}

use parent 'Exporter';
use JSON qw(decode_json);

our $VERSION = 0.02;

our ($admin, $db, $users);

our @EXPORT = qw(
  $db
  $admin
  %conf
  $base_dir
  $DATE
  $TIME
  $users
  @MODULES
  $var_dir
  get_test_user
  get_tests
);
our @EXPORT_OK = qw(
  $db
  $admin
  %conf
  get_test_user
  get_tests
);


# Declare vars we should read from config.pl
our (
  %conf,
  @MODULES,
  $DATE, $TIME,
  $base_dir,
  $lang_path,
  $lib_path,
  $var_dir
);

eval {
  do "$libpath/libexec/config.pl";
};

if ($@) {
  print "Content-Type: text/html\n\n";
  print "Can't load config file 'config.pl' <br>";
  print "Check ABillS config file /usr/abills/libexec/config.pl";
  die;
}

use Admins;
use Users;
require Abills::SQL;

# TODO: implement sub import, analyze what we have to import and init only needed objects
# TODO: add export of html object and base lang load optionally

$db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'}, {
  CHARSET => $conf{dbcharset}
});
$admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.10' });

use Conf;
Conf->new($db, $admin, \%conf);

$users = Users->new($db, $admin, \%conf);


#**********************************************************
=head get_test_user($attr) - Get test user

  Arguments:
    $attr
      USER


  Returns:
    $user_info

=cut
#**********************************************************
sub get_test_user {
  my ($attr) = @_;

  my $test_user = $attr->{USER} || $conf{API_TEST_USER_LOGIN} || 'test';
  my $users_list = $users->list({
    LOGIN     => $test_user,
    COLS_NAME => 1,
  });

  if ($users->{TOTAL} < 1) {
    #_log("test user not exists '$test_user'");
    print "test user not exists '$test_user'";
    return 0;
  }

  my $uid = $users_list->[0]->{uid};

  my $user_info = $users->info($uid);

  return $user_info;
}

#**********************************************************
=head get_test_user($attr) - Get test user

  Arguments:
    $attr
      USER


  Returns:
    $user_info

=cut
#**********************************************************
sub get_tests {
  my ($test_destination) = @_;
  my @tests_list = ();

  if (! $test_destination) {
    return \@tests_list;
  }

  if (-d $test_destination) {
    opendir(my $dh, $test_destination);
      while(my $filename = readdir $dh) {
        next if (($filename eq '.') || ($filename eq '..'));
        #print "$filename\n";
        my $test = get_test_file($test_destination .'/'.$filename);
        push @tests_list, @$test;
      }
    close($dh);
  }
  elsif(-f $test_destination) {
    my $test = get_test_file($test_destination);
    push @tests_list, @$test;
  }
  else {
    print "No test files\n";
  }

  return \@tests_list;
}

#**********************************************************
=head get_test_file($attr) - Get test user

  Arguments:
    $attr
      USER


  Returns:
    $user_info

=cut
#**********************************************************
sub get_test_file {
  my ($filename) = @_;

  my $content  = q{};
  if (open(my $fh, '<', $filename)) {
    while(<$fh>) {
      $content .= $_;
    }
    close($fh);
  }

  my $result = decode_json($content);


  return $result;
}



1;
