#!/usr/bin/perl -w
# GEt peering networks
# 

#TRaffic Class source - Class ID => Source URL
# 2 is first peer network
my %class_source = (
  #UA-IX
  2 => 'https://noc.ix.net.ua/ua-list.txt', #'http://noc.ua-ix.net.ua/ua-list.txt',
  #Crimea IX
  # 3 => 'http://193.33.236.1/crimea-ix.txt'
  # Belarus AX
  #2 => 'http://datacenter.by/ip/bynets.txt'
);

my $WGET = 'wget -qO-';
if (-f '/usr/bin/fetch') {
  $WGET = '/usr/bin/fetch -q -o -';
}

my $IPFW    = '/sbin/ipfw';

my $debug   = 0;
my $version = 0.20;

use vars qw(%RAD %conf @MODULES $db $html $DATE $TIME $GZIP $TAR
  $MYSQLDUMP
  %ADMIN_REPORT
  $DEBUG
);

#use strict;
use FindBin '$Bin';
use Sys::Hostname;

require $Bin . '/../libexec/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");
require Abills::SQL;
Abills::SQL->import();

require Abills::Base;
Abills::Base->import();

require Tariffs;
Tariffs->import();

my $sql = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });
my $db = $sql->{db};

my $argv = parse_arguments(\@ARGV);

if (defined($argv->{help})) {
  help();
}
elsif($argv->{type} eq 'ros_com') {
	get_ros_com();
}
else {
  get_networks();
}


$debug = $argv->{debug} if ($argv->{debug});

#**********************************************************
#
#**********************************************************
sub get_ros_com {



}


#**********************************************************
#
#**********************************************************
sub get_networks {

#add traffic to abills nets
my $Tariffs = Tariffs->new($db, \%conf);

while (my ($k, $url) = each %class_source) {
  my $nets = '';
  print "Class: $k Url: $url\n$WGET \"$url\"\n" if ($debug > 0);

  my @url_arr = split(/;/, $url);
  foreach $url (@url_arr) {
    $nets .= `$WGET "$url"`;
  }

  my @nets_arr = split(/\n/, $nets);
  my @sorted_net_arr = sort @nets_arr;

  if (defined($argv->{'ipfw'})) {
    add_to_ipfw(
      {
        TABLE_ID      => $k,
        NETS          => \@sorted_net_arr,
        TRAFFIC_CLASS => ($k-1)
      }
    );
  }
  elsif (defined($argv->{'iptables'})) {
    add_to_iptables(
      {
        TABLE_ID => $k,
        NETS     => \@sorted_net_arr
      }
    );
  }
  elsif (-f '/usr/sbin/ipset') {
    add_to_iptables(
      {
        TABLE_ID => $k,
        NETS     => \@sorted_net_arr
      }
    );
  }

  #Update route table
  if ($argv->{route}) {
    my ($net_id, $router_ip) = split(/:/, $argv->{route});
    if ($net_id eq $k) {
      route_add($router_ip, \@sorted_net_arr);
    }
  }

  my $new_net = analize(analize(analize(analize(analize(\@sorted_net_arr)))));
  $nets = join(";\n", @$new_net);
  print $#{$new_net} if ($debug > 1);

  #test new agregation ======================================

=comments
  my $main_mask = 0b0000000000000000000000000000001;
  
  foreach my $net (@nets_arr) {
		$net =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/;
		my $ip    = ip2int($1);
		my $mask  = $2;
    
    my $yes = 0;

    #foreach my $new_net_ ( @$new_net ) {
    for(my $i=0; $i<=$#{ $new_net }; $i++) {
      my $new_net_ = $new_net->[$i];
  		$new_net_ =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/;
  		my $new_ip    = ip2int($1);
	  	my $new_mask  = $2;
    	my $last_ip   = $new_ip + sprintf("%d", $main_mask << (32  - $new_mask) );
    	
    	#print int2ip($new_ip) ." -> ". int2ip($last_ip) ."\n";
    	
    	if ( $new_ip <= $ip && $last_ip >= $ip) {
    		$yes = 1;
    		next;
    	 }
     }

    if ($yes == 0) {
    	 print int2ip($ip)."/$mask\n";
 	     exit;
     }
  }
=cut

  #==========================================================

  #print  $nets;
  next if ($nets eq '');

  print $nets if ($debug > 1);
  print "Traffic Class: $k Nets: " . ($#nets_arr + 1) . "\n" if ($debug > 0);

  $Tariffs->traffic_class_change(
    {
      ID   => $k,
      NETS => $nets,
    }
  );

}
}

#**********************************************************
#
#**********************************************************
sub route_add {
  my ($router_ip, $networks) = @_;

  print "Route add:\n" if ($debug > 0);

  my @cur_routes_hash = ();

  #Get cure address
  my $cure_routes = `netstat -rn | grep '$router_ip'`;
  my @arr = split(/\n/, $cure_routes);
  foreach my $route (@arr) {
    if ($route =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})[\/]?(\d{0,2})/) {

      my $destination_ip = $1;
      my $mask = $2 || 32;
      next if ($destination_ip eq $router_ip);
      $cur_routes_hash{"$destination_ip/$mask"} = 1;
    }
  }
  foreach my $net (@{$networks}) {
    if ($cur_routes_hash{$net}) {
      delete $cur_routes_hash{$net};
    }
    else {
      print "Add $net -> $router_ip\n" if ($debug > 0);
      my $r = `/sbin/route add $net $router_ip` if ($debug < 3);
    }
  }

  #delete old
  while (my ($net, $mask) = each %cur_routes_hash) {
    print "delete $net\n" if ($debug > 0);
    my $r = `/sbin/route delete $net` if ($debug < 3);
  }
}

