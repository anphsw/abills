#!/usr/bin/perl

=head1 NAME

  E-chat callback cgi

=cut

use strict;
use warnings;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  @MODULES,
  %FORM,
  %COOKIES
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../Abills',
    $Bin . '/../Abills/mysql',
    $Bin . '/../Abills/modules',
  );

  foreach my $module (@MODULES) {
    unshift(@INC, $Bin . "/../Abills/modules/$module/config");
  }
}

use Abills::Base qw/_bp in_array/;
use Abills::SQL;
use Admins;
use Abills::Misc;
use Abills::Api::Handle;
use Conf;
use Abills::HTML;
use Crm::db::Echat;
use JSON qw(decode_json);

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

our $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} || 3, {
  IP    => $ENV{REMOTE_ADDR},
  SHORT => 1
});

our $Conf = Conf->new($db, $admin, \%conf);

my $Echat = Echat->new($db, $admin, \%conf);

my $message = ();
my $fn_data = "";

print "Content-Type: text/html\n\n";
my $buffer = '';
read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
`echo '$buffer' >> /tmp/telegram.log`;
my $websocket_data = decode_json($buffer);

message_process();

sub message_process {

  if (!$websocket_data || !$websocket_data->{direction} || $websocket_data->{direction} ne 'incoming') {
    return;
  }

  if (!$websocket_data->{message}) {
    return;
  }

  my $user_info = {
    MESSAGE    => $websocket_data->{message} && $websocket_data->{message}{text} ? $websocket_data->{message}{text} : '',
    MESSAGE_ID => $websocket_data->{message} ? ($websocket_data->{message}{id} || $websocket_data->{message}{message_id}) : '',
  };

  if ($websocket_data->{sender} && $websocket_data->{sender}{id}) {
    $user_info->{EXTERNAL_ID} = $websocket_data->{sender}{id};
    $user_info->{FIO} = $websocket_data->{sender}{name} || $websocket_data->{sender}{username};
    $user_info->{AVATAR} = $websocket_data->{sender}{photo};
    $user_info->{PHONE} = $websocket_data->{sender}{phone};
    $user_info->{TYPE} = 'telegram';
  }
  elsif ($websocket_data->{contact}) {
    $user_info->{EXTERNAL_ID} = $websocket_data->{contact}{number};
    $user_info->{FIO} = $websocket_data->{contact}{name};
    $user_info->{AVATAR} = $websocket_data->{contact}{photo};
    $user_info->{PHONE} = $websocket_data->{contact}{number};
    $user_info->{TYPE} = $websocket_data->{messenger};
  }

  my $echat_contact = get_echat_contact($user_info);
  if (!$echat_contact->{id}) {
    return;
  }

  $ENV{HTTP_USERBOT} = 'ECHAT';
  $ENV{HTTP_USERID} = $echat_contact->{id};
  use Abills::Api::Handle;
  my $handle = Abills::Api::Handle->new($db, $admin, \%conf, {
    lang   => \%lang,
    direct => 1
  });

  my ($result, $status) = $handle->api_call({
    METHOD => 'POST',
    PATH   => '/crm/leads/social',
    PARAMS => {
      FIO       => $user_info->{FIO},
      AVATAR    => $user_info->{AVATAR},
      PHONE     => $user_info->{PHONE},
      RECIPIENT => $websocket_data->{number}
    }
  });

  if (!$result->{NEW_DIALOGUE_ID}) {
    return;
  }

  $user_info->{EXTERNAL_ID} = $user_info->{MESSAGE_ID};
  ($result, $status) = $handle->api_call({
    METHOD => 'POST',
    PATH   => '/crm/leads/dialogue/message',
    PARAMS => $user_info
  });
}

#**********************************************************
=head2 get_echat_contact($attr) - Get receiver by external_id and type or create new one

  Arguments:
    $attr   - Hash reference with receiver attributes
       EXTERNAL_ID      - External messenger identifier (required)
       TYPE             - Messenger type (telegram, viber, etc) (required)
       LEAD_ID          - Lead ID to associate (optional, default: 0)
       ECHAT_NUMBER_ID  - Echat number ID to associate (optional, default: 0)

  Returns:
    Hash reference with receiver data or 0 on error

  Example:

    my $receiver = get_echat_contact({
      EXTERNAL_ID     => '123456789',
      TYPE            => 'telegram',
      LEAD_ID         => 15,
      ECHAT_NUMBER_ID => 5
    });

