package Abills::Sender::Mail;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Send E-mail message

=cut

#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr - hash_ref
      UID     - user ID
      MESSAGE - string. CANNOT CONTAIN DOUBLE QUOTES \"

  Returns:
    1 if success, 0 otherwise

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;


  return $self;
}

1;
