#!/usr/bin/perl

=head1 NAME

  WhatsApp Business API webhook handler

=head1 SYNOPSIS

  Handles incoming WhatsApp messages and integrates with CRM dialogue system

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/abills(\/)/) {
    my $libpath = substr($Bin, 0, $-[1]);
    unshift(@INC, "$libpath/lib");
  }
  else {
    die "Error: Script should be inside /usr/abills directory\n";
  }
}

use Abills::Init qw/$db $admin %conf $users @MODULES $DATE $TIME/;
use Abills::HTML;
use Abills::Base qw(_bp load_pmodule in_array);
use MIME::Base64;
use JSON qw/decode_json encode_json/;
use Digest::SHA qw(hmac_sha256);
use Abills::Fetcher qw/web_request/;

use constant {
  SOURCE_TYPE => 'whatsapp',
  LOG_FILE    => '',
};

main();

#**********************************************************
=head2 main()

=cut
#**********************************************************
sub main {
  print "Content-Type: application/json\n\n";

  our %FORM;
  %FORM = form_parse();

  if ($FORM{'hub.challenge'}) {
    print $FORM{'hub.challenge'};
    exit 0;
  }

  eval {
    process_webhook();
  };

  if ($@) {
    # log_error("Webhook processing failed: $@");
    print encode_json({ error => 'Internal server error' });
    exit 1;
  }

  print encode_json({ success => 1 });
  exit 0;
}

#**********************************************************
=head2 process_webhook()

=cut
#**********************************************************
sub process_webhook {
  if (!$FORM{__BUFFER}) {
    return;
  }

  load_pmodule('JSON');
  my $json = JSON->new->allow_nonref;
  my $webhook_data = eval { $json->decode($FORM{__BUFFER}) };

  if ($@) {
    # log_error("Failed to parse JSON: $@");
    return;
  }

  my $message_data = extract_message_data($webhook_data);
  if (!$message_data) {
    return;
  }

  handle_incoming_message($message_data);
}

#**********************************************************
=head2 extract_message_data($webhook_data)

  Extract relevant message data from webhook payload

  Arguments:
    $webhook_data - Parsed webhook JSON data

  Returns:
    Hash reference with message data or undef

=cut
#**********************************************************
sub extract_message_data {
  my ($webhook_data) = @_;

  if (ref $webhook_data ne 'HASH') {
    return;
  }

  if (!$webhook_data->{entry} || ref $webhook_data->{entry} ne 'ARRAY') {
    return;
  }

  if (!@{$webhook_data->{entry}}) {
    return;
  }

  my $entry = $webhook_data->{entry}[0];
  if (!$entry->{changes} || ref $entry->{changes} ne 'ARRAY') {
    return;
  }

  my $change = $entry->{changes}[0];
  if (!$change->{value}) {
    return;
  }

  my $value = $change->{value};

  my $phone_number_id = $value->{metadata}{phone_number_id};
  if (!$phone_number_id) {
    return;
  }

  my $messages = $value->{messages};
  if (!$messages || ref $messages ne 'ARRAY' || !@{$messages}) {
    return;
  }

  my $message = $messages->[0];
  my $message_text = $message->{text}{body} || '';

  my $contacts = $value->{contacts};
  my $contact = ($contacts && ref $contacts eq 'ARRAY' && @{$contacts}) ? $contacts->[0] : {};

  return {
    sender       => $phone_number_id,
    message      => $message_text,
    contact_name => $contact->{profile}{name} || '',
    contact_id   => $contact->{wa_id} || '',
    attachments  => $message->{attachments} || [],
  };
}

#**********************************************************
=head2 handle_incoming_message($message_data)

  Process incoming message and save to CRM

  Arguments:
    $message_data - Hash reference with message data

