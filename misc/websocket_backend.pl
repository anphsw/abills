#!/usr/bin/env perl
use strict;
use warnings;
use utf8;

our (%conf, $base_dir, $debug, $ARGS, @MODULES, $db);

$debug ||= 3;

BEGIN {
  use FindBin '$Bin';
  unshift @INC, $Bin . '/../lib';
  unshift @INC, $Bin . '/../lib/Backend';
  unshift @INC, $Bin . '/../Abills/modules';
  unshift @INC, $Bin . '/../Abills/mysql';
}

# Localizing global variables
use Abills::Backend::Defs;

use AnyEvent;
use AnyEvent::Handle;
use AnyEvent::Socket;
use AnyEvent::Impl::Perl;

use Abills::Base;
use Abills::Server;

use Abills::Backend::Plugin::BaseAPI;
use Abills::Backend::Plugin::BasePlugin;

# Setting up Log
use Abills::Backend::Log;
my $log_level = $conf{WEBSOCKET_DEBUG} || $debug;
my $log_file = $ARGS->{LOG_FILE}
  || $conf{WEBSOCKET_DEBUG_FILE}
  || ($base_dir || '/usr/abills/') . '/var/log/websocket.log';

our $Log = Abills::Backend::Log->new('FILE', $log_level, 'Main', {
    FILE => $log_file
  });

_bp(undef, undef, { SET_ARGS => { TO_CONSOLE => 1 } });

# Daemon controls block
{
  my %daemon_args = (
    LOG_DIR => $base_dir . '/var/log/',
    PROGRAM => 'websocket_backend'
  );
  
  my $start = sub {
    my $pid_file = daemonize(\%daemon_args);
    $Log->info("Started... $pid_file", 'Daemon');
    $pid_file;
  };
  
  my $stop = sub {
    stop_server(undef, \%daemon_args);
    $Log->info('Normal exit', 'Daemon');
  };
  
  #Starting
  if ( defined($ARGS->{'-d'}) || defined($ARGS->{'start'}) ) {
    $start->();
  }
  # Stoppping
  elsif ( defined($ARGS->{stop}) ) {
    $stop->();
    exit;
  }
  elsif ( defined($ARGS->{restart}) ) {
    $Log->info('Restarting', 'Daemon');
    
    $stop->();
    my $pid_file = $start->();
    
    $Log->info("Restarted $pid_file", 'Daemon');
  }
  # Checking if already running
  elsif ( make_pid() == 1 ) {
    exit;
  }
  
  $SIG{INT} = sub {
    $stop->();
    $Log->info("Stop on signal INT", 'Daemon');
    print "Interrupted\n";
    exit 0;
  };
  
}

# This should be global so plugins live in event loop
my %LOADED_PLUGINS = ();

# Allow to start only one plugin
if ( $ARGS->{PLUGIN} ) {
  foreach my $plugin ( split(',', $ARGS->{PLUGIN}) ){
    start_plugin($plugin);
  };
}
else {
  # Load plugins that have been enabled in config
  start_plugin('Websocket') if ( !$conf{WEBSOCKET_DISABLED} );
  start_plugin('Internal') if ( !$conf{WEBSOCKET_INTERNAL_DISABLED} );
  
  if ( $conf{EVENTS_ASTERISK} ) {
    start_plugin('Asterisk');
  }
  
  if ( $conf{TELEGRAM_TOKEN} ) {
    start_plugin('Telegram');
  }
  
  if ( $conf{SATELLITE_MODE} ) {
    start_plugin('Satellite');
  }
  
}

$Log->info('Waiting for events');

AnyEvent::Impl::Perl::loop;
exit;

#**********************************************************
=head2 start_plugin($plugin_name, $attr)

  Arguments:
    $plugin_name, $attr -
    
  Returns:
  
=cut
#**********************************************************
sub start_plugin {
  my ($plugin_name) = @_;
  
  my $package_name = 'Abills::Backend::Plugin::' . $plugin_name;
  my $file_name = 'Abills/Backend/Plugin/' . $plugin_name . '.pm';
  
  require $file_name;
  $package_name->import();
  
  eval {
    my Abills::Backend::Plugin::BasePlugin $plugin_object = $package_name->new(\%conf);
    $LOADED_PLUGINS{$plugin_name} = $plugin_object;
    
    my Abills::Backend::Plugin::BaseAPI $plugin_api = $plugin_object->init();
    register_global(uc($plugin_name) . '_API', $plugin_api);
  };
  
  if ( $@ ) {
    $Log->alert("Failed to load $plugin_name : $@");
    return 0;
  }
  
  $Log->notice("Loaded $plugin_name");
  return 1;
}

1;