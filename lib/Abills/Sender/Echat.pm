package Abills::Sender::Echat;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Abills::Sender::Echat

=head2 SYNOPSIS

  E-chat sender plugin

=cut

use Abills::Base qw(in_array load_pmodule json_former);
use Abills::Fetcher qw/web_request/;
use Crm::db::Echat;

our $VERSION = 0.01;

# use constant {
#   ERR_MISSING_PARAMS    => 1,
#   ERR_INVALID_RESPONSE  => 10,
#   ERR_JSON_DECODE       => 11,
#   ERR_TIMEOUT           => 50,
#   ERR_API_ERROR         => 100,
# };

#**********************************************************
=head2 new($conf, $attr) - Create new Echat sender instance

  Arguments:
    $conf   - Hash reference with configuration
    $attr   - Hash reference with attributes
       db      - Database object (required)
       admin   - Admin object (required)

  Returns:
    Blessed object instance

  Example:

    my $echat_sender = Abills::Sender::Echat->new(\%conf, {
      db    => $db,
      admin => $admin
    });

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  my $self = {
    conf       => $conf,
    db         => $attr->{db} || {},
    admin      => $attr->{admin} || {},
    messengers => {
      telegram => {
        base_url  => 'https://telegram.e-chat.tech/api',
        endpoints => {
          send_message => '/SendMessage.php',
        },
        headers   => {
          api_key => 'API'
        }
      },
      viber => {
        base_url  => 'https://e-chat.tech/api/viber/v2',
        endpoints => {
          send_message => '/messages/send',
        },
        headers   => {
          api_key => 'Api-Key'
        }
      },
      whatsapp => {
        base_url  => 'https://e-chat.tech/api/whatsapp/v1',
        endpoints => {
          send_message => '/messages/send',
        },
        headers   => {
          api_key => 'Api-Key'
        }
      }
    }
  };

  bless($self, $class);

  $self->{Echat} = Echat->new(@{$self}{qw/db admin conf/});

  load_pmodule('JSON');

  $self->{json} = JSON->new->allow_nonref;

  return $self;
}

#**********************************************************
=head2 send_message($attr) - Send message via E-chat messenger

  Arguments:
    $attr   - Hash reference with message attributes
       RECIPIENT   - E-chat number to send from (required)
       TO_ADDRESS  - Contact ID to send message to (required)
       MESSAGE     - Message text content (required)
       TIMEOUT     - Request timeout in seconds (optional, default: 30)

  Returns:
    Hash reference with result:
      On success: API response from E-chat
      On error:
        errno  - Error code (ERR_MISSING_PARAMS, ERR_TIMEOUT, ERR_API_ERROR, etc)
        errstr - Error description

  Example:

    my $result = $echat_sender->send_message({
      RECIPIENT  => '+380123456789',
      TO_ADDRESS => 42,
      MESSAGE    => 'Hello, how can we help you?'
    });

    if ($result->{errno}) {
      print "Error: $result->{errstr}\n";
    }
    else {
      print "Message sent successfully\n";
    }

=cut
#**********************************************************
sub send_message {
  my ($self, $attr) = @_;

  if (!$attr->{RECIPIENT} || !$attr->{TO_ADDRESS}) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'Missing required parameters: RECIPIENT or TO_ADDRESS' };
  }

  my $Echat = $self->{Echat};

  $Echat->crm_echat_contacts_info({ ID => $attr->{TO_ADDRESS} });

  if ($Echat->{errno}) {
    return {
      errno  => $Echat->{errno},
      errstr => $Echat->{errstr}
    }
  }

  my $source = $Echat->{TYPE};
  my $external_id = $Echat->{EXTERNAL_ID};
  if (!$Echat->{TOTAL} || $Echat->{TOTAL} < 1 || !$external_id || !$source) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'Contact not found or missing TYPE/EXTERNAL_ID' };
  }

  my $numbers = $Echat->crm_echat_numbers_list({ NUMBER => $attr->{RECIPIENT}, TYPE => $source, TOKEN => '_SHOW', STATUS => '0', COLS_UPPER => 1 });

  if ($Echat->{errno}) {
    return {
      errno  => $Echat->{errno},
      errstr => $Echat->{errstr}
    }
  }

  if (!$Echat->{TOTAL} || $Echat->{TOTAL} < 1) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'No active E-chat number found for recipient' };
  }

  my $number_info = $numbers->[0];

  my $result = $self->_send_request({
    %{$attr},
    TOKEN       => $number_info->{TOKEN},
    NUMBER      => $number_info->{NUMBER},
    SOURCE      => $source,
    EXTERNAL_ID => $external_id
  });

  return $result;
}

