package Cams::Init;
=head1

  Cams Init module

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use Abills::Loader qw/load_plugin/;
use Abills::Base qw/in_array/;

our @EXPORT = qw(
  init_cams_service
);

our @EXPORT_OK = qw(
  init_cams_service
);

#**********************************************************
=head2 init_cams_service($db, $admin, $conf)

=cut
#**********************************************************
sub init_cams_service {
  my ($db, $admin, $conf, $attr) = @_;

  my $Cams_service;
  if ($attr->{SERVICE_ID}) {
    use Cams;
    my $Cams = Cams->new($db, $admin, $conf);
    $Cams->services_info($attr->{SERVICE_ID});

    if ($Cams->{TOTAL} && $Cams->{MODULE}) {
      $Cams_service = load_plugin('Cams::Plugins::' . ($Cams->{MODULE} || ''), {
        SERVICE        => $Cams,
        HTML           => $attr->{HTML},
        LANG           => $attr->{LANG},
        RETURN_ERROR   => $attr->{RETURN_ERROR} ? 1 : 0,
        SOFT_EXCEPTION => $attr->{SOFT_EXCEPTION}
      });
    }
  }
  elsif ($attr->{MODULE}) {
    $Cams_service = load_plugin('Cams::Plugins::' . ($attr->{MODULE} || ''), {
      SERVICE        => $attr->{SERVICE},
      HTML           => $attr->{HTML},
      LANG           => $attr->{LANG},
      RETURN_ERROR   => $attr->{RETURN_ERROR} ? 1 : 0,
      SOFT_EXCEPTION => $attr->{SOFT_EXCEPTION}
    });
  }

  if (!$Cams_service || (ref $Cams_service eq 'HASH' && $Cams_service->{errno})) {
    return $Cams_service;
  }

  return $Cams_service;
}

1;
