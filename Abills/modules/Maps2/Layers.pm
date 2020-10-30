#package Layers;
use strict;
use warnings FATAL => 'all';
use v0.02;

=head1 NAME

  Maps2::Layers - maps layer objects serializing functions

=head2 SYNOPSIS

  This is part of webinterface that transforms DB objects to JSON

=cut

use Abills::Base qw/_bp in_array/;

our ($MAPS_ENABLED_LAYERS);
use Maps2::Shared;
use Abills::Experimental;

our (
  $db,
  $admin,
  %conf,
  $html,
  %lang,
  %permissions,
  $Address,
  $Nas,
  $Maps,
  @WEEKDAYS,
);

require JSON;
JSON->import(qw/to_json from_json encode_json decode_json/);


#**********************************************************
=head2 maps2_point_info_table($attr) - Make point info window

  Arguments:
    $attr
      OBJECTS - Data form map Hash ref
            [{
              login   => 'test',
              deposit => 1.11
            }]

      TABLE_TITLES - array_ref Location table information fields

  Returns:
    string - HTML table with information

=cut
#**********************************************************
sub maps2_point_info_table {
  my ($attr) = @_;
  my $point_info_object = '<div class="box box-theme"><table class="table table-condensed table-hover table-bordered">';

  my $objects = $attr->{OBJECTS};
  my $table_titles = $attr->{TABLE_TITLES};

  return q{} unless ($objects && ref $objects eq 'ARRAY' && scalar @{$objects});

  my $online_block = $html->element('span', '', {
    class => 'glyphicon glyphicon-ok-circle text-green',
    title => $lang{ONLINE}
  });

  # Add headers
  if ($attr->{TABLE_LANG_TITLES} && ref $attr->{TABLE_LANG_TITLES} eq 'ARRAY') {
    $point_info_object .= '<tr>' . join('', map {'<th>' . ($_ || q{}) . '</th>'} @{$attr->{TABLE_LANG_TITLES}}) . '</tr>';
  }

  foreach my $u (@{$objects}) {
    $point_info_object .= '<tr>';
    for (my $i = 0; $i <= $#{$table_titles}; $i++) {
      my $value = $table_titles->[$i];
      next unless $value;

      $value = _maps2_get_value_for_table({
        OBJECT        => $u,
        FIELD_ID      => lc($table_titles->[$i]),
        TITLE         => $value,
        ONLINE_BLOCK  => $online_block,
        LINK_ITEMS    => $attr->{LINK_ITEMS},
        DEFAULT_VALUE => $attr->{DEFAULT_VALUE},
      });
      next if $value eq '-1';
      $point_info_object .= '<td>' . ($value || q{}) . '</td>';
    }
    $point_info_object .= '</tr>';
  }

  $point_info_object .= '</table></div>';
  $point_info_object =~ s/\"/\\\"/gm if $attr->{TO_SCREEN};

  return $point_info_object;
}

