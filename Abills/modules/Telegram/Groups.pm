package Telegram::Groups;

=head1 NAME

  Telegram groups function

=cut

use strict;
use warnings FATAL => 'all';

use Msgs;
use Contacts;

my Msgs $Msgs;
my Contacts $Contacts;

use constant {
  TELEGRAM_SENDER_TYPE_ID => 6
};

#**********************************************************
=head2 new($db, $conf, $admin, $attr) - Create new Telegram::Groups object

  Arguments:
    $db      - Database handler
    $conf    - System configuration
    $admin   - Admin object
    $attr    - Extra attributes
       lang  - Language hash reference

  Returns:
    Telegram::Groups object

  Example:
    my $Telegram_groups = Telegram::Groups->new($db, $admin, $conf, { lang => \%lang });

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  bless($self, $class);

  $Msgs = Msgs->new($db, $admin, $conf);
  $Contacts = Contacts->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 telegram_group_add($group_info) - Register a Telegram group in system

  Arguments:
    $group_info - Hash reference
       id|ID     - Telegram group ID
       title|TITLE - Group title (optional)

  Returns:
    Hash reference
      { ID => INSERT_ID } - On success
      { errno, errstr }   - On error
    undef                 - If no group_id provided

  Example:
    $Telegram_groups->telegram_group_add({ id => 12345, title => 'Support group' });

=cut
#**********************************************************
sub telegram_group_add {
  my ($self, $group_info) = @_;

  my $group_id = $group_info->{id} || $group_info->{ID};

  if (!$group_id) {
    return undef;
  }

  my $name = $group_info->{title} || $group_info->{TITLE} || "Telegram #$group_id";

  $Msgs->external_chats_add({
    CHAT_ID => $group_id,
    TYPE    => 'telegram',
    NAME    => $name
  });

  if ($Msgs->{errno}) {
    return {
      errno  => $Msgs->{errno},
      errstr => $Msgs->{errstr}
    };
  }

  return {
    ID => $Msgs->{INSERT_ID}
  };
}

#**********************************************************
=head2 telegram_group_info($group_info) - Retrieve Telegram group information

  Arguments:
    $group_info - Hash reference
       id|ID - Telegram group ID

  Returns:
    Hash reference with group data:
      {
        ID         => Chat internal ID,
        UID        => User ID,
        MESSAGE_ID => Message ID
      }
    undef - If not found or invalid input

  Example:
    my $info = $Telegram_groups->telegram_group_info({ id => 12345 });

=cut
#**********************************************************
sub telegram_group_info {
  my ($self, $group_info) = @_;

  my $group_id = $group_info->{id} || $group_info->{ID};

  if (!$group_id) {
    return undef;
  }

  my $chat_info = $Msgs->external_chats_list({
    CHAT_ID    => $group_id,
    TYPE       => 'telegram',
    UID        => '_SHOW',
    MESSAGE_ID => '_SHOW',
    COLS_NAME  => 1
  });

  if (!$Msgs->{TOTAL} || $Msgs->{TOTAL} < 1) {
    return undef;
  }

  return {
    ID         => $chat_info->[0]{id},
    UID        => $chat_info->[0]{uid},
    MESSAGE_ID => $chat_info->[0]{message_id},
  };
}

#**********************************************************
=head2 telegram_group_add_message($group, $message) - Add message from Telegram group

  Arguments:
    $group   - Hash reference with group data (id|ID required)
    $message - Hash reference
       from         - Sender info { id, first_name, last_name, username }
       text|caption - Message text
       attachments  - ArrayRef with file attachments

  Returns:
    Nothing. Adds message and attachments into system.
    Skips if sender or group is not registered.

  Example:
    $Telegram_groups->telegram_group_add_message(
      { id => 12345 },
      {
        from => { id => 678, first_name => 'John' },
        text => 'Hello world'
      }
    );

