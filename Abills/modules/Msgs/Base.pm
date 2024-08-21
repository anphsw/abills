package Msgs::Base;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/json_former/;

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my $Msgs;

my %msgs_permissions;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  $html = $attr->{HTML} if $attr->{HTML};
  $lang = $attr->{LANG} if $attr->{LANG};

  my $self = {};

  require Msgs;
  Msgs->import();
  $Msgs = Msgs->new($db, $admin, $CONF);

  %msgs_permissions = %{$Msgs->permissions_list($admin->{AID})} if (!%msgs_permissions);

  bless($self, $class);

  return $self;
}

#***************************************************************
=head2 msgs_events($attr)

=cut
#***************************************************************
sub msgs_events {
  my $self = shift;
  my ($attr) = @_;

  my %LIST_PARAMS;
  my $events_json = [];

  if ($attr->{CLIENT_INTERFACE}) {
    my $messages_list = $Msgs->messages_list({
      UID       => $attr->{UID},
      LOGIN     => '_SHOW',
      USER_READ => '0000-00-00 00:00:00',
      GET_NEW   => $attr->{PERIOD} || '60',
      MESSAGE   => '_SHOW',
      COLS_NAME => 1
    });

    foreach my $line (@{$messages_list}) {
      push @{$events_json}, json_former({
        TYPE        => 'MESSAGE',
        MODULE      => 'Msgs',
        TITLE       => $line->{subject},
        TEXT        => $line->{message},
        CREATED     => $line->{datetime},
        MSGS_ID     => $line->{id},
        RESPONSIBLE => $line->{resposible},
        EXTRA       => "?get_index=msgs_user&full=1&chg=$line->{id}",
        SENDER      => { UID => '', LOGIN => '' }
      });
    }

    return join(", ", @{$events_json});
  }

  $LIST_PARAMS{CHAPTERS_DELIGATION} = $msgs_permissions{deligation_level};
  my $list = $Msgs->messages_list({
    PAGE_ROWS  => 3,
    CLIENT_ID  => '_SHOW',
    SUBJECT    => '_SHOW',
    MESSAGE    => '_SHOW',
    DATETIME   => '_SHOW',
    RESPOSIBLE => '_SHOW',
    ADMIN_READ => '0000-00-00 00:00:00',
    GET_NEW    => $attr->{PERIOD} || '60',
    MSGS_AID   => "!$admin->{AID}",
    %LIST_PARAMS,
    COLS_NAME  => 1
  });

  foreach my $line (@{$list}) {
    push @{$events_json}, json_former({
      TYPE        => 'MESSAGE',
      MODULE      => 'Msgs',
      TITLE       => $line->{subject},
      TEXT        => $line->{message},
      CREATED     => $line->{datetime},
      MSGS_ID     => $line->{id},
      RESPONSIBLE => $line->{resposible},
      EXTRA       => "?get_index=msgs_admin&full=1&chg=$line->{id}" . ($line->{uid} ? "&UID=$line->{uid}" : ''),
      SENDER      => { UID => $line->{uid}, LOGIN => $line->{client_id} }
    });
  }

  my @skip_status = ('!5', '!9');
  my $closed_status = $Msgs->status_list({ TASK_CLOSED => 1, COLS_NAME => 1 });
  map push(@skip_status, "!$_->{id}"), @{$closed_status};

  # Planned work
  my $responsible_and_planned_for_today_list = $Msgs->messages_list({
    PAGE_ROWS      => 3,
    SUBJECT        => '_SHOW',
    MESSAGE        => '_SHOW',
    CLIENT_ID      => '_SHOW',
    RESPOSIBLE     => $admin->{AID},
    PLAN_FROM_DATE => $main::DATE,
    PLAN_TO_DATE   => $main::DATE,
    PLAN_TIME      => '<=' . $main::TIME,
    STATE          => join(',', @skip_status),
    %LIST_PARAMS,
    COLS_NAME      => 1,
    COLS_UPPER     => 0
  });

  foreach my $line (@{$responsible_and_planned_for_today_list}) {
    $line->{subject} //= '';
    $line->{subject} = $lang->{PLANNED} . ' : ' . $line->{subject};

    push @{$events_json}, json_former({
      TYPE        => 'MESSAGE',
      MODULE      => 'Msgs',
      TITLE       => $line->{subject},
      TEXT        => $line->{message},
      CREATED     => $line->{datetime},
      MSGS_ID     => $line->{id},
      RESPONSIBLE => $line->{resposible},
      EXTRA       => "?get_index=msgs_admin&full=1&chg=$line->{id}" . ($line->{uid} ? "&UID=$line->{uid}" : ''),
      SENDER      => { UID => $line->{uid}, LOGIN => $line->{client_id} }
    });
  }

  return join(', ', @{$events_json});
}

#**********************************************************
=head2 msgs_user_del($uid, $attr) - Delete user  from module

=cut
#**********************************************************
sub msgs_user_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if !$attr->{USER_INFO} || !$attr->{USER_INFO}{UID};

  $Msgs->message_del({ UID => $attr->{USER_INFO}{UID}, COMMENTS => $attr->{USER_INFO}{COMMENTS} });

  return 1;
}

1;