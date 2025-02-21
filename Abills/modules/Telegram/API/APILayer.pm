package Telegram::API::APILayer;

=head NAME

  Telegram <-> ABillS User API layer

=head DOCUMENTATION

  ABillS User API
  http://abills.net.ua/wiki/display/AB/USER+RESTful+JSON+API

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Api::Handle;

#**********************************************************
=head2 new($attr)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot, $attr) = @_;

  my $self = {
    db         => $db,
    admin      => $admin,
    conf       => $conf,
    bot        => $bot,
    for_admins => $attr->{for_admins}
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 fetch_api($attr)

=cut
#**********************************************************
sub fetch_api {
  my $self = shift;
  my ($attr) = @_;

  return {} if !$self->{bot} || !$self->{bot}{chat_id};

  $ENV{HTTP_USERBOT} = 'TELEGRAM';
  if ($self->{for_admins}) {
    $ENV{HTTP_ADMINID} = $self->{bot}{chat_id};
  }
  else {
    $ENV{HTTP_USERID} = $self->{bot}{chat_id};
  }
  my $handle = Abills::Api::Handle->new(
    $self->{db},
    $self->{admin},
    $self->{conf},
    {
      lang => $self->{bot}{lang},
      html => $self->{bot}{html},
      direct => 1
    }
  );

  return $handle->api_call($attr);
}

1;
