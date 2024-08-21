#!/usr/bin/perl

=head1 NAME

  Crm obtaining new leads from external systems

=cut

use strict;
use warnings;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  @MODULES,
  %FORM,
  %COOKIES
);

BEGIN {
  use FindBin '$Bin';

  require $Bin . '/../../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../../',
    $Bin . '/../../lib/',
    $Bin . '/../../Abills',
    $Bin . '/../../Abills/mysql',
    $Bin . '/../../Abills/modules',
  );
}

use Abills::Defs;
use Abills::JSON;
use Admins;
use Abills::Base qw(json_former _bp check_ip);
use Crm::db::Crm;
require Abills::Misc;

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin = Admins->new($db, \%conf);
my $Crm = Crm->new($db, $admin, \%conf);

use JSON qw(decode_json);
our $html = Abills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
});

_start();

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {

  if (!$FORM{__BUFFER}) {
    print Abills::JSON::header(undef, { STATUS => 400 });
    print json_former({ error => 'The data is empty' });
    exit;
  }

  my $params = ();
  eval {
    $params = decode_json($FORM{__BUFFER});
  };
  if ($@) {
    print Abills::JSON::header(undef, { STATUS => 400 });
    print json_former({ error => $@ }, { BOOL_VALUES => 1 });
    exit;
  }

  if (ref $params eq 'HASH') {
    manage_lead_request($params);
    print Abills::JSON::header(undef, { STATUS => 200 });
    print json_former({ success => 'true' }, { BOOL_VALUES => 1 });
    exit;
  }

  if (ref $params eq 'ARRAY') {
    foreach my $lead (@{$params}) {
      manage_lead_request($lead);
    }
  }

  print Abills::JSON::header(undef, { STATUS => 200 });
  print json_former({ success => 'true' }, { BOOL_VALUES => 1 });
  exit;
}

#**********************************************************
=head2 manage_lead_request($lead)

=cut
#**********************************************************
sub manage_lead_request {
  my ($lead) = @_;

  if ($lead->{mobile} && $lead->{name} && defined($lead->{city})) {

    if (!$ENV{REMOTE_ADDR} || !check_ip($ENV{REMOTE_ADDR}, $conf{CRM_MULTITEST_IPS})) {
      print Abills::JSON::header(undef, { STATUS => 403 });
      print json_former({ error => 'Unknown IP address' });
      exit;
    }

    use Crm::Plugins::Multitest;
    my $Multitest = Crm::Plugins::Multitest->new($db, $admin, \%conf);

    $Multitest->lead_add($lead);
    return;
  }
}

1;