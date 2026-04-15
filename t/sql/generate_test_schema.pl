#!/usr/bin/perl

=head1 NAME

  documentation_link_parser.pl

=head1 SYNOPSIS

  Generate tables Inserts for dev abills databases for static params

=head1 OPTIONS

    UID - user which need to analyse and take his data

    FOR FUTURE:
      MODULES - take only such modules

=cut

use strict;
use warnings FATAL => 'all';

use lib '../../lib/';

use Abills::Init;
use Abills::Base;
use Internet;

our (
  %conf,
  $admin,
  $db
);

my $argv = parse_arguments(\@ARGV);
my $user = get_test_user($argv);

start();

sub start {

  my @tables = tables();

  foreach my $table (@tables) {
    my $name = $table->{name};
    my $field = $table->{field} || '';
    my $value = $table->{value} || 0;

    my $extras = '';
    if ($field) {
      $extras = "WHERE $field = ', \@row_id, '";
    }

    my $cmd = <<"CMD";
mysql -u $conf{dbuser} -D $conf{dbname} -p'$conf{dbpasswd}' <<'EOF'
SET \@row_id := $value;
SET \@key := '$conf{secretkey}';

SELECT GROUP_CONCAT(CONCAT('`', COLUMN_NAME, '`') ORDER BY ORDINAL_POSITION SEPARATOR ', ')
  INTO \@cols
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = '$name';

SELECT GROUP_CONCAT(
         CASE
           WHEN DATA_TYPE IN ('tinyblob','blob','mediumblob','longblob') THEN
               CONCAT(
                   'IF(`', COLUMN_NAME, '` IS NULL, ''NULL'', CONCAT(''ENCODE('', QUOTE(DECODE(`', COLUMN_NAME, '`, ''' , \@key , ''')), '', '', QUOTE(''', \@key, '''), '')''))'
               )
           ELSE
               CONCAT(
                   'IF(`', COLUMN_NAME, '` IS NULL, ''NULL'', QUOTE(`', COLUMN_NAME, '`))'
               )
         END
         ORDER BY ORDINAL_POSITION SEPARATOR ', '
       )
INTO \@vals_list
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = DATABASE()
  AND TABLE_NAME = '$name';

SET \@vals_expr := CONCAT('CONCAT_WS(\\', \\', ', \@vals_list, ')');

SET \@sql := CONCAT(
  'SELECT CONCAT(''INSERT INTO `$name` (', \@cols, ') VALUES ('', ',
      \@vals_expr,
  ', '');'') AS insert_sql FROM `$name` $extras ;'
);

-- SELECT \@sql AS debug_sql;

PREPARE stmt FROM \@sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
EOF
CMD

    my $result = cmd($cmd);
    $result =~ s/^.*[\r\n]+//;

    print $result;
  }

  return 0;
}

sub tables {

  my $Internet = Internet->new($db, $admin, \%conf);
  $Internet->user_info($user->{UID});

  my @tables = (
    # base tables
    {
      name  => 'users',
      field => 'uid',
      value => $user->{UID}
    },
    {
      name  => 'users_pi',
      field => 'uid',
      value => $user->{UID}
    },
    {
      name  => 'bills',
      field => 'uid',
      value => $user->{UID}
    },
    {
      name  => 'payments',
      field => 'uid',
      value => $user->{UID}
    },
    {
      name  => 'fees',
      field => 'uid',
      value => $user->{UID}
    },
    {
      name  => 'groups',
      field => 'gid',
      value => $user->{GID}
    },
    {
      name  => 'companies',
      field => 'company_id',
      value => $user->{COMPANY_ID}
    },

    # internet
    {
      name  => 'tarif_plans',
      field => 'tp_id',
      value => $Internet->{TP_ID}
    },
    {
      name  => 'internet_main',
      field => 'uid',
      value => $user->{UID}
    },

    # default all fields
    {
      name => 'info_fields',
    },
  );

  return @tables;
}

1;
