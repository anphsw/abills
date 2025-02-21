package Tasks::Api::admin::Tasks;

=head1 NAME

  Tasks manage

  Endpoints:
    /tasks/*

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
=head2 post_tasks($path_params, $query_params)

  Endpoint POST /tasks

=cut
#**********************************************************
sub post_tasks {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Tasks->add($query_params);
  return $Tasks if $Tasks->{errno} || !$Tasks->{INSERT_ID};

  my $task_id = $Tasks->{INSERT_ID};

  if (!$query_params->{PATH} && $query_params->{PARENT_ID}) {
    my $task = $Tasks->info({ ID => $query_params->{PARENT_ID} });
    if (!$Tasks->{errno} && !$task->{PATH}) {
      $Tasks->change({ ID => $query_params->{PARENT_ID}, PATH => $query_params->{PARENT_ID} });
      $task->{PATH} = $query_params->{PARENT_ID};
    }

    my $path = join('/', ($task->{PATH}, $task_id));
    $Tasks->change({ ID => $task_id, PATH => $path });
  }
  else {
    $Tasks->change({ ID => $task_id, PATH => $task_id });
  }

  return $Tasks;
}

#**********************************************************
=head2 put_tasks($path_params, $query_params)

  Endpoint PUT /tasks/:id/

=cut
#**********************************************************
sub put_tasks {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $old_info = $Tasks->info({ ID => $path_params->{id} });
  my $old_path = $old_info->{PATH};
  my $old_state = $old_info->{STATE};

  if ($query_params->{STATE} && $old_state ne $query_params->{STATE}) {
    my $subtasks = $Tasks->list({ PARENT_ID => $path_params->{id}, STATE => '0' });
    return $Errors->throw_error(1580001) if $Tasks->{TOTAL} && $Tasks->{TOTAL} > 0;
  }

  if ($query_params->{PARENT_ID}) {
    my $task = $Tasks->info({ ID => $query_params->{PARENT_ID} });
    if (!$Tasks->{errno} && !$task->{PATH}) {
      $self->district_change({ ID => $query_params->{PARENT_ID}, PATH => $query_params->{PARENT_ID} });
      $task->{PATH} = $query_params->{PARENT_ID};
    }

    my $current_path = join('/', ($task->{PATH}, $path_params->{id}));

    if ($current_path ne $old_path) {
      $query_params->{PATH} = $current_path;
      $Tasks->query("UPDATE tasks_main SET path = REPLACE(path, '$old_path', '$current_path') WHERE path LIKE '$old_path%';", 'do')
    }
  }
  elsif (defined $query_params->{PARENT_ID}) {
    $query_params->{PATH} = $path_params->{id};
  }

  $query_params->{CLOSED_DATE} = $main::DATE if $query_params->{STATE} && !$query_params->{CLOSED_DATE};

  $Tasks->change({ %{$query_params}, ID => $path_params->{id} });

  return $Tasks;
}

#**********************************************************
=head2 get_tasks($path_params, $query_params)

  Endpoint GET /tasks/

=cut
#**********************************************************
sub get_tasks {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0')
      ? $query_params->{$param}
      : '_SHOW';
  }

  my $list = $Tasks->list({ %$query_params, %PARAMS });

  return {
    list  => $list,
    total => $Tasks->{TOTAL}
  };
}

#**********************************************************
=head2 delete_task_id($path_params, $query_params)

  Endpoint DELETE /tasks/:id/

=cut
#**********************************************************
sub delete_task_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $task = $Tasks->info({ ID => $path_params->{id} });
  my $path = $task->{PATH};
  if ($path && !$Tasks->{errno}) {
    $Tasks->query("DELETE FROM tasks_main WHERE path LIKE '$path%';", 'do');
  }

  return $Tasks->del({ ID => $path_params->{id} });
}

#**********************************************************
=head2 get_task_id($path_params, $query_params)

  Endpoint GET /tasks/:id/

=cut
#**********************************************************
sub get_task_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Tasks->info({ ID => $path_params->{id} });
}

1;