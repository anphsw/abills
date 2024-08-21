package Accident::Configure;

=head1 NAME

  Accident configuration functions

  ERROR ID: 101ХХХХ

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;

use Control::Errors;
use Accident;

my Control::Errors $Errors;
my Accident $Accident;

#**********************************************************
=head2 new($db, $conf, $admin, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  bless($self, $class);
  $Accident = Accident->new($db, $admin, $conf);
  $Errors = Control::Errors->new($db, $admin, $conf, { lang => $self->{lang}, module => 'Accident' });

  return $self;
}

#**********************************************************
=head2 accident_add($attr)

=cut
#**********************************************************
sub accident_add {
  my $self = shift;
  my ($attr) = @_;

  $Accident->add($attr);
  return $Accident if $Accident->{errno};

  my $accident_id = $Accident->{INSERT_ID};
  $Accident->address_add({ %{$attr}, AC_ID => $accident_id });

  $self->_notify_admin_by_address($accident_id);
  return $Accident;
}

#**********************************************************
=head2 _notify_admin_by_address($accident_id) - Notify administrators about an accident based on their proximity to the accident site

  Arguments:
    $accident_id   - A scalar representing the ID of the accident.

  Returns:
   $self - The object reference for method chaining.

  Example:

    $self->_notify_admin_by_address($accident_id);

=cut
#**********************************************************
sub _notify_admin_by_address {
  my $self = shift;
  my $accident_id = shift;

  return $self if !in_array('GPS', \@main::MODULES);

  return $self if !$accident_id;

  my $accident_info = $Accident->info($accident_id);
  return $self if !$Accident->{TOTAL} || $Accident->{TOTAL} < 1 || !$Accident->{TYPE};

  my $builds = $Accident->accident_builds($accident_id);
  my %address_list = ();

  foreach my $build (@{$builds}) {
    next if !$build->{address_id};

    push @{$address_list{$build->{address_id}}}, $build;
  }

  my $address_hulls = [];
  
  foreach my $address (keys(%address_list)) {
    my @hulls = _accident_convex_hull(@{$address_list{$address}});
    push @{$address_hulls}, \@hulls;
  }

  my $admins = $Accident->admin_list({
    ACCIDENT_TYPE => $Accident->{TYPE},
    ADMIN_DISABLE => '0',
    AID           => '_SHOW',
    GROUP_BY      => '',
    COLS_NAME     => 1
  });

  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  require GPS;
  GPS->import();
  my $Gps = GPS->new($self->{db}, $self->{admin}, $self->{conf});
  my $radius = $self->{conf}{ACCIDENT_RADIUS_NOTIFY} || 20;

  foreach my $admin_info (@{$admins}) {
    my $last_location = $Gps->tracked_admin_info($admin_info->{aid});
    next if !$Gps->{TOTAL} || $Gps->{TOTAL} < 1;

    my $notify = 0;
    foreach my $hulls (@{$address_hulls}) {
      if (scalar(@{$hulls}) < 3) {
        foreach my $point (@{$hulls}) {
          my $distance = _haversine($point, {
            coordx => $last_location->{coord_x},
            coordy => $last_location->{coord_y}
          });
          $notify = $distance <= $radius ? 1 : 0;
        }

        last if $notify;
        next;
      }

      $notify = _is_point_in_polygon({
        coordx => $last_location->{coord_x},
        coordy => $last_location->{coord_y}
      }, @{$hulls});

      last if $notify;
    }

    $accident_info->{NAME} //= '';
    $Sender->send_message_auto({
      AID       => $admin_info->{aid},
      TITLE     => $self->{lang}{ACCIDENT_LOG} ? "$self->{lang}{ACCIDENT_LOG}: $accident_info->{NAME}" : $accident_info->{NAME},
      MESSAGE   => $accident_info->{DESCR}
    });
  }
}

#**********************************************************
=head2 _accident_convex_hull(@points) - Calculate Convex Hull for a set of geographical points

  Arguments:
    @points   - An array of hash references, where each hash contains the geographical coordinates
                of a point with keys `coordx` for the longitude and `coordy` for the latitude.

  Returns:
   An array of points representing the convex hull in counter-clockwise order.

  Example:

    my @points = (
      { coordx => 30.123, coordy => 50.456 },
      { coordx => 30.234, coordy => 50.567 },
      { coordx => 30.345, coordy => 50.678 },
      { coordx => 30.456, coordy => 50.789 },
      { coordx => 30.567, coordy => 50.890 },
    );

    my @hull = _accident_convex_hull(@points);

=cut
#**********************************************************
sub _accident_convex_hull {
  my @points = @_;
  my $n = scalar @points;

  return @points if $n < 3;

  my $l = 0;
  for my $i (1 .. $n-1) {
    if ($points[$i]->{coordy} < $points[$l]->{coordy} ||
      ($points[$i]->{coordy} == $points[$l]->{coordy} && $points[$i]->{coordx} < $points[$l]->{coordx})) {
      $l = $i;
    }
  }

  my @hull;
  my $p = $l;
  do {
    push @hull, $points[$p];

    my $q = ($p + 1) % $n;
    for my $i (0 .. $n-1) {
      if (_accident_orientation($points[$p], $points[$i], $points[$q]) == 2) {
        $q = $i;
      }
    }

    $p = $q;
  } while ($p != $l);

  return @hull;
}

