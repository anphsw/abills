=head1 NAME

  Sms configure

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(json_former);
use Abills::Loader qw /load_plugin/;
require Control::Services;

our (
  %lang,
  $db,
  $admin,
  %conf,
  %FORM,
  $pages_qs,
  $index,
  %permissions,
  $DATE,
  $base_dir,
  $libpath,
  @bool_vals
);

use Sms;
my $Sms = Sms->new($db, $admin, \%conf);
our Abills::HTML $html;

require Abills::Template;
my $Templates = Abills::Template->new($db, $admin, \%conf, { html => $html, lang => \%lang, libpath => $libpath });

use Sms::Services;
my $Services = Sms::Services->new($db, $admin, \%conf, { LANG => \%lang });

#**********************************************************
=head2 sms_services()

=cut
#**********************************************************
sub sms_services {

  $Sms->{ACTION} = 'add';
  $Sms->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    my $result = $Services->sms_service_add(\%FORM);
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    $html->message('info', $lang{ADDED}) if !_error_show($result);
  }
  elsif ($FORM{change}) {
    my $result = $Services->sms_service_change(\%FORM);
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    $html->message('info', $lang{CHANGED}) if !_error_show($result);
  }
  elsif ($FORM{chg}) {
    $Sms->service_info({ ID => $FORM{chg} });
    $FORM{add_form} = 1;
    $Sms->{ACTION} = 'change';
    $Sms->{LNG_ACTION} = $lang{CHANGE};
  }
  elsif ($FORM{del}) {
    $Sms->service_del({ ID => $FORM{del} });
    $html->message('info', $lang{INFO}, "$lang{DELETED}: $FORM{del}") if !_error_show($Services);
  }
  elsif ($FORM{import}) {
    sms_service_import();
  }

  if ($FORM{add_form}) {
    $Sms->{DEBUG_SEL} = $html->form_select('DEBUG', {
      SELECTED  => $Sms->{DEBUG} || 0,
      SEL_ARRAY => [ 0, 1, 2, 3, 4, 5, 6, 7 ],
    });
    $Sms->{STATUS} = 'checked' if $Sms->{STATUS};
    $Sms->{BY_DEFAULT} = 'checked' if $Sms->{BY_DEFAULT};

    $Sms->{PLUGIN_SEL} = sel_plugins('Sms', { SELECT => 'PLUGIN', SELECTED => $Sms->{PLUGIN} });
    $Sms->{PLUGINS_SETTINGS} = json_former(sms_plugins_settings({
      SERVICE_PARAMS  => $Sms->{SERVICE_PARAMS},
      PLUGIN          => $Sms->{PLUGIN},
      SKIP_CONNECTION => $Sms->{PLUGIN} && $Sms->{PLUGIN} eq 'Turbosms' ? 0 : 1
    }));

    $html->tpl_show($Templates->_include('sms_services', 'Sms'), { %FORM, %{$Sms} });
  }

  result_former({
    INPUT_DATA      => $Sms,
    FUNCTION        => 'service_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,PLUGIN,COMMENT,STATUS,BY_DEFAULT',
    FUNCTION_FIELDS => 'change,del',
    FUNCTION_INDEX  => $index,
    SKIP_USER_TITLE => 1,
    FILTER_VALUES   => {
      by_default => sub {return $bool_vals[ shift ]},
    },
    EXT_TITLES      => {
      id         => '#',
      name       => $lang{NAME},
      comment    => $lang{COMMENTS},
      plugin     => 'Plug-in',
      status     => $lang{DISABLE},
      by_default => $lang{DEFAULT},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{SERVICES},
      qs      => $pages_qs,
      ID      => 'SMS_SERVICES',
      MENU    => "$lang{ADD}:index=$index&add_form=1:add;$lang{IMPORT}:index=$index&import=1:",
    },
    MAKE_ROWS       => 1,
    MODULE          => 'SMS',
    TOTAL           => 1,
    SEARCH_FORMER   => 1,
  });
}

#**********************************************************
=head2 sms_service_import() - import Sms services from conf

