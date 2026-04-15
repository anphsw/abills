package Equipment::Api::admin::Box;

=head1 NAME

  Equipment Box

  Endpoints:
    /equipment/box/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

use Equipment::db::Boxes;

my Equipment::db::Boxes $Equipment_box;
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

  $Equipment_box = Equipment::db::Boxes->new($db, $admin, $conf);
  $Equipment_box->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_equipment_box_list($path_params, $query_params)

  Endpoint GET /equipment/box/list/

=cut
#**********************************************************
sub get_equipment_box_list {
  my ($self, $path_params, $query_params) = @_;

  return $Equipment_box->list($query_params);
}


1;
