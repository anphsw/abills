use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Echat - crm E-chat forms

=cut

our (
  $Crm,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  $libpath,
  %LIST_PARAMS
);

use JSON qw(decode_json);
use Abills::Fetcher qw/web_request/;

if (form_purchase_module({
  HEADER          => $FORM{UID},
  MODULE          => 'Crm::db::Echat',
  REQUIRE_VERSION => 0.01
})) {
  exit;
}

use Abills::Template;
my $Templates = Abills::Template->new($db, $admin, \%conf, { html => $html, lang => \%lang, libpath => $libpath });

use Crm::db::Echat;
my $Echat = Echat->new($db, $admin, \%conf);

use Control::Errors;
my $Errors = Control::Errors->new($db, $admin, \%conf, { lang => \%lang, module => 'Crm' });

use constant ECHAT_MESSENGERS => {
  telegram => {
    base_url  => 'https://telegram.e-chat.tech/api',
    endpoints => {
      enable_webhook  => '/CreateChannel.php',
      disable_webhook => '/DisableChannel.php'
    },
    headers   => {
      api_key => 'API'
    }
  },
  viber    => {
    base_url  => 'https://e-chat.tech/api/viber/v2',
    endpoints => {
      enable_webhook  => '/channel/connect',
      disable_webhook => '/channel/disconnect'
    },
    headers   => {
      api_key => 'Api-Key'
    }
  },
  whatsapp => {
    base_url  => 'https://e-chat.tech/api/whatsapp/v1',
    endpoints => {
      enable_webhook  => '/channel/connect',
      disable_webhook => '/channel/disconnect'
    },
    headers   => {
      api_key => 'Api-Key'
    }
  }
};

#**********************************************************
=head2 crm_echat_numbers($attr)