=cut
#**********************************************************
sub get_echat_contact {
  my ($attr) = @_;

  if (!$attr->{EXTERNAL_ID} || !$attr->{TYPE}) {
    return {};
  }

  my $receiver = _find_contact_by_external_id({
    EXTERNAL_ID => $attr->{EXTERNAL_ID},
    TYPE        => $attr->{TYPE}
  });

  if ($receiver && $receiver->{id}) {
    return $receiver;
  }

  my $new_receiver = _create_echat_contact({
    EXTERNAL_ID     => $attr->{EXTERNAL_ID},
    TYPE            => $attr->{TYPE},
    LEAD_ID         => $attr->{LEAD_ID} || 0,
    ECHAT_NUMBER_ID => $attr->{ECHAT_NUMBER_ID} || 0
  });

  return $new_receiver;
}

#**********************************************************
=head2 _find_contact_by_external_id($attr) - Find receiver by external_id and type

  Arguments:
    $attr   - Hash reference with search criteria
       EXTERNAL_ID  - External messenger identifier (required)
       TYPE         - Messenger type (required)

  Returns:
    Hash reference with receiver data or 0 if not found

  Example:

    my $receiver = _find_contact_by_external_id({
      EXTERNAL_ID => '123456789',
      TYPE        => 'telegram'
    });

=cut
#**********************************************************
sub _find_contact_by_external_id {
  my ($attr) = @_;

  if (!$attr->{EXTERNAL_ID} || !$attr->{TYPE}) {
    return {};
  }

  my $list = $Echat->crm_echat_contacts_list({
    EXTERNAL_ID => $attr->{EXTERNAL_ID},
    TYPE        => $attr->{TYPE},
    COLS_NAME   => 1,
    PAGE_ROWS   => 1
  });

  if ($Echat->{errno}) {
    return $Echat;
  }

  if ($list && ref $list eq 'ARRAY' && scalar @{$list} > 0) {
    return $list->[0];
  }

  return 0;
}

#**********************************************************
=head2 _create_echat_contact($attr) - Create new receiver

  Arguments:
    $attr   - Hash reference with receiver data
       EXTERNAL_ID      - External messenger identifier (required)
       TYPE             - Messenger type (required)
       LEAD_ID          - Lead ID (default: 0)
       ECHAT_NUMBER_ID  - Echat number ID (default: 0)

  Returns:
    Hash reference with created receiver data or 0 on error

  Example:

    my $receiver = _create_echat_contact({
      EXTERNAL_ID     => '123456789',
      TYPE            => 'telegram',
      LEAD_ID         => 15,
      ECHAT_NUMBER_ID => 5
    });

=cut
#**********************************************************
sub _create_echat_contact {
  my ($attr) = @_;

  if (!$attr->{EXTERNAL_ID} || !$attr->{TYPE}) {
    return {
      errno  => 1,
      errstr => 'EXTERNAL_ID and TYPE are required'
    };
  }

  $Echat->crm_echat_contacts_add({
    EXTERNAL_ID     => $attr->{EXTERNAL_ID},
    TYPE            => $attr->{TYPE},
    LEAD_ID         => $attr->{LEAD_ID} || 0,
    ECHAT_NUMBER_ID => $attr->{ECHAT_NUMBER_ID} || 0
  });

  if ($Echat->{errno}) {
    return $Echat;
  }

  my $insert_id = $Echat->{INSERT_ID};

  if (!$insert_id) {
    return {
      errno  => 2,
      errstr => 'Failed to get INSERT_ID after creating receiver'
    };
  }

  my $receiver = _find_contact_by_external_id({
    EXTERNAL_ID => $attr->{EXTERNAL_ID},
    TYPE        => $attr->{TYPE}
  });

  return $receiver;
}

1;