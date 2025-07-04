package Discounts::Base;
use strict;
use warnings FATAL => 'all';
use Discounts;

my Discounts $Discounts;

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
  my ($class, $db, $admin, $CONF) = @_;

  $Discounts = Discounts->new($db, $admin, $CONF);

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 get_discounts($attr) - get services for invoice

  Arguments:
    $attr
      UID
      DATE
      TP_ID
      MODULE

  Returns:
    $discount_percent

=cut
#**********************************************************
sub get_discount {
  my ($self, $attr) = @_;

  my $date = $attr->{DATE} || '0000-00-00';
  my %result = (
    SUM     => 0,
    PERCENT => 0
  );

  if ($attr->{UID}) {
    my $discounts_list = $Discounts->user_list({
      UID       => $attr->{UID},
      FROM_DATE => "<=$date",
      TO_DATE   => "0000-00-00,>=$date",
      MODULE    => '_SHOW',
      TP_ID     => '_SHOW',
      PERCENT   => '_SHOW',
      SUM       => '_SHOW',
      STATUS    => 0,
      COLS_NAME => 1
    });

    foreach my $discount (@$discounts_list) {
      if ($discount->{module} && $discount->{module} ne ($attr->{MODULE} || q{})) {
        next;
      }

      if ($discount->{module} && $discount->{module} ne ($attr->{MODULE} || q{})
        && $discount->{tp_id} && $discount->{tp_id} != ($attr->{TP_ID} || 0)) {
        next;
      }

      if ($discount->{sum}) {
        $result{SUM} += $discount->{sum};
      }

      if ($discount->{percent}) {
        $result{PERCENT} += $discount->{percent};
      }
    }

    $self->{RESULT} = \%result;
  }

  return $self;
}

#**********************************************************
=head2 discounts_quick_info()

  Arguments:
    $attr
       UID

  Returns:
    TOTAL

=cut
#**********************************************************
sub discounts_quick_info {
  my $self = shift;
  my ($attr) = @_;

  my $form = $attr->{FORM} || {};
  my $uid = $form->{UID} || 0;

  $Discounts->user_list({ UID => $uid || 0, COLS_NAME => 1 });

  return ($Discounts->{TOTAL} > 0) ? $Discounts->{TOTAL} : '';
}

1;