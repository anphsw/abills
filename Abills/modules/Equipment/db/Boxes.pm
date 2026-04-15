package Equipment::db::Boxes;
=head NAME

  Equipment boxes

=cut

use strict;
use parent qw(dbcore);


#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $MODULE = 'Equipment';
  $admin->{MODULE} = $MODULE;
  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    module => $MODULE
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 type_add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub type_add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_box_types', $attr);
  return [] if ($self->{errno});

  $self->{admin}->system_action_add("card TYPES: $self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 type_info()

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub type_info {
  my ($self, $id) = @_;

  $self->query('SELECT * FROM equipment_box_types WHERE id= ? ;',
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 type_del($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub type_del {
  my ($self, $id) = @_;

  $self->query_del('equipment_box_types', { ID => $id });

  return [] if ($self->{errno});

  $self->{admin}->system_action_add("card TYPES: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 type_change($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub type_change {
  my ($self, $attr) = @_;

  $attr->{DISABLE} = (!defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_box_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 type_list($id)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub type_list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'MARKING', 'STR', 'marking', ],
    [ 'VENDOR', 'STR', 'vendor', ],
  ],
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT marking, vendor, units, width, hieght, length, diameter, id
FROM equipment_box_types
$WHERE
SQL

  $self->query_list($sql, $attr);

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(id) AS total FROM equipment_box_types $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub add {
  my ($self, $attr) = @_;

  $self->query_add('equipment_boxes', $attr);
  return [] if ($self->{errno});

  $self->{admin}->system_action_add("card TYPES: $self->{INSERT_ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
=head2 info($attr)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub info {
  my ($self, $id) = @_;

  $self->query("SELECT * FROM equipment_boxes WHERE id= ? ;",
    undef,
    { INFO => 1,
      Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 del($attr)

  Arguments:
    $id
  Results:
    $self

=cut
#**********************************************************
sub del {
  my ($self, $id) = @_;

  $self->query_del('equipment_boxes', { ID => $id });

  return [] if ($self->{errno});

  $self->{admin}->system_action_add("card: $id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub change {
  my ($self, $attr) = @_;

  $attr->{DISABLE} = (!defined($attr->{DISABLE})) ? 0 : 1;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'equipment_boxes',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 list($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'SERIAL', 'STR', 'serial', ],
    [ 'VENDOR', 'STR', 'vendor', ],
  ],
    { WHERE => 1 }
  );

  my $sql = <<"SQL";
SELECT b.serial, bt.marking, b.datetime, b.id
FROM equipment_boxes b
LEFT JOIN equipment_box_types bt ON (b.type_id=bt.id)
$WHERE
SQL


  $self->query_list($sql, $attr);

  return [] if ($self->{errno});

  my $list = $self->{list} || [];

  if ($self->{TOTAL} >= 0) {
    $self->query("SELECT COUNT(id) AS total FROM equipment_boxes $WHERE",
      undef, { INFO => 1 });
  }

  return $list;
}


1;