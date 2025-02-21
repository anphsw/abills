package Api::Controllers::User::User_core::Credit;

=head1 NAME

  User API Credit

  Endpoints:
    /user/credit/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Control::Service_control;

my Control::Errors $Errors;
my Control::Service_control $Service_control;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_credit($path_params, $query_params)

  Endpoint POST /user/credit/

=cut
#**********************************************************
sub post_user_credit {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Service_control->user_set_credit({
    UID           => $path_params->{uid},
    change_credit => 1,
  });
}

#**********************************************************
=head2 get_user_credit($path_params, $query_params)

  Endpoint GET /user/credit/

=cut
#**********************************************************
sub get_user_credit {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Service_control->user_set_credit({
    UID => $path_params->{uid}
  });
}

1;
