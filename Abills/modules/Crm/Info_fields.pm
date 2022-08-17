use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Info_fields - crm leads info fields

=cut

our (
  %lang,
  %conf,
  $admin,
  $db,
  %permissions,
  %LIST_PARAMS
);

use Time::Piece;
our Crm $Crm;
our Abills::HTML $html;

my @fields_types = (
  'string',
  'integer',
  'list',
  'text',
  'flag',
  'autoincrement',
  'url',
  'language',
  'time_zone',
  'date',
);

my @fields_types_lang = (
  'String',
  'Integer',
  $lang{LIST},
  $lang{TEXT},
  'Flag',
  'AUTOINCREMENT',
  'URL',
  $lang{LANGUAGE},
  'Time zone',
  $lang{DATE},
);

#**********************************************************
=head2 crm_info_fields($attr)

=cut
#**********************************************************
sub crm_info_fields {

  my %TEMPLATE_VARIABLES = ();

  if ($FORM{LIST_TABLE} && $FORM{LIST_TABLE_NAME}) {
    crm_info_lists();
    return;
  }

  if ($FORM{add}) {
    if (!$FORM{SQL_FIELD}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (SQL_FIELD)");
    }
    elsif (length($FORM{SQL_FIELD}) > 20) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (Length > 20)");
    }
    else {
      $Crm->lead_field_add({
        POSITION   => $FORM{PRIORITY},
        FIELD_TYPE => $FORM{TYPE},
        FIELD_ID   => $FORM{SQL_FIELD},
        NAME       => $FORM{NAME},
      });
      $Crm->fields_add({ %FORM });
    }
  }
  elsif ($FORM{change}) {
    $Crm->fields_change({ %FORM });
  }
  elsif ($FORM{chg}) {
    $Crm->field_info($FORM{chg});
    $TEMPLATE_VARIABLES{READONLY2} = "disabled";
    $TEMPLATE_VARIABLES{READONLY} = "readonly";
    $TEMPLATE_VARIABLES{REGISTRATION} = 'checked' if $Crm->{REGISTRATION};
    $TEMPLATE_VARIABLES{TYPE_SELECT} = $html->element('input', '', {
      readonly => 'readonly',
      type     => 'text',
      class    => 'form-control',
      value    => $Crm->{TOTAL} > 0 ? $fields_types_lang[$Crm->{TYPE}] : q{},
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->field_info($FORM{del});
    $Crm->lead_field_del({ FIELD_ID => $Crm->{SQL_FIELD} });
    $Crm->fields_del($FORM{del}, { COMMENTS => $FORM{COMMENTS} });
  }

  $html->tpl_show(_include('crm_info_fields', 'Crm'), {
    %{$Crm},
    TYPE_SELECT       => $html->form_select('TYPE', {
      SELECTED     => $Crm->{TYPE} || 0,
      SEL_ARRAY    => \@fields_types_lang,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { "" => "" }
    }),
    %TEMPLATE_VARIABLES,
    SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
    SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
  });

  _crm_info_fields_table();
}

#**********************************************************
=head2 crm_tp_info_fields($attr)

=cut
#**********************************************************
sub crm_tp_info_fields {

  my %TEMPLATE_VARIABLES = ();

  if ($FORM{LIST_TABLE} && $FORM{LIST_TABLE_NAME}) {
    crm_info_lists({ TP_INFO_FIELDS => 1 });
    return;
  }

  if ($FORM{add}) {
    if (!$FORM{SQL_FIELD}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (SQL_FIELD)");
    }
    elsif (length($FORM{SQL_FIELD}) > 20) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} (Length > 20)");
    }
    else {
      $Crm->lead_field_add({
        POSITION       => $FORM{PRIORITY},
        FIELD_TYPE     => $FORM{TYPE},
        FIELD_ID       => $FORM{SQL_FIELD},
        NAME           => $FORM{NAME},
        TP_INFO_FIELDS => 1
      });
      $Crm->fields_add({ %FORM, TP_INFO_FIELDS => 1 });
    }
  }
  elsif ($FORM{change}) {
    $Crm->fields_change({ %FORM, TP_INFO_FIELDS => 1 });
  }
  elsif ($FORM{chg}) {
    $Crm->field_info($FORM{chg}, { TP_INFO_FIELDS => 1 });
    $TEMPLATE_VARIABLES{READONLY2} = "disabled";
    $TEMPLATE_VARIABLES{READONLY} = "readonly";
    $TEMPLATE_VARIABLES{TYPE_SELECT} = $html->element('input', '', {
      readonly => 'readonly',
      type     => 'text',
      class    => 'form-control',
      value    => $Crm->{TOTAL} > 0 ? $fields_types_lang[$Crm->{TYPE}] : q{},
    });
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->field_info($FORM{del}, { TP_INFO_FIELDS => 1 });
    $Crm->lead_field_del({ FIELD_ID => $Crm->{SQL_FIELD}, TP_INFO_FIELDS => 1 });
    $Crm->fields_del($FORM{del}, { COMMENTS => $FORM{COMMENTS}, TP_INFO_FIELDS => 1 });
  }

  $html->tpl_show(_include('crm_info_fields', 'Crm'), {
    %{$Crm},
    TYPE_SELECT       => $html->form_select('TYPE', {
      SELECTED     => $Crm->{TYPE} || 0,
      SEL_ARRAY    => \@fields_types_lang,
      ARRAY_NUM_ID => 1,
      SEL_OPTIONS  => { "" => "" }
    }),
    %TEMPLATE_VARIABLES,
    SUBMIT_BTN_ACTION => ($FORM{chg}) ? 'change' : 'add',
    SUBMIT_BTN_NAME   => ($FORM{chg}) ? $lang{CHANGE} : $lang{ADD},
  });

  $LIST_PARAMS{TP_INFO_FIELDS} = 1;
  _crm_info_fields_table();
}

