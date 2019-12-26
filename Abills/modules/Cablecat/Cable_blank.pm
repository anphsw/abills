=head1 NAME

  Cable_blank

=cut

use strict;
use warnings;
use GD::Simple;
use Cablecat::db::Commutation_blank;
use utf8;
use Abills::Base qw(_bp in_array);
use Cablecat;

our ($html, %FORM, $db, %conf, $admin, %lang);

my $Commutation = Commutation_blank->new($db, $admin, \%conf);
my ($y1_first, $y1_second) = (40, 40);
my (%cable_box, %cross_array, %equipment_array) = ();
my (%cable_sides, %cross_array_number, %equipment_array_number) = ();
my (%splitter_array_number, %splitter_array) = ();
my ($number_index, $cross_number_index, $equipment_number_index, $splitter_number_index) = 1;
my $center = 650;
my $center_color = 400;
my $center_for_left_links = 550;
my $center_for_right_links = 560;
my $connecter_id = 0;
my %standart_coords = (
  x_start_left           => 20,
  x_end_left             => 320,
  x_end_left_not_cable   => 220,
  x_start_left_not_cable => 120,
);

my $img = GD::Simple->new(1050, 1520);

my %CONNECTION_TYPES = (
  cable     => 'CABLE',
  splitter  => 'SPLITTER',
  cross     => 'CROSS',
  equipment => 'EQUIPMENT',
);

our %CABLE_COLORS = (
  'fcfefc' => 'white',
  '04fefc' => 'sea',
  'fcfe04' => 'yellow',
  '048204' => 'green',
  '840204' => 'brown',
  'fc0204' => 'red',
  'fc9a04' => 'orange',
  'fc9acc' => 'pink',
  '848284' => 'gray',
  '0402fc' => 'blue',
  '840284' => 'violet',
  '040204' => 'black',
  '04fe04' => 'yellowgreen',
  '9cce04' => 'olive',
  'fcfe9c' => 'beige',
  'dbefdb' => 'natural',
  'fde910' => 'lemon',
  '9c3232' => 'cherry',
);

#**********************************************************
=head2 _get_information ()

  Returns:
    Array of Links

=cut
#**********************************************************
sub _get_information {

  my @Links;
  my $links = $Commutation->select_links_info({ COLS_NAME => 1, COMMUTATION_ID => $FORM{ID} || 0 });

  foreach my $link (@$links) {
    push @Links, {
      "element_1_id"   => $link->{element_1_id},
      "element_1_type" => $link->{element_1_type},
      "element_2_id"   => $link->{element_2_id},
      "element_2_type" => $link->{element_2_type},
      "fiber_num_1"    => $link->{fiber_num_1},
      "fiber_num_2"    => $link->{fiber_num_2},
    };
  }

  return @Links;
}

#**********************************************************
=head2 _print_elements (img)

  Arguments:
    $img - Image file

=cut
#**********************************************************
sub _print_elements {

  my $elements = $Commutation->get_commutation_elements({ ID => $FORM{ID} });

  return 1 if ref($elements) ne "ARRAY";
  foreach my $element (@{$elements}) {
    _draw_cable({ id => $element->{element_id}, img => $img }) if $element->{element_type} eq $CONNECTION_TYPES{"cable"};

    if ($element->{element_type} eq $CONNECTION_TYPES{"cross"}) {
      my $cross = $Commutation->select_cross({ COLS_NAME => 1, ID => $element->{element_id} });
      my $cross_type = $Commutation->select_cross_types({ COLS_NAME => 1, ID => $cross->{type_id} });
      _cross_equipment_line($cross_type->{ports_count} - 1, $cross->{id}, "CROSS", $cross->{name});
      next;
    }

    if ($element->{element_type} eq $CONNECTION_TYPES{"equipment"}) {
      my $equipment = $Commutation->select_equipment({ COLS_NAME => 1, ID => $element->{element_id} });
      my $equipment_name = $Commutation->select_equipment_name({ COLS_NAME => 1, ID => $equipment->{model_id} });
      _cross_equipment_line($equipment->{ports} - 1, $element->{element_id}, "EQUIPMENT", $equipment_name->{model_name});
      next;
    }

    if ($element->{element_type} eq $CONNECTION_TYPES{"splitter"}) {
      my $splitter = $Commutation->select_splitter({ COLS_NAME => 1, ID => $element->{element_id} });
      my $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $splitter->{color_scheme_id} });
      my $splitter_type = $Commutation->select_splitter_types({ COLS_NAME => 1, ID => $splitter->{type_id} });
      my @colors = split(',', $color->{colors});
      _splitter_line({
        fiber_in  => $splitter_type->{fibers_in},
        fiber_out => $splitter_type->{fibers_out},
        digit     => $splitter->{id},
        name      => $splitter_type->{name},
        colors    => \@colors
      });
      next;
    }
  }

  return 1;
}

#**********************************************************
=head2 _print_links (img)

  Arguments:
    $img - Image file

