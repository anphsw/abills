package Api::Controllers::Admin::Info_fields;

=head1 NAME

  ADMIN API Info fields

  Endpoints:
    /info-fields/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Info_fields;

my Info_fields $Info_fields;
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

  $Errors = $self->{attr}->{Errors};
  $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
  $Info_fields->{debug} = $self->{debug};

  return $self;
}

#**********************************************************
=head2 get_info_fields_id($path_params, $query_params)

  Endpoint GET /info-fields/:id/

=cut
#**********************************************************
sub get_info_fields_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Info_fields->fields_info($path_params->{id});

  if ($Info_fields->{TYPE} && $Info_fields->{TYPE} == 2 && $Info_fields->{SQL_FIELD}) {
    my $list_items = $Info_fields->info_lists_list({ LIST_TABLE => lc $Info_fields->{SQL_FIELD} . '_list', COLS_NAME => 1 });
    $Info_fields->{LIST_ITEMS} = $Info_fields->{TOTAL} && $Info_fields->{TOTAL} > 0 ? $list_items : [];
  }

  delete @{$Info_fields}{qw/TOTAL list AFFECTED/};
  return $Info_fields;
}

#**********************************************************
=head2 get_info_fields($path_params, $query_params)

  Endpoint GET /info-fields/

=cut
#**********************************************************
sub get_info_fields {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %PARAMS = (
    COLS_NAME => 1,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    DESC      => $query_params->{DESC}
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  if ($query_params->{PARENT_ID} && $query_params->{PARENT_ID} ne '_SHOW') {
    $Info_fields->fields_info($query_params->{PARENT_ID});
    if ($Info_fields->{TOTAL} && $Info_fields->{TOTAL} > 0) {
      $query_params->{COMPANY} = $Info_fields->{COMPANY};
    }
  }

  my $list = $Info_fields->fields_list({ %$query_params, %PARAMS });
  my $total = $Info_fields->{TOTAL};

  foreach my $info_field (@{$list}) {
    next if !$info_field->{TYPE} || $info_field->{TYPE} != 2 || !$info_field->{SQL_FIELD};

    my $list_items = $Info_fields->info_lists_list({ LIST_TABLE => lc $info_field->{SQL_FIELD} . '_list', COLS_NAME => 1 });
    $info_field->{LIST_ITEMS} = $Info_fields->{TOTAL} && $Info_fields->{TOTAL} > 0 ? $list_items : [];
  }

  return {
    list  => $list,
    total => $total
  };
}

1;
