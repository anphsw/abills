package Viber::buttons::Equipment_info;

use strict;
use warnings FATAL => 'all';
use Abills::Fetcher qw(web_request);

my %icons = (
  not_active       => "\xE2\x9D\x8C",
  active           => "\xE2\x9C\x85",
  check_connection => "\xF0\x9F\x93\xB6"
);

#**********************************************************
=head2 new($Botapi)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $user_config) = @_;

  my $self = {
    conf        => $conf,
    bot         => $bot,
    bot_db      => $bot_db,
    api         => $APILayer,
    user_config => $user_config
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {
  my $self = shift;

  return $self->{user_config}{equipment_user};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{check_connection} $self->{bot}{lang}{EQUIPMENT_CONNECTION_CHECK}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_WAIT} });

  my $custom_error_text = $self->{bot}->{html}->tpl_show(
    main::_include('viber_equipment_info_error', 'Viber'),
    {},
    { OUTPUT2RETURN => 1 }
  );

  my ($result) = $self->{api}->fetch_api({
    METHOD => 'GET',
    PATH   => '/user/equipment/'
  });

  my ($id, $equipment_info) = each %$result;
  if ($result->{errno} || !$id) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_ERROR} });
    return 0;
  }

  if (defined($equipment_info->{PORT_STATUS})) {
    if ($equipment_info->{PORT_STATUS} ne '1') {
      $self->{bot}->send_message({ text => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_ROUTER_NOT_WORKING}" });
      $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;
    }
    else {
      $self->{bot}->send_message({ text => "$icons{active} $self->{bot}{lang}{EQUIPMENT_ROUTER_WORKING}" });
    }
    $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_CHECK_COMPLETED} });
    return 0;
  }

  if (!defined($equipment_info->{STATUS}) || $equipment_info->{STATUS} < 1) {
    $self->{bot}->send_message({ text => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_OPTICAL_TERMINAL_NOT_WORKING}" });
    $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;
    return 0;
  }

  $self->{bot}->send_message({ text => "$icons{active} $self->{bot}{lang}{EQUIPMENT_OPTICAL_TERMINAL_WORKING}", });

  $equipment_info->{ONU_PORTS_STATUS} //= $equipment_info->{onuPortsStatus};
  if (defined $equipment_info->{ONU_PORTS_STATUS}) {
    my @ports_status = split(/\n/, $equipment_info->{ONU_PORTS_STATUS});
    my $port_info = shift @ports_status;
    my ($port, $status) = split(/ /, $port_info);
    $status //= 0;

    if (!$status || $status != 1) {
      $self->{bot}->send_message({ text => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_ROUTER_NOT_WORKING}" });
      $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;
      return 0;
    }
    $self->{bot}->send_message({ text => "$icons{active} $self->{bot}{lang}{EQUIPMENT_ROUTER_WORKING}" });
  }

  $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_CHECK_COMPLETED} });

  return 0;
}

1;
