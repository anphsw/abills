package Crm::Api::admin::Deals;

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
=head2 put_crm_deals_id($path_params, $query_params)

  Endpoint PUT /crm/deals/:id/

=cut
#**********************************************************
sub put_crm_deals_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Crm->crm_deals_change({ %{$query_params}, ID => $path_params->{id} });
}

1;
