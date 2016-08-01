package Abills::Sender::Browser;
use strict;
use warnings FATAL => 'all';

use AnyEvent::Socket;
use AnyEvent::Handle;
use Abills::Misc;

use Abills::Base qw/_bp in_array/;

use JSON qw//;

my $PING_REQUEST = '{"TYPE":"PING"}';
my $PING_RESPONCE = '{"TYPE":"PONG"}';

my $json = JSON->new->utf8;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($CONF) = @_;

  my $connection_host = $CONF->{WEBSOCKET_HOST} || '127.0.0.1:19444';

  my ($host, $port) = split( ':', $connection_host );
  my $self = {
    conf            => $CONF,
    connection_host => $connection_host,
    host            => $host,
    port            => $port,
  };

  # Because of sync calls need to wait for connection
  my $connection_wait = AnyEvent->condvar;
  tcp_connect $host, $port, sub {
      my ($fh) = @_;
      $connection_wait->send( AnyEvent::Handle->new( fh => $fh, no_delay => 1 ) );
    };

  #Wait until got connection
  $self->{fh} = $connection_wait->recv;

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 is_connected() - check if connected to internal WebSocket server

=cut
#**********************************************************
sub is_connected {
  my ($self) = @_;

  my $responce = $self->_synchronous_request( { MESSAGE => $PING_REQUEST } );

  return 0 unless ($responce);
  return $responce =~ /$PING_RESPONCE/;
}

#**********************************************************
=head2 send_message($attr)

  Arguments:
    $attr -
      UID|AID - receiver ( TODO: '*' to send to all of this type)
      MESSAGE - text of message

  Returns:
    1 if sended;

=cut
#**********************************************************
sub send_message {
  my ($self, $attr) = @_;

  my $receiver_type = (exists $attr->{AID}) ? 'ADMIN' : 'CLIENT';
  my $receiver_id = $attr->{AID} || $attr->{UID};

  # Has no one to send message to
  return undef unless ($receiver_id);

  if (ref $attr->{MESSAGE} eq 'HASH'){
    $attr->{MESSAGE} = $json->encode($attr->{MESSAGE});
  }

  my %payload = (
    TYPE => 'MESSAGE',
    TO   => $receiver_type,
    ID   => $receiver_id,
    DATA => $attr->{MESSAGE}
  );

  my $sended = $self->_synchronous_request( {
      MESSAGE => $json->encode( \%payload )
    } );

  return defined $sended;
}

#**********************************************************
=head2 connected_admins()

  Returns:
    list - aids of connected admins

=cut
#**********************************************************
sub connected_admins {
  my $self = shift;

  my %request = (
    TYPE      => 'REQUEST_LIST',
    LIST_TYPE => 'ADMINS',
  );

  my $responce = $self->json_request( { MESSAGE => $json->encode( \%request ) } );

  #TODO: check for errors
  my $connected = $responce->{LIST};

  return $connected;
}

#**********************************************************
=head2 has_connected_admin($aid) - check if certain admin is present in connected sockets

  Arguments:
    $aid - admin ID

  Returns:
    boolean - if connected

=cut
#**********************************************************
sub has_connected_admin {
  my $self = shift;
  my ( $aid ) = @_;

  my $admins = $self->connected_admins();

  return in_array( $aid, $admins );
}

#**********************************************************
=head2 call($aid, $message) - send message and receive responce

  Arguments:
    $aid     - Admin ID
    $message - json
      DATA

  Returns:
    hash - responce

=cut
#**********************************************************
sub call {
  my $self = shift;
  my ($aid, $message) = @_;

  my %payload = (
    TYPE => 'MESSAGE',
    TO   => 'ADMIN',
    ID   => $aid,
    DATA => $message,
  );

  my $result = $self->json_request( {
      MESSAGE => $json->encode( \%payload )
    } );

  return $result;
}

#**********************************************************
=head2 json_request($attr) - simple alias to get perl structure as result

  Arguments:
    $attr - hash_ref
      MESSAGE - JSON string

  Returns:
    hash_ref - result
    undef on timeout

=cut
#**********************************************************
sub json_request {
  my $self = shift;
  my ($attr) = @_;

  my $responce = $self->_synchronous_request( $attr );

  return $json->decode( $responce );
}

#**********************************************************
=head2 _synchronous_request()

  Arguments:
    MESSAGE - text will be send to backend server

  Returns:
    string - if server responded with message
    ''     - if server accepted message, but not responded nothing
    undef  - if timeout

=cut
#**********************************************************
sub _synchronous_request {
  my ($self, $attr) = @_;

  my $result = '';

  my $operation_end_waiter = AnyEvent->condvar;

  # Set timeout to 5 seconds
  my $timeout_waiter = AnyEvent->timer(
    after => 5,
    cb    => sub {
      _bp("Abills::Sender::Browser", "$self->{host} Timeout" , { TO_WEB_CONSOLE => 1});
      $operation_end_waiter->send(undef);
    }
  );

  my $handle = $self->{fh};
  my $message = $attr->{MESSAGE};

  # Setup recieve callback
  $handle->on_read(
    sub {
      my ($responce_handle) = shift;

      my $readed = $responce_handle->{rbuf};
      $responce_handle->{rbuf} = undef;

      $operation_end_waiter->send( $readed );
    }
  );

  $handle->push_write( $message );

  $result = $operation_end_waiter->recv;
  return $result;
};

1;