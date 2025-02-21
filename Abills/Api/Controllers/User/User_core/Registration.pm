package Api::Controllers::User::User_core::Registration;

=head1 NAME

  User API Registration

  Endpoints:
    /user/password/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Control::Registration_mng;

my Control::Errors $Errors;
my Control::Registration_mng $Registration_mng;

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

  $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf},
    { HTML => $self->{html}, LANG => $self->{lang} }
  );

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_resend_verification($path_params, $query_params)

  Endpoint POST /user/resend/verification/

=cut
#**********************************************************
sub post_user_resend_verification {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Registration_mng->resend_pin($query_params);
}

#**********************************************************
=head2 post_user_verify($path_params, $query_params)

  Endpoint POST /user/verify/

=cut
#**********************************************************
sub post_user_verify {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Registration_mng->verify_pin($query_params);
}

#**********************************************************
=head2 post_user_verify($path_params, $query_params)

  Endpoint POST /user/registration/

=cut
#**********************************************************
sub post_user_registration {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Registration_mng->user_registration($query_params);
}

1;
