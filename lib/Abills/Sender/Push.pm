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

  return 1 unless ($conf->{PUSH_ENABLED} || $conf->{FIREBASE_SERVER_KEY});

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

  my %req_params = (
    to       => $attr->{CONTACT}->{value},
    data     => {
      body  => $attr->{MESSAGE},
      title => $attr->{TITLE} || $attr->{SUBJECT} || '',
    },
    priority => 'high'
  );

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

  my $result = web_request('https://fcm.googleapis.com/fcm/send', {
    HEADERS     => [ "Content-Type: application/json", "Authorization: key=$self->{conf}->{FIREBASE_SERVER_KEY}" ],
    JSON_BODY   => \%req_params,
    JSON_RETURN => 1,
    METHOD      => 'POST',
    JSON_FORMER => {
      CONTROL_CHARACTERS => 1
    }
  });

  my $receiver_type = ($attr->{AID})
    ? 'AID'
    : (($attr->{UID}) ? 'UID' : 0);
  my $contacts = $self->{Contacts}->push_contacts_list({
    AID       => ($receiver_type eq 'AID') ? $attr->{AID} : '_SHOW',
    UID       => ($receiver_type eq 'UID') ? $attr->{UID} : '_SHOW',
    TYPE_ID   => '_SHOW',
    PAGE_ROWS => 1
  });

  $self->{Contacts}->push_messages_add({
    AID        => ($receiver_type eq 'AID') ? $attr->{AID} : 0,
    UID        => ($receiver_type eq 'UID') ? $attr->{UID} : 0,
    TYPE_ID    => $contacts->[0]->{type_id},
    TITLE      => $attr->{TITLE} || $attr->{SUBJECT} || '',
    MESSAGE    => $attr->{MESSAGE},
    RESPONSE   => json_former($result),
    REQUEST    => json_former(\%req_params),
    STATUS     => $result->{success} ? 0 : 1
  });

  ($result->{success}) ? return 0 : return 1;
}

1;
