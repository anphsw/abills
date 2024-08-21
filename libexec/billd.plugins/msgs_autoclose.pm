=head1 NAME

 billd plugin

 DESCRIBE: billd plugin automatic closing of old messages

=head ARGIMENTS

  NOTIFY=1
  DATE="YYYY-MM-DD"

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $argv,
  %lang,
  %LIST_PARAMS,
  $debug
);


my %list_params = %LIST_PARAMS;

use Msgs;
use Msgs::Notify;
use Abills::Templates qw/templates/;
use Abills::Base qw/date_diff/;
our $html = Abills::HTML->new({ CONF => \%conf });

my $date = $argv->{DATE} || $DATE;
my $Msgs = Msgs->new($db, $Admin, \%conf);
my $Notify = Msgs::Notify->new($db, $Admin, \%conf, { HTML => $html });

do "../language/$html->{language}.pl";
do 'Abills/Misc.pm';
our $admin = $Admin;

msgs_autoclose();

#**********************************************************
=head2 msgs_autoclose()

=cut
#**********************************************************
sub msgs_autoclose {
  load_module('Msgs', $html);
  %LIST_PARAMS = %list_params;
  my $closed = 0;
  my $notified = 0;

  if ($debug > 6) {
    $Msgs->{debug} = 1;
  }

  $Msgs->chapters_list({
    AUTOCLOSE => '>0',
    LIST2HASH => 'id,autoclose'
  });

  if ($Msgs->{TOTAL} < 1) {
    _log('LOG_INFO', "NOT Exists autoclose chapters");
    return 1;
  }

  my $autoclose_list = $Msgs->{list_hash};

  my $messages_list = $Msgs->messages_list({
    LAST_REPLIE_DATE => '_SHOW',
    REPLY_STATUS     => '!3',
    CHAPTER          => join(';', keys %{$autoclose_list}),
    STATE            => 6,
    RESPOSIBLE       => '_SHOW',
    DATE             => '<'.$date,
    PAGE_ROWS        => 999999,
    COLS_NAME        => 1,
    %LIST_PARAMS,
    DISABLE          => undef
  });

  foreach my $message (@$messages_list) {
    next if (!$message->{last_replie_date} || $message->{last_replie_date} eq '0000-00-00 00:00:00');

    my $period = $autoclose_list->{$message->{chapter_id}};
    my $half_period = int($period / 2);

    if (date_diff($message->{last_replie_date}, $date) == $half_period
     || ($argv->{NOTIFY} && date_diff($message->{last_replie_date}, $date) > $half_period)) {
      my $message_body = $html->tpl_show(templates('form_msgs_autoclose'), { MSGS_ID => $message->{id} }, {
        OUTPUT2RETURN      => 1,
        SKIP_DEBUG_MARKERS => 1
      });

      _log('LOG_INFO', "NOTIFY UID: $message->{uid} ID: $message->{id} LAST_REPLY: $message->{last_replie_date}");

      $notified++;
      if ($debug < 5) {
        $Msgs->message_reply_add({
          ID         => $message->{id},
          REPLY_TEXT => $message_body,
          STATE      => 3,
          UID        => $message->{uid},
          AID        => $message->{resposible},
        });

        $Notify->notify_user({
          REPLY_ID => $Msgs->{INSERT_ID},
          MSG_ID   => $message->{id},
          MESSAGE  => $message_body,
          UID      => $message->{uid}
        });
      }

      next;
    }

    if (date_diff($message->{last_replie_date}, $date) > $period) {
      my $message_body = $html->tpl_show(templates('form_msgs_autoclose2'), { MSGS_ID => $message->{id} }, {
        OUTPUT2RETURN      => 1,
        SKIP_DEBUG_MARKERS => 1
      });

      _log('LOG_INFO', "CLOSE UID: $message->{uid} ID: $message->{id} LAST_REPLY: $message->{last_replie_date}");
      $closed++;

      if ($debug < 5) {
        $Msgs->message_reply_add({
          ID         => $message->{id},
          REPLY_TEXT => $message_body,
          STATE      => 3,
          UID        => $message->{uid},
          AID        => $message->{resposible},
        });

        next if $Msgs->{error};

        $Msgs->message_change({
          ID         => $message->{id},
          ADMIN_READ => "$DATE $TIME",
          STATE      => 2,
          CLOSED_DATE=> "$DATE $TIME"
        });

        $Notify->notify_user({
          REPLY_ID => $Msgs->{INSERT_ID},
          MSG_ID   => $message->{id},
          MESSAGE  => $message_body,
          UID      => $message->{uid},
          STATE    => 2
        });
      }
      next;
    }
  }

  _log('LOG_INFO', "NOTIFY: $notified CLOSED: $closed");

  return 1;
}

1;