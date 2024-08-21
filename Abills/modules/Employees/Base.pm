package Employees::Base;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;
my ($admin, $CONF, $db);
my $Employees;

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

  my $self = {};

  require Employees;
  Employees->import();
  $Employees = Employees->new($db, $admin, $CONF);

  $html = $attr->{HTML} if $attr->{HTML};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 employees_payment_del($attr) - delete payment from cashbox

  Arguments:
    $attr
  Returns:
    $self

=cut
#**********************************************************
sub employees_payment_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if (!$attr->{ID});

  my $coming_cashbox_list = $Employees->employees_list_coming({
    ID          => '_SHOW',
    PAYMENT_ID  => $attr->{ID},
    COLS_NAME   => 1
  });

  if ($coming_cashbox_list && $coming_cashbox_list->[0]->{id}){
    $Employees->employees_delete_coming({ ID => $coming_cashbox_list->[0]->{id} });
  }

  return $self;
}

1;