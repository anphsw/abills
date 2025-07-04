#package Abills::Selects;
=head1 DESCRIPTION

 Select elements

=cut

use strict;
use warnings FATAL => 'all';
use Abills::HTML;

our (
  $db,
  $admin,
  %conf,
  %lang,
  %COOKIES,
  $users,
  $base_dir,
);

our Abills::HTML $html;

#**********************************************************
=head2 sel_groups($attr) - show select user group

  Attributes:
    $attr
      GID
      HASH_RESULT      - Return results as hash
      SKIP_MULTISELECT - Skip multiselect
      FILTER_SEL       - Select for reports (filter)

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_groups {
  my ($attr) = @_;

  my $GROUPS_SEL = '';
  if ($admin->{GID} && $admin->{GID} !~ m/,/x) {
    $users->group_info($admin->{GID});
    $GROUPS_SEL = "$admin->{GID}:$users->{NAME}";
    $GROUPS_SEL .= $html->form_input('GID', $admin->{GID}, { TYPE => 'hidden' });

    if($attr->{HASH_RESULT}) {
      my %group_hash = ();
      $group_hash{$admin->{GID}} = $users->{NAME};
      return \%group_hash;
    }
  }
  elsif($attr->{HASH_RESULT}) {
    my %group_hash = ();
    my $list = $users->groups_list({
      GIDS            => ($admin->{GID}) ? $admin->{GID} : undef,
      GID             => '_SHOW',
      NAME            => '_SHOW',
      DESCR           => '_SHOW',
      ALLOW_CREDIT    => '_SHOW',
      DISABLE_PAYSYS  => '_SHOW',
      DISABLE_CHG_TP  => '_SHOW',
      USERS_COUNT     => '_SHOW',
      COLS_NAME       => 1,
    });
    foreach my $line (@$list) {
      $group_hash{$line->{gid}} = "($line->{gid}) $line->{name}";
    }

    return \%group_hash;
  }
  else {
    my $gid = $attr->{GID} || $FORM{GID};
    my %PARAMS = (
      SELECTED  => $gid,
      SEL_LIST  => $users->groups_list({
        GID            => '_SHOW',
        NAME           => '_SHOW',
        DESCR          => '_SHOW',
        ALLOW_CREDIT   => '_SHOW',
        DISABLE_PAYSYS => '_SHOW',
        DISABLE_CHG_TP => '_SHOW',
        USERS_COUNT    => '_SHOW',
        GIDS           => ($admin->{GID}) ? $admin->{GID} : undef,
        DOMAIN_ID      => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
        COLS_NAME      => 1
      }),
      SEL_KEY   => 'gid',
      SEL_VALUE => 'name',
      EX_PARAMS => $attr->{MULTISELECT} ? 'multiple="multiple"' : $attr->{EX_PARAMS},
      ID        => $attr->{ID}
    );

    if ($attr->{FILTER_SEL}) {
      $PARAMS{SEL_OPTIONS} = ($admin->{GID}) ? undef : { '*' => "$lang{ALL}", '0' => "$lang{WITHOUT_GROUP}" };
      $PARAMS{MULTIPLE}    = 1;
    }
    else {
      $PARAMS{SEL_OPTIONS} = ($admin->{GID}) ? undef : { '' => "$lang{ALL}", '0' => "$lang{WITHOUT_GROUP}" };
      $PARAMS{MAIN_MENU}      = get_function_index('form_groups');
      $PARAMS{MAIN_MENU_ARGV} = $gid ? "GID=$gid" : '';
    }
    $GROUPS_SEL = $html->form_select('GID', \%PARAMS);
  }

  return $GROUPS_SEL;
}

#**********************************************************
=head2 sel_status($attr) - show select user group
  Attributes:
    $attr
      STATUS       - Status ID
      HASH_RESULT  - Return results as hash
      NAME         - Select element name
      COLORS       - Status colors
      ALL          - Show all item

  Returns:
    GID select form

