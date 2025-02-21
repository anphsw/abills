package Msgs::Api::admin::Workflow;

=head1 NAME

  Msgs manage

  Endpoints:
    /msgs/workflow/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Msgs;

my Msgs $Msgs;
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
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Msgs = Msgs->new($db, $admin, $conf);
  $Msgs->{debug} = $self->{debug};
  $self->{permissions} = $Msgs->permissions_list($admin->{AID});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_msgs_workflow($path_params, $query_params)

  Endpoint POST /msgs/workflow/

=cut
#**********************************************************
sub post_msgs_workflow {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->msgs_workflow_add($query_params);
}

#**********************************************************
=head2 post_msgs_workflow_id($path_params, $query_params)

  Endpoint POST /msgs/workflow/:id/

=cut
#**********************************************************
sub post_msgs_workflow_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Msgs->msgs_workflow_change({ %{$query_params}, ID => $path_params->{id} });
}

1;
