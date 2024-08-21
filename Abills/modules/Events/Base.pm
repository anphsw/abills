package Events::Base;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/json_former/;

my ($admin, $CONF, $db);
my Abills::HTML $html;
my $lang;
my $Events;

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

  require Events;
  Events->import();
  $Events = Events->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 events_events($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    JSON array string

=cut
#**********************************************************
sub events_events {
  my $self = shift;
  my ($attr) = @_;

  my @events_list = ();

  if ($attr->{CLIENT_INTERFACE}) {
    return '';
  }

  my $events_list = $Events->events_list({
    STATE_ID         => 1,
    AID              => $admin->{AID},
    SHOW_ALL_COLUMNS => 1
  });

  foreach my $event (@{$events_list}) {
    $event->{message} = ::_translate($event->{message} || '');
    $event->{subject} = $event->{title} || $event->{module} || '';
    $event->{subject} = ::_translate($event->{subject});
    $event->{extra} ||= "?get_index=events_main&full=1&chg=$event->{id}";

    my $subject = $event->{subject} || $event->{title} || $lang->{ERR_NO_TITLE};
    my $message = $event->{message} || $event->{comments} || $lang->{ERR_NO_MESSAGE};

    push @events_list, json_former({
      TYPE        => "EVENT",
      TITLE       => $subject,
      CREATED     => $event->{created},
      STATE       => $event->{state_id},
      TEXT        => $message,
      EXTRA       => $event->{extra},
      MODULE      => $event->{module},
      GROUP_ID    => $event->{group_id},
      ID          => $event->{id},
      NOTICED_URL => "?get_index=events_seen_message&json=1&AJAX=1&header=2&ID=$event->{id}"
    });
  }

  return join(", ", @events_list);
}

1;