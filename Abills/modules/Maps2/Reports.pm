use strict;
use warnings FATAL => 'all';

=head1 NAME

  Maps2::Reports - maps reports

=cut

our (
  $Maps,
  $html,
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS
);

use Maps2::Layers;
use Address;
use Abills::Base qw(in_array _bp);

#**********************************************************
=head2 maps_objects_reports()

=cut
#**********************************************************
sub maps_objects_reports {

  my $objects = _maps2_get_basic_object();

  if (in_array('Cablecat', \@MODULES)) {
    use Cablecat;
    my $Cablecat = Cablecat->new($db, $admin, \%conf);

    $objects->{CABLE} = $Cablecat->cable_list_with_points({ONLY_TOTAL => 1});
    $objects->{WELL} = _maps2_well_reports($Cablecat);
  }

  if (in_array('Equipment', \@MODULES)) {
    use Equipment;

    %{$objects} = (%{$objects} ,%{_maps2_equipment_show()});
  }

  my $objects_info = $html->table({
    width      => '100%',
    caption    => "Maps: " . $lang{DISPLAYED_ITEMS},
    title      => [ $lang{TYPE}, $lang{COUNT}, "Maps" ],
    ID         => 'MAPS_ITEMS',
    DATA_TABLE => 1,
  });

  foreach my $key (sort keys %{$objects}) {
    my $type_name = $lang{$key} ? $lang{$key} : $key eq 'BUILD2' ? $lang{'BUILD'} . '2' : $key;
    my $maps_btn = maps2_show_object_button($key);
    $objects_info->addrow($type_name, $objects->{$key}, $maps_btn);
  }

  print $objects_info->show();
}

#**********************************************************
=head2 _maps2_get_basic_object()

=cut
#**********************************************************
sub _maps2_get_basic_object {
  return {
    BUILD    => maps2_builds_show({ ONLY_COUNT => 1 }),
    BUILD2   => maps2_builds2_show({ ONLY_COUNT => 1 }),
    DISTRICT => maps2_districts_show({ ONLY_COUNT => 1 }),
    WIFI     => maps2_wifis_show({ ONLY_COUNT => 1 }),
  }
}

#**********************************************************
=head2 _maps2_well_reports()

=cut
#**********************************************************
sub _maps2_well_reports {
  my ($Cablecat) = @_;

  my $wells_list = $Cablecat->wells_list({
    POINT_ID  => '!',
    NAME      => '_SHOW',
    TYPE_ID   => '_SHOW',
    ICON      => '_SHOW',
    COMMENTS  => '_SHOW',
    PAGE_ROWS => 10000
  });
  _error_show($Cablecat);

  my @object_ids = map {$_->{point_id}} @{$wells_list};

  my $point_ids = join(';', @object_ids);
  _error_show($Maps);

  $Maps->points_list({
    ID               => $point_ids,
    SHOW_ALL_COLUMNS => 1,
    NAME             => '_SHOW',
    ICON             => '_SHOW',
    TYPE             => '_SHOW',
    TYPE_ID          => '_SHOW',
    COORDX           => '!',
    COORDY           => '!',
    COLS_NAME        => 1,
    ADDRESS_FULL     => '_SHOW',
    EXTERNAL         => 1,
  });

  return $Maps->{TOTAL};
};

#**********************************************************
=head2 _maps2_equipment_show()

=cut
#**********************************************************
sub _maps2_equipment_show {

  my $Equipment = Equipment->new($db, $admin, \%conf);
  my $count_equipment = 0;
  my %showed_equipment = ();

  my $equipment_list = $Equipment->_list({
    NAS_ID      => '_SHOW',
    LOCATION_ID => '_SHOW',
    COORDX      => '_SHOW',
    COORDY      => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 10000,
  });

  foreach my $point (@{$equipment_list}) {
    next if (!($point->{coordy} && $point->{coordx}) || $showed_equipment{$point->{location_id}});
    $count_equipment++;
    $showed_equipment{$point->{location_id}} = 1;
  }

  #  PON
  $equipment_list = $Equipment->onu_list({
    MAPS_COORDS => '_SHOW',
    LOCATION_ID => '_SHOW',
    LOGIN       => '_SHOW',
    COLS_NAME   => 1,
    PAGE_ROWS   => 100000,
  });

  my $count_pon = 0;
  foreach my $point (@{$equipment_list}) {
    next if (!($point->{build_id} && $point->{maps_coords}));
    my ($coordy, $coordx) = split(/:/, $point->{maps_coords});

    if ($coordx ne "0.00000000000000" && $coordy ne "0.00000000000000") {
      $count_pon++;
    }
  }

  return {
    EQUIPMENT => $count_equipment,
    PON       => $count_pon
  }
}
1;

