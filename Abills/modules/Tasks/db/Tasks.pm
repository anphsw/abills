package Tasks;

=head1 NAME

 Tasks sql functions

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Tasks';

my Admins $admin;
my $CONF;

use Abills::Base qw/_bp/;

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($attr) = @_;

  return {} unless ($attr->{ID});

  $self->query("SELECT tm.*,
      tt.name as type_name,
      tt.plugins as plugins,
      r.name as responsible_name,
      a.name as admin_name
      FROM tasks_main tm
      LEFT JOIN tasks_type tt ON (tm.task_type=tt.id)
      LEFT JOIN admins a ON (tm.aid=a.aid)
      LEFT JOIN admins r ON (tm.responsible=r.aid)
      WHERE tm.id= ?;",
    undef,
    { Bind => [ $attr->{ID} ], COLS_NAME => 1, COLS_UPPER => 1 }
  );
  return {} if ($self->{errno});

  my $info = $self->{list}->[0];

  $self->query("SELECT aid
      FROM tasks_partcipiants
      WHERE id= ?;",
    undef,
    { Bind => [ $attr->{ID} ], COLS_NAME => 1 }
  );

  if ($self->{TOTAL} > 0) {
    my @p_arr = ();
    foreach (@{$self->{list}}) {
      push(@p_arr, $_->{aid});
    }
    $info->{PARTCIPIANTS_LIST} = join(',', @p_arr);
  }

  return $info;
}

#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tasks_main', $attr);
  return $self if ($self->{errno});

  if ($attr->{LEAD_ID} && Abills::Base::in_array('Crm', \@main::MODULES)) {
    require Crm::db::Crm;
    Crm->import();
    my $Crm = Crm->new($self->{db}, $admin, $CONF);

    $Crm->_crm_workflow('newTask', $attr->{LEAD_ID}, $attr) if !$self->{errno};
  }

  return $self;
}

