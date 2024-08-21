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
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID};

  $Accident->user_accident_list({ UID => $uid, COLS_NAME => 1 });

  return ($Accident->{TOTAL} && $Accident->{TOTAL} > 0) ? $Accident->{TOTAL} : '';
}

1;
