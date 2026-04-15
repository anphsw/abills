package Crm::Leads_service;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array days_in_month/;
use Crm::db::Crm;
use Control::Errors;

#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db               => $db,
    admin            => $admin,
    conf             => $conf,
    lang             => $attr->{lang} || {},
    html             => $attr->{html} || undef,
    libpath          => $attr->{libpath},

    _lead_cache      => {},
    _step_hash_cache => undef,
  };
  bless($self, $class);

  $self->{Crm} = Crm->new($db, $admin, $conf);

  $self->{Errors} = Control::Errors->new($db, $admin, $conf, {
    lang   => $attr->{lang},
    module => 'Crm'
  });

  $self->_init_handlers();

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

  my $db = $self->{Crm}{db}{db};
  my $manage_transaction = !$self->{Crm}{db}{TRANSACTION};

  if ($manage_transaction) {
    $db->{AutoCommit} = 0;
    $self->{Crm}{db}{TRANSACTION} = 1;
  }

  return {
    rollback => sub {
      return if !$manage_transaction;

      delete $self->{Crm}{db}{TRANSACTION};
      $db->rollback();
      $db->{AutoCommit} = 1;
    },
    commit => sub {
      return if !$manage_transaction;

      delete $self->{Crm}{db}{TRANSACTION};
      $db->commit();
      $db->{AutoCommit} = 1;
    }
  };
}

#**********************************************************
=head2 crm_lead_add($attr) - Add new CRM lead

  Arguments:
    $attr   - Lead attributes

  Returns:
    HASHREF
      INSERT_ID - ID of created lead
      LEAD_ID   - ID of created lead

  Example:

    crm_lead_add({
      NAME       => 'John Doe',
      PHONE      => '+380...',
      STREET_ID  => 12
    });

=cut
#**********************************************************
sub crm_lead_add {
  my ($self, $attr) = @_;

  my $transaction = $self->_start_transaction();

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID         => $attr->{STREET_ID},
      ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD}
    });
    $attr->{BUILD_ID} = $Address->{LOCATION_ID};
  }

  $self->{Crm}->crm_lead_add($attr);

  if ($self->{Crm}->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $self->{Crm}->{errno},
      errstr => $self->{Crm}->{errstr}
    };
  }

  my $lead_id = $self->{Crm}{INSERT_ID};
  $self->_process_workflow('isNew', $lead_id, {
    %$attr,
    NEW_LEAD_ID => $lead_id,
    LEAD_ID     => $lead_id
  });
  $transaction->{commit}->();

  return {
    INSERT_ID => $lead_id,
    LEAD_ID   => $lead_id
  };
}

#**********************************************************
=head2 crm_lead_change($attr) - Change CRM lead

  Arguments:
    $attr   - Lead attributes
       ID     - Lead ID

  Example:

    crm_lead_change({
      ID    => 10,
      NAME  => 'John Doe'
    });

=cut
#**********************************************************
sub crm_lead_change {
  my ($self, $attr) = @_;

  my $lead_id = $attr->{ID};
  return $self->{Errors}->throw_error(1230007) if (!$lead_id);

  my $transaction = $self->_start_transaction();

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID         => $attr->{STREET_ID},
      ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD}
    });
    $attr->{BUILD_ID} = $Address->{LOCATION_ID};
  }

  my $old_info = $self->{Crm}->crm_lead_info({ ID => $lead_id });

  my $change_result = $self->{Crm}->crm_lead_change($attr);

  if ($self->{Crm}->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $self->{Crm}->{errno},
      errstr => $self->{Crm}->{errstr}
    };
  }

  $self->_process_workflow('isChanged', $lead_id, {
    %$attr,
    OLD_INFO => $old_info,
    LEAD_ID  => $lead_id,
    CHANGED  => 1
  });
  $transaction->{commit}->();

  return $change_result;
}

#**********************************************************
=head2 crm_progressbar_comment_add($attr) - Add progress bar comment

  Arguments:
    $attr   - Comment attributes
       LEAD_ID - Lead ID

  Example:

    crm_progressbar_comment_add({
      LEAD_ID => 10,
      COMMENT => 'Contacted client'
    });

