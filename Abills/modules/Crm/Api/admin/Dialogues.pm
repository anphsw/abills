package Crm::Api::admin::Dialogues;

=head1 NAME

  CRM dialogues manage

  Endpoints:
    /crm/dialogues/*
    /crm/dialogue/*

=cut

use strict;
use warnings FATAL => 'all';

use Crm::db::Crm;
use Crm::Attachments;

my Crm $Crm;
my Crm::Attachments $Attachments;

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
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Crm = Crm->new($db, $admin, $conf);
  $Crm->{debug} = $self->{debug};
  $Attachments = Crm::Attachments->new($db, $admin, $conf);

  # $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_crm_dialogue_id_message($path_params, $query_params)

  Endpoint POST /crm/dialogue/:id/message

=cut
#**********************************************************
sub post_crm_dialogue_id_message {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  use Abills::Sender::Core;
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  my $ex_params = {};
  my $dialog = $Crm->crm_dialogue_info({ ID => $path_params->{id} });
  my $lead = $Crm->crm_lead_info({ ID => $dialog->{LEAD_ID} });
  my $lead_address = $lead->{"_crm_$dialog->{SOURCE}"};

  if ($dialog->{SOURCE} eq 'mail') {
    $ex_params->{MAIL_HEADER} = [ "References: <$lead_address>", "In-Reply-To: <$lead_address>" ];
    $lead_address = $lead->{EMAIL};
  }

  $query_params->{ATTACHMENT_ID} = [ $query_params->{ATTACHMENT_ID} ] if $query_params->{ATTACHMENT_ID} && ref $query_params->{ATTACHMENT_ID} ne 'ARRAY';
  if (scalar(@{$query_params->{ATTACHMENT_ID}}) > 0) {
    my $attachments = $Crm->crm_attachment_list({
      ID           => join(';', @{$query_params->{ATTACHMENT_ID}}),
      FILENAME     => '_SHOW',
      FILE_SIZE    => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      COLS_NAME    => 1
    });

    my $attachment_path=  $Attachments->attachment_path();
    $ex_params->{ATTACHMENTS} = [];
    foreach my $attachment (@{$attachments}) {
      next if !$attachment->{filename};

      push @{$ex_params->{ATTACHMENTS}}, {
        content       => "FILE: $attachment_path/$attachment->{filename}",
        content_type  => $attachment->{content_type},
        filename      => $attachment->{filename},
        content_size  => $attachment->{file_size},
        file_size     => $attachment->{file_size},
        img_file_path => '/images/attach/crm/'
      };
    }
  }

  if (!$lead_address) {
    if ($query_params->{ATTACHMENT_ID}) {
      foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
        $Attachments->attachment_del($attachment);
      }
    }

    return {
      errno  => 101,
      errstr => 'No found address to send'
    };
  }

  my $result = $Sender->send_message({
    TO_ADDRESS  => $lead_address,
    MESSAGE     => Encode::encode_utf8($query_params->{MESSAGE}),
    SENDER_TYPE => ucfirst $dialog->{SOURCE},
    %{$ex_params}
  });

  if (!$result) {
    if ($query_params->{ATTACHMENT_ID}) {
      foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
        $Attachments->attachment_del($attachment);
      }
    }

    return {
      errno  => 102,
      errstr => 'The message was not sent'
    };
  }

  $Crm->crm_dialogue_messages_add({
    MESSAGE     => $query_params->{MESSAGE},
    AID         => $self->{admin}{AID},
    DIALOGUE_ID => $path_params->{id}
  });

  if ($Crm->{errno}) {
    if ($query_params->{ATTACHMENT_ID}) {
      foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
        $Attachments->attachment_del($attachment);
      }
    }

    return $Crm;
  }

  my $message_id = $Crm->{INSERT_ID};
  if ($query_params->{ATTACHMENT_ID}) {
    foreach my $attachment (@{$query_params->{ATTACHMENT_ID}}) {
      $Crm->crm_attachment_change({
        ID         => $attachment,
        MESSAGE_ID => $message_id
      });
    }
  }

  return $Crm;
}

#**********************************************************
=head2 put_crm_step_step_id($path_params, $query_params)

  Endpoint GET /crm/dialogue/:id/messages/

=cut
#**********************************************************
sub get_crm_dialogue_id_messages {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $messages = $Crm->crm_dialogue_messages_list({
    MESSAGE     => '_SHOW',
    DAY         => '_SHOW',
    TIME        => '_SHOW',
    AID         => '_SHOW',
    ATTACHMENTS => '_SHOW',
    PAGE_ROWS   => 99999,
    %{$query_params},
    DIALOGUE_ID => $path_params->{id},
    SORT        => 'cdm.date',
    DESC        => 'DESC',
    COLS_NAME   => 1
  });

  foreach my $message (@{$messages}) {
    next if !$message->{attachments};

    my $attachments = $Crm->crm_attachment_list({
      MESSAGE_ID   => $message->{id},
      FILENAME     => '_SHOW',
      FILE_SIZE    => '_SHOW',
      CONTENT_TYPE => '_SHOW',
      COLS_NAME    => 1
    });

    if ($Crm->{TOTAL} && $Crm->{TOTAL} > 0) {
      $message->{attachments} = [];
      foreach my $attachment (@{$attachments}) {
        push @{$message->{attachments}}, {
          id   => $attachment->{id},
          name => $attachment->{filename},
          size => $attachment->{file_size},
          type => $attachment->{content_type}
        }
      }
    }
  }

  return $messages;
}

#**********************************************************
=head2 put_crm_dialogue_id($path_params, $query_params)

  Endpoint PUT /crm/dialogue/:id/

=cut
#**********************************************************
sub put_crm_dialogue_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{AID} && (!$self->{admin}{permissions}{7} || !$self->{admin}{permissions}{7}{10})) {
    $Crm->crm_dialogue_info({ ID => $path_params->{id} });
    return { affected => $Crm->{AID} eq $query_params->{AID} ? 1 : undef } if $Crm->{AID};
  }

  $Crm->crm_dialogues_change({ %{$query_params}, ID => $path_params->{id} });
}

#**********************************************************
=head2 get_crm_dialogues($path_params, $query_params)

  Endpoint GET /crm/dialogues/

=cut
#**********************************************************
sub get_crm_dialogues {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
      $query_params->{$param} : '_SHOW';
  }

  $query_params->{COLS_NAME} = 1;
  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
  $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
  $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
  $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

  my $admin_open_lines = $Crm->crm_open_lines_list({ AID => $self->{admin}{AID}, SOURCE => '_SHOW', COLS_NAME => 1 });
  my $enabled_open_lines = [];
  map push(@{$enabled_open_lines}, $_->{source}), @{$admin_open_lines};

  if ($query_params->{SOURCE} && $query_params->{SOURCE} ne '_SHOW') {
    my @source_arr = $query_params->{SOURCE} =~ ';' ? split(';', $query_params->{SOURCE}) : split(',', $query_params->{SOURCE});
    my $enabled_query_open_lines = [];
    foreach my $source (@source_arr) {
      next if !Abills::Base::in_array($source, $enabled_open_lines);
      push @{$enabled_query_open_lines}, $source;
    }

    $query_params->{SOURCE} = join(';', @{$enabled_query_open_lines}) || '_SHOW';
  }
  elsif (defined $query_params->{SOURCE}) {
    $query_params->{SOURCE} = join(';', @{$enabled_open_lines});
  }

  $Crm->crm_dialogues_list($query_params);
}

1;
