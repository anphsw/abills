package Abills::Api::Router;

use strict;
use warnings FATAL => 'all';

use JSON;

use Abills::Base qw(escape_for_sql in_array decamelize);
use Abills::Api::Validator;
use Abills::Api::Paths;

#**********************************************************
=head2 new($url, $db, $user, $admin, $conf, $query_params)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db             => $db,
    admin          => $admin,
    conf           => $conf,
    lang           => $attr->{lang},
    modules        => $attr->{modules},
    html           => $attr->{html},
    debug          => ($attr->{debug} || 0),
    request_method => $attr->{request_method} || 'GET',
    direct         => $attr->{direct} || 0,
    libpath        => $attr->{libpath} || ''
  };

  bless($self, $class);

  $self->preprocess($attr->{url}, $attr->{query_params});

  return $self;
}

#**********************************************************
=head2 preprocess($url, $query_params) - preprocess request

  Gets params from request. Sets $self attrs

  Arguments:
    $url          - part of URL that goes after "api.cgi/" (name of API route)
    $query_params - query params. \%FORM variable goes here

  Returns:
    $self

=cut
#**********************************************************
sub preprocess {
  my $self = shift;
  my ($url, $query_params) = @_;

  if (!in_array($self->{request_method}, [ 'GET', 'POST', 'PATCH', 'PUT', 'DELETE' ])) {
    $self->{result} = {
      errno   => 25,
      errstr  => 'Method not allowed',
      methods => [ 'GET', 'POST', 'PATCH', 'PUT', 'DELETE' ],
    };
    $self->{status} = 405;

    return $self;
  }

  $url =~ s/\?.+//g;
  my @params = split('/', $url);
  my $resource_name = $params[1] || q{};

  my $resource_name_user_api = q{};
  if ($params[2] && $params[2] =~ /\d+/) {
    $resource_name_user_api = $params[3] || q{};
  }
  else {
    $resource_name_user_api = $params[2] || q{};
  }

  my $Paths = Abills::Api::Paths->new($self->{db}, $self->{admin}, $self->{conf}, $self->{lang}, $self->{html}, {
    libpath => $self->{libpath}
  });

  if ($self->{direct}) {
    $self->{query_params} = $query_params;
  }
  elsif (in_array($self->{request_method}, [ 'GET', 'DELETE' ])) {
    $self->{query_params} = $query_params;
  }
  elsif ($ENV{CONTENT_TYPE} && $ENV{CONTENT_TYPE} =~ 'multipart/form-data') {
    $self->{query_params} = $query_params;
  }
  elsif ($query_params->{__BUFFER}) {
    my $q_params = eval {decode_json($query_params->{__BUFFER})};

    if ($@) {
      $self->{result} = {
        errno  => 1,
        errstr => 'There was an error parsing the body'
      };
      $self->{status} = 400;
      $self->{error_msg} = $@;

      return $self;
    }
    else {
      if (ref $q_params ne 'HASH') {
        $self->{result} = {
          errno  => 6,
          errstr => 'Wrong request type. Please check of request type body.',
        };
        $self->{status} = 400;
        return $self;
      }
      $self->{query_params} = escape_for_sql($q_params);
    }
  }
  else {
    $self->{query_params} = undef;
  }

  if ($self->{query_params}->{__BUFFER}) {
    delete $self->{query_params}->{__BUFFER};
  }

  #TODO: if in future one Router object will be used for multiple queries, move this to new()
  if ($resource_name eq 'user') {
    $self->{resource_own} = $Paths->load_own_resource_info({
      package => $resource_name_user_api,
      debug   => $self->{debug},
      type    => 'user',
    });

    if (!$self->{resource_own}) {
      $self->{resource_own} = $Paths->load_own_resource_info({
        package => 'User_core',
        debug   => $self->{debug},
        type    => 'user',
      });
    }
  }
  elsif ($resource_name ne 'user') {
    $self->{resource_own} = $Paths->load_own_resource_info({
      package => $resource_name,
      debug   => $self->{debug},
      type    => 'admin',
    });
  }

  $self->{Errors} = $Paths->{Errors} || undef;

  $self->{error_msg} = $Paths->{error_msg} || '';

  if (!$self->{resource_own}) {
    $self->{paths} = $Paths->list();
    $self->{resource} = $self->{paths}->{$resource_name};
  }
  elsif (ref \$self->{resource_own} eq 'SCALAR' && $self->{resource_own} == 2) {
    $self->{errno} = 10;
    $self->{errstr} = 'Access denied';
    $self->{status} = 403;

    return $self;
  }

  $self->{request_path} = join('/', @params) . '/';
  $self->{allowed} = 0;
  $self->{status} = 0;

  return $self;
}

