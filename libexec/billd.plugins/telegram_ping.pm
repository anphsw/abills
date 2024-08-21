=head1 NAME

  Telegram ping send

=head1 EXAMPLES

  billd telegram_ping

=cut

use strict;
use warnings;
use FindBin '$Bin';

push @INC, $Bin . '/../', $Bin . '/../Abills/';

use Abills::Sender::Core;

our (
  $debug,
  %conf,
  $Admin,
  $db,
  $argv,
  %lang,
  $base_dir,
);

my $Sender = Abills::Sender::Core->new($db, $Admin, \%conf);
do "$base_dir/Abills/modules/Telegram/lng_$conf{default_language}.pl";

our $html = Abills::HTML->new({ CONF => \%conf, LANG => \%lang });

telegram_ping_users();

#**********************************************************
=head2 telegram_ping_users()

=cut
#**********************************************************
sub telegram_ping_users {

  use Telegram::db::Telegram;
  my $Telegram_db = Telegram->new($db, $Admin, \%conf);

  my $users_list = $Telegram_db->list({
    UID                        => '!',
    PING_COUNT                 => '<3',
    FN                         => '_SHOW',
    MINUTES_SINCE_LAST_CONTACT => '>=2;<1440',
    COLS_NAME                  => '_SHOW'
  });

  foreach my $user (@{$users_list}) {
    $Sender->send_message({
      MESSAGE     => $lang{TELEGRAM_PING_MESSAGE},
      SENDER_TYPE => 'Telegram',
      UID         => $user->{uid}
    });

    $Telegram_db->change({
      ID         => $user->{id},
      PING_COUNT => $user->{ping_count} + 1
    });
  }
}

1;