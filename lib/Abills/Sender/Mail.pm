package Abills::Sender::Mail;
use strict;
use warnings FATAL => 'all';

use Abills::Sender::Plugin;
use parent 'Abills::Sender::Plugin';

use Abills::Base qw(sendmail _bp);

=head1 NAME

  Send E-mail message

=cut


#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Email addess
    MAIL_TPL

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  my $sender = $attr->{SENDER} || $self->{conf}->{ADMIN_MAIL} || 'abills_admin';

  if($attr->{MAIL_TPL}) {
    $attr->{MESSAGE}=$attr->{MAIL_TPL};
  }

  my $sent = sendmail(
    $sender,
    $attr->{TO_ADDRESS},
    $attr->{SUBJECT},
    $attr->{MESSAGE},
    $self->{conf}->{MAIL_CHARSET} || 'utf-8',
    undef
  );

  print "Sending E-mail\n Subject: $attr->{SUBJECT}\n $attr->{MESSAGE}\n" if($self->{debug});

  return $sent;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
