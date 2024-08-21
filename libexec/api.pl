#!/usr/bin/perl
package main v0.3.2;
=head ABillS Api MojoLite

  Test Version

  Proxy server with Mojolicious::Lite

   run dev server
     morbo -l http://localhost:{PORT} api.pl

   run production server
     hypnotoad api.pl

=cut

use strict;
use warnings FATAL => 'all';

BEGIN {
  our $libpath = '../';
  eval { do "$libpath/libexec/config.pl" };
  our %conf;

  if (!%conf) {
    print "Content-Type: text/plain\n\n";
    print "Error: Can't load config file 'config.pl'\n";
    print "Create ABillS config file /usr/abills/libexec/config.pl\n";
    exit;
  }

  my $sql_type = $conf{dbtype} || 'mysql';
  unshift(@INC,
    $libpath . 'Abills/modules/',
    $libpath . "Abills/$sql_type/",
    $libpath . '/lib/',
    $libpath . 'Abills/',
    $libpath
  );
}

use Time::HiRes qw(gettimeofday);

use Mojolicious::Lite -signatures;

# Please do not delete. Used for debugging of requests
# plugin NYTProf => {
#   nytprof => {
#     profiles_dir     => '/usr/abills/cgi-bin/nytprof',
#     allow_production => 0,
#     pre_hook         => 'before_routes',
#     post_hook        => 'around_dispatch',
#   },
# };

use Abills::Filters qw(url2parts);
use Abills::Base qw(json_former);
use Abills::Api::Handle;
use Abills::Api::Paths;
use Abills::Defs;
use Users;
use Conf;
use Admins;

# Please do not delete this global vars for stability work of global packages
our (
  %LANG,
  %lang,
  %conf,
  @MONTHES,
  @WEEKDAYS,
  $base_dir,
  @REGISTRATION,
  @MODULES,
  %functions,
  %COOKIES,
  %FORM,
  $PROGRAM,
);

do $libpath . '/language/english.pl';

require Control::Auth;
require Abills::Misc;

our $db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, {
  CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
  dbdebug => $conf{dbdebug}
});

our $html = Abills::HTML->new({
  IMG_PATH   => '../img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE}
});

our $admin = Admins->new($db, \%conf);
our Users $user = Users->new($db, $admin, \%conf);
our $Conf = Conf->new($db, $admin, \%conf);
my $Handle = Abills::Api::Handle->new($db, $admin, $Conf->{conf}, {
  html => $html,
  lang => \%lang,
});

my $mojo_port = $conf{API_MOJO_PORT} || 3000;

app->renderer->default_format('json');
app->renderer->cache->max_keys(0);

app->config(
  # production config, maybe need to do custom in config.pl
  hypnotoad => {
    listen             => [ "http://localhost:$mojo_port" ],
    proxy              => 1,
    workers            => 2,
    keep_alive_timeout => 10,
    inactivity_timeout => 10,
    graceful_timeout   => 20,
    upgrade_timeout    => 60,
    heartbeat_timeout  => 20,
    heartbeat_interval => 5,
    no_cache           => 1
  },
);

hook before_render => sub {
  my Mojolicious::Controller $router = shift;
  my $args = shift;

  if ($args->{template} && $args->{template} eq 'not_found') {
    $args->{json} = { errno => 2, errstr => 'No such route' };
    $args->{status} = 404;
  }
  elsif ($args->{template} && $args->{template} eq 'exception') {
    $args->{json} = { errno => 21, errstr => 'Unknown error, please try later' };
    $args->{status} = 502;
  }

  if ($conf{API_LOG} && $args->{json}) {
    _define_env($router);

    $Handle->api_add_log(
      {},
      $router->req->content->asset->{content},
      json_former($args->{json}),
      $args->{status},
      $router->req->url->path->{method},
      $router->req->url->path->{path}
    );
  }
};

# must run after hook
start();

