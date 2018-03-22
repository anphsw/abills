=head1 NAME

 create ISC DHCP conf file

=cut

use strict;
use warnings FATAL => 'all';

use Socket;
use Abills::Base qw(_bp int2ip);
use Abills::HTML;
use Abills::Misc;

our(
  $db,
  %conf,
  $admin,
  %lang,
  %permissions,
  %FORM,
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Nas      = Nas->new($db, \%conf, $admin);

our $html = Abills::HTML->new(
  {
    CONF => \%conf,
  }
);

$html->{language} = '';
require Abills::Templates;

isc_dhcp_config();

#**********************************************************
=head2 isc_dhcp_config() - make_config

=cut
#**********************************************************
sub isc_dhcp_config {

  my $debug = 0;
  my $filename = $conf{INTERNET_ISC_DHCP_CONFIG};

  foreach (@ARGV)
  {
    if($_ =~ /DEBUG/){
      $debug = 1;
    }
    if($_ =~ /CONFIG=\//){
      (undef, $filename) = split('=', $_);
    }
  }

  if (!$filename && !$conf{INTERNET_ISC_DHCP_CONFIG}){
  	print 'ERROR: $conf{INTERNET_ISC_DHCP_CONFIG} is empty';
  	exit;
  }

  my $networks = $Nas->ip_pools_list({
  	COLS_NAME     => 1,
  	COLS_UPPER    => 1, 
    STATIC        => 1,
    NETMASK       => '_SHOW',
    GATEWAY       => '_SHOW',
    NAME          => '_SHOW',
  	PAGE_ROWS     => 60000,	
  });
  _error_show($Nas);

  my $subnet_tpls //= '';

  foreach my $subnet (@{$networks}) {
  	$subnet->{RANGE}   = 'range ' . $subnet->{FIRST_IP} . ' ' . $subnet->{LAST_IP} . ';';
    my $address_int    = 0 + $subnet->{IP} & 0 + $subnet->{NETMASK};
    $subnet->{SUBNET}  = int2ip($address_int);
    $subnet->{NETMASK} = int2ip($subnet->{NETMASK});
    $subnet->{GATEWAY} = int2ip($subnet->{GATEWAY});
    $subnet_tpls .= $html->tpl_show(_include( 'internet_isc_dhcp_conf_subnet', 'Internet'), {%$subnet}, {OUTPUT2RETURN => 1}) . "\n";
  }

  my $hosts = $Internet->list({
  	COLS_NAME      => 1,
  	COLS_UPPER     => 1, 
    INTERNET_LOGIN => '_SHOW',
  	CID            => '*',
  	IP_NUM         => '>0',             
  	PAGE_ROWS      => 60000,	
  }); 
  _error_show($Internet);

  my $hosts_tpls //= '';

  foreach my $host (@{$hosts}) {
  	$host->{IP}  = int2ip($host->{IP_NUM});
    $hosts_tpls .= $html->tpl_show(_include( 'internet_isc_dhcp_conf_host', 'Internet'), {%$host}, {OUTPUT2RETURN => 1}) . "\n";
  }

  my $conf_main = $html->tpl_show(_include( 'internet_isc_dhcp_conf_main', 'Internet'), 
    {
      SUBNETS => $subnet_tpls, 
      HOSTS => $hosts_tpls, 
      DATE => $DATE
    }, 
    {OUTPUT2RETURN => 1}
  ) . "\n";

  open(my $fh, '>', $filename) or die "ERROR: Can`t open filename. Edit " . '$conf{INTERNET_ISC_DHCP_CONFIG}.' . " $!\n";
    print $fh $conf_main;
  close $fh;

  if($debug){
    print 'The configuration file was successfully created' . "\n";
  }
  
}

1;