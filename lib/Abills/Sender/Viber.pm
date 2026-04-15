package Abills::Sender::Viber;
=head1 Viber

  Send viber message

=cut


use strict;
use warnings FATAL => 'all';

use Abills::Sender::Plugin;
use parent 'Abills::Sender::Plugin';
use Sms::Init;
use Sms;

my %conf = ();
my @viber_msgs = (
  'SMS_OMNICELL_VIBER',
  'SMS_TURBOSMS_VIBER'
);

my $Sms_service;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr) - Create new Viber object

  Arguments:
    $attr
      CONF

  Returns:

  Examples:
    my $Viber = Abills::Sender::Viber->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my ($class, $conf, $attr) = @_;

  %conf = %{$conf};

  my $self = {};

  $Sms_service = init_sms_service($attr->{db}, $attr->{admin}, $conf);

  foreach my $viber_check (@viber_msgs) {
    if ($Sms_service->{$viber_check}) {
      $self->{VIBER_TOKEN} = $Sms_service->{$viber_check};
      last;
    }
  }

  die 'Not configured Viber sending' if (!$self->{VIBER_TOKEN});

  bless $self, $class;

  return $self;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Sms address
    UID
    debug

  Returns:
    result_hash_ref

success
  {"response_code":801,"response_status":"SUCCESS_MESSAGE_SENT","response_result":[{"phone":"380932331412","message_id":"ecfacfcb-9624-4372-9339-e5b085876929","response_code":0,"response_status":"OK"}]} //
error

=cut
#**********************************************************
sub send_message {
  my ($self, $attr) = @_;

  if (!$attr->{TO_ADDRESS}) {
    print "No recipient address given\n" if ($self->{debug});
    return 0;
  };

  my $number_pattern = $self->{conf}{SMS_NUMBER} || "[0-9]{12}";
  if ($attr->{TO_ADDRESS} !~ /$number_pattern/mx) {
    return 0;
  }

  my $sms_result = $Sms_service->send_sms({
    NUMBER  => $attr->{TO_ADDRESS},
    MESSAGE => $attr->{MESSAGE},
    VIBER   => $self->{VIBER_TOKEN}
  });

  my $DATE = POSIX::strftime("%Y-%m-%d", localtime(time));
  my $TIME = POSIX::strftime("%H:%M:%S", localtime(time));

  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

  $Sms->add({
    UID         => $attr->{UID} || $self->{UID} || 0,
    MESSAGE     => $attr->{MESSAGE} || q{},
    PHONE       => $attr->{TO_ADDRESS},
    DATETIME    => "$DATE $TIME",
    STATUS      => ($sms_result) ? 0 : 1,
    EXT_ID      => $Sms_service->{id} || '',
    STATUS_DATE => "$DATE $TIME",
    EXT_STATUS  => $Sms_service->{errstr} || $Sms_service->{status} || '',
  });

  return ($Sms_service->{status}) ? 0 : 1;
}

#**********************************************************
=head2 contact_types() -

=cut
#**********************************************************
sub contact_types {
  my $self = shift;

  return $self->{conf}{SMS_CONTACT_ID} || 1;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
