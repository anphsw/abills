package Api::Controllers::Admin::Users::Abon;

=head1 NAME

  ADMIN API Users Abon

  Endpoints:
    /users/abon/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Abon;

my Control::Errors $Errors;
my Abon $Abon;

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

  $Abon = Abon->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_users_uid_abon($path_params, $query_params)

  Endpoint GET /users/:uid/abon/

=cut
#**********************************************************
sub get_users_uid_abon {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if $self->{admin}->{MODULES} && !$self->{admin}->{MODULES}->{Abon};

  $Abon->user_tariff_list($path_params->{uid}, {
    COLS_NAME => 1
  });
}

1;