=cut
#**********************************************************
sub crm_progressbar_comment_add {
  my ($self, $attr) = @_;

  my $lead_id = $attr->{LEAD_ID};
  return $self->{Errors}->throw_error(1230007) if (!$lead_id);

  my $transaction = $self->_start_transaction();

  my $result = $self->{Crm}->progressbar_comment_add($attr);

  if ($self->{Crm}->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $self->{Crm}->{errno},
      errstr => $self->{Crm}->{errstr}
    };
  }

  $self->_process_workflow('newAction', $lead_id, {
    %$attr,
    LEAD_ID => $lead_id
  });
  $transaction->{commit}->();

  return $result;
}

#**********************************************************
=head2 _process_workflow($type, $lead_id, $attr) - Process CRM workflow

  Arguments:
    $type     - Workflow type
    $lead_id  - Lead ID
    $attr     - Workflow attributes

  Returns:
    OBJECT

  Example:

    $self->_process_workflow('isNew', 10, {
      LEAD_ID => 10
    });

=cut
#**********************************************************
sub _process_workflow {
  my ($self, $type, $lead_id, $attr) = @_;

  return if (!$type || !$lead_id);

  my $workflows = $self->_get_active_workflows($type);
  return if (!$workflows);

  my @matched = ();
  for my $wf_id (keys %$workflows) {
    if ($self->_check_conditions($workflows->{$wf_id}, $attr)) {
      push @matched, $wf_id;
    }
  }

  return if (!@matched);

  $self->_execute_actions(\@matched, $lead_id);

  return $self;
}

#**********************************************************
=head2 _get_active_workflows($type) - Get active CRM workflows by type

  Arguments:
    $type   - Workflow trigger type

  Returns:
    HASHREF

  Example:

    my $workflows = $self->_get_active_workflows('isNew');

=cut
#**********************************************************
sub _get_active_workflows {
  my ($self, $type) = @_;

  my $core_triggers = $self->{Crm}->crm_workflow_triggers_list({
    TYPE            => $type,
    WORKFLOW_STATUS => '0',
    WORKFLOW_ID     => '_SHOW',
    COLS_NAME       => 1
  });
  return if (!$self->{Crm}->{TOTAL} || $self->{Crm}->{TOTAL} < 1);

  my $workflow_ids = [];
  map push(@$workflow_ids, $_->{workflow_id}), @$core_triggers;

  my $triggers = $self->{Crm}->crm_workflow_triggers_list({
    NEW_VALUE       => '_SHOW',
    OLD_VALUE       => '_SHOW',
    TYPE            => '_SHOW',
    WORKFLOW_STATUS => '0',
    WORKFLOW_ID     => join(';', @$workflow_ids),
    COLS_NAME       => 1
  });
  return if (!$self->{Crm}->{TOTAL} || $self->{Crm}->{TOTAL} < 1);

  my %workflows = ();
  for my $trigger (@$triggers) {
    push @{$workflows{$trigger->{workflow_id}}}, $trigger;
  }

  return \%workflows;
}

#**********************************************************
=head2 _check_conditions($triggers, $attr) - Check workflow trigger conditions

  Arguments:
    $triggers - Workflow triggers list
    $attr     - Workflow attributes

  Returns:
    TRUE or FALSE

  Example:

    my $result = $self->_check_conditions($triggers, {
      LEAD_ID => 10
    });

=cut
#**********************************************************
sub _check_conditions {
  my ($self, $triggers, $attr) = @_;

  for my $trigger (@$triggers) {
    my $handler = $self->{workflow_triggers}{$trigger->{type}};
    return 0 if (!$handler);
    return 0 if (!$handler->($trigger, $attr));
  }

  return 1;
}

#**********************************************************
=head2 _execute_actions($workflow_ids, $lead_id) - Execute workflow actions

  Arguments:
    $workflow_ids - Workflow IDs list
    $lead_id      - Lead ID

  Example:

    $self->_execute_actions([1, 2, 3], 10);

=cut
#**********************************************************

