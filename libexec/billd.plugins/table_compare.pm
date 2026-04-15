=head1 NAME

  Builld plugin for compare DB data

=head ARGUMENTS

    DATE - date to which the tables are compared

  EXECUTE:
    /usr/abills/libexec/billd table_compare DATE=XXXX-XX-XX

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $argv,
  $debug
);

my $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
bless($db,'dbbase');

table_compare($argv);

#**********************************************************
=head2 table_compare($attr)

=cut
#**********************************************************
sub table_compare {
  my ($attr) = @_;
  my $date = '';

  if ($argv->{DATE} && $argv->{DATE} =~ /(\d{4})\-(\d{2})\-(\d{2})/){
    $date = $attr->{DATE};
  }
  else {
    print "Please specify argument DATE in format: DATE=YYYY-MM-DD \n";
    return 1;
  }

  if (!$conf{BACKUP_DIR}){
    print "Please specify backup dir \$conf{BACKUP_DIR} in config.pl \n";
    return 1;
  }

  print "=== TABLE COMPARE for $date ===\n";

  _load_dump($date);

  my $db_compare = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, 'abills_compare', '', '',
    { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
  bless($db_compare,'dbbase');

  _compare_users($db_compare, $date);
  _compare_payments($db_compare, $date);
  _compare_fees($db_compare, $date);
  _compare_admin_actions($db_compare, $date);
  _compare_bills($db_compare, $date);

  return 1;
}

#**********************************************************
=head2 table_compare($attr)

=cut
#**********************************************************
sub _load_dump {
  my ($date) = @_;

  my $file_sql = $conf{BACKUP_DIR}."stats-$date.sql";
  my $file_gz  = "$file_sql.gz";

  my $cmd;
  my $cmp_db = 'abills_compare';

  if (-f $file_sql) {
    print "Loading SQL dump: $file_sql\n";
    $cmd = "mysql $cmp_db < $file_sql";
  }
  elsif (-f $file_gz) {
    print "Loading GZ dump: $file_gz\n";
    $cmd = "zcat $file_gz | mysql $cmp_db";
  }
  else {
    die "Dump not found: $file_sql(.gz)\n";
  }

  system("mysql -e 'DROP DATABASE IF EXISTS $cmp_db'");
  system("mysql -e 'CREATE DATABASE $cmp_db'");
  system($cmd) == 0 or die "Import failed\n";

  return 1;
}

#**********************************************************
=head2 _compare_users($attr)

=cut
#**********************************************************
sub _compare_users {
  my ($db_compare, $date) = @_;

  print "\n--- USERS ---\n";

  my $list = $db_compare->query("
    SELECT id, uid
    FROM users
    WHERE registration <= ?
  ", undef, { Bind => ["$date 00:00:00"], COLS_NAME => 1 })->{list};

  foreach my $u (@$list) {
    my $uid = $u->{uid};
    my $diff = '';

    my $orig = $db->query("SELECT * FROM users WHERE uid=?", undef, { Bind => [$uid], COLS_NAME => 1 })->{list}->[0];
    my $dump = $db_compare->query("SELECT * FROM users WHERE uid=?", undef, { Bind => [$uid], COLS_NAME => 1 })->{list}->[0];

    if (!$orig) {
      print "Missing in origin database: UID=$uid\n";
      next;
    }

    foreach my $k (keys %$orig) {
      next if (!defined $orig->{$k} && !defined $dump->{$k});

      if (($orig->{$k} // '') ne ($dump->{$k} // '')) {
        $diff .= "FIELD=$k: $dump->{$k} != $orig->{$k}, ";
      }
    }

    if ($diff) {
      print "Changed fields: UID=$uid:\n";
      print "$diff\n";
    }

  }

  return 1;
}

#**********************************************************
=head2 _compare_payments($attr)

=cut
#**********************************************************
sub _compare_payments {
  my ($db_compare, $date) = @_;

  print "\n--- PAYMENTS ---\n";

  my $list = $db_compare->query("
    SELECT id, uid, sum, date
    FROM payments
    WHERE date <= ?
  ", undef, { Bind => ["$date 00:00:00"], COLS_NAME => 1 })->{list};

  foreach my $p (@$list) {
    my $id = $p->{id};
    my $uid = $p->{uid};
    my $diff = '';

    my $orig = $db->query("SELECT * FROM payments WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];
    my $dump = $db_compare->query("SELECT * FROM payments WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];

    if (!$orig) {
      print "Missing in origin database: PAYMENT_ID=$id, SUM=$p->{sum}, DATE=$p->{date}, UID=$uid\n";
      next;
    }

    if ($orig->{sum} ne $dump->{sum}) {
      $diff .= "SUM: $orig->{sum} != $dump->{sum}, ";
    }
    if ($orig->{date} ne $dump->{date}) {
      $diff .= "DATE: $orig->{date} != $dump->{date}";
    }
    if ($diff) {
      print "Changed PAYMENT_ID=$id, UID=$uid, $diff\n";
    }
  }
}

#**********************************************************
=head2 _compare_fees($attr)

=cut
#**********************************************************
sub _compare_fees {
  my ($db_compare, $date) = @_;

  print "\n--- FEES ---\n";

  my $list = $db_compare->query("
    SELECT id, uid, sum, date
    FROM fees
    WHERE date <= ?
  ", undef, { Bind => ["$date 00:00:00"], COLS_NAME => 1 })->{list};

  foreach my $f (@$list) {
    my $id = $f->{id};
    my $uid = $f->{uid};
    my $diff = '';

    my $orig = $db->query("SELECT * FROM fees WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];
    my $dump = $db_compare->query("SELECT * FROM fees WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];

    if (!$orig) {
      print "Missing in origin database: FEE_ID=$id, SUM=$f->{sum}, DATE=$f->{date}, UID=$uid\n";
      next;
    }

    if ($orig->{sum} ne $dump->{sum}) {
      $diff .= "SUM: $orig->{sum} != $dump->{sum}, ";
    }
    if ($orig->{date} ne $dump->{date}) {
      $diff .= "DATE: $orig->{date} != $dump->{date}";
    }
    if ($diff) {
      print "Changed FEE_ID=$id, UID=$uid, $diff\n";
    }
  }
}

#**********************************************************
=head2 _compare_admin_actions($attr)

=cut
#**********************************************************
sub _compare_admin_actions {
  my ($db_compare, $date) = @_;

  print "\n--- ADMIN ACTIONS ---\n";

  my $list = $db_compare->query("
    SELECT * FROM admin_actions
    WHERE datetime <= ?
  ", undef, { Bind => ["$date 00:00:00"], COLS_NAME => 1 })->{list};

  foreach my $a (@$list) {
    my $id = $a->{id};

    my $orig = $db->query("SELECT * FROM admin_actions WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];

    if (!$orig) {
      my $user_exist = $db->query("SELECT id FROM users WHERE uid=?", undef, { Bind => [$a->{uid}], COLS_NAME => 1 })->{list}->[0];
      next if (!$user_exist);

      print "Missing admin_action: ID=$id, UID=$a->{uid}, ACTION=$a->{actions}, AID=$a->{aid}, DATE=$a->{datetime}\n";
    }
  }
}

#**********************************************************
=head2 _compare_bills($attr)

=cut
#**********************************************************
sub _compare_bills {
  my ($db_compare, $date) = @_;

  print "\n--- BILLS ---\n";

  my $list = $db_compare->query("
    SELECT * FROM bills
    WHERE registration <= ?
  ", undef, { Bind => ["$date 00:00:00"], COLS_NAME => 1 })->{list};

  foreach my $p (@$list) {
    my $id = $p->{id};
    my $abonent = ($p->{uid} > 0) ? "UID=$p->{uid}" : "COMPANY_ID=$p->{company_id}";
    my $diff = '';

    my $orig = $db->query("SELECT * FROM bills WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];
    my $dump = $db_compare->query("SELECT * FROM bills WHERE id=?", undef, { Bind => [$id], COLS_NAME => 1 })->{list}->[0];

    if ($orig->{deposit} ne $dump->{deposit}) {
      $diff .= "DEPOSIT: $orig->{deposit} != $dump->{deposit} ";
    }
    if ($diff) {
      print "Changed bill, $abonent, $diff\n";
    }
  }
}