#**********************************************************
=head2 _crm_info_fields_table($attr)

=cut
#**********************************************************
sub _crm_info_fields_table {

  result_former({
    INPUT_DATA      => $Crm,
    FUNCTION        => 'fields_list',
    DEFAULT_FIELDS  => 'ID,NAME,SQL_FIELD,TYPE,PRIORITY,COMMENT',
    FUNCTION_FIELDS => 'change,del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => {
      id        => '#',
      name      => $lang{NAME},
      sql_field => "SQL_FIELD",
      type      => $lang{TYPE},
      priority  => $lang{PRIORITY},
      comment   => $lang{COMMENTS},
    },
    FILTER_VALUES   => {
      type => sub {
        my (undef, $line) = @_;
        if ($line->{type} == 2) {
          $html->button($fields_types_lang[2], "index=$index&LIST_TABLE=$line->{id}&LIST_TABLE_NAME=$line->{sql_field}");
        }
        else {
          $fields_types_lang[$line->{type}];
        }
      }
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{INFO_FIELDS},
      ID      => "CRM_INFO_FIELDS",
      MENU    => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add; :index=$index&update_table=1&$pages_qs:fa fa-reply",
    },
    MAKE_ROWS       => 1,
    TOTAL           => 1
  });
}

#**********************************************************
=head2 crm_info_lists($attr)

