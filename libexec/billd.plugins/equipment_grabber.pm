=head1 NAME

  equipment grab

  Params:
    SEARCH_MAC

  Arguments:

   CLEAN=1
   IP_RANGE='192.168.1.0/24'
   SNMP_VERSION=1 - Default:1
   INFO_ONLY=1 

=cut


use strict;
use warnings "all";
use Abills::Base qw(in_array startup_files _bp);
use Nas;
use Equipment;

use SNMP_util;
use SNMP_Session;
use Abills::Misc qw(snmp_get host_diagnostic);

our (
  $db,
  %conf,
  $argv,
  $debug,
  $var_dir,
  %lang
);

our Admins $Admin;

$Admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );
my $Equipment = Equipment->new( $db, $Admin, \%conf );
my $Nas = Nas->new( $db, \%conf, $Admin);
my $Log = Log->new($db, $Admin);

if($debug > 2) {
  $Log->{PRINT}=1;
}
else {
  $Log->{LOG_FILE} = $var_dir.'/log/equipment_check.log';
}

equipment_grab();

#**********************************************************
=head2 equipment_check($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_grab {

  if($debug > 3) {
    print "Equipment grab\n";
  }

  my @equipment_info = ();
  if($argv->{FILENAME}) {
    @equipment_info = @{ equipment_from_file($argv->{FILENAME}) };
  }
  elsif($argv->{IP_RANGE}) {
    @equipment_info = @{ equipment_scan($argv->{IP_RANGE}) };
  }
  else {
    print "Show help\n";
  }
  return 1 if ($argv->{INFO_ONLY});
  foreach my $info ( @equipment_info ) {
    if($debug > 1) {
      print "$info->{IP}\n";
      foreach my $key (keys %$info) {
        print "$key - $info->{$key}\n";
      }
      print "\n";
    }

    if(! $info->{IP}) {
      next;
    }

    my $nas_list = $Nas->list({
      NAS_IP    => $info->{IP},
      COLS_NAME => 1,
      PAGE_ROWS => 3
    });

    if(! $Nas->{TOTAL}) {
      if($debug > 2) {
        print "Not exists \n";
      }

      if(! $info->{NAS_TYPE}) {
        $info->{NAS_TYPE} = 'other';
      }

      $Nas->add($info);

      $info->{NAS_ID} = $Nas->{NAS_ID};
    }
    else {
      $info->{NAS_ID} = $nas_list->[0]{nas_id};
    }

    #Check equipment
    $Equipment->_list({ NAS_ID => $info->{NAS_ID} });

    if(! $Equipment->{TOTAL}) {
      $info->{MODEL_ID} = equipment_model_detect($info->{MODEL}) unless ($argv->{IP_RANGE});
      if($info->{MODEL_ID}) {
        $Equipment->_add($info);
        next;
      }
      elsif ($info->{MODEL}) {
        print "Can't find model '$info->{MODEL}'\n";
        next;
      }
    }
    else {
      print "Equipment exist\n" if($debug);
    }
  }

  return 1;
}


#**********************************************************
=head2 equipment_from_file($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_from_file {
  my($filename)=@_;

  my @equipment_info = ();
  my $content = '';
  if(open(my $fh, '<', $filename)) {
    while(<$fh>) {
      $content .= $_;
    }
    close($fh);
  }

  my @rows = split(/[\r]\n/, $content);
  my @cols_name = ();


  if($argv->{COLS_NAME}) {
    @cols_name = split(/,\s?/, $argv->{COLS_NAME});
  }

  foreach my $line ( @rows ) {
    my @cols = split(/\t/, $line);
    my %equipment_info = ();

    for(my $i=0; $i<=$#cols; $i++) {
      my $col_name = ($cols_name[$i]) ? $cols_name[$i] : $i;
      $equipment_info{$col_name}=$cols[$i];
    }

    push @equipment_info, \%equipment_info;
  }

  return \@equipment_info;
}

#**********************************************************
=head2 equipment_model_detect($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_model_detect {
  my ($model) = @_;
  my $model_id = 0;

  return 0 unless ($model);

  my $list = $Equipment->model_list({
    MODEL_NAME => $model,
    COLS_NAME  => 1
  });

  if($Equipment->{TOTAL}) {
    $model_id = $list->[0]->{id};
  }

  return $model_id;
}

#**********************************************************
=head2 equipment_scan($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub equipment_scan {
  my ($ip_range) = @_;

  my ($ip, $mask) = split /\//, $ip_range;
  die "Wrong mask: '$mask'" unless ($mask > 0 && $mask < 32);
  my $ip_count = 2 ** (32 - $mask);
  my $split_ip = my ($w, $x, $y, $z) = split /\./, $ip;
  die "Wrong ip: '$ip'" unless ($split_ip == 4);
  
  my $i = 0;
  my @info = ();

  my $list = $Equipment->model_list({
    MODEL_NAME => '_SHOW',
    COLS_NAME  => 1,
  });

  while (++$i < $ip_count) {
    my %host = ();
    $z++;
    if ($z > 255) {
      $z = 1;
      $y++;
    }
    last if ($y > 255);

    print "check $w.$x.$y.$z\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});

    my $ping = host_diagnostic("$w.$x.$y.$z", {
      QUITE         => 1,
      RETURN_RESULT => 1,
    });

    next if (!$ping);

    $host{IP} = "$w.$x.$y.$z";
    $host{NAS_NAME} = join ('_', $w, $x, $y, $z);

    $host{COMMENTS} = snmp_get({ 
                                SNMP_COMMUNITY => $host{IP}, 
                                OID            => ".1.3.6.1.2.1.1.1.0",
                                SILENT         => 1,
                                VERSION        => $argv->{SNMP_VERSION} || 1
                              });

    if ($host{COMMENTS}) {
      print "SNMP answer: '$host{COMMENTS}'\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});
      $host{MULTY_RESULT} = '';
      foreach (@$list) {
        next unless($_->{model_name});
        if ($host{COMMENTS} =~ m/$_->{model_name}/) {
          print "Found matches:\n model_id: '$_->{id}'\n model_name: '$_->{model_name}'\n" if ($argv->{DEBUG} || $argv->{INFO_ONLY});

          if ($host{MODEL_ID}) {
            $host{MULTY_RESULT} .= "$_->{id}, "
          }
          else {
            $host{MODEL_ID} = $_->{id};
          }
        }
      }
    }
    $host{COMMENTS} .= "\n Also found matches $host{MULTY_RESULT}" if ($host{MULTY_RESULT});

    push @info, \%host;
  }
  return \@info;
}

1;