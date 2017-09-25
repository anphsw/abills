#package Events::Configure;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Events::Configure - functions for Configuration ( 5 ) menu

=cut

use Abills::Experimental;

our (
  %lang,
  $html,
  $Events,
  $admin, $db, %conf,
  @DEFAULT_SEND_TYPES,
  @PRIORITY_SEND_TYPES
);

require Events::UniversalPageLogic;

#**********************************************************
=head2 events_main()

=cut
#**********************************************************
sub events_main {
  
  events_uni_page_logic(
    'events', # Table name
    {
      # Template variables
      SELECTS    => {
        PRIVACY_SELECT  => { func => '_events_privacy_select', argument => 'PRIVACY_ID' },
        PRIORITY_SELECT => { func => '_events_priority_select', argument => 'PRIORITY_ID' },
        
        GROUP_SELECT    => { func => '_events_group_select', argument => 'GROUP_ID' },
        STATE_SELECT    => { func => '_events_state_select', argument => 'STATE_ID' },
      },
      
      # Result former variables
      HAS_VIEW   => 1,
      HAS_SEARCH => 1
    }
  );
  
  return 1 if ( $FORM{MESSAGE_ONLY} );
  
  my $management_template = $html->tpl_show(_include('events_events_management_inline', 'Events'), {
      STATE_SELECT => _events_state_select(),
      COMMENTS     => "$lang{ADMIN} -> $admin->{AID} ",
      FORM_ID      => 'DELETE_EVENTS_FORM'
    }, { OUTPUT2RETURN => 1 }
  );
  
  my $management_form = $html->form_main({
    CONTENT => $management_template,
    HIDDEN  => { index => "$index" },
    METHOD  => 'POST',
    ID      => 'DELETE_EVENTS_FORM'
  });
  
  my $translate_simple = sub {
    $_[0] =~ s/\_\{(\w+)\}\_/$lang{$1}/sg;
    $_[0];
  };
  events_uni_result_former({
    LIST_FUNC       => "events_list",
    DEFAULT_FIELDS  => "ID,TITLE,COMMENTS,PRIORITY_NAME,STATE_NAME,GROUP_NAME",
    HIDDEN_FIELDS   => "PRIORITY_ID,STATE_ID,GROUP_ID,COMMENTS,EXTRA,CREATED,MODULE",
    EXT_TITLES      => {
      id            => "#",
      comments      => $lang{COMMENTS},
      module        => $lang{MODULE},
      created       => $lang{CREATED},
      state_name    => $lang{STATE},
      privacy_name  => $lang{ACCESS},
      priority_name => $lang{PRIORITY},
      group_name    => $lang{GROUP},
      title         => $lang{NAME}
    },
    FILTER_COLS     => {
      comments => 0,
      title    => 0,
    },
    FILTER_VALUES   => {
      comments      => $translate_simple,
      title         => $translate_simple,
      priority_name => $translate_simple
    },
    READABLE_NAME   => "$lang{EVENTS}",
    TABLE_NAME      => "EVENTS_TABLE",
    HAS_SEARCH      => 1,
    MANAGEMENT_FORM => $management_form
  });
  
  return 1;
}

#**********************************************************

=head2 events_state_main()

=cut

#**********************************************************
sub events_state_main {
  
  events_uni_page_logic('state');
  
  events_uni_result_former(
    {
      LIST_FUNC      => "state_list",
      DEFAULT_FIELDS => "ID,NAME",
      EXT_TITLES     => {
        id   => "ID",
        name => "$lang{NAME}"
      },
      READABLE_NAME  => "$lang{STATE}",
      TABLE_NAME     => "STATE_TABLE",
    }
  );
  
  return 1;
}

#**********************************************************

=head2 events_priority_main()

=cut

#**********************************************************
sub events_priority_main {
  
  events_uni_page_logic('priority');
  
  events_uni_result_former(
    {
      LIST_FUNC      => "priority_list",
      DEFAULT_FIELDS => "ID,NAME,VALUE",
      EXT_TITLES     => {
        id    => "ID",
        name  => "$lang{NAME}",
        value => "$lang{VALUE}"
      },
      READABLE_NAME  => "$lang{PRIORITY}",
      TABLE_NAME     => "PRIORITY_TABLE",
    }
  );
  
  return 1;
}

#**********************************************************

=head2 events_privacy_main()

=cut

#**********************************************************
sub events_privacy_main {
  
  events_uni_page_logic('privacy');
  
  events_uni_result_former(
    {
      LIST_FUNC      => "privacy_list",
      DEFAULT_FIELDS => "ID,NAME,VALUE",
      EXT_TITLES     => {
        id    => "ID",
        name  => "$lang{NAME}",
        value => "$lang{VALUE}"
      },
      READABLE_NAME  => "$lang{ACCESS}",
      TABLE_NAME     => "PRIVACY_TABLE",
    }
  );
  
  return 1;
}

#**********************************************************
=head2 events_group_main()

=cut
#**********************************************************
sub events_group_main {
  
  our @MODULES;
  my $modules_checkboxes_html = '';
  
  # Storing comma separated list of modules in single DB field #TODO: move to Events.pm
  my %checked_modules = ();
  if ( $FORM{chg} ) {
    my $group = $Events->group_info($FORM{chg});
    _error_show($Events);
    
    if ( $group->{modules} ) {
      map {$checked_modules{$_} = 1} split (',', $group->{modules});
    }
  }
  if ( $FORM{add} || $FORM{change} ) {
    my @checked = grep {$_ if ( exists $FORM{$_} )} @MODULES;
    $FORM{MODULES} = join(',', @checked);
  };
  
  foreach my $module_name ( sort @MODULES ) {
    
    next if ( $module_name eq 'Events' );
    
    my $checkbox = $html->form_input($module_name, 1, { TYPE => 'checkbox', STATE => $checked_modules{$module_name} });
    my $label = $html->element('label', $checkbox . $module_name);
    my $checkbox_group = $html->element('div', $label, { class => 'checkbox col-md-6 text-left' });
    
    $modules_checkboxes_html .= $checkbox_group;
  }
  
  events_uni_page_logic('group', { MODULE_CHECKBOXES => $modules_checkboxes_html });
  
  my $groups_list = $Events->group_list({ SHOW_ALL_COLUMNS => 1 });
  _error_show($Events);
  
  my $table = $html->table({
    width      => '100%',
    caption    => $lang{GROUP},
    title      => [ '#', $lang{NAME}, $lang{MODULES} ],
    cols_align => [ 'left', 'right', 'right', 'right', 'center', 'center' ],
    pages      => $Events->{TOTAL},
    qs         => $pages_qs,
    ID         => 'EVENTS_GROUP_ID',
    MENU       => "$lang{ADD}:index=$index&show_add_form=1&$pages_qs:add",
  });
  
  foreach my $group ( @{$groups_list} ) {
    
    my @group_modules = split (',', $group->{modules});
    
    my $chg_button = $html->button('', "index=$index&chg=$group->{id}", { class => 'change' });
    my $del_button = $html->button('', "index=$index&del=$group->{id}",
      { MESSAGE => "$lang{DEL} $group->{name}?", class => 'del' });
    
    $table->addrow(
      $group->{id},
      $group->{name},
      join(', ', @group_modules),
      $chg_button,
      $del_button,
    );
  }
  
  print $table->show();
}

1;