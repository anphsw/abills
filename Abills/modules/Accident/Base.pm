package Accident::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my Accident $Accident;
my %status = ();

use Abills::Base qw/days_in_month in_array/;

#**********************************************************
=head2 new($html, $lang)

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

  require Accident;
  Accident->import();
  $Accident = Accident->new($db, $admin, $CONF);

  %status = (
    0 => $lang->{PROCESSING},
    1 => $lang->{PROCESSED},
    2 => $lang->{CLOSED},
  );

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 accident_quick_info($attr) - Quick information

  Arguments:
    $attr

=cut
#**********************************************************
sub accident_quick_info {
  my ($self, $attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID} || '-1';
  my $total = 0;

  $Accident->user_accident_list({ UID => $uid, COLS_NAME => 1 });
  $total += $Accident->{TOTAL} if ($Accident->{TOTAL});

  $Accident->accident_equipment_list({
    ID_EQUIPMENT => '_SHOW',
    PORT_ID      => '_SHOW',
    STATUS       => 0,
    UID          => $uid,
    EXT_TABLE    => 1,
    COLS_NAME    => 1,
  });
  $total += $Accident->{TOTAL} if ($Accident->{TOTAL});

  return ($total > 0) ? $total : '';
}

1;