sub _execute_actions {
  my ($self, $workflow_ids, $lead_id) = @_;

  my $actions = $self->{Crm}->crm_workflow_actions_list({
    WORKFLOW_ID => join(';', @$workflow_ids),
    TYPE        => '_SHOW',
    VALUE       => '_SHOW',
    COLS_NAME   => 1
  });

  return if (!$actions || !@$actions);

  for my $action (@$actions) {
    my $handler = $self->{workflow_actions}{$action->{type}};
    next if (!$handler);

    $handler->($action, $lead_id);
  }

  return;
}

#**********************************************************
=head2 _get_cached_lead($lead_id) - Get cached CRM lead info

  Arguments:
    $lead_id - Lead ID

  Returns:
    HASHREF

  Example:

    my $lead = $self->_get_cached_lead(10);

=cut
#**********************************************************
sub _get_cached_lead {
  my ($self, $lead_id) = @_;

  if (!exists $self->{_lead_cache}{$lead_id}) {
    $self->{_lead_cache}{$lead_id} = $self->{Crm}->crm_lead_info({ ID => $lead_id });
  }

  return $self->{_lead_cache}{$lead_id};
}

#**********************************************************
=head2 _get_step_hash() - Get cached lead step hash

  Arguments:
    none

  Returns:
    HASHREF

  Example:

    my $steps = $self->_get_step_hash();

=cut
#**********************************************************
sub _get_step_hash {
  my ($self) = @_;

  if (!defined $self->{_step_hash_cache}) {
    $self->{_step_hash_cache} = $self->{Crm}->crm_step_number_leads();
  }

  return $self->{_step_hash_cache};
}

#**********************************************************
=head2 _get_cached_field($attr, $field) - Get cached lead field value

  Arguments:
    $attr   - Attributes hash
    $field  - Field name

  Example:

    my $value = $self->_get_cached_field($attr, 'STATUS');

=cut
#**********************************************************

sub _get_cached_field {
  my ($self, $attr, $field) = @_;

  return $attr->{$field} if (defined $attr->{$field});
  return $attr->{OLD_INFO}{$field} if (defined $attr->{OLD_INFO}{$field});

  if ($attr->{LEAD_ID}) {
    my $lead = $self->_get_cached_lead($attr->{LEAD_ID});
    return $lead->{$field};
  }

  return;
}

#**********************************************************
=head2 _get_cached_step($attr) - Get cached lead step info

  Arguments:
    $attr - Attributes hash

  Example:

    my $step = $self->_get_cached_step({
      LEAD_ID => 10
    });

=cut
#**********************************************************
sub _get_cached_step {
  my ($self, $attr) = @_;

  my $step_id = $attr->{CURRENT_STEP};

  if (!$step_id) {
    return if (!$attr->{LEAD_ID});
    my $lead = $self->_get_cached_lead($attr->{LEAD_ID});
    $step_id = $lead->{CURRENT_STEP};
  }

  return if (!$step_id);

  my $step_hash = $self->_get_step_hash();
  return $step_hash->{$step_id};
}

#**********************************************************
=head2 _init_handlers() - Initialize workflow triggers and actions handlers

  Example:

    $self->_init_handlers();

