package Abills::Radius_Pairs;

use strict;

#**********************************************************
=head2 build_radius_params_result_response($module)

  Arguments:
    $module
  Results:
    $result

=cut
#**********************************************************
sub build_radius_params_result_response {
  my ($module) = @_;

  my $errno = $module->{errno} || 0;
  my $err_str = $module->{err_str} || '';

  return << "[END]";
  {
      "status": $errno,
      "message": "$err_str"
    }
[END]
}


#**********************************************************
=head2 parse_radius_params_json($pairs_json)

  Arguments:
    $pairs_json
  Results:
    $radius_pairs_string

=cut
#**********************************************************
sub parse_radius_params_json {
  my ($pairs_json) = @_;

  if(!$pairs_json) {
    return '';
  }

  $pairs_json =~ s/\\//xg;
  $pairs_json =~ s/’/'/xg;

  require JSON;
  my $json = JSON->new()->utf8(0);

  my $radius_pairs = $json->decode($pairs_json);
  my $radius_pairs_string = build_radius_params_string($radius_pairs);

  return $radius_pairs_string;
}


#**********************************************************
=head2 parse_radius_params_string($radius_pairs_string)

  Arguments:
    $radius_pairs_string
  Results:
    pairs

=cut
#**********************************************************
sub parse_radius_params_string {
  my ($radius_pairs_string) = @_;

  if(!$radius_pairs_string) {
    return '[]';
  }

  my @pairs = split(", \n", $radius_pairs_string);
  my $rad_pairs_expr = q/([0-9a-zA-Z\-:!]+)([-+=<>]{1,2})([:\-_\;\(\,\)\\'\\’\"\#=\s0-9a-zA-Zа-яА-Я.]+)/;
  foreach my $pair (@pairs) {
    my @pair_parts = $pair =~ /$rad_pairs_expr/xm;

    if(scalar @pair_parts != 3) {
      next;
    }

    my $is_ignored = substr($pair_parts[0], 0, 1 ) eq '!';

    if($is_ignored) {
      $pair_parts[0] = substr($pair_parts[0], 1)
    }

    $pair = {
      left => $pair_parts[0],
      condition => $pair_parts[1],
      right => $pair_parts[2],
      ignore => $is_ignored ? 1 : 0,
    }
  }

  require JSON;
  JSON->import();
  my $json = JSON->new()->utf8(0);

  return $json->encode(\@pairs);
}


#**********************************************************
=head2 build_radius_params_string($pairs)

  Arguments:
    $pairs
  Results:
    $params_string

=cut
#**********************************************************
sub build_radius_params_string {
  my ($pairs) = @_;
  my $params_string = '';

  foreach my $pair (@{ $pairs }) {
    if($pair->{ignore} || !$pair->{left} || !$pair->{right}) {
      $params_string .= '!';
    }

    $params_string .= $pair->{left} || 'LEFT_PART';
    $params_string .= $pair->{condition} || '=';
    $params_string .= defined($pair->{right}) ? $pair->{right} : 'RIGHT_PART';

    $params_string .= ", \n";
  }

  return substr($params_string, 0, -3);
}

1;