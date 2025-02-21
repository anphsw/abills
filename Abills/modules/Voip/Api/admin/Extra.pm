package Voip::Api::admin::Extra;

=head1 NAME

  Voip Trunks

  Endpoints:
    /voip/phones/
=cut

use strict;
use warnings FATAL => 'all';

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
=head2 get_voip_extra_tarifications($path_params, $query_params)

  Endpoint GET /voip/extra/tarifications/

=cut
#**********************************************************
sub get_voip_extra_tarifications {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Voip->extra_tarification_list({
    %$query_params,
    SORT         => $query_params->{SORT} ? $query_params->{SORT} : 1,
    DESC         => $query_params->{DESC} ? $query_params->{DESC} : '',
    PG           => $query_params->{PG} ? $query_params->{PG} : 0,
    PAGE_ROWS    => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    COLS_NAME    => 1
  });
}

#**********************************************************
=head2 get_voip_extra_tarifications_id($path_params, $query_params)

  Endpoint GET /voip/extra/tarifications/:id/

=cut
#**********************************************************
sub get_voip_extra_tarifications_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $route = $Voip->extra_tarification_info({ ID => $path_params->{id} });
  delete @{$route}{qw/AFFECTED TOTAL list/};
  return $route;
}

#**********************************************************
=head2 post_voip_extra_tarification($path_params, $query_params)

  Endpoint POST /voip/extra/tarification/

=cut
#**********************************************************
sub post_voip_extra_tarification {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 30007,
    errstr => 'no fields prepaidTime or name',
  } if (!$query_params->{NAME} || !$query_params->{PREPAID_TIME});

  $Voip->extra_tarification_add({
    NAME         => $query_params->{NAME},
    PREPAID_TIME => $query_params->{PREPAID_TIME} || '',
  });
}

#**********************************************************
=head2 put_voip_extra_tarification_id($path_params, $query_params)

  Endpoint PUT /voip/extra/tarification/:id/

=cut
#**********************************************************
sub put_voip_extra_tarification_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 30008,
    errstr => 'no fields prepaidTime and name, so no params to change',
  } if (!$query_params->{NAME} && !$query_params->{PREPAID_TIME});

  my $params = {};

  $params->{PREPAID_TIME} = $query_params->{PREPAID_TIME} if (defined $query_params->{PREPAID_TIME});
  $params->{NAME} = $query_params->{NAME} if (defined $query_params->{NAME});

  $Voip->extra_tarification_change({
    %$params,
    ID => $path_params->{id},
  });

  if ($Voip && $Voip->{errno}) {
    return $Voip;
  }
  else {
    return {
      result => "Successfully changed $path_params->{id}"
    };
  }
}

#**********************************************************
=head2 delete_voip_extra_tarification_id($path_params, $query_params)

  Endpoint PUT /voip/extra/tarification/:id/

=cut
#**********************************************************
sub delete_voip_extra_tarification_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->extra_tarification_del({ ID => $path_params->{id} });

  if (!$Voip->{errno}) {
    if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30015,
        errstr => "tarificationId $path_params->{id} not exists",
      };
    }
  }
  return $Voip;
}

1;
