package Control::Contacts;

=head1 NAME

  Control::Contacts - Business logic for contacts management

  ERROR ID: 100005Х

=cut

use strict;
use warnings FATAL => 'all';

use Contacts;
use Control::Errors;

my Control::Errors $Errors;

use constant DEFAULT_CONTACT_TYPES => {
  CELL_PHONE  => 1,
  PHONE       => 2,
  SKYPE       => 3,
  ICQ         => 4,
  VIBER       => 5,
  TELEGRAM    => 6,
  EMAIL       => 9,
  GOOGLE_PUSH => 10,
};

use constant CONTACT_TYPES_ERROR_VALIDATION => {
  DEFAULT_CONTACT_TYPES->{EMAIL}      => 'ERR_WRONG_EMAIL',
  DEFAULT_CONTACT_TYPES->{CELL_PHONE} => 'ERR_WRONG_CELL_PHONE_FORMAT',
  DEFAULT_CONTACT_TYPES->{PHONE}      => 'ERR_WRONG_PHONE_FORMAT',
};

use constant {
  METHOD_DELETE => 'contacts_del',
  METHOD_ADD    => 'contacts_add',
  METHOD_CHANGE => 'contacts_change',
  METHOD_LIST   => 'contacts_list',
};


#**********************************************************
=head2 new($db, $admin, $conf, $attr)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db         => $db,
    admin      => $admin,
    conf       => $conf,
    lang       => $attr->{lang} || {},
    role       => $attr->{role} || 'user',
    validators => {
      DEFAULT_CONTACT_TYPES->{EMAIL} => $Abills::Filters::EMAIL_EXPR
    }
  };

  if ($self->{role} eq 'admin') {
    $self->{handler} = $admin;
  } else {
    $self->{handler} = Contacts->new($db, $admin, $conf);
  }

  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang   => $self->{lang},
    parent => $self
  });

  $self->{method_map} = _get_method_map($self->{role});
  $self->{owner_field} = ($self->{role} eq 'admin') ? 'AID' : 'UID';

  if ($conf->{CELL_PHONE_FORMAT}) {
    $self->{validators}{DEFAULT_CONTACT_TYPES->{CELL_PHONE}} = $conf->{CELL_PHONE_FORMAT};
  }

  if ($conf->{PHONE_FORMAT}) {
    $self->{validators}{DEFAULT_CONTACT_TYPES->{PHONE}} = $conf->{PHONE_FORMAT};
  }

  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 _get_method_map($role) - Get method map based on role

  Arguments:
    $role - The role ('user' or 'admin')

  Returns:
    A hashref containing the method mappings.

  Example:
    my $method_map = _get_method_map('admin');

=cut
#**********************************************************
sub _get_method_map {
  my ($role) = @_;

  if ($role && $role eq 'admin') {
    return {
      METHOD_DELETE() => 'admin_contacts_del',
      METHOD_ADD()    => 'admin_contacts_add',
      METHOD_CHANGE() => 'admin_contacts_change',
      METHOD_LIST()   => 'admins_contacts_list',
    };
  }

  return {
    METHOD_DELETE() => 'contacts_del',
    METHOD_ADD()    => 'contacts_add',
    METHOD_CHANGE() => 'contacts_change',
    METHOD_LIST()   => 'contacts_list',
  };
}

#**********************************************************
=head2 _transform_params($params) - Transform parameters for the handler method

  Arguments:
    $params - A hashref of parameters.
      owner_id - The ID of the owner (user or admin)

  Returns:
    A hashref with transformed parameters (e.g., owner_id is mapped to UID or AID).

  Example:
    my $transformed = $self->_transform_params({ owner_id => 1, VALUE => 'test@example.com' });

=cut
#**********************************************************
sub _transform_params {
  my ($self, $params) = @_;

  my %transformed = %$params;

  if (exists $transformed{owner_id}) {
    $transformed{$self->{owner_field}} = delete $transformed{owner_id};
  }

  return \%transformed;
}

#**********************************************************
=head2 _call_contacts_method($method_name, $params) - Call a method on the appropriate contacts handler

  Arguments:
    $method_name - The name of the method to call (e.g., METHOD_ADD).
    $params      - A hashref of parameters for the method.

  Returns:
    The result from the called handler method, or an error hash on failure.

  Example:
    $self->_call_contacts_method(METHOD_ADD, { owner_id => 1, TYPE_ID => 9, VALUE => 'test@example.com' });

