package Sms::Init;
=head1

  INIT SMS Service

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use Abills::Loader qw/load_plugin/;

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
  my ($db, $admin, $conf, $attr) = @_;

  if ($attr->{UID}) {
    require Users;
    my $Users = Users->new($db, $admin, $conf);
    $Users->info($attr->{UID});
    $Users->group_info($Users->{GID});
    $attr->{SMS_SERVICE} ||= $Users->{SMS_SERVICE};
  }

  require Sms;
  my $Sms = Sms->new($db, $admin, $conf);
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
        db    => $db,
        admin => $admin,
        conf  => $conf
      }
    });
    next if $Sms_service->{errno};

    last;
  }

  if (!$Sms_service) {
    $Sms_service = {};
    $Sms_service->{errno} = 1;
    $Sms_service->{errstr} = 'SMS_SERVICE_NOT_CONNECTED';
  }
  return $Sms_service;
}

1;