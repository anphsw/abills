package Crm::Api::admin::Steps;

=head1 NAME

  CRM steps manage

  Endpoints:
    /crm/steps/*
    /crm/step/*

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
=head2 post_crm_step($path_params, $query_params)

  Endpoint POST /crm/step/

=cut
#**********************************************************
sub post_crm_step {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_progressbar_step_add($query_params);
}

#**********************************************************
=head2 put_crm_step_step_id($path_params, $query_params)

  Endpoint PUT /crm/step/:step_id/

=cut
#**********************************************************
sub put_crm_step_step_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_progressbar_step_change({ ID => $path_params->{step_id}, %{$query_params} });
}

#**********************************************************
=head2 delete_crm_step_step_id($path_params, $query_params)

  Endpoint DELETE /crm/step/:step_id/

=cut
#**********************************************************
sub delete_crm_step_step_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_progressbar_step_info({ ID => $path_params->{step_id} });
  if ($Crm->{TOTAL} < 1) {
    return {
      errno  => 104005,
      errstr => 'Step not found'
    };
  }

  $Crm->crm_progressbar_step_delete({ ID => $path_params->{step_id} });

  if (!$Crm->{errno}) {
    return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
    return {
      errno  => 104006,
      errstr => 'Step not found'
    };
  }
}

#**********************************************************
=head2 get_crm_step_step_id($path_params, $query_params)

  Endpoint GET /crm/step/:step_id/

=cut
#**********************************************************
sub get_crm_step_step_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_progressbar_step_info({ ID => $path_params->{step_id} });
}

#**********************************************************
=head2 get_crm_steps($path_params, $query_params)

  Endpoint GET /crm/steps/

=cut
#**********************************************************
sub get_crm_steps {
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

  $Crm->crm_progressbar_step_list($query_params);
}

1;
