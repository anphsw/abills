#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

our ($libpath, %conf, $base_dir);

BEGIN {
  use FindBin '$Bin';

  $libpath = $Bin . '/../';

  unshift( @INC,
    $libpath,
    $libpath . "Abills/mysql/",
    $libpath . 'Abills/',
    $libpath . 'lib/'
  );
}

do 'libexec/config.pl' or die "Cannot load config: $!";
$base_dir //= $libpath;

use Abills::Defs;
use Abills::Base qw/_bp parse_arguments in_array/;
use Abills::SQL;
use Admins;

require Abills::Misc;

my $db = Abills::SQL->connect(
  @conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} }
) or die "Failed to connect to database: $!";

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $argv = parse_arguments(\@ARGV);

my $debug = 0;
if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  _bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });
}

do 'language/english.pl' or die "Cannot load language file: $!";

pi_docs_migrate();

#**********************************************************
=head2 log_info($message)

=cut
#**********************************************************
sub log_info {
  my ($message) = @_;

  print "[INFO] $message\n";
  return 1;
}

#**********************************************************
=head2 log_error($message)

=cut
#**********************************************************
sub log_error {
  my ($message) = @_;

  print STDERR "[ERROR] $message\n";
  return 1;
}

#**********************************************************
=head2 pi_docs_migrate()

=cut
#**********************************************************
sub pi_docs_migrate {

  require Tools;
  Tools->import();

  my $Tools = Tools->new($db, $admin, \%conf);

  if (!$argv->{SKIP_BACKUP}) {
    my $backup_ok = save_old_docs();
    if (!$backup_ok) {
      log_error("Aborting migration: backup step did not complete.");
      return 0;
    }
  }

  if ($debug > 5) {
    $Tools->{debug} = 1;
  }

  my $migrate_ok = $Tools->pi_docs_migrate({ IGNORE_DUPLICATE => $argv->{IGNORE_DUPLICATE} });
  $migrate_ok = $migrate_ok && !$Tools->{errno};

  if ($migrate_ok) {
    log_info("User documents migrated successfully.");
    log_info("You should now enable \$conf{PASSPORT_NEW}.");
  }
  else {
    log_error("Something went wrong during migration — rolling back.");
    log_error("No data was lost; your documents are in the same state as before.");
    log_error("If you have duplicate doc type/num entries, re-run with --ignore-duplicate.");
  }

  return $migrate_ok;
}

#**********************************************************
=head2 save_old_docs() - Creates a SQL backup of users_pi before migration.

  Returns:
    1 - backup succeeded
    0 - backup failed

=cut
#**********************************************************
sub save_old_docs {

  our $html = Abills::HTML->new({ CONF => \%conf, NO_PRINT => 1, });
  require Control::System;
  my $backup_result = form_sql_backup({
    mk_backup => 1,
    TABLES    => 'users_pi',
    EXTERNAL  => 1,
  });

  if (!$backup_result || !ref $backup_result) {
    log_error("Backup failed — aborting migration to protect existing data.");
    return 0;
  }

  print "\n$backup_result->{result}\n\n";
  return 1;
}