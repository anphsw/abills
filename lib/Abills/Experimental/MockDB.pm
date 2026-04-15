package Abills::Experimental::MockDB;
=head NAME

  Creates mock database for local tests for static data, for correct checking of tests

=cut

use strict;
use warnings FATAL => 'all';

use lib '../../../lib/';

use Carp;

use DBI;
use Test::mysqld;

use Abills::Init;
use Abills::Base qw(cmd _bp in_array);

use dbbase;
use Abills::SQL;

my DBI $dbh;
my Test::mysqld $mysqld;

#**********************************************************
=head2 connect($attr)

    attr:
      debug: int - make extra prints during execution of module

=cut
#**********************************************************
sub connect {
  my ($class, $attr) = @_;

  my $self = {
    # debug => $attr->{DEBUG} || ''
    debug => 1,
  };

  bless( $self, $class );

  if (!-d '/tmp/abills_mock_db_template') {
    $self->define_db_template();
  }

  cmd('cp -r /tmp/abills_mock_db_template /tmp/abills_mock_db_work');

  $mysqld = Test::mysqld->new(
    my_cnf   => {
      'skip-networking'    => '',
      'max_allowed_packet' => '32M',
      # db at all not strict a lot problems of structure, need to off all default strict rules
      # option not describe, but found it in repo https://grep.app/sixapart/data-objectdriver/master/t/lib/DodTestUtil.pm?q=Test%3A%3Amysqld-%3E#L93
      'sql-mode'           => 'NO_ENGINE_SUBSTITUTION'
    },
    base_dir => '/tmp/abills_mock_db_work',
  ) or die $Test::mysqld::errstr;


  $dbh = DBI->connect(
    $mysqld->dsn(dbname => 'test'),
    'root', '',
    { RaiseError => 1, PrintError => 0 },
  );

  my dbbase $dbbase = {
    dbcharset => 'utf8',
    db        => $dbh,
  };

  bless($dbbase, 'dbbase');

  my Abills::SQL $db = {
    sql_type => 'mysql',
    db       => $dbbase->{db},
    mysql    => $dbbase,
    dbo      => $dbbase,
  };

  bless($dbbase, 'Abills::SQL');

  $self->{db} = $db;
  $self->{dbh} = $dbh;
  $self->{mysqld} = $mysqld;

  return $self;
}

#**********************************************************
=head2 define_db_template() - create database mock database

=cut
#**********************************************************
sub define_db_template {
  my ($self) = @_;

  print "Defining db template: /tmp/abills_mock_db_template\n\n";
  my @sql_files = _find_sql_files();

  my $_mysqld = Test::mysqld->new(
    base_dir => '/tmp/abills_mock_db_template',
    my_cnf   => {
      'skip-networking'    => '',
      'max_allowed_packet' => '32M',
      'sql-mode'           => 'NO_ENGINE_SUBSTITUTION'
    },
  );

  my $cnf = $_mysqld->my_cnf;

  foreach my $sql_file (@sql_files) {
    my $result = system("mysql -S $cnf->{socket} -D test < $sql_file");

    if ($self->{debug}) {
      print "Importing: $sql_file\n";
      warn "Error importing $sql_file: $result\n" if ($result);
    }
  }

  $_mysqld->stop;

  return 1;
}

#**********************************************************
=head2 _find_sql_files() - returns sql modules

=cut
#**********************************************************
sub _find_sql_files {
  my @files;

  my $dir = '/usr/abills/db';
  opendir(my $dh, '/usr/abills/db') or die $!;
  while (my $f = readdir($dh)) {
    next if ($f !~ /\.sql$/xi || in_array($f, ['config_variables.sql', 'abills.sql']));
    push @files, "$dir/$f";
  }
  closedir($dh);

  my $modules_dir = '/usr/abills/Abills/modules';

  opendir(my $dh2, $modules_dir) or die $!;
  while (my $module = readdir($dh2)) {
    next if ($module =~ /^\./x);

    my $db_file = "$modules_dir/$module/$module.sql";
    next if (!-f $db_file);

    push @files, $db_file;
  }
  closedir($dh2);

  push @files, '/usr/abills/t/sql/schema.sql';
  unshift @files,  '/usr/abills/db/abills.sql';
  unshift @files,  '/usr/abills/t/sql/preprocess.sql';

  return @files;
}

DESTROY {
  $dbh->disconnect;
  $mysqld->stop;
  cmd('rm -r /tmp/abills_mock_db_work');
}

1;


# Special thanks for Perl Berlin community for idea of db mocking
