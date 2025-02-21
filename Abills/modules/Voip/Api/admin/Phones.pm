package Voip::Api::admin::Phones;

=head1 NAME

  Voip Phones

  Endpoints:
    /voip/phones/
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
=head2 get_voip_phone_aliases($path_params, $query_params)

  Endpoint GET /voip/phone/aliases/

=cut
#**********************************************************
sub get_voip_phone_aliases {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->phone_aliases_list({
    NUMBER    => $query_params->{NUMBER} || '_SHOW',
    DISABLE   => $query_params->{DISABLE} || '_SHOW',
    CHANGED   => $query_params->{CHANGED} || '_SHOW',
    UID       => $query_params->{UID} || '_SHOW',
    COLS_NAME => 1,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    DESC      => $query_params->{DESC} ? $query_params->{DESC} : '',
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
  });
}

1;
