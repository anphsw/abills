#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
=head1 NAME

  db_check.pl - console utility to check DB consistency

=head1 SYNOPSIS

  db_check.pl - checks .sql schema files and current DB scheme to find incosistency

=head2 ARGUMENTS

  --help, help, ?    - Show this help and exit

  FROM_CACHE=1            - Use cache from previous run
  ALLOW_DATA_STRIP=1      - Show commands that may cause data truncation (use with caution)
  SHOW_CREATE=1           - Try to check enabled modules and tables with module-like names
  BATCH=1                 - No confirmation (print all ALTER and MODIFY statements to STDOUT)
  APPLY_ALL=1, -a         - No confirmation (apply all ALTER and MODIFY statements)
  SKIP_DISABLED_MODULES   - Skip comparing module-specific tables when module is disabled
  CREATE_NOT_EXIST_TABLES - Create tables that exist in schema files but not in the database
  SKIP_DB_CHECK           - Skip database structure check (e.g., load only config variables)
  SKIP_CONFIG_UPDATE      - Skip config variables update
  ADD_INDEX               - Check and offer to add missing indexes from schema files

  Debug options:
    DEBUG            - Debug level (0..5)
    FILE             - Parse only one .sql file
    SKIP_DUMP        - Skip parsing .sql files
    D_TABLE          - When DEBUG=5, show table structure from dump
    D_FIELD          - When DEBUG=5, show D_TABLE field structure from dump
    S_TABLE          - When DEBUG=5, show table structure from DB
    S_FIELD          - When DEBUG=5, show S_TABLE field structure from DB

=head1 AUTHORS

  ABillS Team

=cut


our $libpath;
our ($Bin, %conf, $base_dir, @MODULES);
BEGIN {
  use FindBin '$Bin';
  # Assuming we are in '/usr/abills/misc/db_check/'
  # Should point to abills root dir
  $libpath = $Bin . '/../../';
}
use lib $Bin;
use lib $libpath;
use lib $libpath . 'lib';
use lib $libpath . 'Abills/mysql';

do 'libexec/config.pl';
$base_dir //= $libpath;

# Enable Autoflush
$| = 1;

use Pod::Usage qw/&pod2usage/;

eval {require Carp::Always};

use Abills::Base qw/_bp parse_arguments in_array/;
use Abills::Misc;
use Abills::Experimental;

use Abills::SQL;
use Admins;

use Parser::Dump;
use Parser::Scheme;

my $db = Abills::SQL->connect(@conf{'dbtype', 'dbhost', 'dbname', 'dbuser', 'dbpasswd'},
  { CHARSET => $conf{dbcharset} });
my $Admin = Admins->new($db, \%conf);
$Admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1', SHORT => 1 });

my $argv = parse_arguments(\@ARGV);

if ($argv->{'--help'} || $argv->{-help} || $argv->{-help} || $argv->{'-?'} || $argv->{'t'}) {
  pod2usage(1);
}

my $debug = 0;
if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  Parser::Dump::set_debug($debug);
  _bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });
}

my %cached = ();
my %create_defined = ();
my %tables_keys = ();
my %tables_unique_keys = ();

if ($argv->{FROM_CACHE}) {
  $cached{$base_dir . 'db'} = 1;

  #  map { $cached{$_} = 1; } split(',\s?', $ARGS->{FROM_CACHE});
}

if ($argv->{CREATE_NOT_EXIST_TABLES}) {
  create_not_exist_tables();
}

if ($argv->{ADD_INDEX}) {
  add_indexes_from_schema();
}

if (!$argv->{SKIP_DB_CHECK}) {
  db_check();
}

if (!$argv->{SKIP_CONFIG_UPDATE}) {
  update_config_variables()
}

exit 0;

#**********************************************************
=head2 db_check()

