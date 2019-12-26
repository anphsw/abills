package Abills::Sender::Sms;
=head1 NAME

  Send Sms message

=cut


use strict;
use warnings FATAL => 'all';

use Abills::Sender::Plugin;
use parent 'Abills::Sender::Plugin';


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

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  unless ($attr->{TO_ADDRESS}){
    print "No recipient address given \n" if ($self->{debug});
    return 0;
  };
  
  my $sms_pattern = $self->{conf}->{SMS_NUMBER} || "[0-9]{12}";
  if ($attr->{TO_ADDRESS} !~ /$sms_pattern/) {
    return 0;
  }

  use Sms::Init;
  my $Sms_service = init_sms_service($self->{db}, $self->{admin}, $self->{conf});
  my $sms_result = $Sms_service->send_sms({
    NUMBER     => $attr->{TO_ADDRESS},
    MESSAGE    => $attr->{MESSAGE}
  });

  return 1;
}

#**********************************************************
=head2 contact_types() -

=cut
#**********************************************************
sub contact_types {
  my $self = shift;

  return $self->{conf}->{SMS_CONTACT_ID} || 1;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
