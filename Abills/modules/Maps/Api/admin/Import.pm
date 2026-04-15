package Maps::Api::admin::Import;

=head1 NAME

  Maps Import

  Endpoints:
    /maps/import/

=cut

use strict;
use warnings FATAL => 'all';

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

  return $self;
}

#**********************************************************
=head2 post_maps_import($path_params, $query_params)

  Endpoint POST /maps/import/

=cut
#**********************************************************
sub post_maps_import {
  my ($self, $path_params, $query_params) = @_;

  require Maps::Import;
  my $Import = Maps::Import->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang} });

  return $Import->maps_import($query_params);
}

1;
