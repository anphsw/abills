#!/usr/bin/perl

use FindBin '$Bin';


#use strict;
use vars qw( %conf $DATE $TIME );

my $debug   = 1;
my $version = 0.06;

require $Bin . '/../../libexec/config.pl';
unshift(@INC, $Bin . '/../../', 
              $Bin . '/../../Abills', 
              $Bin . "/../../Abills/$conf{dbtype}");

require Abills::SQL;
Abills::SQL->import();

require Abills::Base;
Abills::Base->import();

my $begin_time = check_time();

require Admins;
Admins->import();

my $ARGV = parse_arguments(\@ARGV);
if ($ARGV->{DB_NAME}) {
  $conf{dbname}=$ARGV->{DB_NAME};
}

my $sql = Abills::SQL->connect($conf{dbtype}, 
  $conf{dbhost}, 
  $conf{dbname}, 
  $conf{dbuser}, 
  $conf{dbpasswd}, 
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} :
  undef });

my $db = $sql->{db};
my $admin = Admins->new($db, \%conf);

my $debug = 1;


if ($ARGV->{DEBUG}) {
  $debug = $ARGV->{DEBUG};
  print  "DEBUG: $debug \n";
}

my $action = 'SELECT * ';
if (defined($ARGV->{DEL})) { 
  $action = "DELETE";
}

if (defined($ARGV->{'-h'})) {
  help();
  exit;
}

if (! $ARGV->{ACTIONS}) {
  $ARGV->{ACTIONS}='payments,fees,dv_log';
}

if (! $ARGV->{DATE}) {
  print "use DATE=  argument\n";
  exit;
}

my $drop_exist_table = 1;

$admin->{debug}=1 if ( $debug > 6 );

$ARGV->{ACTIONS}=~s/ //g;
my @actions = split(/,/, $ARGV->{ACTIONS});

my $CUR_DATE = $ARGV->{DATE};
$CUR_DATE =~ s/\-/\_/g;

if ($ARGV->{DATE} =~ /^\d{4}\-\d{2}\-\d{2}$/) {
  $ARGV->{DATE} = "$ARGV->{DATE}";
}

db_action();

if ($begin_time > 0 && $debug > 0) {
  Time::HiRes->import(qw(gettimeofday));
  my $end_time = gettimeofday();
  my $gen_time = $end_time - $begin_time;
  printf(" GT: %2.5f\n", $gen_time);
}


#**********************************************************
#
#**********************************************************
sub db_action {
  my ($attr) = @_;

foreach my $log (@actions) {
  my $fn = $log.'_rotate';

  my $sql_arr = $fn->({ %$ARGV, 
                        DATE => "<$ARGV->{DATE}" 
                       });

  if (defined($ARGV->{'ROTATE'})) {
    $action = 'DELETE ';
    push @{ $sql_arr }, @{ $fn->({ DELETE => 1, 
                                   DATE   => "<$ARGV->{DATE}" }) 
                         };
    $action='SELECT * ';
  }

  if ($debug > 1) {
    print "\n==> $fn\n";
  }


  $admin->{db}->{AutoCommit} = 0;

  foreach my $sql (@$sql_arr) {
    if ($debug > 3) {
      print $sql."\n";
    }
    
    if ($debug < 5) {
      $admin->query2("$sql", (($action eq 'DELETE' || defined($ARGV->{'ROTATE'})) ? 'do' : undef));

      if ($admin->{errno}) {
        print "SQL Error: [$admin->{errno}] $admin->{errstr} / $admin->{sql_errno} $admin->{sql_errstr}\n";
        
        if ($admin->{sql_errno} == 1050 && $drop_exist_table)  {
          if ($admin->{sql_errstr}=~/\'(\S+)\'/) {
            my $table = $1;
            print "Drop table: $table\n";
            $admin->query2("DROP TABLE $1", 'do');
          }
        }
        else {
          exit;
        }
      }
      
      print "$fn Rows: $admin->{TOTAL}/$admin->{AFFECTED}\n" if ($debug > 0);
    }
  }
  $admin->{db}->commit();
  $admin->{db}->{AutoCommit} = 1;
}

}

