#!/usr/bin/perl

use FindBin '$Bin';

my $debug   = 1;
my $version = 0.02;

require $Bin . '/../../libexec/config.pl';
unshift(@INC, $Bin . '/../../', 
              $Bin . '/../../Abills', 
              $Bin . "/../../Abills/$conf{dbtype}");

require Abills::SQL;
Abills::SQL->import();

require Abills::Base;
Abills::Base->import();

require Admins;
Admins->import();

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} :
 undef });
my $db = $sql->{db};
my $admin = Admins->new($db, \%conf);

my $ARGV = parse_arguments(\@ARGV);
my $debug = $ARGV->{DEBUG} || 1;

my $action = ($ARGV->{SHOW}) ? 'SELECT * ' : "DELETE";


if (defined($ARGV->{'-h'}) || defined($ARGV->{debug}) ) {
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


$ARGV->{ACTIONS}=~s/ //g;
my @actions = split(/,/, $ARGV->{ACTIONS});

foreach my $log (@actions) {
  my $fn = $log.'_rotate';
  my $sql_arr = $fn->();
  
  if ($debug > 1) {
  	print "\n==> $fn\n";
  }
  
  foreach my $sql (@$sql_arr) {
  	if ($debug > 3) {
  	  print $sql."\n";
  	}
  	
  	if ($debug < 5) {
  		$admin->query2("$sql;", (($action eq 'DELETE') ? 'do' : undef));
  		print "$admin->{TOTAL} / \n";
  	}
  }
}


#**********************************************************
#
#**********************************************************
sub payments_list {
	my ($attr) = @_;

	my $WHERE = '';
	my @WHERE_RULES = ();
	
	if ($attr->{GID}) {
		push @WHERE_RULES, @{ $admin->search_expr("$attr->{GID}", 'INT', 'groups.gid') };
	}
	
	if ($attr->{DATE}) {
		push @WHERE_RULES, @{ $admin->search_expr("$attr->{DATE}", 'DATE', 'p.date') };
	}

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';
	
	my $sql_expr = "(SELECT p.id FROM payments p
    LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN groups ON (u.gid=groups.gid)
   $WHERE
   GROUP BY p.id)";
	
	my $sql_expr2 = " LEFT JOIN users u ON (u.uid=p.uid)
    LEFT JOIN groups ON (u.gid=groups.gid)
   $WHERE";
	
	return ($sql_expr, $sql_expr2);
}



#**********************************************************
#
#**********************************************************
sub payments_rotate {
	
	my ($payments_list, $payments_list2) = payments_list($ARGV);

  my @SQL_array = (
    "$action FROM docs_invoice2payments WHERE payment_id IN $payments_list;	",
    "$action FROM docs_invoices WHERE id IN (SELECT invoice_id FROM docs_invoice2payments WHERE payment_id IN $payments_list);	",
    "$action FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE payment_id IN $payments_list);",
    "$action FROM docs_receipts WHERE payment_id IN $payments_list;",
    "$action p.* FROM payments p $payments_list2;"
  );

  return \@SQL_array;
}


#**********************************************************
#
#**********************************************************
sub fees_rotate {

	my $WHERE = '';
	my @WHERE_RULES = ();
	
  my @SQL_array = ("$action from fees f where
    LEFT JOIN users ON (users.uid=f.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   WHERE $WHERE;");
   
  return \@SQL_array;
}


#**********************************************************
#
#**********************************************************
sub dv_log_rotate {
	my $WHERE = '';
	my @WHERE_RULES = ();
	
  my @SQL_array = ("$action from dv_log l
    LEFT JOIN users ON (users.uid=l.uid)
    LEFT JOIN groups ON (users.gid=groups.gid)
   WHERE $WHERE;");


  # CREATE TABLE IF NOT EXISTS dv_log_new LIKE dv_log ; 
  # RENAME TABLE dv_log TO dv_log_' . $DATE . ', dv_log_new TO dv_log;', 
  #
  #

  return \@SQL_array;
}


#**********************************************************
#
#**********************************************************
sub help () {
	
print << "[END]";
	Clear db utilite
	Clear payments, fees, dv_log
  ACTION=[payments, fees, dv_log] - default all tables
	GID           - Groups
	DATE          - Date time DATE="<YYYY-MM-DD"
  SHOW          - Show clear date
  DEBUG=1..5    - Debug mode
  help          - Help
[END]

}