package Api::Controllers::Admin::Callback;

=head1 NAME

  ADMIN API Callback

  Endpoints:
    /callback/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Voip;

my Control::Errors $Errors;
my Voip $Voip;

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
  $Voip = Voip->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 post_callback_subscribe($path_params, $query_params)

  Endpoint POST /callback/subscribe/

=cut
#**********************************************************
sub post_callback_subscribe {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->vpbx_subscribe_add($query_params);
}

#**********************************************************
=head2 delete_callback_unsubscribe($path_params, $query_params)

  Endpoint DELETE /callback/unsubscribe/

=cut
#**********************************************************
sub delete_callback_unsubscribe {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->vpbx_subscribe_del($query_params->{CALLBACK_URL});
}

1;
