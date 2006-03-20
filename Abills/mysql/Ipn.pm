package Ipn;
# Auth functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');
@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
#my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;
use main;
@ISA  = ("main");

use POSIX qw(strftime);
my $DATE = strftime "%Y-%m-%d", localtime(time);
my ($Y, $M, $D)=split(/-/, $DATE, 3);

my $db;
my $CONF;
my $debug =0;

#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $CONF) = @_;
  my $self = { };
  bless($self, $class);

  if (! defined($CONF->{KBYTE_SIZE})) {
  	 $CONF->{KBYTE_SIZE}=1024;
  	}

  return $self;
}



#**********************************************************
# traffic_add
#**********************************************************
sub traffic_add {
  my $self = shift;
  my ($DATA) = @_;

# $self->{debug}=1;
 my $table_name = "ipn_traf_log_". $Y."_".$M;

 $self->query($db, "CREATE TABLE IF NOT EXISTS `$table_name`  (
  `src_addr` int(11) unsigned NOT NULL default '0',
  `dst_addr` int(11) unsigned NOT NULL default '0',
  `src_port` smallint(5) unsigned NOT NULL default '0',
  `dst_port` smallint(5) unsigned NOT NULL default '0',
  `protocol` tinyint(3) unsigned default '0',
  `size` bigint(20) unsigned default '0',
  `f_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `s_time` datetime NOT NULL default '0000-00-00 00:00:00',
  `nas_id` smallint(5) unsigned NOT NULL default 0
  );", 'do');



  $self->query($db, "insert into $table_name (src_addr,
       dst_addr,
       src_port,
       dst_port,
       protocol,
       size,
       f_time,
       nas_id)
     VALUES (
        $DATA->{SRC_IP},
        $DATA->{DST_IP},
       '$DATA->{SRC_PORT}',
       '$DATA->{DST_PORT}',
       '$DATA->{PROTOCOL}',
       '$DATA->{SIZE}',
        now(),
        '$DATA->{NAS_ID}'
      );", 'do');

 return $self;
}
	




#**********************************************************
# List
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;

 undef @WHERE_RULES; 

 my $table_name = "ipn_traf_log_". $Y."_".$M;

 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }


if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }



my $f_time = 'f_time';


#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
#elsif($attr->{INTERVAL_TYPE} eq 'sessions') {
#	$WHERE = '';
#  $lupdate = "f_time";
#  $GROUP=2;
#}
else {
  $lupdate = "f_time";
}



 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';




#$PAGE_ROWS = 10;

 $self->{debug}=1;
 $self->query($db, "SELECT 
  $lupdate,
  $size,
  INET_NTOA(src_addr),
  src_port,
  INET_NTOA(dst_addr),
  dst_port,

  protocol
  FROM $table_name
  $WHERE
  $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS
  ;");


  #

 my $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  sum(size)
  from traf_log 
  ;");

  my $a_ref = $self->{list}->[0];
  ($self->{COUNT},
   $self->{SUM}) = @$a_ref;


  return $list;
}


#**********************************************************
# host_list
#**********************************************************
sub hosts_list {
  my $self = shift;
  my ($attr) = @_;
	
	
}

#**********************************************************
#
#**********************************************************
sub reports {
 my $self = shift;
 my ($attr) = @_;

  my $table_name = "ipn_traf_log_". $Y."_".$M;

 undef @WHERE_RULES; 

 my $GROUP = '';
 my $size  = 'size';
 
 if ($attr->{GROUPS}) {
 	  $GROUP = "GROUP BY $attr->{GROUPS}";
 	  $size = "sum(size)";
  }


if ($attr->{SRC_ADDR}) {
   push @WHERE_RULES, "src_addr=INET_ATON('$attr->{SRC_ADDR}')";
 }

if (defined($attr->{SRC_PORT}) && $attr->{SRC_PORT} =~ /^\d+$/) {
   push @WHERE_RULES, "src_port='$attr->{SRC_PORT}'";
 }

if ($attr->{DST_ADDR}) {
   push @WHERE_RULES, "dst_addr=INET_ATON('$attr->{DST_ADDR}')";
 }

if (defined($attr->{DST_PORT}) && $attr->{DST_PORT} =~ /^\d+$/ ) {
   push @WHERE_RULES, "dst_port='$attr->{DST_PORT}'";
 }



my $f_time = 'f_time';


#Interval from date to date
if ($attr->{INTERVAL}) {
 	my ($from, $to)=split(/\//, $attr->{INTERVAL}, 2);
  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')>='$from' and date_format(f_time, '%Y-%m-%d')<='$to'";
 }
#Period
elsif (defined($attr->{PERIOD})) {
   my $period = $attr->{PERIOD} || 0;   
   if ($period == 4) { $WHERE .= ''; }
   else {
     $WHERE .= ($WHERE ne '') ? ' and ' : 'WHERE ';
     if($period == 0)    {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')=curdate()"; }
     elsif($period == 1) {  push @WHERE_RULES, "TO_DAYS(curdate()) - TO_DAYS(f_time) = 1 ";  }
     elsif($period == 2) {  push @WHERE_RULES, "YEAR(curdate()) = YEAR(f_time) and (WEEK(curdate()) = WEEK(f_time)) ";  }
     elsif($period == 3) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m')=date_format(curdate(), '%Y-%m') "; }
     elsif($period == 5) {  push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}' "; }
     else {$WHERE .= "date_format(f_time, '%Y-%m-%d')=curdate() "; }
    }
 }
elsif($attr->{HOUR}) {
   push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d %H')='$attr->{HOUR}'";
 }
elsif($attr->{DATE}) {
	 push @WHERE_RULES, "date_format(f_time, '%Y-%m-%d')='$attr->{DATE}'";
}


my $lupdate = '';

if ($attr->{INTERVAL_TYPE} eq 3) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
elsif($attr->{INTERVAL_TYPE} eq 2) {
  $lupdate = "DATE_FORMAT(f_time, '%Y-%m-%d %H')";	
  $GROUP="GROUP BY 1";
  $size = 'sum(size)';
}
#elsif($attr->{INTERVAL_TYPE} eq 'sessions') {
#	$WHERE = '';
#  $lupdate = "f_time";
#  $GROUP=2;
#}
else {
  $lupdate = "f_time";
}



 $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';

  $self->{debug}=1;

  my $list;

if (defined($attr->{HOSTS})) {

 	 $self->query($db, "SELECT INET_NTOA(src_addr), sum(size), count(*)
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{HOSTS_LIST_FROM} = $self->{list};

 	 $self->query($db, "SELECT INET_NTOA(dst_addr), sum(size), count(*)
     from $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{HOSTS_LIST_TO} = $self->{list};
 }
elsif (defined($attr->{PORTS})) {
 	 $self->query($db, "SELECT src_port, sum(size), count(*)
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{PORTS_LIST_FROM} = $self->{list};

 	 $self->query($db, "SELECT dst_port, sum(size), count(*)
     from  $table_name
     $WHERE
     GROUP BY 1
    ORDER BY 2 DESC 
    LIMIT $PG, $PAGE_ROWS;");
   $self->{PORTS_LIST_TO} = $self->{list};
 }
else {
#$PAGE_ROWS = 10;
 $self->query($db, "SELECT   $lupdate,
   sum(if(src_port=0 && (src_port + dst_port>0), size, 0)),
   sum(if(dst_port=0 && (src_port + dst_port>0), size, 0)),
   sum(if(src_port=0 && dst_port=0, size, 0)),
   sum(size),
   count(*)
   from  $table_name
   $WHERE
   $GROUP
  ORDER BY $SORT $DESC 
  LIMIT $PG, $PAGE_ROWS;
  ;");
}

  #

 $list = $self->{list};


 $self->query($db, "SELECT 
  count(*),  sum(size)
  from  $table_name
  $WHERE
  ;");

  my $a_ref = $self->{list}->[0];
  ($self->{COUNT},
   $self->{SUM}) = @$a_ref;


 return $list;
}



1
