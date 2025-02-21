package Api::Controllers::User::User_core::Root;

=head1 NAME

  User API Root (other)

  Endpoints:
    /user/...

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
=head2 get_user_services($path_params, $query_params)

  Endpoint GET /user/services/

=cut
#**********************************************************
sub get_user_services {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($INC{'Control/Services.pm'}) {
    delete $INC{'Control/Services.pm'};
  }
  ::load_module('Control::Services', { LOAD_PACKAGE => 1 });

  my $services = ::get_user_services({
    uid         => $path_params->{uid},
    active_only => $query_params->{ACTIVE_ONLY} ? 1 : 0
  });

  return $services;
}

#**********************************************************
=head2 get_user_recommendedPay($path_params, $query_params)

  Endpoint GET /user/recommendedPay/

=cut
#**********************************************************
sub get_user_recommendedPay {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->info($path_params->{uid});

  my $sum = ::recomended_pay($Users);
  my $min_sum = $self->{conf}->{PAYSYS_MIN_SUM} || 0;

  if ($self->{conf}->{PAYSYS_MIN_SUM_RECOMMENDED_PAY} && $sum > $min_sum) {
    $min_sum = $sum;
  }

  my $all_services_fee = ::recomended_pay($Users, { SKIP_DEPOSIT_CHECK => 1 });

  return {
    sum              => $sum,
    all_services_sum => $all_services_fee,
    max_sum          => $self->{conf}->{PAYSYS_MAX_SUM} || 0,
    min_sum          => $min_sum,
  };
}

1;
