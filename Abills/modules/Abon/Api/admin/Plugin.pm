package Abon::Api::admin::Plugin;

=head1 NAME

  Abon plugin manage

  Endpoints:
    /abon/plugin/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(convert);
use Control::Errors;
use Abills::Loader qw/load_plugin/;

use Abon;
use Abon::Base;

my Control::Errors $Errors;

my Abon $Abon;
my Abon::Base $Abon_base;
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
  $Abon_base = Abon::Base->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_abon_plugin_plugin_id_info($path_params, $query_params)

  Endpoint GET /abon/plugin/:plugin_id/info/

=cut
#**********************************************************
sub get_abon_plugin_plugin_id_info {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $Plugin_info = $Abon->tariff_info($path_params->{plugin_id});
  if (!$Abon->{TOTAL} || $Abon->{TOTAL} < 1) {
    return $Errors->throw_error(1020002);
  }

  return {} if !$Plugin_info->{PLUGIN};

  my $api = load_plugin('Abon::Plugins::' . $Plugin_info->{PLUGIN}, {
    SERVICE      => $Plugin_info,
    LANG         => $self->{lang},
    RETURN_ERROR => 1
  });

  return $api->info($query_params) if ($api->can('info'));
  return {};
}

#**********************************************************
=head2 get_abon_plugin_plugin_id_print($path_params, $query_params)

  Endpoint GET /abon/plugin/:plugin_id/print/

=cut
#**********************************************************
sub get_abon_plugin_plugin_id_print {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $Plugin_info = $Abon->tariff_info($path_params->{plugin_id});
  if (!$Abon->{TOTAL} || $Abon->{TOTAL} < 1) {
    return $Errors->throw_error(1020002);
  }

  return '' if !$Plugin_info->{PLUGIN};
  my $api = load_plugin('Abon::Plugins::' . $Plugin_info->{PLUGIN}, {
    SERVICE      => $Plugin_info,
    LANG         => $self->{lang},
    RETURN_ERROR => 1
  });

  return $api->print($query_params) if ($api->can('print'));
  return '';
}

1;
