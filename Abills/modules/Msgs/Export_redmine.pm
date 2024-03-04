package Export_redmine;

=head1 NAME

  Export to redmine

=head1 VERSION

  VERSION: 1.22

  API:
    http://www.redmine.org/projects/redmine/wiki/Rest_api

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(load_pmodule);
use Abills::Fetcher;

our $VERSION = 1.22;

my $MODULE = 'Export_redmine';
my ($json);
my ($admin, $CONF);

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };
  bless($self, $class);

  load_pmodule('JSON');

  $json = JSON->new->allow_nonref;

  $self->{api_url} = $CONF->{MSGS_REDMINE_APIURL} || '';
  $self->{api_login} = $CONF->{MSGS_REDMINE_LOGIN} || '';
  $self->{api_passwd} = $CONF->{MSGS_REDMINE_PASSWORD} || '';
  $self->{api_key} = $CONF->{MSGS_REDMINE_APIKEY} || '';
  $self->{project_id} = $CONF->{MSGS_REDMINE_PROJECT_ID} || '1';
  $self->{subject_prefix} = $CONF->{MSGS_REDMINE_SUBJECT_PREFIX} // '#S';

  if ($self->{api_url} && $self->{api_url} !~ /\/$/) {
    $self->{api_url} .= '/';
  }

  $self->{debug} = $CONF->{MSGS_REDMINE_DEBUG};
  $self->{SERVICE_NAME} = 'Redmine';
  $self->{VERSION} = $VERSION;

  return $self;
}

#**********************************************************
=head2 task_list() list of tasks

=cut
#**********************************************************
sub task_list {
  my $self = shift;
  my ($attr) = @_;

  my $project_id = $attr->{PROJECT} || $self->{project_id};
  return $self if !$project_id;

  $self->send_request({
    ACTION => "issues.json?sort=id:desc",
  });

  return $self;
}

#**********************************************************
=head2 check_dublicate($attr) list of tasks

  Attributes:
    $attr
      SUBJECT

=cut
#**********************************************************
sub check_dublicate {
  my $self = shift;
  my $search_query = shift;
  my ($attr) = @_;

  my $project = $attr->{PROJECT_ID} || $self->{project_id};

  return 0 unless ($search_query);
  # Search for issue with query in title

  my $project_info = $self->project_info($project);
  return 0 if !$project_info->{id};

  $self->send_request({
    ACTION => "search.json?utf8=%E2%9C%93&q=$search_query"
      . "&scope=all&project_id=$project&titles_only=1&issues=1&attachments=0&options=1",
  });
  return 0 if ($self->{errno});

  if ($self->{RESULT} && defined $self->{RESULT}->{total_count}) {
    if ($self->{RESULT}{results} && ref $self->{RESULT}{results} eq 'ARRAY') {
      foreach my $task (@{$self->{RESULT}{results}}) {
        my $task_info = $self->task_info({ TASK_ID => $task->{id} });
        
        if ($task_info->{project} && $task_info->{project}{id} & $task_info->{project}{id} eq $project_info->{id}) {
          $self->{TASK_ID} = $task->{id};
          $self->{TASK_LINK} = $self->{api_url};
          $self->{TASK_LINK} =~ s/\/[a-zA-Z]+\/[a-zA-Z0-9]+\/?$//;
          $self->{TASK_LINK} .= "/issues/" . $task->{id};
          return 1;
        }
      }
    }
  }

  return 0;
}

#**********************************************************
=head2 export_task($attr) list of tasks

  Attributes:
    $attr
      ID
      SUBJECT
      MESSAGE
      PRIORITY

  Results:
    $self
      $Export_redmine->{TASK_ID}

=cut
#**********************************************************
sub export_task {
  my $self = shift;
  my ($attr) = @_;

  my $priority = $attr->{PRIORITY} || 2;

  # '%23' is url encoded '#'
  if ($self->check_dublicate('%23S' . $attr->{ID}, $attr)) {
    $self->{errno} = 7;
    $self->{errstr} = 'EXIST';
    return $self;
  }

  $attr->{MESSAGE} =~ s/\\\"/\"/g;

  my $data = {
    "issue" => {
      "project_id"  => $attr->{PROJECT_ID} || $self->{project_id},
      "subject"     => "$self->{subject_prefix}$attr->{ID} $attr->{SUBJECT}",
      "priority_id" => $priority,
      "notes"       => 'ABillS',
      "description" => $attr->{MESSAGE}
    }
  };

  $self->send_request({
    ACTION   => "/projects/$data->{issue}{project_id}/issues.json",
    JSON_BODY => $data,
    METHOD   => 'POST',
  });

  if ($self->{RESULT} && $self->{RESULT}->{issue}->{id}) {
    $self->{TASK_ID} = $self->{RESULT}->{issue}->{id};
    $self->{TASK_LINK} = $self->{api_url};
    $self->{TASK_LINK} =~ s/\/[a-zA-Z]+\/[a-zA-Z0-9]+\/?$//;
    $self->{TASK_LINK} .= '/issues/' . $self->{TASK_ID};
  }

  return $self;
}

