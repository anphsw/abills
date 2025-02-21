package Msgs::Api::admin::Root;

=head1 NAME

  Msgs manage

  Endpoints:
    /msgs/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);

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
=head2 post_user_msgs($path_params, $query_params)

  Endpoint POST /msgs/

=cut
#**********************************************************
sub post_msgs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$self->{permissions}{1}{0}) {
    return $Errors->throw_error(1071001);
  }

  if ($query_params->{CHAPTER} && $self->{permissions}{4} && !$self->{permissions}{4}{$query_params->{CHAPTER}}) {
    return $Errors->throw_error(1071002);
  }

  $Msgs->message_add({ %$query_params });
}

#**********************************************************
=head2 get_msgs_statuses($path_params, $query_params)

  Endpoint GET /msgs/statuses/

=cut
#**********************************************************
sub get_msgs_statuses {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$self->{permissions}{1}{0}) {
    return $Errors->throw_error(1071003);
  }

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $list = $Msgs->status_list({
    ID          => '_SHOW',
    NAME        => '_SHOW',
    READINESS   => '_SHOW',
    TASK_CLOSED => '_SHOW',
    COLOR       => '_SHOW',
    ICON        => '_SHOW',
    %{$query_params},
    COLS_NAME   => 1
  });

  foreach my $status (@$list) {
    if ($status->{name} && $status->{name} =~ /\$lang\{(\S+)\}/g) {
      my $marker = $1;
      if($self->{lang}{$marker}) {
        $status->{locale_name} = $status->{name};
        $status->{locale_name} =~ s/\$lang\{$marker\}/$self->{lang}{$marker}/;
      }
      else {
        $status->{locale_name} = $marker;
      }
    }
  }

  return {
    list  => $list,
    total => $Msgs->{TOTAL}
  }
}

#**********************************************************
=head2 get_msgs_id($path_params, $query_params)

  Endpoint GET /msgs/:id/

=cut
#**********************************************************
sub get_msgs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $message = $Msgs->message_info($path_params->{id});

  if ($self->{permissions}{1}{21} && (!$message->{RESPOSIBLE} || $message->{RESPOSIBLE} ne $self->{admin}{AID})) {
    return $Errors->throw_error(1071004);
  }

  if ($self->{permissions}{4} && (!$message->{CHAPTER} || !$self->{permissions}{4}{$message->{CHAPTER}})) {
    return $Errors->throw_error(1071005);
  }

  return $message;
}

#**********************************************************
=head2 put_msgs_id($path_params, $query_params)

  Endpoint PUT /msgs/:id/

=cut
#**********************************************************
sub put_msgs_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $message = $Msgs->message_info($path_params->{id});

  if ($self->{permissions}{1}{21} && (!$message->{RESPOSIBLE} || $message->{RESPOSIBLE} ne $self->{admin}{AID})) {
    return $Errors->throw_error(1071006);
  }

  if ($self->{permissions}{4} && (!$message->{CHAPTER} || !$self->{permissions}{4}{$message->{CHAPTER}})) {
    return $Errors->throw_error(1071007);
  }

  if ($query_params->{STATE}) {
    $Msgs->status_info($query_params->{STATE});
    delete $query_params->{STATE} if $Msgs->{TASK_CLOSED} && (!$self->{permissions}{1} || !$self->{permissions}{1}{3});
  }

  delete $query_params->{PRIORITY} if !$self->{permissions}{1} || !$self->{permissions}{1}{13};
  delete $query_params->{RESPOSIBLE} if !$self->{permissions}{1} || !$self->{permissions}{1}{16};
  delete $query_params->{DISPATCH_ID} if !$self->{permissions}{1} || !$self->{permissions}{1}{26};

  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 });
  $Msgs->message_change({ %{$query_params}, ID => $path_params->{id} });

  $Notify->notify_admins({ MSG_ID => $path_params->{id}, NEW_RESPONSIBLE => 1 }) if $query_params->{RESPOSIBLE};

  return $Msgs;
}

#**********************************************************
=head2 post_msgs_list($path_params, $query_params)

  Endpoint POST /msgs/list/

=cut
#**********************************************************
sub post_msgs_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{CHAPTER} && $self->{permissions}{4}) {
    my @available_chapters = keys %{$self->{permissions}{4}};

    $query_params->{CHAPTER} = $query_params->{CHAPTER} eq '_SHOW' ? join(';', @available_chapters)
      : join(';', grep {in_array($_, \@available_chapters)} split('[,;]\s?', $query_params->{CHAPTER}));
  }
  elsif ($self->{permissions}{4}) {
    $query_params->{CHAPTER} = join(';', keys %{$self->{permissions}{4}});
  }

  $Msgs->messages_list({
    %$query_params,
    COLS_NAME => 1,
    DESC      => 'DESC',
    SUBJECT   => '_SHOW',
    STATE_ID  => '_SHOW',
    DATE      => '_SHOW'
  });
}