#**********************************************************
=head2 _send_request($attr) - Send API request to E-chat (internal method)

  Arguments:
    $attr   - Hash reference with request parameters
       SOURCE      - Messenger type (telegram, viber, whatsapp) (required)
       TOKEN       - API token for authentication (required)
       MESSAGE     - Message text content (required)
       EXTERNAL_ID - External messenger identifier (required)
       TIMEOUT     - Request timeout in seconds (optional, default: 30)

  Returns:
    Hash reference with result:
      On success: Decoded JSON response from E-chat API
      On error:
        errno  - Error code
        errstr - Error description

  Example:

    my $result = $self->_send_request({
      SOURCE      => 'telegram',
      TOKEN       => 'abc123',
      MESSAGE     => 'Test message',
      EXTERNAL_ID => '123456789',
      TIMEOUT     => 30
    });

=cut
#**********************************************************
sub _send_request {
  my ($self, $attr) = @_;

  my $messenger_config = $self->{messengers}{$attr->{SOURCE}};

  if (!$messenger_config || !$messenger_config->{base_url}) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'URL is not configured for messenger type' };
  }

  if (!$attr->{TOKEN}) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'Missing API token for E-chat number' };
  }

  if (!$attr->{MESSAGE} || $attr->{MESSAGE} =~ /^\s*$/) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'Message content is empty or whitespace only' };
  }

  if (!$attr->{EXTERNAL_ID}) {
    return 0;
    # return { errno => ERR_MISSING_PARAMS, errstr => 'Missing EXTERNAL_ID for recipient' };
  }

  my $request_url = $messenger_config->{base_url} . $messenger_config->{endpoints}{send_message};
  my $api_key = $messenger_config->{headers}{api_key};

  my @headers = (
    "accept: application/json",
    "$api_key: $attr->{TOKEN}",
    'Content-Type: application/json'
  );

  my $params = {
    HEADERS      => \@headers,
    CURL         => 1,
    TIMEOUT      => $attr->{TIMEOUT} || 30,
    JSON_BODY    => {
      number   => "<str_>$attr->{NUMBER}",
      user => {
        number   => "<str_>$attr->{NUMBER}",
      },
      message  => {
        id   => "<str_>$attr->{EXTERNAL_ID}",
        text => $attr->{MESSAGE}
      },
      receiver => {
        id => "<str_>$attr->{EXTERNAL_ID}"
      },
      contact => {
        number => "<str_>$attr->{EXTERNAL_ID}"
      }
    },
    CURL_OPTIONS => '-X POST'
  };

  my $result = web_request($request_url, $params);

  if ($result =~ /Timeout/xi) {
    return 0;
    # $self->{errno} = ERR_TIMEOUT;
    # $self->{errstr} = 'Request timeout';
    # return { errno => ERR_TIMEOUT, errstr => 'Request timeout' };
  }

  my $perl_scalar;

  if ($result && $result =~ /^\s*[\{\[]/x) {
    eval {
      $perl_scalar = $self->{json}->decode($result);
    };

    if ($@) {
      return 0;
      # return { errno => ERR_JSON_DECODE, errstr => "JSON decode error: $@", raw => $result };
    }

    if (ref($perl_scalar) eq 'HASH') {
      if (!$perl_scalar->{status} || $perl_scalar->{status} eq 'Error' || $perl_scalar->{status} eq 'ERROR') {
        # $perl_scalar->{errno} = ERR_API_ERROR;
        # $perl_scalar->{errstr} = $perl_scalar->{description} || 'Unknown API error';
        return 0;
      }
    }
  }
  else {
    return 0;
    # return { errno => ERR_INVALID_RESPONSE, errstr => 'Invalid response format', raw => $result };
  }

  return $perl_scalar;
}

1;
