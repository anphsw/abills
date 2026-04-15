package Netlist::Tools;
use strict;
use warnings FATAL => 'all';


use parent 'Exporter';
use POSIX qw(strftime);
use Socket qw(inet_pton inet_aton AF_INET6 AF_INET);
use Math::BigInt try => 'GMP';

our $VERSION = 0.01;

our @EXPORT = qw(
  ipv6_short
  ipv6_pools
  get_expanded_v6
);

our @EXPORT_OK = qw(
  ipv6_short
  ipv6_pools
  get_expanded_v6
);


#***************************************************************
=head2 ipv6_short($ip)

  ARGUMENTS
    $ip - string representation of IPv6 in any form

  RESULT
    $shortened - string represantation of IPv6 in shortened form

  SYNOPSIS
    Shortening is defined by 2 rules

  1. All trailing zeros in each hextet can be dropped

    000A:0200:0000:0000:0000:0100:00f0:0001
      -> 1:200:::100:f0:1

  2. First group of 0-valued hextets(..:::::...) can be replaced by :: (...::...)

    A:200:::100:f0:1
      -> 1:200::100:f0:1

=cut
#***************************************************************
sub ipv6_short {
  my ($ip) = @_;

  #Normalize $ip
  $ip = get_expanded_v6($ip);

  my $short;

  #1-st rule
  my @hextets = split(':', $ip);
  for ( my $i = 0; $i < 8; $i++ ) {
    $hextets[$i] =~ s/^0*//xg;
  }
  $short = join(":", @hextets);

  #2-nd rule
  $short =~ s/:{2,}/::/x;

  return $short;
}

#***************************************************************
=head2 get_expanded_v6 ($ip) - Get extended form for ipv6 address

  Get extended form for ipv6 address

  Arguments:
    $addr - Any type of annotation for IPv6 address

  Returns:
    string - full representation of IPv6 address

=cut
#***************************************************************
sub get_expanded_v6 {
  my ($addr) = @_;

  return join(":", unpack("H4H4H4H4H4H4H4H4", inet_pton(AF_INET6, $addr)));
}


#**********************************************************
=head2 ipv6_pools($first_ip_num, $last_ip_num)

  Arguments:
    $attr
      IP
      NET_MASK
      MASK
      PD
      PD_NET_MASK
      PD_MASK

  Results:
    \@ipv6_pool

=cut
#**********************************************************
sub ipv6_pools {
  my ($attr)=@_;

  my $debug = 0;
  my $count    = 65000;
  my $pd_base  = $attr->{PD} || q{};
  my $pd_net_mask = $attr->{PD_NET_MASK} || q{};
  my $pd_mask  = $attr->{PD_MASK} || '56';

  my $wan_base = $attr->{IP} || "2001:db8:200";
  my $wan_net_mask = $attr->{NET_MASK} || '48';
  my $wan_mask = $attr->{MASK} || '64';

  my $start    = $attr->{START} || 0;

  my %ips = ();
  my @wan_ips = ();

  my ($BASE_INT, $SHIFT, $MAX_INDEX) = ipam_init($wan_base, $wan_net_mask, $wan_mask);
  my ($PD_INT, $PD_SHIFT, $PD_INDEX) = ipam_init($pd_base, $pd_net_mask, $pd_mask);

  my $last_id = ($MAX_INDEX < $start + $count - 1) ? $MAX_INDEX : $start + $count - 1;

  for my $num ($start .. $last_id) {
    my $wan_ip = get_subnet_by_index($num, $BASE_INT, $SHIFT, $MAX_INDEX);

    $wan_ip = ipv6_short($wan_ip);
    $ips{$wan_ip}{IPV6_MASK}=$wan_mask;

    if($pd_base) {
      my $pd = get_subnet_by_index($num, $PD_INT, $PD_SHIFT, $PD_INDEX);
      $ips{$wan_ip}{PD} = ipv6_short($pd);
      $ips{$wan_ip}{PD_MASK} = $pd_mask;
    }
    push @wan_ips, $wan_ip;
  }

  return \%ips, \@wan_ips;
}


#**********************************************************
=head2 ipam_init($base_prefix, $base_mask, $target_mask)

  Arguments:
    $base_prefix
    $base_mask
    $target_mask - User mask

  Results:
    $BASE_INT, $SHIFT, $MAX_INDEX

=cut
#**********************************************************
sub ipam_init {
  my ($base_prefix, $base_mask, $target_mask) = @_;

  my $BASE_INT = ipv62int($base_prefix);
  my $SHIFT = 128 - $target_mask;
  my $MAX_INDEX = Math::BigInt->new(2)->bpow($target_mask - $base_mask) - 1;

  return $BASE_INT, $SHIFT, $MAX_INDEX;
}

#**********************************************************
=head2 get_subnet_by_index($index, $BASE_INT, $SHIFT, $MAX_INDEX)

  Arguments:
    $base_prefix
    $base_mask
    $target_mask

  Results:
    $ipv6_subnet

=cut
#**********************************************************
sub get_subnet_by_index {
  my ($index, $BASE_INT, $SHIFT, $MAX_INDEX) = @_;

  #die "Index required" unless defined $index;
  my $i = Math::BigInt->new($index);

  if ($i > $MAX_INDEX) {
    die "Index out of range (max=$MAX_INDEX)";
  }

  # subnet = base + (index * 2^(128-target_mask))
  my $offset = $i->copy()->blsft($SHIFT);
  my $subnet = $BASE_INT->copy()->badd($offset);

  return int2ipv6($subnet);
}


#**********************************************************
=head2 ipv62int($ipv6)

  Arguments:
    $ipv6

  Results:
    $int

=cut
#**********************************************************
sub ipv62int {
  my ($ip) = @_;

  my @parts = split /::/x, $ip;
  my @left_  = split /:/x, ($parts[0] // '');
  my @right_ = split /:/x, ($parts[1] // '');

  my $missing = 8 - (@left_ + @right_);
  my @full = (
    @left_,
    (('0') x $missing),
    @right_
  );

  my $int = Math::BigInt->new(0);

  for my $part (@full) {
    $int <<= 16;
    $int += hex($part || 0);
  }

  return $int;
}

#**********************************************************
=head2 int2ipv6($int)

  Arguments:
    $int

  Results:
    $ipv6

=cut
#**********************************************************
sub int2ipv6 {
  my ($int) = @_;

  my @parts;
  for (1..8) {
    unshift @parts, sprintf("%x", ($int & 0xffff));
    $int >>= 16;
  }

  return join(":", @parts);
}


1;

