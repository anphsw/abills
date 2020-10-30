#!/usr/bin/perl

use strict;
use warnings;

BEGIN {
  our $libpath = '../';
  my $sql_type = 'mysql';
  unshift(@INC,
    $libpath . "Abills/$sql_type/",
    $libpath . "Abills/modules/",
    $libpath . "/lib/",
    $libpath . "/Abills/",
    $libpath . "/Abills/Api/",
    $libpath
  );

  eval {require Time::HiRes;};
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::JSON;
use Abills::Defs;
use Abills::Base qw(gen_time in_array mk_unique_value load_pmodule sendmail cmd decode_base64);

use Users;
use Finance;
use Admins;

use Conf;
use POSIX qw(mktime strftime);

use Abills::Api::Router;
use Abills::Api::Formatter::JSONFormatter;

use Abills::Api::FildsGrouper;

our (
  %LANG,
  %lang,
  @MONTHES,
  @WEEKDAYS,
  $base_dir,
  @REGISTRATION
);

do '../libexec/config.pl';
do 'Abills/Misc.pm';

require Abills::Templates;
require Abills::Result_former;

our $db = Abills::SQL->connect(
  $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  {
    CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef,
    dbdebug => $conf{dbdebug}
  }
);

our $html = Abills::HTML->new(
  {
    IMG_PATH  => "img/",
    NO_PRINT  => 1,
    CONF      => \%conf,
    CHARSET   => $conf{default_charset},
    HTML_STYLE=> $conf{UP_HTML_STYLE}
  }
);

if ($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if (-f $libpath . "/language/$html->{language}.pl") {
  do $libpath . "/language/$html->{language}.pl";
}

our $admin = Admins->new($db, \%conf);
our Users $user = Users->new($db, $admin, \%conf);

my $use_camelize = defined $ENV{HTTP_CAMELIZE} ? $ENV{HTTP_CAMELIZE} : (
  defined $conf{API_FILDS_CAMELIZE} ? $conf{API_FILDS_CAMELIZE} : 1
);

print Abills::JSON::header();

my $router = Abills::Api::Router->new($ENV{PATH_INFO}, $db, $user, $admin, \%conf, \%FORM);

require Control::Auth;

$router->add_custom_handler("users", {
  method  => "POST",
  path    => "/users/login/",
  handler => sub {
    my ($path_params, $query_params) = @_;

    my ($uid, $sid, $login) = auth_user($query_params->{login}, $query_params->{password}, '');

    return {
      UID   => $uid,
      SID   => $sid,
      LOGIN => $login
    }
  }
});

$router->add_custom_handler("pages", {
  method  => "GET",
  path    => "/pages/index/",
  handler => sub {
    my ($path_params, $query_params) = @_;

    my $index = get_function_index($query_params->{name});

    return {
      INDEX => $index
    }
  }
});

$router->add_credential('ADMIN', sub {
  my ($request) = @_;

  my $API_KEY = $ENV{HTTP_KEY};

  return check_permissions('', '', '', { API_KEY => $API_KEY }) == 0;
});

$router->add_credential('USER', sub {
  my ($request) = @_;

  my $SID = $ENV{HTTP_CGI_AUTHORIZATION};
  my $user_info = $user->info('', { SID => $SID });

  my ($UID) = auth_user('', '', $SID);

  return $UID != 0;
});

$router->handle();

if($router->{allowed}) {
  $router->transform(\&Abills::Api::FildsGrouper::group_filds);
}
else {
  $router->{result} = {
    error => 'Access denied'
  }
}

print $router->out(Abills::Api::Formatter::JSONFormatter->new($use_camelize, ['COL_NAMES_ARR']));