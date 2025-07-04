package Storage::Api::user::Incoming_articles;

=head1 NAME

  Storage Installation

  Endpoints:
    /user/storage/incoming_articles/

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
=head2 get_incoming_articles_by_serial_number($path_params, $query_params)

  Endpoint GET /user/storage/incoming_articles/

=cut
#**********************************************************
sub get_incoming_articles_by_serial_number {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$query_params->{SERIAL} || $query_params->{SERIAL} =~ /\*/) {
    return {
      list  => [],
      total => 0
    };
  }

  my $incoming_articles = $Storage->storage_incoming_articles_list2({
    SERIAL            => $query_params->{SERIAL},
    ARTICLE_NAME      => '_SHOW',
    ARTICLE_TYPE_NAME => '_SHOW',
    SIA_COUNT         => '>0',
    SIA_SUM           => '_SHOW',
    COLS_NAME         => 1
  });

  return {
    list  => $incoming_articles || [],
    total => $Storage->{TOTAL},
  };
}

1;