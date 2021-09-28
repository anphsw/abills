package Extreceipt::Base;
use strict;
use warnings FATAL => 'all';

use parent 'Exporter';

our $VERSION = 0.01;

our @EXPORT = qw(
  receipt_init
);

our @EXPORT_OK = qw(
  receipt_init
);


#**********************************************************
=head2 receipt_init($attr)

  Arguments:
    $Receipts
    $attr
      API
      AID - Admin ID
      API_NAME -
      DEBUG -

  Resturn
    $Receipt_apies

=cut
#**********************************************************
sub receipt_init {
  my $Receipt = shift;
  my ($attr) = @_;

  my $api_list = $Receipt->api_list();
  my $debug = $attr->{DEBUG} || 0;
  my $Receipt_api = ();
  foreach my $api (@$api_list) {
    my $api_name = $api->{api_name};
    my $api_id = $api->{api_id};
    if ($attr->{API_NAME} && $attr->{API_NAME} ne $api_name) {
      next;
    }

    if (eval {
      require "Extreceipt/API/$api_name.pm";
      1;
    }) {
      $Receipt_api->{$api_id} = $api_name->new($Receipt->{conf}, $api);
      $Receipt_api->{$api_id}->{debug} = 1 if ($debug);
      if (!$Receipt_api->{$api_id}->init()) {
        $Receipt_api->{$api_id} = ();
      }
    }
    else {
      print $@;
      $Receipt_api->{$api_id} = ();
    }
  }

  return $Receipt_api;
}

1;