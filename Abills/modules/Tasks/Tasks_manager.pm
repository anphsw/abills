package Tasks::Tasks_manager;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array days_in_month/;
use Tasks::db::Tasks;
use Control::Errors;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    lang    => $attr->{lang} || $attr->{LANG} || {},
    html    => $attr->{html} || undef,
    libpath => $attr->{libpath}
  };
  bless($self, $class);

  $self->{Tasks} = Tasks->new($db, $admin, $conf);

  $self->{Errors} = Control::Errors->new($db, $admin, $conf, {
    lang   => $attr->{lang},
    module => 'Tasks'
  });

  return $self;
}

#**********************************************************
=head2 _start_transaction() - Initialize transaction manager

  Arguments:
    None

  Returns:
    HASHREF
      {
        rollback => sub { ... }, # Rollback transaction if needed
        commit   => sub { ... }  # Commit transaction if needed
      }

  Example:
    my $transaction = $self->_start_transaction();
    $transaction->{commit}->();

=cut
#**********************************************************
sub _start_transaction {
  my ($self) = @_;

  my $db = $self->{Tasks}{db}{db};
  my $manage_transaction = !$self->{Tasks}{db}{TRANSACTION};

  if ($manage_transaction) {
    $db->{AutoCommit} = 0;
    $self->{Tasks}{db}{TRANSACTION} = 1;
  }

  return {
    rollback => sub {
      return if !$manage_transaction;

      delete $self->{Tasks}{db}{TRANSACTION};
      $db->rollback();
      $db->{AutoCommit} = 1;
    },
    commit   => sub {
      return if !$manage_transaction;

      delete $self->{Tasks}{db}{TRANSACTION};
      $db->commit();
      $db->{AutoCommit} = 1;
    }
  };
}

#**********************************************************
=head2 tasks_add($attr) - Add new task

  Arguments:
    $attr   - Extra attributes
       NAME          - Task name
       DESCR         - Task description
       PARENT_ID     - Parent task ID
       PATH          - Task path
       RESPONSIBLE   - Responsible admin ID
       CONTROL_DATE  - Due date

  Returns:
   HASH with INSERT_ID and TASK_ID or error structure

  Example:

    tasks_add({
      NAME        => 'Test task',
      DESCR       => 'Description',
      RESPONSIBLE => 1
    });

=cut
#**********************************************************
sub tasks_add {
  my ($self, $attr) = @_;

  $self->_address_add($attr);

  my $transaction = $self->_start_transaction();

  $self->{Tasks}->add($attr);
  my $task_id = $self->{Tasks}->{INSERT_ID};
  if ($self->{Tasks}->{errno} || !$task_id) {
    $transaction->{rollback}->();
    return $self->{Tasks};
  }

  if (!$attr->{PATH} && $attr->{PARENT_ID}) {
    my $task = $self->{Tasks}->info({ ID => $attr->{PARENT_ID} });
    if (!$self->{Tasks}->{errno} && !$task->{PATH}) {
      $self->{Tasks}->change({ ID => $attr->{PARENT_ID}, PATH => $attr->{PARENT_ID} });
      $task->{PATH} = $attr->{PARENT_ID};

      if ($self->{Tasks}->{errno}) {
        $transaction->{rollback}->();
        return {
          errno  => $self->{errno},
          errstr => $self->{errstr}
        };
      }
    }

    my $path = join('/', ($task->{PATH}, $task_id));
    $self->{Tasks}->change({ ID => $task_id, PATH => $path });
  }
  else {
    $self->{Tasks}->change({ ID => $task_id, PATH => $attr->{PATH} });
  }

  if ($self->{Tasks}->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $self->{errno},
      errstr => $self->{errstr}
    };
  }

  $transaction->{commit}->();

  if ($attr->{RESPONSIBLE}) {
    require Abills::Sender::Core;
    Abills::Sender::Core->import();
    my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

    $attr->{NAME} //= $self->{lang}{EMPTY};
    $attr->{DESCR} //= $self->{lang}{EMPTY};
    $attr->{CONTROL_DATE} //= '';

    $self->{lang}{TASK} //= 'Task';
    $self->{lang}{TASK_NAME} //= 'Task name';
    $self->{lang}{TASK_DESCRIBE} //= 'Task describe';
    $self->{lang}{DUE_DATE} //= 'Due date';

    my $message = <<"TEXT";
     $self->{lang}{TASK}
     $self->{lang}{TASK_NAME}: $attr->{NAME}
     $self->{lang}{TASK_DESCRIBE}: $attr->{DESCR}
     $self->{lang}{DUE_DATE}: $attr->{CONTROL_DATE}
TEXT

    $Sender->send_message_auto({
      AID     => $attr->{RESPONSIBLE},
      MESSAGE => $message,
      DEBUG   => 0
    });
  }

  return {
    INSERT_ID => $task_id,
    TASK_ID   => $task_id
  };
}