=cut
#**********************************************************
sub db_check {

  # Get list of modules
  my $all_modules = existing_modules_list();

  my %dump_info = parse_schema_files($all_modules);

  if ($debug > 4 && $argv->{D_TABLE}) {
    if (!exists $dump_info{$argv->{D_TABLE}}) {
      die "TABLE $argv->{D_TABLE} was not found in dump";
    }
    _bp($argv->{D_TABLE}, $dump_info{$argv->{D_TABLE}});
    if ($argv->{D_FIELD} && exists $dump_info{ $argv->{D_TABLE} }->{columns}->{ $argv->{D_FIELD} }) {
      _bp($argv->{D_FIELD}, $dump_info{$argv->{D_TABLE}}->{columns}->{$argv->{D_FIELD}});
    }
  }

  if ($debug > 4 && $argv->{D_TABLE}) {
    debug_dump_table(\%dump_info);
  }

  print "Found " . scalar(keys %dump_info) . " tables\n" if ($debug);

  # Get info for tables from DB
  my $scheme_parser = Parser::Scheme->new($db, $Admin, \%conf);
  my %scheme_info = %{$scheme_parser->parse()};

  load_tables_from_files();

  get_table_keys_from_files();

  # Get all tables from DB
  my @existing_tables = sort keys %scheme_info;
  foreach my $table (@existing_tables) {
    # Filter tables with module name but not enabled
    if ($argv->{SKIP_DISABLED_MODULES} && $table =~ /^([a-z]+)\_/) {
      my $name = ucfirst $1;
      # Skip if it is module name and not enabled module
      next if (is_disabled_module_name($name, $all_modules));
    }

    if (exists $dump_info{$table}) {
      # Compare columns and types
      compare_tables($table, $dump_info{$table}, $scheme_info{$table});
      check_table_keys($table, $scheme_info{$table}) if $debug;
    }
  }

  return 1;
}

#**********************************************************
=head2 parse_schema_files($all_modules) - Parse SQL schema files

  Arguments:
    $all_modules - Reference to array of module names

  Returns:
    %dump_info - Hash of table structures from schema files

=cut
#**********************************************************
sub parse_schema_files {
  my ($all_modules) = @_;
  my %dump_info = ();

  # Skip parsing if requested
  if ($argv->{SKIP_DUMP}) {
    return %dump_info;
  }

  # Parse single file if specified
  if ($argv->{FILE}) {
    Parser::Dump::parse_accumulate($argv->{FILE});
    return %{Parser::Dump::get_accumulated()};
  }

  # Parse all schema files
  for my $dir ('db') {
    # Could add 'db/update' if needed
    my $dir_path = $base_dir . $dir;
    my $cache_path = $dir_path . '/parser_dump.cache';

    if (exists $cached{$dir_path}) {
      if (-e $cache_path) {
        print " Using cache for $dir_path\n" if $debug;
        %dump_info = (%dump_info, %{Parser::Dump::read_from_file($cache_path)});
      }
      else {
        print " No cache found for $dir_path\n" if $debug;
        Parser::Dump::parse_accumulate($dir_path, {
          SAVE_TO     => $cache_path,
          MODULE_DB   => $base_dir . 'Abills/modules/',
          ALL_MODULES => $all_modules
        });
      }
    }
    else {
      Parser::Dump::parse_accumulate($dir_path, {
        SAVE_TO     => $cache_path,
        MODULE_DB   => $base_dir . 'Abills/modules/',
        ALL_MODULES => $all_modules
      });
    }
  }

  return %{Parser::Dump::get_accumulated({ USE_CACHE => \%dump_info })};
}

#**********************************************************
=head2 debug_dump_table(\%dump_info) - Output debug info for a specific table from dump

  Arguments:
    \%dump_info - Reference to hash of table structures

=cut
#**********************************************************
sub debug_dump_table {
  my ($dump_info) = @_;

  if (!exists $dump_info->{$argv->{D_TABLE}}) {
    die "TABLE $argv->{D_TABLE} was not found in dump";
  }

  _bp($argv->{D_TABLE}, $dump_info->{$argv->{D_TABLE}});

  if ($argv->{D_FIELD} && exists $dump_info->{$argv->{D_TABLE}}->{columns}->{$argv->{D_FIELD}}) {
    _bp($argv->{D_FIELD}, $dump_info->{$argv->{D_TABLE}}->{columns}->{$argv->{D_FIELD}});
  }
}

#**********************************************************
=head2 compare_tables($table_name, $dump_table, $sql_table) - Compare table definitions

  Arguments:
    $table_name - Name of the table to compare
    $dump_table - Table structure from schema files
    $sql_table  - Table structure from database

  Returns:
    1 - Success

