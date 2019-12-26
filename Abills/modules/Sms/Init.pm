=head1

  INIT SMS Service

=cut

use strict;
use warnings FATAL => 'all';

#**********************************************************
=head2 init()

=cut
#**********************************************************
sub init_sms_service {
  my ($db, $admin, $conf) = @_;

  my $Sms_service;

  my @sms_systems = (
    { SMS_PLAYMOBILE_LOGIN   => 'Playmobile'            },
    { SMS_CMD                => 'Cmd'                   },
    { SMS_TXTLOCAL_APIKEY    => 'Txtlocal'              },
    { SMS_SMSC_USER          => 'Smsc'                  },
    { SMS_LITTLESMS_USER     => 'Littlesms'             },
    { SMS_EPOCHTASMS_OPENKEY => 'Epochtasms'            },
    { SMS_TURBOSMS_PASSWD    => 'Turbosms'              },
    { SMS_JASMIN_USER        => 'Jasmin'                },
    { SMS_SMSEAGLE_USER      => 'Smseagle'              },
    { SMS_BULKSMS_LOGIN      => 'Bulksms'               },
    { SMS_IDM_LOGIN          => 'IDM'                   },
    { SMS_TERRA_USER         => 'Sms_terra'             },
    { SMS_UNIVERSAL_URL      => 'Universal_sms_module'  },
  );

  foreach my $sms_system ( @sms_systems ) {
    my $config_key = ( keys %$sms_system )[0];
    if ($conf->{ $config_key } ) {
      $Sms_service = $sms_system->{$config_key};     
      eval { require "Sms/$Sms_service.pm"; };
      if (!$@) {
        $Sms_service->import();
        $Sms_service = $Sms_service->new($db, $admin, $conf);
        last;
      }
      else {
        print $@;
        exit;
      }
    }
  }

  if (! $Sms_service) {
    $Sms_service->{errno}=1;
    $Sms_service->{errstr}="SMS_SERVICE_NOT_CONNECTED";
  }

  return $Sms_service;
}

1;