#**********************************************************
=head2 task_info($attr)

=cut
#**********************************************************
sub task_info {
  my $self = shift;
  my ($attr) = @_;

  my $task_id = $attr->{TASK_ID} || 0;
  return $self if !$task_id;

  $self->send_request({
    ACTION   => "issues.json?issue_id=$task_id&status_id=*",
    METHOD   => 'GET',
  });
  $self->{TASK_LINK} = $self->{api_url};
  $self->{TASK_LINK} =~ s/\/[a-zA-Z]+\/[a-zA-Z0-9]+\/?$//;
  $self->{TASK_LINK} .= '/issues/' . $task_id;

  if ($self->{RESULT} && $self->{RESULT}{issues} && $self->{RESULT}{issues}[0]) {
    return $self->{RESULT}{issues}[0];
  }

  return {};
}

#**********************************************************
=head2 project_info($attr)

=cut
#**********************************************************
sub project_info {
  my $self = shift;
  my $project_id = shift;

  return {} if !$project_id;

  $self->send_request({
    ACTION   => "projects/$project_id.json",
    METHOD   => 'GET',
  });

  if ($self->{RESULT} && $self->{RESULT}{project}) {
    return $self->{RESULT}{project};
  }

  return {};
}

#**********************************************************
=head2 task_list() list of tasks

=cut
#**********************************************************
sub project_list {
  my $self = shift;
  #my ($attr) = @_;

  $self->send_request({ ACTION => 'projects.json' });

  return $self->{RESULT} && $self->{RESULT}{projects} ? $self->{RESULT}{projects} : [];
}

#**********************************************************
=head2 send_request()

=cut
#**********************************************************
sub send_request {
  my $self = shift;
  my ($attr) = @_;

  my $request_url = $self->{api_url};

  delete($self->{errno});
  delete($self->{error});
  delete($self->{errstr});

  if ($attr->{ACTION}) {
    $request_url .= "$attr->{ACTION}";
  }

  my @headers = ('Content-Type: application/json');

  if ($self->{api_key}) {
    push @headers, "X-Redmine-API-Key: $self->{api_key}";
  }

  my $result = web_request($request_url, {
    JSON_BODY      => $attr->{JSON_BODY},
    JSON_FORMER   => {
      CONTROL_CHARACTERS => 1
    },
    DEBUG         => (defined($attr->{DEBUG})) ? $attr->{DEBUG} : $self->{debug},
    CURL          => 1,
    HEADERS       => \@headers,
    REQUEST_COUNT => $self->{request_count},
    CURL_OPTIONS  => ($attr->{METHOD}) ? "-X $attr->{METHOD}" : undef,
    TPL_DIR       => $CONF->{TPL_DIR}
  });


  $result = $attr->{_RESULT} if ($attr->{_RESULT});

  if ($result =~ /API not enabled/) {
    $self->{errno} = 3;
    $self->{error} = 3;
    $self->{errstr} = "API_NOT_ENABLED";
    return $result;
  }
  elsif ($result =~ /Timeout/) {
    $self->{errno} = 50;
    $self->{error} = 50;
    $self->{errstr} = "TIMEOUT";
    return $result;
  }
  elsif ($result =~ /Not Found/) {
    $self->{errno} = 4;
    $self->{error} = 4;
    $self->{errstr} = "NOT_FOUND";
    return $result;
  }

  return if (!$result);

  my $perl_scalar = $json->decode($result);

  if ($perl_scalar->{status} && $perl_scalar->{status} eq 'ERROR') {
    $self->{errno} = 1;
    $self->{error} = 1;
    $self->{errstr} = "$perl_scalar->{error}";
  }

  $self->{RESULT} = $perl_scalar;

  return $result;
}

1
