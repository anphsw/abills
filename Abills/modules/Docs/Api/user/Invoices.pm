package Docs::Api::user::Invoices;
=head1 NAME

  Docs invoices

  Endpoints:
    /user/docs/invoices/*

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
=head2 get_user_docs_invoices($path_params, $query_params)

  Endpoint GET /user/docs/invoices/

=cut
#**********************************************************
sub get_user_docs_invoices {
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
    ID             => '_SHOW',
    DOC_ID         => '_SHOW',
    DOCS_DEPOSIT   => '_SHOW',
    SUM            => '_SHOW',
    CUSTOMER       => '_SHOW',
    FEES_ID        => '_SHOW',
    TYPE_FEES      => '_SHOW',
    EXCHANGE_RATE  => '_SHOW',
    ALT_SUM        => '_SHOW',
    CREATED        => '_SHOW',
    PAYMENT_METHOD => '_SHOW',
    PAYMENT_ID     => '_SHOW',
    DOC_ID         => '_SHOW',
    EXT_ID         => '_SHOW',
    UID            => $path_params->{uid},
    %PARAMS,
  });

  return {
    list   => $list,
    total  => $Docs->{TOTAL},
  };
}

#**********************************************************
=head2 get_user_docs_invoices_id($path_params, $query_params)

  Endpoint GET /user/docs/invoices/:id/

=cut
#**********************************************************
sub get_user_docs_invoices_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $info = $Docs->invoice_info($path_params->{id}, {
    UID       => $path_params->{uid},
    COLS_NAME => $query_params->{ORDERS_AS_ARRAY} ? 0 : 1
  });

  delete $info->{list};
  return $info;
}

#**********************************************************
=head2 post_user_docs_invoices_period($path_params, $query_params)

  Endpoint POST /user/docs/invoices/period

=cut
#**********************************************************
sub post_user_docs_invoices {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Docs::Api::common::Invoices;
  Docs::Api::common::Invoices->import();
  my $Invoices = Docs::Api::common::Invoices->new($self->{db}, $self->{admin}, $self->{conf}, {Errors => $Errors});

  my %add_params = ();

  if (!$query_params->{NEXT_PERIOD} && !$query_params->{IDS}) {
    $add_params{DATE} = $main::DATE;
  }
  else {
    my $invoices = $Invoices->docs_invoices_period({
      NEXT_PERIOD   => 1,
      UID           => $path_params->{uid},
      USER_API_CALL => 1,
    });

    return $invoices if ($invoices->{errno});

    if (!$invoices->{TOTAL}) {
      return $Errors->throw_error(1054015);
    }

    $add_params{ISD} = '';
    my $num = 0;

    my $service_orders = $invoices->{SERVICE_ORDERS};
    foreach my $module (keys %$service_orders) {
      foreach my $doc_id (keys %{$service_orders->{$module}}) {
        $num++;
        my $invoice_info = $service_orders->{$module}->{$doc_id};

        $add_params{"ORDER_" . $num} = $invoice_info->{order};
        $add_params{"FEES_TYPE_" . $num} = $invoice_info->{fees_type};
        $add_params{"SUM_" . $num} = $invoice_info->{result_sum};
        $add_params{IDS} .= "$num, ";
      }
    }
  }

  $add_params{UID} = $path_params->{uid};

  return $Invoices->docs_invoices_add({
    %$query_params,
    %add_params
  });
}

#**********************************************************
=head2 get_user_docs_invoices_period($path_params, $query_params)

  Endpoint GET /user/docs/invoices/period/

=cut
#**********************************************************
sub get_user_docs_invoices_period {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Docs::Api::common::Invoices;
  Docs::Api::common::Invoices->import();
  my $Invoices = Docs::Api::common::Invoices->new($self->{db}, $self->{admin}, $self->{conf}, {Errors => $Errors});

  my $invoices = $Invoices->docs_invoices_period({
    NEXT_PERIOD   => 1,
    UID           => $path_params->{uid},
    USER_API_CALL => 1,
  });

  return $Errors->throw_error(1054019) if (!$invoices->{TOTAL});

  return $invoices;
}

1;
