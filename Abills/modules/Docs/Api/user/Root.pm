package Docs::Api::user::Root;
=head1 NAME

  Portal articles manage

  Endpoints:
    /user/docs/*

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
=head2 get_user_docs($path_params, $query_params)

  Endpoint GET /user/docs

=cut
#**********************************************************
sub get_user_docs {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Docs->user_info($path_params->{uid});

  if ($Docs->{errno}) {
    delete @{$Docs}{qw/AFFECTED DOCS_ACCOUNT_EXPIRE_PERIOD TOTAL/};
    return $Docs;
  }
  else {
    return {
      UID               => $Docs->{UID},
      EMAIL             => $Docs->{EMAIL},
      NEXT_INVOICE_DATE => $Docs->{NEXT_INVOICE_DATE},
      INVOICING_PERIOD  => $Docs->{INVOICING_PERIOD},
    };
  }
}

#**********************************************************
=head2 get_user_docs($path_params, $query_params)

  Endpoint GET /user/docs/invoices/document/

=cut
#**********************************************************
sub get_user_docs_invoice_document {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $token = $query_params->{TOKEN};
  if (!$token) {
    return '';
  }

  my $result = $self->_validate_download_token($token);

  if (!$result) {
    return '';
  }

  ::load_module("Docs", $self->{html});
  return ::docs_invoice_print($result->{file_id}, { UID => $result->{uid}, PRINT_HEADERS => 1 });
}

#**********************************************************
=head2 _validate_download_token($uid, $file_id)

=cut
#**********************************************************
sub _validate_download_token {
  my ($self, $token) = @_;

  return if (!$self->{conf}->{secretkey});

  use MIME::Base64 qw(decode_base64url);
  use JSON qw(decode_json);
  use Digest::SHA qw(hmac_sha256_hex);
  use Time::HiRes qw(time);

  my ($encoded_payload, $signature) = split /\./, $token;
  return if (!$encoded_payload || !$signature);

  my $expected_sig = hmac_sha256_hex($encoded_payload, $self->{conf}->{secretkey});
  return if ($signature ne $expected_sig);

  my $payload_json = decode_base64url($encoded_payload);
  my $payload = eval {decode_json($payload_json)};
  return if (!$payload);

  return if (time() > $payload->{exp});

  return $payload;
}

1;
