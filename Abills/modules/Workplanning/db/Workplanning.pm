package Workplanning;

=head2

  Workplanning

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Workplanning';

my ($admin);

#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $Admin, $CONF) = @_;

  $Admin->{MODULE} = $MODULE;
  $admin = $Admin;

  my $self = {
    db    => $db,
    admin => $Admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 add() - Add info

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('work_planning', $attr);

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Workplanning';
    $admin->system_ction_add("ADD WORK PLAN", { TYPE => 1 });
  }

  return $self;
}

#**********************************************************
=head2 del() - Delete info

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($id) = @_;

  $self->query_del('work_planning', { ID => $id });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Workplanning';
    $admin->system_action_add("DELETE work plan: $id", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 list($attr) - list

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'ID', 'INT', 'wp.id', 1],
      [ 'DATE_OF_CREATION', 'DATE', 'wp.date_of_creation', 1 ],
      [ 'DATE_OF_EXECUTION', 'DATE', 'wp.date_of_execution', 1 ],
      [ 'AID', 'INT', 'wp.AID', 1 ],
      [ 'DESCRIPTION', 'STR', 'wp.description', 1 ],
      [ 'STATUS', 'INT', 'wp.status', 1 ],
      [ 'BUDGET', 'INT', 'wp.budget', 1 ],
      [ 'UID', 'INT', 'wp.uid', 1 ],
      [ 'BUILDS_ID', 'INT', 'wp.builds_id', 1 ],
      [ 'COMMENT', 'STR', 'wp.comment', 1 ],
      [ 'CREATOR', 'INT', 'wp.creator', 1 ],
      [ 'MSGS_ID', 'INT', 'wp.msgs_id', 1 ],
    ],
    { WHERE => 1,
    }
  );

  $self->query(
    "SELECT wp.*, a.name 
     FROM work_planning wp 
     JOIN admins a ON wp.aid=a.aid
     $WHERE
     ORDER BY $SORT $DESC;",
    undef,
    { COLS_NAME => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 change($attr) - change

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'work_planning',
    DATA         => $attr,
  });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = 'Workplanning';
    $admin->system_action_add("CHANGE work plan: $attr->{ID}", { TYPE => 2 });
  }

  return $self;
}

1;
