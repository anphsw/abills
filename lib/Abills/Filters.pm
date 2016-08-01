package Abills::Filters v2.0.2;

=head1 NAME

Abills::Filters - AbillS Filters function

=head1 SYNOPSIS

    use Abills::Filters;

=cut

use strict;
use vars qw(
$IPV4
$IPV4CIDR
$HD
$V6P1
$V6P2
$IPV6
$HOCT
$MAC
$DEFAULT_DATE_FORMAT
$EMAIL_EXPR
);

use base 'Exporter';
use Encode;
use POSIX qw(locale_h);

our @EXPORT = qw(
_expr
_utf8_encode
_mac_former
$IPV4
$IPV4CIDR
$HD
$V6P1
$V6P2
$IPV6
$HOCT
$MAC
$DEFAULT_DATE_FORMAT
$EMAIL_EXPR
);

our @EXPORT_OK = qw(
_expr
_utf8_encode
_mac_former
$IPV4
$IPV4CIDR
$HD
$V6P1
$V6P2
$IPV6
$HOCT
$MAC
$DEFAULT_DATE_FORMAT
$EMAIL_EXPR
);

our %EXPORT_TAGS = ();

#Check IP
$IPV4 = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';
#Check ip new model
$IPV4 = '((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))';
$IPV4CIDR = '^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}(?:\/\d{1,2})?$';
$HD   = '[0-9A-Fa-f]{1,4}'; # Hexadecimal digits, 2 bytes
$V6P1 = "(?:$HD:){7}$HD";
$V6P2 = "(?:$HD(?:\:$HD){0,6})?::(?:$HD(?:\:$HD){0,6})?";
$IPV6 = "$V6P1|$V6P2"; # Note: Not strictly a valid V6 address
$HOCT = '[0-9A-Fa-f]{2}';
$MAC  = "$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT\[.:-\]?$HOCT";
$DEFAULT_DATE_FORMAT='\d{4}-\d{2}-\d{2}';
$EMAIL_EXPR = '^(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';

#**********************************************************
=head2 _expr($value, $expr_tpl) - Expration

  Filter expr

  Arguments:
    $value
    $expr_tpl

  Returns:
    Return result string

=cut
#**********************************************************
sub _expr {
  my ($value, $expr_tpl)=@_;

  if (! $expr_tpl) {
    return $value;
  }

  my @num_expr = split(/;/, $expr_tpl);

  for (my $i = 0 ; $i <= $#num_expr ; $i++) {
    my ($left, $right) = split(/\//, $num_expr[$i]);
    my $r = ($right eq '$1') ? $right : eval "\"$right\"";
    if ($value =~ s/$left/eval $r/e) {
      return $value;
    }
  }

  return $value;
}

#**********************************************************
=head2 _utf8_encode($value, $attr) - Normilize utf string

  Attributes:
    $value  - Valie for normalise
    $attr

  Returns:

    return normilize string
=cut
#**********************************************************
sub _utf8_encode {
  my ($value)=@_;

  Encode::_utf8_off($value);

  return $value;
}


#**********************************************************
=head2 _mac_former($mac, $attr) - Convert any mac format to xx:xx:xx;xx:xx:xx

   Arguments:
     $mac  - MAC string
     $attr
       BIN   - Convert fom binari string

   Results:
     MAC (hh:hh:hh:hh:hh:hh)


=cut
#**********************************************************
sub _mac_former {
  my ($mac, $attr) = @_;

  if (! $mac ) {
    $mac ='00:00:00:00:00:00';
  }
  #From hex string
  elsif($attr->{BIN}) {
  	$mac = join(':', unpack("H2H2H2H2H2H2", $mac));
  }
  # 111.222.33.444.55.66
  elsif($mac =~ /\d+\.\d+\.\d+\.\d+\.\d+\.\d+/) {
  	my @mac_arr = ();
    foreach my $val (split(/\./, $mac)) {
      push @mac_arr, unpack("H2", pack("c", $val));
    }

    $mac = join(':', @mac_arr);
  }
  # xxxx.xxxx.xxxx
  elsif ($mac =~ m/([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})\.([0-9a-f]{2})([0-9a-f]{2})/i) {
    $mac = "$1:$2:$3:$4:$5:$6";
  }
  # xXXxxXXxxXX
  elsif ($mac =~ m/^([0-9a-f]{1})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i) {
    $mac = "0$1:$2:$3:$4:$5:$6";
  }
  # XXxxXXxxXX
  elsif ($mac =~ m/^([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})$/i) {
    $mac = "00:$1:$2:$3:$4:$5";
  }
  # xxXXxxXXxxXX
  elsif ($mac =~ m/([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i) {
    $mac = "$1:$2:$3:$4:$5:$6";
  }
  elsif ($mac =~ s/:$//) {

  }
  # xx-XX-xx-XX-xx-XX
  elsif ($mac =~ s/[\.\-]/:/g) {

  }

  return lc($mac);
}

1;
