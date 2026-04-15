package Abills::Api::FieldsGrouper;

use warnings FATAL => 'all';
use strict;

#***********************************************************
=head2 group_fields($result)

  Arguments:
    $result
  Results:
    $result

=cut
#***********************************************************
sub group_fields {
  my ($result) = @_;

  if (ref $result eq 'ARRAY') {
    foreach (@$result) {
      $_ = group($_)
    }
  }
  else {
    $result = group($result)
  }

  return $result;
}

#***********************************************************
=head2 group($result)

  Arguments:
    $attr
  Results:
    $self

=cut
#***********************************************************
sub group {
  my ($result) = @_;

  my @del_fields_array = (
    '',
    'COL_NAMES_ARR',
    'COL_TYPES_ARR',
    'db',
    'admin',
    'conf',
    'lang',
    'modules',
    'debug',
    'Conf',
    'CONF',
    'Admin',
    'ADMIN',
    'LANG',
    'MODULES',
    'SEARCH_FIELDS',
    'EXTRA_FIELDS',
    'EXT_TABLES',
    'SEARCH_FIELDS_COUNT',
    'SEARCH_VALUES',
    'SEARCH_FIELDS_ARR',
    'sql_errstr',
    'sql_errno',
    'sql_query',
  );

  if (ref $result eq 'HASH' && ($result->{sql_errstr} || $result->{sql_errno})) {
    push @del_fields_array, 'list';
  }

  if (ref $result eq 'HASH') {
    foreach my $field_name (keys %$result) {
      if ($field_name =~ m/(.*)_(\d*)$/xgm) {
        delete $result->{$field_name};
      }
      else {
        foreach my $field (@del_fields_array) {
          delete $result->{$field_name} if ($field_name eq $field)
        }
      }

      if ($field_name =~ m/(.*)_ALL$/xgm) {
        my $old_field_name = $field_name;
        $field_name =~ s/_ALL$//xgm;

        my @list = split(', ', $result->{$old_field_name});
        $result->{$field_name} = \@list;
        delete $result->{$old_field_name};
      }
    }
  }

  return $result;
}

1;