sub start {
  _define_env();

  my $Paths = Abills::Api::Paths->new($db, $admin, $Conf->{conf}, \%lang, $html);

  my @paths = ();
  my $path_list = $Paths->list();

  foreach my $path_name (keys %{$path_list}) {
    push @paths, @{$path_list->{$path_name}};
  }

  my $modules = $Paths->_extra_api_modules();

  my @modules = (@MODULES, @{$modules});

  foreach my $module (@modules) {
    my $paths = $Paths->load_own_resource_info({
      package => $module,
      debug   => 0,
      type    => 'user',
    });

    push @paths, @{$paths || []};

    $paths = $Paths->load_own_resource_info({
      package => $module,
      debug   => 0,
      type    => 'admin',
    });

    push @paths, @{$paths || []};
  }

  my %method_map = (
    GET    => \&get,
    POST   => \&post,
    PUT    => \&put,
    PATCH  => \&patch,
    DELETE => \&del,
  );

  foreach my $path (@paths) {
    my $method = $path->{method};
    if (exists $method_map{$method}) {
      $method_map{$method}->($path->{path} => sub($router) {
        response($router, $path);
      });
    }
  }
}

#**********************************************************
=head2 response($router, $path) - Render response on API req

  Arguments:
     $router - Mojolicious::Lite req/res body object by default in Mojo $c
     $path   - path object. You can read more about it in Abills::Api::Paths::list() POD code before function.

=cut
#**********************************************************
sub response {
  my Mojolicious::Controller $router = shift;
  my $path = shift;
  my $begin_time = Time::HiRes::gettimeofday();

  %FORM = ();

  #sh1t fix of base memory leak
  delete $db->{COL_NAMES_ARR};
  delete $db->{queries_list};

  _define_env($router, $path);

  my $body = {};
  if ($path->{method} eq 'GET' || $path->{method} eq 'DELETE') {
    $body = $router->req->query_params->to_hash;
  }
  else {
    $body->{__BUFFER} = $router->req->content->asset->{content};
  }

  %COOKIES = ();
  Abills::HTML::get_cookies();

  my $handle = Abills::Api::Handle->new($db, $admin, $Conf->{conf}, {
    html        => $html,
    lang        => \%lang,
    cookies     => \%COOKIES,
    return_type => 'json',
    begin_time  => $begin_time
  });

  my ($response, $status) = $handle->api_call({
    METHOD => $ENV{REQUEST_METHOD} || q{},
    PARAMS => $body,
    PATH   => $ENV{PATH_INFO} || q{},
  });

  $router->render(data => $response, status => $status);

  return 1;
}

#**********************************************************
=head2 _define_env($router, $path) define default env variables

  Arguments:
   $router - Mojolicious::Lite req/res body object by default in Mojo $c
   $path   - path object. You can read more about it in Abills::Api::Paths::list() POD code before function.

=cut
#**********************************************************
sub _define_env {
  my Mojolicious::Controller $router = shift;
  my $path = shift;

  if (!$router) {
    return 1 if (!$conf{BILLING_URL});
    # lets define environment variables because its daemon
    my ($proto, $host, $port) = url2parts($conf{BILLING_URL});
    $ENV{PROT} = $proto;
    $ENV{SERVER_NAME} = $host;
    $ENV{SERVER_PORT} = $port || ($ENV{PROT} eq 'http' ? '80' : '443');
    # Used to check process is daemon. If daemon prevent places where is possible memory leak
    $ENV{IS_DAEMON} = 1;

    # maybe better use? but it will be needed to redefine each time after request
    # $router->req->headers->header('x-forwarded-https') || '';
    # $router->req->headers->header('x-forwarded-host') || '';
  }
  else {
    #define default headers
    $ENV{PATH_INFO} = $router->req->url->path->{path} || '';
    $ENV{REMOTE_ADDR} = $router->req->headers->header('x-forwarded-for') || '';

    # empty cache if was defined before, preventing auth without access allow
    foreach my $variable (keys %ENV) {
      next if ($variable !~ /^HTTP_/);
      delete $ENV{$variable};
    }

    my $headers = $router->req->headers->to_hash;
    foreach my $header (keys %{$headers}) {
      next if (!$header);
      my $value = $headers->{$header};
      $header =~ s/-/_/g;

      $ENV{'HTTP_' . uc($header)} = $value;
    }

    $ENV{REQUEST_METHOD} = $path->{method};
  }

  return 1;
}

app->start;