#**********************************************************
=head2 _maps2_get_value_for_table($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub _maps2_get_value_for_table {
  my ($attr) = @_;

  return -1 if (!$attr->{OBJECT} || !$attr->{FIELD_ID});
  my $value = '';

  if ($attr->{TITLE} eq 'LOGIN' && $attr->{OBJECT}{uid}) {
    $value = $html->button($attr->{OBJECT}{$attr->{FIELD_ID}}, "index=15&UID=$attr->{OBJECT}{uid}");
  }
  elsif ($attr->{TITLE} eq 'DEPOSIT' && defined($attr->{OBJECT}{'deposit'})) {
    my $deposit = sprintf("%.2f", $attr->{OBJECT}{'deposit'});
    $value = $attr->{OBJECT}{$attr->{FIELD_ID}} < 0 ? qq{<div class="text-danger">$deposit</div>} : $deposit;
  }
  elsif ($attr->{TITLE} eq 'ADDRESS_FLAT') {
    $value = $html->b($attr->{OBJECT}->{$attr->{FIELD_ID}});
  }
  elsif ($attr->{TITLE} eq 'ONLINE') {
    $value = ($attr->{OBJECT}{$attr->{FIELD_ID}}) ? $attr->{ONLINE_BLOCK} : 0;
  }
  elsif ($attr->{LINK_ITEMS} && $attr->{LINK_ITEMS}{$attr->{FIELD_ID}}) {
    $value = _maps2_get_link_value($attr->{OBJECT}, $attr->{FIELD_ID}, $attr);
    return -1 unless $value;
  }
  else {
    $value = (ref $attr->{OBJECT} eq 'HASH' && $attr->{OBJECT}{$attr->{FIELD_ID}}) ? $attr->{OBJECT}{$attr->{FIELD_ID}} : '';
    $value =~ s/[\r\n]/ /g;
  }

  return $value;
}

#**********************************************************
=head2 _maps2_get_link_value($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub _maps2_get_link_value {
  my ($object, $field_id, $attr) = @_;

  my $index_link = $attr->{LINK_ITEMS}{$field_id}{index} || "";
  return 0 if !$index_link;

  if (!$object->{$field_id} && $attr->{DEFAULT_VALUE}{$field_id}) {
    $object->{$field_id} = $attr->{DEFAULT_VALUE}{$field_id};
  }

  my $link = '<a href="?index=' . $index_link;
  foreach my $extra_key (sort keys %{$attr->{LINK_ITEMS}{$field_id}{EXTRA_PARAMS}}) {
    my $link_value = $attr->{LINK_ITEMS}{$field_id}{EXTRA_PARAMS}->{$extra_key};
    next if !$object->{$link_value};
    $link .= "&$extra_key=$object->{$link_value}";
  }
  return $link . '" target=_blank>' . ($object->{$field_id} || '') . '</a>';
}

#**********************************************************
=head2 maps2_builds_show($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub maps2_builds_show {
  my ($attr) = @_;

  my $export = $FORM{EXPORT_LIST} || $attr->{EXPORT};
  my $object_info = $attr->{DATA};
  my $to_screen = $attr->{TO_SCREEN} || 0;
  my $count_object = 0;
  my @export_hash_arr = ();

  _maps2_get_old_builds($attr, \$count_object, \@export_hash_arr, $object_info, $to_screen);

  _maps2_get_new_builds($attr, \$count_object, \@export_hash_arr, $object_info);

  return $count_object if ($attr->{ONLY_COUNT});
  return \@export_hash_arr if $attr->{RETURN_HASH};

  return '' if !$export;

  my $export_string = JSON::to_json(\@export_hash_arr, { utf8 => 0 });
  print $export_string;
  return $export_string;
}

#**********************************************************
=head2 maps2_builds2_show($attr)

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub maps2_builds2_show {
  my ($attr) = @_;

  my $export = $FORM{EXPORT_LIST} || $attr->{EXPORT};
  my @export_hash_arr = ();
  my $to_screen = $attr->{TO_SCREEN} || 0;

  if ($FORM{RETURN_HASH_OBJECT}) {
    $attr->{LOCATION_ID} ||= $FORM{OBJECT_ID};
    delete $FORM{OBJECT_ID};
  }
  $FORM{LAST_OBJECT_ID} = "> $FORM{LAST_OBJECT_ID}" if $FORM{LAST_OBJECT_ID};

  my $list_builds_objects = $Maps->build2_list_with_points({
    LOCATION_ID   => $attr->{LOCATION_ID} || '_SHOW',
    COORDS        => '_SHOW',
    FULL_ADDRESS  => '_SHOW',
    OBJECT_ID     => $FORM{OBJECT_ID} || $FORM{LAST_OBJECT_ID} || '_SHOW',
    COORDX_CENTER => '_SHOW',
    COORDY_CENTER => '_SHOW',
    COLS_NAME     => 1,
  });

  return $Maps->{TOTAL} if ($attr->{ONLY_COUNT} || !$Maps->{TOTAL});

  foreach my $build (@{$list_builds_objects}) {
    next unless ($build->{object_id});

    next if $attr->{BUILD_IDS} && !in_array($build->{location_id}, $attr->{BUILD_IDS});

    my $info_hash = {};
    my $point_count = 0;

    $info_hash = maps2_load_info({ LOCATION_ID => $build->{location_id}, TO_SCREEN => $to_screen }) if !$attr->{CLIENT_MAP};
    $point_count = $info_hash->{COUNT} || 0;

    my $color = $info_hash->{COLOR} || _maps2_point_color($point_count);
    my $info_table = $info_hash->{HTML} || '';

    my @points = split(',', $build->{coords});
    foreach my $point (@points) {
      my @point_array = split('\|', $point);
      push @{$build->{POLYGON}{POINTS}}, \@point_array;
    }

    my %regex = (
      ID        => $build->{object_id},
      OBJECT_ID => $build->{object_id},
      POLYGON   => {
        ID        => $build->{object_id},
        OBJECT_ID => $build->{object_id},
        NAME      => $build->{address_full},
        LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD2} ]},
        INFO      => $info_table,
        COUNT     => $point_count,
        POINTS    => $build->{POLYGON}->{POINTS},
        COLOR     => $color
      },
      LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD2} ]}
    );

    if ($attr->{GET_LIKE_MARKER}) {
      %regex = (
        ID        => $build->{object_id},
        OBJECT_ID => $build->{object_id},
        MARKER   => {
          ID        => $build->{object_id},
          OBJECT_ID => $build->{object_id},
          NAME      => $build->{address_full},
          LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD2} ]},
          COORDX    => $build->{coordx_center},
          COORDY    => $build->{coordy_center},
          INFO      => $info_table,
          COLOR     => $color,
          TYPE      => "build_$color",
        },
        LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD2} ]}
      );
    }

    push @export_hash_arr, \%regex;
  }

  return \@export_hash_arr if ($attr->{RETURN_HASH});

  if ($export) {
    my $export_string = JSON::to_json(\@export_hash_arr, { utf8 => 0 });
    print $export_string if $FORM{RETURN_JSON};;
    return $export_string;
  }

  return 1;
}