#**********************************************************
#
#**********************************************************
sub payments_list {
  my ($attr) = @_;

  my $WHERE       = '';
  my @WHERE_RULES = ();
  
  if ($attr->{GID}) {
    push @WHERE_RULES, @{ $admin->search_expr("$attr->{GID}", 'INT', 'groups.gid') };
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $admin->search_expr("$attr->{DATE}", 'DATE', 'payments.date') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
  
  my $sql_expr = "(SELECT payments.id FROM payments 
    LEFT JOIN users u ON (u.uid=payments.uid)
    LEFT JOIN groups ON (u.gid=groups.gid)
   $WHERE
   GROUP BY payments.id)";
  
  my $sql_expr2 = " LEFT JOIN users u ON (u.uid=payments.uid)
    LEFT JOIN groups ON (u.gid=groups.gid)
   $WHERE";
  
  return ($sql_expr, $sql_expr2);
}



#**********************************************************
#
#**********************************************************
sub payments_rotate {
  my ($attr) = @_;

  my ($payments_list, $payments_list2) = payments_list($attr);

  my $action_ = $action; 

  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_invoice2payments_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/docs_invoice2payments\.\*/g;
  }

  my @SQL_array = (
    "$action_ FROM docs_invoice2payments  WHERE payment_id IN $payments_list;  ");

 if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_invoices_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/docs_invoices\.\*/g;
 }

 push @SQL_array,  "$action_ FROM docs_invoices WHERE id IN (SELECT invoice_id FROM docs_invoice2payments WHERE payment_id IN $payments_list);";

 if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_receipt_orders_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/docs_receipt_orders\.\*/g;
 }
 push @SQL_array,   "$action_ FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE payment_id IN $payments_list);";

 if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE docs_receipts_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/docs_receipts\.\*/g;
 }
 push @SQL_array,  "$action_ FROM docs_receipts WHERE payment_id IN $payments_list;";

 if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE payments_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/payments\.\*/g;
 }
 elsif($action =~ /DELETE/) {
   $action_ .= ' payments ';
 }
 
 push @SQL_array,  "$action_ FROM payments $payments_list2;";


  return \@SQL_array;
}


