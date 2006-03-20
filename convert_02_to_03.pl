#!/usr/bin/perl
# Convert from version 0.2 to 0.3


#if($#ARGV < 0) {
#  print "NOt work \n";
#  exit;
#}




require "libexec/config.pl";


use DBI;

my $db = DBI -> connect("DBI:mysql:database=$conf{dbname};host=$conf{dbhost}", "$conf{dbuser}", "$conf{dbpasswd}") 
  or die "Unable connect to server '$conf{dbhost}'\n" . $DBI::errstr;
my $not_found = "";

#other_convert();
#users_convert();
#tariffs();
log_convert();



sub tariffs {
	my $q, $q2, $q3;


  
  
  $q = $db -> prepare("SELECT id,  dt, ut, hourp from tarif_plans GROUP BY id;") || die $db->strerr;
  $q->execute ();
  while(my($id, $begin, $end, $traf_price)=$q->fetchrow()) {
     print "$id, $begin, $end, $traf_price\n";
     if($tarf_price > 0) {
       $q2 = $db->do("INSERT INTO  intervals (tp_id, begin, end, tarif, day) 
           VALUES ('$id', '$begin', '$end', '0', '0');");
       my $insert_id = $db->{'mysql_insertid'};
       $q3 = $db->do("UPDATE trafic_tarifs SET interval_id='$insert_id' WHERE TP_ID='$id'") || die $db->strerr;
      }
     else {
       my $sql = "INSERT INTO  intervals (tp_id, begin, end, tarif, day) 
           VALUES ('$id', '$begin', '$end', '0', '0');";
       print "-- $sql\n";
       $q2 = $db->do($sql);
      }
   }

 my  @sql_array = ("DELETE FROM  trafic_tarifs WHERE interval_id='0';",
  "ALTER TABLE `trafic_tarifs` ADD UNIQUE KEY `id` (`id`, `interval_id`);",
	"ALTER TABLE `tarif_plans` DROP COLUMN `ut`;",
	"ALTER TABLE `tarif_plans` DROP COLUMN `dt`;");
  
  foreach my $l (@sql_array) {
    $q2 = $db->do($l) || die $db->errstr;
    print "$l\n";
   }

}





sub log_convert {
  my  @sql_array = (



   "ALTER TABLE log add column uid integer(11) unsigned not null default 0;",
   "ALTER TABLE log change login start datetime NOT NULL default '0000-00-00 00:00:00';",
   "ALTER TABLE log change variant tp_id smallint(5) unsigned NOT NULL default '0';",
   "ALTER TABLE log ADD COLUMN bill_id INTEGER(11) UNSIGNED NOT NULL DEFAULT '0';");

   #"DELETE FROM log WHERE login<'2005-01-01 00:00:00';",   
  
  my $user_ids = get_user_ids();

  $q = $db -> prepare("SELECT id from log GROUP BY id;") || die $db->strerr;
  $q->execute ();
  while(my($id)=$q->fetchrow()) {
    if (defined($user_ids->{"$id"})) {
      push @sql_array,  "UPDATE log SET uid='$user_ids->{$id}', bill_id='$user_ids->{$id}' WHERE id='$id';";
     }  
    else {   
      $not_found .= "$id, ";
     }
   }

  #push @sql_array, "ALTER TABLE log add index (uid);";
  push @sql_array, "ALTER TABLE `log` MODIFY COLUMN `minp` DOUBLE(10,2) NOT NULL DEFAULT '0.00';";
  push @sql_array, "ALTER TABLE `log` MODIFY COLUMN `kb` DOUBLE(10,2) NOT NULL DEFAULT '0.00';";

  push @sql_array, "ALTER TABLE log add index (uid, start);";
  push @sql_array, "ALTER TABLE log drop index id;";  
  push @sql_array, "ALTER TABLE log drop index login;";
  push @sql_array, "ALTER TABLE log drop column id";
  push @sql_array, "UPDATE log SET bill_id=uid;";
  push @sql_array, "ALTER TABLE log ADD COLUMN terminate_cause TINYINT(4) UNSIGNED NOT NULL DEFAULT '0';";
  push @sql_array, "RENAME TABLE log to dv_log";



  foreach my $l (@sql_array) {
    $q2 = $db->do($l);
    print "$l\n";
   }



  print "\n\n$not_found";
 
}

sub get_user_ids {
 my %user_ids = ();
 my  $q = $db -> prepare("SELECT id, uid from users;") || die $db->strerr;
 $q->execute ();
  while(my($login, $id)=$q->fetchrow()) {
    $user_ids{"$login"}=$id;
   }

  return \%user_ids;
}










#DROP TABLE IF EXISTS accounts;
#CREATE TABLE `accounts` (
#  `id` int(11) unsigned NOT NULL auto_increment,
#  `name` varchar(100) NOT NULL default '',
#  `deposit` double(8,6) NOT NULL default '0.000000',
#  `tax_number` varchar(250) NOT NULL default '',
#  `bank_account` varchar(250) default NULL,
#  `bank_name` varchar(150) default NULL,
#  `cor_bank_account` varchar(150) default NULL,
#  `bank_bic` varchar(100) default NULL,
#  `registration` date NOT NULL default '0000-00-00',
#  `disable` tinyint(1) unsigned NOT NULL default '0',
#  `credit` double(6,2) NOT NULL default '0.00',
#  PRIMARY KEY  (`id`),
#  UNIQUE KEY `id` (`id`),
#  UNIQUE KEY `name` (`name`)
#) TYPE=MyISAM;
#DROP DATABASE IF EXISTS groups;
#CREATE TABLE `groups` (
#  `gid` tinyint(4) unsigned NOT NULL auto_increment,
#  `name` varchar(12) NOT NULL default '',
#  `descr` varchar(200) NOT NULL default '',
#  PRIMARY KEY  (`gid`),
#  UNIQUE KEY `gid` (`gid`),
#  UNIQUE KEY `name` (`name`)
#) TYPE=MyISAM;
#
#
#
#
#
#
#
#
#
#
#
#
#
