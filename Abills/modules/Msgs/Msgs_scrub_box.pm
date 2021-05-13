=head1 Msgs_scrub_box

  Msgs Msgs_scrub_box

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Misc;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html
);

my @priority_colors = ('#8A8A8A', $_COLORS[8], $_COLORS[9], '#E06161', $_COLORS[6]);
my @priority = ($lang{VERY_LOW}, $lang{LOW}, $lang{NORMAL}, $lang{HIGH}, $lang{VERY_HIGH});
my %panel_color = ( 1 => 'card-danger', 2 => 'card-success', 4 => 'card-warning' );

my $Msgs  = Msgs->new($db, $admin, \%conf);

#**********************************************************
=head2 msgs_scrub_box() -

=cut
#**********************************************************
sub msgs_scrub_box {

  my ($msgs_list, $msgs_status) = _scrub_data_proccess();

  my $count_status = $#{ $msgs_status } + 1;

  my $statuses = $Msgs->status_list({ COLS_NAME => 1 });

  map $_->{name} = _translate($_->{name}), @{ $statuses };

  my $status_sel = $html->form_select(
    'MSGS_STATUS',
    {
      SELECTED       => $FORM{MSGS_STATUS},
      SEL_LIST       => $statuses,
      SEL_KEY        => 'id',
      SEL_VALUE      => 'name',
      SEL_OPTIONS    => { 0 => $lang{OPEN} },
      MULTIPLE       => 1,
      NO_ID          => 1,
    }
  );

  _scrub_tpl_workind($msgs_list, {
    MSGS_BODY   => $msgs_status,
    COUNT       => $count_status,
    STATUS_SEL  => $status_sel,
  });

  return 1;
}

#**********************************************************
=head2 _scrub_data_proccess() -

=cut
#**********************************************************
sub _scrub_data_proccess {
  my $msgs_list = $Msgs->messages_list({
    CHAPTER         => '_SHOW',
    CLIENT_ID       => '_SHOW',
    SUBJECT         => '_SHOW',
    STATE           => '_SHOW',
    DATE            => '_SHOW',
    PRIORITY_ID     => '_SHOW',
    COLS_NAME       => 1,
    PAGE_ROWS       => 30000,
  });

  my $status_select = '0,6,5,4';
  if ($FORM{MSGS_STATUS}) {
    $status_select = $FORM{MSGS_STATUS};
  }

  my $status_list = $Msgs->status_list({
    ID          => $status_select,
    _MULTI_HIT  => 1,
    COLS_NAME   => 1
  });

  return ($msgs_list, $status_list);
}

#**********************************************************
=head2 _scrub_tpl_workind() -

=cut
#**********************************************************
sub _scrub_tpl_workind {
  my ($msgs_list, $attr) = @_;

  my $index_msgs = get_function_index('msgs_admin');
  my $index_user = get_function_index('form_users');

  $attr->{COUNT} = 4 unless ($FORM{MSGS_STATUS});
  $attr->{COUNT} = 4 if ($attr->{COUNT} > 4);

  my $width = 12 / $attr->{COUNT};

  my $card_template = _create_cards_msgs({
    INDEX_MSGS  => $index_msgs,
    INDEX_USER  => $index_user,
    MSGS_LIST   => $msgs_list,
    MSGS_BODY   => $attr->{MSGS_BODY},
    COUNT       => $attr->{COUNT},
    WIDTH       => $width,
  });

  $html->tpl_show(_include('msgs_scrub_box_page', 'Msgs'), {
    MSGS_BODY       => $card_template,
    STATUS_SELECT   => $attr->{STATUS_SEL},
    MSGS_INDEX      => $index_msgs,
  });

  return 1;
}

#**********************************************************
=head2 _create_cards_msgs() -

=cut
#**********************************************************
sub _create_cards_msgs {
  my ($attr) = @_;

  my $status_template = '';
  my $messages_template = '';

  for (my $status = 0; $status < $attr->{COUNT}; $status++) {
    my $status_id = $attr->{MSGS_BODY}->[ $status ]{id};

    foreach my $message ( @{$attr->{MSGS_LIST}} ) {
      next unless (defined($status_id) && $message->{state} eq $status_id);
      my $msgs_url       = "?index=$attr->{INDEX_MSGS}&UID=$message->{uid}&chg=$message->{id}#last_msg";
      my $user_card      = "?index=$attr->{INDEX_USER}&UID=$message->{uid}";
      my $priority_name  = $priority[ $message->{priority_id} ];

      $messages_template .= $html->tpl_show(_include('msgs_scrub_box_messages', 'Msgs'), {
        ID            => $message->{id},
        USER          => $message->{client_id},
        SUBJECT       => $message->{subject},
        MSGS_OPEN     => $msgs_url,
        USER_CARD     => $user_card,
        UID           => $message->{uid},
        DATE          => $message->{date},
        PRIORITY_ID   => $html->color_mark($priority_name, $priority_colors[ $message->{priority_id} ]),
        STATUS_COLOR  => $panel_color{ $status_id } || 'card-info',
      }, { OUTPUT2RETURN => 1 });

    }

    $status_template .= $html->tpl_show(_include('msgs_scrub_box_status', 'Msgs'), {
      STATUS_NAME => _translate($attr->{MSGS_BODY}->[ $status ]{name}),
      MSGS_CARD   => $messages_template,
      WIDTH       => $attr->{WIDTH},
      ID          => $status_id,
    }, { OUTPUT2RETURN => 1 });

    $messages_template = '';

  }

  return $status_template;
}

1;