#**********************************************************
#
#**********************************************************
sub fees2_rotate {
  my ($attr)= @_;
  
  my @WHERE_RULES = ();

  if ($attr->{DELETE}) {
    return []; 
  }

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $admin->search_expr("<$ARGV->{DATE}", 'DATE', 'f.date') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  my @SQL_array = ('DROP TABLE IF EXISTS fees_new;',
    'CREATE TABLE fees_new LIKE fees;',
    'DROP TABLE IF EXISTS fees_backup;',
    'RENAME TABLE fees TO fees_backup, fees_new TO fees;',
    'CREATE TABLE IF NOT EXISTS fees_' . $CUR_DATE .' LIKE fees;');

  push @SQL_array,  'INSERT INTO fees_'. $CUR_DATE ." 
  SELECT DISTINCT f.* FROM fees_backup f 
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
   GROUP BY f.id";

  if ($attr->{DATE}) {
    @WHERE_RULES = @{ $admin->search_expr(">=$ARGV->{DATE}", 'DATE', 'f.date') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  push @SQL_array, "INSERT INTO fees
    SELECT DISTINCT f.* FROM fees_backup f 
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
   GROUP BY f.id";
   
  push  @SQL_array, 'DROP TABLE fees_backup;';
  return \@SQL_array;
}

#**********************************************************
#
#**********************************************************
sub fees_rotate {
  my ($attr) = @_;

  my $WHERE = '';
  my @WHERE_RULES = ();

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $admin->search_expr("$attr->{DATE}", 'DATE', 'f.date') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  my $action_ = $action; 
  
  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE fees_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/f\.\*/g;
  }
  elsif($action_ =~ /DELETE/) {
    $action_ .= ' f ';
  }

  my @SQL_array = ("$action_ FROM fees f 
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE");
   
  return \@SQL_array;
}


#**********************************************************
#
#**********************************************************
sub dv_log_rotate {
  my ($attr) = @_;

  my $WHERE = '';
  my @WHERE_RULES = ();

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $admin->search_expr("$attr->{DATE}", 'DATE', 'l.start') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
  my $action_ = $action; 
  
  if (defined($attr->{ROTATE})) {
    $action_ = 'CREATE TABLE dv_log_'. $CUR_DATE .' AS ' . $action ;
    $action_ =~ s/\*/l\.\*/g;
  }
  elsif($action_ =~ /DELETE/) {
    $action_ .= ' l ';
  }


  my @SQL_array = (  "$action_ FROM dv_log l
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE");

  return \@SQL_array;
}


#**********************************************************
#
#**********************************************************
sub dv_log_group_rotate {
  my ($attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{DATE}) {
    push @WHERE_RULES, @{ $admin->search_expr("<$ARGV->{DATE}", 'DATE', 'l.start') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';
  my $table_name = 'dv_log';

  my @SQL_array = ('DROP TABLE IF EXISTS '. $table_name .'_new;',
    'CREATE TABLE '. $table_name .'_new LIKE '. $table_name .';',
    'DROP TABLE IF EXISTS '. $table_name .'_backup;',
    'RENAME TABLE '. $table_name .' TO '. $table_name .'_backup, '. $table_name .'_new TO '. $table_name.';',
    'CREATE TABLE IF NOT EXISTS '. $table_name .'_' . $CUR_DATE .' LIKE '. $table_name .';'
  );

  push @SQL_array, 'INSERT INTO '. $table_name ." 
    (
   start,
   tp_id,
   duration,
   sent,
   recv,
   sum,
   nas_id,
   sent2,
   recv2,
   CID,
   bill_id,
   uid,
   acct_input_gigawords,
   acct_output_gigawords,
   ex_input_octets_gigawords,
   ex_output_octets_gigawords)
    SELECT DATE_FORMAT(l.start, '%Y-%m-%d 00:00:00'),
   l.tp_id,
   sum(l.duration),
   sum(l.sent),
   sum(l.recv),
   sum(l.sum),
   l.nas_id,
   sum(l.sent2),
   sum(l.recv2),
   l.CID,
   l.bill_id,
   l.uid,
   sum(l.acct_input_gigawords),
   sum(l.acct_output_gigawords),
   sum(l.ex_input_octets_gigawords),
   sum(l.ex_output_octets_gigawords)
    FROM ". $table_name ."_backup l
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE
   GROUP BY uid, 1";

  if ($attr->{DATE}) {
    @WHERE_RULES = @{ $admin->search_expr(">=$ARGV->{DATE}", 'DATE', 'l.start') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  push @SQL_array, "INSERT INTO ". $table_name ."
    SELECT l.* FROM ". $table_name ."_backup l 
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   $WHERE";
   
  push  @SQL_array, 'DROP TABLE '. $table_name .'_backup;';
  return \@SQL_array;
}

#**********************************************************
#
#**********************************************************
sub help () {
  
print << "[END]";
  Clear db utilite
  Clear payments, fees, dv_log
  ACTIONS=[payments, fees, dv_log] - default all tables
  GID           - Groups
  DATE          - Date time DATE="<YYYY-MM-DD"
  SHOW          - Show clear date (default)
  DEL           - Clear date
  ROTATE        - Add rows to rotate table
  DEBUG=1..8    - Debug mode
  DB_NAME       - DB name (default from config.pl)
  help          - Help
[END]

}