=cut
#**********************************************************
sub crm_echat_numbers {

  $Echat->{ACTION} = 'add';
  $Echat->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Echat->crm_echat_numbers_add(\%FORM);
    $html->message('success', $lang{CRM_NUMBER_ADDED}) if (!_error_show($Crm));
  }
  elsif ($FORM{chg}) {
    $Echat->{ACTION} = 'change';
    $Echat->{LNG_ACTION} = $lang{CHANGE};

    $Echat->crm_echat_numbers_info({ ID => $FORM{chg} });
  }
  elsif ($FORM{change}) {
    $Echat->crm_echat_numbers_change(\%FORM);
    $html->message('success', $lang{CRM_NUMBER_CHANGED}) if (!_error_show($Crm));
  }
  elsif ($FORM{del}) {
    $Echat->crm_echat_numbers_del({ ID => $FORM{del} });
    $html->message('success', $lang{CRM_NUMBER_DELETED}) if (!_error_show($Crm));
  }
  elsif ($FORM{activate}) {
    my $result = _crm_echat_activate_number($FORM{activate});
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    if (!_error_show($result)) {
      $Echat->crm_echat_numbers_change({
        ID     => $FORM{activate},
        STATUS => 0
      });
      $html->message('success', $lang{CRM_NUMBER_ACTIVATED}) if (!_error_show($Crm));
    }
  }
  elsif ($FORM{deactivate}) {
    my $result = _crm_echat_deactivate_number($FORM{deactivate});
    $result->{message} = $result->{errmsg} if $result->{errmsg};
    if (!_error_show($result)) {
      $Echat->crm_echat_numbers_change({
        ID     => $FORM{deactivate},
        STATUS => 1
      });
      $html->message('success', $lang{CRM_NUMBER_DEACTIVATED}) if (!_error_show($Crm));
    }
  }

  if ($FORM{add_form} || $FORM{chg}) {
    $Echat->{TYPE_SEL} = $html->form_select('TYPE', {
      SELECTED    => $Echat->{TYPE},
      SEL_HASH    => {
        'telegram' => 'Telegram',
        'viber'    => 'Viber',
        'whatsapp' => 'WhatsApp',
      },
      SEL_OPTIONS => { '' => '' },
      SORT_KEY    => 1,
      NO_ID       => 1,
      EX_PARAMS   => 'required="required"',
    }, { class => 'form-control' });

    $html->tpl_show($Templates->_include('crm_echat_number', 'Crm'), $Echat);
  }

  result_former({
    INPUT_DATA      => $Echat,
    FUNCTION        => 'crm_echat_numbers_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,TYPE,NUMBER,TOKEN,STATUS,COMMENTS,ACTION_BTN',
    FUNCTION_FIELDS => 'change, del',
    SKIP_USER_TITLE => 1,
    FILTER_VALUES   => {
      action_btn => sub {
        my (undef, $line) = @_;

        return '' if (!defined($line->{status}));

        if ($line->{status}) {
          return $html->button($lang{DO_ENABLE}, "index=$index&activate=$line->{id}", { class => 'btn btn-success btn-xs' });
        }

        return $html->button($lang{HANGUP}, "index=$index&deactivate=$line->{id}", {
          MESSAGE => "$lang{HANGUP}: $line->{number}?",
          class   => 'btn btn-warning btn-xs'
        });
      },
    },
    EXT_TITLES      => {
      id         => '#',
      type       => $lang{TYPE},
      status     => $lang{STATUS},
      token      => $lang{CRM_API_KEY},
      comments   => $lang{COMMENTS},
      number     => $lang{CRM_PHONE_NUMBER},
      action_btn => $lang{ACTION}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{CRM_CONNECTED_NUMBERS},
      qs      => $pages_qs,
      ID      => 'CRM_ECHAT_NUMBERS_LIST',
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1" . ':add',
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#**********************************************************
=head2 _crm_echat_activate_number($number_id) - Activate E-chat webhook for number

  Arguments:
    $number_id - E-chat number ID from database

  Returns:
    Result hash from API request or error object

=cut
#**********************************************************
sub _crm_echat_activate_number {
  my ($number_id) = @_;

  $Echat->crm_echat_numbers_info({ ID => $number_id });

  if (!$Echat->{TOTAL} || $Echat->{TOTAL} < 1) {
    return $Errors->throw_error(1230009);
  }

  return _send_request({
    NUMBER   => $Echat->{NUMBER},
    TOKEN    => $Echat->{TOKEN},
    SOURCE   => $Echat->{TYPE},
    ACTIVATE => 1
  });
}

#**********************************************************
=head2 _crm_echat_deactivate_number($number_id) - Deactivate E-chat webhook for number

  Arguments:
    $number_id - E-chat number ID from database

  Returns:
    Result hash from API request or error object

=cut
#**********************************************************
sub _crm_echat_deactivate_number {
  my ($number_id) = @_;

  $Echat->crm_echat_numbers_info({ ID => $number_id });

  if (!$Echat->{TOTAL} || $Echat->{TOTAL} < 1) {
    return $Errors->throw_error(1230009);
  }

  if ($Echat->{STATUS}) {
    return $Errors->throw_error(1230011);
  }

  return _send_request({
    NUMBER   => $Echat->{NUMBER},
    TOKEN    => $Echat->{TOKEN},
    SOURCE   => $Echat->{TYPE}
  });
}

#**********************************************************
=head2 _send_request($attr) - Send webhook request to E-chat API

  Arguments:
    $attr - Hash reference with parameters:
      SOURCE   - Messenger type (telegram, viber, whatsapp) (required)
      NUMBER   - Phone number for webhook (required)
      TOKEN    - API token for authentication (required)
      ACTIVATE - 1 to enable webhook, 0 to disable (optional)
      TIMEOUT  - Request timeout in seconds (optional, default: 30)

  Returns:
    Hash reference:
      On success: decoded API response
      On error: { errno => code, errstr => description }

=cut
#**********************************************************
sub _send_request {
  my ($attr) = @_;

  if (!$attr->{SOURCE}) {
    return $Errors->throw_error(1230013, { lang_vars => { FIELD => 'SOURCE' } });
  }

  if (!$attr->{NUMBER}) {
    return $Errors->throw_error(1230013, { lang_vars => { FIELD => 'NUMBER' } });
  }

  if (!$attr->{TOKEN}) {
    return $Errors->throw_error(1230013, { lang_vars => { FIELD => 'TOKEN' } });
  }

  my $messenger_config = ECHAT_MESSENGERS->{lc $attr->{SOURCE}};

  if (!$messenger_config || !$messenger_config->{base_url}) {
    return $Errors->throw_error(1230014, { lang_vars => { TYPE => $attr->{SOURCE} } });
  }

  my $endpoint = $attr->{ACTIVATE}
    ? $messenger_config->{endpoints}{enable_webhook}
    : $messenger_config->{endpoints}{disable_webhook};

  my $request_url = $messenger_config->{base_url} . $endpoint;
  my $api_key_header = $messenger_config->{headers}{api_key};

  my @headers = (
    'accept: application/json',
    "$api_key_header: $attr->{TOKEN}",
    'Content-Type: application/json'
  );

  my $params = {
    HEADERS      => \@headers,
    CURL         => 1,
    TIMEOUT      => $attr->{TIMEOUT} || 30,
    JSON_BODY    => {
      number => $attr->{NUMBER}
    },
    CURL_OPTIONS => '-X POST',
    DEBUG        => $attr->{DEBUG} || 0
  };

  my $result = web_request($request_url, $params);

  if ($result =~ /Timeout/xi) {
    return $Errors->throw_error(1230015);
  }

  if (!$result || $result !~ /^\s*[\{\[]/x) {
    return $Errors->throw_error(1230017);
  }

  my $perl_scalar;
  eval {
    $perl_scalar = decode_json($result);
  };

  if ($@) {
    my $error = $@;
    $error =~ s/ at .* line \d+.*$//;
    return $Errors->throw_error(1230016, { lang_vars => { ERROR => $error } });
  }

  if (ref($perl_scalar) ne 'HASH') {
    return $Errors->throw_error(1230017);
  }

  if (!$perl_scalar->{status} || lc($perl_scalar->{status}) eq 'error') {
    if ($perl_scalar->{description} && $perl_scalar->{description} eq 'Integration already exists') {
      return {};
    }

    return {
      errno  => 1230012,
      errstr => $perl_scalar->{description} || 'Unknown API error',
      raw    => $result
    };
  }

  return $perl_scalar;
}

1;