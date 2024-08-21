package Triplay::Api::User::Services;
=head1 NAME

  Triplay service info

  Endpoints:
    /user/triplay/*

=cut
use strict;
use warnings FATAL => 'all';

use Triplay;

use Control::Errors;

my Triplay $Triplay;
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
    attr  => $attr
  };

  bless($self, $class);

  $Triplay = Triplay->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_triplay($path_params, $query_params)

  GET /user/triplay/

=cut
#**********************************************************
sub get_user_triplay {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 });
  return ::get_user_services({
    uid     => $path_params->{uid},
    service => 'Triplay',
  });
}

1;
