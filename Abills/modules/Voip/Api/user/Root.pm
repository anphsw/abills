package Voip::Api::user::Root;

=head1 NAME

  User Voip

  Endpoints:
    /user/voip/*

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
=head2 get_user_voip($path_params, $query_params)

  Endpoint GET /user/voip/

=cut
#**********************************************************
sub get_user_voip {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
  my $tariffs = ::get_user_services({
    uid     => $path_params->{uid},
    service => 'Voip',
  });

  return $tariffs;
}

#**********************************************************
=head2 get_user_voip_sessions($path_params, $query_params)

  Endpoint GET /user/voip/sessions/

=cut
#**********************************************************
sub get_user_voip_sessions {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %result = ();
  my @PERIODS = ('Today', 'Yesterday', 'Week', 'Month', 'All sessions');

  $query_params = {
    SORT      => 2,
    DESC      => 'DESC',
    PAGE_ROWS => $query_params->{PAGE_ROWS} || 25,

    #TODO: move it to base params and defined them if they are possible

    FROM_DATE => ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef,
    TO_DATE   => ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef,
  };

  require Voip_Sessions;
  Voip_Sessions->import();
  my $Sessions = Voip_Sessions->new($self->{db}, $self->{admin}, $self->{conf});
  $Sessions->periods_totals({ %$query_params, UID => $path_params->{uid} });

  if (!defined $Sessions->{sum_4}) {
    return {
      result     => 'OK',
      warnings   => 'No sessions',
      warning_id => 30101
    };
  };

  for (my $i = 0; $i < 5; $i++) {
    $result{periods}{$PERIODS[$i]}{duration} = $Sessions->{'duration_' . $i};
    $result{periods}{$PERIODS[$i]}{sum} = $Sessions->{'sum_' . $i};
  }

  $Sessions->calculation($query_params);

  $result{periods}{stats} = {
    min => {
      sum      => $Sessions->{MIN_SUM},
      duration => $Sessions->{MIN_DUR}
    },
    max => {
      sum      => $Sessions->{MAX_SUM},
      duration => $Sessions->{MAX_DUR}
    },
    avg => {
      sum      => $Sessions->{AVG_SUM},
      duration => $Sessions->{AVG_DUR}
    },
  };

  my $sessions = $Sessions->list({
    %$query_params,
    COLS_NAME          => 1,
    TP_ID              => '_SHOW',
    CALLING_STATION_ID => '_SHOW',
    CALLED_STATION_ID  => '_SHOW',
    DURATION           => '_SHOW',
    SUM                => '_SHOW',
  });

  $result{sessions}{total} = {
    sum      => $Sessions->{SUM},
    duration => $Sessions->{DURATION}
  };

  if ($Sessions->{TOTAL} && $Sessions->{TOTAL} > 0) {
    foreach my $session (@{$sessions}) {
      delete @{$session}{qw/acct_session_id call_origin nas_id/};
    }
    $result{sessions}{list} = $sessions;
  }

  return \%result;
}

#**********************************************************
=head2 get_user_voip_routes($path_params, $query_params)

  Endpoint GET /user/voip/routes/

=cut
#**********************************************************
sub get_user_voip_routes {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->user_info($path_params->{uid});

  return {
    errno  => 30011,
    errstr => 'Not active voip service'
  } if (!($Voip->{TOTAL} && $Voip->{TOTAL} > 0));

  require Tariffs;
  Tariffs->import();
  my $Voip_tp = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

  my $list = $Voip_tp->ti_list({ TP_ID => $Voip->{TP_ID} });

  my @interval_ids = ();
  foreach my $line (@{$list}) {
    push @interval_ids, $line->[0];
  }

  $query_params = {
    PAGE_ROWS => $query_params->{PAGE_ROWS} || 25,
    PG        => $query_params->{PG} || 0,
  };

  $list = $Voip->rp_list({ %$query_params, COLS_NAME => 1 });
  my %prices = ();
  foreach my $line (@{$list}) {
    $prices{$line->{interval_id}}{$line->{route_id}} = $line->{price};
  }

  $list = $Voip->routes_list($query_params);

  my @result = ();
  my $price = 0;
  foreach my $line (@{$list}) {
    for (my $i = 0; $i < $Voip_tp->{TOTAL}; $i++) {
      if (defined($prices{$interval_ids[$i]}{$line->[4]})) {
        $price = $prices{ $interval_ids[$i] }{ $line->[4] };
      }
      else {
        $price = 0;
      }
    }
    push @result, {
      prefix => $line->[0],
      name   => $line->[1],
      status => $line->[2],
      price  => $price
    };
  }

  return \@result;
}


#**********************************************************
=head2 get_user_voip_tariffs($path_params, $query_params)

  Endpoint GET /user/voip/tariffs/

=cut
#**********************************************************
sub get_user_voip_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Control::Service_control;
  Control::Service_control->import();
  my $Service_control = Control::Service_control->new($self->{db}, $self->{admin}, $self->{conf});

  my $result = $Service_control->available_tariffs({
    SKIP_NOT_AVAILABLE_TARIFFS => 1,
    UID                        => $path_params->{uid},
    MODULE                     => 'Voip'
  });

  return {
    errno  => $result->{errno} || $result->{error},
    errstr => $result->{errstr}
  } if (ref $result eq 'HASH' && ($result->{error} || $result->{errno}));

  return $result;
}

1;
