package Accident::Base;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db);
#my $json;
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
  my $uid = $attr->{UID} || $form->{UID};

  return () if $form->{sid};

  if ($attr->{UID}) {
    my $list = $Accident->user_accident_list({ UID => $uid, COLS_NAME => 1 });

    my @result = ();
    #my $admins_list = ::sel_admins({ HASH => 1 });

    foreach my $line (@{$list}) {
      push @result, {
        NAME   => $line->{name},
        DESC   => $line->{descr},
        STATUS => $status{ $line->{status} },
        AID    => $line->{aid}, #$admins_list->{ $line->{aid} },
      };
    }

    return \@result;
  }
  elsif ($attr->{GET_PARAMS}) {
    my %result = (
      HEADER => $lang->{ACCIDENT_LOG},
      SLIDES => [
        { NAME => $lang->{NAME} },
        { DESC => $lang->{DESCRIBE} },
        { STATUS => $lang->{STATUS} },
        { AID => $lang->{RESPONSIBLE} },
      ]
    );

    return \%result;
  }

  $Accident->user_accident_list({ UID => $uid, COLS_NAME => 1 });

  return ($Accident->{TOTAL} > 0) ? $Accident->{TOTAL} : '';
}

1;