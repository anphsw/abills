package Storage::Api::admin::Incoming_articles;

=head1 NAME

  Storage Installation

  Endpoints:
    /storage/incoming_articles/

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
=head2 get_storage_incoming_articles($path_params, $query_params)

  Endpoint GET /storage/incoming_articles/

=cut
#**********************************************************
sub get_storage_incoming_articles {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $incoming_articles = $Storage->storage_incoming_articles_list2({
    %{$query_params},
    COLS_NAME => 1
  });

  return {
    list  => $incoming_articles,
    total => $Storage->{TOTAL},
  };
}

1;