#**********************************************************
=head2 tasks_change($attr) - Change task

  Arguments:
    $attr   - Extra attributes
       ID            - Task ID
       NAME          - Task name
       DESCR         - Task description
       PARENT_ID     - Parent task ID
       PATH          - Task path
       STATE         - Task state
       CLOSED_DATE   - Task closed date

  Returns:
   OBJECT Tasks or error structure

  Example:

    tasks_change({
      ID    => 10,
      NAME  => 'Updated task',
      STATE => 1
    });

=cut
#********************************************************
sub tasks_change {
  my ($self, $attr) = @_;

  $self->_address_add($attr);

  my $task_id = $attr->{ID};
  if (!$task_id) {
    return $self->{Errors}->throw_error(1580002);
  }

  my $old_info = $self->{Tasks}->info({ ID => $task_id });
  my $old_path = $old_info->{PATH};
  my $old_state = $old_info->{STATE};

  if ($attr->{STATE} && $old_state ne $attr->{STATE}) {
    my $subtasks = $self->{Tasks}->list({ PARENT_ID => $task_id, STATE => '0' });
    return $self->{Errors}->throw_error(1580001) if ($self->{Tasks}->{TOTAL} && $self->{Tasks}->{TOTAL} > 0);
  }

  my $transaction = $self->_start_transaction();

  if ($attr->{PARENT_ID}) {
    my $task = $self->{Tasks}->info({ ID => $attr->{PARENT_ID} });
    if (!$self->{Tasks}->{errno} && !$task->{PATH}) {
      $self->{Tasks}->change({ ID => $attr->{PARENT_ID}, PATH => $attr->{PARENT_ID} });
      if ($self->{Tasks}->{errno}) {
        $transaction->{rollback}->();
        return $self->{Tasks};
      }

      $task->{PATH} = $attr->{PARENT_ID};
    }

    my $current_path = join('/', ($task->{PATH}, $task_id));

    if ($current_path ne $old_path) {
      $attr->{PATH} = $current_path;
      $self->{Tasks}->query("UPDATE tasks_main SET path = REPLACE(path, '$old_path', '$current_path') WHERE path LIKE '$old_path%';", 'do');
      if ($self->{Tasks}->{errno}) {
        $transaction->{rollback}->();
        return $self->{Tasks};
      }
    }
  }
  elsif (defined $attr->{PARENT_ID}) {
    $attr->{PATH} = $task_id;
  }

  $attr->{CLOSED_DATE} = $main::DATE if ($attr->{STATE} && !$attr->{CLOSED_DATE});

  $self->{Tasks}->change({ %{$attr}, ID => $task_id });
  if ($self->{Tasks}->{errno}) {
    $transaction->{rollback}->();
    return $self->{Tasks};
  }

  $transaction->{commit}->();

  return $self->{Tasks};
}

#**********************************************************
=head2 _address_add($attr) - Add address data

  Arguments:
    $attr   - Extra attributes
       DISTRICT_ID        - District ID
       ADD_ADDRESS_STREET - Flag to add street
       STREET_ID          - Street ID
       ADD_ADDRESS_BUILD  - Flag to add building

  Returns:
   VOID

  Example:

    _address_add({
      DISTRICT_ID        => 1,
      ADD_ADDRESS_STREET => 1
    });

=cut
#**********************************************************
sub _address_add {
  my ($self, $attr) = @_;

  if ($attr->{DISTRICT_ID} && $attr->{ADD_ADDRESS_STREET}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->street_add({ %$attr, COMMENTS => q{}, ID => '' });
    $attr->{STREET_ID} = $Address->{STREET_ID};
  }

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();

    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({ %$attr, COMMENTS => q{}, ID => '' });

    $attr->{LOCATION_ID} = $Address->{LOCATION_ID};
  }
}

1;