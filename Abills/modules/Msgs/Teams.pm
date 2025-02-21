=head1 Teams

  Msgs: Teams

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  $libpath
);

my $Msgs = Msgs->new($db, $admin, \%conf);

require Abills::Template;
my $Templates = Abills::Template->new($db, $admin, \%conf, {
  html    => $html,
  lang    => \%lang,
  libpath => $libpath
});

#**********************************************************
=head2 msgs_teams()

=cut
#**********************************************************
sub msgs_teams {

  $Msgs->{ACTION} = 'add';
  $Msgs->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Msgs->msgs_team_add(\%FORM);
    if (!_error_show($Msgs) && $Msgs->{INSERT_ID}) {
      my $team_id = $Msgs->{INSERT_ID};
      $html->message('info', $lang{ADDED});
      $Msgs->msgs_team_address_change({
        DISTRICT_IDS => $FORM{DISTRICT_ID} ? [ split(',\s?', $FORM{DISTRICT_ID}) ] : [],
        STREET_IDS   => $FORM{STREET_ID} ? [ split(',\s?', $FORM{STREET_ID}) ] : [],
        BUILD_IDS    => $FORM{BUILD_ID} ? [ split(',\s?', $FORM{BUILD_ID}) ] : [],
        TEAM_ID      => $team_id
      });
      $Msgs->msgs_team_members_change({
        AIDS    => $FORM{AID} ? [ split(',\s?', $FORM{AID}) ] : [],
        TEAM_ID => $team_id
      });
    }
  }
  elsif ($FORM{chg}) {
    $Msgs->msgs_team_info($FORM{chg});
    $Msgs->{ACTION} = 'change';
    $Msgs->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form} = 1;

    $Msgs->{TEAM_ADDRESS_LIST} = $Msgs->msgs_team_address_list({ TEAM_ID => $FORM{chg}, COLS_NAME => 1 });
  }
  elsif ($FORM{change}) {
    $Msgs->msgs_team_change(\%FORM);
    if (!_error_show($Msgs)) {
      $html->message('info', $lang{CHANGED});
      if (!$FORM{CLEAR}) {
        $Msgs->msgs_team_address_change({
          DISTRICT_IDS => $FORM{DISTRICT_ID} ? [ split(',\s?', $FORM{DISTRICT_ID}) ] : [],
          STREET_IDS   => $FORM{STREET_ID} ? [ split(',\s?', $FORM{STREET_ID}) ] : [],
          BUILD_IDS    => $FORM{BUILD_ID} ? [ split(',\s?', $FORM{BUILD_ID}) ] : [],
          TEAM_ID      => $FORM{ID}
        });
      }
      else {
        $Msgs->msgs_team_address_del({ TEAM_ID => $FORM{ID} });
      }
      $Msgs->msgs_team_members_change({
        AIDS    => $FORM{AID} ? [ split(',\s?', $FORM{AID}) ] : [],
        TEAM_ID => $FORM{ID}
      });
    }
  }
  elsif ($FORM{del}) {
    $Msgs->msgs_team_del({ ID => $FORM{del} });
    if (!_error_show($Msgs)) {
      $html->message('info', $lang{DELETED});
      $Msgs->msgs_team_address_del({ TEAM_ID => $FORM{del} });
      $Msgs->msgs_team_members_del({ TEAM_ID => $FORM{del} });
    }
  }

  if ($FORM{add_form}) {
    my $team_members = _msgs_team_members($FORM{chg});
    $html->tpl_show($Templates->_include('msgs_teams_add', 'Msgs'), { %FORM, %{$Msgs},
      GEOLOCATION_TREE => geolocation_tree({
        RETURN_TREE => 1,
      }, $Msgs->{TEAM_ADDRESS_LIST} && ref $Msgs->{TEAM_ADDRESS_LIST} eq 'ARRAY' ? $Msgs->{TEAM_ADDRESS_LIST} : []),
      TEAM_MEMBERS     => $team_members
    });
  }

  result_former({
    INPUT_DATA      => $Msgs,
    FUNCTION        => 'msgs_teams_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'ID,NAME,MESSAGES,DESCR',
    FUNCTION_FIELDS => 'change,del',
    FUNCTION_INDEX  => $index,
    SKIP_USER_TITLE => 1,
    FILTER_VALUES   => {
      messages => sub {
        my $messages = shift;
        my ($line) = @_;

        my $msgs_admin_index = get_function_index('msgs_admin');
        return $messages if !$msgs_admin_index;

        return $html->button($messages || '0', "index=$msgs_admin_index&TEAM_ID=$line->{id}&ALL_MSGS=1");
      },
    },
    EXT_TITLES      => {
      ID          => '#',
      NAME        => $lang{NAME},
      RESPONSIBLE => $lang{RESPONSIBLE},
      MESSAGES    => $lang{MESSAGES},
      DESCR       => $lang{DESCRIBE},
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{BRIGADES},
      qs      => $pages_qs,
      ID      => 'MSGS_TEAMS',
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS       => 1,
    MODULE          => 'Msgs',
    TOTAL           => 1,
    SEARCH_FORMER   => 1,
  });
}

#**********************************************************
=head2 _msgs_team_members()

=cut
#**********************************************************
sub _msgs_team_members {
  my $team_id = shift;

  my $active_admins = {};
  my $admins = $admin->list({
    DISABLE   => 0,
    COLS_NAME => 1,
    PAGE_ROWS => 1000
  });

  if ($team_id) {
    my $team_members = $Msgs->msgs_team_members_list({ TEAM_ID => $team_id, AID => '_SHOW', COLS_NAME => 1 });
    if ($Msgs->{TOTAL} && $Msgs->{TOTAL} > 0) {
      map $active_admins->{$_->{aid}} = 1, @{$team_members};
    }
  }

  my @checkboxes = ();
  foreach my $line (@{$admins}) {

    my $label = $html->element('label', join(' : ', ($line->{name}, $line->{login})), { FOR => "AID_$line->{aid}" });
    my $checkbox = $html->element('input', '', {
      type  => 'checkbox',
      name  => 'AID',
      value => $line->{aid},
      id    => "AID_$line->{aid}",
      class => 'mr-1',
      ($active_admins->{$line->{aid}} ? (checked => 'checked') : ())
    });
    my $checkbox_parent = $html->element('div', $checkbox . $label, { class => 'abills-checkbox-parent' });
    push @checkboxes, $checkbox_parent;
  }

  my $cols = '';
  my $count_checkboxes = scalar @checkboxes;
  my $col_size = $count_checkboxes >= 16 ? 3 : 6;
  my $fields_in_col = POSIX::ceil($count_checkboxes / int(12 / $col_size));
  my $rows = (POSIX::ceil($count_checkboxes / $fields_in_col) - 1);

  foreach my $row (0 .. $rows) {
    my $start_index = $row * $fields_in_col;
    my $end_index = $start_index + ($fields_in_col - 1);
    $end_index = $count_checkboxes - 1 if ($count_checkboxes - 1) < $end_index;

    $cols .= $html->element('div', join('', @checkboxes[$start_index .. $end_index]), { class => "col-md-$col_size" });
  }

  my $admins_list = $html->element('div', $cols, { class => 'row' });

  return $admins_list;
}

1;