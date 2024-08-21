package Extreceipt::Init;
=head

  Init Extreceipt Services

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';

use Abills::Loader qw(load_plugin);
use Extreceipt::db::Extreceipt;

our @EXPORT = qw(
  init_extreceipt_service
);

our @EXPORT_OK = qw(
  init_extreceipt_service
);

#**********************************************************
=head2 init_extreceipt_service($db, $admin, $conf, $attr)

  Arguments:
    $db
    $admin
    $conf
    $attr
      API_ID: number     - API ID
      API_NAME: string   - Api name - example: Checkbox
      DEBUG: number      - level of DEBUG
      SKIP_INIT: number  - skip init if needs public info
      SILENT: string     - do not print anything

  Return
    Receipts Api hash

=cut
#**********************************************************
sub init_extreceipt_service {
  my ($db, $admin, $conf, $attr) = @_;

  my $Receipt = Extreceipt->new($db, $admin, $conf);
  my $api_list = $Receipt->api_list({ API_ID => $attr->{API_ID} });
  my $debug = $attr->{DEBUG} || 0;
  my $Receipts_api = ();

  foreach my $api (@$api_list) {
    my $api_name = $api->{api_name};
    my $api_id = $api->{api_id};
    if ($attr->{API_NAME} && $attr->{API_NAME} ne $api_name) {
      next;
    }

    my $Receipt_api = load_plugin('Extreceipt::Plugins::' . ($api_name || ''), {
      SERVICE      => $Receipt,
      RETURN_ERROR => 1,
      EXTRA_PARAMS => {
        debug => $debug || 0,
        %{$api},
      }
    });

    $Receipts_api->{$api_id} = $Receipt_api;

    if (!$Receipt_api || (ref $Receipt_api eq 'HASH' && $Receipt_api->{errno})) {
      if (!$attr->{SILENT}) {
        print $Receipt_api->{errstr} || '';
      }

      next;
    }

    $Receipts_api->{$api_id}->init() if (!$attr->{SKIP_INIT});
  }

  return $Receipts_api;
}

1;
