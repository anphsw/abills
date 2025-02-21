package Voip::Api::admin::Trunks;

=head1 NAME

  Voip Trunks

  Endpoints:
    /voip/trunks/
    /voip/trunk/*

=cut

use strict;
use warnings FATAL => 'all';

use Voip::Constants qw/TRUNK_PROTOCOLS/;

use Control::Errors;
use Voip;

my Voip $Voip;
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

  $Voip = Voip->new($db, $admin, $conf);
  $Voip->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_voip_trunk_protocols($path_params, $query_params)

  Endpoint GET /voip/trunk/protocols/

=cut
#**********************************************************
sub get_voip_trunk_protocols {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return TRUNK_PROTOCOLS;
}

#**********************************************************
=head2 get_voip_trunks($path_params, $query_params)

  Endpoint GET /voip/trunks/

=cut
#**********************************************************
sub get_voip_trunks {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{NAME} = $query_params->{NAME} || '_SHOW';
  $query_params->{PROTOCOL} = $query_params->{PROTOCOL} || '_SHOW';
  $query_params->{PROVNAME} = $query_params->{PROVIDER_NAME} || '_SHOW';
  $query_params->{FAILTRUNK} = $query_params->{FAILOVER_TRUNK} || '_SHOW';

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Voip->trunk_list({
    %$query_params,
    COLS_NAME => 1,
    PAGE_ROWS => ($query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25),
    SORT      => ($query_params->{SORT} ? $query_params->{SORT} : 1),
    PG        => (defined($query_params->{PG}) ? $query_params->{PG} : 0),
  });
}

#**********************************************************
=head2 get_voip_trunk_id($path_params, $query_params)

  Endpoint GET /voip/trunk/:id/

=cut
#**********************************************************
sub get_voip_trunk_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->trunk_info($path_params->{id});
}

#**********************************************************
=head2 post_voip_trunk($path_params, $query_params)

  Endpoint POST /voip/trunk/

=cut
#**********************************************************
sub post_voip_trunk {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->trunk_add($query_params);
}

#**********************************************************
=head2 delete_voip_trunk_id($path_params, $query_params)

  Endpoint DELETE /voip/trunk/:id/

=cut
#**********************************************************
sub delete_voip_trunk_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->trunk_del($path_params->{id});

  if (!$Voip->{errno}) {
    if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30010,
        errstr => "trunkId $path_params->{id} not exists",
      };
    }
  }
  return $Voip;
}

#**********************************************************
=head2 put_voip_trunk_id($path_params, $query_params)

  Endpoint PUT /voip/trunk/:id/

=cut
#**********************************************************
sub put_voip_trunk_id {
  my ($path_params, $query_params) = @_;

  delete $query_params->{ID};

  $Voip->trunk_change({ %$query_params, ID => $path_params->{id} });
}

1;
