package Voip::Api::admin::Tariffs;

=head1 NAME

  Voip Tariffs

  Endpoints:
    /voip/tariffs/
    /voip/tariff/*

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
=head2 get_voip_tariffs($path_params, $query_params)

  Endpoint GET /voip/tariffs/

=cut
#**********************************************************
sub get_voip_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{COLS_NAME} = 1;
  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
  $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
  $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
  $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

  return $Voip->tp_list($query_params);
}

#**********************************************************
=head2 get_voip_tariff_tpId($path_params, $query_params)

  Endpoint GET /voip/tariff/:tpId/

=cut
#**********************************************************
sub get_voip_tariff_tpId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->tp_info($path_params->{tpId});

  return {
    errno  => 30019,
    errstr => "Tariff with tpId $path_params->{tpId}"
  } if (!$Voip->{TP_ID} || ($Voip->{errno} && $Voip->{errno} == 2));

  return {
    errno  => $Voip->{errno},
    errstr => $Voip->{errstr},
  } if ($Voip->{errno});

  delete $Voip->{TP_INFO};
  return $Voip;
}

#**********************************************************
=head2 post_voip_tariff($path_params, $query_params)

  Endpoint POST /voip/tariff/

=cut
#**********************************************************
sub post_voip_tariff {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 30001,
    errstr => 'No field id or value id not number',
  } if (!$query_params->{ID});

  return {
    errno  => 30002,
    errstr => 'No field name',
  } if (!$query_params->{NAME});

  my $PARAMS = $self->_tp_add_filter($query_params, 0);

  return $Voip->tp_add($PARAMS);
}

#**********************************************************
=head2 put_voip_tariff_tpId($path_params, $query_params)

  Endpoint PUT /voip/tariff/:tpId/

=cut
#**********************************************************
sub put_voip_tariff_tpId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $PARAMS = $self->_tp_add_filter($query_params, 1);
  $PARAMS->{TP_ID} = $path_params->{tpId};
  $Voip->tp_change($path_params->{tpId}, $PARAMS);

  return {
    errno      => 30003,
    errstr     => $Voip->{errstr},
    voip_error => $Voip->{errno}
  } if ($Voip->{errno});

  delete $Voip->{TP_INFO};
  return $Voip;
}

#**********************************************************
=head2 delete_voip_tariff_tpId($path_params, $query_params)

  Endpoint DELETE /voip/tariff/:tpId/

=cut
#**********************************************************
sub delete_voip_tariff_tpId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->tp_del($path_params->{tpId});

  if (!$Voip->{errno}) {
    if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30004,
        errstr => "tpId $path_params->{tpId} not exists",
      };
    }
  }
  return $Voip;
}

#**********************************************************
=head2 _tp_add_filter()

=cut
#**********************************************************
sub _tp_add_filter {
  shift;
  my ($query_params, $change) = @_;

  my %PARAMS = ();
  my @allowed_params = (
    'NEXT_PERIOD_STEP',
    'AGE',
    'SIMULTANEOUSLY',
    'FILTER_ID',
    'FEES_METHOD',
    'ACTIV_PRICE',
    'CREDIT_TRESSHOLD',
    'DAY_TIME_LIMIT',
    'MONTH_FEE',
    'CHANGE_PRICE',
    'MONTH_TIME_LIMIT',
    'FIRST_PERIOD_STEP',
    'DAY_FEE',
    'EXTRA_NUMBERS_MONTH_FEE',
    'ID',
    'TIME_DIVISION',
    'ADD_TP',
    'MIN_SESSION_COST',
    'WEEK_TIME_LIMIT',
    'MAX_SESSION_DURATION',
    'FREE_TIME',
    'TIME_TARIF',
    'NAME',
    'PAYMENT_TYPE',
    'FIRST_PERIOD',
    'EXTRA_NUMBERS_DAY_FEE',
    'ALERT',
  );

  foreach my $param (@allowed_params) {
    next if (!$query_params->{$param} && $change);
    $PARAMS{$param} = $query_params->{$param} || '';
  }

  return \%PARAMS;
}

1;
