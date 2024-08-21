package Abills::Api::Validator;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(camelize is_number in_array);

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 validate_params($attr)

  Request
    attr: object
      query_params: object  - query or request body params
      params: object        - allowed and required params in object
      parent_param?: string - used or naming nested values of objects and arrays

  Result
    validation_result: object - result of validation errors, filtered params

      if error:

        errno?: error number
        errstr?: error string
        errobj?: detailed error info

      if ok
        filtered_result

=cut
#**********************************************************
sub validate_params {
  my $self = shift;
  my ($attr) = @_;

  my %filtered_params = ();
  my @errors = ();
  $attr->{parent_param} //= '';

  foreach my $param (keys %{$attr->{query_params}}) {
    my $parameter = $attr->{query_params}->{$param};
    my $cam_param = $attr->{parent_param} . ($attr->{param} ? $attr->{param} : camelize($param));
    my $is_pattern_property = 0;

    if ($attr->{params}->{_PATTERN_PROPERTIES}) {
      foreach my $key (keys %{$attr->{params}->{_PATTERN_PROPERTIES}}) {
        next if ($param !~ /$key/g);

        my $validation_result = $self->validate_params({
          param        => lc($param),
          query_params => {
            $param => $parameter,
          },
          params       => {
            $param => $attr->{params}->{_PATTERN_PROPERTIES}->{$key}
          }
        });

        if ($validation_result->{errno}) {
          push @errors, @{$validation_result->{errors}};
        }
        else {
          $filtered_params{$param} = $parameter;
          delete $attr->{params}->{$param};
        }

        $is_pattern_property = 1;
      }

      next if ($is_pattern_property);
    }

    next if (!exists $attr->{params}->{$param});

    if (!$attr->{params}->{$param}->{type}) {
      $filtered_params{$param} = $parameter;
      delete $attr->{params}->{$param};
      next;
    }

    if ($attr->{params}->{$param}->{type} eq 'object') {
      my $error = {
        errno  => 21,
        errstr => 'ERR_PARAMETER_NOT_VALID',
        param  => $cam_param,
        type   => 'object',
      };

      if (ref $parameter ne 'HASH') {
        push @errors, $error;
        next;
      }
      elsif (!$attr->{params}->{$param}->{properties}) {
        $error->{errno} = 22;
        push @errors, $error;
        next;
      }

      my $validation_result = $self->validate_params({
        query_params => $parameter,
        params       => $attr->{params}->{$param}->{properties},
        parent_param => "$attr->{parent_param}$cam_param."
      });

      if ($validation_result->{errno}) {
        push @errors, @{$validation_result->{errors}};
      }
    }
    elsif ($attr->{params}->{$param}->{type} eq 'array') {
      my $error = {
        errno  => 21,
        errstr => 'ERR_PARAMETER_NOT_VALID',
        param  => $cam_param,
        type   => 'array',
      };

      my $items = $attr->{params}->{$param}->{items};

      if (ref $parameter ne 'ARRAY') {
        push @errors, $error;
        next;
      }
      elsif (!$items || !$items->{type} || ($items->{type} eq 'object' && !$items->{properties})) {
        $error->{errno} = 22;
        push @errors, $error;
        next;
      }

      for (my $i = 0; $i < scalar @{$parameter}; $i++) {
        my $val = $parameter->[$i];
        my $validation_result = $self->validate_params({
          parent_param => ($items->{type} eq 'object') ? "$attr->{parent_param}$cam_param\[$i]." : "$attr->{parent_param}$cam_param\[$i]",
          query_params => ($items->{type} eq 'object')
            ? $val
            :
            {
              "ARR_VAL_$i" => {
                type => $items->{type},
              },
            },
          params       => ($items->{type} eq 'object')
            ? $items->{properties}
            :
            {
              "ARR_VAL_$i" => $val || ''
            },
        });

        if ($validation_result->{errno}) {
          push @errors, @{$validation_result->{errors}};
        }
      }
    }
    elsif (
        ($attr->{params}->{$param}->{type} eq 'datetime' && $parameter !~ /^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/) ||
        ($attr->{params}->{$param}->{type} eq 'date' && $parameter !~ /^\d{4}-\d{2}-\d{2}$/) ||
        ($attr->{params}->{$param}->{type} eq 'unsigned_integer' && $parameter !~ /^(0|[1-9]\d*)$/) ||
        ($attr->{params}->{$param}->{type} eq 'integer' && $parameter !~ /^-?(0|[1-9]\d*)$/) ||
        ($attr->{params}->{$param}->{type} eq 'unsigned_number' && !is_number($parameter)) ||
        ($attr->{params}->{$param}->{type} eq 'number' && !is_number($parameter, 0, 1)) ||
        ($attr->{params}->{$param}->{type} eq 'bool_number' && !in_array($parameter, [1, 0]))
      ) {
      push @errors, {
        errno  => 21,
        errstr => 'ERR_PARAMETER_NOT_VALID',
        param  => $cam_param,
        type   => $attr->{params}->{$param}->{type}
      };
    }
    elsif ($attr->{params}->{$param}->{type} eq 'enum' && (!$attr->{params}->{$param}->{values} || !in_array($parameter, $attr->{params}->{$param}->{values}))) {
      push @errors, {
        errno          => 21,
        errstr         => 'ERR_PARAMETER_NOT_VALID',
        param          => $cam_param,
        type           => $attr->{params}->{$param}->{value_type} || 'string',
        allowed_params => $attr->{params}->{$param}->{values},
        desc_params    => $attr->{params}->{$param}->{values_desc} || {},
      };
    }
    elsif ($attr->{params}->{$param}->{type} eq 'string') {
      my $min_length = $attr->{params}->{$param}->{min_length} || 0;
      my $max_length = $attr->{params}->{$param}->{max_length};
      my $is_error = 0;

      my $error = {
        errno  => 21,
        errstr => 'ERR_PARAMETER_NOT_VALID',
        param  => $cam_param,
        type   => 'string',
      };

      $error->{min_length} = $min_length if ($min_length);
      $error->{regex_pattern} = $attr->{params}->{$param}->{regex} if ($attr->{params}->{$param}->{regex});

      if (ref $parameter ne '') {
        push @errors, $error;
        next;
      }

      my $param_length = 0;
      my $is_utf = Encode::is_utf8($parameter);

      if ($is_utf) {
        $param_length = length($parameter) || 0;
      }
      else {
        my $copy = $parameter;
        Encode::_utf8_on($copy);
        $param_length = length($copy) || 0;
      }

      if (($min_length > $param_length) || ($max_length && $max_length < $param_length)) {
        if ($max_length) {
          $error->{max_length} = $max_length;
          $is_error = 1;
        }
      }

      if ($attr->{params}->{$param}->{regex} && $parameter !~ /$attr->{params}->{$param}->{regex}/g) {
        $is_error = 1;
      }

      push @errors, $error if ($is_error);
    }
    elsif ($attr->{params}->{$param}->{type} eq 'custom') {
      my $result = $attr->{params}->{$param}->{function}->($self, $parameter);
      if (ref $result eq 'HASH' && !$result->{result}) {
        delete $result->{result};
        push @errors, {
          errno  => 21,
          errstr => 'ERR_PARAMETER_NOT_VALID',
          param  => $cam_param,
          %$result
        };
      }
    }

    $filtered_params{$param} = $parameter;
    delete $attr->{params}->{$param};
  }

  foreach my $param (sort keys %{$attr->{params}}) {
    my $cam_param = camelize($param);
    if ($attr->{params}->{$param}->{required}) {
      push @errors, {
        errno    => 20,
        errstr   => 'ERR_REQUIRED_PARAMETER',
        param    => $cam_param,
        required => 'true'
      };
    }
    elsif (defined $attr->{params}->{$param}->{default}) {
      $filtered_params{$param} = $attr->{params}->{$param}->{default};
    }
  }

  if (scalar @errors) {
    return {
      errno  => 9,
      errstr => 'VALIDATION_FAILED',
      errors => \@errors
    };
  }
  else {
    return \%filtered_params;
  }
}

1;
