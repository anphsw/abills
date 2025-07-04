package Api::Controllers::User::Contacts;

=head1 NAME

  User API Contacts

  Endpoints:
    /user/contacts/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;
use Control::Errors;

use Contacts;

my Control::Errors $Errors;
my Contacts $Contacts;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};
  $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 get_user_contacts_id($path_params, $query_params)

  Endpoint GET /user/contacts/:id/

=cut
#**********************************************************
sub get_user_contacts_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $validation = $self->_validate_allowed_types_contacts($path_params->{id});
  return $validation if ($validation->{errno});

  $Contacts->contacts_del({
    UID     => $path_params->{uid},
    TYPE_ID => $path_params->{id}
  });

  if (!$Contacts->{errno}) {
    if ($Contacts->{AFFECTED} && $Contacts->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result =>  'Successfully deleted'
      };
    }
    else {
      return {
        errno  => 10089,
        errstr => "Push contact with typeId $path_params->{id} not found",
      };
    }
  }
  else {
    return {
      errno  => 10090,
      errstr => "Failed delete contact with typeId $path_params->{id}, error happened try later",
    };
  }
}

#**********************************************************
=head2 post_user_contacts_push_subscribe_id($path_params, $query_params)

  Endpoint POST /user/contacts/push/subscribe/:id/

=cut
#**********************************************************
sub post_user_contacts_push_subscribe_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errstr => 'No field token in body',
    errno  => 5000
  } if (!$query_params->{TOKEN});

  my $validation = $self->_validate_allowed_types_push($path_params->{id});
  return $validation if ($validation->{errno});

  require Abills::Sender::Push;
  my $Push = Abills::Sender::Push->new($self->{conf}, { db => $self->{db}, admin => $self->{admin} });
  my $status = $Push->dry_run({
    TOKEN => $query_params->{TOKEN} || '',
  });

  return {
    internal_status => $status,
    errno           => 5004,
    errstr          => 'Invalid FCM token',
  } if ($status);

  my $list = $Contacts->push_contacts_list({
    VALUE => $query_params->{TOKEN},
    UID   => '_SHOW',
    AID   => '_SHOW',
  });

  if ($list && !scalar(@{$list})) {
    return $self->_add_fcm_token($path_params, $query_params);
  }
  else {
    if ($list->[0]->{aid}) {
      return {
        errstr => 'Token already used. Can\'t add again',
        errno  => 5002
      };
    }
    elsif (!$path_params->{uid}) {
      return {
        errstr => 'Token already used. Can\'t add again',
        errno  => 5001,
      };
    }
    else {
      if ("$list->[0]->{uid}" eq "$path_params->{uid}") {
        return {
          errstr => 'You are already subscribed',
          errno  => 5003,
        };
      }

      if ($path_params->{uid}) {
        $self->delete_user_contacts_push_subscribe_id($path_params, $query_params, {
          SKIP_DEL_STATUS => 1,
          TOKEN           => $query_params->{TOKEN},
          UID             => $list->[0]->{uid}
        });
      }

      return $self->_add_fcm_token($path_params, $query_params);
    }
  }
}

#**********************************************************
=head2 delete_user_contacts_push_subscribe_id($path_params, $query_params)

  Endpoint DELETE /user/contacts/push/subscribe/:id/

=cut
#**********************************************************
sub delete_user_contacts_push_subscribe_id {
  my $self = shift;
  my ($path_params, $query_params, $attr) = @_;
  $attr //= {};

  my $validation = $self->_validate_allowed_types_push($path_params->{id});
  return $validation if ($validation->{errno});

  my $message = 'OK';

  my %params = (
    TYPE_ID => $path_params->{id},
    UID     => $attr->{UID} || $path_params->{uid},
  );

  $params{VALUE} = $attr->{TOKEN} || $path_params->{token} if ($path_params->{token} || $attr->{TOKEN});

  $Contacts->push_contacts_del(\%params);

  if (!$Contacts->{errno} && !$attr->{SKIP_DEL_STATUS}) {
    if ($Contacts->{AFFECTED} && $Contacts->{AFFECTED} =~ /^[0-9]$/) {
      $message = 'Successfully deleted';
    }
    else {
      return {
        errno  => 10084,
        errstr => "Push contact with typeId $path_params->{id} not found",
      };
    }
  }

  if (in_array('Ureports', \@main::MODULES)) {
    $Contacts->{TOTAL} = 0;
    $Contacts->push_contacts_list({
      UID     => $path_params->{uid},
    });

    if (!$Contacts->{TOTAL}) {
      my $Ureports = '';
      eval {require Ureports; Ureports->import()};
      if (!$@) {
        $Ureports = Ureports->new($self->{db}, $self->{admin}, $self->{conf});
        $Ureports->user_send_type_del({
          TYPE => 10,
          UID  => $path_params->{uid}
        });
      }
    }
  }

  return {
    result => $message,
  };
}

#**********************************************************
=head2 delete_user_contacts_push_subscribe_id_string_token($path_params, $query_params)

  Endpoint DELETE /user/contacts/push/subscribe/:id/:string_token/

=cut
#**********************************************************
sub delete_user_contacts_push_subscribe_id_string_token {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # TODO: that's crazy path, redo.
  return $self->delete_user_contacts_push_subscribe_id($path_params, $query_params, { TOKEN => $path_params->{token} })
}

