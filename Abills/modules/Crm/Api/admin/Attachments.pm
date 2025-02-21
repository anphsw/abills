package Crm::Api::admin::Attachments;

=head1 NAME

  CRM attachments manage

  Endpoints:
    /crm/attachment/*

=cut

use strict;
use warnings FATAL => 'all';

use Crm::Attachments;

my Crm::Attachments $Attachments;

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

  $Attachments = Crm::Attachments->new($db, $admin, $conf);

  # $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_crm_attachment($path_params, $query_params)

  Endpoint POST /crm/attachment/

=cut
#**********************************************************
sub post_crm_attachment {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  if ($query_params->{FILE} && ref $query_params->{FILE} eq 'HASH') {
    return $Attachments->attachment_add($query_params->{FILE});
  }
  elsif ($query_params->{filename} && $query_params->{Contents}) {
    return $Attachments->attachment_add($query_params);
  }

  return $Attachments;
}

#**********************************************************
=head2 delete_crm_attachment_id($path_params, $query_params)

  Endpoint DELETE /crm/attachment/:id/

=cut
#**********************************************************
sub delete_crm_attachment_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Attachments->attachment_del($path_params->{id});
  return $result->{errno} ? $result : { result => 'Successfully deleted' };
}

#**********************************************************
=head2 get_crm_attachment_id_content($path_params, $query_params)

  Endpoint GET /crm/attachment/:id/content/

=cut
#**********************************************************
sub get_crm_attachment_id_content {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Attachments->attachment_info($path_params->{id});

  # return $result if $result->{errno};
  return $result->{CONTENT};
}

1;