=cut
#**********************************************************
sub sel_status {
  my ($attr, $select_params) = @_;

  my $select_name = $attr->{NAME} || 'STATUS';

  require Service;
  Service->import();
  my $Service = Service->new($db, $admin, \%conf);
  my $list = $Service->status_list({ NAME => '_SHOW', COLOR => '_SHOW', COLS_NAME => 1 });
  my %hash  = ();
  my @style = ();

  foreach my $line (@$list) {
    my $color = $line->{color} || '';
    $hash{$line->{id}} = ((exists $line->{name}) ? _translate($line->{name}) : '');

    if (!$attr->{SKIP_COLORS}) {
      $hash{$line->{id}} .= ":$color" if $attr->{HASH_RESULT};
      $style[$line->{id}] = '#'.$color;
    }
  }

  my $SERVICE_SEL = '';
  if ($attr->{COLORS}) {
    return \@style;
  }
  elsif($attr->{HASH_RESULT}) {
    return \%hash;
  }
  else {
    my $status_id = (defined($attr->{$select_name})) ? $attr->{$select_name} : $FORM{$select_name};

    $SERVICE_SEL = $html->form_select(
      $select_name,
      {
        SELECTED       => $status_id,
        SEL_HASH       => \%hash,
        STYLE          => \@style,
        SORT_KEY_NUM   => 1,
        NO_ID          => 1,
        SEL_OPTIONS    => ($attr->{ALL}) ? { '' => $lang{ALL} } : undef,
        EX_PARAMS      => $attr->{EX_PARAMS},
        #MAIN_MENU      => get_function_index('form_status'),
        #MAIN_MENU_ARGV => "chg=$status_id"
        %{($select_params) ? $select_params : {}}
      }
    );
  }

  return $SERVICE_SEL;
}

#**********************************************************
=head2 sel_fees_methods($sel_name, $selected, \%attr)

  Arguments:
    $sel_name - Name of the select field
    $selected - ID of the selected fee method
    \%attr    - (optional) Additional attributes for the select field

  Returns:
    $html_output - HTML string containing the select field for fee methods

=cut
#**********************************************************
sub sel_fees_methods {
  my ($sel_name, $selected, $attr) = @_;

  my $fees_types = get_fees_types({ PARENT_ID => 0 });
  my $child_fees_method_sel = '';
  my $parent_selected = $selected;

  if (defined $selected && !$fees_types->{$selected}) {
    require Abills::Api::Handle;
    Abills::Api::Handle->import();
    my $Api = Abills::Api::Handle->new($db, $admin, \%conf, {
      html    => $html,
      lang    => \%lang,
      cookies => \%COOKIES,
      direct  => 1
    });

    my ($types) = $Api->api_call({
      METHOD => 'GET',
      PATH   => "/fees/types/",
      PARAMS => { ID => $selected, PARENT_ID => '_SHOW' },
    });

    my $fees_type = $types && ref $types eq 'ARRAY' ? shift @{$types} : {};
    if ($fees_type->{parent_id}) {
      $parent_selected = $fees_type->{parent_id};
      my ($fees_type_children) = $Api->api_call({
        METHOD => 'GET',
        PATH   => "/fees/types/",
        PARAMS => { PARENT_ID => $fees_type->{parent_id} },
      });

      my $parent_sel_id = $attr->{ID} || $sel_name;
      if ($fees_type_children && ref $fees_type_children eq 'ARRAY' && scalar(@{$fees_type_children}) > 0) {
        $child_fees_method_sel = $html->tpl_show(templates('form_row'), {
          VALUE => $html->form_select($sel_name, {
            SELECTED     => $selected,
            SEL_LIST     => $fees_type_children,
            SEL_VALUE    => 'name',
            SEL_KEY      => 'id',
            SORT_KEY_NUM => 1,
            NO_ID        => 1,
            ID           => $sel_name . "_CHILD",
            EX_PARAMS    => "data-fees-methods-parent-id='$parent_sel_id'",
          })
        }, { OUTPUT2RETURN => 1 });
      }
    }
  }

  my $fees_method_sel = $html->form_select($sel_name, {
    %{ $attr ? $attr : {} },
    SELECTED       => $parent_selected,
    SEL_HASH       => $fees_types,
    NO_ID          => 1,
    SORT_KEY       => 1,
    SEL_OPTIONS    => { 0 => '' },
    MAIN_MENU      => get_function_index('form_fees_types'),
    EX_PARAMS      => 'data-fees-methods-select=1',
  });

  return $html->tpl_show(templates('form_row'), {
    ID    => $attr->{ID},
    NAME  => $attr->{LABEL} ? "$attr->{LABEL}:" : "$lang{FEES} $lang{TYPE}:",
    VALUE => $fees_method_sel
  }, { OUTPUT2RETURN => 1 }) . $child_fees_method_sel;
}

#**********************************************************
=head2 sel_admins($attr) - Admin select element

  Arguments:
    NAME     - Element name
    SELECTED - value
    REQUIRED - Required options
    HASH     - Hash return
    DISABLE  - 0 = Active; 1 = Disable; 2 = Fired;
    MULTIPLE - multiple admins

  Returns:
    Select element

