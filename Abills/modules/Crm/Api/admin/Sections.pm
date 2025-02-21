package Crm::Api::admin::Sections;

=head1 NAME

  CRM sections manage

  Endpoints:
    /crm/sections/*

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
=head2 post_crm_actions($path_params, $query_params)

  Endpoint POST /crm/sections/

=cut
#**********************************************************
sub post_crm_sections {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_sections_add({ %{$query_params}, AID => $self->{admin}{AID} });
}

#**********************************************************
=head2 put_crm_sections_id($path_params, $query_params)

  Endpoint PUT /crm/sections/:id/

=cut
#**********************************************************
sub put_crm_sections_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_sections_change({ %{$query_params}, ID => $path_params->{id}, AID => $self->{admin}{AID} });
}

#**********************************************************
=head2 delete_crm_section_id($path_params, $query_params)

  Endpoint DELETE /crm/section/:id/

=cut
#**********************************************************
sub delete_crm_sections_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_sections_info({ ID => $path_params->{id} });
  if ($Crm->{TOTAL} < 1) {
    return {
      errno  => 104008,
      errstr => 'Section not found'
    };
  }

  $Crm->crm_sections_del({ ID => $path_params->{id} });

  if (!$Crm->{errno}) {
    return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
    return {
      errno  => 104009,
      errstr => 'Section not found'
    };
  }
}

1;
