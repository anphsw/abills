package Docs::Api::common::Invoices;
=head1 NAME

  Docs Invoices common functions for admin and user API

  For Endpoints:
    /docs/invoices/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(days_in_month);
use Control::Errors;
use Abills::Api::FieldsGrouper;

use Docs;
use Docs::Utils qw(next_payment_period);

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
  };

  bless($self, $class);

  $Docs = Docs->new($db, $admin, $conf);
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 docs_invoices_period($attr)

  ARGS:
    UID
    NEXT_PERIOD
    NEW_INVOICES
    USER_API_CALL

=cut
#**********************************************************
sub docs_invoices_period {
  my $self = shift;
  my ($attr) = @_;

  require POSIX;
  POSIX->import(qw/mktime strftime/);
  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  require Fees;
  Fees->import();
  my $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->info($attr->{UID});
  my $service_activate = $Users->{ACTIVATE} || '0000-00-00';

  $Docs->user_info($Users->{UID});
  if ($Docs->{TOTAL}) {
    if (!defined($attr->{NEXT_PERIOD})) {
      $attr->{NEXT_PERIOD} = 0;
    }
    $service_activate = $Docs->{INVOICE_DATE};
  }

  my $date = $main::DATE;
  if ($service_activate ne '0000-00-00') {
    $date = $service_activate;
  }

  my ($Y, $M, $D) = split(/-/, $date);
  my ($num, $service_info) = (0, 0, 0, 0, '');

  my %current_invoice = ();
  $Docs->invoices_list({
    UID         => $Users->{UID},
    ORDERS_LIST => 1,
    COLS_NAME   => 1,
    PAGE_ROWS   => 1000
  });

  foreach my $doc_id (keys %{$Docs->{ORDERS}}) {
    foreach my $invoice (@{$Docs->{ORDERS}->{$doc_id}}) {
      $current_invoice{$invoice->{orders}} = $invoice->{invoice_id};
    }
  }

  my %fees_tax = ();
  my $fees_type_list = $Fees->fees_type_list({
    COLS_NAME => 1,
    TAX       => '_SHOW',
    PAGE_ROWS => 10000
  });

  foreach my $line (@$fees_type_list) {
    $fees_tax{$line->{id}} = $line->{tax} if ($line->{tax});
  }

  my $new_invoices;
  if ($attr->{NEW_INVOICES}) {
    my $new_invoices_res = $self->_docs_invoices_new($attr, $Users, $num, \%fees_tax, \%current_invoice);
    $num = $new_invoices->{num};
    $new_invoices = $new_invoices_res->{new_invoices};
  }

  my $start_period_unixtime;
  my $TO_D;
  if ($service_activate ne '0000-00-00') {
    $start_period_unixtime = (POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0));
    $Docs->{CURENT_BILLING_PERIOD_START} = $service_activate;
    $Docs->{CURENT_BILLING_PERIOD_STOP} = POSIX::strftime("%Y-%m-%d",
      localtime((POSIX::mktime(0, 0, 0, $D, ($M - 1), ($Y - 1900), 0, 0, 0) + 30 * 86400)));
  }
  else {
    $D = '01';
    $Docs->{CURENT_BILLING_PERIOD_START} = "$Y-$M-$D";
    $TO_D = days_in_month({ DATE => "$Y-$M-$D" });
    $Docs->{CURENT_BILLING_PERIOD_STOP} = "$Y-$M-$TO_D";
  }

  my $service_orders;
  if ($attr->{NEXT_PERIOD}) {
    my $new_invoices_res = $self->_docs_invoices_next_period($attr, $Users, $num, $service_activate, $date, \%fees_tax, \%current_invoice);
    ($num, $service_orders, $service_info) = @{$new_invoices_res}{qw/num service_orders service_info/};
  }

  my %return_params = (
    TOTAL          => $num,
    SERVICE_ORDERS => $service_orders,
  );

  if ($attr->{EXTRA_INFO}) {
    my $_Docs = { %$Docs };
    delete $_Docs->{list};
    delete $_Docs->{AFFECTED};
    $_Docs = Abills::Api::FieldsGrouper::group_fields($_Docs);

    $return_params{DOC_INFO} = $_Docs;
    $return_params{SERVICE_INFO} = $service_info;
  }

  if ($attr->{NEW_INVOICES}) {
    $return_params{NEW_INVOICES} = $new_invoices;
  }

  return \%return_params;
}

#**********************************************************
=head2 _docs_invoices_next_period($attr, $Users, $num, $service_activate, $date, $fees_tax, $current_invoice)