#**********************************************************
=head2 maps2_districts_show()

=cut
#**********************************************************
sub maps2_districts_show {
  my ($attr) = @_;

  my $districts_list = $Maps->districts_list({
    OBJECT_ID   => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" : $FORM{ID} ?
      $FORM{ID} : $FORM{OBJECT_ID} ? $FORM{OBJECT_ID} : '_SHOW',
    DISTRICT_ID => $FORM{DISTRICT_ID} || '_SHOW',
    DISTRICT    => '_SHOW',
    LIST2HASH   => 'object_id,district_id'
  });
  _error_show($Maps);

  my $district_for_object_id = sort_array_to_hash($districts_list, 'object_id');

  my @object_ids = map {$_->{object_id}} @{$districts_list};

  my $layer_objects = _maps2_get_layer_objects(LAYER_ID_BY_NAME->{DISTRICT}, {
    ID => join(';', @object_ids)
  });
  _error_show($Maps);

  if ($attr->{ONLY_COUNT}) {
    my $count = @{$layer_objects};
    return $count;
  }

  foreach my $object (@$layer_objects) {
    $object->{POLYGON}{name} = $district_for_object_id->{$object->{OBJECT_ID}}{district};
  }

  if ($FORM{RETURN_JSON}) {
    print "[" . join(', ', map {JSON::to_json($_)} @{$layer_objects}) . "]";
    return 1;
  }

  $MAPS_ENABLED_LAYERS->{ LAYER_ID_BY_NAME->{DISTRICT} } = 'DISTRICT';
  return join(";", map {"ObjectsArray[ObjectsArray.length] = " . JSON::to_json($_)} @{$layer_objects});
}