=cut
#**********************************************************
sub _call_contacts_method {
  my ($self, $method_name, $params) = @_;

  if (!exists $self->{method_map}{$method_name}) {
    return $Errors->throw_error(1000058, { errstr => 'ERR_CONTACTS_UNKNOWN_METHOD' });
  }

  my $actual_method = $self->{method_map}{$method_name};

  if (!$self->{handler}->can($actual_method)) {
    return $Errors->throw_error(1000059, { errstr => 'ERR_CONTACTS_METHOD_NOT_FOUND' });
  }

  my $transformed_params = $self->_transform_params($params);

  return $self->{handler}->$actual_method($transformed_params);
}

#**********************************************************
=head2 _validate_owner_id($owner_id) - Validate the owner ID

  Arguments:
    $owner_id - The ID of the owner (user or admin) to validate.

  Returns:
    undef on success, or an error hash on failure.

  Example:
    my $error = $self->_validate_owner_id(123);
    return $error if $error;

=cut
#**********************************************************
sub _validate_owner_id {
  my ($self, $owner_id) = @_;

  if (!$owner_id || $owner_id !~ /^\d+$/x) {
    return $Errors->throw_error(1000050, {
      errstr => $self->{role} eq 'admin' ? 'ERR_AID_NOT_DEFINED' : 'ERR_UID_NOT_DEFINED'
    });
  }
  return;
}

#**********************************************************
=head2 validate_contacts(\%contact) - Validate a single contact hash

  Arguments:
    $contact - A hashref representing a contact.
      TYPE_ID - The type ID of the contact (required, numeric).
      VALUE   - The value of the contact (required, string).

  Returns:
    undef on success, or an error hash on failure.

  Example:
    my $error = $self->validate_contacts({ TYPE_ID => 9, VALUE => 'invalid-email' });
    if ($error) {
      return $error;
    }

=cut
#**********************************************************
sub validate_contacts {
  my ($self, $contact) = @_;

  if (ref $contact ne 'HASH') {
    return $Errors->throw_error(1000051, { errstr => 'ERR_CONTACTS_INVALID_FORMAT' });
  }

  if (!$contact->{TYPE_ID}) {
    return $Errors->throw_error(1000052, { errstr => 'ERR_CONTACT_TYPE_REQUIRED' });
  }

  if ($contact->{TYPE_ID} !~ /^\d+$/x) {
    return $Errors->throw_error(1000053, { errstr => 'ERR_CONTACT_TYPE_INVALID' });
  }

  if (!defined $contact->{VALUE}) {
    return $Errors->throw_error(1000054, { errstr => 'ERR_CONTACT_VALUE_REQUIRED' });
  }

  if ($self->{validators}{$contact->{TYPE_ID}} && $contact->{VALUE} && $contact->{VALUE} !~ m/$self->{validators}{$contact->{TYPE_ID}}/x) {
    return $Errors->throw_error(1000055, { errstr => CONTACT_TYPES_ERROR_VALIDATION->{$contact->{TYPE_ID}} });
  }

  return;
}

#**********************************************************
=head2 renew_contacts($owner_id, \@contacts, $attr) - Renew all contacts for an owner

  Deletes all existing contacts for the owner and adds the new ones. This is a transactional operation.

  Arguments:
    $owner_id - The ID of the owner (user or admin).
    $contacts - An arrayref of contact hashrefs to set.
    $attr     - Extra attributes.
      LIST_PARAMS - Parameters to pass to the final contacts_list call.

  Returns:
    A hashref with the new list of contacts on success, or an error hash on failure.

  Example:
    my $new_contacts = $self->renew_contacts(123, [
      { TYPE_ID => 1, VALUE => '+380501234567' },
      { TYPE_ID => 9, VALUE => 'new.email@example.com' }
    ]);

