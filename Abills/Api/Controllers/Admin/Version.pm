package Api::Controllers::Admin::Version;

=head1 NAME

  ADMIN API Version

  Endpoints:
    /version/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;

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

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_version($path_params, $query_params)

  Endpoint GET /version/

=cut
#**********************************************************
sub get_version {
  my $version = ::get_version();
  ($version) = $version =~ /\d+.\d+.\d+/g;
  return {
    version     => "$version",
    billing     => 'ABillS',
    api_version => $Abills::Api::Paths::VERSION,
  };
}

1;