#**********************************************************
=head2 maps2_districts_main()

=cut
#**********************************************************
sub maps2_districts_main {

  my %TEMPLATE_ARGS = ();
  my $show_add_form = $FORM{add_form} || 0;

  if ($FORM{add}) {
    my $new_point_id = maps2_add_external_object(LAYER_ID_BY_NAME->{DISTRICT}, \%FORM);
    show_result($Maps, $lang{ADDED} . ' ' . $lang{OBJECT}) unless !$FORM{ADD_ON_NEW_MAP};
    $FORM{OBJECT_ID} = $new_point_id;

    $Maps->districts_add({ %FORM });
    $show_add_form = show_result($Maps, $lang{ADDED}) unless !$FORM{ADD_ON_NEW_MAP};

    if ($FORM{ADD_ON_NEW_MAP}) {
      $Maps->polygons_add({
        OBJECT_ID => $new_point_id,
        LAYER_ID  => 4,
        COLOR     => $FORM{COLOR}
      });

      my @points_array = split(/,/, $FORM{coords});

      if ($Maps->{INSERT_ID}) {
        my $polygon_id = $Maps->{INSERT_ID};
        foreach my $point (@points_array) {
          my ($coordx, $coordy) = split(':', $point);
          $Maps->polygon_points_add({
            POLYGON_ID => $polygon_id,
            COORDX     => $coordx,
            COORDY     => $coordy
          });
        }
      }

      $html->message('info', "$lang{ADDED} $lang{DISTRICT}");
      return 1;
    }

    if ($FORM{RETURN_FORM} && $html->{TYPE} eq 'json') {
      foreach (split(',\s?', $FORM{RETURN_FORM})) {
        push(@{$html->{JSON_OUTPUT}}, {
          $_ => '"' . ($FORM{$_} || q{}) . '"'
        });
      }
    }
  }
  elsif ($FORM{change}) {
    $Maps->districts_change({ %FORM });
    show_result($Maps, $lang{CHANGED});
    $show_add_form = 1;
  }
  elsif ($FORM{del}) {
    $Maps->districts_del({}, { district_id => $FORM{del} });
    show_result($Maps, $lang{DELETED});
  }
  elsif ($FORM{chg}) {
    my $tp_info = $Maps->districts_info($FORM{chg});
    if (!_error_show($Maps)) {
      %TEMPLATE_ARGS = %{$tp_info};
      $show_add_form = 1;
    }
  }

  return 1 if ($FORM{MESSAGE_ONLY});

  if ($show_add_form) {
    my $districts = $Address->district_list({ PAGE_ROWS => 1000, COLS_NAME => 1 });
    my $used_districts_list = $Maps->districts_list({
      OBJECT_ID   => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" : $FORM{ID} || '_SHOW',
      DISTRICT_ID => $FORM{DISTRICT_ID} || '_SHOW',
      DISTRICT    => '_SHOW',
      LIST2HASH   => 'object_id,district_id'
    });
    my @used_districts_ids = ();
    
    foreach (@{$used_districts_list}) {
      my $t = $Maps->polygons_list({ OBJECT_ID => $_->{object_id} });
      next if !$Maps->{TOTAL};

      push(@used_districts_ids, $_->{district_id});
    }

    my $not_used_districts_list = ();

    foreach (@{$districts}) {
      next if in_array($_->{id}, \@used_districts_ids);
      push @{$not_used_districts_list}, $_;
    }

    $TEMPLATE_ARGS{DISTRICT_ID_SELECT} = $html->form_select("DISTRICT_ID", {
      SELECTED    => $TEMPLATE_ARGS{DISTRICT_ID},
      SEL_LIST    => $not_used_districts_list,
      SEL_OPTIONS => { '' => '--' },
      NO_ID       => 1
    });
    $TEMPLATE_ARGS{COLOR} ||= '#ffffff';

    $html->tpl_show(_include('maps2_district', 'Maps2'), {
      %TEMPLATE_ARGS,
      %FORM,
      SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
      SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
    });
  }

  return 1 if ($FORM{TEMPLATE_ONLY});

  my Abills::HTML $table;
  ($table) = result_former({
    INPUT_DATA      => $Maps,
    FUNCTION        => 'districts_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'DISTRICT_ID,DISTRICT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_FIELDS      => 0,
    EXT_TITLES      => {
      district_id => '#',
      district    => $lang{DISTRICT},
      object_id   => $lang{MAP},
    },
    FILTER_VALUES   => {
      district_id => sub {
        my ($district_id, $line) = @_;
        $line->{id} = $district_id;
        return $district_id;
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DISTRICTS},
      ID      => 'DISTRICTS_TABLE'
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Maps2',
  });

  print $table->show();

  return 1;
}

#**********************************************************
=head2 maps2_wifis_show($attr)

=cut
#**********************************************************
sub maps2_wifis_show {
  my ($attr) = @_;

  my $list_wifi_objects = _maps2_get_layer_objects(2, {
    ID        => $FORM{ID} || '_SHOW',
    OBJECT_ID => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" : '_SHOW',
    COLS_NAME => 1
  });

  if ($attr->{ONLY_COUNT}) {
    my $count = @{$list_wifi_objects};
    return $count;
  }

  my @export_arr = ();

  foreach my $wifi (@{$list_wifi_objects}) {
    if ($wifi->{POLYGON}) {
      $wifi->{POLYGON}->{NAME} ||= '';
      my $points_json = JSON::to_json($wifi->{POLYGON}->{POINTS});
      $wifi->{OBJECT_ID} ||= 0;
      my $info = qq{
            {
                "ID"        : $wifi->{POLYGON}->{ID},
                "OBJECT_ID" : $wifi->{OBJECT_ID},
                "POLYGON"   : {
                    "OBJECT_ID" : $wifi->{OBJECT_ID},
                    "ID"        : $wifi->{OBJECT_ID},
                    "LAYER_ID"  : 2,
                    "POINTS"    : $points_json,
                    "NAME"      : "$wifi->{POLYGON}->{NAME}",
                    "COLOR"     : "$wifi->{POLYGON}->{COLOR}"
                },
                "LAYER_ID"  : 2
            }
      };
      push @export_arr, $info;
    }

  }

  if ($FORM{RETURN_JSON}) {
    print "[" . join(", ", @export_arr) . "]";
    return 1;
  }

  return join(", ", @export_arr);
}


#**********************************************************
=head2 maps2_location_info($attr) - Returns geolocation information about object

  Arguments:
    $attr
      LOCATION_ID   - location id
      TYPE          - map object type

  Returns:
    hash_ref
      HTML  - content for infowindow
      count - numeric label for marker

=cut
#**********************************************************
sub maps2_location_info {
  my ($attr) = @_;
  return unless ($attr->{LOCATION_ID});
  $attr->{TYPE} ||= 'BUILD';

  my $info = '';
  my $count = 0;
  my $color = '';

  CORE::state $users_for_location_id;
  CORE::state $online_uids;
  if (!$online_uids) {
    $online_uids = _maps2_get_online_users({ SHORT => 1 });
  }
  if (!$users_for_location_id) {
    my $users_list = _maps2_get_users({ RETURN_AS_ARRAY => 1 });
    foreach my $user (@{$users_list}) {
      next unless $user->{build_id};

      my $location_id = $user->{build_id};

      if (exists $online_uids->{$user->{uid}}) {
        $user->{online} = 1;
      }

      # Sort to hash_ref of  array_refs
      if ($users_for_location_id->{$location_id}) {
        push(@{$users_for_location_id->{$location_id}}, $user);
      }
      else {
        $users_for_location_id->{$location_id} = [ $user ];
      }
    }
  }

  if (defined $users_for_location_id->{ $attr->{LOCATION_ID} }) {
    $info = maps2_point_info_table({
      OBJECTS           => $users_for_location_id->{ $attr->{LOCATION_ID} },
      TABLE_TITLES      => [ 'ONLINE', 'LOGIN', 'DEPOSIT', 'FIO', 'ADDRESS_FLAT' ],
      TABLE_LANG_TITLES => [ $lang{ONLINE}, $lang{LOGIN}, $lang{DEPOSIT}, $lang{FIO}, $lang{FLAT} ],
      TO_SCREEN         => $attr->{TO_SCREEN}
    });
    $count = scalar @{$users_for_location_id->{ $attr->{LOCATION_ID} }};

    if ($conf{MAPS_BUILD_COLOR_BY_ONLINE}) {
      $color = (grep {$_->{online} && $_->{online} == 1} @{$users_for_location_id->{ $attr->{LOCATION_ID} }}) ? 'green' : 'red'
    }

  }
  elsif ($FORM{GROUP_ID}) {
    return 0;
  }

  return {
    HTML  => $info,
    COUNT => $count,
    COLOR => $color
  }

}

#**********************************************************

=head2 maps2_info_modules_list()

=cut

#**********************************************************
sub maps2_info_modules_list {

  my @result_list = ();

  our @MAPS_INFO_MODULES;
  my @ext_modules = ('Msgs', 'Maps', 'Equipment', @MAPS_INFO_MODULES);

  foreach my $module_name (@ext_modules) {
    load_module($module_name, $html);
    my $fn_name = lc($module_name . "_location_info");
    if (defined &{$fn_name}) {

      push(@result_list, $module_name);
    }
  }

  return \@result_list;
}


#**********************************************************
=head2 maps2_load_info($attr) - Loads information for location from specified module

  Arguments:
    $attr - hash_ref
      LOCATION_ID   - location id
      TYPE          - map object type

  Returns:
    hash_ref
      HTML  - Infowindow content
      COUNT - count for object

=cut

#**********************************************************
sub maps2_load_info {

  my $module_name = $FORM{INFO_MODULE} || 'Maps2';

  my $fn_name = lc "$module_name\_location_info";
  load_module($module_name, $html) if (!defined &{$fn_name});

  return {} if !(defined &{$fn_name});

  my $result = &{\&{$fn_name}}(@_);
  if ($result && $result->{HTML}) {
    $result->{HTML} =~ s/\n/ /gm;
    $result->{HTML} =~ s/\+"+/'/gm;
    return $result;
  }

  return {};
}

#**********************************************************
=head2 maps2_add_external_points($attr)

  Arguments:

  Returns:

=cut

#**********************************************************
sub maps2_add_external_points {

  return 0 if !$FORM{POINT_ID} || !$FORM{COORDX} || !$FORM{COORDY};

  $Maps->points_change({
    ID     => $FORM{POINT_ID},
    COORDX => $FORM{COORDX},
    COORDY => $FORM{COORDY},
  });

  return 0;
}

#**********************************************************

=head2 _maps2_points_count($list, $object_info, $attr) - Counts points

  Arguments:
    $list - arr_ref for DB list
    $object_info - DB list
    $attr - hash_ref
      KEY    - string, key for which to count

  Returns:
    arr_ref - array that contains sorted count

=cut

#**********************************************************
sub _maps2_points_count {
  my ($list, $object_info, $attr) = @_;
  my $key = (defined $attr->{KEY}) ? $attr->{KEY} : 'id';

  my %max_objects_on_point = ();
  foreach my $line (@{$list}) {
    if ($object_info->{ $line->{$key} }) {
      $max_objects_on_point{ $line->{$key} } = $#{$object_info->{ $line->{$key} }} + 1;
    }
  }

  my @max_arr = sort {$b <=> $a} values %max_objects_on_point;

  return \@max_arr;
}

#**********************************************************

=head2 _maps2_point_color($point_count, $max_points) - get color for point

  Arguments:
    $point_count  - Point object count
    $max_points   - Points max objects

  Returns:
    string - color name

=cut

#**********************************************************
sub _maps2_point_color {
  my ($point_count, $max_points) = @_;

  my $color = 'grey';

  return $color unless ($point_count);

  #Fire for top 3
  if ($point_count > 2 && $max_points->[2] && $point_count >= $max_points->[2]) {
    $color = 'fire';
  }

  #Other points by colors
  elsif ($point_count > 0 && $point_count < 3) {
    $color = 'grey';
  }
  elsif ($point_count < 5) {
    $color = 'green';
  }
  elsif ($point_count < 10) {
    $color = 'blue';
  }
  elsif ($point_count >= 10) {
    $color = 'yellow';
  }

  return $color;
}

#**********************************************************
=head2 _maps_get_custom_point_icon()

=cut
#**********************************************************
sub _maps2_get_custom_point_icon {
  my ($icon) = @_;

  if ($icon !~ /^https?\:\/\//o) {
    my $has_extension = $icon =~ /\.\w{3,4}$/o;

    if ($has_extension) {
      $icon =~ s/\.\w{3,4}$//;
    }
  }

  return $icon;
}

#**********************************************************
=head2 _maps2_get_layer_objects()

=cut
#**********************************************************
sub _maps2_get_layer_objects {
  my ($layer_id, $attr) = @_;

  my @main_object_types = qw/circle polygon polyline/;
  my %have_points = (polygon => 1, polyline => 1);

  my @OBJECTS = ();
  foreach my $object_type (@main_object_types) {
    my $func_name = $object_type . 's_list';

    my $this_type_objects_list = $Maps->$func_name({
      LAYER_ID         => $layer_id,
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER       => 1,
      OBJECT_ID        => $attr->{ID} || '_SHOW',
      PAGE_ROWS        => 10000
    });

    next if (!is_not_empty_array_ref($this_type_objects_list));

    if ($have_points{$object_type}) {
      my $points_func_name = $object_type . '_points_list';
      my $parent_id_name = uc($object_type . '_id');

      foreach my $map_object_row (@{$this_type_objects_list}) {
        my $points_list = $Maps->$points_func_name({
          $parent_id_name => $map_object_row->{id},
          COORDX          => '_SHOW',
          COORDY          => '_SHOW',
          COLS_UPPER      => 0,
          PAGE_ROWS       => 10000
        });

        $map_object_row->{POINTS} = [ map {[ +$_->{coordx}, +$_->{coordy} ]} @{$points_list} ];
      }
    }

    push(@OBJECTS, map {{
      uc($object_type) => $_,
      LAYER_ID         => $layer_id,
      OBJECT_ID        => $_->{object_id}
    }} @{$this_type_objects_list});
  }

  return \@OBJECTS;
}

#**********************************************************
=head2 _maps2_get_old_builds($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _maps2_get_old_builds {
  my ($attr, $count_object, $export_hash_arr, $object_info, $to_screen) = @_;

  my $builds_list = $Address->build_list({
    DISTRICT_ID        => $FORM{DISTRICT_ID} || '>0',
    DISTRICT_NAME      => '_SHOW',
    %LIST_PARAMS,
    NUMBER             => '_SHOW',
    PUBLIC_COMMENTS    => '_SHOW',
    PLANNED_TO_CONNECT => '_SHOW',
    STREET_NAME        => '_SHOW',
    COORDX             => '!',
    COORDY             => '!',
    ZOOM               => '_SHOW',
    COLS_NAME          => 1,
    PG                 => '0',
    PAGE_ROWS          => 10000,
    LOCATION_ID        => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" :
      $attr->{ID} || $FORM{OBJECT_ID} || $attr->{LOCATION_ID} || '_SHOW'
  });

  $$count_object += $Address->{TOTAL} if $Address->{TOTAL};

  my $count_array = _maps2_points_count($builds_list, $object_info);

  foreach my $build (@{$builds_list}) {
    last if ($attr->{ONLY_COUNT});

    next if $attr->{BUILD_IDS} && !in_array($build->{id}, $attr->{BUILD_IDS});

    my $info_hash = {};
    my $point_count = 0;

    $info_hash = maps2_load_info({ LOCATION_ID => $build->{id}, TO_SCREEN => $to_screen }) if !$attr->{CLIENT_MAP};
    $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);

    next if ($FORM{GROUP_ID} && !$info_hash->{HTML});

    my $color = $info_hash->{COLOR} || _maps2_point_color($point_count, $count_array);
    my $address_full = ($build->{district_name} || '') . ' ,' . ($build->{street_name} || '') . ' ,' . ($build->{number} || '');

    my $info_table = $info_hash->{HTML} || q{};

    # REVERSE COORDS
    my %regex = (
      ID        => $build->{location_id},
      OBJECT_ID => $build->{location_id},
      MARKER    => {
        ID        => $build->{location_id},
        OBJECT_ID => $build->{id},
        NAME      => $address_full,
        COORDX    => $build->{coordy},
        COORDY    => $build->{coordx},
        TYPE      => "build_$color",
        INFO      => $info_table,
        COUNT     => $point_count,
        LAYER_ID  => LAYER_ID_BY_NAME->{BUILD},
      },
      ADDRESS   => $address_full,
      LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD} ]}
    );

    push @{$export_hash_arr}, \%regex;
  }

  return 0;
}