#**********************************************************
=head2 _accident_orientation($pointA, $pointB, $pointC) - Determine the orientation of three points

  Arguments:
    $pointA   - A hash reference representing the first point, with keys `coordx` for longitude
                and `coordy` for latitude.
    $pointB   - A hash reference representing the second point, with keys `coordx` for longitude
                and `coordy` for latitude.
    $pointC   - A hash reference representing the third point, with keys `coordx` for longitude
                and `coordy` for latitude.

  Returns:
   An integer representing the orientation of the triplet:
    0 - Collinear
    1 - Clockwise
    2 - Counterclockwise

  Example:

    my $pointA = { coordx => 30.123, coordy => 50.456 };
    my $pointB = { coordx => 30.234, coordy => 50.567 };
    my $pointC = { coordx => 30.345, coordy => 50.678 };

    my $orientation = _accident_orientation($pointA, $pointB, $pointC);

=cut
#**********************************************************
sub _accident_orientation {
  my ($pointA, $pointB, $pointC) = @_;

  my $determinant = ($pointB->{coordx} - $pointA->{coordx}) * ($pointC->{coordy} - $pointB->{coordy}) -
    ($pointB->{coordy} - $pointA->{coordy}) * ($pointC->{coordx} - $pointB->{coordx});

  return 0 if $determinant == 0;
  return ($determinant > 0) ? 1 : 2;
}

#**********************************************************
=head2 _is_point_in_polygon($point, @polygon) - Check if a point is inside a polygon

  Arguments:
    $point     - A hash reference representing the point to check, with keys `coordx` for longitude
                 and `coordy` for latitude.
    @polygon   - An array of hash references representing the vertices of the polygon, where each
                 hash contains the coordinates of a vertex with keys `coordx` for longitude
                 and `coordy` for latitude.

  Returns:
   A boolean value indicating whether the point is inside the polygon (1 for true, 0 for false).

  Example:

    my $point = { coordx => 30.345, coordy => 50.678 };

    my @polygon = (
      { coordx => 30.123, coordy => 50.456 },
      { coordx => 30.234, coordy => 50.567 },
      { coordx => 30.345, coordy => 50.678 },
      { coordx => 30.456, coordy => 50.789 },
    );

    my $is_inside = _is_point_in_polygon($point, @polygon);

=cut
#**********************************************************
sub _is_point_in_polygon {
  my $point = shift;
  my @polygon = @_;

  my $x = $point->{coordx};
  my $y = $point->{coordy};

  my $inside = 0;
  my $n = @polygon;

  for (my $i = 0, my $j = $n - 1; $i < $n; $j = $i++) {
    my ($xi, $yi) = ($polygon[$i]->{coordx}, $polygon[$i]->{coordy});
    my ($xj, $yj) = ($polygon[$j]->{coordx}, $polygon[$j]->{coordy});

    my $intersect = (($yi > $y) != ($yj > $y)) &&
      ($x < ($xj - $xi) * ($y - $yi) / ($yj - $yi) + $xi);
    $inside = !$inside if $intersect;
  }

  return $inside;
}

#**********************************************************
=head2 _haversine($first_point, $second_point) - Calculate the great-circle distance between two points on Earth using the Haversine formula

  Arguments:
    $first_point   - A hash reference representing the first geographical point, with keys `coordx`
                     for longitude and `coordy` for latitude.
    $second_point  - A hash reference representing the second geographical point, with keys `coordx`
                     for longitude and `coordy` for latitude.

  Returns:
   A numerical value representing the distance in kilometers between the two points.
   Returns -1 if the input is invalid.

  Example:

    my $pointA = { coordx => 30.123, coordy => 50.456 };
    my $pointB = { coordx => 30.234, coordy => 50.567 };

    my $distance = _haversine($pointA, $pointB);

=cut
#**********************************************************
sub _haversine {
  my $first_point = shift;
  my $second_point = shift;

  return -1 if !$first_point || ref($first_point) ne 'HASH';
  return -1 if !$second_point || ref($second_point) ne 'HASH';

  my $EARTH_RADIUS_KM = 6371;

  my $phi1 = deg2rad($first_point->{coordy});
  my $phi2 = deg2rad($second_point->{coordy});
  my $delta_phi = deg2rad($second_point->{coordy} - $first_point->{coordy});
  my $delta_lambda = deg2rad($second_point->{coordx} - $first_point->{coordx});

  my $haversine_formula = sin($delta_phi / 2) ** 2 + cos($phi1) * cos($phi2) * sin($delta_lambda / 2) ** 2;
  my $central_angle = 2 * atan2(sqrt($haversine_formula), sqrt(1 - $haversine_formula));

  return $EARTH_RADIUS_KM * $central_angle;
}

#**********************************************************
=head2 deg2rad($deg) - Convert degrees to radians

  Arguments:
    $deg   - A numerical value representing an angle in degrees.

  Returns:
   A numerical value representing the angle in radians.

  Example:

    my $radians = deg2rad(180);  # Returns 3.141592653589793

=cut
#**********************************************************
sub deg2rad {
  my ($deg) = @_;

  return $deg * (3.141592653589793 / 180);
}

1;