=cut
#**********************************************************
sub _print_links {

  my @Links = _get_information();
  my $cable;
  my ($cable_type_1, $cable_type_2);
  my $color;
  my @colors_1;
  my @colors_2;

  foreach my $link (@Links) {
    #   Cable with Cable
    if ($link->{element_1_type} eq $CONNECTION_TYPES{"cable"} && $link->{element_2_type} eq $CONNECTION_TYPES{"cable"}) {
      $cable = $Commutation->select_cable({ COLS_NAME => 1, ID => $link->{element_1_id} });
      $cable_type_1 = $Commutation->select_cable_types({ COLS_NAME => 1, ID => $cable->{type_id} });
      $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $cable_type_1->{color_scheme_id} });
      @colors_1 = split(',', $color->{colors});

      $cable = $Commutation->select_cable({ COLS_NAME => 1, ID => $link->{element_2_id} });
      $cable_type_2 = $Commutation->select_cable_types({ COLS_NAME => 1, ID => $cable->{type_id} });
      $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $cable_type_2->{color_scheme_id} });
      @colors_2 = split(',', $color->{colors});

      _print_link_cables($cable_type_1, $cable_type_2, $link, \@colors_1, \@colors_2);
    }

    #   Cable with Cross
    if ($link->{element_1_type} eq $CONNECTION_TYPES{"cable"} && $link->{element_2_type} eq $CONNECTION_TYPES{"cross"}) {
      $cable = $Commutation->select_cable({ COLS_NAME => 1, ID => $link->{element_1_id} });
      $cable_type_1 = $Commutation->select_cable_types({ COLS_NAME => 1, ID => $cable->{type_id} });
      $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $cable_type_1->{color_scheme_id} });
      @colors_1 = split(',', $color->{colors});

      _print_link_cable_equipment_with_cross($cable_type_1, $link, \@colors_1, "CROSS");
    }

    #   Cable with Equipment
    if ($link->{element_1_type} eq $CONNECTION_TYPES{"cable"} && $link->{element_2_type} eq $CONNECTION_TYPES{"equipment"}) {
      $cable = $Commutation->select_cable({ COLS_NAME => 1, ID => $link->{element_1_id} });
      $cable_type_1 = $Commutation->select_cable_types({ COLS_NAME => 1, ID => $cable->{type_id} });
      $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $cable_type_1->{color_scheme_id} });
      @colors_1 = split(',', $color->{colors});

      _print_link_cable_equipment_with_cross($cable_type_1, $link, \@colors_1, "EQUIPMENT");
    }

    #   Cable with Splitter
    if ($link->{element_1_type} eq $CONNECTION_TYPES{"cable"} && $link->{element_2_type} eq $CONNECTION_TYPES{"splitter"} ||
      $link->{element_1_type} eq $CONNECTION_TYPES{"splitter"} && $link->{element_2_type} eq $CONNECTION_TYPES{"cable"}) {
      my $cable_id = $link->{element_2_type} eq $CONNECTION_TYPES{"cable"} ? $link->{element_2_id} : $link->{element_1_id};
      $cable = $Commutation->select_cable({ COLS_NAME => 1, ID => $cable_id });
      $cable_type_1 = $Commutation->select_cable_types({ COLS_NAME => 1, ID => $cable->{type_id} });
      $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $cable_type_1->{color_scheme_id} });
      my @cable_colors = split(',', $color->{colors});

      my $splitter_id = $link->{element_2_type} eq $CONNECTION_TYPES{"splitter"} ? $link->{element_2_id} : $link->{element_1_id};
      my $splitter = $Commutation->select_splitter({ COLS_NAME => 1, ID => $splitter_id });
      $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $splitter->{color_scheme_id} });
      my @splitter_colors = split(',', $color->{colors});

      my $link_info = ();
      if ($link->{element_2_type} eq $CONNECTION_TYPES{"cable"}) {
        $link_info->{element_1_id} = $link->{element_2_id};
        $link_info->{element_1_type} = $link->{element_2_type};
        $link_info->{fiber_num_1} = $link->{fiber_num_2};
        $link_info->{element_2_id} = $link->{element_1_id};
        $link_info->{element_2_type} = $link->{element_1_type};
        $link_info->{fiber_num_2} = $link->{fiber_num_1};
      }
      else {
        $link_info = $link;
      }

      _print_link_cable_with_splitter({
        cable_type     => $cable_type_1,
        link           => $link_info,
        cable_color    => \@cable_colors,
        splitter_color => \@splitter_colors
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 _print_link_cables ()

  Arguments:
    $cable_type_1 - Type of first cable
    $cable_type_2 - Type of second cable
    $link         - Link between cable and cable
    $img          - Image file
    $color_1      - Color for the first cable link
    $color_2      - Color for the second cable link

=cut
#**********************************************************
sub _print_link_cables {
  my ($cable_type_1, $cable_type_2, $link, $color_1, $color_2) = @_;

  my (@color_1_modules, @color_2_modules);
  my ($first_color, $second_color);
  my $count_p = 0;
  my $count = 0;
  my $elements_1 = @$color_1;
  my $elements_2 = @$color_2;

  if ($cable_type_1->{modules_count} > 1) {
    $count_p = 0;
    $count = $cable_type_1->{fibers_count};

    while ($count_p < ($count / $cable_type_1->{modules_count})) {
      if ($count_p >= $elements_1) {
        $color_1_modules[$count_p] = @$color_1[$count_p - $elements_1];
      }
      else {
        $color_1_modules[$count_p] = @$color_1[$count_p];
      }

      $count_p++;
    }

    $elements_1 = @color_1_modules;
    @color_1_modules = _check_colors(@color_1_modules);
    $first_color = $color_1_modules[$link->{fiber_num_1} % $elements_1 - 1];
  }
  else {
    $count = $cable_type_1->{fibers_count};
    for (my $i = 0; $i < $count; $i++) {
      if ($i >= $elements_1) {
        $color_1_modules[$i] = @$color_1[$i - $elements_1];
      }
      else {
        $color_1_modules[$i] = @$color_1[$i];
      }
    }

    @color_1_modules = _check_colors(@color_1_modules);
    $first_color = $color_1_modules[$link->{fiber_num_1} - 1];
  }

  if ($cable_type_2->{modules_count} != 1) {
    $count_p = 0;
    $count = $cable_type_2->{fibers_count};

    while ($count_p < ($count / $cable_type_2->{modules_count})) {
      if ($count_p >= $elements_2) {
        $color_2_modules[$count_p] = @$color_2[$count_p - $elements_2];
      }
      else {
        $color_2_modules[$count_p] = @$color_2[$count_p];
      }
      $count_p++;
    }

    $elements_2 = @color_2_modules;
    @color_2_modules = _check_colors(@color_2_modules);
    $second_color = $color_2_modules[$link->{fiber_num_2} % $elements_2 - 1];
  }
  else {
    $count = $cable_type_2->{fibers_count};
    for (my $i = 0; $i < $count; $i++) {
      if ($i >= $elements_2) {
        $color_2_modules[$i] = @$color_2[$i - $elements_2];
      }
      else {
        $color_2_modules[$i] = @$color_2[$i];
      }
    }
    @color_2_modules = _check_colors(@color_2_modules);
    $second_color = $color_2_modules[$link->{fiber_num_2} - 1];
  }

  _set_com(
    $cable_box{$link->{element_1_id}},
    $cable_box{$link->{element_2_id}},
    $link->{fiber_num_1},
    $link->{fiber_num_2},
    $first_color,
    $second_color,
    $cable_sides{$link->{element_1_id}},
    $cable_sides{$link->{element_2_id}},
  );

  return 1;
}

#**********************************************************
=head2 _print_link_cable_with_cross ()

  Arguments:
    $cable_type - Type of cable
    $link       - Link between cable and cross
    $img        - Image file
    $color_1    - Color for cable link
    $type       - Type of element (Cross or Equipment)

=cut
#**********************************************************
sub _print_link_cable_equipment_with_cross {
  my ($cable_type, $link, $color_1, $type) = @_;

  my @color_1_modules;
  my ($first_color, $second_color);
  my $count_p = 0;
  my $count = 0;
  my $elements_1 = @$color_1;

  if ($cable_type->{modules_count} != 1) {
    $count_p = 0;
    $count = $cable_type->{fibers_count};

    while ($count_p < ($count / $cable_type->{modules_count})) {
      if ($count_p >= $elements_1) {
        $color_1_modules[$count_p] = @$color_1[$count_p - $elements_1];
      }
      else {
        $color_1_modules[$count_p] = @$color_1[$count_p];
      }

      $count_p++;
    }

    $elements_1 = @color_1_modules;
    @color_1_modules = _check_colors(@color_1_modules);
    $first_color = $color_1_modules[$link->{fiber_num_1} % $elements_1 - 1];
  }
  else {
    $count = $cable_type->{fibers_count};
    for (my $i = 0; $i < $count; $i++) {
      if ($i >= $elements_1) {
        $color_1_modules[$i] = @$color_1[$i - $elements_1];
      }
      else {
        $color_1_modules[$i] = @$color_1[$i];
      }
    }

    @color_1_modules = _check_colors(@color_1_modules);
    $first_color = $color_1_modules[$link->{fiber_num_1} - 1];
  }

  $second_color = "cecece";

  if ($type eq $CONNECTION_TYPES{"cross"}) {
    _set_com(
      $cable_box{$link->{element_1_id}},
      $cross_array{$link->{element_2_id}},
      $link->{fiber_num_1},
      $link->{fiber_num_2},
      $first_color,
      $second_color,
      $cable_sides{$link->{element_1_id}},
      $cross_array_number{$link->{element_2_id}},
    );
  }
  if ($type eq $CONNECTION_TYPES{"equipment"}) {
    _set_com(
      $cable_box{$link->{element_1_id}},
      $equipment_array{$link->{element_2_id}},
      $link->{fiber_num_1},
      $link->{fiber_num_2},
      $first_color,
      $second_color,
      $cable_sides{$link->{element_1_id}},
      $equipment_array_number{$link->{element_2_id}},
    );
  }

  return 1;
}

#**********************************************************
=head2 _print_link_cable_with_splitter ()

  Arguments:
    $cable_type - Type of cable
    $link       - Link between cable and splitter
    $img        - Image file
    $color_1    - Color for cable link

=cut
#**********************************************************
sub _print_link_cable_with_splitter {
  my ($attr) = @_;

  my @color_1_modules;
  my ($first_color);
  my $count_p = 0;
  my $count = 0;
  my $elements_1 = @{$attr->{cable_color}};

  if ($attr->{cable_type}->{modules_count} != 1) {
    $count_p = 0;
    $count = $attr->{cable_type}->{fibers_count};

    while ($count_p < ($count / $attr->{cable_type}{modules_count})) {
      if ($count_p >= $elements_1) {
        $color_1_modules[$count_p] = @$attr->{cable_type}[$count_p - $elements_1];
      }
      else {
        $color_1_modules[$count_p] = $attr->{cable_color}[$count_p];
      }

      $count_p++;
    }

    $elements_1 = @color_1_modules;
    @color_1_modules = _check_colors(@color_1_modules);
    $first_color = $color_1_modules[$attr->{link}{fiber_num_1} % $elements_1 - 1];
  }
  else {
    $count = $attr->{cable_type}{fibers_count};
    for (my $i = 0; $i < $count; $i++) {
      if ($i >= $elements_1) {
        $color_1_modules[$i] = $attr->{cable_color}[$i - $elements_1];
      }
      else {
        $color_1_modules[$i] = $attr->{cable_color}[$i];
      }
    }

    @color_1_modules = _check_colors(@color_1_modules);
    $first_color = $color_1_modules[$attr->{link}{fiber_num_1} - 1];
  }

  foreach my $color (@{$attr->{splitter_color}}) {
    $color = substr($color, 0, 6) if length($color) > 6;
  }

  my $splitter_colors_count = @{$attr->{splitter_color}};
  $splitter_colors_count ||= 1;
  my $second_color = $attr->{splitter_color}[$attr->{link}{fiber_num_2} % $splitter_colors_count - 1];

  _set_com(
    $cable_box{$attr->{link}{element_1_id}},
    $splitter_array{$attr->{link}{element_2_id}},
    $attr->{link}{fiber_num_1},
    $attr->{link}{fiber_num_2},
    $first_color,
    $second_color,
    $cable_sides{$attr->{link}{element_1_id}},
    $splitter_array_number{$attr->{link}{element_2_id}},
  );

  return 1;
}

#**********************************************************
=head2 _check_colors ()

  Arguments:
    @colors_module - Module colors

  Returns:
    Array of Module colors

=cut
#**********************************************************
sub _check_colors {
  my @colors_module = @_;

  foreach my $color_module (@colors_module) {
    $color_module = substr($color_module, 0, 6) if length($color_module) > 6;
  }

  return @colors_module;
}

#**********************************************************
=head2 show_box () - Show image

=cut
#**********************************************************
sub show_box {
  $img->bgcolor('white');
  $img->fgcolor('black');
  $img->font('optima.ttf');

  _print_elements();
  _print_links();

  if ($FORM{print} && $FORM{print} == 1) {
    $html->tpl_show(_include('cable_blank_print', 'Cablecat'));
    print qq(<img src="img.png" alt="Smiley face">);

    return 1;
  }

  print qq(<img src="img.png" alt="Smiley face">);

  return 1;
}

#**********************************************************
=head2 _print_cable_lines()

  Arguments:
    $porst                   - Number of ports
    $digit                   - Cable number
    $img                     - Image file
    $name                    - Name of the cable
    $modules_count           - Number of modules
    $modules_color_scheme_id - ID for color scheme of the modules
    @colors                  - Array of colors for the cable

=cut
#**********************************************************
sub _print_cable_lines {
  my ($ports, $digit, $name, $modules_count, $modules_color_scheme_id, @colors) = @_;
  my $digit2 = $number_index % 2;
  my ($x1, $x2, $y1, $y2);

  if ($y1_first == 40 && $y1_second == 40) {
    $img->rectangle(0, 0, 1045, 1510);

    $img->font('Times:italic');
    $img->fontsize(14);
    $img->moveTo(990, 20);
    $img->string("Abills");
  }

  if ($digit2 != 0) {
    ($x1, $x2) = ($standart_coords{x_start_left}, $standart_coords{x_end_left});
    ($y1, $y2) = ($y1_first, $y1_first + 57 + (15 * $ports));

    $y1_first += 57 + (15 * $ports) + 25;
  }
  else {
    ($x1, $x2) = (725, 1025);
    ($y1, $y2) = ($y1_second, $y1_second + 57 + (15 * $ports));
    $y1_second += 57 + (15 * $ports) + 25;
  }

  $cable_box{$digit} = $y1;
  $cable_sides{$digit} = $number_index++;

  _cable_print($digit, $x1, $x2, $y1, $y2, $ports + 1, $name, $modules_count, $number_index - 1, $modules_color_scheme_id, @colors);

  return 1;
}

#**********************************************************
=head2 _cross_equipment_line()

  Arguments:
    $porst - Number of ports
    $digit - Cross or Equipment number
    $img   - Image file
    $type  - Type of element (Cross or Equipment)

=cut
#**********************************************************
sub _cross_equipment_line {
  my ($ports, $digit, $type, $name) = @_;
  my $digit2 = $cross_number_index % 2;
  my ($x1, $x2, $y1, $y2);

  if ($y1_first == 40 && $y1_second == 40) {
    $img->rectangle(0, 0, 1045, 1510);

    $img->font('Times:italic');
    $img->fontsize(14);
    $img->moveTo(1000, 20);
    $img->string("Abills");
  }

  if ($digit2 != 0) {
    ($x1, $x2) = ($standart_coords{x_start_left_not_cable}, $standart_coords{x_end_left_not_cable});
    ($y1, $y2) = ($y1_first, $y1_first + 57 + (15 * $ports));

    $y1_first += 57 + (15 * $ports) + 25;

    if ($type eq $CONNECTION_TYPES{"cross"}) {
      $cross_array{$digit} = $y1;
      $cross_array_number{$digit} = $cross_number_index++;
    }
    if ($type eq $CONNECTION_TYPES{"splitter"}) {
      $splitter_array{$digit} = $y1;
      $splitter_array_number{$digit} = ++$splitter_number_index;
    }
    if ($type eq $CONNECTION_TYPES{"equipment"}) {
      $equipment_array{$digit} = $y1;
      $equipment_array_number{$digit} = ++$equipment_number_index;
    }
  }
  else {
    ($x1, $x2) = (725, 820);
    ($y1, $y2) = ($y1_second, $y1_second + 57 + (15 * $ports));
    $y1_second += 57 + (15 * $ports) + 25;

    if ($type eq $CONNECTION_TYPES{"cross"}) {
      $cross_array{$digit} = $y1;
      $cross_array_number{$digit} = $cross_number_index++;
    }
    if ($type eq $CONNECTION_TYPES{"equipment"}) {
      $equipment_array{$digit} = $y1;
      $equipment_array_number{$digit} = $equipment_number_index;
      $equipment_number_index++;
    }
    if ($type eq $CONNECTION_TYPES{"splitter"}) {
      $splitter_array{$digit} = $y1;
      $splitter_array_number{$digit} = $splitter_number_index;
      $splitter_number_index++;
    }
  }

  _cross_equipment_print($digit, $x1, $x2, $y1, $y2, $ports + 1, $type, $name);

  return 1;
}

#**********************************************************
=head2 _cable_print ()

  Arguments:
    $number                  - Cable number
    $x1                      - x1 position for cable
    $x2                      - x2 position for cable
    $y1                      - y1 position for cable
    $y2                      - y2 position for cable
    $img                     - Image file
    $count                   - Number of ports
    $name                    - Name of the cable
    $modules_count           - Number of modules
    $modules_color_scheme_id - ID for color scheme of the modules
    @colors                  - Array of colors for the cable

=cut
#**********************************************************
sub _cable_print {
  my ($number, $x1, $x2, $y1, $y2, $count, $name, $modules_count, $number_index_, $modules_color_scheme_id, @colors) = @_;

  my $black = $img->colorAllocate(0, 0, 0);

  my $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $modules_color_scheme_id });
  my @colors_modules = split(',', $color->{colors});

  foreach my $color_1 (@colors) {
    if (length($color_1) > 6) {
      $color_1 = substr($color_1, 0, 6);
    }
  }

  foreach my $color_1 (@colors_modules) {
    if (length($color_1) > 6) {
      $color_1 = substr($color_1, 0, 6);
    }
  }

  my $elements = @colors;

  $img->rectangle($x1, $y1, $x2, $y2 + 15);
  $img->rectangle($x1, $y1, $x1 + 40, $y1 + 40);
  $img->rectangle($x1 + 40, $y1, $x2, $y1 + 40);

  #color
  $img->rectangle($x1, $y1 + 40, $x1 + 60, $y2 + 15);
  #address
  $img->rectangle($x1 + 60, $y1 + 40, $x1 + 200, $y2 + 15);
  #Model color
  $img->rectangle($x1 + 200, $y1 + 40, $x1 + 260, $y2 + 15);
  #Port
  $img->rectangle($x1 + 260, $y1 + 40, $x2, $y2 + 15);

  $img->string(GD::Simple::gdSmallFont, $x1 + 10, $y1 + 40, "Color", $black);
  $img->string(GD::Simple::gdSmallFont, $x1 + 70, $y1 + 40, "Address", $black);
  $img->string(GD::Simple::gdSmallFont, $x1 + 265, $y1 + 40, "Port", $black);
  $img->string(GD::Simple::gdSmallFont, $x1 + 205, $y1 + 40, "Model Col", $black);

  if ($modules_count == 1) {
    for (my $i = 0; $i < $count; $i++) {
      $img->string(GD::Simple::gdSmallFont, $x1 + 277, $y1 + ($i + 3) * 15 + 15, $i + 1, $black);
      $img->line($x1, $y1 + ($i + 3.8) * 15 + 15, $x1 + 200, $y1 + ($i + 3.8) * 15 + 15);
      $img->line($x1 + 260, $y1 + ($i + 3.8) * 15 + 15, $x2, $y1 + ($i + 3.8) * 15 + 15);
    }

    for (my $i = 0; $i < $count; $i++) {
      if ($i >= $elements) {
        $img->string(GD::Simple::gdSmallFont, $x1 + 13, $y1 + ($i + 2.9) * 15 + 15,
          $CABLE_COLORS{"$colors[$i - $elements]"}, $black);

        if ($number_index_ % 2 != 0) {
          $img->bgcolor(unpack('C*', pack('H*', $colors[$i - $elements])));
          $img->rectangle($x1 - 15, $y1 + ($i + 2.9) * 15 + 15, $x1 - 5, $y1 + ($i + 1 + 2.9) * 15 + 15);
        }
        else {
          $img->bgcolor(unpack('C*', pack('H*', $colors[$i - $elements])));
          $img->rectangle($x2 + 5, $y1 + ($i + 2.9) * 15 + 15, $x2 + 15, $y1 + ($i + 1 + 2.9) * 15 + 15);
        }
      }
      else {
        $img->string(GD::Simple::gdSmallFont, $x1 + 13, $y1 + ($i + 2.9) * 15 + 15,
          $CABLE_COLORS{"$colors[$i]"}, $black);

        if ($number_index_ % 2 != 0) {
          $img->bgcolor(unpack('C*', pack('H*', $colors[$i - $elements])));
          $img->rectangle($x1 - 15, $y1 + ($i + 2.9) * 15 + 15, $x1 - 5, $y1 + ($i + 1 + 2.9) * 15 + 15);
        }
        else {
          $img->bgcolor(unpack('C*', pack('H*', $colors[$i - $elements])));
          $img->rectangle($x2 + 5, $y1 + ($i + 2.9) * 15 + 15, $x2 + 15, $y1 + ($i + 1 + 2.9) * 15 + 15);
        }
      }

      $img->bgcolor(255, 255, 255);

      if ($i == $count / 2 - 1) {
        $img->string(GD::Simple::gdSmallFont, $x1 + 210, $y1 + ($i + 2.9) * 15 + 15,
          $CABLE_COLORS{"$colors_modules[0]"}, $black);
      }
    }
  }
  else {
    for (my $i = 0; $i < $count; $i++) {
      $img->string(GD::Simple::gdSmallFont, $x1 + 277, $y1 + ($i + 3) * 15 + 15, $i + 1, $black);
      $img->line($x1, $y1 + ($i + 3.8) * 15 + 15, $x1 + 200, $y1 + ($i + 3.8) * 15 + 15);
      $img->line($x1 + 260, $y1 + ($i + 3.8) * 15 + 15, $x2, $y1 + ($i + 3.8) * 15 + 15);
    }

    my $center_0 = $count / $modules_count - 1;
    my $center_1 = $center_0;

    for (my $i = 0; $i < $modules_count; $i++) {
      $img->line($x1, $y1 + ($center_0 + 3.8) * 15 + 15, $x2, $y1 + ($center_0 + 3.8) * 15 + 15);
      $img->string(GD::Simple::gdSmallFont, $x1 + 210, $y1 + ($center_0 + 2.8) * 15 + 15,
        $CABLE_COLORS{"$colors_modules[$i]"}, $black);

      $center_0 += $center_1 + 1;
    }

    my $count_y = 0;
    for (my $i = 0; $i < $modules_count; $i++) {
      my $count_p = 0;

      while ($count_p < ($count / $modules_count)) {
        if ($count_p >= $elements) {
          $img->string(GD::Simple::gdSmallFont, $x1 + 15, $y1 + ($count_y + 2.9) * 15 + 15,
            $CABLE_COLORS{"$colors[$count_p - $elements]"}, $black);

          if ($number_index_ % 2 != 0) {
            $img->bgcolor(unpack('C*', pack('H*', $colors[$count_p - $elements])));
            $img->rectangle($x1 - 15, $y1 + ($count_y + 2.9) * 15 + 15, $x1 - 5, $y1 + ($count_y + 1 + 2.9) * 15 + 15);
          }
          else {
            $img->bgcolor(unpack('C*', pack('H*', $colors[$count_p - $elements])));
            $img->rectangle($x2 + 5, $y1 + ($count_y + 2.9) * 15 + 15, $x2 + 15, $y1 + ($count_y + 1 + 2.9) * 15 + 15);
          }

          $img->bgcolor(255, 255, 255);
        }
        else {
          $img->string(GD::Simple::gdSmallFont, $x1 + 15, $y1 + ($count_y + 2.9) * 15 + 15,
            $CABLE_COLORS{"$colors[$count_p]"}, $black);

          if ($number_index_ % 2 != 0) {
            $img->bgcolor(unpack('C*', pack('H*', $colors[$count_p])));
            $img->rectangle($x1 - 15, $y1 + ($count_y + 2.9) * 15 + 15, $x1 - 5, $y1 + ($count_y + 1 + 2.9) * 15 + 15);
          }
          else {
            $img->bgcolor(unpack('C*', pack('H*', $colors[$count_p])));
            $img->rectangle($x2 + 5, $y1 + ($count_y + 2.9) * 15 + 15, $x2 + 15, $y1 + ($count_y + 1 + 2.9) * 15 + 15);
          }

          $img->bgcolor(255, 255, 255);
        }

        $count_p++;
        $count_y++;

      }
    }
  }

  $img->line($x1, $y1 + 40 + 15, $x2, $y1 + 40 + 15);

  $img->font('Times:italic');
  $img->fontsize(13);
  $img->string(GD::Simple::gdGiantFont, $x1 + 2, $y1 + 5, "$number", $black);

  my $name_length = length $name;

  if ($name_length < 52) {
    $img->moveTo($x1 + 45, $y1 + 30);
    $img->string("$name");
  }
  else {
    my @result = split(' ', $name);
    my $sub_name1 = "";
    my $sub_name2 = "";
    my $temp = "";
    my $len = 0;

    foreach my $str (@result) {
      $temp = $sub_name1 . " " . $str . " ";
      $len = length $temp;
      if ($len < 55) {
        $sub_name1 = $sub_name1 . " " . $str . " ";
      }
      else {
        $sub_name2 = $sub_name2 . " " . $str . " ";
      }
    }

    $img->moveTo($x1 + 40, $y1 + 15);
    $img->string("$sub_name1");

    $img->moveTo($x1 + 40, $y1 + 35);
    $img->string("$sub_name2");
  }

  if ($connecter_id == 0) {
    $connecter_id = $Commutation->select_cablecat_commutations({ COLS_NAME => 1, ID => $FORM{ID} });
    $name = $Commutation->select_cablecat_well({ COLS_NAME => 1, ID => $connecter_id->{connecter_id} });

    $img->moveTo(45, 1480);
    $img->string("$name->{name}");
  }

  open(my $out, '>', 'img.png') or die "Write image $!\n";
  binmode $out;
  print $out $img->png;

  return 1;
}

