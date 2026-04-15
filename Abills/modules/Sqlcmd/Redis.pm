# package Sqlcmd::Redis;


use strict;
use warnings FATAL => 'all';

our (
  %conf
);

#**********************************************************
=head2 sqlcmd_redis($attr) -

  Arguments:

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub sqlcmd_redis {

  use Redis;
  my $Redis = Redis->new(server => $conf{REDIS_DB}, reconnect => 10, every => 200);

  my $count = $Redis->dbsize;
  print "Count: $count<br>\n";

  my @keys = $Redis->keys('user:*');

  foreach my $key (@keys) {
    print "'$key'<br>\n";

    my %hash = $Redis->hgetall($key);

    foreach my $field (sort keys %hash) {
      my $value = $hash{$field};
      print "$field => $value<br>\n";
    }
    print "<br>";
  }

  print "OK";

  return 1;
}

1;