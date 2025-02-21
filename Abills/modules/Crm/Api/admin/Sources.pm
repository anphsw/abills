package Crm::Api::admin::Sources;

=head1 NAME

  CRM sources manage

  Endpoints:
    /crm/sources/*

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
=head2 get_crm_sources($path_params, $query_params)

  Endpoint GET /crm/sources/

=cut
#**********************************************************
sub get_crm_sources {
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

  $Crm->leads_source_list($query_params);
}

1;
