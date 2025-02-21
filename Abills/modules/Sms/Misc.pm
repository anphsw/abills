package Sms::Misc;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Sms::Misc

=cut

=head2 SYNOPSIS

  Sms miscellaneous functions

=cut

use Sms;
use Sms::Init;
use Abills::Loader qw/load_plugin/;

#*******************************************************************
=head2 new() - init

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 sms_status() - Request for sms status

=cut
#**********************************************************
sub sms_status {
  my ($self, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  do 'Abills/Misc.pm';
  print "Sms status\n" if ($debug > 1);
  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});
  my $services = $Sms->service_list({
    PLUGIN     => '_SHOW',
    STATUS     => '0',
    DEBUG      => '_SHOW',
    BY_DEFAULT => '_SHOW',
    ID         => ($attr->{SMS_SERVICE} && $attr->{SMS_SERVICE} =~ /^\d+/) ? $attr->{SMS_SERVICE} : '_SHOW',
    SORT       => 'smss.by_default DESC, smss.id ASC',
    COLS_NAME  => 1
  });
  return {} if !$Sms->{TOTAL} || $Sms->{TOTAL} < 1;

  my $Sms_service = '';
  foreach my $service (@{$services}) {
    next if !$service->{plugin};

    my $service_params = $Sms->service_params({ SERVICE_ID => $service->{id}, COLS_NAME => 1, COLS_UPPER => 1 });
    my $params = { DEBUG => $service->{debug} };

    foreach my $param (@{$service_params}) {
      next if !$param->{PARAM};
      $params->{$param->{PARAM}} = $param->{VALUE};
    }

    $Sms_service = load_plugin("Sms::Plugins::$service->{plugin}", {
      SERVICE => {
        %{$params},
        db    => $self->{db},
        admin => $self->{admin},
        conf  => $self->{conf}
      }
    });

    next if $Sms_service->{errno};

    if ($Sms_service->can('get_status')) {
      if ($debug > 2) {
        $Sms->{debug}=1;
      }
      my $sms_list = $Sms->list({
        DATETIME   => '_SHOW',
        SMS_STATUS => 0,
        COLS_NAME  => 1,
        SKIP_DEL_CHECK=>1,
        PAGE_ROWS  => 100000
      });

      foreach my $sms (@$sms_list) {
        if ($debug > 1) {
          print "ID: $sms->{id} DATE: $sms->{datetime}\n";
        }

        $Sms_service->get_status({
          REF_ID => $sms->{datetime},
          EXT_ID => ($sms->{ext_id} ? $sms->{ext_id} : $sms->{id}),
          DEBUG  => $debug || 0,
        });

        if ($debug > 1) {
          print "  STATUS: " . (defined($Sms_service->{status}) ? $Sms_service->{status} : 0) . "\n";
        }

        if (!$Sms_service->{errno}) {
          if ($Sms_service->{status} || $Sms_service->{list}->[0]{status}) {
            $Sms->change({
              ID     => $sms->{id},
              STATUS => ($Sms_service->{status}) ? $Sms_service->{status} : $Sms_service->{list}->[0]{status}
            });
          }
        }
      }
    }
  }

  return 1;
}

1;