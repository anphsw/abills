package Crm::Plugins::Workflow::GoogleCopy;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Plugins::Workflow::GoogleCopy

=head2 SYNOPSIS

  Plugin for Google file copy

=cut

my $Crm;
use Abills::Base qw(in_array vars2lang);
use Crm::db::Crm;

use Abills::Fetcher qw(web_request);
use Abills::Google;

#**********************************************************
=head2 new($db,$admin,\%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $Crm //= Crm->new(@{$self}{qw/db admin conf/});

  return $self;
}

#**********************************************************
=head2 execute($lead_id)

=cut
#**********************************************************
sub execute {
  my $self = shift;
  my $lead_id = shift;

  if (!$self->_check_fields()) {
    return { errno => 10, errstr => '' };
  }

  my $lead = $Crm->crm_lead_info({ ID => $lead_id });
  my $step_id_hash = $Crm->crm_step_number_leads();

  my ($url, $filename) = $self->_copy_file($lead);

  my $change_field = $self->{conf}->{CRM_WORKFLOW_GOOGLECOPY_CHANGE_FIELD};

  $Crm->crm_lead_change({
    ID            => $lead_id,
    $change_field => $url
  });

  $Crm->progressbar_comment_add({
    LEAD_ID => $lead_id,
    STEP_ID => $step_id_hash->{$lead->{CURRENT_STEP}} || 1,
    MESSAGE => "File $filename successfully created.",
    DATE    => "$main::DATE $main::TIME"
  });
}

#**********************************************************
=head2 _check_fields()

=cut
#**********************************************************
sub _check_fields {
  my $self = shift;
  my @fields = (
    'CRM_WORKFLOW_GOOGLECOPY_FILE_ID',
    'CRM_WORKFLOW_GOOGLECOPY_CHANGE_FIELD',
    'CRM_WORKFLOW_GOOGLECOPY_FILENAME_PREFIX'
  );

  for my $field (@fields) {
    if (!$self->{conf}->{$field}) {
      return 0;
    }
  }

  return 1;
}

#**********************************************************
=head2 _copy_file($lead_info)

=cut
#**********************************************************
sub _copy_file {
  my $self = shift;
  my ($lead) = @_;

  my $base_dir = $self->{conf}->{base_dir} || '/usr/abills';

  my $Google = Abills::Google->new({
    file_path => "$base_dir/Certs/google/service_account.json",
    scope     => [ 'https://www.googleapis.com/auth/drive' ],
  });

  my $exist_file_id = $self->{conf}->{CRM_WORKFLOW_GOOGLECOPY_FILE_ID};

  my $result = $Google->access_token();
  my $access_token = $result->{access_token};
  my @headers = ("Authorization: Bearer $access_token", 'Content-Type: application/json');

  my $new_file_name = $self->_make_file_name(\@headers, $lead);

  my $copy_url = "https://www.googleapis.com/drive/v3/files/$exist_file_id/copy";

  my $res = web_request($copy_url, {
    CURL        => 1,
    HEADERS     => \@headers,
    JSON_RETURN => 1,
    JSON_BODY   => {
      name => $new_file_name,
    }
  });

  my $url = "https://docs.google.com/spreadsheets/d/" . $res->{id};

  return ($url, $res->{name});
}

#**********************************************************
=head2 _make_file_name($headers, $lead)

=cut
#**********************************************************
sub _make_file_name {
  my $self = shift;
  my ($headers, $lead) = @_;

  my $exist_file_id = $self->{conf}->{CRM_WORKFLOW_GOOGLECOPY_FILE_ID};
  my $prefix_template = $self->{conf}->{CRM_WORKFLOW_GOOGLECOPY_FILENAME_PREFIX};

  # Get existing file name
  my $get_file_url = "https://www.googleapis.com/drive/v3/files/$exist_file_id";

  my $file_res = web_request($get_file_url, {
    CURL        => 1,
    HEADERS     => $headers,
    JSON_RETURN => 1
  });

  my $prefix = vars2lang($prefix_template, $lead);

  my $filename = $file_res->{name};
  $filename =~ s/(?:ШАБЛОН|TEMPLATE)_[a-zA-Z]{2}//;

  return $prefix . $filename;
}

1;