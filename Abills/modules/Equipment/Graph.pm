#**********************************************************
=head1 NAME

  Equipment::Graph

=cut
#**********************************************************


use strict;
use warnings;
use Abills::Base qw(load_pmodule show_hash);
use POSIX qw( strftime );

our (
  $html,
  #%lang,
  $var_dir
);

my $load_data = load_pmodule('RRDTool::OO', { SHOW_RETURN => 1 });

#**********************************************************
=head2 add_graph($attr)

   Arguments:
     $attr
       NAS_ID  - Nas id
       PORT    - Port id
       TYPE    - Graph type: SPEED, SIGNAL, TEMPERATURE
       STEP    - Step: 60, 300, 600 (default 300)
       DATA    - Data hash

   Results:
     TRUE or FALSE

   Examples:
     add_graph({ NAS_ID => $nas_id, PORT => $onu->{ONU_SNMP_ID}, TYPE => $graph_type, DATA => \@onu_graph_data, STEP => $argv->{STEP} || '300' });

=cut
#**********************************************************
sub add_graph {
  my ($attr) = @_;

  my $debug = $attr->{DEBUG} || $FORM{DEBUG} || 0;

  if ($load_data) {
    return 0;
  }

  my $rrd_dir = $var_dir . "db/rrd";
  my $db_dir = $var_dir . "db/";

  if (!-d $db_dir) {
    mkdir $db_dir, 777;
    print "mkdir:  $db_dir\n";
  }
  if (!-d $rrd_dir) {
    mkdir $rrd_dir, 777;
    print "mkdir: $rrd_dir \n";
  }

  my $archive = {
    60  => [
      archive => { rows => 1440, cpoints => 1, cfunc => 'AVERAGE' },
      archive => { rows => 672, cpoints => 15, cfunc => 'AVERAGE' },
      archive => { rows => 744, cpoints => 60, cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 360, cfunc => 'AVERAGE' },
      archive => { rows => 1440, cpoints => 1, cfunc => 'MAX' },
      archive => { rows => 672, cpoints => 30, cfunc => 'MAX' },
      archive => { rows => 744, cpoints => 120, cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 360, cfunc => 'MAX' },
    ],
    300 => [
      archive => { rows => 288, cpoints => 1, cfunc => 'AVERAGE' },
      archive => { rows => 672, cpoints => 3, cfunc => 'AVERAGE' },
      archive => { rows => 744, cpoints => 12, cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 72, cfunc => 'AVERAGE' },
      archive => { rows => 288, cpoints => 1, cfunc => 'MAX' },
      archive => { rows => 672, cpoints => 3, cfunc => 'MAX' },
      archive => { rows => 744, cpoints => 12, cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 72, cfunc => 'MAX' },
    ],
    600 => [
      archive => { rows => 144, cpoints => 1, cfunc => 'AVERAGE' },
      archive => { rows => 336, cpoints => 3, cfunc => 'AVERAGE' },
      archive => { rows => 744, cpoints => 6, cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'AVERAGE' },
      archive => { rows => 144, cpoints => 1, cfunc => 'MAX' },
      archive => { rows => 336, cpoints => 3, cfunc => 'MAX' },
      archive => { rows => 744, cpoints => 6, cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'MAX' },
    ],
    0   => [
      archive => { rows => 144, cpoints => 1, cfunc => 'AVERAGE' },
      archive => { rows => 336, cpoints => 3, cfunc => 'AVERAGE' },
      archive => { rows => 744, cpoints => 6, cfunc => 'AVERAGE' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'AVERAGE' },
      archive => { rows => 144, cpoints => 1, cfunc => 'MAX' },
      archive => { rows => 336, cpoints => 3, cfunc => 'MAX' },
      archive => { rows => 744, cpoints => 6, cfunc => 'MAX' },
      archive => { rows => 1460, cpoints => 36, cfunc => 'MAX' },
    ]
  };

  # my $step = (defined($attr->{STEP}) && ($attr->{STEP} eq 60 || $attr->{STEP} eq 300 || $attr->{STEP} eq 600) ) ? $attr->{STEP} : '300';
  my $step = ($attr->{STEP}) ? $attr->{STEP} : 300;

  my @datasource = ();
  my %values = ();
  my $rrdfile = $rrd_dir . "/" . $attr->{NAS_ID} . "_" . $attr->{PORT} . "_" . lc($attr->{TYPE}) . ".rrd";
  my $rrd = RRDTool::OO->new(file => $rrdfile);

  foreach my $line (@{$attr->{DATA}}) {
    push @datasource, (
      data_source => {
        name => $line->{SOURCE},
        type => $line->{TYPE}
      }
    );
    $values{$line->{SOURCE}} = $line->{DATA};
  }

  if (-f $rrdfile) {
    my $rrd_info = $rrd->info();
    if ($rrd_info->{step} != $step) {
      #if ($debug > 0) {
      print "wrong step del_graph_data: $rrdfile\n";
        if ($debug > 3) {
          show_hash($rrd_info, { DELIMITER => "\n" });
        }
      #}
      del_graph_data($attr);
    }
  }

  if (! -f $rrdfile) {
    $rrd->create(
      step => $step,
      @datasource,
      @{$archive->{$step} || $archive->{0}}
    );
  }

  if (! $rrd->update(values => \%values)) {
    print $rrd->error_message();
  }

  return 1;
}