#***********************************************************
=head2 transform()

=cut
#***********************************************************
sub transform {
  my $self = shift;
  my ($transformer) = @_;

  $self->{result} = $transformer->($self->{result});
  return 1;
}

#***********************************************************
=head2 add_credential()

=cut
#***********************************************************
sub add_credential {
  my $self = shift;
  my ($credential_name, $credential_handler) = @_;

  $self->{credentials}->{$credential_name} = $credential_handler;
  return 1;
}

#***********************************************************
=head2 handle() - execute routed method

=cut
#***********************************************************
sub handle {
  my $self = shift;

  if ($self->{status}) {
    $self->{allowed} = 1;
    return 0;
  }

  my $handler = $self->parse_request();
  my $route = $handler->{route} if ($handler);

  if (!$route) {
    $self->{result} = {
      errno  => 2,
      errstr => 'No such route'
    };
    if ($self->{conf}->{API_DEBUG} && $@) {
      $self->{result}->{debuginfo} = $@;
    }
    $self->{status} = 404;
    $self->{allowed} = 1;

    return 0;
  }

  my $cred = q{};

  # check is allowed to execute this path
  if ($route->{credentials}) {
    foreach my $credential_name (@{$route->{credentials}}) {
      my $credential = $self->{credentials}->{$credential_name};

      if (defined $credential) {
        if ($credential->($handler)) {
          $cred = $credential_name;
          $self->{allowed} = 1;
          last;
        }
      }
    }

    return if (!$self->{allowed});
  }
  else {
    return;
  }

  # validate request body or query params
  if (defined $route->{params}) {
    my $Validator = Abills::Api::Validator->new($self->{db}, $self->{admin}, $self->{conf});
    my $validation_result = $Validator->validate_params({
      query_params => $handler->{query_params} || {},
      params       => $route->{params} || {},
    });

    if ($validation_result->{errno}) {
      require Control::Errors;
      Control::Errors->import();
      my $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, { lang => $self->{lang} });

      $self->{result} = $Errors->throw_error($validation_result->{errno}, $validation_result);
      return 0;
    }

    $handler->{query_params} = $validation_result;
  }

  # global check user exists and adding user_obj to request
  if ($cred && in_array($cred, [ 'ADMIN', 'ADMIN_SID' ]) && $handler->{path_params} && $handler->{path_params}->{uid}) {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->info($handler->{path_params}->{uid});

    if (!$Users->{TOTAL}) {
      $self->{result} = {
        errno  => 15,
        errstr => "User not found with uid $handler->{path_params}->{uid}",
        uid    => $handler->{path_params}->{uid},
      };
      return 0;
    }
    else {
      $handler->{path_params}->{user_object} = $Users;
    }
  }

  $self->{handler} = $handler;

  my $module_obj;
  if ($route->{module}) {
    return $self if !$self->_load_module($route->{module});

    $module_obj = $route->{module}->new($self->{db}, $self->{admin}, $self->{conf});
    $module_obj->{debug} = $self->{debug};
  }

  my $result = '';

  if ($route->{controller} && $route->{endpoint}) {
    return $self if !$self->_load_module($route->{controller});

    my $func = $route->{endpoint};
    my $controller = $route->{controller}->new($self->{db}, $self->{admin}, $self->{conf}, {
      lang   => $self->{lang},
      html   => $self->{html},
      Errors => $self->{Errors},
    });

    eval {
      $result = $controller->$func(
        $handler->{path_params},
        $handler->{query_params},
        $module_obj,
      );
    };
  }
  else {
    eval {
      $result = $handler->{handler_fn}->(
        $handler->{path_params},
        $handler->{query_params},
        $module_obj
      );
    };
  }

  if ($@) {
    $self->{result} = {
      errno  => 20,
      errstr => 'Unknown error, please try later'
    };
    if ($self->{conf}->{API_DEBUG} && $@) {
      $self->{result}->{debuginfo} = $@;
    }

    $self->{status} = 502;
    $self->{error_msg} = $@;

    return 0;
  }

  if ($module_obj->{errno}) {
    $self->{result} = {
      errno  => $module_obj->{errno},
      errstr => $module_obj->{errstr}
    };
    $self->{status} = 400;
  }
  else {
    $self->{content_type} = $route->{content_type} || q{};

    if (ref $result ne 'HASH' && ref $result ne 'ARRAY' && ref $result ne '') {
      foreach my $key (keys %{$result}) {
        next if (defined $self->{$key} && $key ne 'result');
        $self->{result}->{$key} = $result->{$key};
      }
    }
    else {
      $self->{result} = $result;

      if (!defined($self->{result})) {
        $self->{result} = {};
      }

      if (!ref $self->{result} && !$route->{content_type}) {
        $self->{result} = {
          result => $self->{result} ? 'OK' : 'BAD'
        };
      }
    }
  }

  return 1;
}

