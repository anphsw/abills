package Maps::Api::admin::Online;

=head1 NAME

  Maps Online

  Endpoints:
    /maps/online/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Maps;

use Maps::Shared qw/LAYER_ID_BY_NAME/;

my Maps $Maps;
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

  $Maps = Maps->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_maps_online($path_params, $query_params)

  Endpoint GET /maps/online/

=cut
#**********************************************************
sub get_maps_online {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $online_list = $Maps->users_monitoring_list({ COLS_NAME => 1 });
  return $online_list if !$Maps->{TOTAL} || $Maps->{TOTAL} < 1;

  my $builds_polygon_list = $Maps->polygon_points_list({
    COORDX     => '_SHOW',
    COORDY     => '_SHOW',
    POLYGON_ID => '_SHOW',
    LAYER_ID   => LAYER_ID_BY_NAME->{BUILD2}
  });

  my $coords_by_polygon_id = {};
  foreach my $coord (@{$builds_polygon_list}) {
    next unless $coord->{polygon_id};
    push @{$coords_by_polygon_id->{$coord->{polygon_id}}}, [ $coord->{coordx}, $coord->{coordy} ];
  }

  my $builds = {};
  foreach my $online_user (@{$online_list}) {
    my $build_id = $online_user->{build_id};
    my $polygon_id = $online_user->{polygone_id};

    $builds->{$build_id} //= {
      build_id => $build_id,
      coords   => [],
      users    => [],
    };

    push @{$builds->{$build_id}{users}}, $online_user;
    $builds->{$build_id}{is_online} = $online_user->{online} if !$builds->{$build_id}{is_online};

    if ($online_user->{coordx} && $online_user->{coordy}) {
      $builds->{$build_id}{coords} = [ [ $online_user->{coordx}, $online_user->{coordy} ] ];
    } elsif ($polygon_id && $coords_by_polygon_id->{$polygon_id}) {
      $builds->{$build_id}{coords} = $coords_by_polygon_id->{$polygon_id};
    }
  }

  return {
    list  => [ values %{$builds} ],
    total => scalar keys %{$builds},
  };

}

1;
