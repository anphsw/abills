package Paysys::Api::admin::Merchants;

=head1 NAME

  Admin Paysys merchants paths

  Endpoints:
    /paysys/merchants/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(mk_unique_value);
use Abills::Fetcher qw(web_request);
use Control::Errors;
use Paysys;
use Paysys::Init;

my Paysys $Paysys;
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

  $Paysys = Paysys->new($db, $admin, $conf);
  $Paysys->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_paysys_merchants($path_params, $query_params)

  Endpoint GET /paysys/merchants/

=cut
#**********************************************************
sub get_paysys_merchants {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Paysys->merchant_settings_list({
    %$query_params,
    ID             => '_SHOW',
    MERCHANT_NAME  => '_SHOW',
    SYSTEM_ID      => '_SHOW',
    PAYSYSTEM_NAME => '_SHOW',
    MODULE         => '_SHOW',
    DOMAIN_ID      => '_SHOW',
    COLS_NAME      => $query_params->{LIST2HASH} ? 0 : 1,
  });
}

#**********************************************************
=head2 get_paysys_merchants_tooltips($path_params, $query_params)

  Endpoint GET /paysys/systems/:id/merchants/tooltips/

=cut
#**********************************************************
sub get_paysys_merchants_tooltips {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $payment_system_info = $Paysys->paysys_connect_system_info({
    ID               => $path_params->{id},
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1
  });

  my $Pasysy_plugin = _configure_load_payment_module($payment_system_info->{module}, 1, $self->{conf});
  if (!$Pasysy_plugin->can('get_settings')) {
    return $Errors->throw_error(1170107);
  }

  my $Module = $Pasysy_plugin->new($self->{db}, $self->{admin}, $self->{conf});
  my %settings = $Module->get_settings();

  return $Errors->throw_error(1170120) if (!$settings{DOCS});

  my $is_page_id = $settings{DOCS} =~ /pageId/;
  my ($match) = $settings{DOCS} =~ /([a-zA-Z0-9_\-\+]+)$/;

  return $Errors->throw_error(1170121) if (!$match);

  my $url;
  if ($is_page_id) {
    $url = "http://abills.net.ua/wiki/rest/api/content/$match?expand=body.storage";
  }
  else {
    $url = "http://abills.net.ua/wiki/rest/api/content/search?cql=space=AB AND title=$match&expand=body.storage";
  }

  my $res = web_request($url, {
    INSECURE    => 1,
    JSON_RETURN => 1,
    CURL        => 1
  });

  return $Errors->throw_error(1170122) if ($res->{errno} || !$res->{size});

  my $body;
  if ($is_page_id) {
    $body = $res->{body}->{storage}->{value};
  }
  else {
    $body = $res->{results}->[0]->{body}->{storage}->{value};
  }

  my @tooltips = ();
  my @values = $body =~ /<td[^>]*>(.*?)<\/td>/g;

  for (my $i = 0; $i < @values - 1; $i++) {
    my $tooltip_name = $values[$i];

    next if ($tooltip_name !~ /PAYSYS_/);

    $tooltip_name =~ s/<[^>]*>//g;

    my $tooltip_value = $values[$i + 1];
    $tooltip_value =~ s/<[^>]*>//g;

    push @tooltips, {
      name  => $tooltip_name,
      value => $tooltip_value
    };
  }

  return {
    total => scalar @tooltips,
    list  => \@tooltips,
  };
}

1;
