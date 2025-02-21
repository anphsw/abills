package Voip::Api::admin::Sessions;

=head1 NAME

  Voip Trunks

  Endpoints:
    /voip/sessions/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Voip_Sessions;

my Voip_Sessions $Voip_Sessions;
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

  $Voip_Sessions = Voip_Sessions->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_voip_sessions($path_params, $query_params)

  Endpoint GET /voip/sessions/

=cut
#**********************************************************
sub get_voip_sessions {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $list = $Voip_Sessions->list({
    %$query_params,
    FROM_DATE => ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef,
    TO_DATE   => ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef,
    COLS_NAME => 1,
  });

  return $list;
}

1;