#**********************************************************
=head2 get_msgs_list($path_params, $query_params)

  Endpoint GET /msgs/list/

=cut
#**********************************************************
sub get_msgs_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{CHAPTER} && $self->{permissions}{4}) {
    my @available_chapters = keys %{$self->{permissions}{4}};

    $query_params->{CHAPTER} = $query_params->{CHAPTER} eq '_SHOW' ? join(';', @available_chapters)
      : join(';', grep {in_array($_, \@available_chapters)} split('[,;]\s?', $query_params->{CHAPTER}));
  }
  elsif ($self->{permissions}{4}) {
    $query_params->{CHAPTER} = join(';', keys %{$self->{permissions}{4}});
  }

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $msgs_list = $Msgs->messages_list({
    %$query_params,
    COLS_NAME => 1,
    SUBJECT   => '_SHOW',
    STATE_ID  => '_SHOW',
    DATE      => '_SHOW',
    DESC      => 'DESC'
  });

  my @extra_params = (
    'OPEN',
    'CLOSED',
    'TOTAL',
    'IN_WORK',
    'UNMAKED',
  );

  foreach my $msg (@{$msgs_list}) {
    foreach my $param (@extra_params) {
      $msg->{lc($param)} = $Msgs->{$param} if (defined($query_params->{$param}));
    }
  }

  return {
    list => $msgs_list,
    total => $Msgs->{TOTAL}
  };
}

#**********************************************************
=head2 post_msgs_id_reply($path_params, $query_params)

  Endpoint POST /msgs/:id/reply/

=cut
#**********************************************************
sub post_msgs_id_reply {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  # spend time for reply by admin
  if ($query_params->{RUN_TIME}) {
    my ($h, $min, $sec) = split(/:/, $query_params->{RUN_TIME}, 3);
    $query_params->{RUN_TIME} = ($h || 0) * 60 * 60 + ($min || 0) * 60 + ($sec || 0);
  }

  $Msgs->message_info($path_params->{id});

  if ($Msgs->{CHAPTER} && $self->{permissions}{4} && !$self->{permissions}{4}{$Msgs->{CHAPTER}}) {
    return $Errors->throw_error(1071008);
  }

  delete $query_params->{REPLY_INNER_MSG} if !$self->{permissions}{1} || !$self->{permissions}{1}{7};
  $Msgs->message_reply_add({
    %{$query_params},
    ID  => $path_params->{id},
    AID => $self->{admin}->{AID},
    IP  => $self->{admin}->{SESSION_IP},
  });

  return $Msgs if ($Msgs->{errno});

  $Attachments->msgs_attachment_add($query_params, {
    MSG_ID   => $path_params->{id},
    REPLY_ID => $Msgs->{INSERT_ID},
    UID      => $Msgs->{UID},
  });

  my $reply_id = $Msgs->{INSERT_ID};
  my $responsible = $Msgs->{RESPOSIBLE} || $self->{admin}->{AID};
  my %params = (
    ID         => $path_params->{id},
    USER_READ  => (!$query_params->{REPLY_INNER_MSG}) ? "0000-00-00 00:00:00" : undef,
    ADMIN_READ => "$main::DATE $main::TIME",
    RESPOSIBLE => $responsible,
  );

  my $msg_state = $query_params->{STATE} || 0;
  $params{STATE} = ($msg_state == 0 && !$query_params->{MAIN_INNER_MESSAGE} && !$query_params->{REPLY_INNER_MSG})
    ? 6 : $msg_state;

  $Msgs->status_info($msg_state);
  if ($Msgs->{TOTAL} > 0 && $Msgs->{TASK_CLOSED}) {
    $params{CLOSED_DATE} = "$main::DATE $main::TIME";
    $params{STATE} = 0 if $Msgs->{TASK_CLOSED} && (!$self->{permissions}{1} || !$$self->{permissions}{1}{3});
  }
  $params{DONE_DATE} = $main::DATE if ($msg_state > 1);

  $Msgs->message_change(\%params);

  if ($query_params->{STEP_NUM}) {
    require Abills::Sender::Core;
    Abills::Sender::Core->import();
    my $Sender = Abills::Sender::Core->new(@{$self}{qw/db admin conf/});

    my $chapter = $Msgs->pb_msg_list({
      MAIN_MSG           => $path_params->{id},
      CHAPTER_ID         => $Msgs->{CHAPTER},
      STEP_NUM           => $query_params->{STEP_NUM},
      USER_NOTICE        => '_SHOW',
      RESPONSIBLE_NOTICE => '_SHOW',
      FOLLOWER_NOTICE    => '_SHOW',
      COLS_NAME          => 1,
    });

    if (!defined($Msgs->{TOTAL})) {
      $Msgs->msg_watch_info($path_params->{id});
      my $watch_aid = $Msgs->{AID};

      my %send_msgs = (
        SUBJECT => $chapter->[0]->{step_name},
        MESSAGE => $query_params->{REPLY_TEXT} || "$lang{CHAPTER} $chapter->[0]->{step_name} $lang{DONE}",
      );

      foreach my $chapter_info (@{$chapter}) {
        if ($chapter_info->{user_notice} && $Msgs->{UID}) {
          $Sender->send_message({ UID => $Msgs->{UID}, SENDER_TYPE => 'Mail', %send_msgs });
        }
        elsif ($chapter_info->{responsible_notice} && $responsible) {
          $Sender->send_message({ AID => $responsible, %send_msgs });
        }
        elsif ($chapter_info->{follower_notice} && $watch_aid) {
          $Sender->send_message({ AID => $watch_aid, %send_msgs });
        }
      }
    }

    $Msgs->pb_msg_change($query_params);
  }

  $Msgs->message_info($path_params->{id});

  my $attachments_list = $Msgs->attachments_list({
    REPLY_ID     => $reply_id,
    FILENAME     => '_SHOW',
    CONTENT      => '_SHOW',
    CONTENT_TYPE => '_SHOW',
    CONTENT_SIZE => '_SHOW'
  });

  # loading all module for cringe function msgs_sel_status inside Notify->notify_user
  ::load_module('Msgs');
  # loading for Notify
  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 });

  #todo: rewrite to getting locale of state inside Notify, not in external call
  $Notify->notify_user({
    UID             => $Msgs->{UID},
    STATE_ID        => $Msgs->{STATE},
    SEND_TYPE       => $Msgs->{SEND_TYPE},
    REPLY_ID        => $reply_id,
    MSG_ID          => $path_params->{id},
    MSGS            => $Msgs,
    SENDER_AID      => $self->{admin}->{AID},
    ATTACHMENTS     => $attachments_list,
    REPLY_INNER_MSG => $query_params->{REPLY_INNER_MSG}
  });

  $Notify->notify_admins({
    SEND_TYPE   => $Msgs->{SEND_TYPE},
    SENDER_AID  => $self->{admin}->{AID},
    MSG_ID      => $path_params->{id},
    MSGS        => $Msgs,
    ATTACHMENTS => $attachments_list
  });

  return $Msgs->message_reply_info($reply_id);
}

