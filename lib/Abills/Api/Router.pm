package Abills::Api::Router;

use strict;
use warnings;

use JSON;

BEGIN {
  our $libpath = '../../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/modules/",
    $libpath . "Abills/Control/",
    $libpath . "/lib/",
    $libpath . "/Abills/",
    $libpath
  );
}

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
  $self->{request_path} = join('/', @params)."/";

  $self->{credentials} = ();
  $self->{allowed} = 0;

  $self->{query_params} = ($ENV{REQUEST_METHOD} eq "GET") ? $query_params : $query_params->{__BUFFER} ? decode_json $query_params->{__BUFFER} : ();

  if($ENV{REQUEST_METHOD} eq "PUT" || $ENV{REQUEST_METHOD} eq "DELETE") {
      my @pairs = split(/[&,;]/, $ENV{QUERY_STRING});

      foreach my $pair (@pairs){
        my ($name, $value) = split(/=/, $pair);
        $self->{query_params}->{$name} = $value;
      }
  }

  if(defined $self->{query_params}->{__BUFFER}) {
    delete $self->{query_params}->{__BUFFER};
  }

  $self->{status} = 0;

  bless($self, $class);

  return $self;
}

sub transform {
  my ($self, $transformer) = @_;

  $self->{result} = $transformer->($self->{result}, $self->{response_type});
}

sub add_credential {
  my ($self, $credential_name, $credential_handler) = @_;

  $self->{credentials}->{$credential_name} = $credential_handler
}

# **********************************************************
=head2 handle() - execute routed method

=cut
# **********************************************************
sub handle {
  my ($self) = @_;

  my $handler = parse_request($self, $self->{query_params});

  if(defined $handler->{route}->{credentials}) {
    foreach my $credential_name (@{ $handler->{route}->{credentials} }) {
      my $credential = $self->{credentials}->{$credential_name};

      if(defined $credential) {
        if($credential->($self->{query_params})) {
          $self->{allowed} = 1;
        }
      }
    }

    unless($self->{allowed}) {
      return;
    }
  }
  else {
    $self->{allowed} = 1;
  }

  if($handler->{route}->{custom}) {
    my $result = $handler->{route}->{handler}->(
      $handler->{path_params},
      $self->{query_params}
    );

    $self->{result} = $result;
    $self->{response_type} = $handler->{route}->{type} || 'HASH';
  }
  else {
    my $module_name = $handler->{route}->{module};

    $self->{response_type} = $handler->{route}->{type} || 'HASH';

    require "$module_name.pm";

    my $module = eval "$module_name->new(\$self->{db}, \$self->{admin}, \$self->{conf})";

    $self->{result} = eval "\$module->$handler->{signature}";

    unless($self->{result}) {
      if($handler->{route}->{type} eq 'ARRAY'){
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


# **********************************************************
=head2 load_resource_info($resource_name)
#   Return:
#     @router - list of available mathods for this resource

=cut
# **********************************************************
sub load_resource_info {
  my ($self, $resource_name) = @_;

  return $self->{paths}->{$resource_name};
}


# **********************************************************
=head2 out($formatter)
#   Arguments:
#     $formatter

#   Return:
#     $string - plain string for response

=cut
# **********************************************************
sub out {
  my ($self, $formatter) = @_;

  return $formatter->format(
    $self->{result},
    $self->{response_type},
    $self->{errno},
    $self->{errstr}
  );
}

sub add_custom_handler {
  my ($self, $resource_name, $info) = @_;

  $info->{custom} = 1;

  push(@{ $self->{paths}->{$resource_name} }, $info);
}


# **********************************************************
=head2 parse_request()
#   Return:
#     %(
#        route
#        signature
#        path_params
#      )

=cut
# **********************************************************
sub parse_request {
  my ($self) = @_;

  my $request_path = $self->{request_path};
  my $query_params = $self->{query_params};

  foreach my $route (@{ $self->{resource} }) {
    if($route->{method} ne $ENV{REQUEST_METHOD}) {
      next;
    }

    my $route_path_template = $route->{path};
    my $router_handler = $route->{handler};

    my @path_keys = $route_path_template =~ m/(?<=\:)(.*?)(?=\/)/gm;

    $route_path_template =~ s/(?=\:)(.*?)(?=\/)/(\\d*?)/g;
    $route_path_template =~ s/(\/)/\\\//g;
    $route_path_template = '^'.$route_path_template.'$';

    unless($request_path =~ $route_path_template) {
      next;
    }

    my @request_values = $request_path =~ $route_path_template;
    my %path_params = ();

    while (@path_keys) {
      my $key   = shift(@path_keys);
      my $value = shift(@request_values);

      $path_params{$key} = $value;

      $router_handler =~ s/\:$key/\'$value\'/gm;
    }

    my $rest_params = '';

    for my $query_key (keys %{ $query_params }) {
      my $key = Abills::Api::Camelize::decamelize($query_key);
      $rest_params .= "$key => '$query_params->{$query_key}',";
    }

    chop($rest_params);

    $router_handler =~ s/\:(\w*)/undef/gm;

    $router_handler =~ s/\.\.\.PARAMS/$rest_params/gm;

    return {
      route       => $route,
      signature   => $router_handler,
      path_params => \%path_params,
    };
  }
}

1;