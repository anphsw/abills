package Crm::Api::admin::Progressbar;

=head1 NAME

  CRM progressbar manage

  Endpoints:
    /crm/progressbar/*

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
=head2 post_crm_progressbar_messages($path_params, $query_params)

  Endpoint POST /crm/progressbar/messages/

=cut
#**********************************************************
sub post_crm_progressbar_messages {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Crm->progressbar_comment_add({ %{$query_params}, DOMAIN_ID => $self->{admin}{DOMAIN_ID} || 0 });
}

#**********************************************************
=head2 put_crm_progressbar_messages_id($path_params, $query_params)

  Endpoint PUT /crm/progressbar/messages/:id/

=cut
#**********************************************************
sub put_crm_progressbar_messages_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Crm->progressbar_comment_change({ %{$query_params}, ID => $path_params->{id} });
}

#**********************************************************
=head2 delete_crm_progressbar_messages_id($path_params, $query_params)

  Endpoint DELETE /crm/progressbar/messages/:id/

=cut
#**********************************************************
sub delete_crm_progressbar_messages_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->progressbar_comment_delete({ ID => $path_params->{id} });

  if (!$Crm->{errno}) {
    return { result => 'Successfully deleted' } if ($Crm->{AFFECTED} && $Crm->{AFFECTED} =~ /^[0-9]$/);
    return {
      errno  => 104001,
      errstr => "No message with id $path_params->{id}"
    };
  }
}

1;
