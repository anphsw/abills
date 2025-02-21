package Equipment::Api::user::Root;

=head1 NAME

  Equipment Onu

  Endpoints:
    /user/equipment/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

use Equipment;
use Equipment::Users;

my Equipment $Equipment;
my Equipment::Users $Equipment_users;
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

  $Equipment = Equipment->new($db, $admin, $conf);
  $Equipment->{debug} = $self->{debug};
  $Equipment_users = Equipment::Users->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_equipment($path_params, $query_params)

  Endpoint GET /user/equipment/

=cut
#**********************************************************
sub get_user_equipment {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # clear global form
  %main::FORM = ();

  my $devices_info = $Equipment_users->devices_info({
    UID => $path_params->{uid},
  });

  return $devices_info;
}

1;