=cut
#**********************************************************
sub telegram_group_add_message {
  my ($self, $group, $message) = @_;

  if (!$message || (!defined($message->{text}) && !defined($message->{attachments})) || !$message->{from}) {
    return;
  }

  my $group_info = $self->telegram_group_info($group);
  return if !$group_info;
  return if (!$group_info->{MESSAGE_ID} || !$group_info->{UID});

  my $sender_id = $message->{from}{id};
  return if !$sender_id;

  my $user_contact_id = 0;
  my $aid = $self->_get_admin_id($sender_id);

  if (!$aid) {
    $user_contact_id = $self->_get_user_contact_id($message->{from}, $group_info->{UID});
  }

  return if !$aid && !$user_contact_id;

  $Msgs->message_reply_add({
    ID         => $group_info->{MESSAGE_ID},
    REPLY_TEXT => $message->{text} || $message->{caption},
    AID        => $aid,
    UID        => $aid ? 0 : $group_info->{UID},
    CONTACT_ID => $user_contact_id
  });
  my $reply_id = $Msgs->{REPLY_ID};

  if ($Msgs->{errno} || !$reply_id) {
    return;
  }

  if ($message->{attachments} && ref($message->{attachments}) eq 'ARRAY') {
    use Msgs::Misc::Attachments;
    my $Attachments = Msgs::Misc::Attachments->new($self->{db}, $self->{admin}, $self->{conf});

    foreach my $attach (@{$message->{attachments}}) {
      $Attachments->attachment_add({
        REPLY_ID     => $reply_id,
        MSG_ID       => $reply_id,
        MESSAGE_TYPE => 1,
        CONTENT      => $attach->{CONTENTS},
        FILESIZE     => $attach->{SIZE},
        FILENAME     => $attach->{FILE_NAME},
        CONTENT_TYPE => $attach->{CONTENT_TYPE},
        UID          => $group_info->{UID}
      });
    }
  }
}

#**********************************************************
=head2 _get_admin_id($sender_id) - Find admin by Telegram sender ID

  Arguments:
    $sender_id - Telegram user ID

  Returns:
    Admin ID (AID) if found
    undef      if not found

  Example:
    my $aid = $self->_get_admin_id(123456);

=cut
#**********************************************************
sub _get_admin_id {
  my ($self, $sender_id) = @_;

  return if !$sender_id;

  my $contacts_list = $self->{admin}->admins_contacts_list({
    TYPE           => TELEGRAM_SENDER_TYPE_ID,
    VALUE          => $sender_id,
    AID            => '_SHOW',
    SKIP_AID_CHECK => 1
  });
  
  if ($contacts_list && ref $contacts_list eq 'ARRAY' && scalar($contacts_list) > 0) {
    return $contacts_list->[0]{aid} || 0;
  }

  return;
}

#**********************************************************
=head2 _get_user_contact_id($sender_info, $uid) - Find or create contact for Telegram user

  Arguments:
    $sender_info - Hash reference with Telegram user info
       id         - Telegram user ID
       first_name - Sender first name (optional)
       last_name  - Sender last name (optional)
       username   - Telegram @username (optional)
    $uid         - Local user ID

  Returns:
    Contact ID if found or created
    undef       if failed

  Example:
    my $contact_id = $self->_get_user_contact_id(
      { id => 678, first_name => 'John', username => 'john_d' },
      1001
    );

=cut
#**********************************************************
sub _get_user_contact_id {
  my ($self, $sender_info, $uid) = @_;

  return if (!$sender_info || !$sender_info->{id} || !$uid);

  my $contacts_list = $Contacts->contacts_list({
    TYPE  => TELEGRAM_SENDER_TYPE_ID,
    VALUE => $sender_info->{id},
    UID   => $uid
  });

  if ($Contacts->{TOTAL} && $Contacts->{TOTAL} > 0) {
    return $contacts_list->[0]{id};
  }
  
  my $fio = join(' ', ($sender_info->{last_name} || '', $sender_info->{first_name} || ''));
  my $user_name = $sender_info->{username} ? ('@' . $sender_info->{username}) : '';
  my $comments = join(' / ', ($fio, $user_name));

  $Contacts->contacts_add({
    UID      => $uid,
    TYPE_ID  => TELEGRAM_SENDER_TYPE_ID,
    VALUE    => $sender_info->{id},
    COMMENTS => $comments
  });

  if (!$Contacts->{errno} && $Contacts->{INSERT_ID}) {
    return $Contacts->{INSERT_ID};
  }

  return;
}

1;