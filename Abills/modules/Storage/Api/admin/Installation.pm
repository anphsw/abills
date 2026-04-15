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
use Storage::Installation;

my Storage $Storage;
my Control::Errors $Errors;
my Storage::Installation $Installation;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Storage = Storage->new($db, $admin, $conf);
  $Installation = Storage::Installation->new($db, $admin, $conf, { lang => $self->{lang}, html => $self->{html}, libpath => $self->{libpath} });
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
  my ($self, $path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Storage->storage_installation_list({
    %{$query_params},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 post_storage_installation($path_params, $query_params)

  Endpoint POST /storage/installation/

=cut
#**********************************************************
sub post_storage_installation {
  my ($self, $path_params, $query_params) = @_;

  return $Installation->storage_add_installation($query_params);
}

#**********************************************************
=head2 del_storage_installation($path_params, $query_params)

  Endpoint DELETE /storage/installation/:id/

=cut
#**********************************************************
sub del_storage_installation {
  my ($self, $path_params, $query_params) = @_;

  my $installation_id = $path_params->{id};
  return $Installation->storage_del_installation({ INSTALLATION_ID => $installation_id });
}

1;