#**********************************************************
=head2 get_msgs_id_reply($path_params, $query_params)

  Endpoint GET /msgs/:id/reply/

=cut
#**********************************************************
sub get_msgs_id_reply {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->messages_reply_list({
    %$query_params,
    MSG_ID    => $path_params->{id},
    LOGIN     => '_SHOW',
    ADMIN     => '_SHOW',
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 post_msgs_reply_reply_id_attachment($path_params, $query_params)

  Endpoint POST /msgs/reply/:reply_id/attachment/

=cut
#**********************************************************
sub post_msgs_reply_reply_id_attachment {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->attachment_add({
    %$query_params,
    REPLY_ID  => $path_params->{reply_id},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 get_msgs_chapters($path_params, $query_params)

  Endpoint GET /msgs/chapters/

=cut
#**********************************************************
sub get_msgs_chapters {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{CHAPTER} && $self->{permissions}{4}) {
    my @available_chapters = keys %{$self->{permissions}{4}};

    $query_params->{CHAPTER} = $query_params->{CHAPTER} eq '_SHOW' ? join(';', @available_chapters)
      : join(';', grep {in_array($_, \@available_chapters)} split('[,;]\s?', $query_params->{CHAPTER}));
  }
  elsif ($self->{permissions}{4}) {
    $query_params->{CHAPTER} = join(';', keys %{$self->{permissions}{4}});
  }

  return {
    errno  => 104,
    errstr => 'Access denied'
  } if (defined $query_params->{CHAPTER} && !$query_params->{CHAPTER});

  $Msgs->chapters_list({
    %$query_params,
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 get_msgs_survey($path_params, $query_params)

  Endpoint GET /msgs/survey/

=cut
#**********************************************************
sub get_msgs_survey {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $list = $Msgs->survey_subjects_list({
    %$query_params,
    COLS_NAME => 1
  });

  return {
    list  => $list,
    total => $Msgs->{TOTAL}
  }
}

1;