#**********************************************************
=head2 _cross_print ()

  Arguments:
    $number - Cross number
    $x1     - x1 position for cross
    $x2     - x2 position for cross
    $y1     - y1 position for cross
    $y2     - y2 position for cross
    $img    - Image file
    $count  - Number of ports
    $type   - Type of element (Cross or Equipment)

=cut
#**********************************************************
sub _cross_equipment_print {
  my ($number, $x1, $x2, $y1, $y2, $count, $type, $name) = @_;

  my $x1_for_left = $x1;
  my $x2_for_left = $x2;
  if ($type eq $CONNECTION_TYPES{"cross"} && $cross_array_number{$number} % 2 == 1) {
    $x1_for_left += 100;
  }
  else {
    $x2_for_left -= 94;
  }

  my $black = $img->colorAllocate(0, 0, 0);

  $img->rectangle($x1_for_left, $y1, $x2_for_left, $y2 + 15);
  $img->rectangle($x1, $y1, $x1 + 40, $y1 + 40);
  $img->rectangle($x1 + 40, $y1, $x2 + 100, $y1 + 40);

  #port
  $img->rectangle($x1_for_left, $y1 + 40, $x2_for_left + 40, $y2 + 15);
  #color
  $img->rectangle($x1_for_left + 40, $y1 + 40, $x2_for_left + 100, $y2 + 15);

  $img->string(GD::Simple::gdSmallFont, $x1_for_left + 10, $y1 + 40, "Port", $black);
  $img->string(GD::Simple::gdSmallFont, $x1_for_left + 50, $y1 + 40, "Color", $black);

  my $x1_for_left_line = $x1_for_left + 100;
  for (my $i = 0; $i < $count; $i++) {
    $img->string(GD::Simple::gdSmallFont, $x1_for_left + 15, $y1 + ($i + 3) * 15 + 15, $i + 1, $black);
    $img->string(GD::Simple::gdSmallFont, $x1_for_left + 50, $y1 + ($i + 2.8) * 15 + 15, "grey", $black);
    $img->line($x1_for_left_line, $y1 + ($i + 3.8) * 15 + 15, $x2_for_left, $y1 + ($i + 3.8) * 15 + 15);
  }

  $img->line($x1_for_left_line, $y1 + 40 + 15, $x2_for_left, $y1 + 40 + 15);

  $img->font('Times:italic');
  $img->fontsize(13);
  $img->string(GD::Simple::gdGiantFont, $x1 + 2, $y1 + 5, "$number", $black);

  if ($type eq $CONNECTION_TYPES{"cross"}) {
    my $name_length = length $name;

    if ($name_length < 35) {
      $img->moveTo($x1 + 40, $y1 + 25);
      $img->string("$name");
    }
    else {
      my @result = split(' ', $name);
      my $sub_name1 = "";
      my $sub_name2 = "";
      my $temp = "";
      my $len = 0;

      foreach my $str (@result) {
        $temp = $sub_name1 . " " . $str . " ";
        $len = length $temp;
        if ($len < 35) {
          $sub_name1 = $sub_name1 . " " . $str . " ";
        }
        else {
          $sub_name2 = $sub_name2 . " " . $str . " ";
        }
      }
      $img->moveTo($x1 + 20, $y1 + 18);
      $img->string("$sub_name1");

      $img->moveTo($x1 + 20, $y1 + 35);
      $img->string("$sub_name2");
    }
  }
  if ($type eq $CONNECTION_TYPES{"equipment"}) {
    $img->fontsize(13);
    my $name_length = length $name;

    if ($name_length < 25) {
      $img->moveTo($x1 + 20, $y1 + 25);
      $img->string("$name");
    }
    else {
      my @result = split(' ', $name);
      my $sub_name1 = "";
      my $sub_name2 = "";
      my $temp = "";
      my $len = 0;

      foreach my $str (@result) {
        $temp = $sub_name1 . " " . $str . " ";
        $len = length $temp;
        if ($len < 25) {
          $sub_name1 = $sub_name1 . " " . $str . " ";
        }
        else {
          $sub_name2 = $sub_name2 . " " . $str . " ";
        }
      }
      $img->moveTo($x1 + 20, $y1 + 18);
      $img->string("$sub_name1");

      $img->moveTo($x1 + 20, $y1 + 35);
      $img->string("$sub_name2");
    }

  }

  open(my $out, '>', 'img.png') or die "Write image $!\n";
  binmode $out;
  print $out $img->png;

  return 1;
}

