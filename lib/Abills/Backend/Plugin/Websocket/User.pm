package Abills::Backend::Plugin::Websocket::User;
use strict;
use warnings FATAL => 'all';

our ($Log, $db, $admin, %conf);
use Abills::Backend::Defs;

use Abills::Backend::Plugin::Websocket::Client;
use parent 'Abills::Backend::Plugin::Websocket::Client';

use Users;
my Users $user = Users->new($db, $admin, \%conf);

my %cache = (
  uid_by_sid => {}
);

#**********************************************************
=head2 authenticate($chunk)

  Authentificate admin by cookies

=cut
#**********************************************************
sub authenticate {
  my ($chunk) = @_;

  if ($chunk && $chunk =~ /^Cookie: .*$/m) {
    # TODO LOGIN WITH Cookie
    # my (@sids) = $chunk =~ /sid=([a-zA-Z0-9]*)/gim;
    #
    # return -1 unless (scalar @sids);
    # my $aid = undef;
    # foreach my $sid (@sids) {
    #   $Log->debug("Will try to authentificate admin with sid $sid") if (defined $Log);
    #
    #   # Try to retrieve from cache
    #   if ($aid = $cache{aid_by_sid}->{$sid}) {
    #     $Log->debug("cache hit $sid") if (defined $Log);
    #     return $aid;
    #   }
    #
    #   my $admin_with_this_sid = $admin->online_info({ SID => $sid, COLS_NAME => 1 });
    #
    #   if ($admin->{TOTAL}) {
    #     $aid = $admin_with_this_sid->{AID};
    #     $cache{aid_by_sid}->{$sid} = $aid;
    #     return $aid;
    #   }
    # }
    return -1;
  }
  elsif ($chunk && $chunk =~ /(?<=\bUSERSID:\s)(\w+)/gim) {
    my $uid = undef;

    if ($uid = $cache{uid_by_sid}->{$1}) {
      $Log->debug("cache hit $1") if (defined $Log);
      return $uid;
    }

    my $user_with_this_sid = $user->web_session_info({ SID => $1 });

    if ($user->{TOTAL}) {
      $uid = $user_with_this_sid->{UID};
      $cache{uid_by_sid}->{$1} = $uid;
      return $uid;
    }
  }

  return -1;
}

1;
