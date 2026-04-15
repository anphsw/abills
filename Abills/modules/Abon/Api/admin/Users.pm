package Abon::Api::admin::Users;

=head1 NAME

  Abon users manage

  Endpoints:
    /abon/users/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(convert);
use Control::Errors;

use Abon;

my Control::Errors $Errors;

my Abon $Abon;
my %permissions = ();

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
    lang  => $attr->{lang}
  };

  %permissions = %{$attr->{permissions} || {}};

  bless($self, $class);

  $Abon = Abon->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_abon_users($path_params, $query_params)

  Endpoint GET /abon/users/

=cut
#**********************************************************
sub get_abon_users {
  my ($self, $path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ?
      $query_params->{$param} : '_SHOW';
  }

  return $Abon->user_list({
    LOGIN         => '_SHOW',
    FIO           => '_SHOW',
    %$query_params,
    _SHOW_ALL_COLUMNS => 1,
  });
}

1;