=cut
#**********************************************************
sub compare_tables {
  my ($table_name, $dump_table, $sql_table) = @_;

  return 0 if (!$sql_table);

  my $dump_cols_ref = $dump_table->{columns} || {};
  my $sql_cols_ref = $sql_table->{columns} || {};

  # If found global differences, than should check it more
  print "Checking table $table_name\n" if ($debug);

  my @dump_cols = sort keys %{$dump_cols_ref};
  my @sql_cols = sort keys %{$sql_cols_ref};

  my @missing_in_db = grep {!in_array($_, \@sql_cols)} @dump_cols;
  my @not_in_schema = grep {!in_array($_, \@dump_cols)} @sql_cols;

  for (@dump_cols) {
    if (!in_array($_, \@sql_cols)) {
      my $col_definition = get_column_definition($dump_cols_ref->{$_});
      show_tip("ALTER TABLE `$table_name` ADD COLUMN `$_` " . "$col_definition;");
    }
  }

  if ($debug) {
    if (@missing_in_db) {
      print "  Columns defined in schema but missing in database:\n";
      print join('', map {"    $_ \n"} @missing_in_db);
    }

    if (@not_in_schema) {
      print "  Columns in database but not defined in schema:\n";
      print map {"    $table_name.$_\n"} @not_in_schema;
    }
  }

  # Getting only both existing cols for check
  my %common_columns = ();
  foreach (@dump_cols) {
    $common_columns{$_} = 1 if (exists $dump_cols_ref->{$_} && exists $sql_cols_ref->{$_});
  }
  my @common_cols = sort keys %common_columns;

  # Now can check types
  foreach my $col (@common_cols) {
    compare_column_definitions($table_name, $col, $dump_cols_ref->{$col}, $sql_cols_ref->{$col});
  }

  return 1;
}

#**********************************************************
=head2 compare_column_definitions($table_name, $col, $dump_col, $sql_col) - Compare column definitions

  Arguments:
    $table_name - Name of the table
    $col        - Column name
    $dump_col   - Column definition from schema
    $sql_col    - Column definition from database

=cut
#**********************************************************
sub compare_column_definitions {
  my ($table_name, $col, $dump_col, $sql_col) = @_;

  # Extract column attributes
  my $dump_type = lc $dump_col->{Type};
  my $sql_type = lc $sql_col->{Type};

  my ($dump_size) = $dump_type =~ /\((\d+)\)/;
  my ($sql_size) = $sql_type =~ /\((\d+)\)/;

  my $dump_nullable = is_nullable($dump_col);
  my $sql_nullable = is_nullable($sql_col);

  my $dump_default = $dump_col->{Default};
  my $sql_default = $sql_col->{Default};

  # Get full column definitions
  my $col_definition = get_column_definition($dump_col);
  my $current_def = get_column_definition($sql_col);

  # Skip if definitions match or current is TEXT (special case)
  if ($current_def eq $col_definition || $current_def eq 'TEXT') {
    return;
  }

  # Check if attributes match
  my $type_equals = ($dump_type eq $sql_type);
  my $null_equals = (defined($dump_nullable) && defined($sql_nullable)) ?
    ($dump_nullable eq $sql_nullable) :
    undef;
  my $default_equals = (defined($dump_default) && defined($sql_default)) ?
    ($dump_default eq $sql_default) :
    undef;

  # Skip if type and nullable match and default can't be compared
  if ($type_equals && $null_equals && !defined $default_equals) {
    return;
  }

  print "  Found incorrect column definition for $table_name.$col\n" if $debug;

  # Check if data will be truncated by this modification
  if ($dump_size && $sql_size && $sql_size > $dump_size && !$argv->{ALLOW_DATA_STRIP}) {
    print "  Will truncate data if applied ($sql_size -> $dump_size). Skipping. Use ALLOW_DATA_STRIP=1 to override.\n" if $debug;
    return;
  }

  print "  Expected: '$col_definition', Current: '$current_def'\n" if $debug;

  # Remove PRIMARY KEY attribute for MODIFY statement
  $col_definition =~ s/PRIMARY KEY//g;

  # Generate ALTER statement
  show_tip("ALTER TABLE `$table_name` MODIFY COLUMN `$col` $col_definition;", {
    PREV => uc($current_def),
    NEW  => uc($col_definition)
  });
}

#**********************************************************
=head2 get_column_definition($col_info) - Generate SQL column definition string

  Arguments:
    $col_info - Column information hash

  Returns:
    String with SQL column definition