#**********************************************************
=head2 _splitter_print ()

  Arguments:
    $number - Splitter number
    $x1     - x1 position for cross
    $x2     - x2 position for cross
    $y1     - y1 position for cross
    $y2     - y2 position for cross
    $img    - Image file
    $count  - Number of ports

=cut
#**********************************************************
sub _splitter_print {
  my ($attr) = @_;

  my $black = $img->colorAllocate(0, 0, 0);

  $img->rectangle($attr->{x1}, $attr->{y1}, $attr->{x1} + 140, $attr->{y1} + 40);
  $img->rectangle($attr->{x1}, $attr->{y1}, $attr->{x2}, $attr->{y1} + 40);
  $img->rectangle($attr->{x1}, $attr->{y1}, $attr->{x1} + 40, $attr->{y1} + 40);

  my $x1_for_left = $attr->{x1};
  my $x2_for_left = $attr->{x2};
  if ($splitter_array_number{$attr->{side}} % 2 == 1) {
    $x1_for_left += 50;
  }
  else {
    $x2_for_left -= 50;
  }

  #port
  $img->rectangle($x1_for_left, $attr->{y1} + 40, $x1_for_left + 40, $attr->{y2} + 15);
  #  color
  $img->rectangle($x1_for_left + 40, $attr->{y1} + 40, $x1_for_left + 90, $attr->{y2} + 15);
  #  type
  $img->rectangle($x1_for_left + 90, $attr->{y1} + 40, $x2_for_left, $attr->{y2} + 15);

  $img->string(GD::Simple::gdSmallFont, $x1_for_left + 9, $attr->{y1} + 40, "Port", $black);
  $img->string(GD::Simple::gdSmallFont, $x1_for_left + 50, $attr->{y1} + 40, "Color", $black);
  $img->string(GD::Simple::gdSmallFont, $x1_for_left + 105, $attr->{y1} + 40, "Type", $black);

  my $colors_count = @{$attr->{colors}};

  for (my $i = 0; $i < $attr->{fiber_in} + $attr->{fibers_out}; $i++) {
    my $type = $i - $attr->{fiber_in} > -1 ? "output" : "input";
    my $color_index = $i >= $colors_count ? $i - $colors_count : $i;
    $img->string(GD::Simple::gdSmallFont, $x1_for_left + 15, $attr->{y1} + ($i + 3) * 15 + 15, $i + 1, $black);
    $img->string(GD::Simple::gdSmallFont, $x1_for_left + 50, $attr->{y1} + ($i + 2.8) * 15 + 15, $CABLE_COLORS{$attr->{colors}[$color_index]}, $black);
    $img->string(GD::Simple::gdSmallFont, $x1_for_left + 100, $attr->{y1} + ($i + 2.8) * 15 + 15, $type, $black);
    $img->line($x1_for_left, $attr->{y1} + ($i + 3.8) * 15 + 15, $x2_for_left, $attr->{y1} + ($i + 3.8) * 15 + 15);
  }
  $img->line($x1_for_left, $attr->{y1} + 40 + 15, $x2_for_left, $attr->{y1} + 40 + 15);

  $img->font('Times:italic');
  $img->fontsize(13);
  $img->string(GD::Simple::gdGiantFont, $attr->{x1} + 2, $attr->{y1} + 5, "$attr->{side}", $black);

  $attr->{name} = "$lang{SPLITTER}: $attr->{name}";
  my $name_length = length $attr->{name};

  if ($name_length < 30) {
    $img->moveTo($attr->{x1} + 42, $attr->{y1} + 25);
    $img->string("$attr->{name}");
  }
  else {
    my @result = split(' ', $attr->{name});
    my $sub_name1 = "";
    my $sub_name2 = "";
    my $temp = "";
    my $len = 0;

    foreach my $str (@result) {
      $temp = $sub_name1 . " " . $str . " ";
      $len = length $temp;
      if ($len < 21) {
        $sub_name1 = $sub_name1 . " " . $str . " ";
      }
      else {
        $sub_name2 = $sub_name2 . " " . $str . " ";
      }
    }

    $img->moveTo($attr->{x1} + 40, $attr->{y1} + 15);
    $img->string("$sub_name1");

    $img->moveTo($attr->{x1} + 40, $attr->{y1} + 35);
    $img->string("$sub_name2");
  }

  open(my $out, '>', 'img.png') or die "Write image $!\n";
  binmode $out;
  print $out $img->png;

  return 1;
}