=cut
#**********************************************************
sub renew_contacts {
  my ($self, $owner_id, $contacts, $attr) = @_;

  $attr ||= {};

  my $error = $self->_validate_owner_id($owner_id);
  if ($error && ref $error eq 'HASH' && $error->{errno}) {
    return $error;
  }

  if (!$contacts || ref $contacts ne 'ARRAY') {
    return $Errors->throw_error(1000057, { errstr => 'ERR_CONTACTS_INVALID_FORMAT' });
  }

  my $transaction = $self->_start_transaction();

  $self->_call_contacts_method(METHOD_DELETE, { owner_id => $owner_id });

  if ($self->{handler}->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $self->{handler}->{errno},
      errstr => $self->{handler}->{errstr}
    };
  }

  my $old_contacts = $self->{handler}->{OLD_INFO} || {};
  my @changed_contacts = ();

  my @added_ids;
  foreach my $contact (@$contacts) {
    my $val_result = $self->validate_contacts($contact);
    if ($val_result && ref $val_result eq 'HASH' && $val_result->{errno}) {
      if ($self->{lang} && $self->{lang}{$val_result->{errstr}}) {
        $val_result->{errmsg} ||= $self->{lang}{$val_result->{errstr}};
      }
      $transaction->{rollback}->();
      return $val_result;
    }

    $self->_call_contacts_method(METHOD_ADD, {
      %$contact,
      owner_id => $owner_id
    });

    if ($self->{handler}->{errno}) {
      $transaction->{rollback}->();
      return {
        errno  => $self->{handler}->{errno},
        errstr => $self->{handler}->{errstr}
      };
    }

    if ($old_contacts->{$contact->{TYPE_ID}} && $old_contacts->{$contact->{TYPE_ID}} ne $contact->{VALUE}) {
      push @changed_contacts, {
        TYPE_ID => $contact->{TYPE_ID},
        FROM    => $old_contacts->{$contact->{TYPE_ID}},
        TO      => $contact->{VALUE}
      }
    }

    push @added_ids, $self->{handler}->{INSERT_ID};
  }

  if (scalar(@changed_contacts) > 0 && $self->{role} eq 'user') {
    my %crossmodules_params = (
      USER_INFO        => {
        UID => $owner_id
      },
      CHANGED_CONTACTS => \@changed_contacts,
      UID              => $owner_id,
      SILENT           => 1,
      QUITE            => 1
    );

    my $result = ::cross_modules('contacts_changed', \%crossmodules_params);
    if ($result && ref $result eq 'HASH') {
      foreach my $module (keys %{$result}) {
        next if (ref $result->{$module} ne 'HASH');

        if ($result->{$module}->{errno}) {
          $transaction->{rollback}->();
          $result->{$module}->{errstr} = "$module: " . ($result->{$module}->{errstr} || '');
          return $result->{$module};
        }
      }
    }
  }

  $transaction->{commit}->();

  return $self->contacts_list({ owner_id => $owner_id });
}

#**********************************************************
=head2 contacts_list($attr) - Get contacts

  Arguments:
    $attr     - Extra attributes to filter the list (passed to the handler).
      COLS_NAME - Set to 1 to get column names in the result.

  Returns:
    A hashref containing the list of contacts and the total count, or an error hash on failure.
    {
      list  => \@contacts,
      total => $total_count
    }

  Example:
    my $result = $self->contacts_list({ owner_id => $owner_id });

=cut
#**********************************************************
sub contacts_list {
  my ($self, $attr) = @_;

  $attr ||= {};

  my $list = $self->_call_contacts_method(METHOD_LIST, {
    VALUE     => '_SHOW',
    PRIORITY  => '_SHOW',
    TYPE      => '_SHOW',
    TYPE_NAME => '_SHOW',
    COMMENTS  => '_SHOW',
    DEFAULT   => '_SHOW',
    HIDDEN    => '0',
    COLS_NAME => 1,
    %$attr
  });

  if ($self->{handler}->{errno}) {
    return {
      errno  => $self->{handler}->{errno},
      errstr => $self->{handler}->{errstr}
    };
  }

  return {
    list   => $list || [],
    total  => $self->{handler}->{TOTAL}
  };
}

#**********************************************************
=head2 add_contact($owner_id, \%contact_data) - Add a single contact for an owner

  Arguments:
    $owner_id     - The ID of the owner (user or admin).
    $contact_data - A hashref representing the contact to add.
      TYPE_ID - The type ID of the contact.
      VALUE   - The value of the contact.
      ...     - Other optional fields like PRIORITY, COMMENTS, etc.

  Returns:
    A hashref with the new contact's ID on success, or an error hash on failure.
    {
      id        => $new_id,
      INSERT_ID => $new_id
    }

  Example:
    my $result = $self->add_contact(123, {
      TYPE_ID => 9,
      VALUE   => 'work@example.com',
      COMMENTS => 'Work Email'
    });

