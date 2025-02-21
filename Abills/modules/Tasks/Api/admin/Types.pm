package Tasks::Api::admin::Types;

=head1 NAME

  Tasks types manage

  Endpoints:
    /tasks/types/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(dirname cmd next_month in_array);
use Control::Errors;

use Tasks::db::Tasks;

my Tasks $Tasks;
my Control::Errors $Errors;

my %permissions = ();

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
    attr  => $attr
  };

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);

  $Tasks = Tasks->new($db, $admin, $conf);
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_tasks_type_by_id($path_params, $query_params)

  Endpoint GET /tasks/type/:id/

=cut
#**********************************************************
sub get_tasks_type_by_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $type_info = $Tasks->type_info({ ID => $path_params->{id} });
  return $type_info if $Tasks->{errno};

  my $type_fields = $Tasks->type_fields_list({
    TASK_TYPE_ID => $path_params->{id},
    NAME         => '_SHOW',
    TYPE         => '_SHOW',
    LABEL        => '_SHOW'
  });
  $type_info->{ADDITIONAL_FIELDS} = $type_fields;

  my $type_plugins = $Tasks->type_plugins_list({
    TASK_TYPE_ID => $path_params->{id},
    PLUGIN_NAME  => '_SHOW',
  });
  $type_info->{PLUGINS} = [];
  map push(@{$type_info->{PLUGINS}}, $_->{plugin_name}), @{$type_plugins};

  my $type_admins = $Tasks->type_admins_list({
    TASK_TYPE_ID => $path_params->{id},
    AID          => '_SHOW'
  });
  $type_info->{ADMINS} = [];
  map push(@{$type_info->{ADMINS}}, $_->{aid}), @{$type_admins};

  my $type_participants = $Tasks->type_participants_list({
    TASK_TYPE_ID => $path_params->{id},
    AID          => '_SHOW'
  });
  $type_info->{PARTICIPANTS} = [];
  map push(@{$type_info->{PARTICIPANTS}}, $_->{aid}), @{$type_participants};

  return $type_info;
}

#**********************************************************
=head2 get_tasks_types($path_params, $query_params)

  Endpoint GET /tasks/types/

=cut
#**********************************************************
sub get_tasks_types {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $type_fields = $Tasks->type_fields_list({
    TASK_TYPE_ID => '_SHOW',
    NAME         => '_SHOW',
    TYPE         => '_SHOW',
    LABEL        => '_SHOW'
  });
  my $type_fields_hash = {};
  foreach my $field (@{$type_fields}) {
    push @{$type_fields_hash->{$field->{task_type_id}}}, $field;
  }

  my $type_plugins = $Tasks->type_plugins_list({
    TASK_TYPE_ID => '_SHOW',
    PLUGIN_NAME  => '_SHOW'
  });
  my $type_plugins_hash = {};
  foreach my $plugin (@{$type_plugins}) {
    push @{$type_plugins_hash->{$plugin->{task_type_id}}}, $plugin->{plugin_name};
  }

  my $type_admins = $Tasks->type_admins_list({
    TASK_TYPE_ID => '_SHOW',
    AID          => '_SHOW'
  });
  my $type_admins_hash = {};
  foreach my $type_admin (@{$type_admins}) {
    push @{$type_admins_hash->{$type_admin->{task_type_id}}}, $type_admin->{aid};
  }

  my $type_participants = $Tasks->type_participants_list({
    TASK_TYPE_ID => '_SHOW',
    AID          => '_SHOW'
  });
  my $type_participants_hash = {};
  foreach my $participant (@{$type_participants}) {
    push @{$type_participants_hash->{$participant->{task_type_id}}}, $participant->{aid};
  }

  my $types = $Tasks->types_list({ NAME => '_SHOW', COLS_NAME => 1 });

  foreach my $type (@{$types}) {
    $type->{PARTICIPANTS} = $type_participants_hash->{$type->{id}} || [];
    $type->{ADMINS} = $type_admins_hash->{$type->{id}} || [];
    $type->{PLUGINS} = $type_plugins_hash->{$type->{id}} || [];
    $type->{ADDITIONAL_FIELDS} = $type_fields_hash->{$type->{id}} || [];
  }

  return $types;
}

#**********************************************************
=head2 post_tasks_type($path_params, $query_params)

  Endpoint POST /tasks/types/

=cut
#**********************************************************
sub post_tasks_type {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $task_add_result = $Tasks->type_add({ NAME => $query_params->{NAME} });
  return $Tasks if $Tasks->{errno} || !$Tasks->{INSERT_ID};
  
  my $task_type_id = $Tasks->{INSERT_ID};

  if ($query_params->{ADDITIONAL_FIELDS} && ref $query_params->{ADDITIONAL_FIELDS} eq 'ARRAY') {
    $Tasks->type_fields_add({
      ADDITIONAL_FIELDS => $query_params->{ADDITIONAL_FIELDS},
      TASK_TYPE_ID      => $task_type_id
    });
  }

  if ($query_params->{PLUGINS} && ref $query_params->{PLUGINS} eq 'ARRAY') {
    $Tasks->type_plugins_add({
      PLUGINS      => $query_params->{PLUGINS},
      TASK_TYPE_ID => $task_type_id
    });
  }

  if ($query_params->{ADMINS} && ref $query_params->{ADMINS} eq 'ARRAY') {
    $Tasks->type_admins_add({
      ADMINS       => $query_params->{ADMINS},
      TASK_TYPE_ID => $task_type_id
    });
  }

  if ($query_params->{PARTICIPANTS} && ref $query_params->{PARTICIPANTS} eq 'ARRAY') {
    $Tasks->type_participants_add({
      PARTICIPANTS => $query_params->{PARTICIPANTS},
      TASK_TYPE_ID => $task_type_id
    });
  }
  
  return $task_add_result;
}

#**********************************************************
=head2 put_tasks_type_by_id($path_params, $query_params)

  Endpoint PUS /tasks/types/:id/

=cut
#**********************************************************
sub put_tasks_type_by_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tasks->type_hide($path_params->{id});
  return $self->post_tasks_type($path_params, $query_params);
}

#**********************************************************
=head2 delete_tasks_type_by_id($path_params, $query_params)

  Endpoint DELETE /tasks/types/:id/

=cut
#**********************************************************
sub delete_tasks_type_by_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Tasks->type_hide($path_params->{id});
}

1;