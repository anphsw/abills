package Api::Controllers::Common::Users;
=head NAME

  Common users functions articles manage

  Endpoints:
    /users/*
    or
    /user/*

=cut
use strict;
use warnings FATAL => 'all';

use Control::Services;

my Control::Errors $Errors;
my Users $Users;
my Control::Services $Services;

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

  $Services = Control::Services->new($self->{db}, $self->{admin}, $self->{conf});
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_recommendedPay($path_params, $query_params)

  Endpoint GET /user/recommendedPay/

=cut
#**********************************************************
sub get_user_recommendedPay {
  my ($self, $path_params, $query_params) = @_;

  $Users->info($path_params->{uid});

  my $sum = ::recomended_pay($Users);
  my $min_sum = $self->{conf}->{PAYSYS_MIN_SUM} || 0;

  if ($self->{conf}->{PAYSYS_MIN_SUM_RECOMMENDED_PAY} && $sum > $min_sum) {
    $min_sum = $sum;
  }

  my $service_info = $Services->get_services($Users, { SKIP_MODULES => 'Sqlcmd' });

  return {
    sum              => $sum,
    all_services_sum => $service_info->{total_sum} || 0,
    max_sum          => $self->{conf}->{PAYSYS_MAX_SUM} || 0,
    min_sum          => $min_sum,
  };
}

1;