=cut
#**********************************************************
sub get_column_definition {
  my ($col_info) = @_;

  my $default_def = '';
  my $nullable = '';
  my $primary_key = '';

  if (defined $col_info->{Null} && $col_info->{Null} eq 'No') {
    $nullable = ' NOT NULL';
  }

  if (defined $col_info->{Default}) {
    my $default_val = undef;

    if (ref $col_info->{Default} && ref $col_info->{Default} eq 'SCALAR') {
      $default_val = qq{${$col_info->{Default}}};
    }
    # True
    elsif ($col_info->{Default}) {
      if ($col_info->{Default} eq 'CURRENT_TIMESTAMP') {
        $default_val = q{CURRENT_TIMESTAMP};
      }
      elsif ($col_info->{Default} eq 'NOW') {
        $default_val = q{NOW()};
      }
      elsif ($col_info->{Default} eq 'NULL') {
        #        $default_val = q{NULL};
      }
      else {
        $default_val = qq{'$col_info->{Default}'};
      }

    }
    elsif ($col_info->{Default} eq '0') {
      $default_val = q/0/;
    }
    else {
      $default_val = q/''/;
    }

    $default_def = defined $default_val ? (' DEFAULT ' . $default_val) : '';
  }

  if ($col_info->{_raw} && $col_info->{_raw}{is_primary_key}) {
    $primary_key = ' PRIMARY KEY ';
  }

  return uc($col_info->{Type}) . $primary_key . $nullable . $default_def;
}

#**********************************************************
=head2 is_nullable($col_def) - Check if column allows NULL values

  Arguments:
    $col_def - Column definition hash

  Returns:
    1       - Column is nullable
    0       - Column is NOT NULL
    undef   - Not defined

=cut
#**********************************************************
sub is_nullable {
  my ($col_def) = @_;

  my $null_defined = exists $col_def->{Null} && defined $col_def->{Null};
  my $nullable = $null_defined && $col_def->{Null} && lc($col_def->{Null}) !~ /no/i;

  return $nullable
    ? 1
    : $null_defined
    ? 0
    : undef;
}

#**********************************************************
=head2 show_tip($tip, $attr) - Display and optionally apply SQL statement

  Arguments:
    $tip  - SQL statement to show/execute
    $attr - Optional attributes for display (PREV, NEW)

  Returns:
    1 - Success
    0 - Error

=cut
#**********************************************************
sub show_tip {
  my ($tip, $attr) = @_;

  if ($argv->{BATCH}) {
    print "$tip\n";
    return 1;
  }

  if ($argv->{APPLY_ALL} || defined($argv->{'-a'})) {
    return execute_sql($tip);
  }

  my $text = ($attr->{PREV} && $attr->{NEW}) ? "Current: $attr->{PREV}\n Change to : $attr->{NEW} \n $tip" : $tip;
  print "\n $text \n Apply? (y/N/a): ";
  chomp(my $response = <STDIN>);

  if ($response eq 'a') {
    $response = 'y';
    $argv->{APPLY_ALL} = 1;
  }

  if ($response !~ /y/i) {
    print " Skipped \n";
    return 1;
  };

  return execute_sql($tip);
}

#**********************************************************
=head2 execute_sql($sql) - Execute an SQL statement

  Arguments:
    $sql - SQL statement to execute

  Returns:
    1 - Success
    0 - Error

=cut
#**********************************************************
sub execute_sql {
  my ($sql) = @_;

  $Admin->query($sql, 'do', {});

  if ($Admin->{errno}) {
    print "\nError: " . ($Admin->{errno} || '') . "\n";
    return 0;
  }

  print "Applied successfully\n" if ($debug > 0);
  return 1;
}

#**********************************************************
=head2 existing_modules_list()

=cut
#**********************************************************
sub existing_modules_list {

  my $dirs_list = _get_files_in($base_dir . 'Abills/modules', { WITH_DIRS => 1 });

  my @module_names = grep {-d $base_dir . 'Abills/modules/' . $_} @{$dirs_list};

  return \@module_names;
}

#**********************************************************
=head2 is_disabled_module_name($name, $existing_modules) - Check if module is disabled

  Arguments:
    $name - Module name
    $existing_modules - Reference to array of existing module names

  Returns:
    1 - Module is disabled
    0 - Module is enabled

=cut
#**********************************************************
sub is_disabled_module_name {
  my ($name, $existing_modules) = @_;

  $name = 'Equipment' if ($name eq 'Pon');
  $name = 'Crm' if ($name eq 'Cashbox');

  return (in_array($name, $existing_modules) && !in_array($name, \@MODULES));
}

#**********************************************************
=head2 _get_create_commands()