#**********************************************************
=head2 get_user_contacts_push_subscribe_id($path_params, $query_params)

  Endpoint DELETE /user/contacts/push/subscribe/:id/

=cut
#**********************************************************
sub get_user_contacts_push_subscribe_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $validation = $self->_validate_allowed_types_push($path_params->{id});
  return $validation if ($validation->{errno});

  my $list = $Contacts->push_contacts_list({
    UID     => $path_params->{uid},
    TYPE_ID => $path_params->{id},
    VALUE   => '_SHOW'
  });

  delete @{$list->[0]}{qw/type_id id/} if ($list->[0]);

  return $list->[0] || {};
}

#**********************************************************
=head2 get_user_contacts_push_messages($path_params, $query_params)

  Endpoint DELETE /user/contacts/push/messages/

=cut
#**********************************************************
sub get_user_contacts_push_messages {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{TYPE_ID}) {
    my $validation = $self->_validate_allowed_types_push($query_params->{TYPE_ID});
    return $validation if ($validation->{errno});
  }

  my $list = $Contacts->push_messages_list({
    UID      => $path_params->{uid},
    TITLE    => '_SHOW',
    MESSAGE  => '_SHOW',
    CREATED  => '_SHOW',
    STATUS   => 0,
    GROUP_BY => 'CASE WHEN message_id = 0 THEN id ELSE message_id END',
    TYPE_ID  => $query_params->{TYPE_ID} ? $query_params->{TYPE_ID} : '_SHOW',
    DESC     => 'DESC',
  });

  return $list || [];
}

#**********************************************************
=head2 delete_user_contacts_push_badges($path_params, $query_params)

  Endpoint DELETE /user/contacts/push/badges/:id/

=cut
#**********************************************************
sub delete_user_contacts_push_badges {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $validation = $self->_validate_allowed_types_push($path_params->{id});
  return $validation if ($validation->{errno});

  my $list = $Contacts->push_contacts_list({
    UID     => $path_params->{uid},
    TYPE_ID => $path_params->{id},
    VALUE   => '_SHOW'
  });

  if (scalar @$list) {
    $Contacts->push_contacts_change({
      ID     => $list->[0]->{id},
      BADGES => 0,
    });
  }

  return {
    result => 'OK',
  };
}

#**********************************************************
=head2 _add_fcm_token()

=cut
#**********************************************************
sub _add_fcm_token {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Contacts->push_contacts_add({
    TYPE_ID => $path_params->{id},
    VALUE   => $query_params->{TOKEN},
    UID     => $path_params->{uid} || 0,
  });

  if ($path_params->{uid} && in_array('Ureports', \@main::MODULES)) {
    eval {require Ureports; Ureports->import()};
    if (!$@) {
      my $Ureports = Ureports->new($self->{db}, $self->{admin}, $self->{conf});

      $Ureports->user_send_type_del({
        TYPE => 10,
        UID  => $path_params->{uid},
      });

      $Ureports->user_send_type_add({
        TYPE        => 10,
        DESTINATION => 1,
        UID         => $path_params->{uid},
      });
    }
  }

  return {
    result  => 'OK',
    message => 'Successfully added push notification token',
    uid     => $path_params->{uid} || 0,
  };
}

#**********************************************************
=head2 validate_allowed_types_push()

=cut
#**********************************************************
sub _validate_allowed_types_push {
  my $self = shift;
  my ($id) = @_;
  my @allowed_types = (1, 2, 3);

  return {
    errno  => 5005,
    errstr => 'Push disabled',
  } if ((!$self->{conf}{GOOGLE_PROJECT_ID} || !$self->{conf}{FIREBASE_KEY}) || !$self->{conf}{PUSH_ENABLED});

  if (in_array($id, \@allowed_types)) {
    return {
      result => 'OK',
    };
  }
  else {
    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno          => 21,
        errstr         => 'typeId is not valid',
        param          => 'typeId',
        type           => 'number',
        allowed_params => [ 1, 2, 3 ],
        desc_params    => {
          1 => 'Web Push',
          2 => 'Android Push',
          3 => 'iOS/MacOS Silicon Push'
        }
      } ],
    }
  };
}

#**********************************************************
=head2 _validate_allowed_types_contacts()

=cut
#**********************************************************
sub _validate_allowed_types_contacts {
  my $self = shift;
  my ($id) = @_;
  my @allowed_types = ();

  push @allowed_types, 5 if ($self->{conf}{VIBER_TOKEN});
  push @allowed_types, 6 if ($self->{conf}{TELEGRAM_TOKEN});

  if (!scalar @allowed_types) {
    return {
      errno  => 10048,
      errstr => 'No allowed contacts typeId to delete, try later'
    };
  }

  if (in_array($id, \@allowed_types)) {
    return {
      result => 'OK',
    };
  }
  else {
    my %desc_params = ();
    $desc_params{5} = 'Viber bot token' if ($self->{conf}{VIBER_TOKEN});
    $desc_params{6} = 'Telegram bot token' if ($self->{conf}{TELEGRAM_TOKEN});

    return {
      errno  => 9,
      errstr => 'Validation failed',
      errors => [ {
        errno          => 21,
        errstr         => 'typeId is not valid',
        param          => 'typeId',
        type           => 'number',
        allowed_params => \@allowed_types,
        desc_params    => \%desc_params
      } ],
    }
  };
}

1;
