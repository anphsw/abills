#!/usr/bin/perl

use strict;
use warnings;

our (
  %conf,
  $base_dir,
  %lang
);

BEGIN {
  require '/usr/abills/libexec/config.pl';

  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . '/lib/',
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/modules/",
    $libpath . "Abills/mysql/",
    $libpath . "Abills/modules/Callcenter/",
  );
}

use Users;
use Admins;
use Abills::SQL;
use Users;
use Contacts;
use Abills::Misc;

my $sql = Abills::SQL->connect(
  $conf{dbtype}, 
  $conf{dbhost}, 
  $conf{dbname}, 
  $conf{dbuser},
  $conf{dbpasswd}, { 
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : 'utf-8'  
  }
);

my $db  = $sql->{db};

our $admin    = Admins->new($db, \%conf);
our $Users    = Users->new($db, $admin, \%conf);
our $Contacts = Contacts->new($db, $admin, \%conf);

callcenter_proccess(\%ENV, init_call_center());

exit 1;

#**********************************************************
=head2 init_call_center()
  
=cut
#**********************************************************
sub init_call_center {
  my ($attr) = @_;

  my $Callcenter_service;

  my @callcenter_systems = (
    { BINOTEL_KEY   => 'Binotel' },
  );

  foreach my $callcenter ( @callcenter_systems ) {
    my $config_key = ( keys %$callcenter )[0];
    if ($conf{ $config_key } ) {
      $Callcenter_service = $callcenter->{$config_key};  

      eval { 
        require "Callcenter/$Callcenter_service.pm"; 
      };
      
      if ($@) {
        print $@;
        exit;
      }
      else {
        $Callcenter_service->import();
        $Callcenter_service = $Callcenter_service->new($db, $admin, \%conf);
        last;
      }
    }
  }

  unless ($Callcenter_service) {
    $Callcenter_service->{errno} = 1;
    $Callcenter_service->{errstr} = 'CALLCENTER_PLUGIN_NOT_CONNECTION';
  }

  return $Callcenter_service;
}

#**********************************************************
=head2 callcenter_proccess()
  
=cut
#**********************************************************
sub callcenter_proccess {
  my $env = shift;
  my ($callcenter) = @_;

  $callcenter->get_users_service({ %{ $env } });

  return 1;
}

1;