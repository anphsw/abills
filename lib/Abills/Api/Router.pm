package Abills::Api::Router;

use strict;
use warnings;

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

use JSON;

BEGIN {
  our $libpath = '../../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/$sql_type/Internet/",
    $libpath . "Abills/modules/",
    $libpath . "Abills/Control/",
    $libpath . "/lib/",
    $libpath . "/Abills/",
    $libpath
  );
}

do "libexec/config.pl";

our (
  %conf
);

use Abills::Api::Camelize;
use Abills::Api::Paths;

#**********************************************************
=head2 new($url, $db, $user, $admin, $conf, $query_params)

=cut
#**********************************************************
sub new {
  my ($class, $url, $db, $user, $admin, $conf, $query_params) = @_;

  my $self = {};

  my @params = split('/', $url);
  my $resource_name = $params[1];

  $self->{params} = \@params;
  $self->{resource_name} = $resource_name;

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $conf;

  $self->{user} = $user;
  $self->{paths} = Abills::Api::Paths::list();

  $self->{resource} = load_resource_info($self, $resource_name);
  $self->{request_path} = join('/', @params) . "/";

  $self->{credentials} = ();
  $self->{allowed} = 0;
  $self->{query_params} = ($ENV{REQUEST_METHOD} ~~ [ "GET", "DELETE" ]) ? $query_params : $query_params->{__BUFFER} ? decode_json $query_params->{__BUFFER} : ();
  if ($ENV{REQUEST_METHOD} eq "DELETE") {
    my @pairs = split(/[&,;]/, $ENV{QUERY_STRING});

    foreach my $pair (@pairs) {
      my ($name, $value) = split(/=/, $pair);
      $self->{query_params}->{$name} = $value;
    }
  }

  if (defined $self->{query_params}->{__BUFFER}) {
    delete $self->{query_params}->{__BUFFER};
  }

  $self->{status} = 0;

  bless($self, $class);

  return $self;
}

#***********************************************************
=head2 transform()

=cut
#***********************************************************
sub transform {
  my ($self, $transformer) = @_;

  $self->{result} = $transformer->($self->{result}, $self->{response_type});
}

#***********************************************************
=head2 add_credential()

=cut
#***********************************************************
sub add_credential {
  my ($self, $credential_name, $credential_handler) = @_;

  $self->{credentials}->{$credential_name} = $credential_handler
}

#***********************************************************
=head2 handle() - execute routed method

=cut
#***********************************************************
sub handle {
  my ($self) = @_;

  my $handler = parse_request($self, $self->{query_params});

  my $route = $handler->{route};

  $route->{subpackage} = $route->{subpackage} || '';

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

  if ($route->{custom}) {
    my $result = $route->{handler}->(
      $handler->{path_params},
      $self->{query_params}
    );

    $self->{result} = $result;
    $self->{response_type} = $handler->{route}->{type} || 'HASH';
  }
  else {
    my $module_package = $route->{subpackage} . ($route->{subpackage} ? '::' : '') . $handler->{route}->{module};

    $self->{response_type} = $route->{type} || 'HASH';

    eval "use $module_package";

    if ($@) {
      $self->{errno} = 1;
      $self->{errstr} = 'Module is not found';

      return;
    }

    my $module = eval "$module_package->new(\$self->{db}, \$self->{admin}, \$self->{conf})";

    if ($module && $handler->{function_name} && $module->can($handler->{function_name})) {
      my $function_name = $handler->{function_name};
      $self->{result} = eval {$module->$function_name($handler->{signature_params});};
    }
    else {
      $self->{result} = eval "\$module->$handler->{signature}";
    }

    if(defined ($route->{conf_params})) {
      foreach my $conf_param (@{$route->{conf_params}}) {
        next if(!$conf{$conf_param});
        $self->{result}->{$conf_param} = $conf{$conf_param};
      }
    }

    if ($@) {
      $self->{errno} = 2;
      $self->{errstr} = $@;

      return;
    }

    unless ($self->{result}) {
      if ($self->{response_type} eq 'ARRAY') {
        $self->{result} = []
      }
      else {
        $self->{result} = {}
      }
    }

    $self->{errno} = $module->{errno};
    $self->{errstr} = $module->{errstr};
  }
}

#***********************************************************
=head2 load_resource_info($resource_name)

   Return:
     @router - list of available mathods for this resource
=cut
#***********************************************************
sub load_resource_info {
  my ($self, $resource_name) = @_;

  return $self->{paths}->{$resource_name};
}

#***********************************************************
=head2 out($formatter)

   Arguments:
     $formatter

   Return:
     $string - plain string for response
=cut
#***********************************************************
sub out {
  my ($self, $formatter) = @_;

  return $formatter->format(
    $self->{result},
    $self->{response_type},
    $self->{errno},
    $self->{errstr}
  );
}

#***********************************************************
=head2 add_custom_handler()

=cut
#***********************************************************
sub add_custom_handler {
  my ($self, $resource_name, $info) = @_;

  $info->{custom} = 1;

  push(@{$self->{paths}->{$resource_name}}, $info);
}

#***********************************************************
=head2 parse_request()

   Return:
     %(
        route
        signature
        path_params
      )
=cut
#***********************************************************
sub parse_request {
  my ($self) = @_;

  my $request_path = $self->{request_path};
  my $query_params = $self->{query_params};

  foreach my $route (@{$self->{resource}}) {
    next if ($route->{method} ne $ENV{REQUEST_METHOD});

    my $route_path_template = $route->{path};
    my $route_conf_params = $route->{conf_params};
    my $router_handler = $route->{handler};

    my @path_keys = $route_path_template =~ m/(?<=\:)(.*?)(?=\/)/gm;

    $route_path_template =~ s/(?=\:)(.*?)(?=\/)/(\\d*?)/g;
    $route_path_template =~ s/(\/)/\\\//g;
    $route_path_template = '^' . $route_path_template . '$';

    next unless ($request_path =~ $route_path_template);

    my @request_values = $request_path =~ $route_path_template;
    my %path_params = ();
    my $signature_params = ();

    while (@path_keys) {
      my $key = shift(@path_keys);
      my $value = shift(@request_values);

      $path_params{$key} = $value;

      $signature_params->{$key} = $value;
      $router_handler =~ s/\:$key/\"$value\"/gm;
    }

    my $rest_params = '';

    for my $query_key (keys %{$query_params}) {
      my $key = Abills::Api::Camelize::decamelize($query_key);
      my $value = $query_params->{$query_key} || q{};
      $signature_params->{$key} = $value;
      $value =~ s/\'/\\\'/g;
      $rest_params .= "$key => '" . qq{$value} . "',";
    }

    chop($rest_params);

    $router_handler =~ s/\:(\w*)/undef/gm;

    $router_handler =~ s/\.\.\.PARAMS/$rest_params/gm;

    my ($function_name, undef) = split(/\(/, $router_handler);

    return {
      route            => $route,
      signature        => $router_handler,
      signature_params => $signature_params,
      conf_params      => $route_conf_params,
      function_name    => $route->{use_function} ? $function_name : undef,
      path_params      => \%path_params,
    };
  }

  return { status => '404' }
}

1;