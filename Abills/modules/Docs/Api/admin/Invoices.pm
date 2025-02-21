package Docs::Api::admin::Invoices;
=head1 NAME

  Docs invoices manage

  Endpoints:
    /docs/invoices/*

=cut
use strict;
use warnings FATAL => 'all';

use Abills::Base;
use Control::Errors;
use Docs;
use Payments;

my Docs $Docs;
my Control::Errors $Errors;
my Payments $Payments;

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
  $Payments = Payments->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_docs_invoices($path_params, $query_params)

  Endpoint GET /docs/invoices/

=cut
#**********************************************************
sub get_docs_invoices {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} //= '';
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $list = $Docs->invoices_list({
    ID           => '_SHOW',
    UID          => '_SHOW',
    CREATED      => '_SHOW',
    DOC_ID       => '_SHOW',
    DOCS_DEPOSIT => '_SHOW',
    SUM          => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  return {
    list   => $list,
    total  => $Docs->{TOTAL},
    orders => $Docs->{ORDERS},
  };
}

#**********************************************************
=head2 post_docs_invoices($path_params, $query_params)

  Endpoint POST /docs/invoices/:uid/

=cut
#**********************************************************
sub post_docs_invoices {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  #TODO: delete when will be added validations
  if (!$query_params->{UID}) {
    return $Errors->throw_error(1054021);
  }

  require Docs::Api::common::Invoices;
  Docs::Api::common::Invoices->import();
  my $Invoices = Docs::Api::common::Invoices->new($self->{db}, $self->{admin}, $self->{conf}, {Errors => $Errors});

  $query_params->{DATE} //= $main::DATE;

  if ($query_params->{ORDERS} && ref $query_params->{ORDERS} eq 'ARRAY') {
    my $num = 0;
    $query_params->{IDS}='';
    foreach my $order (@{$query_params->{ORDERS}}) {
      $num++;
      $query_params->{"ORDER_" . $num} = $order->{order};
      $query_params->{"FEES_TYPE_" . $num} = $order->{fees_type};
      $query_params->{"SUM_" . $num} = $order->{sum};
      $query_params->{"COUNTS_" . $num} = $order->{count};
      $query_params->{"UNIT_" . $num} = $order->{unit};
      $query_params->{IDS} .= "$num, ";
    }
  }

  return $Invoices->docs_invoices_add($query_params);
}

#**********************************************************
=head2 get_docs_invoices_id($path_params, $query_params)

  Endpoint GET /docs/invoices/:id/

=cut
#**********************************************************
sub get_docs_invoices_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $info = $Docs->invoice_info($path_params->{id}, {
    COLS_NAME => $query_params->{ORDERS_AS_ARRAY} ? 0 : 1
  });

  delete $info->{list};
  return $info;
}

#**********************************************************
=head2 put_docs_invoices_id($path_params, $query_params)

  Endpoint PUT /docs/invoices/:id/

=cut
#**********************************************************
sub put_docs_invoices_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Docs->invoice_change({
    %$query_params,
    ID => $path_params->{id},
  });
}

#**********************************************************
=head2 delete_docs_invoices($path_params, $query_params)

  Endpoint DELETE /docs/invoices/

=cut
#**********************************************************
sub delete_docs_invoices {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$query_params->{IDS} && !$query_params->{ID}) {
    return $Errors->throw_error(1054013);
  }

  my $ids = $query_params->{IDS} || $query_params->{ID};

  my $errors = 0;
  my @invoices = split('\s?,\s?', $ids);
  my @results = ();

  foreach my $invoice (@invoices) {
    $Docs->invoice_del($invoice);

    if ($Docs->{errno}) {
      push @results, {
        id     => $invoice,
        errno  => $Docs->{errno} || 0,
        errstr => $Docs->{errstr} || '',
      };

      $errors++;
      delete @{$Docs}{qw/errno errstr/};
    }
    else {
      push @results, {
        id     => $invoice,
        result => 'OK',
      };
    }
  }

  return {
    result  => 'OK',
    results => \@results,
    errors  => $errors
  };
}

#**********************************************************
=head2 get_docs_invoices($path_params, $query_params)

  Endpoint GET /docs/invoices/:uid/period/

=cut
#**********************************************************
sub get_docs_invoices_period {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Docs::Api::common::Invoices;
  Docs::Api::common::Invoices->import();
  my $Invoices = Docs::Api::common::Invoices->new($self->{db}, $self->{admin}, $self->{conf}, {Errors => $Errors});

  return $Invoices->docs_invoices_period({
    %$query_params,
    UID => $path_params->{uid}
  });
}

#**********************************************************
=head2 get_docs_invoices_payments($path_params, $query_params)

  Endpoint GET /docs/invoices/payments/

=cut
#**********************************************************
sub get_docs_invoices_payments {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $list = $Docs->invoices2payments_list({
    UID        => '_SHOW',
    INVOICE_ID => '_SHOW',
    PAYMENT_ID => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  return {
    list   => $list,
    total  => $Docs->{TOTAL},
  };
}

#**********************************************************
=head2 post_docs_invoices_payments($path_params, $query_params)

  Endpoint POST /docs/invoices/payments/

=cut
#**********************************************************
sub post_docs_invoices_payments {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $ids = $query_params->{IDS};

  my $total_sum = 0;
  my $total_count = 0;
  my $skip_count = 0;
  my @payments = ();

  $ids =~ s/, /;/g;
  my $list = $Docs->invoices_list({
    ID        => $ids,
    UID       => '_SHOW',
    BILL_ID   => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 1000000
  });

  foreach my $line (@{$list}) {
    if ($line->{payment_sum}) {
      $skip_count++;
      next;
    }

    $Payments->add(
      # user info object
      {
        UID     => $line->{uid},
        BILL_ID => $line->{bill_id},
      },
      # payment attr
      {
        METHOD => $query_params->{METHOD} || 0,
        SUM => $line->{total_sum}
      }
    );

    $Docs->invoices2payments({
      PAYMENT_ID => $Payments->{INSERT_ID},
      INVOICE_ID => $line->{id},
      SUM        => $line->{total_sum}
    });

    $total_sum += $line->{total_sum};
    $total_count++;

    push @payments, {
      id  => $Payments->{INSERT_ID},
      sum => $line->{total_sum},
      uid => $line->{uid},
    }
  }

  return {
    skip_count  => $skip_count,
    total_count => $total_count,
    total_sum   => sprintf("%.2f", $total_sum),
    payments    => \@payments,
  };
}

#**********************************************************
=head2 patch_docs_invoices_payments($path_params, $query_params)

  Endpoint PATCH /docs/invoices/payments/

=cut
#**********************************************************
sub patch_docs_invoices_payments {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{INVOICE_CREATE} && $query_params->{INVOICE_ID}) {
    return $Errors->throw_error(1054016);
  }
  elsif (!$query_params->{INVOICE_CREATE} && !$query_params->{INVOICE_ID}) {
    return $Errors->throw_error(1054017);
  }

  my $payment_list = $Payments->list({
    ID        => $query_params->{PAYMENT_ID} || -1,
    SUM       => '_SHOW',
    UID       => '_SHOW',
    COLS_NAME => 1
  });

  if (!$Payments->{TOTAL} || $Payments->{TOTAL} < 0) {
    return $Errors->throw_error(1054014);
  }

  if ($query_params->{SUM} > $payment_list->[0]{sum}) {
    return $Errors->throw_error(1054015);
  }

  $query_params->{UID} = $payment_list->[0]{uid};

  if ($query_params->{INVOICE_CREATE}) {
    $Docs->invoice_add({
      SUM => $query_params->{SUM},
      UID => $payment_list->[0]{uid},
    });

    $query_params->{INVOICE_ID} = $Docs->{INSERT_ID};
  }

  require Docs::Base;
  Docs::Base->import();
  my $Docs_base = Docs::Base->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

  $Docs_base->docs_payments_maked({ %$query_params, FORM => $query_params });

  return {
    result     => 'ok',
    invoice_id => $query_params->{INVOICE_ID},
    payment_id => $query_params->{PAYMENT_ID},
    sum        => $query_params->{SUM},
  };
}

1;