=cut
#**********************************************************
sub crm_info_lists {
  my ($attr) = @_;

  my $action_lng = $lang{ADD};
  my $action_value = 'add';

  if ($FORM{add}) {
    $Crm->info_list_add({ %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    $html->message('info', $lang{INFO}, "$lang{ADDED}: $FORM{NAME}") if (!_error_show($Crm));
  }
  elsif ($FORM{change}) {
    $Crm->info_list_change({ ID => $FORM{chg}, %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    $html->message('info', $lang{INFO}, "$lang{CHANGED}: $FORM{NAME}") if (!_error_show($Crm));
  }
  elsif ($FORM{chg}) {
    $action_lng = $lang{CHANGE};
    $action_value = 'change';

    $Crm->info_list_info($FORM{chg}, { %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    if (!_error_show($Crm)) {
      $FORM{INFO_NAME} = $Crm->{NAME};
      $FORM{ID} = $Crm->{ID};
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Crm->info_list_del({ ID => $FORM{del}, %FORM, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
    $html->message('info', $lang{INFO}, "$lang{DELETED}: $FORM{del}") if (!_error_show($Crm));
  }

  my $lists = $html->form_main({
    CONTENT => $html->form_select('LIST_TABLE', {
      SELECTED  => $FORM{LIST_TABLE},
      SEL_LIST  => $Crm->fields_list({ TYPE => 2, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 }),
      SEL_KEY   => 'id',
      SEL_VALUE => 'name',
      NO_ID     => 1
    }),
    HIDDEN  => {
      index           => $index,
      LIST_TABLE      => $FORM{LIST_TABLE},
      LIST_TABLE_NAME => $FORM{LIST_TABLE_NAME}
    },
    SUBMIT  => { show => $lang{SHOW} },
    class   => 'navbar navbar-expand-lg',
  });

  func_menu({ $lang{NAME} => $lists });

  my $table = $html->table({
    caption => $lang{LIST},
    title   => [ '#', $lang{NAME}, '-', '-' ],
    ID      => 'LIST'
  });

  my $list = $Crm->info_lists_list({ %FORM, COLS_NAME => 1, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0 });
  foreach my $line (@{$list}) {
    my $chg_btn = $html->button($lang{CHANGE}, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}" .
      "&LIST_TABLE_NAME=$FORM{LIST_TABLE_NAME}&chg=$line->{id}", { class => 'change' });
    my $del_btn = $html->button($lang{DEL}, "index=$index&LIST_TABLE=$FORM{LIST_TABLE}&LIST_TABLE_NAME=$FORM{LIST_TABLE_NAME}" .
      "&del=$line->{id}", { MESSAGE => "$lang{DEL} $line->{id} / $line->{name}?", class => 'del' });

    $table->addrow($line->{id}, $line->{name}, $chg_btn, $del_btn);
  }

  $table->addrow($FORM{ID} || '', $html->form_input('NAME', $FORM{INFO_NAME} || '', { SIZE => 80 }),
    $html->form_input($action_value, $action_lng, { TYPE => 'SUBMIT' }), '');

  print $html->form_main({
    CONTENT => $table->show(),
    HIDDEN  => {
      index           => $index,
      chg             => $FORM{chg},
      LIST_TABLE      => $FORM{LIST_TABLE},
      LIST_TABLE_NAME => $FORM{LIST_TABLE_NAME}
    },
    NAME    => 'list_add'
  });
}

#**********************************************************
=head2 crm_lead_info_field_tpl($attr) - Info fields

  Arguments:
    COMPANY                - Company info fields
    VALUES                 - Info field value hash_ref
    RETURN_AS_ARRAY        - returns hash_ref for name => $input (for custom design logic)
    CALLED_FROM_CLIENT_UI  - apply client_permission view/edit logic

  Returns:
    Return formed HTML

=cut
#**********************************************************
sub crm_lead_info_field_tpl {
  my ($attr) = @_;

  my $fields_list = $Crm->fields_list({
    SORT           => 5,
    TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0,
    REGISTRATION   => $attr->{REGISTRATION} || '_SHOW' # ????
  });

  my @field_result = ();

  foreach my $field (@{$fields_list}) {
    next if !defined($field->{TYPE}) || !$fields_types[$field->{TYPE}];

    my $function_name = 'crm_info_field_' . $fields_types[$field->{TYPE}];
    next if !defined(&$function_name);

    my $disabled_ex_params = ($attr->{READ_ONLY} || ($attr->{CALLED_FROM_CLIENT_UI}))
      ? ' disabled="disabled" readonly="readonly"' : '';

    $field->{TITLE} ||= '';
    $field->{PLACEHOLDER} ||= '';
    $field->{SQL_FIELD} = uc $field->{SQL_FIELD} if $field->{SQL_FIELD};

    my $input = defined(&$function_name) ? &{\&{$function_name}}($field, {
      DISABLED       => $disabled_ex_params || '',
      VALUE          => $attr->{$field->{SQL_FIELD}} || '',
      TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0
    }) : '';

    next if !$input;

    push @field_result, $html->tpl_show(templates('form_row'), {
      ID         => $field->{ID},
      NAME       => (_translate($field->{NAME})),
      VALUE      => $input,
      COLS_LEFT  => $attr->{COLS_LEFT},
      COLS_RIGHT => $attr->{COLS_RIGHT},
    }, { OUTPUT2RETURN => 1, ID => $field->{ID} });
  }

  return join((($FORM{json}) ? ',' : ''), @field_result);
}

#**********************************************************
=head2 crm_info_field_string($attr) - String info fields

=cut
#**********************************************************
sub crm_info_field_string {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_input($field->{SQL_FIELD}, $attr->{VALUE}, {
    ID            => $field->{ID},
    EX_PARAMS     => "$attr->{DISABLED} title='$field->{TITLE}'"
      . ($field->{PATTERN} ? " pattern='$field->{PATTERN}'" : '')
      . "' placeholder='$field->{PLACEHOLDER}'",
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_integer($attr) - Integer info fields

=cut
#**********************************************************
sub crm_info_field_integer {
  my $field = shift;
  my ($attr) = @_;

  return crm_info_field_string($field, $attr);
}

#**********************************************************
=head2 crm_info_field_date($attr) - Date info fields

=cut
#**********************************************************
sub crm_info_field_date {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_datepicker($field->{SQL_FIELD}, $attr->{VALUE}, { TITLE => $field->{TITLE}, OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 crm_info_field_time_zone($attr) - Time-zone info fields

=cut
#**********************************************************
sub crm_info_field_time_zone {
  my $field = shift;
  my ($attr) = @_;

  my $val = $attr->{VALUE} || 0;
  my @sel_list = map {{ id => $_, name => "UTC" . sprintf("%+.2d", $_) . ":00" }} (-12 ... 12);
  my $select = $html->form_select($field->{SQL_FIELD}, {
    SEL_LIST      => \@sel_list,
    SELECTED      => $val,
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });

  my $input = $html->element('div', $select, { class => 'col-md-8', OUTPUT2RETURN => 1 });
  my Time::Piece $t = gmtime();
  $t = $t + 3600 * $val;

  $input .= $html->element('label', $t->hms, { class => 'control-label col-md-4', OUTPUT2RETURN => 1 });

  return $html->element('div', $input, { class => 'row', OUTPUT2RETURN => 1 });
}

#**********************************************************
=head2 crm_info_field_language($attr) - Language info fields

=cut
#**********************************************************
sub crm_info_field_language {
  my $field = shift;
  my ($attr) = @_;

  my @lang_list = map {my ($language, $lang_name) = split(':', $_);
    { id => $language, name => $lang_name };} split(';\s*', $conf{LANGS});

  return $html->form_select($field->{SQL_FIELD}, {
    SEL_LIST      => \@lang_list,
    SELECTED      => $attr->{VALUE},
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_url($attr) - Url info fields

=cut
#**********************************************************
sub crm_info_field_url {
  my $field = shift;
  my ($attr) = @_;

  my $go_button = $html->element('div', $html->button($lang{GO}, "", {
    GLOBAL_URL => '',
    ex_params  => ' target=_new',
  }), { class => 'input-group-text' });

  return $html->element('div', $html->form_input($field->{SQL_FIELD}, $attr->{VALUE}, { ID => $field->{ID}, EX_PARAMS => $attr->{DISABLED}, OUTPUT2RETURN => 1 }) .
    $html->element('div', $go_button, { class => 'input-group-append' }), { class => 'input-group' });
}

#**********************************************************
=head2 crm_info_field_autoincrement ($attr) - Autoincrement info fields

=cut
#**********************************************************
sub crm_info_field_autoincrement {
  my $field = shift;
  my ($attr) = @_;

  return crm_info_field_string($field, $attr);
}

#**********************************************************
=head2 crm_info_field_flag ($attr) - Flag info fields

=cut
#**********************************************************
sub crm_info_field_flag {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_input($field->{SQL_FIELD}, 1, {
    TYPE          => 'checkbox',
    STATE         => $attr->{VALUE} ? 1 : undef,
    ID            => $field->{ID},
    EX_PARAMS     => $attr->{DISABLED} . ((!$attr->{SKIP_DATA_RETURN}) ? " data-return='1' " : ''),
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_text ($attr) - Textarea info fields

=cut
#**********************************************************
sub crm_info_field_text {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_textarea($field->{SQL_FIELD}, $attr->{VALUE}, {
    ID            => $field->{SQL_FIELD},
    EX_PARAMS     => $attr->{DISABLED},
    OUTPUT2RETURN => 1
  });
}

#**********************************************************
=head2 crm_info_field_list ($attr) - List info fields

=cut
#**********************************************************
sub crm_info_field_list {
  my $field = shift;
  my ($attr) = @_;

  return $html->form_select($field->{SQL_FIELD},{
    SELECTED      => $attr->{VALUE},
    SEL_LIST      => $Crm->info_lists_list({ LIST_TABLE_NAME => lc $field->{SQL_FIELD}, TP_INFO_FIELDS => $attr->{TP_INFO_FIELDS} || 0, COLS_NAME => 1 }),
    SEL_OPTIONS   => { '' => '--' },
    NO_ID         => 1,
    ID            => $field->{SQL_FIELD},
    EX_PARAMS     => $attr->{DISABLED},
    OUTPUT2RETURN => 1
  });
}

1;