=cut
#**********************************************************
sub _init_handlers {
  my ($self) = @_;

  my $service = $self;

  $self->{workflow_triggers} = {
    isNew => sub {
      my (undef, $attr) = @_;

      return 1 if ($attr->{NEW_LEAD_ID});
    },

    isChanged => sub {
      my (undef, $attr) = @_;

      return 1 if ($attr->{CHANGED});
    },

    newAction => sub {
      my ($trigger, $attr) = @_;
      return 0 if (!defined $trigger->{new_value} && !defined $trigger->{old_value});

      if ($trigger->{new_value}) {
        my @ids = split /,\s?/, $trigger->{new_value};
        return 0 if (!in_array($attr->{ACTION_ID}, \@ids));
      }
      if ($trigger->{old_value}) {
        my @ids = split /,\s?/, $trigger->{old_value};
        return 0 if (!in_array($attr->{AID}, \@ids));
      }
      return 1;
    },

    newTask => sub {
      my ($trigger, $attr) = @_;
      return 0 if (!defined $trigger->{new_value});
      my @ids = split /,\s?/, $trigger->{new_value};
      return in_array($attr->{TASK_TYPE}, \@ids) ? 1 : 0;
    },

    closedTask => sub {
      my ($trigger, $attr) = @_;
      return 0 if (!defined $trigger->{new_value} || $attr->{STATE} ne '1');
      my @ids = split /,\s?/, $trigger->{new_value};
      return in_array($attr->{TASK_TYPE}, \@ids) ? 1 : 0;
    },

    responsible => sub {
      my ($trigger, $attr) = @_;
      return 1 if (!$trigger->{new_value});

      my $resp = $service->_get_cached_field($attr, 'RESPONSIBLE');
      return 0 if (!defined $resp);

      my @allowed = split /,\s?/, $trigger->{new_value};
      return in_array($resp, \@allowed) ? 1 : 0;
    },

    responsibleChanged => sub {
      my ($trigger, $attr) = @_;
      return 0 if (!defined $trigger->{new_value} ||
        !defined $trigger->{old_value} ||
        !defined $attr->{RESPONSIBLE});

      $attr->{OLD_INFO}{RESPONSIBLE} = '' if (!defined $attr->{OLD_INFO}{RESPONSIBLE});
      return ($trigger->{new_value} eq $attr->{RESPONSIBLE} &&
        $trigger->{old_value} eq $attr->{OLD_INFO}{RESPONSIBLE}) ? 1 : 0;
    },

    stepChanged => sub {
      my ($trigger, $attr) = @_;
      return 0 if (!$trigger->{new_value} ||
        !$attr->{CURRENT_STEP} ||
        !$attr->{OLD_INFO}{CURRENT_STEP});

      my $step_hash = $service->_get_step_hash();
      my $current = $step_hash->{$attr->{CURRENT_STEP}};
      return 0 if (!$current);

      my $old = $step_hash->{$attr->{OLD_INFO}{CURRENT_STEP}};
      return 0 if (!$old);

      my @old_steps = split /,\s?/, $trigger->{old_value};
      return ($trigger->{new_value} == $current && in_array($old, \@old_steps)) ? 1 : 0;
    },

    step => sub {
      my ($trigger, $attr) = @_;
      return 1 if (!$trigger->{new_value});

      my $current = $service->_get_cached_step($attr);
      return 0 if (!$current);

      my @allowed = split /,\s?/, $trigger->{new_value};
      return in_array($current, \@allowed) ? 1 : 0;
    },

    priority => sub {
      my ($trigger, $attr) = @_;
      return 1 if (!defined $trigger->{new_value});

      my $priority = $service->_get_cached_field($attr, 'PRIORITY');
      $priority = defined $priority && !$priority ? 0 : $priority;
      return 0 if (!defined $priority);

      my @allowed = split /,\s?/, $trigger->{new_value};
      return in_array($priority, \@allowed) ? 1 : 0;
    }
  };

  $self->{workflow_actions} = {
    addAction => sub {
      my ($action, $lead_id) = @_;
      return if ($action->{value} !~ /;/);

      my ($action_id, $aid, $priority, $plan_date, $message) = split /;/, $action->{value}, 5;
      return if (!$action_id || !$aid);

      my $lead = $service->_get_cached_lead($lead_id);
      my $step_hash = $service->_get_step_hash();

      $service->{Crm}->progressbar_comment_add({
        LEAD_ID      => $lead_id,
        STEP_ID      => $step_hash->{$lead->{CURRENT_STEP}} || 1,
        PRIORITY     => $priority,
        ACTION_ID    => $action_id,
        AID          => $aid,
        PLANNED_DATE => $plan_date,
        MESSAGE      => $message
      });
    },

    addTask => sub {
      my ($action, $lead_id) = @_;
      return if (!in_array('Tasks', \@main::MODULES) || $action->{value} !~ /;/);

      my ($task_type, $name, $aid, $days) = split /;/, $action->{value}, 4;
      return if (!$task_type || !$name);

      my $lead = $service->_get_cached_lead($lead_id);
      my $responsible = ($aid && $aid =~ /^\d+$/) ? $aid : $lead->{RESPONSIBLE};

      my $plan_date = '';
      if ($days && $days =~ /^\d+$/) {
        require POSIX;
        $plan_date = POSIX::strftime("%Y-%m-%d", localtime(time + $days * 86400));
      }

      require Tasks::db::Tasks;
      Tasks->import();

      my $Tasks = Tasks->new($service->{db}, $service->{admin}, $service->{conf});
      $Tasks->add({
        AID          => $service->{admin}{AID},
        TASK_TYPE    => $task_type,
        RESPONSIBLE  => $responsible,
        NAME         => $name,
        LEAD_ID      => $lead_id,
        STEP_ID      => $lead->{CURRENT_STEP},
        PLAN_DATE    => $plan_date,
        CONTROL_DATE => $plan_date
      });
    },

    setStep => sub {
      my ($action, $lead_id) = @_;
      return if (!$lead_id || !$action->{value});

      my $step = $service->{Crm}->crm_progressbar_step_info({ ID => $action->{value} });
      return if (!$step->{STEP_NUMBER});

      $service->{Crm}->crm_lead_change({
        ID           => $lead_id,
        CURRENT_STEP => $step->{STEP_NUMBER}
      });

      # Invalidate cache
      delete $service->{_lead_cache}{$lead_id};
    },

    setResponsible => sub {
      my ($action, $lead_id) = @_;
      return if (!$lead_id || !defined $action->{value});

      $service->{Crm}->crm_lead_change({
        ID          => $lead_id,
        RESPONSIBLE => $action->{value}
      });

      delete $service->{_lead_cache}{$lead_id};
    },

    setPriority => sub {
      my ($action, $lead_id) = @_;
      return if (!$lead_id || !defined $action->{value});

      $service->{Crm}->crm_lead_change({
        ID       => $lead_id,
        PRIORITY => $action->{value}
      });

      delete $service->{_lead_cache}{$lead_id};
    },

    sendMessage => sub {
      my ($action, $lead_id) = @_;
      return if (!$action->{value});

      my $lead = $service->_get_cached_lead($lead_id);
      my $step_hash = $service->_get_step_hash();

      $service->{Crm}->progressbar_comment_add({
        LEAD_ID => $lead_id,
        STEP_ID => $step_hash->{$lead->{CURRENT_STEP}} || 1,
        MESSAGE => $action->{value},
        DATE    => "$main::DATE $main::TIME"
      });
    },

    sendMessageToResponsible => sub {
      my ($action, $lead_id) = @_;

      my ($subject, $message) = split /;/, $action->{value}, 2;
      return if (!$subject || !$message);

      my $lead = $service->_get_cached_lead($lead_id);
      return if (!$lead->{RESPONSIBLE});

      while ($message =~ /%(\w+)%/g) {
        my $var = $1;
        my $value = defined $lead->{$var} ? $lead->{$var} : '';
        $message =~ s/%$var%/$value/g;
      }

      require Abills::Sender::Core;
      Abills::Sender::Core->import();

      my $Sender = Abills::Sender::Core->new($service->{db}, $service->{admin}, $service->{conf});
      $Sender->send_message_auto({
        AID     => $lead->{RESPONSIBLE},
        MESSAGE => $message,
        SUBJECT => $subject,
        SOURCE  => 'Crm'
      });
    },

    runPlugin => sub {
      my ($action, $lead_id) = @_;
      return if (!$action->{value});

      my $plugin_name = 'Crm::Plugins::Workflow::' . $action->{value};
      my $module_path = $plugin_name;
      $module_path =~ s{::}{/}g;
      $module_path .= '.pm';

      eval { require $module_path };
      return if ($@);
      return if (!$plugin_name->can('new') || !$plugin_name->can('execute'));

      my $plugin = $plugin_name->new(@{$service}{qw/db admin conf/});
      $plugin->execute($lead_id);
    }
  };
}

1;