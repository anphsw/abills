package Api::Controllers::Admin::Bots;
use strict;
use warnings FATAL => 'all';

use Abills::Base qw(mk_unique_value);

use Control::Errors;

my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 bots_subscribe_link_bot($path_params, $query_params)

  Endpoint GET /bots/subscribe/link/:string_bot/

=cut
#**********************************************************
sub get_bots_subscribe_link_bot {
  my $self = shift;
  return $self->_bot_link(@_, 'LINK');
}

#**********************************************************
=head2 bots_subscribe_qrcode_bot($path_params, $query_params)

  Endpoint GET /bots/subscribe/qrcode/:string_bot/

=cut
#**********************************************************
sub get_bots_subscribe_qrcode_bot {
  my $self = shift;
  return $self->_bot_link(@_, 'QRCODE');
}

#**********************************************************
=head2 _bot_link($path_params, $query_params, $type)

=cut
#**********************************************************
sub _bot_link {
  my $self = shift;
  my ($path_params, $query_params, undef, $type) = @_;

  require Api::Controllers::Common::Bots;
  Api::Controllers::Common::Bots->import();
  my $Bots = Api::Controllers::Common::Bots->new($self->{db}, $self->{admin}, $self->{conf}, {Errors => $Errors});

  my $sid = $query_params->{REQUEST_ADMINSID} || '';

  if (!$sid) {
    $self->{admin}->online({
      SID      => $sid,
      TIMEOUT  => $self->{conf}->{web_session_timeout},
      EXT_INFO => $ENV{HTTP_USER_AGENT}
    });

    $sid = $self->{admin}->{SID} || '';
  }

  if ($type eq 'QRCODE') {
    return $Bots->_bots_subscribe_qrcode({
      BOT => $path_params->{bot},
      SID => "a_$sid",
    });
  }
  else {
    return $Bots->_bots_subscribe_link({
      BOT => $path_params->{bot},
      SID => "a_$sid",
    });
  }
}

1;
