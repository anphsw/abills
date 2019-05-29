use strict;
use warnings FATAL => 'all';

our ($Maps, $html, %lang, %conf, $admin, $db, %permissions, %LIST_PARAMS);

use Address;
use Equipment;
use Cablecat;
use Abills::Base qw(in_array _bp);
my $Address = Address->new($db, $admin, \%conf);
my $Equipment = Equipment->new($db, $admin, \%conf);
my $Cablecat = Cablecat->new($db, $admin, \%conf);

require GPS;
GPS->import();
my $Gps = GPS->new($db, $admin, \%conf);

my %LAYER_ID_BY_NAME = (
  'BUILDS'        => 1,
  'WIFI'          => 2,
  'ROUTES'        => 3,
  'DISTRICT'      => 4,
  'TRAFFIC'       => 5,
  'OBJECTS'       => 6,
  'EQUIPMENT'     => 7,
  'GPS'           => 8,
  'GPS_ROUTE'     => 9,
  'CABLES'        => 10,
  'WELLS'         => 11,
  'CABLE_RESERVE' => 11,
  'BUILD2'        => 12,
  'PON'           => 20,
  'CAMS'          => 33,
);

#**********************************************************
=head2 maps_builds_reports()

=cut
#**********************************************************
sub maps_builds_reports {
  my %list_items = ();

  #  BUILDS
  $Address->build_list(
    {
      DISTRICT_ID => '>0',
      COORDX      => '!',
      COORDY      => '!',
      PAGE_ROWS   => 100000,
      LOCATION_ID => '_SHOW'
    }
  );
  $list_items{BUILDS} = $Address->{TOTAL};

  #  ROUTES
  $Maps->routes_list({ ID => '_SHOW', });
  $list_items{ROUTES} = $Maps->{TOTAL} == -1 ? 0 : $Maps->{TOTAL};

  #  WI-FI
  my $list_wifi_objects = _maps_get_layer_objects(1, { ID => '_SHOW', });
  my $size = @$list_wifi_objects;
  $list_items{WIFI} = $size > 0 ? $size : 0;

  #  GPS
  my @list_gps = ();
  my $tracked_admins = $Gps->tracked_admins_list();
  foreach my $tracker (@{$tracked_admins}) {
    push @list_gps, $Gps->tracked_admin_info($tracker->{aid});
  }
  $size = @list_gps;
  $list_items{GPS} = $size > 0 ? $size : 0;

  #  Objects
  my $custom_points_list = $Maps->points_list({
    NAME         => '_SHOW',
    ICON         => '_SHOW',
    TYPE         => '_SHOW',
    TYPE_ID      => '_SHOW',
    COORDX       => '_SHOW',
    COORDY       => '_SHOW',
    ADDRESS_FULL => '_SHOW',
    COMMENTS     => '_SHOW',
    EXTERNAL     => '0',
    COLS_NAME    => 1,
  });

  my $count_object = 0;
  foreach my $point ( @{$custom_points_list} ) {
    next if (!($point->{coordy} && $point->{coordx}) || (!$point->{icon}));
    $count_object++;
  }
  $list_items{OBJECTS} = $count_object++;

  #  District
  $Maps->districts_list({
    OBJECT_ID => '_SHOW',
    LIST2HASH => 'object_id,district_id'
  });
  $list_items{DISTRICT} = $Maps->{TOTAL};

  #  Equipment
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
  $list_items{EQUIPMENT} = $count_equipment;

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

    if (!($coordx eq "0.00000000000000" && $coordy eq "0.00000000000000")) {
      $count_pon++;
    }
  }

  $list_items{PON} = $count_pon;

  #  Cables
  $list_items{CABLES} = _cable_reports();

  #  Wells
  $list_items{WELLS} = _well_reports();

  #  Cable reserve
  $list_items{CABLE_RESERVE} = _coil_reports();

  my $table = $html->table(
    {
      width   => '100%',
      caption => "Maps: " . $lang{DISPLAYED_ITEMS},
      title   => [ $lang{TYPE}, $lang{COUNT}, "Maps" ],
      ID      => 'MAPS_ITEMS',
      DATA_TABLE => 1,
    }
  );

  foreach my $key (sort keys %list_items) {
    my $type_name = $lang{$key} ? $lang{$key} : $key;
    my $maps_btn = maps_show_object_button(
      $LAYER_ID_BY_NAME{$key},
      '',
      { GO_TO_MAP => 1 }
    );
    $table->addrow($type_name, $list_items{$key}, $maps_btn);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 _cable_reports()

=cut
#**********************************************************
sub _cable_reports {

  my $cables_list = $Cablecat->cables_list({
    POINT_ID          => $FORM{OBJECT_ID} || $FORM{POINT_ID} || '!',
    NAME              => '_SHOW',
    CABLE_TYPE        => '_SHOW',
    WELL_1            => '_SHOW',
    WELL_2            => '_SHOW',
    WELL_1_ID         => '_SHOW',
    WELL_2_ID         => '_SHOW',
    OUTER_COLOR       => '_SHOW',
    LINE_WIDTH        => '_SHOW',
    LENGTH            => '_SHOW',
    LENGTH_CALCULATED => '_SHOW',
    CAN_BE_SPLITTED   => '_SHOW',
    COMMENTS          => '_SHOW',
    PAGE_ROWS         => 10000
  });
  _error_show($Cablecat);

  # Get all current active objects that cables are linked to
  my @object_ids = map {+$_->{point_id}} @{$cables_list};

  # Joining for DB searching
  my $point_ids = join(';', @object_ids);

  my $points_list = $Maps->points_list({ ID => $point_ids, SHOW_ALL_COLUMNS => 1, EXTERNAL => 1, PAGE_ROWS => 10000 });
  my $layer_objects = _maps_get_layer_objects(10, { OBJECT_ID => $point_ids });

  # Sorting to hashes
  my $points_by_id = sort_array_to_hash($points_list, 'id');
  my $cable_by_point_id = sort_array_to_hash($cables_list, 'point_id');
  my $layer_objects_by_point_id = sort_array_to_hash($layer_objects, 'OBJECT_ID');

  my $count = 0;
  # Apply cable_info to geometric figures
  foreach (@object_ids) {
    my $cable = $cable_by_point_id->{$_};
    next if (!$cable->{point_id} || !$cable->{id});

    my $polyline = $layer_objects_by_point_id->{$_}->{POLYLINE};
    next if (!$polyline->{id});

    my $point = $points_by_id->{$_};
    next if (!$point);

    $count++;
  }

  return $count;
}

#**********************************************************
=head2 _well_reports()

=cut
#**********************************************************
sub _well_reports {

  my $wells_list = $Cablecat->wells_list({
    POINT_ID  => $FORM{OBJECT_ID} || $FORM{POINT_ID} || '!',
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

  my $points_list = $Maps->points_list({
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

  my $points_by_id = sort_array_to_hash($points_list);
  my $count = 0;;

  foreach (@object_ids) {
    my $point = $points_by_id->{$_};

    next if (!($point->{coordx} && $point->{coordy}));

    $count++;
  }

  return $count;
}

=head2 _coil_reports()

=cut
#**********************************************************
sub _coil_reports {

  my $coils_list = $Cablecat->coil_list({
    POINT_ID  => '_SHOW',
    NAME      => '_SHOW',
    CABLE_ID  => '_SHOW',
    ID        => '_SHOW',
    PAGE_ROWS => 10000
  });
  _error_show($Cablecat);

  my @object_ids = map {$_->{point_id}} @{$coils_list};

  my $point_ids = join(';', @object_ids);

  my $points_list = $Maps->points_list({
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
  _error_show($Maps);

  my $points_by_id = sort_array_to_hash($points_list);
  my $count = 0;

  foreach (@object_ids) {
    my $point = $points_by_id->{$_};

    next if (!($point->{coordx} && $point->{coordy}));
    $count++;
  }

  return $count;
}

1;