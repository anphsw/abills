package Docs::Init;
=head1

  Docs Init module

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Abills::Loader qw(load_plugin);
use Docs;

our @EXPORT = qw(
  init_esign_service
);

our @EXPORT_OK = qw(
  init_esign_service
);

#**********************************************************
=head2 init_esign_service($db, $admin, $conf)

=cut
#**********************************************************
sub init_esign_service {
  my ($db, $admin, $conf, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  if (!$conf->{DOCS_ESIGN}) {
    return {
      errno  => 1054017,
      errstr => 'ESIGN_SERVICE_NOT_CONNECTED'
    };
  }

  my $Docs = Docs->new($db, $admin, $conf);

  my %esign_services = (
    DOCS_DIIA_ACQUIRER_TOKEN => 'Diia',
  );

  my $ESign_Service = {};

  foreach my $config_key (sort keys %esign_services) {
    next if !$conf->{$config_key};

    my $name = $esign_services{$config_key};

    $ESign_Service = load_plugin('Docs::Plugins::' . ($name || ''), {
      SERVICE      => $Docs,
      RETURN_ERROR => 1,
      EXTRA_PARAMS => {
        debug => $debug || 0,
        %$attr
      }
    });

    next if (!$ESign_Service || (ref $ESign_Service eq 'HASH' && $ESign_Service->{errno}));

    $ESign_Service->init();

    last;
  }

  return $ESign_Service;
}

1;
