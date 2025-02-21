package Crm::Api::admin::Workflow;

=head1 NAME

  CRM workflow

  Endpoints:
    /crm/workflow/*

=cut

use strict;
use warnings FATAL => 'all';

use Crm::db::Crm;
my Crm $Crm;

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

  # $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_crm_workflow($path_params, $query_params)

  Endpoint POST /crm/workflow/

=cut
#**********************************************************
sub post_crm_workflow {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_workflow_add($query_params);
}

#**********************************************************
=head2 post_crm_workflow_id($path_params, $query_params)

  Endpoint POST /crm/workflow/:id/

=cut
#**********************************************************
sub post_crm_workflow_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_workflow_change({ %{$query_params}, ID => $path_params->{id} });
}

1;
