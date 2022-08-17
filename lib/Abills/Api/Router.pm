package Abills::Api::Router;

use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use JSON;

use Abills::Base qw(escape_for_sql);
use Abills::Api::Paths;

#**********************************************************
=head2 new($url, $db, $user, $admin, $conf, $query_params)

=cut
#**********************************************************
sub new {
  my ($class, $url, $db, $user, $admin, $conf, $query_params, $lang, $modules, $debug, $additional_params) = @_;

  my $self = {
    db                => $db,
    admin             => $admin,
    conf              => $conf,
    lang              => $lang,
    user              => $user,
    modules           => $modules,
    debug             => ($debug || 0),
    additional_params => $additional_params
  };

  bless($self, $class);

  $self->preprocess($url, $query_params);

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

  $url  =~ s/\?.+//g;
  my @params = split('/', $url);
  my $resource_name = $params[1] || q{};
  my $resource_name_user_api = $params[3] || q{};
  my $Paths = Abills::Api::Paths->new($self->{db}, $self->{conf}, $self->{admin}, $self->{lang});

  if ($ENV{REQUEST_METHOD} ~~ [ 'GET', 'DELETE' ]) {
    $self->{query_params} = $query_params;
  }
  elsif ($query_params->{__BUFFER}) {
    my $q_params = eval {decode_json($query_params->{__BUFFER}) };

    if ($@) {
      $self->{result} = {
        errno  => 1,
        errstr => 'There was an error parsing the body'
      };
      $self->{status} = '400';

      return $self;
    }
    else {
      $self->{query_params} = escape_for_sql($q_params);
    }
  }
  else {
    $self->{query_params} = undef;
  }

  if (defined $self->{query_params}->{__BUFFER}) {
    delete $self->{query_params}->{__BUFFER};
  }

  #TODO: if in future one Router object will be used for multiple queries, move this to new()
  if ($resource_name eq 'user' && $resource_name_user_api) {
    $self->{resource_own} = $Paths->load_own_resource_info({
      package           => $resource_name_user_api,
      modules           => $self->{modules},
      debug             => $self->{debug},
      type              => 'user',
      additional_params => $self->{additional_params}
    });
  }
  elsif ($resource_name ne 'user') {
    $self->{resource_own} = $Paths->load_own_resource_info({
      package           => $resource_name,
      modules           => $self->{modules},
      debug             => $self->{debug},
      type              => 'admin',
      additional_params => $self->{additional_params}
    });
  }

  if (!$self->{resource_own}) {
    $self->{paths} = $Paths->list();
    $self->{resource} = $self->load_resource_info($resource_name);
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
}

#***********************************************************
=head2 add_credential()

=cut
#***********************************************************
sub add_credential {
  my ($self, $credential_name, $credential_handler) = @_;

  $self->{credentials}->{$credential_name} = $credential_handler;
}

#***********************************************************
=head2 handle() - execute routed method

=cut
#***********************************************************
sub handle {
  my $self = shift;

  if ($self->{status}) {
    $self->{allowed} = 1;
    return;
  }

  my $handler = $self->parse_request();
  my $route = $handler->{route} if ($handler);

  if (!$route) {
    $self->{result} = {
      errno  => 2,
      errstr => 'No such route'
    };
    $self->{status} = '404';
    $self->{allowed} = 1;

    return;
  }

  if (defined $route->{credentials}) {
    foreach my $credential_name (@{$route->{credentials}}) {
      my $credential = $self->{credentials}->{$credential_name};

      if (defined $credential) {
        if ($credential->($handler)) {
          $self->{allowed} = 1;
        }
      }
    }

    return unless $self->{allowed};
  }
  else {
    $self->{allowed} = 1;
  }

  my $module_obj;
  if ($route->{module} && $self->{resource}) {
    if ($route->{module} !~ /^[a-zA-Z0-9_:]+$/) {
      $self->{result} = {
        errno  => 3,
        errstr => 'Module is not found'
      };
      return;
    }

    eval "use $route->{module}";

    if ($@ || !$route->{module}->can('new')) {
      $self->{result} = {
        errno  => 4,
        errstr => 'Module is not found'
      };
      return;
    }

    $module_obj = $route->{module}->new($self->{db}, $self->{admin}, $self->{conf});
    $module_obj->{debug} = $self->{debug};
  }

  my $result = $handler->{handler_fn}->(
    $handler->{path_params},
    $handler->{query_params},
    $module_obj
  );

  if ($module_obj->{errno}) {
    $self->{result} = {
      errno  => $module_obj->{errno},
      errstr => $module_obj->{errstr}
    };
    $self->{status} = '400';
  }
  else {
    if (ref $result ne 'HASH' && ref $result ne 'ARRAY' && ref $result ne '') {
      foreach my $key (keys %{$result}) {
        next if (defined $self->{$key} && $key ne 'result');
        $self->{result}->{$key} = $result->{$key};
      }
    }
    else {
      $self->{result} = $result;

      unless (defined($self->{result})) {
        $self->{result} = {};
      }

      unless (ref $self->{result}) {
        $self->{result} = {
          result => $self->{result} ? 'OK' : 'BAD'
        }
      }
    }
  }

  return 1;
}

#***********************************************************
=head2 load_resource_info($resource_name)

   Return:
     @router - list of available methods for this resource
=cut
#***********************************************************
sub load_resource_info {
  my $self = shift;
  my ($resource_name) = @_;

  return $self->{paths}->{$resource_name};
}

#***********************************************************
=head2 add_custom_handler()

=cut
#***********************************************************
sub add_custom_handler {
  my ($self, $resource_name, $info) = @_;

  push(@{$self->{paths}->{$resource_name}}, $info);
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
                     using Abills::Base::decamelize unless
                     $route->{no_decamelize_params} is set
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
    next if ($route->{method} ne $ENV{REQUEST_METHOD});

    my $route_handler = $route->{handler};
    next if (ref $route_handler ne 'CODE');

    my $route_path_template = $route->{path};

    my @path_keys = $route_path_template =~ m/:([a-zA-Z0-9_]+)(?=\/)/g;

    $route_path_template =~ s/:([a-zA-Z0-9_]+)(?=\/)/(\\d+)/g;
    $route_path_template =~ s/(\/)/\\\//g;
    $route_path_template = '^' . $route_path_template . '$';

    #TODO: make possible ti put not only numbers but also letters into path variables
    next unless ($request_path =~ $route_path_template);

    my @request_values = $request_path =~ $route_path_template;

    my %path_params = ();

    while (@path_keys) {
      my $key = shift(@path_keys);
      my $value = shift(@request_values);

      $path_params{$key} = $value;
    }

    my %query_params = ();

    for my $query_key (keys %{$query_params}) {
      my $key = $route->{no_decamelize_params} ? $query_key : Abills::Base::decamelize($query_key);

      if ($key eq 'SORT') {
        $query_params->{$query_key} = Abills::Base::decamelize($query_params->{$query_key});
      }

      $query_params{$key} = $query_params->{$query_key};
    }

    return {
      route        => $route,
      handler_fn   => $route_handler,
      path_params  => \%path_params,
      query_params => \%query_params,
    };
  }
}

1;
