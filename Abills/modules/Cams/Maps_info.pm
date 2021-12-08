package Cams::Maps_info;

=head1 NAME

  Cams::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20201021

=cut

use strict;
use warnings FATAL => 'all';
use parent qw(Exporter);

our $VERSION = 1.00;

our (
  $admin,
  $CONF,
  $lang,
  $html,
  $db
);
my $Cams;

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  require Cams;
  Cams->import();
  $Cams = Cams->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS      => [ {
      id              => '33',
      name            => 'CAMS',
      lang_name       => $lang->{CAMERAS},
      module          => 'Cams',
      structure       => 'MARKER',
      clustering      => 1,
      export_function => 'cams_maps'
    }, {
      id              => '34',
      name            => 'CAMS_REVIEW',
      lang_name       => $lang->{CAMS_REVIEW},
      module          => 'Cams',
      structure       => 'POLYGON',
      clustering      => 1,
      export_function => 'cams_maps_review'
    } ]
  }
}

#**********************************************************
=head2 cams_cams_maps()

=cut
#**********************************************************
sub cams_maps {
  my $self = shift;
  my ($attr) = @_;

  my $cameras = $Cams->streams_list({
    POINT_ID       => $attr->{OBJECT_ID} || $attr->{POINT_ID} || '!',
    NAME           => '_SHOW',
    TITLE          => '_SHOW',
    GROUP_NAME     => '_SHOW',
    SERVICE_NAME   => '_SHOW',
    HOST           => '_SHOW',
    ANGEL          => '_SHOW',
    LOCATION_ANGEL => '_SHOW',
    LENGTH         => '_SHOW',
    FOLDER_NAME    => '_SHOW',
    PAGE_ROWS      => 10000
  });

  require Maps;
  Maps->import();
  my $Maps = Maps->new($db, $admin, $CONF);

  my @object_ids = map {+$_->{point_id}} @{$cameras};
  my $point_ids = join(';', @object_ids);
  my $points_list = $Maps->points_list({ ID => $point_ids, SHOW_ALL_COLUMNS => 1, EXTERNAL => 1, PAGE_ROWS => 10000 });

  my %point_id_to_id = ();
  foreach my $camera (@{$cameras}) {
    $point_id_to_id{$camera->{point_id}} = $camera;
  }

  my @export_arr = ();
  foreach my $point (@{$points_list}) {
    next if (!$point->{coordy} || !$point->{coordx} || !$point_id_to_id{$point->{id}});

    my $group_lng = $lang->{CAMS_GROUP};
    my $group_value = $point_id_to_id{$point->{id}}{group_name} || '';

    if ($point_id_to_id{$point->{id}}{folder_name}) {
      $group_lng = $lang->{FOLDER};
      $group_value = $point_id_to_id{$point->{id}}{folder_name};
    }

    my $index = ::get_function_index("cams_main");
    my $link = "$lang->{CAM}:<a href='index.cgi?index=$index&chg_cam=$point_id_to_id{$point->{id}}{id}' target='_blank'> $point->{name}</a>";
    my $tb = "<div class='panel panel-info'>" .
      "<div class='panel-heading'><h3 class='panel-title'>$link</h3></div>" .
      "<ul class='list-group'>" .
      "<li class='list-group-item'>$lang->{NAME}: $point_id_to_id{$point->{id}}{name}</li>" .
      "<li class='list-group-item'>$lang->{CAM_TITLE}: $point_id_to_id{$point->{id}}{title}</li>" .
      "<li class='list-group-item'>$lang->{SERVICE}: $point_id_to_id{$point->{id}}{service_name}</li>" .
      "<li class='list-group-item'>$group_lng: $group_value</li>" .
      "<li class='list-group-item'>Host: $point_id_to_id{$point->{id}}{host}</li>" .
      "</ul>" .
      "</div>";
    my $info = "<div class='panel-group'>$tb</div>";

    my %marker = (
      MARKER   => {
        ID       => $point->{id},
        COORDX   => $point->{coordx},
        COORDY   => $point->{coordy},
        INFO     => $info,
        TYPE     => "cams_main",
        NAME     => $point_id_to_id{$point->{id}}{name},
        POINT_ID => $point_id_to_id{$point->{id}}{point_id}
      },
      LAYER_ID => 33,
      POINT_ID => $point_id_to_id{$point->{id}}{point_id}
    );

    push @export_arr, \%marker;
  }

  my $count = @export_arr;
  return $count if $attr->{ONLY_TOTAL};


  my $export_string = JSON::to_json(\@export_arr, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 cams_maps_review()

=cut
#**********************************************************
sub cams_maps_review {
  my $self = shift;
  my ($attr) = @_;

  my $cameras = $Cams->streams_list({
    POINT_ID       => $attr->{OBJECT_ID} || $attr->{POINT_ID} || '!',
    NAME           => '_SHOW',
    TITLE          => '_SHOW',
    GROUP_NAME     => '_SHOW',
    SERVICE_NAME   => '_SHOW',
    HOST           => '_SHOW',
    LENGTH         => '_SHOW',
    ANGEL          => '_SHOW',
    LOCATION_ANGEL => '_SHOW',
    PAGE_ROWS      => 10000
  });

  require Maps;
  Maps->import();
  my $Maps = Maps->new($db, $admin, $CONF);

  my @object_ids = map {+$_->{point_id}} @{$cameras};
  my $point_ids = join(';', @object_ids);

  my $points_list = $Maps->points_list({ ID => $point_ids, SHOW_ALL_COLUMNS => 1, EXTERNAL => 1, PAGE_ROWS => 10000 });

  my %point_id_to_id = ();
  foreach my $camera (@{$cameras}) {
    $point_id_to_id{$camera->{point_id}} = $camera;
  }

  my @export_arr = ();

  foreach my $point (@{$points_list}) {
    next if (!$point->{coordy} || !$point->{coordx} || !$point_id_to_id{$point->{id}}{angel} || !$point_id_to_id{$point->{id}}{length});

    my %review = (
      SEMICIRCLE => {
        ID             => "REVIEW_$point->{id}",
        COORDX         => $point->{coordx},
        COORDY         => $point->{coordy},
        NAME           => "$lang->{CAMS_REVIEW}: $point_id_to_id{$point->{id}}{name}",
        LENGTH         => $point_id_to_id{$point->{id}}{length},
        ANGEL          => $point_id_to_id{$point->{id}}{angel},
        LOCATION_ANGEL => $point_id_to_id{$point->{id}}{location_angel}
      },
      LAYER_ID   => 34
    );

    push @export_arr, \%review;
  }

  my $count = @export_arr;
  return $count if $attr->{ONLY_TOTAL};

  my $export_string = JSON::to_json(\@export_arr, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

1;