#**********************************************************
=head2 _set_com ($first_y1, $second_y1, $port1, $port2,

  Arguments:
    $first_y1   - y1 for first element
    $second_y1  - y1 for second element
    $port1      - port of the first element
    $port2      - port of the second element
    $img        - Image file
    $color_1    - color of the first port
    $color_2    - color of the second port
    $first_num  - first element number
    $second_num - second element number

=cut
#**********************************************************\
sub _set_com {
  my ($first_y1, $second_y1, $port1, $port2, $color_1, $color_2, $first_num, $second_num) = @_;

  $first_num %= 2;
  $second_num %= 2;

  $first_y1 += 15;
  $second_y1 += 15;

  if ($color_1 eq "fcfefc") {
    $color_1 = "cecece";
  }
  if ($color_2 eq "fcfefc") {
    $color_2 = "cecece";
  }

  my ($y1, $y2);
  my $first_x1 = 0;
  my $second_x1 = 0;
  my $center_for_links = 0;

  my @first_color = unpack('C*', pack('H*', $color_1));
  my @second_color = unpack('C*', pack('H*', $color_2));

  if ($first_num != 0 && $second_num == 0) {
    _set_com_both($first_y1, $second_y1, $port1, $port2, $color_1, $color_2);

    return 1;
  }
  elsif ($second_num != 0 && $first_num == 0) {
    _set_com_both($second_y1, $first_y1, $port2, $port1, $color_2, $color_1);

    return 1;
  }
  elsif ($first_num != 0 && $second_num != 0) {
    $first_x1 = 320;
    $second_x1 = 320;
    $center_for_links = $center_for_left_links;
  }
  elsif ($first_num == 0 && $second_num == 0) {
    $first_x1 = 725;
    $second_x1 = 725;
    $center_for_links = $center_for_right_links;
  }

  if ($port1 == 1 && $port2 == 1) {
    $y1 = $first_y1 + 50;
    $y2 = $second_y1 + 50;
  }
  elsif ($port2 == 1 && $port1 != 1) {
    $y2 = $second_y1 + 50;
    $y1 = $first_y1 + 50 + ($port1 - 1) * 15;
  }
  elsif ($port1 == 1 && $port2 != 1) {
    $y1 = $first_y1 + 50;
    $y2 = $second_y1 + 50 + ($port2 - 1) * 15;
  }
  else {
    $y1 = $first_y1 + 50 + ($port1 - 1) * 15;
    $y2 = $second_y1 + 50 + ($port2 - 1) * 15;
  }

  $img->{fgcolor} = $img->translate_color(@first_color);
  $img->line($first_x1, $y1, $center_for_links, $y1);

  $img->{fgcolor} = $img->translate_color(@second_color);
  $img->line($center_for_links, $y1, $center_for_links, $y2);
  $img->line($center_for_links, $y2, $second_x1, $y2);

  if ($first_num != 0 && $second_num != 0) {
    $center_for_left_links = $center_for_links - 7;
  }
  elsif ($first_num == 0 && $second_num == 0) {
    $center_for_right_links = $center_for_links + 7;
  }

  open(my $out, '>', 'img.png') or die "Write image $!\n";
  binmode $out;
  print $out $img->png;

  return 1;
}

#**********************************************************
=head2 _set_com_both ()

  Arguments:
    $first_y1   - y1 for first element
    $second_y1  - y1 for second element
    $port1      - port of the first element
    $port2      - port of the second element
    $img        - Image file
    $color_1    - color of the first port
    $color_2    - color of the second port

=cut
#**********************************************************\
sub _set_com_both {
  my ($first_y1, $second_y1, $port1, $port2, $color_1, $color_2) = @_;

  $color_1 = "cecece" if $color_1 eq "fcfefc";
  $color_2 = "cecece" if $color_2 eq "fcfefc";

  my @first_color = unpack('C*', pack('H*', $color_1));
  my @second_color = unpack('C*', pack('H*', $color_2));

  my $first_x1 = 320;
  my $second_x1 = 725;
  my ($y1, $y2);

  if ($port1 == 1) {
    $y1 = $first_y1 + 50;
    $y2 = $port2 == 1 ? $second_y1 + 50 : $second_y1 + 50 + ($port2 - 1) * 15;;
  }
  elsif ($port2 == 1) {
    $y2 = $second_y1 + 50;
    $y1 = $first_y1 + 50 + ($port1 - 1) * 15;
  }
  else {
    $y1 = $first_y1 + 50 + ($port1 - 1) * 15;
    $y2 = $second_y1 + 50 + ($port2 - 1) * 15;
  }

  if ($port1 != $port2 || $first_y1 != $second_y1) {
    $img->{fgcolor} = $img->GD::Simple::translate_color(@first_color);
    $img->line($first_x1, $y1, $center_color, $y1);

    $img->{fgcolor} = $img->GD::Simple::translate_color(@second_color);
    $img->line($center_color, $y1, $center, $y1);
    $img->line($center, $y1, $center, $y2);
    $img->line($center, $y2, $second_x1, $y2);
  }
  else {
    $img->{fgcolor} = $img->GD::Simple::translate_color(@first_color);
    $img->line($first_x1, $y1, $center_color, $y1);

    $img->{fgcolor} = $img->GD::Simple::translate_color(@second_color);
    $img->line($center_color, $y1, $second_x1, $y2);
  }

  $center = $center < 425 ? 648 : $center - 5;

  open(my $out, '>', 'img.png') or die "Write image $!\n";
  binmode $out;
  print $out $img->png;

  return 1;
}

#**********************************************************
=head2 _splitter_line()

  Arguments:
    $porst - Number of ports
    $digit - Splitter id
    $img   - Image file

=cut
#**********************************************************
sub _splitter_line {
  my ($attr) = @_;

  my $digit2 = $splitter_number_index % 2;
  my ($x1, $x2, $y1, $y2);

  if ($y1_first == 40 && $y1_second == 40) {
    $img->rectangle(0, 0, 1045, 1510);

    $img->font('Times:italic');
    $img->fontsize(14);
    $img->moveTo(1000, 20);
    $img->string("Abills");
  }

  foreach my $color (@{$attr->{colors}}) {
    $color = substr($color, 0, 6) if length($color) > 6;
  }

  if ($digit2 != 0) {
    ($x1, $x2) = (120, 320);
    ($y1, $y2) = ($y1_first, $y1_first + 57 + (15 * ($attr->{fiber_in} + $attr->{fiber_out} - 1)));

    $y1_first += 57 + (15 * ($attr->{fiber_in} + $attr->{fiber_out} - 1)) + 25;
  }
  else {
    ($x1, $x2) = (725, 920);
    ($y1, $y2) = ($y1_second, $y1_second + 57 + (15 * ($attr->{fiber_in} + $attr->{fiber_out} - 1)));
    $y1_second += 57 + (15 * ($attr->{fiber_in} + $attr->{fiber_out} - 1)) + 25;
  }

  $splitter_array{$attr->{digit}} = $y1;
  $splitter_array_number{$attr->{digit}} = $splitter_number_index || 0;
  $splitter_number_index++;

  _splitter_print({
    side       => $attr->{digit},
    x1         => $x1,
    x2         => $x2,
    y1         => $y1,
    y2         => $y2,
    fiber_in   => $attr->{fiber_in},
    fibers_out => $attr->{fiber_out},
    name       => $attr->{name},
    colors     => $attr->{colors}
  });

  return 1;
}

#**********************************************************
=head2 _draw_cable()

=cut
#**********************************************************
sub _draw_cable {
  my ($attr) = @_;
  my $cable = $Commutation->select_cable({ COLS_NAME => 1, ID => $attr->{id} });
  my $cable_type = $Commutation->select_cable_types({ COLS_NAME => 1, ID => $cable->{type_id} });
  my $color = $Commutation->select_color_schemes({ COLS_NAME => 1, ID => $cable_type->{color_scheme_id} });

  _print_cable_lines($cable_type->{fibers_count} - 1, $cable->{id}, $cable->{name}, $cable_type->{modules_count},
    $cable_type->{modules_color_scheme_id}, split(',', $color->{colors}));
}

1;
