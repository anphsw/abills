package Equipment_info;

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
  my ($db, $admin, $conf, $bot) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    bot   => $bot,
  };

  bless($self, $class);

  return $self;
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

  my $uid = $self->{bot}->{uid};

  $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_WAIT} });

  use Abills::HTML;
  my $html = Abills::HTML->new({ CONF => $self->{conf} });
  my $custom_error_text = $html->tpl_show(main::_include('telegram_equipment_info_error', 'Telegram'), {}, { OUTPUT2RETURN => 1 });

  # my $result = $self->fetch_api({
  #   method => 'GET',
  #   url   => ($self->{conf}->{API_URL} || '') . '/api.cgi/user/equipment/'
  # });

  my $result = $self->fetch_api({
    method => 'GET',
    path   => '/user/equipment/'
  });

  if ($result && ref $result eq 'HASH') {
    if ($result->{errno}) {
      $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_ERROR} });
      return;
    }

    my $id = (keys %{$result})[0];
    if (!$id) {
      $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_ERROR} });
      return;
    }
    my $equipment_info = $result->{$id};

    if (defined($equipment_info->{PORT_STATUS})) {
      if ($equipment_info->{PORT_STATUS} ne '1') {
        $self->{bot}->send_message({ text => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_ROUTER_NOT_WORKING}" });
        $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;
      }
      else {
        $self->{bot}->send_message({ text => "$icons{active} $self->{bot}{lang}{EQUIPMENT_ROUTER_WORKING}" });
      }
      $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_CHECK_COMPLETED} });
      return;
    }

    if (!defined($equipment_info->{STATUS}) || $equipment_info->{STATUS} < 1) {
      $self->{bot}->send_message({ text => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_OPTICAL_TERMINAL_NOT_WORKING}" });
      $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;
      return;
    }

    $self->{bot}->send_message({ text => "$icons{active} $self->{bot}{lang}{EQUIPMENT_OPTICAL_TERMINAL_WORKING}" });

    $equipment_info->{ONU_PORTS_STATUS} //= $equipment_info->{onuPortsStatus};
    if (defined $equipment_info->{ONU_PORTS_STATUS}) {
      my @ports_status = split(/\n/, $equipment_info->{ONU_PORTS_STATUS});
      my $port_info = pop @ports_status;
      my ($port, $status) = split(/ /, $port_info);
      $status //= 0;

      if (!$status || $status != 1) {
        $self->{bot}->send_message({ text => "$icons{not_active} $self->{bot}{lang}{EQUIPMENT_ROUTER_NOT_WORKING}" });
        $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;
        return;
      }
      $self->{bot}->send_message({ text => "$icons{active} $self->{bot}{lang}{EQUIPMENT_ROUTER_WORKING}" });
    }

    $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_CHECK_COMPLETED} });
    return;
  }

  $self->{bot}->send_message({ text => $self->{bot}{lang}{EQUIPMENT_ERROR} });
  $self->{bot}->send_message({ text => $custom_error_text }) if $custom_error_text;

  return 1;
}

#**********************************************************
=head2 fetch_api($attr)

=cut
#**********************************************************
sub fetch_api {
  my $self = shift;
  my ($attr) = @_;

  return {} if !$self->{bot} || !$self->{bot}{chat_id};

  $ENV{HTTP_USERBOT} = 'TELEGRAM';
  $ENV{HTTP_USERID} = $self->{bot}{chat_id};
  use Abills::Api::Handle;
  my $handle = Abills::Api::Handle->new($self->{db}, $self->{admin}, $self->{conf}, { direct => 1 });

  my ($result) = $handle->api_call({
    METHOD => $attr->{method},
    PATH   => $attr->{path},
  });

  return $result;
}

1;