=cut
#**********************************************************
sub _get_create_commands {
  my $module_sql_name = shift;
  my $module_sql_name_add = shift;

  $module_sql_name = $module_sql_name_add if ($module_sql_name_add && !(-e $module_sql_name));
  if (-e $module_sql_name) {
    my $content = Parser::Dump::get_file_content($module_sql_name);
    my @tables = $content =~ /((^|[^- ])CREATE TABLE [^;]*;)/sg;

    foreach my $table (@tables) {
      my $table_name = "";
      if ($table =~ /((EXISTS|TABLE).+`.+`)/) {
        (undef, $table_name, undef) = split('`', $1);
        next if $table_name eq "id";
        $create_defined{$table_name} = $table;
      }
    }
  }
}

#**********************************************************
=head2 create_not_exist_tables()

=cut
#**********************************************************
sub create_not_exist_tables {

  print "Creating missing tables...\n" if $debug;

  my $scheme_parser = Parser::Scheme->new($db, $Admin, \%conf);
  my %scheme_info = %{$scheme_parser->parse()};

  load_tables_from_files();

  my $count_added_tables = 0;
  foreach my $table_name (keys %create_defined) {
    if (!exists $scheme_info{$table_name}) {
      if (execute_sql($create_defined{$table_name})) {
        $count_added_tables++;
        print "Table `$table_name` successfully added\n" if $debug;
      }
    }
  }

  if (!$count_added_tables) {
    print "No tables needed to be created\n" if ($debug);
  }

  return 1;

}

#**********************************************************
=head2 get_table_keys_from_files()

=cut
#**********************************************************
sub get_table_keys_from_files {

  foreach my $table_name (keys %create_defined) {
    $tables_keys{$table_name} = [];
    $tables_unique_keys{$table_name} = [];

    my @table_keys = $create_defined{$table_name} =~ /(`.+UNIQUE.+|`.+PRIMARY KEY|.+KEY.+\)|.+INDEX.+\)|.+UNIQUE.+\))/g;

    foreach my $key (@table_keys) {
      $key =~ s/^\s+//;
      push @{$tables_keys{$table_name}}, $key;
    }
  }

  return 1;
}

#**********************************************************
=head2 check_table_keys($table_name, $sql_table) - Compare keys in DB with keys in schema

  Arguments:
    $table_name - Table name
    $sql_table  - Table structure from database

  Returns:
    1 - Success

=cut
#**********************************************************
sub check_table_keys {
  my ($table_name, $sql_table) = @_;

  my @db_keys;
  foreach my $column (keys %{$sql_table->{columns}}) {
    if ($sql_table->{columns}{$column}{_raw}{Key}) {
      push @db_keys, $column;
    }
  }

  print "Keys in table `" . lc $table_name . "` in file:\n";
  foreach my $key (@{$tables_keys{$table_name}}) {
    print "\t`$key`\n";
  }

  print "\nKeys in table `" . lc $table_name . "` in DB:\n";
  foreach my $key (@db_keys) {
    print "\t`$key`\n";
  }

  print "\n";

  #  #Not exist keys
  #  foreach my $key (@{$tables_keys{$table_name}}) {
  #    if (!in_array($key, \@db_keys)) {
  #      print "Table`" . lc $table_name . "` has no index `$key`\n";
  #    }
  #  }
  #
  #  #Custom keys
  #  foreach my $key (@db_keys) {
  #    if (!in_array($key, $tables_keys{$table_name}) && !in_array($key, $tables_unique_keys{$table_name})) {
  #      print "Table`" . lc $table_name . "` has custom index `$key`\n";
  #    }
  #  }

  return 1;
}

#**********************************************************
=head2 update_config_variables() - Update config variables from db/config_variables.sql

  Returns:
    1 - Success

=cut
#**********************************************************
sub update_config_variables {
  my $response = 'n';

  if ($argv->{APPLY_ALL} || defined($argv->{'-a'})) {
    $response = 'y';
  }
  else {
    print "\nDo you want reload config variables?\n";
    print "Apply? (y/N): ";
    chomp($response = <STDIN>);
  }

  if (lc($response) eq 'y') {
    my $content = '';
    if (open(my $fh, '<', $libpath . 'db/config_variables.sql')) {
      while (<$fh>) {
        $content .= $_;
      }
      close($fh);
    }

    if ($content) {
      eval {
        $Admin->query('TRUNCATE TABLE config_variables;', 'do', {});
        $Admin->query($content, 'do', {})
      };

      if ($@) {
        print "\nABORTED! Error has occurred with config variables loading.\n";
      }
      else {
        print "\nConfig variables reloaded successfully.\n";
      }
    }
    else {
      print "Config variables not found!\n";
    }
  }
  else {
    print "Skipped\n";
  }
}

