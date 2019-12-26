package Internet::Tcpdump;

=head2 NAME

  Internet::Tcpdump;

=head2 SYNOPSYS

  Tcpdump module for Internet diagnostics

=cut

use strict;
use warnings 'FATAL' => 'all';
use IPC::Open3;
use Abills::HTML;
my $html;

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my ($attr) = @_;

  my $self = {
    db    => $attr->{db},
    admin => $attr->{admin},
    conf  => $attr->{conf}
  };

  $html = $attr->{html};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 tcpdump_event_stream() - streams tcpdump's output to browser via event-stream

=cut
#**********************************************************
sub tcpdump_event_stream {
  print "Content-type: text/event-stream\n\n";

  my $startup_files = main::startup_files();
  my $sudo_path = $startup_files->{SUDO};

  my $cmd = "$sudo_path tcpdump -vv";

  my $pid = open3(undef, \*PH, undef, $cmd);

  while( <PH> ) {
    print "\n\n";
    s/^/data: /g;
    print;
  }

  return 1;
}

#**********************************************************
=head2 action($diagnostic,$extra_param) - main action in module

  Arguments:
    $diagnostic  - URL diagnostic string
    $extra_param - Extra parameters. Here - defines if function should print HTML page or event-stream with tcpdump's output
      'event-stream' - should start event-stream
      empty string   - should print HTML page

    Returns:
      0 - if internet_online() should exit after action() returned
      1 - if internet_online() should run to the end and print full page

    Example:
      $require_module->action($diagnostic,$extra_param);
=cut
#**********************************************************
sub action {
  shift;
  my ($diagnostic, $extra_param) = @_;
  if($extra_param && $extra_param eq 'event-stream'){
    tcpdump_event_stream();
  }
  else{
    print "Content-type: text/html\n\n";
    $html->tpl_show(
      main::_include('internet_tcpdump','Internet'),
      {URL => "index.cgi?get_index=internet_online&diagnostic=$diagnostic event-stream"}
    );
  }
  return 0;
}

1;
