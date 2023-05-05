package Abills::Sender::Push;
=head1 NAME

  Send Push message

=cut

use strict;
use warnings;

#TODO: migrate to HTTP1 when will be algorithm of OAUTH2 google algorithm for admin console

use parent 'Abills::Sender::Plugin';

use Contacts;
use Abills::Fetcher qw(web_request);
use Abills::Base qw(json_former);

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

  die 'No Firebase server key ($conf{FIREBASE_SERVER_KEY})' if (!$conf->{FIREBASE_SERVER_KEY});

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
=head2 send_message($attr)

  Arguments:
    $attr - hash_ref
      UID        - user ID
      MESSAGE    - string. CANNOT CONTAIN DOUBLE QUOTES \"
      TO_ADDRESS - Push endpoint

  Returns:
    1 if success, 0 otherwise

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $receiver_type = ($attr->{AID})
    ? 'AID'
    : (($attr->{UID}) ? 'UID' : 0);

  my $title = $attr->{TITLE} || $attr->{SUBJECT} || '';
  my $action = $title =~ /(?<=#)\d+/g;

  my %req_params = (
    to       => $attr->{CONTACT}->{value},
    data     => {
      body   => $attr->{MESSAGE},
      title  => $title,
      action => $action ? 'message' : 'default',
      %{$attr->{EX_PARAMS} || {}},
    },
    priority => 'high',
  );

  # ios block
  if ($attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} && $attr->{CONTACT}->{push_type_id} == 3) {
    my $badges = $attr->{CONTACT}->{badges} + 1;

    $self->{Contacts}->push_contacts_change({
      ID     => $attr->{CONTACT}->{id} || '--',
      BADGES => $badges
    });

    $req_params{notification} = {
      body         => $attr->{MESSAGE},
      title        => $title,
      badge        => $badges,
      click_action => $action ? 'message' : 'default'
    };

    $req_params{content_available} = 'true';
  }

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';
  my @attachments = ();

  foreach my $file (@{$attr->{ATTACHMENTS}}) {
    my $content = $file->{content} || '';
    next if $content !~ /FILE/ || $content !~ /Abills\/templates/;
    my ($file_path) = $content =~ /Abills\/templates(\/.+)/;

    push @attachments, {
      url          => $SELF_URL . $file_path,
      size         => $file->{content_size},
      name         => $file->{filename},
      content_type => $file->{content_type}
    };
  }

  $req_params{attachments} = \@attachments;

  my $firebase_key = $self->{conf}->{FIREBASE_SERVER_KEY} || '';

  my $result = web_request('https://fcm.googleapis.com/fcm/send', {
    HEADERS     => [ "Content-Type: application/json", "Authorization: key=$firebase_key" ],
    JSON_BODY   => \%req_params,
    JSON_RETURN => 1,
    METHOD      => 'POST',
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1,
      BOOL_VALUES        => 1,
    }
  });

  $self->{Contacts}->push_messages_add({
    AID      => ($receiver_type eq 'AID') ? $attr->{AID} : 0,
    UID      => ($receiver_type eq 'UID') ? $attr->{UID} : 0,
    TYPE_ID  => $attr->{CONTACT} && $attr->{CONTACT}->{push_type_id} ? $attr->{CONTACT}->{push_type_id} : 0,
    TITLE    => $title || '',
    MESSAGE  => $attr->{MESSAGE},
    RESPONSE => json_former($result),
    REQUEST  => json_former(\%req_params),
    STATUS   => $result->{success} ? 0 : 1
  });

  ($result->{success}) ? return 0 : return 1;
}

1;
