package Api::Controllers::User::Bots;

=head1 NAME

  User API Bots

  Endpoints:
    /user/bots/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Api::Controllers::Common::Bots;

my Control::Errors $Errors;
my Api::Controllers::Common::Bots $Bots;

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
  $Bots = Api::Controllers::Common::Bots->new($self->{db}, $self->{admin}, $self->{conf}, {Errors => $Errors});

  return $self;
}

#**********************************************************
=head2 user_bots_subscribe_link_bot($path_params, $query_params)

  Endpoint GET /user/bots/subscribe/link/:string_bot/

=cut
#**********************************************************
sub get_user_bots_subscribe_link_bot {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $sid = $query_params->{REQUEST_USERSID};

  return $Bots->_bots_subscribe_link({
    BOT => $path_params->{bot},
    SID => "u_$sid",
  });
}

#**********************************************************
=head2 user_bots_subscribe_qrcode_bot($path_params, $query_params)

  Endpoint GET /user/bots/subscribe/qrcode/:string_bot/

=cut
#**********************************************************
sub get_user_bots_subscribe_qrcode_bot {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $sid = $query_params->{REQUEST_USERSID};

  return $Bots->_bots_subscribe_qrcode({
    BOT => $path_params->{bot},
    SID => "u_$sid",
  });
}

1;