=cut
#**********************************************************
sub sms_service_import {

  my %sms_systems = (
    SMS_PLAYMOBILE_LOGIN   => 'Playmobile',
    SMS_CMD                => 'Cmd',
    SMS_TXTLOCAL_APIKEY    => 'Txtlocal',
    SMS_SMSC_USER          => 'Smsc',
    SMS_LITTLESMS_USER     => 'Littlesms',
    SMS_EPOCHTASMS_OPENKEY => 'Epochtasms',
    SMS_TURBOSMS_PASSWD    => 'Turbosms',
    SMS_JASMIN_USER        => 'Jasmin',
    SMS_SMSEAGLE_USER      => 'Smseagle',
    SMS_BULKSMS_LOGIN      => 'Bulksms',
    SMS_IDM_LOGIN          => 'IDM',
    SMS_TERRA_USER         => 'Sms_terra',
    SMS_UNIVERSAL_URL      => 'Universal_sms_module',
    SMS_ESKIZ_URL          => 'Eskizsms',
    SMS_BROKER_LOGIN       => 'Sms_Broker',
    SMS_OMNICELL_URL       => 'Omnicell',
    SMS_LIKON_URL          => 'LikonSms',
    SMS_MSGAM_URL          => 'MsgAm',
    SMS_CABLENET_LOGIN     => 'Cablenet',
    SMS_WEBSMS_URL         => 'WebSms',
    SMS_FENIX_URL          => 'Fenix',
    SMS_AMD_URL            => 'AMD',
    SMS_SMSCLUB_URL        => 'SmsClub',
    SMS_ALPHASMS_URL       => 'AlphaSms',
  );

  foreach my $config_key (sort keys %sms_systems) {
    next if !$conf{$config_key};

    $Sms->service_list({ PLUGIN => $sms_systems{$config_key}, NAME => $sms_systems{$config_key} });
    next if $Sms->{TOTAL} && $Sms->{TOTAL} > 1;

    my $sms_plugin = load_plugin("Sms::Plugins::$sms_systems{$config_key}", {
      SERVICE => { db => $db, admin => $admin, conf => \%conf }
    });
    next if !$sms_plugin || (ref $sms_plugin eq 'HASH') || !$sms_plugin->can('get_settings');

    my $settings = $sms_plugin->get_settings();
    my $params = {};

    next if !$settings || !$settings->{CONF} || ref $settings->{CONF} ne 'HASH';
    foreach my $key (keys %{$settings->{CONF}}) {
      $params->{$key} = $conf{$key};
    }

    $Services->sms_service_add({ PLUGIN => $sms_systems{$config_key}, NAME => $sms_systems{$config_key}, %{$params} });
  }
}

#**********************************************************
=head2 sms_plugins_settings($attr) - Get Settings of SMS Plugins

  Arguments:
    $attr   - Extra attributes
       PLUGIN          - Plugin name
       SERVICE_PARAMS  - Service parameters (Array of Hashes with PARAM and VALUE)

  Returns:
   A hash reference with the settings of each SMS plugin

  Example:

    sms_plugins_settings({ PLUGIN => 'PLUGIN_NAME', SERVICE_PARAMS => [{ PARAM => 'PARAM_NAME', VALUE => 'PARAM_VALUE' }] });

=cut
#**********************************************************
sub sms_plugins_settings {
  my ($attr) = @_;

  my $plugins_folder = "$base_dir" . 'Abills/modules/Sms/Plugins/';
  if (!-d $plugins_folder) {
    return {};
  }

  opendir(my $folder, $plugins_folder);
  my @plugins = map {s/\.pm$//r} grep(/\.pm$/, readdir($folder));
  closedir $folder;

  my $service_params = {};
  if ($attr->{PLUGIN} && $attr->{SERVICE_PARAMS} && ref($attr->{SERVICE_PARAMS}) eq 'ARRAY') {
    foreach my $param (@{$attr->{SERVICE_PARAMS}}) {
      next if !$param->{PARAM};

      $service_params->{$attr->{PLUGIN}}{$param->{PARAM}} = $param->{VALUE};
    }
  }
  my %settings = ();

  foreach my $plugin (@plugins) {
    next if !$plugin;

    my $params = { SKIP_CONNECTION => $attr->{SKIP_CONNECTION} || 0 };
    if ($attr->{SERVICE_PARAMS} && ref $attr->{SERVICE_PARAMS} eq 'ARRAY') {
      foreach my $param (@{$attr->{SERVICE_PARAMS}}) {
        next if !$param->{PARAM};

        $params->{$param->{PARAM}} = $param->{VALUE};
      }
    }

    my $Plugin = load_plugin("Sms::Plugins::$plugin", {
      SERVICE => {
        %{$params},
        db    => $db,
        admin => $admin,
        conf  => \%conf,
      }
    });

    next if !$Plugin || (ref $Plugin eq 'HASH') || !$Plugin->can('get_settings');

    $settings{$plugin} = $Plugin->get_settings();

    if ($attr->{PLUGIN} && $plugin eq $attr->{PLUGIN}) {
      $settings{$plugin}{CONF} = $service_params->{$plugin};
    }
  }

  return \%settings;
}

1;