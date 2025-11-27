#!/usr/bin/perl

use strict;
use warnings;

use FindBin qw( $Bin );
use lib "$Bin/../../lib", '../', '../../Abills/mysql';
$Bin .= '/../';
use Abills::Base qw(parse_arguments clearquotes);
require Abills::Misc;

our (
  %RAD_REQUEST,
  %RAD_REPLY,
  $RAD_PAIRS,
  %conf
);

my $argv = parse_arguments(\@ARGV);
my $debug = $argv->{DEBUG} || 1;

do "rlm_perl.pl";

# if ($debug > 3) {
#   $main::conf{AUTH_EXPR_DEBUG}=4;
# }

my $request_ = <<"[END]";
(0)   DHCP-Opcode = Client-Message
(0)   DHCP-Hardware-Type = Ethernet
(0)   DHCP-Hardware-Address-Length = 6
(0)   DHCP-Hop-Count = 1
(0)   DHCP-Transaction-Id = 41732843
(0)   DHCP-Number-of-Seconds = 0
(0)   DHCP-Flags = Broadcast
(0)   DHCP-Client-IP-Address = 0.0.0.0
(0)   DHCP-Your-IP-Address = 0.0.0.0
(0)   DHCP-Server-IP-Address = 0.0.0.0
(0)   DHCP-Gateway-IP-Address = 100.64.1.1
(0)   DHCP-Client-Hardware-Address = 30:b5:c2:c8:8d:7d
(0)   DHCP-Message-Type = DHCP-Discover
(0)   DHCP-DHCP-Maximum-Msg-Size = 1024
(0)   DHCP-Client-Identifier = 0x0130b5c2c88d7d
(0)   DHCP-Hostname = "TL-WR1043"
(0)   DHCP-Vendor-Class-Identifier = 0x4d53465420352e30
(0)   DHCP-Parameter-Request-List = DHCP-Subnet-Mask
(0)   DHCP-Parameter-Request-List = DHCP-Router-Address
(0)   DHCP-Parameter-Request-List = DHCP-Domain-Name-Server
(0)   DHCP-Parameter-Request-List = DHCP-Domain-Name
(0)   DHCP-Parameter-Request-List = DHCP-Static-Routes
(0)   DHCP-Parameter-Request-List = DHCP-Vendor
(0)   DHCP-Parameter-Request-List = DHCP-NETBIOS-Name-Servers
(0)   DHCP-Parameter-Request-List = DHCP-NETBIOS-Node-Type
(0)   DHCP-Parameter-Request-List = DHCP-NETBIOS
(0)   DHCP-Parameter-Request-List = DHCP-Classless-Static-Route
(0)   DHCP-Parameter-Request-List = 249
(0)   DHCP-Relay-Remote-Id = 0x020a00006440010102000000
(0)   DHCP-Subscriber-Id = "0000"
(0)   DHCP-Network-Subnet = 100.64.1.1/32
[END]

if ($ARGV[0]) {
  $request_ = file_op({
    FILENAME => $ARGV[0],
    PATH     => ".."
  });
}

#**********************************************************
=head2 make_tp($request) - Make request

  Arguments:
    $request

  Returns:
    $RAD_PAIRS

=cut
#**********************************************************
sub _mk_request_pairs {
  my ($request) = @_;

  my @req_lines = split(/\n/x, $request);

  foreach my $req (@req_lines) {
    my ($left_side, $right_side) = $req =~ /^\(?\d{0,10}\)?\s+(\S+)\s+=\s+(.+)/xm;

    next if (! $left_side);

    if ($debug > 1) {
      print "$left_side, $right_side\n";
    }

    $RAD_REQUEST{$left_side} = clearquotes($right_side);
  }

  return 1;
}

#**********************************************************
=head2 _mk_result() - Show result

  Arguments:

  Returns:
    $RAD_REPLY

=cut
#**********************************************************
sub _mk_result {

  foreach my $left_key (keys %RAD_REPLY) {
    my $right_side = $RAD_REPLY{$left_key};

    if (ref $right_side eq 'ARRAY') {
      $right_side = join("\n  $left_key = ", @$right_side);
    }

    print "  $left_key = $right_side\n";
  }

  return 1;
}

_mk_request_pairs($request_);
my $result = 0;
if ($request_ =~ /DHCP\-/xm) {
  $result = post_auth();
}
if ($request_ =~ /Acct\-Status\-Type/xm) {
  $result = accounting();
}
else {
  $result = authenticate();
}

print "Result: $result\n";
_mk_result();

1;