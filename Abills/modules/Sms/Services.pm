package Sms::Services;

use strict;
use warnings FATAL => 'all';

use Sms;
use Control::Errors;
use Abills::Loader qw /load_plugin/;

my Sms $Sms;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  my $admin = shift;
  my $conf = shift;
  my $attr = shift;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{LANG} || {},
    html  => $attr->{HTML}
  };

  bless($self, $class);

  $Sms = Sms->new($db, $admin, $conf);
  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang}, module => 'Sms' });

  return $self;
}

#**********************************************************
=head2 sms_service_add($attr) - Add SMS service

  Arguments:
    $attr   - Extra attributes
       PLUGIN   - Plugin name
       ...      - Other parameters depending on the plugin

  Returns:
    Object of the SMS service or error object if an error occurred

  Example:
    $Services->sms_service_add({ PLUGIN => 'SomePlugin', PARAM1 => 'value1', PARAM2 => 'value2' });

=cut
#**********************************************************
sub sms_service_add {
  my $self = shift;
  my ($attr) = @_;

  return $Errors->throw_error(1160001) if !$attr->{PLUGIN};

  my $Plugin = load_plugin("Sms::Plugins::$attr->{PLUGIN}", { SERVICE => { %{$self}, %{$attr} } });
  return $Errors->throw_error(1160001) if !$Plugin;
  return $Plugin if ref $Plugin eq 'HASH' && $Plugin->{errno};

  $Sms->service_add($attr);
  return $Sms if $Sms->{errno} || !$Plugin->can('get_settings') || !$Sms->{INSERT_ID};

  my $service_id = $Sms->{INSERT_ID};

  my $default_settings = $Plugin->get_settings();
  return $Sms if (!$default_settings || ref($default_settings) ne 'HASH' || !$default_settings->{CONF});

  my $params = [];
  foreach my $param (keys %{$default_settings->{CONF}}) {
    my $value = defined $attr->{$param} ? $attr->{$param} : $default_settings->{CONF}{$param};
    push @{$params}, [$service_id, $param, $value];
  }

  $Sms->service_params_change({ SERVICE_ID => $service_id, PARAMS => $params });

  return $Sms;
}

#**********************************************************
=head2 sms_service_change($attr) - Change SMS service

  Arguments:
    $attr   - Extra attributes
       ID      - Service ID
       PLUGIN  - Plugin name
       ...     - Other parameters depending on the plugin

  Returns:
    Object of the SMS service or error object if an error occurred

  Example:
    $Services->sms_service_change({ ID => '1', PLUGIN => 'SomePlugin', PARAM1 => 'value1', PARAM2 => 'value2' });

=cut
#**********************************************************
sub sms_service_change {
  my $self = shift;
  my ($attr) = @_;

  my $service_id = $attr->{ID};

  return $Errors->throw_error(1160002) if !$service_id;
  return $Errors->throw_error(1160001) if !$attr->{PLUGIN};

  my $Plugin = load_plugin("Sms::Plugins::$attr->{PLUGIN}", { SERVICE => { %{$self}, %{$attr} } });
  return $Errors->throw_error(1160001) if !$Plugin;
  return $Plugin if ref $Plugin eq 'HASH' && $Plugin->{errno};

  $Sms->service_change($attr);
  return $Sms if !$Plugin->can('get_settings');

  my $default_settings = $Plugin->get_settings();
  return $Sms if (!$default_settings || ref($default_settings) ne 'HASH' || !$default_settings->{CONF});

  my $params = [];
  foreach my $param (keys %{$default_settings->{CONF}}) {
    my $value = defined $attr->{$param} ? $attr->{$param} : $default_settings->{CONF}{$param};
    push @{$params}, [$service_id, $param, $value];
  }

  $Sms->service_params_change({ SERVICE_ID => $service_id, PARAMS => $params });

  return $Sms;
}

#**********************************************************
=head2 sms_services_sel($attr) - SMS services select

  Arguments:
    $attr   - Extra attributes
       NAME     - Name of the select form
       SELECTED - Selected plugin

  Returns:
   HTML form select with the list of SMS services

  Example:

    sms_services_sel({ NAME => 'SELECT_NAME', SELECTED => 1 });

=cut
#**********************************************************
sub sms_services_sel {
  my $self = shift;
  my ($attr) = @_;

  return '' if !$self->{html};

  my $services = $Sms->service_list({
    NAME      => '_SHOW',
    COLS_NAME => 1
  });

  return $self->{html}->form_select($attr->{NAME} || 'SMS_SERVICE', {
    SELECTED    => $attr->{SELECTED},
    SEL_LIST    => $Sms->service_list({ NAME => '_SHOW', STATUS => '0', COLS_NAME => 1 }),
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name',
    NO_ID       => 1,
    SEL_OPTIONS => { '' => '--' }
  });
}


1;