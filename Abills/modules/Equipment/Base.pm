package Equipment::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my Equipment $Equipment;


#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

  Arguments:
    $db
    $admin
    $CONF
    $attr
      HTML
      LANG

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Equipment;
  Equipment->import();
  $Equipment = Equipment->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 equipment_search($attr) - Global search submodule

  Arguments:
    $attr
      SEARCH_TEXT
      DEBUG

  Returs:
     TRUE/FALSE

=cut
#**********************************************************

sub equipment_search {
  my $self = shift;
  my ($attr) = @_;

  my @default_search = ('MAC', '_MULTI_HIT');

  my %LIST_PARAMS = ();

  my @qs = ();
  foreach my $field (@default_search) {
    $LIST_PARAMS{$field} = "*$attr->{SEARCH_TEXT}*";
    push @qs, "$field=*$attr->{SEARCH_TEXT}*";
  }

  if ($attr->{DEBUG}) {
    $Equipment->{debug} = 1;
  }

  $Equipment->mac_log_list({
    %LIST_PARAMS,
  });

  my @info = ();

  if ($Equipment->{TOTAL}) {
    push @info, {
      'TOTAL'        => $Equipment->{TOTAL},
      'MODULE'       => 'Equipment',
      'MODULE_NAME'  => $lang->{EQUIPMENT},
      'SEARCH_INDEX' => 261
        . '&' . join('&', @qs) . "&search=1",

    };
  }

  return \@info;
}

1;