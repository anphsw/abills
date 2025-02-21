package Msgs::Plugins::Msgs_teams_select;

use strict;
use warnings FATAL => 'all';

my ($admin, $CONF, $db, $msgs_permissions);
my $json;
my Abills::HTML $html;
my $lang;
my $Msgs;

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
  $msgs_permissions = $attr->{MSGS_PERMISSIONS};

  my $self = { MODULE => 'Msgs' };

  if ($attr->{MSGS}) {
    $Msgs = $attr->{MSGS};
  }
  else {
    require Msgs;
    Msgs->import();
    $Msgs = Msgs->new($db, $admin, $CONF);
  }

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 plugin_info()

=cut
#**********************************************************
sub plugin_info {
  return {
    NAME     => "Teams select",
    POSITION => 'RIGHT',
    DESCR    => $lang->{ASSIGNED_BRIGADE}
  };
}

#**********************************************************
=head2 plugin_show($attr)

  Arguments:

  Return:

=cut
#**********************************************************
sub plugin_show {
  my $self = shift;
  my ($attr) = @_;

  $attr->{ID} //= $attr->{chg};
  if ($attr->{change} && defined $attr->{TEAM_ID} && $attr->{ID}) {
    $Msgs->msgs_team_messages_change({
      MESSAGE_ID => $attr->{ID},
      TEAM_ID    => $attr->{TEAM_ID}
    });
    $Msgs->{TEAM_ID} = $attr->{TEAM_ID} if !$Msgs->{errno};
  }

  if (!$Msgs->{TEAM_ID} && $attr->{ID}) {
    $Msgs->msgs_team_messages_info({ MESSAGE_ID => $attr->{ID} });
  }

  my $teams_sel = $html->form_select('TEAM_ID', {
    SELECTED    => $Msgs->{TEAM_ID} || '',
    SEL_LIST    => $Msgs->msgs_teams_list({
      ID        => '_SHOW',
      NAME      => '_SHOW',
      COLS_NAME => 1
    }),
    SEL_OPTIONS => { '' => '--' },
    SEL_KEY     => 'id',
    SEL_VALUE   => 'name'
  });

  my $col_div = $html->element('div', $teams_sel, { class => 'col-md-12' });
  my $label = $html->element('label', "$lang->{BRIGADE}:", { class => 'col-md-12' });

  return $html->element('div', $label . $col_div, { class => 'form-group' });;
}

1;
