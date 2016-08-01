package Events;
use strict;
use warnings FATAL => 'all';

use Time::Local qw ( timelocal );

our $VERSION = 1.00;

use parent 'main';

# Singleton reference;
my $instance;

#**********************************************************

=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut

#**********************************************************
sub new {
  my $class = shift;

  unless (defined $instance) {
    my ($db, $admin, $CONF) = @_;

    my $self = {
      db    => $db,
      admin => $admin,
      conf  => $CONF,
    };

    bless($self, $class);

    $instance = $self;
  }

  return $instance;
}

#**********************************************************

=head2 events_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub events_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'e.id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID',            'INT', 'e.id',                        1 ],
    [ 'MODULE',        'STR', 'e.module',                    1 ],
    [ 'NAME',          'STR', 'e.module',                    1 ],
    [ 'EXTRA',         'STR', 'e.extra',                     1 ],
    [ 'COMMENTS',      'STR', 'e.comments',                  1 ],
    [ 'STATE_ID',      'INT', 'e.state_id',                  1 ],
    [ 'PRIVACY_ID',    'INT', 'e.privacy_id',                1 ],
    [ 'PRIORITY_ID',   'INT', 'e.priority_id',               1 ],
    [ 'CREATED',       'STR', 'e.created',                   1 ],
    [ 'GROUP_ID',      'INT', 'e.group_id AS group_id',      1 ],
    [ 'PRIVACY_NAME',  'STR', 'epriv.name AS privacy_name',  1 ],
    [ 'PRIORITY_NAME', 'STR', 'eprio.name AS priority_name', 1 ],
    [ 'STATE_NAME',    'STR', 'es.name AS state_name',       1 ],
    [ 'GROUP_MODULES', 'STR', 'eg.modules AS group_modules', 1 ],

  ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} 1 FROM events e
    LEFT JOIN events_privacy epriv ON (e.privacy_id = epriv.id)
    LEFT JOIN events_priority eprio ON (e.priority_id = eprio.id)
    LEFT JOIN events_state es ON (e.state_id = es.id)
    LEFT JOIN events_group eg ON (e.group_id = eg.id)
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 events_info($id)

  Arguments:
    $id - id for events

  Returns:
    hash_ref

=cut

#**********************************************************
sub events_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->events_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0];
}

#**********************************************************

=head2 events_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub events_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('events', $attr);

  return 1;
}

#**********************************************************

=head2 events_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub events_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('events', $attr);

  return 1;
}

#**********************************************************

=head2 events_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub events_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'events',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 state_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub state_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ]];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_state $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 state_info($id)

  Arguments:
    $id - id for state

  Returns:
    hash_ref

=cut

#**********************************************************
sub state_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->state_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0];
}

#**********************************************************

=head2 state_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub state_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('events_state', $attr);

  return 1;
}

#**********************************************************

=head2 state_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub state_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('events_state', $attr);

  return 1;
}

#**********************************************************

=head2 state_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub state_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'events_state',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 privacy_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub privacy_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'VALUE', 'STR', 'value', 1 ], ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_privacy $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 privacy_info($id)

  Arguments:
    $id - id for privacy

  Returns:
    hash_ref

=cut

#**********************************************************
sub privacy_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->privacy_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0];
}

#**********************************************************

=head2 privacy_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub privacy_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('events_privacy', $attr);

  return 1;
}

#**********************************************************

=head2 privacy_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub privacy_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('events_privacy', $attr);

  return 1;
}

#**********************************************************

=head2 privacy_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub privacy_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'events_privacy',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 priority_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub priority_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'VALUE', 'STR', 'value', 1 ], ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless (exists $attr->{ $_->[0] }) } @{$search_columns};
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_priority $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************

=head2 priority_info($id)

  Arguments:
    $id - id for priority

  Returns:
    hash_ref

=cut

#**********************************************************
sub priority_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->priority_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0];
}

#**********************************************************

=head2 priority_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub priority_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('events_priority', $attr);

  return 1;
}

#**********************************************************

=head2 priority_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub priority_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('events_priority', $attr);

  return 1;
}

#**********************************************************

=head2 priority_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub priority_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'events_priority',
      DATA         => $attr,
    }
  );

  return 1;
}

#**********************************************************

=head2 group_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut

#**********************************************************
sub group_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 'id';
  my $DESC      = ($attr->{DESC})      ? 'DESC'             : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [ [ 'ID', 'INT', 'id', 1 ], [ 'NAME', 'STR', 'name', 1 ], [ 'MODULES', 'STR', 'modules', 1 ], ];

  if ($attr->{SHOW_ALL_COLUMNS}) {
    map { $attr->{ $_->[0] } = '_SHOW' unless exists $attr->{ $_->[0] } } @$search_columns;
  }

  my $WHERE = $self->search_former($attr, $search_columns, { WHERE => 1 });

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM events_group $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : {} }
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************

=head2 group_info($id)

  Arguments:
    $id - id for group

  Returns:
    hash_ref

=cut

#**********************************************************
sub group_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->group_list({ COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 });

  return $list->[0];
}

#**********************************************************

=head2 group_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('events_group', $attr);

  return 1;
}

#**********************************************************

=head2 group_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut

#**********************************************************
sub group_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('events_group', $attr);

  return 1;
}

#**********************************************************

=head2 group_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut

#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'events_group',
      DATA         => $attr,
    }
  );

  return 1;
}

1;