package Maps::GMA;

=name Google Maps Geocoding API

  https://developers.google.com/maps/documentation/geocoding/intro

  https://developers.google.com/maps/documentation/geocoding/get-api-key

=cut
use strict;
use warnings FATAL => 'all';

my $admin;
my %CONF = ();

use lib "mysql";
use parent "main";

use Abills::mysql::Address;

use Abills::Base qw(_bp);
do "Abills/Misc.pm";

use JSON;

my $Address = { };

my $api_link = 'http://maps.googleapis.com/maps/api/geocode/json';

#**********************************************************
=head2 new($db, $admin, \%conf) - constructor for Google Maps Api

  Attributes:
    $db, $admin, \%conf -

  Returns:
    object - new Google Maps Api instance

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin_, $CONF_) = @_;

  $admin = $admin_;
  %CONF = %{$CONF_};
  $Address = Address->new( @_ ); # $Address_;

  my $self = { };
  bless( $self, $class );

  $self->{db} = $db;
  $self->{key} = $CONF{GOOGLE_API_KEY} || '';

  return $self;
}

#**********************************************************
=head2 get_unfilled_addresses()

  Returns:
    list

=cut
#**********************************************************
sub get_unfilled_addresses {
  my $self = shift;
  my ($attr) = @_;

  # Ignore district names if they are not real geographic names (e.g in small city)
  my $districts_are_not_real = $attr->{DISTRICTS_ARE_NOT_REAL};

  my $build_list = $Address->build_list( {
      COORDX          => '0',
      COORDY          => '0',
      STREET_NAME     => '_SHOW',
      DISTRICT_ID     => '_SHOW',
      SHOW_GOOGLE_MAP => 1,
      COLS_NAME       => 1,
      PAGE_ROWS       => 10000
    } );

  my %districts_by_id = ();
  my $districts_list = $Address->district_list( { COLS_NAME => 1 } );

  my @districts_list = ();
  @districts_list = @{ $districts_list } if (defined $districts_list);
  foreach my $district ( @districts_list ) {
    $districts_by_id{$district->{id}} = $district;
  }

  my %streets_by_id = ();
  my $streets_list = $Address->street_list( { COLS_NAME => 1 } );

  my @streets_list = ();
  @streets_list = @{ $streets_list } if (defined $streets_list);
  foreach my $street ( @streets_list ) {
    $streets_by_id{$street->{id}} = $street;
  }

  my @builds_without_coords = ();

  #Compressing all needed data in one hash
  foreach my $build ( @{$build_list} ) {

    # Dealing with broken DB
    # Check if street for build exists
    next if (!exists $streets_by_id{$build->{street_id}});

    # Check if district for this build exists
    next if (!exists $districts_by_id{$build->{district_id}});

    my $district = $districts_by_id{ $build->{district_id} };

    my $district_name = $districts_are_not_real ? '' : ($district->{name} || '') . ", ";
    my $street_name = $build->{street_name};

    $build->{country} = $district->{country};
    $build->{city} = $district->{city} || '';
    $build->{district_name} = $district->{name} || '';
    $build->{postalCode} = $district->{zip};

    $build->{full_address} = "$build->{city}, $district_name$street_name, $build->{number}";

    push( @builds_without_coords, $build );
  }

  return \@builds_without_coords;
}

#**********************************************************
=head2 get_coords_for($build) - returns coordinates for build

  See Returns for details

  Arguments:
    $build - build hash
      full_address - address name

  Returns:
    HASH
      STATUS - Status of response. 1 is "OK"
      COORDX - longitude
      COORDY - latitude
      formatted_address - Forrmatted address returned by Google API
      requested_address - address as it was sended to Google API

  Responce from Google API can contain multiple results. In this case returns:
    HASH
      STATUS - integer
      requested_address - address as it was sended to Google API
      formatted_address - Forrmatted address returned by Google API
      COORDS [
        COORDX, - longitude
        COORDY  - latitude
      ]

=cut
#**********************************************************
sub get_coords_for {
  my $self = shift;
  my ($requested_addr, $build_id, $attr) = @_;

  # For free usage, Geocoding API receives one request in 1.5 seconds;
  unless ($CONF{MAPS_NO_THROTTLE}) {
    sleep 2;
  }

  my $responce = web_request( $api_link, {
      REQUEST_PARAMS =>
      {
        address => $requested_addr,
        key     => $self->{key}
      },
      GET            => 1,
    } );

  my $result = '';
  eval { $result = JSON->new->utf8->decode( $responce )};
  if ( $@ ) {
    my ($error_str) = $@ =~ /\(before \"\(.*\)\"\)/;

    unless ($error_str){
      $error_str = $@;
    }

    if ($error_str =~ /Timeout/){
      $error_str = 'Timeout';
    }

    return {
      STATUS => 500,
      ERROR  => $error_str
    };
  }


  # Return status 2 on fail
  unless ( defined $result->{status} && $result->{status} eq "OK" ) {
    return { STATUS => 2, BUILD_ID => $build_id, requested_address => $requested_addr };
  }

  my @results_shortcut = @{$result->{results}};

  # Handle multiple results
  unless ( scalar @results_shortcut == 1 ) {
    my @non_unique_results = ();

    # Clear all non ROOFTOP results
    my $rooftop_counter = 0;
    for ( my $i = 0; $i < scalar @results_shortcut; $i++ ) {
      if ( $results_shortcut[$i]->{geometry}->{location_type} eq 'ROOFTOP' ) {
        $rooftop_counter++;
      }
      else {
        splice( @results_shortcut, $i--, 1 );
      }
    };

    if ( scalar @results_shortcut > 0 && $rooftop_counter > 1 ) {
      foreach my $coord ( @results_shortcut ) {
        my %res = ();
        $res{COORDX} = $coord->{geometry}->{location}->{lng};
        $res{COORDY} = $coord->{geometry}->{location}->{lat};
        $res{formatted_address} = $coord->{formatted_address};

        push ( @non_unique_results, \%res );
      }

      return {
        STATUS            => 3,
        BUILD_ID          => $build_id,
        requested_address => $requested_addr,
        RESULTS           => \@non_unique_results
      };
    }
  }

  unless ( defined $results_shortcut[0]->{geometry}->{location_type} && $results_shortcut[0]->{geometry}->{location_type} eq 'ROOFTOP' ) {
    return { STATUS => 4, BUILD_ID => $build_id, requested_address => $requested_addr };
  }

  my $coords = $results_shortcut[0]->{geometry}->{location};

  return {
    STATUS            => 1,
    BUILD_ID          => $build_id,
    COORDX            => $coords->{lng},
    COORDY            => $coords->{lat},
    formatted_address => $results_shortcut[0]->{formatted_address},
    requested_address => $requested_addr
  }
};

1;