=cut
#**********************************************************
sub add_contact {
  my ($self, $owner_id, $contact_data) = @_;

  my $error = $self->_validate_owner_id($owner_id);
  if ($error && ref $error eq 'HASH' && $error->{errno}) {
    return $error;
  }

  my $val_result = $self->validate_contacts($contact_data);
  if ($val_result && ref $val_result eq 'HASH' && $val_result->{errno}) {
    return $val_result;
  }

  $self->_call_contacts_method(METHOD_ADD, {
    %$contact_data,
    owner_id => $owner_id
  });

  if ($self->{handler}->{errno}) {
    return {
      errno  => $self->{handler}->{errno},
      errstr => $self->{handler}->{errstr}
    };
  }

  return {
    id        => $self->{handler}->{INSERT_ID},
    INSERT_ID => $self->{handler}->{INSERT_ID}
  };
}

#**********************************************************
=head2 change_contact($owner_id, \%contact_data) - Update a single contact

  Arguments:
    $owner_id     - The ID of the owner (user or admin).
    $contact_data - A hashref representing the contact data to update.
      ID      - The ID of the contact to update (required).
      VALUE   - The new value for the contact.
      ...     - Other fields to update.

  Returns:
    The handler's response object on success, or an error hash on failure.

  Example:
    my $result = $self->change_contact(123, {
      ID      => 15,
      VALUE   => 'personal@example.com',
      DEFAULT => 1
    });

=cut
#**********************************************************
sub change_contact {
  my ($self, $owner_id, $contact_data) = @_;

  my $contact_id = $self->{role} eq 'admin' ? undef : $contact_data->{ID};

  my $error = $self->_validate_owner_id($owner_id);
  if ($error && ref $error eq 'HASH' && $error->{errno}) {
    return $error;
  }

  if ($self->{role} ne 'admin' && (!$contact_id || $contact_id !~ /^\d+$/x)) {
    return $Errors->throw_error(1000056, { errstr => 'ERR_CONTACT_ID_REQUIRED' });
  }

  my $val_result = $self->validate_contacts($contact_data);
  if ($val_result && ref $val_result eq 'HASH' && $val_result->{errno}) {
    return $val_result;
  }

  $self->_call_contacts_method(METHOD_CHANGE, {
    %$contact_data,
    ID       => $contact_id,
    owner_id => $owner_id
  });

  if ($self->{handler}->{errno}) {
    return {
      errno  => $self->{handler}->{errno},
      errstr => $self->{handler}->{errstr}
    };
  }

  return $self->{handler};
}

#**********************************************************
=head2 del_contact($owner_id, $contact_id) - Delete a single contact

  Arguments:
    $owner_id   - The ID of the owner (user or admin).
    $contact_id - The ID of the contact to delete.

  Returns:
    An empty hashref on success, or an error hash on failure.

  Example:
    my $result = $self->del_contact(123, 15);

=cut
#**********************************************************
sub del_contact {
  my ($self, $owner_id, $contact_id) = @_;

  my $error = $self->_validate_owner_id($owner_id);
  if ($error && ref $error eq 'HASH' && $error->{errno}) {
    return $error;
  }

  if (!$contact_id || $contact_id !~ /^\d+$/x) {
    return $Errors->throw_error(1000056, { errstr => 'ERR_CONTACT_ID_REQUIRED' });
  }

  $self->_call_contacts_method(METHOD_DELETE, {
    ID       => $contact_id,
    owner_id => $owner_id
  });
  if ($self->{handler}->{errno}) {
    return {
      errno  => $self->{handler}->{errno},
      errstr => $self->{handler}->{errstr}
    };
  }

  return {};
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

  my $db = $self->{handler}->{db}{db};
  my $manage_transaction = !$self->{handler}->{db}->{TRANSACTION};

  if ($manage_transaction) {
    $db->{AutoCommit} = 0;
    $self->{handler}->{db}->{TRANSACTION} = 1;
  }

  return {
    rollback => sub {
      return if !$manage_transaction;

      delete $self->{handler}->{db}->{TRANSACTION};
      $db->rollback();
      $db->{AutoCommit} = 1;
    },
    commit => sub {
      return if !$manage_transaction;

      delete $self->{handler}->{db}->{TRANSACTION};
      $db->commit();
      $db->{AutoCommit} = 1;
    }
  };
}

1;