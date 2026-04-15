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
use Tasks::Tasks_manager;

my Tasks $Tasks;
my Control::Errors $Errors;
my $Tasks_manager;

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

  $Tasks_manager = Tasks::Tasks_manager->new($db, $admin, $conf, { lang => $attr->{lang} });

  return $self;
}

#**********************************************************
=head2 post_tasks($path_params, $query_params)

  Endpoint POST /tasks

=cut
#**********************************************************
sub post_tasks {
  my ($self, $path_params, $query_params) = @_;

  return $Tasks_manager->tasks_add($query_params);
}

#**********************************************************
=head2 put_tasks($path_params, $query_params)

  Endpoint PUT /tasks/:id/

=cut
#**********************************************************
sub put_tasks {
  my ($self, $path_params, $query_params) = @_;

  return $Tasks_manager->tasks_change({ %$query_params, ID => $path_params->{id} });
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