#**********************************************************
=head2 change$attr)

  Arguments:
    $attr - hash_ref

  Returns:
    $self

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  my $old_info = $self->info({ ID => $attr->{ID} });

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'tasks_main',
    DATA         => $attr,
  });

  if (!$self->{errno} && $attr->{STATE} && $attr->{STATE} eq '1' && $old_info->{STATE} ne '1' && $old_info->{LEAD_ID}) {
    require Crm::db::Crm;
    Crm->import();
    my $Crm = Crm->new($self->{db}, $admin, $CONF);

    $Crm->_crm_workflow('closedTask', $old_info->{LEAD_ID}, { %{$attr}, TASK_TYPE => $old_info->{TASK_TYPE} });
  }

  return $self;
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if (defined $attr->{SUBTASKS_OF} && $attr->{SUBTASKS_OF} =~ /^\d+$/) {
    push @WHERE_RULES,
      "(path LIKE CONCAT((SELECT CONCAT(path, '/') FROM tasks_main WHERE id = $attr->{SUBTASKS_OF}), '%')) OR tm.id = $attr->{SUBTASKS_OF}";
    $attr->{PATH} = '_SHOW';
  }

  my $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'tm.id', 1 ],
    [ 'TASK_TYPE', 'INT', 'tm.task_type', 1 ],
    [ 'STATE', 'INT', 'tm.state', 1 ],
    [ 'AID', 'INT', 'tm.aid', 1 ],
    [ 'RESPONSIBLE', 'INT', 'tm.responsible', 1 ],
    [ 'PLAN_DATE', 'DATE', 'tm.plan_date', 1 ],
    [ 'CLOSED_DATE', 'DATE', 'tm.closed_date', 1 ],
    [ 'CONTROL_DATE', 'DATE', 'tm.control_date', 1 ],
    [ 'MSG_ID', 'INT', 'tm.msg_id', 1 ],
    [ 'STEP_ID', 'INT', 'tm.step_id', 1 ],
    [ 'LEAD_ID', 'INT', 'tm.lead_id', 1 ],
    [ 'DEAL_ID', 'INT', 'tm.deal_id', 1 ],
    [ 'PARENT_ID', 'INT', 'tm.parent_id', 1 ],
    [ 'PATH', 'STR', 'tm.path', 1 ],
    [ 'NAME', 'STR', 'tm.name', 1 ],
  ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query("SELECT 
      $self->{SEARCH_FIELDS}
      tm.id,
      tm.name,
      tm.task_type,
      tm.descr,
      tm.state,
      tm.aid,
      tm.responsible,
      tm.plan_date,
      tm.control_date,
      tm.additional_values,
      tm.comments,
      tt.name as type_name,
      tt.plugins as plugins,
      r.name as responsible_name,
      a.name as admin_name
      FROM tasks_main tm
      LEFT JOIN tasks_type tt ON (tm.task_type=tt.id)
      LEFT JOIN admins a ON (tm.aid=a.aid)
      LEFT JOIN admins r ON (tm.responsible=r.aid)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr, COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT count( DISTINCT tm.id) AS total 
        FROM tasks_main tm
        LEFT JOIN tasks_type tt ON (tm.task_type=tt.id)
        LEFT JOIN admins a ON (tm.aid=a.aid)
        LEFT JOIN admins r ON (tm.responsible=r.aid)
        $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 del($attr)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('tasks_main', $attr);
  return $self if ($self->{errno});

  my @del_descr = ();
  if ($attr->{ID}) {
    push @del_descr, "ID: $attr->{ID}";
  }
  if ($attr->{COMMENTS}) {
    push @del_descr, "COMMENTS: $attr->{COMMENTS}";
  }

  $admin->action_add('', join(' ', @del_descr), { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 p_list($attr)

=cut
#**********************************************************
sub p_list {
  my $self = shift;
  my ($attr) = @_;

  $attr->{PARTCIPIANT} = $attr->{RESPONSIBLE};
  delete $attr->{RESPONSIBLE};

  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'tm.id', 1 ],
    [ 'TASK_TYPE', 'INT', 'tm.task_type', 1 ],
    [ 'STATE', 'INT', 'tm.state', 1 ],
    [ 'AID', 'INT', 'tm.aid', 1 ],
    [ 'RESPONSIBLE', 'INT', 'tm.responsible', 1 ],
    [ 'PLAN_DATE', 'DATE', 'tm.plan_date', 1 ],
    [ 'CONTROL_DATE', 'DATE', 'tm.control_date', 1 ],
    [ 'PARTCIPIANT', 'INT', 'tp.aid', 1 ],
  ],
    { WHERE => 1 }
  );

  $self->query("SELECT 
      $self->{SEARCH_FIELDS}
      tm.id,
      tm.name,
      tm.task_type,
      tm.descr,
      tm.state,
      tm.aid,
      tm.responsible,
      tm.plan_date,
      tm.control_date,
      tm.additional_values,
      tm.comments,
      tt.name as type_name,
      tt.plugins as plugins,
      r.name as responsible_name,
      a.name as admin_name
      FROM tasks_partcipiants tp
      LEFT JOIN tasks_main tm ON (tp.id=tm.id)
      LEFT JOIN tasks_type tt ON (tm.task_type=tt.id)
      LEFT JOIN admins a ON (tm.aid=a.aid)
      LEFT JOIN admins r ON (tm.responsible=r.aid)
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    { %$attr, COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0 && !$attr->{SKIP_TOTAL}) {
    $self->query("SELECT count( DISTINCT tm.id) AS total 
        FROM tasks_partcipiants tp
        LEFT JOIN tasks_main tm ON (tp.id=tm.id)
        LEFT JOIN tasks_type tt ON (tm.task_type=tt.id)
        LEFT JOIN admins a ON (tm.aid=a.aid)
        LEFT JOIN admins r ON (tm.responsible=r.aid)
        $WHERE",
      undef,
      { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 p_add($attr)

=cut
#**********************************************************
sub p_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tasks_partcipiants', $attr);
  return [] if ($self->{errno});

  return $self;
}

#**********************************************************
=head2 del($attr)

=cut
#**********************************************************
sub p_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('tasks_partcipiants', $attr);
  return [] if ($self->{errno});

  return $self;
}

#**********************************************************
=head2 type_add($attr)

=cut
#**********************************************************
sub type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tasks_type', $attr);
  return $self if ($self->{errno});

  return $self;
}

#**********************************************************
=head2 type_hide($attr)

=cut
#**********************************************************
sub type_hide {
  my $self = shift;
  my ($id) = @_;

  $self->query("UPDATE tasks_type
      SET hidden = 1
      WHERE id= ?;",
    'do',
    { Bind => [ $id ] }
  );

  return [] if ($self->{errno});

  return $self;
}

#**********************************************************
=head2 type_info($attr)

=cut
#**********************************************************
sub type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT *
      FROM tasks_type
      WHERE id= ?",
    undef,
    { Bind => [ ($attr->{ID} ? $attr->{ID} : '') ], COLS_NAME => 1, COLS_UPPER => 1 }
  );
  return [] if ($self->{errno});

  return $self->{list}->[0];
}

