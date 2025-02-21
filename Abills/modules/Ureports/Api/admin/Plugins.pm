package Ureports::Api::admin::Plugins;

=head1 NAME

  Ureports User

  Endpoints:
    /ureports/plugins/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Abills::Loader qw(load_plugin);

use Ureports;

my Ureports $Ureports;
my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Ureports = Ureports->new($db, $admin, $conf);
  $Ureports->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_ureports_plugins($path_params, $query_params)

  Endpoint GET /ureports/plugins/

=cut
#**********************************************************
sub get_ureports_plugins {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %reports = ();
  my $base_dir = $main::base_dir || '/usr/abills/';
  my $mod_path = $base_dir . 'Abills/modules/Ureports/Plugins/';

  my $contents = ::_get_files_in($mod_path, { FILTER => '\.pm' });
  foreach my $report_module (@{$contents}) {
    $report_module =~ s/\.pm//;
    my $plugin_name = "Ureports::Plugins::$report_module";

    my $report = load_plugin($plugin_name, {
      SERVICE      => $self,
      RETURN_ERROR => 1
    });

    if ($report->{SYS_CONF}{REPORT_NAME}) {
      $reports{$report_module} = { %{$report->{SYS_CONF}}, MODULE => $report_module };
    }
  }

  return \%reports;
}

1;
