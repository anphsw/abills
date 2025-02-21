package Viber::buttons::Invoices;

use strict;
use warnings FATAL => 'all';

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
    $message .= "$self->{bot}{lang}{PRINT}: $self->{conf}{BILLING_URL}/index.cgi?get_index=docs_invoices_list&print=$id&pdf=1 \n";

    push(@invoices_info, $message);
  }

  $self->{bot}->send_message({ text => join("\n", @invoices_info) });

  return 0;
}

1;
