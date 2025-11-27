package Storage::Api::admin::Invoices;

=head1 NAME

  Storage Invoices API

  Endpoints:
    /storage/invoices/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Storage;

my Storage $Storage;
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

  $Storage = Storage->new($db, $admin, $conf);
  $Storage->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_storage_invoices($path_params, $query_params)

=cut
#**********************************************************
sub get_storage_invoices {
  my ($self, $path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $invoices_list = $Storage->storage_invoices_list({
    %{$query_params},
    COLS_NAME => 1
  });

  return {
    list => $invoices_list,
    total => $Storage->{TOTAL}
  };
}

1;