=cut
#**********************************************************
sub handle_incoming_message {
  my ($message_data) = @_;

  if (!$message_data->{message} && !@{$message_data->{attachments}}) {
    # log_error("No message content or attachments found");
    return;
  }

  use Crm::Dialogue;
  my $Dialogue = Crm::Dialogue->new($db, $admin, \%conf, { SOURCE => SOURCE_TYPE });

  my $lead_id = $Dialogue->crm_lead_by_source({
    USER_ID => $message_data->{contact_id},
    FIO     => $message_data->{contact_name},
    PHONE   => $message_data->{contact_id}
  });

  if (!$lead_id) {
    # log_error("Failed to get or create lead for sender: $message_data->{sender}");
    return;
  }

  my $dialogue_id = $Dialogue->crm_get_dialogue_id($lead_id);
  if (!$dialogue_id) {
    # log_error("Failed to get dialogue ID for lead: $lead_id");
    return;
  }

  my $attachment_ids = [];
  if (@{$message_data->{attachments}}) {
    # $attachment_ids = process_attachments($message_data->{attachments});
  }

  $Dialogue->crm_send_message($message_data->{message}, {
    DIALOGUE_ID => $dialogue_id,
    ATTACHMENTS => $attachment_ids
  });
}

#**********************************************************
=head2 process_attachments($attachments)

  Process and save message attachments

  Arguments:
    $attachments - Array reference of attachment data

  Returns:
    Array reference of attachment IDs

=cut
#**********************************************************
sub process_attachments {
  my ($attachments) = @_;

  if (!$attachments || ref $attachments ne 'ARRAY') {
    return [];
  }

  use Crm::Attachments;
  my $Attachments = Crm::Attachments->new($db, $admin, \%conf);
  my @attachment_ids = ();

  foreach my $file (@{$attachments}) {
    if (!$file->{payload} || !$file->{payload}{url}) {
      next;
    }

    my $attachment_id = save_attachment($Attachments, $file);
    if ($attachment_id) {
      push @attachment_ids, $attachment_id;
    }
  }

  return \@attachment_ids;
}

#**********************************************************
=head2 save_attachment($Attachments, $file)

=cut
#**********************************************************
sub save_attachment {
  my ($Attachments, $file) = @_;

  my ($payload_url) = split(/\?/, $file->{payload}{url});
  my ($file_name) = $payload_url =~ m|/([^/]+)$|;

  if (!$file_name) {
    # log_error("Could not extract filename from URL: $payload_url");
    return;
  }

  my ($file_extension) = $file_name =~ /\.([^.]+)$/;
  my $mime_type = get_mime_type($file_extension);

  my $file_content = web_request($file->{payload}{url}, {
    CURL         => 1,
    CURL_OPTIONS => '-s',
  });

  if (!$file_content || $file_content eq 'Bad URL hash') {
    # log_error("Failed to download attachment: $file_name");
    return;
  }

  my $result = $Attachments->attachment_add({
    filename       => $file_name,
    Contents       => $file_content,
    'Content-Type' => $mime_type
  });

  if ($result->{errno} || !$result->{INSERT_ID}) {
    # log_error("Failed to save attachment: $file_name, Error: " . ($result->{errno} || 'Unknown'));
    return;
  }

  return $result->{INSERT_ID};
}

#**********************************************************
=head2 get_mime_type($extension)

=cut
#**********************************************************
sub get_mime_type {
  my ($extension) = @_;

  if (!$extension) {
    return '';
  }

  my %mime_types = (
    jpg  => 'image/jpeg',
    jpeg => 'image/jpeg',
    png  => 'image/png',
    gif  => 'image/gif',
    bmp  => 'image/bmp',
    pdf  => 'application/pdf',
    doc  => 'application/msword',
    docx => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  );

  return $mime_types{lc($extension)} || '';
}

#**********************************************************
=head2 log_error($message)

=cut
#**********************************************************
sub log_error {
  my ($message) = @_;

  my $timestamp = scalar localtime;
  my $log_entry = "[$timestamp] ERROR: $message\n";

  if (open my $fh, '>>', LOG_FILE) {
    print $fh $log_entry;
    close $fh;
  }

  warn $log_entry;
}