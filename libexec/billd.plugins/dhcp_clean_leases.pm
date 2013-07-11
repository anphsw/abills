# billd plugin
#
# DESCRIBE: Clean dhcp leases table
#
#**********************************************************

dhcp_clean_leases();


#**********************************************************
#
#
#**********************************************************
sub dhcp_clean_leases {
  my ($attr)=@_;
  print "dhcp_clean_leases\n" if ($debug > 1);
  
  use Dhcphosts;
  
  my $Dhcphosts = Dhcphosts->new($db, $admin, \%conf);
  if ($debug > 6) {
    $Dhcphosts->{debug}=1;
  }

  $Dhcphosts->leases_clear({ ENDED => 1 });
}

1