#***********************************************************
=head2 _load_module() - load module and and define correct result and http status

  ARGS:
    $module: str - name of module which need load

  Return:
    status: bool -
      1 - module is loaded correctly without errors
      0 - failed load module

=cut
#***********************************************************
sub _load_module {
  my $self = shift;
  my ($module) = @_;

  if ($module !~ /^[a-zA-Z0-9_:]+$/) {
    $self->{status} = 502;
    $self->{result} = {
      errno  => 3,
      errstr => 'Module not found'
    };
    return 0;
  }

  my $module_path = $module . '.pm';
  $module_path =~ s{::}{/}g;
  eval { require $module_path };

  if ($@ || !$module->can('new')) {
    $self->{status} = 502;
    $self->{result} = {
      errno  => 4,
      errstr => 'Module not found'
    };
    if ($self->{conf}->{API_DEBUG} && $@) {
      $self->{result}->{debuginfo} = $@;
    }
    return 0;
  }

  return 1;
}

#***********************************************************
=head2 parse_request() - parses request and returns data, required to process it

   Returns:
    {
      route        - hashref of route's info. look at docs in Abills::Api::Paths
      handler_fn   - coderef of route's handler function
      path_params  - params from path. hashref.
                     Example: if route's path is '/users/:uid/', and queried
                     URL is '/users/9/', there will be { uid => 9 }.
                     always numerical
      query_params - params from query. for details look at sub new(). hashref.
                     keys will be converted from camelCase to UPPER_SNAKE_CASE
                     using Abills::Base::decamelize
      conf_params  - variables from $conf to be returned in result. arrayref.
                     experimental feature, currently disabled
    }

=cut
#***********************************************************
sub parse_request {
  my $self = shift;

  my $request_path = $self->{request_path};
  my $query_params = $self->{query_params};

  my $resource = ($self->{resource_own} || $self->{resource});

  foreach my $route (@{$resource}) {
    next if (!$self->{request_method} || $route->{method} ne $self->{request_method});

    my $route_handler = $route->{handler};
    next if (ref $route_handler ne 'CODE' && !$route->{endpoint} && !$route->{controller});

    my $route_path_template = $route->{path};

    my @path_keys = $route_path_template =~ m/:([a-zA-Z0-9_]+)(?=\/)/g;

    $route_path_template =~ s/:(string_[a-zA-Z0-9_]+)(?=\/)/([a-zA-Z0-9:_-]+)/gm;
    $route_path_template =~ s/:([a-zA-Z0-9_]+)(?=\/)/(\\d+)/g;
    $route_path_template =~ s/(\/)/\\\//g;
    $route_path_template = '^' . $route_path_template . '$';

    next if ($request_path !~ $route_path_template);
    my @request_values = $request_path =~ $route_path_template;

    my %path_params = ();

    while (@path_keys) {
      my $key = shift(@path_keys);

      $key =~ s/string_//;
      my $value = shift(@request_values);

      $path_params{$key} = $value;
    }

    my %query_params = ();

    for my $query_key (keys %{$query_params}) {
      my $key = decamelize($query_key);
      if (ref $query_params->{$query_key} ne '') {
        $query_params->{$query_key} = process_request_body($query_params->{$query_key}, { no_decamelize_params => $route->{no_decamelize_params} || '' });
      }
      else {
        if ($key eq 'SORT') {
          $query_params->{$query_key} = decamelize($query_params->{$query_key});
        }
      }
      $query_params{$key} = $query_params->{$query_key};
    }

    my $path_params = escape_for_sql(\%path_params);

    return {
      route        => $route,
      handler_fn   => $route_handler,
      path_params  => $path_params,
      query_params => \%query_params,
    };
  }
}

#***********************************************************
=head2 process_request_body($query_params)

=cut
#***********************************************************
sub process_request_body {
  my ($query_params, $attr) = @_;

  if (ref $query_params eq 'ARRAY') {
    foreach my $val (@$query_params) {
      next if (ref $val ne 'HASH');
      $val = process_request_body($val, $attr);
    }
  }
  elsif (ref $query_params eq 'HASH') {
    foreach my $query_key (keys %$query_params) {
      if (ref $query_params->{$query_key} eq '') {
        my $key = decamelize($query_key);
        $query_params->{$key} = $query_params->{$query_key};
      }
      else {
        my $key = decamelize($query_key);
        $query_params->{$key} = process_request_body($query_params->{$query_key}, $attr);
      }
    }
  }

  return $query_params;
}

1;
