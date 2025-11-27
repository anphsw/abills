package Viber::buttons::Invoices;

use strict;
use warnings FATAL => 'all';

use Encode qw/encode_utf8/;
use Abills::Base qw/is_number json_former/;
use MIME::Base64 qw(encode_base64url decode_base64url);
use Digest::SHA qw(hmac_sha256_hex);
use Time::HiRes qw(time);

my %icons = (
  not_active => "\xE2\x9D\x8C",
  active     => "\xE2\x9C\x85",
  invoice    => "\xf0\x9f\xa7\xbe"
);

#**********************************************************
=head2 new($Botapi)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $user_config) = @_;

  my $self = {
    conf        => $conf,
    bot         => $bot,
    bot_db      => $bot_db,
    api         => $APILayer,
    user_config => $user_config
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {
  my $self = shift;

  return $self->{user_config}{docs_invoices_list};
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{invoice} $self->{bot}{lang}{INVOICES}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;
  my ($attr) = @_;

  my ($invoices) = $self->{api}->fetch_api({
    METHOD => 'GET',
    PATH   => '/user/docs/invoices/',
    PARAMS => {
      PAGE_ROWS => 5,
      # SORT      => 2,
      DESC      => 'DESC'
    }
  });

  if (!$invoices->{list}) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NOT_EXIST} });
    return 0;
  }

  my $money_currency = $self->{user_config}->{money_unit_names}->{major_unit} || '';

  my @invoices_info = ();
  my @keyboard = ();

  foreach my $invoice (@{$invoices->{list}}) {
    my $id = $invoice->{id} || '';
    my $invoice_num = $invoice->{invoice_num} || '';
    my $sum = $invoice->{total_sum} || '';
    my $date = $invoice->{date} || '';
    my $paid = $invoice->{payment_sum} ? $invoice->{payment_sum} >= $sum : 0;
    my $status = $paid ? "$icons{active} $self->{bot}{lang}{PAID}" : "$icons{not_active} $self->{bot}{lang}{UNPAID}";

    my $message = "#$invoice_num\n";
    $message .= "$self->{bot}{lang}{DATE}: $date\n";
    $message .= "$self->{bot}{lang}{SUM}: $sum $money_currency\n";
    $message .= "$self->{bot}{lang}{STATUS}: $status \n";

    my $button = {
      Columns    => 2,
      Rows       => 1,
      Text       => "$self->{bot}{lang}{DOWNLOAD} #$invoice_num",
      ActionType => 'reply',
      ActionBody => "fn:Invoices&choose_invoice&$id&$invoice_num",
      TextSize   => 'regular'
    };
    push(@keyboard, $button);

    push(@invoices_info, $message);
  }

  my $cancel_button = {
    Text       => $self->{bot}{lang}{CANCEL_TEXT},
    ActionType => 'reply',
    ActionBody => 'fn:Invoices&cancel',
    TextSize   => 'regular'
  };
  push(@keyboard, $cancel_button);

  $self->{bot}->send_message({
    text     => join("\n", @invoices_info),
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'true',
      Buttons       => \@keyboard
    },
  });

  return 1;
}

#**********************************************************
=head2 choose_faq($attr)

=cut
#**********************************************************
sub choose_invoice {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{argv}->[0]) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{NOT_EXIST} });
    return 1;
  }

  my $text = $attr->{argv}->[0];
  my $invoice_num = $attr->{argv}->[1] || $text;

  if ($text && encode_utf8($text) eq $self->{bot}{lang}{CANCEL_TEXT}) {
    $self->{bot}->send_message({ text => $self->{bot}{lang}{CANCELED} });
    return 0;
  }

  if (!is_number($text, 0, 1)) {
    return 0;
  };

  my ($user_info) = $self->{api}->fetch_api({ PATH => '/user' });

  my $protocol = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $doc_url = (defined($ENV{HTTP_HOST})) ? "$protocol://$ENV{HTTP_HOST}/api.cgi/user/docs/invoices/document/" : '';

  $doc_url ||= $self->{conf}{BILLING_URL} ? "$self->{conf}{BILLING_URL}/api.cgi/user/docs/invoices/document/" : '';

  my $token = $self->_generate_secure_download_token($user_info->{UID} || $user_info->{uid}, $text);
  $doc_url .= "?token=$token";

  my ($content) = $self->{api}->fetch_api({
    METHOD => 'GET',
    PATH   => '/user/docs/invoices/document/',
    PARAMS => {
      TOKEN => $token
    }
  });

  $self->{bot}->send_message({ type => 'file', size => length($content) || '10000', file_name => "$invoice_num.pdf", media => $doc_url });

  return 0;
}

#**********************************************************
=head2 cancel()

=cut
#**********************************************************
sub cancel {
  my $self = shift;

  $self->{bot}->send_message({ text => $self->{bot}->{lang}->{SEND_CANCEL} });

  return 0;
}

#**********************************************************
=head2 _generate_secure_download_token($uid, $file_id)

=cut
#**********************************************************
sub _generate_secure_download_token {
  my ($self, $uid, $file_id) = @_;

  my $expires = time() + 3600;
  my $payload = json_former({
    uid     => $uid,
    file_id => $file_id,
    exp     => $expires,
    nonce   => int(rand(999999999))
  });

  my $encoded_payload = encode_base64url($payload);
  my $signature = hmac_sha256_hex($encoded_payload, $self->{conf}->{secretkey});

  return "$encoded_payload.$signature";
}

1;