=cut
#**********************************************************
sub sel_admins {
  my ($attr) = @_;

  my $select_name = $attr->{NAME} || 'AID';

  my $admins_list = $admin->list({
    GID           => $admin->{GID},
    COLS_NAME     => 1,
    DOMAIN_ID     => ($admin->{DOMAIN_ID}) ? $admin->{DOMAIN_ID} : undef,
    PAGE_ROWS     => 10000,
    POSITION      => ($attr->{POSITION} ? $attr->{POSITION} : undef),
    DISABLE       => (defined $attr->{DISABLE} ? $attr->{DISABLE} : undef),
    ACTIVE_ONLY   => $attr->{ACTIVE_ONLY} || undef,
    AID_EXCEPTION => $attr->{AID_EXCEPTION} || undef
  });

  if($attr->{HASH}) {
    my %admins_hash = ();
    foreach my $line (@$admins_list) {
      $admins_hash{$line->{aid}} = $line->{login};
    }

    return \%admins_hash;
  }

  return $html->form_select($select_name, {
    SELECTED           => $attr->{SELECTED} || $attr->{$select_name} || $FORM{$select_name} || 0,
    SEL_LIST           => $admins_list,
    SEL_KEY            => 'aid',
    SEL_VALUE          => 'name,login',
    NO_ID              => 1,
    SEL_OPTIONS        => { '' => '--' },
    REQUIRED           => ($attr->{REQUIRED}) ? 'required' : undef,
    ID                 => $attr->{ID} ? $attr->{ID} : undef,
    MULTIPLE           => $attr->{MULTIPLE} ? 1 : undef,
    %{($attr->{EX_PARAMS} && ref $attr->{EX_PARAMS} eq 'HASH') ? $attr->{EX_PARAMS} : {}}
  });
}

#**********************************************************
=head sel_tp($tp_id)

  Arguments:
    MODULE
    TP_ID    - SHow tp name for tp_id
    SELECT   - Select element
    SKIP_TP  - Skip show tp
    SHOW_ALL - Show all tps
    SEL_OPTIONS - Extra sel options (items)
    EX_PARAMS   - Extra sell options
    SERVICE_ID  - TP SErvice ID
    SMALL_DEPOSIT_ACTION
    USER_INFO -
    DOMAIN_ID
    MAIN_MENU -
    DEBUG

  Returns:
    \%tp_hash (tp_id => name)