=cut
#**********************************************************
sub _docs_invoices_next_period {
  my $self = shift;
  my ($attr, $Users, $num, $service_activate, $date, $fees_tax, $current_invoice) = @_;

  my %service_orders = ();

  my ($from_date, $to_date) = next_payment_period({
    PERIOD => $attr->{NEXT_PERIOD},
    DATE   => $date
  });

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Control/Services.pm'}));

  my $service_info = ::get_services($Users, {
    ACTIVE_ONLY => 1
  });

  foreach my $service (@{$service_info->{list}}) {
    my $sum = sprintf("%.2f", $service->{SUM} || 0);
    my $fees_type = 0;
    my $module = $service->{MODULE};
    my $activate = $service->{ACTIVATE};
    my $describe = $service->{SERVICE_DESC} || q{};
    next if ($sum < 0);

    my $module_service_activate = $service_activate;

    if ($activate && $activate ne '0000-00-00') {
      $module_service_activate = $activate;
      $from_date = $module_service_activate;
    }
    else {
      $from_date = $main::DATE || '0000-00-00';
      $from_date =~ s/\d+$/01/;
    }

    for (my $i = ($attr->{NEXT_PERIOD} == -1) ? -2 : 0; $i < int($attr->{NEXT_PERIOD}); $i++) {
      my $result_sum = sprintf("%.2f", $sum);

      ($from_date, $to_date) = next_payment_period({
        DATE => $from_date
      });

      my $order = "$service->{SERVICE_NAME} $describe($from_date-$to_date)";

      if (!$current_invoice->{$order}) {
        $num++;
      }
      else {
        next if ($attr->{USER_API_CALL});
      }
      my $tax_sum = 0;

      if ($fees_type && $fees_tax->{$fees_type}) {
        $tax_sum = $result_sum / 100 * $fees_tax->{$fees_type};
      }

      $service_orders{$module}{$num} = {
        date            => $from_date,
        login           => $Users->{LOGIN},
        result_sum      => $result_sum,
        tax_sum         => ($tax_sum) ? sprintf("%.2f", $tax_sum) : 0,
        current_invoice => $current_invoice->{$order} ? 1 : 0,
        order           => $order,
        fees_type       => $fees_type,
        num             => $num
      };
    }
  }

  return {
    num            => $num,
    service_orders => \%service_orders,
    service_info   => $service_info
  }
}

#**********************************************************
=head2 _docs_invoices_new($attr, $Users, $num, $fees_tax, $current_invoice)

=cut
#**********************************************************
sub _docs_invoices_new {
  my $self = shift;
  my ($attr, $Users, $num, $fees_tax, $current_invoice) = @_;

  my @new_invoices = ();

  my $invoice_new_list = $Docs->invoice_new({
    FROM_DATE => '0000-00-00',
    TO_DATE   => $attr->{TO_DATE} || $main::DATE,
    PAGE_ROWS => 500,
    UID       => $Users->{UID},
    TAX       => '_SHOW',
    COLS_NAME => 1
  });

  foreach my $line (@$invoice_new_list) {
    next if ($line->{fees_id});
    $num++;
    my $Date = $line->{date} || q{};
    $Date =~ s/ \d+:\d+:\d+//g;

    if ($line->{dsc} && !$current_invoice->{$line->{dsc}}) {
      push @new_invoices, {
        tax   => ($line->{tax} && $fees_tax->{$line->{tax}}) ? $fees_tax->{$line->{tax}} : 0,
        dsc   => ($line->{dsc} || q{}) . " $Date",
        date  => $line->{date},
        login => $line->{login},
        sum   => $line->{sum},
        id    => $line->{id},
        num   => $num
      };
    }
  }

  return {
    new_invoices => \@new_invoices,
    num          => $num,
  };
}

#**********************************************************
=head2 docs_invoices_add($attr)

=cut
#**********************************************************
sub docs_invoices_add {
  my $self = shift;
  my ($attr) = @_;

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->info($attr->{UID});

  $attr->{CUSTOMER} //= '';
  if ($attr->{VAT} && $attr->{VAT} == 1) {
    $attr->{VAT} = $self->{conf}->{DOCS_VAT_INCLUDE};
  }

  $attr->{DOCS_CURRENCY} = $attr->{CURRENCY};

  if (($self->{conf}->{SYSTEM_CURRENCY} && $self->{conf}->{DOCS_CURRENCY})
    && $self->{conf}->{SYSTEM_CURRENCY} ne $self->{conf}->{DOCS_CURRENCY}) {
    require Finance;
    Finance->import();
    my $Finance = Finance->new($self->{db}, $self->{admin}, $self->{conf});
    $Finance->exchange_info(0, { ISO => $attr->{DOCS_CURRENCY} || $self->{conf}->{DOCS_CURRENCY} });
    $attr->{EXCHANGE_RATE} = $Finance->{ER_RATE};
    $attr->{DOCS_CURRENCY} = $Finance->{ISO};
  }

  $Docs->invoice_add({
    %$attr,
    DEPOSIT => ($attr->{INCLUDE_DEPOSIT}) ? $Users->{DEPOSIT} : 0,
    DATE    => $attr->{DATE} || $main::DATE,
    UID     => $Users->{UID}
  });

  if ($Docs->{errno} && $Docs->{errno} == 2) {
    return $Errors->throw_error(1054022);
  }
  elsif ($Docs->{errno}) {
    return {
      errno  => $Docs->{errno},
      errstr => $Docs->{errstr}
    };
  }

  if ($Users->{REGISTRATION}) {
    my ($Y, $M) = split(/-/, $main::DATE, 3);
    $Docs->user_change({
      UID          => $Users->{UID},
      INVOICE_DATE => ($Users->{ACTIVATE} ne '0000-00-00') ? $main::DATE : "$Y-$M-01",
      CHANGE_DATE  => 1
    });
    delete($Docs->{errno});
  }

  $Docs->invoice_info($Docs->{DOC_ID}, { UID => $Users->{UID}, COLS_NAME => $attr->{ORDERS_AS_ARRAY} ? 0 : 1 });

  $Docs->{CUSTOMER} ||= $Docs->{COMPANY_NAME} || $Docs->{FIO} || '-';
  delete $Docs->{list};

  return $Docs;
}

1;
