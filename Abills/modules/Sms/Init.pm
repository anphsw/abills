package Sms::Init;
=head1

  INIT SMS Service

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

our @EXPORT = qw(
  init_sms_service
);

our @EXPORT_OK = qw(
  init_sms_service
);

#**********************************************************
=head2 init_sms_service($db, $admin, $conf)

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
    { SMS_ESKIZ_URL          => 'Eskizsms'              },
    { SMS_BROKER_LOGIN       => 'Sms_Broker'            },
    { SMS_OMNICELL_URL       => 'Omnicell'              },
    { SMS_LIKON_URL          => 'LikonSms'              },
    { SMS_MSGAM_URL          => 'MsgAm'                 },
    { SMS_CABLENET_LOGIN     => 'Cablenet'              },
    { SMS_WEBSMS_URL         => 'WebSms'                },
    { SMS_FENIX_URL          => 'Fenix'                 },
    { SMS_AMD_URL            => 'AMD'                   },
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