#**********************************************************
=head2 types_list($attr)

=cut
#**********************************************************
sub types_list {
  my $self = shift;
  my ($attr) = @_;

  $attr->{HIDDEN} = 0;
  my $WHERE = $self->search_former($attr, [
    [ 'ID',     'INT', 'id',     1 ],
    [ 'NAME',   'STR', 'name',   1 ],
    [ 'HIDDEN', 'INT', 'hidden', 1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM tasks_type
    $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 admins_list($attr)

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  $attr->{AID} =~ s/\,/\;/g if ($attr->{AID});
  $attr->{AID} =~ s/\,/\;/g if ($attr->{AID});

  my $WHERE = $self->search_former($attr, [
    [ 'AID', 'INT', 'a.aid', 1 ],
    [ 'RESPONSIBLE', 'INT', 'ta.responsible', 1 ],
    [ 'ADMIN', 'INT', 'ta.admin', 1 ],
    [ 'SYSADMIN', 'INT', 'ta.sysadmin', 1 ],
  ],
    { WHERE => 1 }
  );

  $self->query("SELECT 
      $self->{SEARCH_FIELDS}
      a.aid,
      a.name as a_name,
      a.id as a_login,
      ta.responsible,
      ta.admin,
      ta.sysadmin
      FROM admins a
      LEFT JOIN tasks_admins ta ON (ta.aid=a.aid)
      $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 admins_change($attr)

=cut
#**********************************************************
sub admins_change {
  my $self = shift;
  my ($attr) = @_;
  $self->query_del('tasks_admins', {}, { AID => $attr->{AID} });
  $self->query_add('tasks_admins', $attr);

  return 1;
}

#**********************************************************
=head2 plugins_list($attr)

=cut
#**********************************************************
sub plugins_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID', 'INT', 'p.aid', 1 ],
    [ 'ENABLE', 'INT', 'p.enable', 1 ],
  ],
    { WHERE => 1 }
  );

  $self->query("SELECT 
      $self->{SEARCH_FIELDS}
      p.id,
      p.enable,
      p.name,
      p.descr
      FROM tasks_plugins p
      $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list};

}

#**********************************************************
=head2 plugins_add($attr)

=cut
#**********************************************************
sub plugins_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tasks_plugins', $attr);

  return $self;
}

#**********************************************************
=head2 plugins_del($id)

=cut
#**********************************************************
sub plugins_del {
  my $self = shift;
  my ($id) = @_;
  $self->query_del('tasks_plugins', { ID => $id });

  return $self;
}

#**********************************************************
=head2 enable_plugin($plugin_name)

=cut
#**********************************************************
sub enable_plugin {
  my $self = shift;
  my ($name) = @_;

  $self->query("UPDATE tasks_plugins
      SET enable = 1
      WHERE name = ?;",
    'do',
    { Bind => [ $name ] }
  );

  return [] if ($self->{errno});

  return $self;
}

#**********************************************************
=head2 disable_plugin($plugin_name)

=cut
#**********************************************************
sub disable_plugin {
  my $self = shift;
  my ($name) = @_;

  $self->query("UPDATE tasks_plugins
      SET enable = 0
      WHERE name = ?;",
    'do',
    { Bind => [ $name ] }
  );

  return [] if ($self->{errno});

  return $self;
}

#**********************************************************
=head2 add_field($field)

=cut
#**********************************************************
sub add_field {
  my $self = shift;
  my ($field) = @_;

  $self->query("ALTER TABLE tasks_main
      ADD $field;",
    'do',
    {}
  );
  return $self;
}

#**********************************************************
=head2 cols_arr()

=cut
#**********************************************************
sub cols_arr {
  my $self = shift;

  $self->query("SELECT * 
    FROM tasks_main
    LIMIT 1;",
    undef,
    { COLS_NAME => 1 }
  );
  return $self->{COL_NAMES_ARR};
}

#**********************************************************
=head2 type_fields_add()

=cut
#**********************************************************
sub type_fields_add {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{TASK_TYPE_ID};

  $self->query_del('tasks_type_fields', undef, { task_type_id => $attr->{TASK_TYPE_ID} });

  return $self if (!$attr->{ADDITIONAL_FIELDS} || ref $attr->{ADDITIONAL_FIELDS} ne 'ARRAY');

  my @MULTI_QUERY = ();
  foreach my $field (@{$attr->{ADDITIONAL_FIELDS}}) {
    push @MULTI_QUERY, [ $attr->{TASK_TYPE_ID}, $field->{NAME} || '', $field->{TYPE} || '', $field->{LABEL} || '' ];
  }

  $self->query("INSERT INTO tasks_type_fields (task_type_id, name, type, label) VALUES (?, ?, ?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 type_fields_list($attr)

=cut
#**********************************************************
sub type_fields_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'id',           1 ],
    [ 'NAME',         'STR', 'name',         1 ],
    [ 'TYPE',         'STR', 'type',         1 ],
    [ 'LABEL',        'STR', 'label',        1 ],
    [ 'TASK_TYPE_ID', 'INT', 'task_type_id', 1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM tasks_type_fields
    $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 type_plugins_add()

=cut
#**********************************************************
sub type_plugins_add {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{TASK_TYPE_ID};

  $self->query_del('tasks_type_plugins', undef, { task_type_id => $attr->{TASK_TYPE_ID} });

  return $self if (!$attr->{PLUGINS} || ref $attr->{PLUGINS} ne 'ARRAY');

  my @MULTI_QUERY = ();
  foreach my $plugin (@{$attr->{PLUGINS}}) {
    push @MULTI_QUERY, [ $attr->{TASK_TYPE_ID}, $plugin ];
  }

  $self->query("INSERT INTO tasks_type_plugins (task_type_id, plugin_name) VALUES (?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 type_plugins_list($attr)

=cut
#**********************************************************
sub type_plugins_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'id',           1 ],
    [ 'PLUGIN_NAME',  'STR', 'plugin_name',  1 ],
    [ 'TASK_TYPE_ID', 'INT', 'task_type_id', 1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM tasks_type_plugins
    $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 type_admins_add()

=cut
#**********************************************************
sub type_admins_add {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{TASK_TYPE_ID};

  $self->query_del('tasks_type_admins', undef, { task_type_id => $attr->{TASK_TYPE_ID} });

  return $self if (!$attr->{ADMINS} || ref $attr->{ADMINS} ne 'ARRAY');

  my @MULTI_QUERY = ();
  foreach my $aid (@{$attr->{ADMINS}}) {
    push @MULTI_QUERY, [ $attr->{TASK_TYPE_ID}, $aid ];
  }

  $self->query("INSERT INTO tasks_type_admins (task_type_id, aid) VALUES (?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 type_admins_list($attr)

=cut
#**********************************************************
sub type_admins_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'id',           1 ],
    [ 'AID',          'INT', 'aid',          1 ],
    [ 'TASK_TYPE_ID', 'INT', 'task_type_id', 1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM tasks_type_admins
    $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list} || [];
}

#**********************************************************
=head2 type_participants_add()

=cut
#**********************************************************
sub type_participants_add {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{TASK_TYPE_ID};

  $self->query_del('tasks_type_participants', undef, { task_type_id => $attr->{TASK_TYPE_ID} });

  return $self if (!$attr->{PARTICIPANTS} || ref $attr->{PARTICIPANTS} ne 'ARRAY');

  my @MULTI_QUERY = ();
  foreach my $aid (@{$attr->{PARTICIPANTS}}) {
    push @MULTI_QUERY, [ $attr->{TASK_TYPE_ID}, $aid ];
  }

  $self->query("INSERT INTO tasks_type_participants (task_type_id, aid) VALUES (?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 type_participants_list($attr)

=cut
#**********************************************************
sub type_participants_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'id',           1 ],
    [ 'AID',          'INT', 'aid',          1 ],
    [ 'TASK_TYPE_ID', 'INT', 'task_type_id', 1 ],
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} id
    FROM tasks_type_participants
    $WHERE;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return [] if ($self->{errno});

  return $self->{list} || [];
}


1;