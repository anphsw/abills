package Iptv::Init;
=head1

  Iptv Init module

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use Abills::Loader qw/load_plugin/;
use Abills::Base qw/in_array/;

our @EXPORT = qw(
  init_iptv_service
);

our @EXPORT_OK = qw(
  init_iptv_service
);

#**********************************************************
=head2 init_iptv_service($db, $admin, $conf)

=cut
#**********************************************************
sub init_iptv_service {
  my ($db, $admin, $conf, $attr) = @_;

  my $Tv_service;
  if ($attr->{SERVICE_ID}) {
    use Iptv;
    my $Iptv = Iptv->new($db, $admin, $conf);
    $Iptv->services_info($attr->{SERVICE_ID});

    if ($Iptv->{TOTAL} && $Iptv->{MODULE}) {
      $Tv_service = load_plugin('Iptv::Plugins::' . ($Iptv->{MODULE} || ''), {
        SERVICE      => $Iptv,
        HTML         => $attr->{HTML},
        LANG         => $attr->{LANG},
        RETURN_ERROR => $attr->{RETURN_ERROR} ? 1 : 0
      });
    }
  }
  elsif ($attr->{MODULE}) {
    $Tv_service = load_plugin('Iptv::Plugins::' . ($attr->{MODULE} || ''), {
      SERVICE      => $attr->{SERVICE},
      HTML         => $attr->{HTML},
      LANG         => $attr->{LANG},
      RETURN_ERROR => $attr->{RETURN_ERROR} ? 1 : 0
    });
  }

  if (!$Tv_service || (ref $Tv_service eq 'HASH' && $Tv_service->{errno})) {
    return $Tv_service;
  }

  if ($attr->{CHECK_PLUGIN_ACTIVITY} && $Tv_service->can('test')) {
    $Tv_service->test();
    if ($Tv_service->{errno} && in_array('Events', \@main::MODULES)) {
      require Events::API;
      Events::API->import();
      my $Events = Events::API->new($db, $admin, $conf);

      $Events->add_event({
        TITLE    => 'Iptv: ' . $Tv_service->{SERVICE_NAME},
        MODULE   => 'Iptv',
        COMMENTS => 'The plugin is not active' . ($Tv_service->{errstr} ? ": $Tv_service->{errstr}" : ''),
        PRIORITY => 4
      });
    }
  }

  return $Tv_service;
}

1;