#**********************************************************
=head2 load_tables_from_files() - Load CREATE TABLE statements from schema files

=cut
#**********************************************************
sub load_tables_from_files {
  my $base_db_dir = $base_dir . "db/";

  load_table_creates_from_file($base_db_dir . "abills.sql");

  foreach my $module (@MODULES) {
    next if $module eq "Multidoms";
    my $module_sql_name = $base_db_dir . $module . ".sql";
    my $module_sql_fallback = $base_dir . "Abills/modules/$module/$module.sql";
    load_table_creates_from_file($module_sql_name, $module_sql_fallback);
  }

  return 1;
}

#**********************************************************
=head2 load_table_creates_from_file($file_path, $fallback_path) - Extract CREATE TABLE statements from file

  Arguments:
    $file_path     - Primary file path
    $fallback_path - Optional fallback file path if primary doesn't exist

=cut
#**********************************************************
sub load_table_creates_from_file {
  my ($file_path, $fallback_path) = @_;

  # Use fallback if primary doesn't exist
  $file_path = $fallback_path if ($fallback_path && !(-e $file_path));

  if (-e $file_path) {
    my $content = Parser::Dump::get_file_content($file_path);
    my @tables = $content =~ /((^|[^- ])CREATE TABLE [^;]*;)/sg;

    foreach my $table (@tables) {
      if ($table =~ /((EXISTS|TABLE).+`.+`)/) {
        my (undef, $table_name, undef) = split('`', $1);
        next if $table_name eq "id";
        $create_defined{$table_name} = $table;
      }
    }
  }
}

#**********************************************************
=head2 add_indexes_from_schema() - Compare and add indexes from schema files to database

  Returns:
    1 - Success

=cut
#**********************************************************
sub add_indexes_from_schema {

  print "Checking for missing indexes...\n" if $debug;

  if (!%tables_keys) {
    load_tables_from_files();
    get_table_keys_from_files();
  }

  my $scheme_parser = Parser::Scheme->new($db, $Admin, \%conf);
  my %scheme_info = %{$scheme_parser->parse()};

  my $missing_count = 0;

  foreach my $table_name (sort keys %tables_keys) {
    next if !exists($scheme_info{$table_name});

    $Admin->query("SHOW INDEX FROM `$table_name`", 'list', { COLS_NAME => 1, COLS_UPPER => 1 });

    my %db_index_names;
    my %primary_key_columns;

    foreach my $idx (@{$Admin->{list}}) {
      my $key_name = $idx->{KEY_NAME};

      if ($key_name eq 'PRIMARY') {
        push @{$primary_key_columns{$table_name}}, $idx->{COLUMN_NAME};
      }
      else {
        $db_index_names{$key_name} = 1;
      }
    }

    my $existing_primary = join(',', sort @{$primary_key_columns{$table_name} || []});

    foreach my $key_def (@{$tables_keys{$table_name}}) {
      my ($key_type, $key_name, $columns);
      if ($key_def =~ /^KEY/) {
        ($key_name, $columns) = $key_def =~ /KEY\s+`?(\w+)`?\s+\(([^)]+)\)/i;
      }
      else {
        ($key_type, $key_name, $columns) = $key_def =~ /([\S]+) KEY\s+`?(\w+)`?\s+\(([^)]+)\)/i;
      }

      next if !$key_name;

      if ($key_type && $key_type eq 'PRIMARY') {
        my $expected_primary = join(',', sort map { s/`//g; $_ } split(/\s*,\s*/, $columns));

        if ($existing_primary ne $expected_primary) {
          print "Mismatch PRIMARY KEY in `$table_name`: Expected ($expected_primary), Found ($existing_primary)\n";
        }
        next;
      }

      if (!exists $db_index_names{$key_name}) {
        $missing_count++;
        my $add_statement = "ALTER TABLE `$table_name` ADD $key_def;";
        print "Found new index: `$table_name` $key_def\n";
        show_tip($add_statement);
      }
    }
  }

  if ($missing_count == 0) {
    print "No missing indexes found.\n" if $debug;
  }
  else {
    print "Found $missing_count missing indexes.\n" if $debug;
  }

  return 1;
}

1;