#**********************************************************
=head2 _maps2_get_new_builds($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub _maps2_get_new_builds {
  my ($attr, $count_object, $export_hash_arr, $object_info) = @_;

  my $coords_list = $Maps->points_list({
    COORDX       => '!',
    COORDY       => '!',
    TYPE_ID      => 3,
    LOCATION_ID  => $FORM{LAST_OBJECT_ID} ? "> $FORM{LAST_OBJECT_ID}" : '_SHOW',
    ADDRESS_FULL => '_SHOW',
    ID           => '_SHOW',
  });

  $$count_object += $Maps->{TOTAL} if $Maps->{TOTAL};

  my $count_array = _maps2_points_count($coords_list, $object_info);

  foreach my $build (@{$coords_list}) {

    last if ($attr->{ONLY_COUNT});
    next if (!$build->{location_id});

    my $info_hash = {};
    my $point_count = 0;

    if (!$attr->{CLIENT_MAP}) {
      $info_hash = maps2_load_info({ LOCATION_ID => $build->{location_id} });
      $point_count = $info_hash->{COUNT} || (($count_array && ref $count_array eq 'ARRAY') ? scalar @{$count_array} : 0);
    }

    next if ($FORM{GROUP_ID} && !$info_hash->{HTML});

    my $color = $info_hash->{COLOR} || _maps2_point_color($point_count, $count_array);
    my $address_full = $build->{address_full} || q{};

    my $info_table = $info_hash->{HTML} || q{};

    my %regex = (
      ID        => $build->{location_id},
      OBJECT_ID => $build->{location_id},
      MARKER    => {
        ID        => $build->{location_id},
        OBJECT_ID => $build->{id},
        NAME      => $address_full,
        COORDX    => $build->{coordx},
        COORDY    => $build->{coordy},
        TYPE      => "build_$color",
        INFO      => $info_table,
        LAYER_ID  => LAYER_ID_BY_NAME->{BUILD},
        COUNT     => $point_count
      },
      ADDRESS   => $address_full,
      LAYER_ID  => @{[ LAYER_ID_BY_NAME->{BUILD} ]}
    );

    push @{$export_hash_arr}, \%regex;
  }

  return 0;
}

1;