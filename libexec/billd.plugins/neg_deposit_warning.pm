# billd plugin
#
# DESCRIBE: Check run programs and run if they shutdown
#
#**********************************************************

neg_deposit_warning();


#**********************************************************
#
#
#**********************************************************
sub neg_deposit_warning {
  my ($attr)=@_;
  print "neg_deposit_warning\n" if ($debug > 1);

  if ($debug > 7) {
    $Nas->{debug}= 1 ;
    $Dv->{debug} = 1 ;
    $Sessions->{debug}=1;
  }
  
  $Sessions->online({	USER_NAME      => '_SHOW', 
      NAS_PORT_ID    => '_SHOW', 
      CONNECT_INFO   => '_SHOW',
      TP_ID          => '_SHOW', 
      SPEED          => '_SHOW', 
      JOIN_SERVICE   => '_SHOW', 
      CLIENT_IP      => '_SHOW', 
      DURATION_SEC   => '_SHOW', 
      STARTED        => '_SHOW',
      CID            => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      PAYMENT_METHOD => '_SHOW',
      NAS_ID         => $LIST_PARAMS{NAS_IDS},
      %LIST_PARAMS,
    }
  );

  #my $online      = $sessions->{nas_sorted};

  foreach my $info (@{ $sessions->{list} }) {
  print "Login: $info->{user_name} IP: $info->{client_ip} DEPOSIT: $info->{deposit} CREDIT: $info->{credit}\n" if ($debug);
    if ($info->{deposit} + $info->{credit} <= 0 && $info->{payment_type} == 0) {
    	mk_redirect({ IP => $info->{ip} });
    }
  }
}


#**********************************************************
#
#**********************************************************
sub mk_redirect {
  my ($attr)=@_;
	
	my $cmd = '';
	
	if ($conf{NEG_DEPOSIT_WARNING_CMD}) {
		$cmd = $conf{NEG_DEPOSIT_WARNING_CMD};
		$cmd =~ s/IP/$attr->{IP}/g;
	}
	elsif ($OS eq 'FreeBSD') {
		$cmd = "/usr/local/bin/sudo /sbin/ipfw table 32 add $attr->{IP}";
		#/usr/local/bin/sudo /sbin/ipfw table 10 delete $attr->{IP};
		#/usr/local/bin/sudo /sbin/ipfw table 11 delete $attr->{IP};";
	}
	elsif($OS eq 'Linux') {
		
	}
	
	if ($debug) {
		print "$cmd\n";
	}
	
	if ($debug<5) {
	  my $result = `$cmd`;
	}
	
}

1
