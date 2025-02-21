package Docs::Api::admin::Users;
=head1 NAME

  Docs users

  Endpoints:
    /docs/users/*

=cut
use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Docs;

my Docs $Docs;
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

  $Docs = Docs->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_docs_users_uid($path_params, $query_params)

  Endpoint GET /docs/users/:uid/

=cut
#**********************************************************
sub get_docs_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Docs->user_info($path_params->{uid});

  return $Docs;
}

1;
