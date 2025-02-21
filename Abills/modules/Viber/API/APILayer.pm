package Viber::API::APILayer;

=head NAME

  Viber <-> ABillS User API layer

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
  my ($db, $admin, $conf, $bot) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    bot   => $bot
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

  return {} if !$self->{bot} || !$self->{bot}{receiver};

  $ENV{HTTP_USERBOT} = 'VIBER';
  $ENV{HTTP_USERID} = $self->{bot}{receiver};
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