#**********************************************************
#
#**********************************************************
sub analize {
  my ($nets) = @_;

  my $main_mask = 0b0000000000000000000000000000001;

  my %agg_nets = ();
  my $last_ip  = '';

  my %net_mask    = ();
  my @ips         = ();
  my $total_count = 0;

  foreach my $net (@$nets) {
    if ($net =~ /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\/(\d{1,2})/) {
      my $ip   = ip2int($1);
      my $mask = $2;
      push @ips, $ip;
      $net_mask{"$ip"} = $mask;
    }
  }

  my @sorted = sort { $a <=> $b } @ips;

  foreach my $ip (@sorted) {
    my $mask = $net_mask{$ip};
    my $count = sprintf("%d", $main_mask << (32 - $mask));
    print int2ip($ip) . " / $mask " . int2ip($ip + $count) . " count: $count \n" if ($debug > 0);

    if ($agg_nets{$last_ip} && $ip + $count == $last_ip + sprintf("%d", $main_mask << (32 - ($agg_nets{$last_ip} - 1)))) {
      print "   " . int2ip($ip) . " !!  last ip: " . int2ip($last_ip + sprintf("%d", $main_mask << (32 - ($agg_nets{$last_ip} - 1)))) . " / " . int2ip($last_ip) . "/$agg_nets{$last_ip} -> " . ($agg_nets{$last_ip} - 1) . "\n" if ($debug > 0);
      $agg_nets{$last_ip}--;
      $total_count++;
    }
    else {
      $agg_nets{$ip} = $mask;
      $last_ip = $ip;
    }
  }

  my @nets_list = ();
  foreach my $ip (sort { $a <=> $b } keys %agg_nets) {
    push @nets_list, int2ip($ip) . '/' . $agg_nets{$ip};
  }

  print "Count: $total_count\n" if ($debug > 1);
  return \@nets_list;
}

#**********************************************************
# add to ipfw  table
#**********************************************************
sub add_to_ipfw {
  my ($attr) = @_;

  my @FW_ACTIONS = ();
  
  if ($debug == 1) {
    print "Add ips to ipfw\n";    	
  }
  
  if ($attr->{TABLE_ID}) {
    push @FW_ACTIONS, "$IPFW table $attr->{TABLE_ID} flush";
    foreach my $ip (@{ $attr->{NETS} }) {
      if ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        push @FW_ACTIONS, "$IPFW table $attr->{TABLE_ID} add $ip $attr->{TRAFFIC_CLASS}";
      }
    }
  }

  #make firewall actions
  foreach my $action (@FW_ACTIONS) {
    if ($debug == 1) {
      print "$action\n";
    }
    else {
      system("$action");
    }
  }

  return 0;
}

#**********************************************************
#
#**********************************************************
sub add_to_iptables {
  my ($attr) = @_;

  if (!-f '/usr/sbin/ipset') {
    print "/usr/sbin/ipset Not found.\n";
    exit;
  }

  my @FW_ACTIONS = ('/sbin/iptables -F -t mangle', 
                    '/sbin/iptables -t mangle -A PREROUTING -j MARK --set-mark 1', '/usr/sbin/ipset -X UKRAINE', 
                    '/usr/sbin/ipset -N UKRAINE nethash');

  if ($attr->{TABLE_ID}) {
    push @FW_ACTIONS, "$IPFW table $attr->{TABLE_ID} flush";
    foreach my $ip (@{ $attr->{NETS} }) {
      if ($ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
        push @FW_ACTIONS, "/usr/sbin/ipset -A UKRAINE $ip";
      }
    }
  }

  push @FW_ACTIONS, '/sbin/iptables -t mangle --flush',
  '/sbin/iptables -t mangle -A PREROUTING -m set --set UKRAINE src -j MARK --set-mark 2', 
  'echo 1 > /proc/sys/vm/drop_caches', 
  'echo 2 > /proc/sys/vm/drop_caches', 
  'echo 3 > /proc/sys/vm/drop_caches', 'sync';

  #make firewall actions
  foreach my $action (@FW_ACTIONS) {
    if ($debug == 1) {
      print "$action\n";
    }
    else {
      system("$action");
    }
  }
}


#**********************************************************
#
#**********************************************************
sub add_2_mikrotik {


}

#**********************************************************
#
#**********************************************************
sub help {

  print << "[END]";
traffic_filters.pl version: $version
Get traffic filters add it to NAS servers

mikrotik  - Update mikrotik traffic filters
ipfw      - Update ipfw class table tables for FreeBSD
iptables  - Update ipset iptables for Linux
route=net_id:router_ip - update route table

type=ua_ix- filter type. defaklt ua_ix. (ua_ix,ros_com,crimea_ix,belarus_ax)

help      - this help
DEBUG     - Debug mode

[END]

  exit;
}

1
