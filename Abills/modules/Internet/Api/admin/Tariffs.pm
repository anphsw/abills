package Internet::Api::admin::Tariffs;

=head1 NAME

  Internet Tariffs

  Endpoints:
    /internet/tariff/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array mk_unique_value json_former/;
use Control::Errors;
use Internet;

my Internet $Internet;
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

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_internet_tariffs($path_params, $query_params)

  Endpoint GET /internet/tariffs/

=cut
#**********************************************************
sub get_internet_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{ACTIV_PRICE} = $query_params->{ACTIVATE_PRICE} if ($query_params->{ACTIVATE_PRICE});

  if ($query_params->{TP_ID}) {
    $query_params->{INNER_TP_ID} = $query_params->{TP_ID};
    delete $query_params->{TP_ID};
  }
  $query_params->{TP_ID} = $query_params->{ID} if ($query_params->{ID});

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  $Tariffs->list({
    %$query_params,
    MODULE       => 'Internet',
    COLS_NAME    => 1,
  });
}

#**********************************************************
=head2 post_internet_tariff($path_params, $query_params)

  Endpoint POST /internet/tariff/

=cut
#**********************************************************
sub post_internet_tariff {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params = $self->tariff_add_preprocess($query_params);
  return $query_params if ($query_params->{errno});

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  return $Tariffs->add({ %{$query_params}, MODULE => 'Internet' });
}

#**********************************************************
=head2 get_internet_tariff_tp_id($path_params, $query_params)

  Endpoint GET /internet/tariff/:tpId/

=cut
#**********************************************************
sub get_internet_tariff_tp_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  $Tariffs->info($path_params->{tpId});
  return $Tariffs if $Tariffs->{errno};

  my $tariff_gradients = $Tariffs->tp_gradients_list({
    TP_ID       => $path_params->{tpId},
    START_VALUE => '_SHOW',
    PRICE       => '_SHOW'
  });

  $Tariffs->{GRADIENTS} = ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) ? $tariff_gradients : [];

  delete @{$Tariffs}{qw/TOTAL list AFFECTED/};

  return $Tariffs;
}

#**********************************************************
=head2 put_internet_tariff_tpId($path_params, $query_params)

  Endpoint PUT /internet/tariff/:tpId/

=cut
#**********************************************************
sub put_internet_tariff_tpId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params = $self->tariff_add_preprocess($query_params);
  return $query_params if ($query_params->{errno});

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  return $Tariffs->change(($path_params->{tpId} || '--'), {
    %{$query_params},
    MODULE => 'Internet',
    TP_ID  => $path_params->{tpId}
  });
}

#**********************************************************
=head2 delete_internet_tariff_tpId($path_params, $query_params)

  Endpoint DELETE /internet/tariff/:tpId/

=cut
#**********************************************************
sub delete_internet_tariff_tpId {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Shedule;
  Shedule->import();
  my $Schedule = Shedule->new($self->{db}, $self->{conf}, $self->{admin});

  my $users_list = $Internet->user_list({
    TP_ID     => $path_params->{tpId},
    UID       => '_SHOW',
    COLS_NAME => 1
  });

  my $schedules = $Schedule->list({
    ACTION    => "*:$path_params->{tpId}",
    TYPE      => 'tp',
    MODULE    => 'Internet',
    COLS_NAME => 1,
  });

  if (($Internet->{TOTAL} && $Internet->{TOTAL} > 0) || ($Schedule->{TOTAL} && $Schedule->{TOTAL} > 0)) {
    my %users_msg = ();
    foreach my $user_tp (@{$users_list}) {
      $users_msg{active}{message} = 'List of users who currently have an active tariff plan';
      push @{$users_msg{active}{users}}, $user_tp->{uid};
    }

    foreach my $schedule (@{$schedules}) {
      $users_msg{schedule}{message} = 'List of users who have scheduled a change in their tariff plan';
      push @{$users_msg{schedule}{users}}, $schedule->{uid};
    }

    return {
      errno  => 102005,
      errstr => "Can not delete tariff plan with tpId $path_params->{tpId}",
      users  => \%users_msg,
    };
  }
  else {
    require Tariffs;
    Tariffs->import();
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
    $Tariffs->del($path_params->{tpId});

    if (!$Tariffs->{errno}) {
      if ($Tariffs->{AFFECTED} && $Tariffs->{AFFECTED} =~ /^[0-9]$/) {
        return {
          result => 'Successfully deleted',
        };
      }
      else {
        return {
          errno  => 102006,
          errstr => "No tariff plan with tpId $path_params->{tpId}",
          tpId   => $path_params->{tpId},
        };
      }
    }

    return $Tariffs;
  }
}

#**********************************************************
=head2 new($, $admin, $CONF)

  Arguments:
    $query_params: object - hash of query params from request

  Returns:
    updated $query_params

=cut
#**********************************************************
sub tariff_add_preprocess {
  my $self = shift;
  my ($query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4};

  $query_params->{SIMULTANEOUSLY} = $query_params->{SIMULTANEOUSLY} if ($query_params->{LOGINS});
  $query_params->{ALERT} = $query_params->{UPLIMIT} if ($query_params->{UPLIMIT});
  $query_params->{ACTIV_PRICE} = $query_params->{ACTIVATE_PRICE} if ($query_params->{ACTIVATE_PRICE});
  $query_params->{NEXT_TARIF_PLAN} = $query_params->{NEXT_TP_ID} if ($query_params->{NEXT_TP_ID});

  if ($query_params->{CREATE_FEES_TYPE}) {
    require Fees;
    Fees->import();
    my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});
    $Fees->fees_type_add({ NAME => $query_params->{NAME}});
    $query_params->{FEES_METHOD} = $Fees->{INSERT_ID};
  }

  if ($query_params->{RAD_PAIRS}) {
    require Abills::Radius_Pairs;
    Abills::Radius_Pairs->import();
    $query_params->{RAD_PAIRS} = Abills::Radius_Pairs::parse_radius_params_json(json_former($query_params->{RAD_PAIRS}));
  }

  if ($query_params->{PERIOD_ALIGNMENT} || $query_params->{ABON_DISTRIBUTION} || $query_params->{FIXED_FEES_DAY}) {
    my $period = $query_params->{PERIOD_ALIGNMENT} ? $query_params->{PERIOD_ALIGNMENT} > 0 : 0;
    my $distribution = $query_params->{ABON_DISTRIBUTION} ? $query_params->{ABON_DISTRIBUTION} > 0 : 0;
    my $fixed = $query_params->{FIXED_FEES_DAY} ? $query_params->{FIXED_FEES_DAY} > 0 : 0;
    return {
      errno  => 102007,
      errstr => "Can not use params periodAlignment, abonDistribution and fixedFeesDay",
    } if (($period + $distribution + $fixed) > 1);
  }

  return $query_params;
}

1;
