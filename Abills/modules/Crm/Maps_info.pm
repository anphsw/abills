package Crm::Maps_info;

=head1 NAME

  Crm::Maps_info - info for map

=head1 VERSION

  VERSION: 1.00
  REVISION: 20210210

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
my ($Crm, $Maps, $Auxiliary, $Tags);
my @priority_colors = ('', '#6c757d', '#17a2b8', '#28a745', '#ffc107', '#dc3545');

use Maps2::Auxiliary qw/maps2_point_info_table/;
use Abills::Base qw(in_array);

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

  require Crm::db::Crm;
  Crm->import();
  $Crm = Crm->new($db, $admin, $CONF);

  require Maps;
  Maps->import();
  $Maps = Maps->new($db, $admin, $CONF);

  $Auxiliary = Maps2::Auxiliary->new($db, $admin, $CONF, { HTML => $html, LANG => $lang });

  return $self;
}

#**********************************************************
=head2 maps_layers()

=cut
#**********************************************************
sub maps_layers {
  return {
    LAYERS => [ {
      id              => '36',
      name            => 'LEAD',
      lang_name       => $lang->{LEADS},
      module          => 'Crm',
      structure       => 'MARKER',
      export_function => 'maps_leads'
    }, {
      id              => '37',
      name            => 'LEAD_TAGS',
      lang_name       => "$lang->{LEADS} ($lang->{TAGS})",
      module          => 'Crm',
      structure       => 'MARKER',
      export_function => 'maps_leads_by_tags'
    } ]
  }
}

#**********************************************************
=head2 maps_leads()

