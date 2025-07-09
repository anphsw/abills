package Viber::buttons::Support_chat;

use strict;
use warnings FATAL => 'all';
use JSON qw(decode_json);

use Abills::Fetcher qw(web_request);
use Abills::Base qw(in_array);

my %icons = (
  admin => "\xF0\x9F\x92\xAC"
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

  return $self->{user_config}{crm_user_leads};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{admin} $self->{bot}{lang}{VIBER_OPERATOR_HELP}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my @keyboard = ();

  my $cancel_button = {
    Text => $self->{bot}{lang}{VIBER_RETURN_TO_MAIN_MENU},
    ActionType => 'reply',
    ActionBody => 'fn:Support_chat&cancel',
    TextSize   => 'regular'
  };
  push (@keyboard, $cancel_button);

  my $dialogue_info = $self->_get_dialogue_id();

  $self->{bot}->send_message({
    text         => $self->{bot}{lang}{VIBER_DESCRIBE_YOUR_ISSUE},
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  my $dialogue_id = $dialogue_info->{NEW_DIALOGUE_ID} || '';
  my $lead_id = $dialogue_info->{NEW_LEAD_ID} || '';
  $self->{bot_db}->add({
    SENDER_ID => $self->{bot}->{receiver},
    FN        => "fn:Support_chat&send_message",
    ARGS      => '{"lead_id":"' . $lead_id . '", "dialogue_id":"' . $dialogue_id  . '"}',
  });

  return 1;
}

#**********************************************************
=head2 send_message($attr)

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{message} || (!$attr->{message}{text} && !$attr->{message}{media})) {
    return 0;
  }

  my @keyboard = ();

  my $cancel_button = {
    Text => $self->{bot}{lang}{VIBER_RETURN_TO_MAIN_MENU},
    ActionType => 'reply',
    ActionBody => 'fn:Support_chat&cancel',
    TextSize   => 'regular'
  };
  push (@keyboard, $cancel_button);

  my $params = {
    MESSAGE => $attr->{message}{text}
  };

  if ($attr->{message}{media}) {
    my $file_id = $attr->{message}{media}.'|'.$attr->{message}{file_name}.'|'.$attr->{message}{size};
    my ($file, $file_size, $file_content) = $self->get_file($file_id);
    my ($file_extension) = $file =~ /\.([^.]+)$/;

    $params->{ATTACHMENTS} = [{
      FILE_NAME    => $attr->{message}{file_name},
      CONTENT_TYPE => file_content_type($file_extension),
      SIZE         => $file_size,
      CONTENTS     => $file_content
    }];
  }

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/dialogue/message/',
    PARAMS => $params
  });

  $self->{bot}->send_message({
    text         => $res->{id} ? $self->{bot}{lang}{VIBER_MESSAGE_SENT} : $self->{bot}{lang}{VIBER_MESSAGE_SEND_ERROR},
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  return 1;
}

#**********************************************************
=head2 get_file($file_id)

=cut
#**********************************************************
sub get_file {
  my $self = shift;
  my ($file_id) = @_;

  my ($file_path, $file_name, $file_size) = $file_id =~ /(.*)\|(.*)\|(.*)/;
  my $file_content = web_request($file_path, {
    CURL         => 1,
    CURL_OPTIONS => '-s',
  });

  return ($file_name, $file_size, $file_content);
}

#**********************************************************
=head2 cancel()

=cut
#**********************************************************
sub cancel {
  my $self = shift;

  $self->{bot_db}->del($self->{bot}{receiver});

  return 0;
}

#**********************************************************
=head2 _get_dialogue_id()

=cut
#**********************************************************
sub _get_dialogue_id {
  my $self = shift;

  my ($user_pi) = $self->{api}->fetch_api({ PATH => '/user/pi' });
  $user_pi->{PHONE} = $user_pi->{PHONE}[0];
  $user_pi->{EMAIL} = $user_pi->{EMAIL}[0];
  $user_pi->{BUILD_ID} = $user_pi->{LOCATION_ID};

  my ($res) = $self->{api}->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/social',
    PARAMS => $user_pi
  });

  return $res;
}

#**********************************************************
=head2 file_content_type()

=cut
#**********************************************************
sub file_content_type {
  my ($file_extension) = @_;

  my @IMAGES_FILE_EXTENSIONS = ('png', 'jpg', 'gif', 'jpeg', 'tiff');

  my $file_content_type = "application/octet-stream";

  if (in_array($file_extension, \@IMAGES_FILE_EXTENSIONS)) {
    $file_content_type = "image/$file_extension";
  }
  elsif ( $file_extension && $file_extension eq "zip" ) {
    $file_content_type = "application/x-zip-compressed";
  }

  return $file_content_type;
}

1;
