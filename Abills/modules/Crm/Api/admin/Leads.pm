package Crm::Api::admin::Leads;

=head1 NAME

  CRM leads manage

  Endpoints:
    /crm/leads/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Crm::db::Crm;
use Crm::Attachments;

my Crm $Crm;
my Crm::Attachments $Attachments;
my Control::Errors $Errors;

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

  $Crm = Crm->new($self->{db}, $self->{admin}, $self->{conf});;
  $Crm->{debug} = $self->{debug};

  $Attachments = Crm::Attachments->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_crm_leads($path_params, $query_params)

  Endpoint POST /crm/leads/

=cut
#**********************************************************
sub post_crm_leads {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{CURRENT_STEP} && $query_params->{CURRENT_STEP} =~ /\D/g) {
    my $steps = $Crm->crm_progressbar_step_list({
      ID          => '_SHOW',
      NAME        => $query_params->{CURRENT_STEP},
      STEP_NUMBER => '_SHOW',
      COLS_NAME   => 1
    });

    $query_params->{CURRENT_STEP} = $Crm->{TOTAL} > 0 ? $steps->[0]{step_number} : 1;
  }

  $Crm->crm_lead_add($query_params);
}

#**********************************************************
=head2 put_crm_leads_id($path_params, $query_params)

  Endpoint PUT /crm/leads/:id/

=cut
#**********************************************************
sub put_crm_leads_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_lead_change({ ID => $path_params->{id}, %{$query_params} });
}

#**********************************************************
=head2 delete_crm_leads_id($path_params, $query_params)

  Endpoint DELETE /crm/leads/:id/

=cut
#**********************************************************
sub delete_crm_leads_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_lead_info({ ID => $path_params->{id} });
  if ($Crm->{TOTAL} < 1) {
    return {
      errno  => 104003,
      errstr => "No lead with id $path_params->{id}"
    };
  }

  $Crm->crm_lead_delete({ ID => $path_params->{id} });

  if (!$Crm->{errno}) {
    return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
    return {
      errno  => 104002,
      errstr => "No lead with id $path_params->{id}"
    };
  }
}

#**********************************************************
=head2 get_crm_leads_id($path_params, $query_params)

  Endpoint GET /crm/leads/:id/

=cut
#**********************************************************
sub get_crm_leads_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_lead_info({ ID => $path_params->{id} });
}

#**********************************************************
=head2 post_crm_leads_id_phone($path_params, $query_params)

  Endpoint POST /crm/leads/:id/phone/

=cut
#**********************************************************
sub post_crm_leads_id_phone {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $lead = $Crm->crm_lead_info({ ID => $path_params->{id} });
  return { errno => 1230001, errstr => 'ERR_CRM_PHONE_NOT_FOUND' } if !$lead->{PHONE};
  return { errno => 1230002, errstr => 'ERR_CRM_EXTERNAL_CMD_NOT_FOUND' } if !$self->{conf}{CRM_PHONE_EXTERNAL_CMD};

  my $result = ::_external('', { EXTERNAL_CMD => 'CRM_PHONE', %{$lead}, QUITE => 1 });
  return $result if $result;

  return { errno => 1230003, errstr => 'ERR_CRM_EXTERNAL_CMD_ERROR' };
}

#**********************************************************
=head2 get_crm_leads($path_params, $query_params)

  Endpoint GET /crm/leads/

=cut
#**********************************************************
sub get_crm_leads {
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

  $Crm->crm_lead_list($query_params);
}

#**********************************************************
=head2 post_crm_leads_social($path_params, $query_params)

  Endpoint POST /crm/leads/social/

=cut
#**********************************************************
sub post_crm_leads_social {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $bot_name = $path_params->{bot_name} eq 'VIBER' ? 'viber_bot' : lc($path_params->{bot_name});
  require Crm::Dialogue;
  my $Dialogue = Crm::Dialogue->new($self->{db}, $self->{admin}, $self->{conf}, { SOURCE => $bot_name });

  my $lead_id = $Dialogue->crm_lead_by_source({
    %$query_params,
    USER_ID => $path_params->{user_id},
  });

  return $Errors->throw_error(1230007) if (!$lead_id);
  my $dialogue_id = $Dialogue->crm_get_dialogue_id($lead_id);

  my $text = '$lang{THE_USER_JOINED_VIA_' . uc($bot_name) . '}';
  my $message_id = $Dialogue->crm_send_message($text, {
    INNER_MSG => 1, SKIP_CHANGE => 1, DIALOGUE_ID => $dialogue_id
  });

  return $Errors->throw_error(1230008) if (!$message_id);

  return {
    # I dont have any normal program API to have standard "affected" value.
    AFFECTED        => 1,
    INSERT_ID       => $lead_id,
    NEW_LEAD_ID     => $lead_id,
    NEW_DIALOGUE_ID => $dialogue_id,
    NEW_MESSAGE_ID  => $message_id,
  }
}

#**********************************************************
=head2 post_crm_leads_dialogue_message($path_params, $query_params)

  Endpoint POST /crm/leads/dialogue/message/

=cut
#**********************************************************
sub post_crm_leads_dialogue_message {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %bot_types = (5 => 'viber_bot', 6 => 'telegram');
  my $source = $bot_types{$path_params->{bot} || ''};

  return $Errors->throw_error(1230004) if !$path_params->{user_id};
  return $Errors->throw_error(1230005) if !$source;

  require Crm::Dialogue;
  my $Dialogue = Crm::Dialogue->new($self->{db}, $self->{admin}, $self->{conf}, { SOURCE => $source });
  return $Errors->throw_error(1230006) if !$Dialogue->can('crm_get_lead_id_by_chat_id');

  my $lead_id = $Dialogue->crm_get_lead_id_by_chat_id($path_params->{user_id});
  return $Errors->throw_error(1230007) if !$lead_id;

  my $attachments = [];
  if ($query_params->{ATTACHMENTS}) {
    $attachments = _crm_dialogue_attachment($query_params->{ATTACHMENTS});
  }

  my $message_id = $Dialogue->crm_send_message($query_params->{MESSAGE}, {
    LEAD_ID     => $lead_id,
    ATTACHMENTS => $attachments
  });
  return $Errors->throw_error(1230008) if !$message_id;

  return {
    result => "OK",
    id     => $message_id,
  }
}

#**********************************************************
=head2 _crm_dialogue_attachment($message)

=cut
#**********************************************************
sub _crm_dialogue_attachment {
  my ($attachments) = @_;

  my @attachments_result = ();

  foreach my $attachment (@{$attachments}) {
    my $result = $Attachments->attachment_add({
      filename       => $attachment->{FILE_NAME},
      'Content-Type' => $attachment->{CONTENT_TYPE},
      Size           => $attachment->{SIZE},
      Contents       => $attachment->{CONTENTS}
    });
    next if $result->{errno} || !$result->{INSERT_ID};

    push @attachments_result, $result->{INSERT_ID};
  }

  return \@attachments_result;
}


1;