=cut
#**********************************************************
sub maps_leads {
  my $self = shift;
  my ($attr) = @_;

  my $leads = $Crm->crm_lead_points_list();

  return $Crm->{TOTAL} if $attr->{ONLY_TOTAL};

  my @objects_to_show = ();
  my %build_info = ();

  foreach my $lead (@{$leads}) {
    if ($lead->{UID}) {
      $lead->{STEP} = $lang->{USER};
      $lead->{COLOR} = '#28a745';
    }

    push @{$build_info{$lead->{BUILD_ID}}}, {
      id           => $html->button($lead->{ID}, 'index=' . ::get_function_index('crm_lead_info') . "&LEAD_ID=$lead->{ID}"),
      fio          => $lead->{FIO},
      address_flat => $lead->{ADDRESS_FLAT},
      step         => $html->color_mark(::_translate($lead->{STEP}), $lead->{COLOR}),
      phone        => $lead->{PHONE},
      uid          => $lead->{UID} ? $html->button($lead->{UID}, 'index=' . ::get_function_index('form_users') . "&UID=$lead->{UID}") : ''
    };
  }

  foreach my $lead (@{$leads}) {
    next if !$build_info{$lead->{BUILD_ID}} || !$lead->{color};

    my $type = _crm_get_icon($lead->{COLOR});

    my $marker_info = maps2_point_info_table($html, $lang, {
      TABLE_TITLE       => $lang->{LEADS},
      OBJECTS           => $build_info{$lead->{BUILD_ID}},
      TABLE_TITLES      => [ 'ID', 'FIO', 'PHONE', 'STEP', 'UID', 'ADDRESS_FLAT' ],
      TABLE_LANG_TITLES => [ 'ID', $lang->{FIO}, $lang->{PHONE}, $lang->{STEP}, $lang->{USER}, $lang->{FLAT} ],
    });

    delete $build_info{$lead->{BUILD_ID}};
    my %marker = (
      MARKER    => {
        LAYER_ID     => 36,
        ID           => $lead->{id},
        OBJECT_ID    => $lead->{build_id},
        COORDX       => $lead->{coordy} || $lead->{coordy_2},
        COORDY       => $lead->{coordx} || $lead->{coordx_2},
        SVG          => $type,
        INFOWINDOW   => $marker_info,
        NAME         => $lead->{fio},
        DISABLE_EDIT => 1
      },
      LAYER_ID  => 36,
      ID        => $lead->{id},
      OBJECT_ID => $lead->{build_id}
    );

    push @objects_to_show, \%marker;
  }

  return \@objects_to_show if $attr->{RETURN_OBJECTS};

  my $export_string = JSON::to_json(\@objects_to_show, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 maps_leads_by_tags()

=cut
#**********************************************************
sub maps_leads_by_tags {
  my $self = shift;
  my ($attr) = @_;

  my $leads = $Crm->crm_lead_points_list();

  return $Crm->{TOTAL} if $attr->{ONLY_TOTAL};
  return 0 if !in_array('Tags', \@::MODULES);

  require Tags;
  Tags->import();
  $Tags = Tags->new($self->{db}, $self->{admin}, $self->{conf});

  my @objects_to_show = ();
  my %build_info = ();

  foreach my $lead (@{$leads}) {
    next if !$lead->{TAG_IDS};

    $lead->{TAG_IDS} =~ s/,/;/g;
    my $tags_list = $Tags->list({
      ID        => $lead->{TAG_IDS},
      NAME      => '_SHOW',
      PRIORITY  => '_SHOW',
      COLOR     => '_SHOW',
      COLS_NAME => 1,
      SORT      => 't.priority',
      DESC      => 'desc'
    });


    next if $Tags->{TOTAL} < 1;

    my $tags_container = '';
    for my $tag (@{$tags_list}) {
      my $priority_color = ($priority_colors[$tag->{priority}]) ? $priority_colors[$tag->{priority}] : $priority_colors[1];
      $tag->{color} ||= $priority_color;
      $tags_container .= ' ' . $html->element('span', $tag->{name}, {
        class => 'label new-tags m-1',
        style => "background-color: $tag->{color}; border-color: $tag->{color}"
      });
    }

    push @{$build_info{$lead->{BUILD_ID}}}, {
      id           => $html->button($lead->{ID}, 'index=' . ::get_function_index('crm_lead_info') . "&LEAD_ID=$lead->{ID}"),
      fio          => $lead->{FIO},
      step         => $html->color_mark(::_translate($lead->{STEP}), $lead->{color}),
      phone        => $lead->{PHONE},
      address_flat => $lead->{ADDRESS_FLAT},
      icon_color   => $tags_list->[0]{color},
      name         => $tags_list->[0]{name},
      tags         => $tags_container
    };
  }

  foreach my $lead (@{$leads}) {
    next if !$build_info{$lead->{BUILD_ID}} || !$lead->{color};

    my $type = _crm_get_icon($build_info{$lead->{BUILD_ID}}[0]{icon_color});

    my $marker_info = maps2_point_info_table($html, $lang, {
      TABLE_TITLE       => "$lang->{LEADS} ($lang->{TAGS})",
      OBJECTS           => $build_info{$lead->{BUILD_ID}},
      TABLE_TITLES      => [ 'ID', 'FIO', 'PHONE', 'STEP', 'TAGS', 'ADDRESS_FLAT' ],
      TABLE_LANG_TITLES => [ 'ID', $lang->{FIO}, $lang->{PHONE}, $lang->{STEP}, $lang->{TAGS}, $lang->{FLAT} ],
    });

    my %marker = (
      MARKER    => {
        LAYER_ID     => 37,
        ID           => $lead->{id},
        OBJECT_ID    => $lead->{build_id},
        COORDX       => $lead->{coordy} || $lead->{coordy_2},
        COORDY       => $lead->{coordx} || $lead->{coordx_2},
        SVG          => $type,
        INFOWINDOW   => $marker_info,
        NAME         => $build_info{$lead->{BUILD_ID}}[0]{name} . ': ' . $lead->{fio},
        DISABLE_EDIT => 1
      },
      LAYER_ID  => 37,
      ID        => $lead->{id},
      OBJECT_ID => $lead->{build_id}
    );

    delete $build_info{$lead->{BUILD_ID}};
    push @objects_to_show, \%marker;
  }

  return \@objects_to_show if $attr->{RETURN_OBJECTS};

  my $export_string = JSON::to_json(\@objects_to_show, { utf8 => 0 });
  if ($attr->{RETURN_JSON}) {
    print $export_string;
    return 1;
  }

  return $export_string;
}

#**********************************************************
=head2 _crm_get_icon()

=cut
#**********************************************************
sub _crm_get_icon {
  my $color = shift;

  return qq{<svg xmlns="http://www.w3.org/2000/svg" version="1.1" class="svg-icon-svg" style="width:23px; height:38">
    <path class="svg-icon-path" d="M 9.6 11.2 L 16.08 11.2 C 19.04 11.04 18.32 12.96 18.4 23.92 C 18.64 25.6 15.2 24.72 14.24
    24.96 V 36.8 C 14.4 38.4 11.68 37.6 6.16 37.84 C 4.32 38 4.96 37.36 4.8 36.8 V 24.88 C 1.44 24.88 1.2 25.04 1.04 24.08 V
    12.48 C 1.28 10.64 3.68 11.04 9.6 11.2 M 9.68 1.6 A 3.2 3.2 90 0 1 9.6 9.6 A 3.2 3.2 90 0 1 9.68 1.6" stroke-width="2"
    stroke="$color" stroke-opacity="1" fill="$color" fill-opacity="0.4"></path></svg>}
}

1;