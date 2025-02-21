package Paysys::Api::admin::Merchants;

=head1 NAME

  Admin Paysys merchants paths

  Endpoints:
    /paysys/merchants/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(mk_unique_value);
use Control::Errors;
use Paysys;
use Paysys::Init;

my Paysys $Paysys;
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

  $Paysys = Paysys->new($db, $admin, $conf);
  $Paysys->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_paysys_merchants($path_params, $query_params)

  Endpoint GET /paysys/merchants/

=cut
#**********************************************************
sub get_paysys_merchants {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  Abills::Base::_bp('', $query_params, {TO_FILE => '/usr/abills/var/log/paysys_check.log'});

  return $Paysys->merchant_settings_list({
    %$query_params,
    ID             => '_SHOW',
    MERCHANT_NAME  => '_SHOW',
    SYSTEM_ID      => '_SHOW',
    PAYSYSTEM_NAME => '_SHOW',
    MODULE         => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    COLS_NAME      => $query_params->{LIST2HASH} ? 0 : 1,
  });
}

1;