#**********************************************************
=head2 get_graph_data($attr)

   Arguments:
     $attr
       NAS_ID   - Nas id
       PORT     - Port id
       TYPE     - Graph type: SPEED, SIGNAL, TEMPERATURE
       DS_NAMES - Array data source names
       START_TIME - Start unixtime
       END_TIME - End unixtime

   Returns:
     TRUE or FALSE

=cut
#**********************************************************
sub get_graph_data {
  my ($attr) = @_;

  if ($load_data) {
    print $load_data;
    return 0;
  }

  my $rrdfile = $var_dir . "db/rrd/" . $attr->{NAS_ID} . "_" . $attr->{PORT} . "_" . lc($attr->{TYPE}) . ".rrd";

  if (! -f $rrdfile) {
    print "Can't open file '$rrdfile' $!";
    return 0;
  }

  my $rrd = RRDTool::OO->new(file => $rrdfile);
  my $ds_info = $rrd->info()->{ds};
  my @def = ();
  my @xport = ();

  if ($FORM{DEBUG}) {
    graph_full_info({
      RRD      => $rrd,
      RRD_FILE => $rrdfile,
      DEBUG    => $FORM{DEBUG}
    });
  }

  foreach my $ds_name (@{$attr->{DS_NAMES}}) {
    if ($ds_info->{$ds_name}) {
      push @def, {
        vname  => $ds_name . "_vname",
        file   => $rrdfile,
        dsname => $ds_name,
        cfunc  => "MAX"
      };

      push @xport, {
        vname  => $ds_name . "_vname",
        legend => $ds_name
      };
    }
  }

  my $start_time = $attr->{START_TIME} || time() - 120 * 3600;
  my $end_time = $attr->{END_TIME} || time();

  if (@def) {
    if ($FORM{DEBUG}) {
      my $start_rrd_time = strftime("%Y-%m-%d %H:%M:%S", localtime($start_time));
      my $stop_rrd_time = strftime("%Y-%m-%d %H:%M:%S", localtime($end_time));
      print  " start => $start_rrd_time,   end   => $stop_rrd_time \n";
    }

    my $results = $rrd->xport(
      start => $start_time,
      end   => $end_time,
      def   => \@def,
      xport => \@xport
    );

    return $results;
  }

  return 0;
}


#**********************************************************
=head2 graph_full_info($attr)

   Arguments:
     $attr
       RRD
       FILE
     $rrd

   Return:
     TRUE or FALSE

=cut
#**********************************************************
sub graph_full_info {
  my ($attr)=@_;

  my $rrdfile = $attr->{RRD_FILE};
  my $rrd = $attr->{RRD};

  my $ds_info = $rrd->info()->{ds};

  print "FILE: $rrdfile<br>";
  foreach my $ds (sort keys %$ds_info) {
    print "<br><b>$ds</b><br>";
    foreach my $key (sort keys %{$ds_info->{$ds}}) {
      print "$key: $ds_info->{$ds}->{$key} <br>";
    }
  }

  if ($attr->{DEBUG} > 1) {
    $rrd->fetch_start();
    # Fetch stored values
    while (my ($time, $value) = $rrd->fetch_next()) {
      print "<br>" . strftime("%Y-%m-%d %H:%M:%S", localtime($time)) . ":",
        defined $value ? $value : "[undef]", "\n";
    }
  }

  my $start_rrd_time = $rrd->first();
  my $stop_rrd_time = $rrd->last();

  $start_rrd_time = strftime("%Y-%m-%d %H:%M:%S", localtime($start_rrd_time));
  $stop_rrd_time = strftime("%Y-%m-%d %H:%M:%S", localtime($stop_rrd_time));

  print "START_RRD: $start_rrd_time STOP_RRD: $stop_rrd_time<br>";

  return 1;
}

#**********************************************************
=head2 del_graph_data($attr)

   Arguments:
     $attr
       NAS_ID   - Nas id
       PORT     - Port id
       TYPE     - Graph type: SPEED, SIGNAL, TEMPERATURE

   Return:
     TRUE or FALSE

=cut
#**********************************************************
sub del_graph_data {
  my ($attr) = @_;
  my $rrdfile = $var_dir . "db/rrd/" . $attr->{NAS_ID} . "_" . $attr->{PORT} . "_" . lc($attr->{TYPE}) . ".rrd";

  if (-f $rrdfile) {
    #unlink($rrdfile) or $html->message('err', $lang{ERROR}, "Can't delete file '$rrdfile' $!");
    unlink($rrdfile) or print "Can't delete file '$rrdfile' $!";
  }

  return 1;
}


1;
