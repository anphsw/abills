package Triplay::Api::Admin::Tariffs;
=head1 NAME

  Triplay tariffs

  Endpoints:
    /triplay/tariffs/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Triplay;
use Triplay::Services;

my Control::Errors $Errors;
my Triplay $Triplay;
my Triplay::Services $Triplay_services;

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

  $Triplay = Triplay->new($db, $admin, $conf);
  $Triplay_services = Triplay::Services->new($db, $admin, $conf, { HTML => $attr->{html}, LANG => $attr->{lang}, ERRORS => $Errors });

  $Triplay->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_triplay_tariffs($path_params, $query_params)

  Endpoint GET /triplay/tariffs/

=cut
#**********************************************************
sub get_triplay_tariffs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{TP_ID}) {
    $query_params->{INNER_TP_ID} = $query_params->{TP_ID};
    delete $query_params->{TP_ID};
  }

  if ($query_params->{ID}) {
    $query_params->{TP_ID} = $query_params->{v};
    delete $query_params->{ID};
  }

  $query_params->{STATUS} = $query_params->{SERVICE_STATUS};
  $query_params->{DISABLE} = $query_params->{SERVICE_STATUS};

  my $tp_list = $Triplay->tp_list({
    %$query_params,
    _SHOW_ALL_COLUMNS => 1,
    COLS_NAME         => 1,
  });

  return {
    list  => $tp_list,
    total => $Triplay->{TOTAL},
  };
}

1;