=cut
#**********************************************************
sub sel_tp {
  my ($attr) = @_;

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($db, \%conf, $admin);
  my %params = (MODULE => 'Dv;Internet');
  $params{MODULE} = $attr->{MODULE} if $attr->{MODULE};

  my $user_info = $attr->{USER_INFO};

  my $tp_gids = $attr->{CHECK_GROUP_GEOLOCATION} ?
    tp_gids_by_geolocation($attr->{CHECK_GROUP_GEOLOCATION}, $Tariffs, $attr->{USER_GID}) : '';

  if ($attr->{TP_ID}) {
    $attr->{TP_ID} = $1 if $attr->{TP_ID} =~ m/:(\d+)/x;
    $params{INNER_TP_ID} = $attr->{TP_ID} if (!$attr->{SHOW_ALL});
  }

  $params{SERVICE_ID} = $attr->{SERVICE_ID} if ($attr->{SERVICE_ID});

  if ($attr->{DEBUG} && $attr->{DEBUG} > 3) {
    $Tariffs->{debug}=1;
  }

  my $list = $Tariffs->list({
    NEW_MODEL_TP  => 1,
    DOMAIN_ID     => $user_info->{DOMAIN_ID} || $admin->{DOMAIN_ID} || $attr->{DOMAIN_ID},
    COLS_NAME     => 1,
    STATUS        => '0',
    TP_GID        => $tp_gids || '_SHOW',
    MONTH_FEE     => '_SHOW',
    DAY_FEE       => '_SHOW',
    COMMENTS      => '_SHOW',
    TP_GROUP_NAME => '_SHOW',
    DESCRIBE_AID  => '_SHOW',
    %params
  });

  if ($attr->{TP_ID} && !$attr->{EX_PARAMS}) {
    return "$list->[0]->{id} : $list->[0]->{name}" if $Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0;

    return $attr->{TP_ID};
  }

  my %tp_list = ();

  foreach my $line (@$list) {
    next if ($attr->{SKIP_TP} && $attr->{SKIP_TP} == $line->{tp_id});
    next if (!$attr->{SHOW_ALL} && $line->{status});

    my $describe_for_aid = ($line->{describe_aid}) ? ('[' . $line->{describe_aid} . ']') : '';

    if ($attr->{GROUP_SORT}) {
      my $small_deposit = q{};
      if ($user_info) {
        my $deposit = (defined($user_info->{DEPOSIT}) && $user_info->{DEPOSIT} =~ m/^[\-0-9,\.\/]+$/x) ? $user_info->{DEPOSIT} : 0;
        $small_deposit = ($deposit + ($user_info->{CREDIT} || 0) < ($line->{month_fee} || 0) + ($line->{day_fee} || 0)) ?
          ' (' . $lang{ERR_SMALL_DEPOSIT} . ')' : '';
      }

      $tp_list{($line->{tp_group_name} || '')}{ $line->{tp_id} } = "$line->{id} : $line->{name} $describe_for_aid " . $small_deposit;
    }
    else {
      $tp_list{$line->{tp_id}} = $line->{id} . ' : ' . $line->{name} . ' ' . $describe_for_aid;
    }
  }

  if ($attr->{SELECT}) {
    my %EX_PARAMS = ();

    my $element_name = $attr->{SELECT};
    my %extra_options = ('' => '--');
    %extra_options = %{$attr->{SEL_OPTIONS}} if $attr->{SEL_OPTIONS};

    if ($attr->{EX_PARAMS}) {
      %EX_PARAMS = (ref $attr->{EX_PARAMS} eq 'HASH') ? %{$attr->{EX_PARAMS}} : (EX_PARAMS => $attr->{EX_PARAMS});
    }

    if ($attr->{MAIN_MENU}) {
      $EX_PARAMS{MAIN_MENU} = get_function_index($attr->{MAIN_MENU});
      $EX_PARAMS{MAIN_MENU_ARGV} = "chg=" . ($attr->{$element_name} // $FORM{$element_name} || '');
    }

    return $html->form_select($element_name, {
      SELECTED    => $attr->{$element_name} // $FORM{$element_name},
      SEL_HASH    => \%tp_list,
      SEL_OPTIONS => \%extra_options,
      NO_ID       => 1,
      SORT_KEY    => 1,
      %EX_PARAMS
    });
  }

  return \%tp_list;
}

#**********************************************************
=head2 sel_plugins($module, $attr) - Select available plugins for a module

  Arguments:
    $module - Name of the module to search for plugins
    $attr   - Extra attributes
       SELECT     - Flag to determine if HTML select should be returned; also serves as the name of the select element
       SELECT_ID  - ID for the HTML select element (optional)
       SELECTED   - Default selected plugin (optional)
       PLUGIN     - Plugin name to be selected by default (optional)
       EX_PARAMS  - Additional parameters for the HTML select element (optional)

  Returns:
   Hash reference of available plugins or HTML select element

  Example:

    # To get a hash reference of plugins
    my $plugins = sel_plugins('Iptv');

    # To get an HTML select element
    my $html_select = sel_plugins('Iptv', { SELECT => 'PLUGIN' });

=cut
#**********************************************************
sub sel_plugins {
  my ($module, $attr) = @_;

  return '' if (!$module);

  my $plugins_folder = "$base_dir" . 'Abills/modules/' . $module . '/Plugins/';
  return '' if (!-d $plugins_folder);

  opendir(my $folder, $plugins_folder) or return '';
  my @plugin_files = grep { /\.pm$/x } readdir($folder);
  closedir $folder;

  my %plugins_hash = map { my ($plugin) = m/(.+)\.pm/x; $plugin => $plugin; } @plugin_files;
  return \%plugins_hash if (!$attr->{SELECT});

  return $html->form_select($attr->{SELECT}, {
    ID          => $attr->{SELECT_ID} || (uc($module) . '_PLUGIN'),
    SELECTED    => $attr->{SELECTED} || $attr->{PLUGIN},
    SEL_HASH    => \%plugins_hash,
    SEL_OPTIONS => { '' => '--' },
    NO_ID       => 1,
    EX_PARAMS   => $attr->{EX_PARAMS}
      ? ((ref $attr->{EX_PARAMS} eq 'HASH')
      ? %{$attr->{EX_PARAMS}}
      : (EX_PARAMS => $attr->{EX_PARAMS}))
      : {},
  });
}


1;