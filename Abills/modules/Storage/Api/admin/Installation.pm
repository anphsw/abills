package Storage::Api::admin::Installation;

=head1 NAME

  Storage Installation

  Endpoints:
    /storage/installation/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Storage;

my Storage $Storage;
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

  $Storage = Storage->new($db, $admin, $conf);
  $Storage->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_storage_installation($path_params, $query_params)

  Endpoint GET /storage/installation/

=cut
#**********************************************************
sub get_storage_installation {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Storage->storage_installation_list({
    %{$query_params},
    COLS_NAME => 1
  });
}

1;
