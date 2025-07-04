package Internet::Diagnostic;
=head1 NAME

  Internet Diagnostic functions

=cut

use strict;
use warnings FATAL => 'all';
use parent 'Exporter';
use Abills::Filters;
use Abills::Base qw(cmd startup_files);

our (%EXPORT_TAGS, %conf);
our $VERSION = 1.00;

our @EXPORT = qw(
  get_oui_info
  host_diagnostic
  host_whois
);

our @EXPORT_OK = qw(
  get_oui_info
  host_diagnostic
  host_whois
);

#our Abills::HTML $html;

#**********************************************************
=head2 get_oui_info($mac); - Get MAC information
  Arguments:
    $mac - mac

  Returns:
    vendor string
=cut
#**********************************************************
sub get_oui_info {
  my ($mac) = @_;

  my $base_dir = $conf{base_dir} || '/usr/abills/';
  my $result = '';
  $mac =~ s/[\-:\.]//xg;
  $mac = uc($mac);
  $mac =~ m/^([0-9A-F]{6})/x;
  my $mac_prefix = $1;
  return '' if (! $mac_prefix);

  my $content = '';
  open(my $fh, '<', "$base_dir/misc/oui.txt") or die "Can't open file 'oui.txt' $!";
  while(<$fh>) {
    $content .= $_;
  }
  close($fh);

  my @content_arr = split(/\n\r?\n\r?/x, $content);
  my %vendors_hash = ();
  foreach my $section (@content_arr) {
    my @rows = split(/\n/x, $section);
    if ($#rows > 0){
      $rows[1] =~ m/([A-F0-9]{6})\s+\(base 16\)\s+(.+)/x;
      my $db_mac_prefix = $1;
      my $vendor_info = $2;
      $vendors_hash{$db_mac_prefix} = $vendor_info;
    }
  }

  $result = $vendors_hash{$mac_prefix} || '';

  return $result;
}

#**********************************************************
=head2 host_diagnostic($ip, $attr); - Diagnostic host activity

  Diagnostic methods:
    ping (Default)
  Arguments:
    IP      - IP address of host
    QUITE   - Quite mode
    TIMEOUT - Timeout
    $attr   -
  Return:
    $ret_message

=cut
#**********************************************************
sub host_diagnostic {
  my($ip, $attr) = @_;
  #my $timeout  = $attr->{TIMEOUT} || 3;

  my $message = q{};

  if ($ip && $ip =~ m/^$IPV4$/x){
    my $tpl_dir =  $conf{TPL_DIR} || '/usr/abills/Abills/templates/';

    my $pathes = startup_files( { TPL_DIR => $tpl_dir } );
    my $PING = $pathes->{PING} || 'ping';

    my $res = cmd( "$PING -c 5 $ip", { timeout => 11 } );
    if ( !$attr->{QUITE} ){
      $message = "$PING -c 5 $ip\nRESULT:\n" .$res;
    }

    if($attr->{RETURN_RESULT}){
      return $res ne '' ? 1 : 0;
    }
  }
  else {
    $message = 'WRONG_DATA: '. (($ip) ? $ip : '') . "' ($IPV4)";
  }

  return $message;
}


#**********************************************************
=head2 host_diagnostic($ip, $attr); - Diagnostic host activity

  Diagnostic methods:
    ping (Default)
  Arguments:
    IP      - IP address of host
    QUITE   - Quite mode
    TIMEOUT - Timeout
    $attr   -
  Return:
    $ret_message

=cut
#**********************************************************
sub host_whois {
  my($ip, $attr) = @_;
  #my $timeout  = $attr->{TIMEOUT} || 3;

  my $message = q{};

  if ($ip && $ip =~ m/^$IPV4$/x){
    my $tpl_dir =  $conf{TPL_DIR} || '/usr/abills/Abills/templates/';

    my $pathes = startup_files( { TPL_DIR => $tpl_dir } );
    my $WHOIS = $pathes->{WHOIS} || 'whois';

    my $res = cmd( "$WHOIS $ip", { timeout => 11 } );
    if ( !$attr->{QUITE} ){
      $message = "$WHOIS -c 5 $ip\nRESULT:\n" .$res;
    }

    if($attr->{RETURN_RESULT}){
      return $res ne '' ? 1 : 0;
    }
  }
  else {
    $message = 'WRONG_DATA: '. (($ip) ? $ip : '') . "' ($IPV4)";
  }

  return $message;
}

1;