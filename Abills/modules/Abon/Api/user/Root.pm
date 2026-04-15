package Abon::Api::user::Root;

=head1 NAME

  User Abon Root

  Endpoints:
    /user/abon/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(dirname cmd next_month in_array);

use Abon;
use Abon::Services;
use Control::Errors;

my Abon $Abon;
my Abon::Services $Abon_services;
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
    attr  => $attr
  };

  bless($self, $class);

  $Abon //= Abon->new($self->{db}, $self->{admin}, $self->{conf});
  $Abon_services //= Abon::Services->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_abon($path_params, $query_params)

  Endpoint GET /user/abon/

=cut
#**********************************************************
sub get_user_abon {
  my ($self, $path_params) = @_;

  require Control::Services;
  Control::Services->import();
  my $Services = Control::Services->new($self->{db}, $self->{admin}, $self->{conf});

  return $Services->get_user_services({
    uid     => $path_params->{uid},
    service => 'Abon',
  });
}

#**********************************************************
=head2 post_user_abon($path_params, $query_params)

  Endpoint POST /user/abon/

=cut
#**********************************************************
sub post_user_abon {
  my ($self, $path_params, $query_params) = @_;

  my $services = $Abon->tariff_info($path_params->{id});

  if (!$Abon->{TOTAL}) {
    return $Errors->throw_error(1020002);
  }
  elsif ($Abon->{TOTAL} && $Abon->{TOTAL} < 0) {
    return {
      errno  => $Abon->{errno},
      errstr => $Abon->{errstr},
    };
  }

  if ($services->{USER_PORTAL} < 2 && !$services->{MANUAL_ACTIVATE}) {
    return {
      errno  => 200,
      errstr => 'Unknown operation'
    }
  }

  return $Abon_services->abon_user_tariff_activate({
    %{$query_params},
    UID => $path_params->{uid},
    ID  => $path_params->{id},
  });
}

1;
