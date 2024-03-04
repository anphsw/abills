#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use lib '../../';
use lib '../../lib/';

use FindBin '$Bin';

use Abills::Base qw(parse_arguments);
use Abills::Api::Postman::Api;
use Abills::Api::Postman::Export;
use Abills::Api::Postman::Import;

our (%conf);

do 'libexec/config.pl';

my $base_dir = '/usr/abills/';

if ($Bin =~ m/\/abills(\/)/) {
  $base_dir = substr($Bin, 0, $-[1]);
  $base_dir .= '/';
}

my $argv = parse_arguments(\@ARGV);

my $type = $argv->{type} || '';
my $module = $argv->{module} || '';
my $Postman_action_plugin;

_start();

sub _start {
  if (!$argv->{export} && !$argv->{import}) {
    print "Unknown interaction. No selected import or export. Process end\n";
    return 1;
  }

  if (!$type) {
    print "No entered value type if import. Please enter admin or user? (admin/user): ";
    chomp($type = <STDIN>);
    $type = lc($type);
  }

  if ($type ne 'user' && $type ne 'admin') {
    print "Import process exit without start. Unknown type of operation\n";
    return 1;
  }

  if (!$module && $argv->{export}) {
    print "No entered module which need to export. Please enter module name?: ";
    chomp($module = <STDIN>);
  }

  $module = ucfirst(lc($module));

  my $collection;

  if ($argv->{export}) {
    $Postman_action_plugin = Abills::Api::Postman::Export->new({
      conf     => \%conf,
      debug    => $argv->{debug} || $argv->{DEBUG},
      type     => $type,
      export   => $argv->{preview} ? 0 : 1,
      module   => $module,
      base_dir => $base_dir
    });
  }
  else {
    my $Postman = Abills::Api::Postman::Api->new({
      conf  => \%conf,
      debug => $argv->{debug},
    });

    #TODO: add argument module for import
    $Postman_action_plugin = Abills::Api::Postman::Import->new({
      conf        => \%conf,
      debug       => $argv->{debug},
      type        => $type,
      import      => $argv->{preview} ? 0 : 1,
      new_schemas => $argv->{new_schemas} || 0,
      base_dir    => $base_dir
    });

    my $collection_id = $type eq 'admin' ? $conf{POSTMAN_ADMIN_COLLECTION_ID} : $conf{POSTMAN_USER_COLLECTION_ID};
    $collection = $Postman->collection_info({ collection_id => $collection_id });
  }

  $Postman_action_plugin->process($collection);

  if ($argv->{preview}) {
    print $Postman_action_plugin->{preview};
  }
}

1;
