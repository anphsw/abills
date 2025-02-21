package Msgs::Api::user::Root;

=head1 NAME

  User Msgs

  Endpoints:
    /user/msgs/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Msgs;
use Msgs::Notify;
use Msgs::Misc::Attachments;

my Msgs $Msgs;
my Msgs::Notify $Notify;
my Msgs::Misc::Attachments $Attachments;

my Control::Errors $Errors;

# Can not delete because is needed in Msgs::Notify. Probably need to create dynamic load of
our %lang;
require 'Abills/modules/Msgs/lng_english.pl';

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

  my %LANG = (%{$self->{lang}}, %lang);

  $Msgs = Msgs->new($db, $admin, $conf);
  $Msgs->{debug} = $self->{debug};
  $Notify = Msgs::Notify->new($db, $admin, $conf, { LANG => \%LANG, HTML => $self->{html} });
  $Attachments = Msgs::Misc::Attachments->new($db, $admin, $conf);
  $self->{permissions} = $Msgs->permissions_list($admin->{AID});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_msgs_chapters($path_params, $query_params)

  Endpoint GET /user/msgs/chapters/

=cut
#**********************************************************
sub get_user_msgs_chapters {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $chapters = $Msgs->chapters_list({
    INNER_CHAPTER => 0,
    COLS_NAME     => 1,
  });

  foreach my $chapter (@{$chapters}) {
    if (ref $chapter eq 'HASH') {
      delete @{$chapter}{qw/admin_login autoclose inner_chapter responsible/};
    }
  }

  return $chapters;
}

#**********************************************************
=head2 get_user_msgs($path_params, $query_params)

  Endpoint GET /user/msgs/

=cut
#**********************************************************
sub get_user_msgs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->messages_list({
    COLS_NAME     => 1,
    SUBJECT       => '_SHOW',
    STATE_ID      => '_SHOW',
    DATE          => '_SHOW',
    MESSAGE       => '_SHOW',
    CHAPTER_NAME  => '_SHOW',
    CHAPTER_COLOR => '_SHOW',
    STATE         => '_SHOW',
    DESC          => 'DESC',
    UID           => $path_params->{uid}
  });
}

#**********************************************************
=head2 post_user_msgs($path_params, $query_params)

  Endpoint POST /user/msgs/

=cut
#**********************************************************
sub post_user_msgs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %extra_params = ();

  if ($self->{conf}{MSGS_USER_REPLY_SECONDS_LIMIT}) {
    $Msgs->messages_list({
      UID       => $path_params->{uid},
      GET_NEW   => $self->{conf}{MSGS_USER_REPLY_SECONDS_LIMIT},
      DESC      => 'DESC',
      COLS_NAME => 1
    });

    if ($Msgs->{TOTAL} && $Msgs->{TOTAL} > 0) {
      return $Errors->throw_error(1070002, { lang_vars => { LIMIT => $self->{conf}{MSGS_USER_REPLY_SECONDS_LIMIT} } });
    }
  }

  if ($query_params->{CHAPTER}) {
    my $chapter = $Msgs->chapter_info($query_params->{CHAPTER});
    $extra_params{RESPONSIBLE} = $chapter->{RESPONSIBLE} if ($chapter->{RESPONSIBLE});
  }

  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 });
  $Msgs->message_add({
    SUBJECT   => $query_params->{SUBJECT} || q{},
    MESSAGE   => $query_params->{MESSAGE} || q{},
    PRIORITY  => $query_params->{PRIORITY} || 2,
    CHAPTER   => $query_params->{CHAPTER} || 0,
    UID       => $path_params->{uid},
    USER_READ => "$main::DATE $main::TIME",
    IP        => $ENV{REMOTE_ADDR} || '0.0.0.0',
    USER_SEND => 1,
    %extra_params
  });

  my $attachment_add_status = $Attachments->msgs_attachment_add($query_params, {
    REPLY_ID => 0,
    MSG_ID   => $Msgs->{INSERT_ID},
    UID      => $path_params->{uid}
  });
  $self->{attachments} = $attachment_add_status if (!$attachment_add_status->{no_attachments});

  if ($query_params->{CHAPTER} && !$extra_params{RESPONSIBLE}) {
    $Notify->notify_admins_by_chapter($query_params->{CHAPTER}, $Msgs->{INSERT_ID});
  }
  else {
    $Notify->notify_admins({ MSG_ID => $Msgs->{INSERT_ID} });
  }

  return $Msgs;
}

#**********************************************************
=head2 get_user_msgs_id($path_params, $query_params)

  Endpoint GET /user/msgs/:id/

=cut
#**********************************************************
sub get_user_msgs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->message_info($path_params->{id}, { UID => $path_params->{uid} });
}

#**********************************************************
=head2 get_user_msgs_id_reply($path_params, $query_params)

  Endpoint GET /user/msgs/:id/reply/

