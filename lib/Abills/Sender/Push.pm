package Abills::Sender::Push;
=head1 NAME

  Send Push message

=cut

use strict;
use warnings;

use parent 'Abills::Sender::Plugin';

use Contacts;
use Abills::Fetcher qw(web_request);
use Abills::Base qw(json_former);

my %status_compare = (
  #TODO: DELETE IT
  # legacy codes, can not find why it was added, because it already deleted https://firebase.google.com/docs/cloud-messaging/http-server-ref
  # MismatchSenderId       => 1000008,
  # MissingRegistration    => 1000008,
  # InvalidRegistration    => 1000008,
  # NotRegistered          => 1000008,
  # InvalidPackageName     => 1000014,
  # InvalidParameters      => 1000014,
  # MessageTooBig          => 1000014,
  # InvalidDataKey         => 1000014,
  #TODO: DELETE IT

  # new error codes https://firebase.google.com/docs/reference/fcm/rest/v1/ErrorCode
  UNAUTHENTICATED        => 1000013,
  INVALID_ARGUMENT       => 1000014,
  PERMISSION_DENIED      => 1000013,
  NOT_FOUND              => 1000008,
  UNREGISTERED           => 1000008,
  UNSPECIFIED_ERROR      => 1000015,
  SENDER_ID_MISMATCH     => 1000008,
  QUOTA_EXCEEDED         => 1000016,
  UNAVAILABLE            => 1000017,
  THIRD_PARTY_AUTH_ERROR => 1000018,
  INTERNAL               => 1000018,
);

#**********************************************************
=head2 new($conf) - constructor for FCM_PUSH

  Attributes:
    $conf

  Returns:
    object - new FCM_PUSH instance

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_;

  return 0 unless ($conf->{PUSH_ENABLED});

  die 'Bad firebase configurations' if (!$conf->{GOOGLE_PROJECT_ID} || !$conf->{FIREBASE_KEY});

  my $self = {
    db    => $attr->{db},
    admin => $attr->{admin},
    conf  => $conf,
  };

  $self->{Contacts} = Contacts->new($self->{db}, $self->{admin}, $conf);

  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 send_message($attr) send message for http1 protocol

  Arguments:
    $attr - hash_ref
      UID        - user ID
      MESSAGE    - string. CANNOT CONTAIN DOUBLE QUOTES \"
      TO_ADDRESS - Push endpoint

  Returns:
    0 if success, 1 otherwise

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $base_dir = $main::base_dir || '/usr/abills';

  require Abills::Google;

  my $Google = Abills::Google->new({
    file_path => "$base_dir/Certs/google/$self->{conf}->{FIREBASE_KEY}.json",
    scope     => [ 'https://www.googleapis.com/auth/firebase.messaging', 'https://www.googleapis.com/auth/cloud-platform' ],
  });

  my $result = $Google->access_token();

  if ($attr->{RETURN_RESULT}) {
    return $result if $result && $result->{errno};
    return { errno => 1000008, errstr => 'ERR_TOKEN_EXPIRED_OR_INVALID' } if $result && !$result->{access_token};
  }

  return $result->{errno} || 1 if ($result->{errno} || !$result->{access_token});

  my $receiver_type = ($attr->{AID})
    ? 'AID'
    : (($attr->{UID}) ? 'UID' : 0);

  my $title = $attr->{TITLE} || $attr->{SUBJECT} || '';
  my $action = $title =~ /(?<=#)\d+/g;

  my %req_params = (
    message => {
      token   => $attr->{CONTACT}->{value},
      data    => {
        body         => $attr->{MESSAGE},
        title        => $title,
        action       => $action ? 'message' : 'default',
        press_action => $action ? 'message' : 'default',
        %{$attr->{EX_PARAMS} || {}},
      },
      android => {
        priority     => 'high',
      }
    },
  );

  # ios block
  if ($attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} && $attr->{CONTACT}->{push_type_id} == 3) {
    my $badges = $attr->{CONTACT}->{badges} + 1;

    $self->{Contacts}->push_contacts_change({
      ID     => $attr->{CONTACT}->{id} || '--',
      BADGES => $badges,
    });

    $req_params{message}{notification} = {
      body  => $attr->{MESSAGE},
      title => $title,
    };

    $req_params{message}{apns} = {
      payload => {
        aps => {
          'mutable-content'   => 1,
          'content-available' => 1,
          badge               => $badges,
          category            => $action ? 'message' : 'default',
        }
      },
      headers => {
        'apns-priority' => '<str_>5',
      }
    };
  }

  # if ($attr->{ATTACHMENTS}) {
  #   my @attachments = ();
  #   my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  #   my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';
  #
  #   foreach my $file (@{$attr->{ATTACHMENTS}}) {
  #     my $content = $file->{content} || '';
  #     next if $content !~ /FILE/ || $content !~ /Abills\/templates/;
  #     my ($file_path) = $content =~ /Abills\/templates(\/.+)/;
  #
  #     push @attachments, {
  #       url          => $SELF_URL . $file_path,
  #       size         => $file->{content_size},
  #       name         => $file->{filename},
  #       content_type => $file->{content_type}
  #     };
  #   }
  #
  #   $req_params{message}{data}{attachments} = \@attachments;
  # }

  my $send_result = web_request("https://fcm.googleapis.com/v1/projects/$self->{conf}->{GOOGLE_PROJECT_ID}/messages:send", {
    HEADERS     => [ "Content-Type: application/json", "Authorization: Bearer $result->{access_token}" ],
    JSON_BODY   => \%req_params,
    JSON_RETURN => 1,
    METHOD      => 'POST',
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1,
    }
  });

  if ($send_result->{error}) {
    if (ref $send_result->{error} eq 'HASH') {
      if ($send_result->{error}{status} && ($send_result->{error}{status} eq 'NOT_FOUND' || $send_result->{error}{status} eq 'UNREGISTERED')) {
        $self->{Contacts}->push_contacts_del({
          ID => $attr->{CONTACT}->{id} || '--',
        });
      }

      $send_result->{errno} = $send_result->{error}{status} ? ($status_compare{$send_result->{error}{status}} || 0) : 0;
      $send_result->{errstr} = $send_result->{error}{message} if $send_result->{error}{message};
    }
    else {
      $send_result->{errno} = $status_compare{$send_result->{error}} || 0;
      $send_result->{errstr} = $send_result->{error};
    }
  }

  $self->{Contacts}->push_messages_add({
    AID        => ($receiver_type eq 'AID') ? $attr->{AID} : 0,
    UID        => ($receiver_type eq 'UID') ? $attr->{UID} : 0,
    TYPE_ID    => $attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} ? $attr->{CONTACT}->{push_type_id} : 0,
    TITLE      => $title || '',
    MESSAGE    => $attr->{MESSAGE},
    RESPONSE   => json_former($send_result),
    REQUEST    => json_former(\%req_params),
    STATUS     => $send_result->{error} ? 1 : 0,
    MESSAGE_ID => $attr->{MESSAGE_ID} || 0
  });

  return $send_result if $attr->{RETURN_RESULT};

  return $send_result->{error} ? 0 : 1;
}

