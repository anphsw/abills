package Equipment::Misc;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Equipment::Misc

=head2 SYNOPSIS

  Equipment miscellaneous functions

=cut

use Exporter;
use base 'Exporter';

our @EXPORT = qw/
  equipment_get_telnet_tpl
  equipment_add_color
/;
our @EXPORT_OK = @EXPORT;

#**********************************************************
=head2 equipment_get_telnet_tpl($attr) - read telnet template from file and substitute params

  Arguments:
    $attr
      TEMPLATE - telnet template filename
      DEBUG - debug level
      ... - any params, which will be used for substitution in template

  Returns:
    \@reg_tpl - array of strings, template with substituted params

=cut
#**********************************************************
sub equipment_get_telnet_tpl {
  my ($attr) = @_;

  my $template = $attr->{TEMPLATE};
  my $debug    = $attr->{DEBUG} || 0;

  my @reg_tpl;

  my $base_dir = $main::base_dir || '/usr/abills/';

  my $template_path = $base_dir . 'Abills/modules/Equipment/snmp_tpl/' . $template;
  if (-f $template_path) {
    if ($debug > 3) {
      print "Tpl: $template_path\n";
    }

    my $content = '';
    open(my $fh, '<', $template_path) || return [];

    while(<$fh>) {
      my $line = $_;
      if ($line && $line !~ /\#/xm) {
        while($line =~ /\%([A-Z0-9\_]+)\%/xig) {
          my $param = $1;
          if(defined($attr->{$param})) {
            print "$param -> $attr->{$param}\n" if($debug > 4);
            $line =~ s/\%$param\%/$attr->{$param}/xg;
          }
          else {
            if($debug < 6) {
              $line =~ s/\%$param\%//xg;
            }
            print "NO input params '$param'\n";
          }
        }

        $content .= $line;
      }
    }

    close($fh);
    print $content if($debug > 3);

    @reg_tpl = split(/\n/x, $content);
  }

  return \@reg_tpl;
}

#**********************************************************
=head2 equipment_add_color($data)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub equipment_add_color {
  my ($data) = @_;

  $data = 0 if ($data !~ /\d+/xm);

  our %html_color = (
    'red'       => '#f56954',
    'green'     => '#00a65a',
    'orange'    => '#f39c12',
    'blue'      => '#00c0ef',
    'dark_blue' => '#3c8dbc'
  );

  if ($data < 30) {
    $data .= ':' . $html_color{dark_blue};
  }
  elsif ($data < 50) {
    $data .= ':' . $html_color{green};
  }
  elsif ($data < 80) {
    $data .= ':' . $html_color{orange};
  }
  else {
    $data .= ':' . $html_color{red};
  }

  return $data;
}

1;