=cut
#**********************************************************
sub get_user_msgs_id_reply {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $reply_list = $Msgs->messages_reply_list({
    MSG_ID    => $path_params->{id},
    UID       => $path_params->{uid},
    INNER_MSG => 0,
    LOGIN     => '_SHOW',
    ADMIN     => '_SHOW',
    COLS_NAME => 1
  });

  my $first_msg = $Msgs->message_info($path_params->{id}, { UID => $path_params->{uid} });

  unshift @$reply_list, {
    'creator_id'  => ($first_msg->{AID} || q{}),
    'admin'       => '',
    'datetime'    => ($first_msg->{DATE} || q{}),
    'survey_id'   => ($first_msg->{SURVEY_ID} || 0),
    'status'      => 0,
    'uid'         => ($first_msg->{UID} || q{}),
    'caption'     => '',
    'creator_fio' => '',
    'main_msg'    => 0,
    'text'        => ($first_msg->{MESSAGE} || q{}),
    'id'          => $path_params->{id},
    'aid'         => ($first_msg->{AID} || q{})
  };

  foreach my $reply (@{$reply_list}) {
    if (ref $reply eq 'HASH') {
      delete @{$reply}{qw/filename attachment_id content_size run_time inner_msg ip/};
    }

    my %attachment_attr = ();
    if ($reply->{main_msg}) {
      $attachment_attr{REPLY_ID} = $reply->{id};
    }
    else {
      $attachment_attr{MESSAGE_ID} = $reply->{id};
    }

    my $attachments_list = $Msgs->attachments_list({
      %attachment_attr,
      FILENAME     => '_SHOW',
      CONTENT_SIZE => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      CONTENT      => '_SHOW',
    });

    if ($attachments_list && scalar(@{$attachments_list}) > 0) {
      my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
      my $SELF_URL = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/images" : '';

      foreach my $attachment (@$attachments_list) {
        my $content = $attachment->{content} || '';
        my ($file_path) = $content =~ /Abills\/templates(\/.+)/;

        push @{$reply->{attachments}}, {
          id           => $attachment->{id},
          content_size => $attachment->{content_size} || 0,
          filename     => $attachment->{filename} || q{},
          content_type => $attachment->{content_type} || q{},
          file_path    => ($SELF_URL || q{}) . ($file_path || q{}),
        };
      }
    }
  }

  return $reply_list || [];
}

#**********************************************************
=head2 post_user_msgs_id_reply($path_params, $query_params)

  Endpoint POST /user/msgs/:id/reply/

=cut
#**********************************************************
sub post_user_msgs_id_reply {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->message_reply_add({
    REPLY_TEXT => $query_params->{REPLY_TEXT} || '',
    ID         => $path_params->{id},
    UID        => $path_params->{uid},
    STATE      => $query_params->{STATE} || 0,
  });

  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 });

  $Msgs->message_change({
    ID         => $path_params->{id},
    STATE      => 0,
    ADMIN_READ => '0000-00-00 00:00:00'
  });

  $Attachments->msgs_attachment_add($query_params, {
    REPLY_ID => $Msgs->{INSERT_ID},
    MSG_ID   => $path_params->{id},
    UID      => $path_params->{uid}
  });

  $Notify->notify_admins({ MSG_ID => $path_params->{id}, REPLY_ID => $Msgs->{INSERT_ID} });

  ($Msgs->{errno}) ? return 0 : return 1;
}

#**********************************************************
=head2 get_user_msgs_attachments_id($path_params, $query_params)

  Endpoint GET /user/msgs/attachments/:id/

=cut
#**********************************************************
sub get_user_msgs_attachments_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->attachment_info({
    ID => $path_params->{id},
  });

  if ($Msgs->{errno} || $Msgs->{errstr}) {
    return $Errors->throw_error(1070003, { lang_vars => { ID => $path_params->{id} } });
  }

  delete $Msgs->{TOTAL};

  if ($Msgs->{MESSAGE_TYPE}) {
    $Msgs->messages_reply_list({
      UID => $path_params->{uid},
      ID  => $Msgs->{MESSAGE_ID},
    });
  }
  else {
    $Msgs->messages_list({
      UID    => $path_params->{uid},
      MSG_ID => $Msgs->{MESSAGE_ID},
    });
  }

  if ($Msgs->{TOTAL}) {
    my $attachment = $Attachments->attachment_info($path_params->{id});
    if ($attachment->{errno} || $attachment->{error}) {
      return $Errors->throw_error(1070004);
    }
    else {
      return {
        CONTENT_TYPE => 'Content-Type: ' . ($Msgs->{CONTENT_TYPE} || ''),
        CONTENT      => $attachment->{CONTENT}
      };
    }
  }
  else {
    return $Errors->throw_error(1070005);
  }
}

1;