#**********************************************************
=head2 dry_run($attr) dry run for http 1 protocol

  Arguments:
    $attr - hash_ref

  Returns:
    0 if success, 1 otherwise

=cut
#**********************************************************
sub dry_run {
  my $self = shift;
  my ($attr) = @_;

  my $base_dir = $main::base_dir || '/usr/abills';

  require Abills::Google;

  my $Google = Abills::Google->new({
    file_path => "$base_dir/Certs/google/$self->{conf}->{FIREBASE_KEY}.json",
    scope     => [ 'https://www.googleapis.com/auth/firebase.messaging', 'https://www.googleapis.com/auth/cloud-platform' ],
  });

  my $result = $Google->access_token();

  return $result->{errno} || 1 if ($result->{errno} || !$result->{access_token});

  my @registration_ids = ();

  if ($attr->{TOKEN}) {
    push @registration_ids, $attr->{TOKEN};
  }
  elsif ($attr->{TOKENS}) {
    push @registration_ids, @{$attr->{TOKENS}};
  }
  else {
    return 2;
  }

  my $results = {};

  foreach my $token (@registration_ids) {
    my $send_result = web_request("https://fcm.googleapis.com/v1/projects/$self->{conf}->{GOOGLE_PROJECT_ID}/messages:send", {
      HEADERS     => [ "Content-Type: application/json", "Authorization: Bearer $result->{access_token}" ],
      JSON_BODY   => {
        validate_only => 'true',
        message => {
          token   => $token,
        }
      },
      JSON_RETURN => 1,
      METHOD      => 'POST',
      JSON_FORMER => {
        CONTROL_CHARACTERS => 1,
        BOOL_VALUES        => 1,
      }
    });

    if ($send_result->{error}) {
      push @{$results->{results}}, { error => $send_result->{error}->{message} };
    }
    else {
      push @{$results->{results}}, { name => $send_result->{name} };
    }
  }

  return $results if ($attr->{RETURN_RESULT});

  return $results->{results}->[0]->{error} ? 3 : 0;
}

1;
