package Storage::Incoming_articles_extended_table;

use strict;
use warnings;
use Time::Local;
use Abills::Base qw/in_array _bp vars2lang/;

use Storage;
my Storage $Storage;

#**********************************************************
=head2 new($db, $admin, $conf, $attr) - Constructor for the Incoming_articles_extended_table

  Arguments:
    $db    => Database handle.
    $admin => Admin user object.
    $conf  => Configuration hashref.
    $attr  => Hashref of additional attributes:

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = bless {
    db                     => $db,
    admin                  => $admin,
    conf                   => $conf,
    attr                   => $attr,
    html                   => $attr->{html},
    lang                   => $attr->{lang},

    main_fields            => [
      'ARTICLE_NAME',
      'ARTICLE_TYPE_NAME',
      'STORAGE_NAME',
      'TOTAL_COUNT',
      'WITHOUT_SERIAL',
      'WITH_SERIAL',
    ],
    enabled_sub_fields     => [
      'ARTICLE_NAME', 'SERIAL', 'IDENT1', 'IDENT2', 'IDENT3', 'IDENT4',
      'DATE', 'INVOICE_ID', 'ARTICLE_PRICE', 'SELL_PRICE',
      'SIA_COUNT', 'SUPPLIER_NAME', 'SN_COMMENTS', 'SI_COMMENTS',
      'INVOICE_NAME', 'SIA_ID',
    ],
    default_sub_fields     => [
      'ARTICLE_NAME', 'SERIAL', 'DATE', 'ARTICLE_PRICE',
      'SIA_COUNT', 'SUPPLIER_NAME', 'SI_COMMENTS', 'SIA_ID'
    ],
    sub_fields             => [],

    group_by_fields        => [ 'article_name', 'article_type_name', 'storage_name' ],
    show_empty_groups      => 0,
    collapse_single_items  => 0,
    highlight_recent_items => 1,
    recent_days            => 20,
  }, $class;

  my @enabled_columns = ();

  if (ref $self->{admin} eq 'Admins' && $self->{admin}->can('settings_info')) {
    $self->{admin}->settings_info('STORAGE_ITEMS');
    if ($self->{admin}->{TOTAL} > 0 && $self->{admin}->{SETTING}) {
      @enabled_columns = split /, /, $self->{admin}->{SETTING};
    }
  }

  if (@enabled_columns) {
    $self->{sub_fields} = [
      grep {in_array($_, \@enabled_columns)} @{$self->{enabled_sub_fields}}
    ];
  }
  else {
    $self->{sub_fields} = [ @{$self->{default_sub_fields}} ];
  }

  $self->{col_titles} = {
    ARTICLE_NAME      => $self->{lang}{NAME} || 'Name',
    ARTICLE_TYPE_NAME => $self->{lang}{TYPE} || 'Type',
    STORAGE_NAME      => $self->{lang}{STORAGE} || 'Storage',
    SERIAL            => $self->{lang}{SERIAL} || 'SN',
    TOTAL_COUNT       => $self->{lang}{STORAGE_TOTAL_COUNT} || 'Total Count',
    WITH_SERIAL       => $self->{lang}{STORAGE_WITH_SERIAL_NUMBERS} || 'With Serial Numbers',
    WITHOUT_SERIAL    => $self->{lang}{STORAGE_WITHOUT_SERIAL_NUMBERS} || 'Without Serial Numbers',
    IDENT1            => $self->{lang}{IDENT1},
    IDENT2            => $self->{lang}{IDENT2},
    IDENT3            => $self->{lang}{IDENT3},
    IDENT4            => $self->{lang}{IDENT4},
    DATE              => $self->{lang}{DATE} || 'Date',
    INVOICE_ID        => $self->{lang}{STORAGE_INVOICE} || 'Invoice',
    SIA_COUNT         => $self->{lang}{COUNT} || 'Count',
    SIA_ID            => $self->{lang}{ACTIONS_LIST} || 'Actions',
    SI_COMMENTS       => $self->{lang}{COMMENTS} || 'Comments',
    SN_COMMENTS       => $self->{lang}{NOTES} || 'Notes',
    SUPPLIER_NAME     => $self->{lang}{SUPPLIERS} || 'Supplier',
    ARTICLE_PRICE     => $self->{lang}{PRICE} || 'Price',
    SELL_PRICE        => $self->{lang}{SELL_PRICE} || 'Sell Price',
    INVOICE_NAME      => $self->{lang}{INVOICE_NUMBER} || 'Invoice Number',
  };

  $Storage = Storage->new($self->{db}, $self->{$admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 generate_table($items_list) - Generate grouped items table

  Arguments:
    $items_list - Arrayref of items to be displayed

  Returns:
    HTML string with grouped items table or empty string if no items

  Example:

    $Incoming_articles_extended_table->generate_table($items);

=cut
#**********************************************************
sub generate_table {
  my ($self, $items_list) = @_;

  if (!$items_list || scalar(@$items_list) < 1) {
    return '';
  }

  my $grouped_items = $self->_group_items($items_list);

  my $group_stats = $self->_calculate_group_stats($grouped_items);

  return $self->_render_table($grouped_items, $group_stats);
}

#**********************************************************
=head2 _group_items($items_list) - Group items by configured fields

  Arguments:
    $items_list - Arrayref of items to be grouped

  Returns:
    Hashref where keys are group identifiers (concatenation of field values)
    and values are arrayrefs of items belonging to that group

  Example:

    my $grouped_items = $self->_group_items($items);

=cut
#**********************************************************
sub _group_items {
  my ($self, $items_list) = @_;

  my %groups;
  my $group_fields = $self->{group_by_fields};

  foreach my $item (@$items_list) {
    my $group_key = join '|||', map {$item->{$_} // 'NULL'} @$group_fields;
    push @{$groups{$group_key}}, $item;
  }

  return \%groups;
}

#**********************************************************
=head2 _calculate_group_stats($grouped_items) - Calculate statistics for each group

  Arguments:
    $grouped_items - Hashref of grouped items (from _group_items)

  Returns:
    Hashref where keys are group identifiers and values are hashrefs with:
      total_count    - Sum of 'sia_count' for all items in the group
      with_serial    - Number of items with serial numbers
      without_serial - Number of items without serial numbers
      items_count    - Total number of items in the group
      recent_items   - Arrayref of recently added/highlighted items
      first_item     - Reference to the first item in the group

  Example:

    my $group_stats = $self->_calculate_group_stats($grouped_items);

=cut
#**********************************************************
sub _calculate_group_stats {
  my ($self, $grouped_items) = @_;

  my %stats;

  foreach my $group_key (keys %$grouped_items) {
    my $items = $grouped_items->{$group_key};
    my $items_count = @$items;

    my ($total_count, $with_serial, $without_serial) = (0, 0, 0);
    my @recent_items;

    foreach my $item (@$items) {
      $total_count += ($item->{sia_count} || 1);

      if ($item->{serial}) {
        $with_serial++;
      }
      else {
        $without_serial++;
      }

      if ($self->{highlight_recent_items} && $self->_is_recent_item($item)) {
        push @recent_items, $item;
      }
    }

    $stats{$group_key} = {
      total_count    => $total_count,
      with_serial    => $with_serial,
      without_serial => $without_serial,
      items_count    => $items_count,
      recent_items   => \@recent_items,
      first_item     => $items->[0],
    };
  }

  return \%stats;
}

#**********************************************************
=head2 _is_recent_item($item) - Check if an item is considered recent

  Arguments:
    $item - Hashref representing a single item (must contain 'date' field)

  Returns:
    Boolean (1 or 0)
      1 - if the item's date is within the configured recent_days
      0 - otherwise or if highlighting is disabled

  Example:

    my $is_recent = $self->_is_recent_item($item);

=cut
#**********************************************************
sub _is_recent_item {
  my ($self, $item) = @_;

  return 0 if !$self->{highlight_recent_items};
  return 0 if !$item->{date};

  my $item_date = $item->{date};
  my $is_recent = 0;

  if ($item_date =~ /^(\d{4})-(\d{2})-(\d{2})/) {
    my ($year, $month, $day) = ($1, $2, $3);

    eval {
      my $item_timestamp = timelocal(0, 0, 0, $day, $month - 1, $year - 1900);
      my $diff_days = (time - $item_timestamp) / 86400;
      $is_recent = $diff_days <= $self->{recent_days};
    };
  }

  return $is_recent;
}

#**********************************************************
=head2 _render_table($grouped_items, $group_stats) - Render HTML table for grouped items

  Arguments:
    $grouped_items - Hashref of grouped items (from _group_items)
    $group_stats   - Hashref of group statistics (from _calculate_group_stats)

  Returns:
    HTML string representing the table with groups and subtables.
    - Each group is displayed with a summary row.
    - Subtables show individual items if group has multiple items
      or collapse_single_items is disabled.

  Example:

    $self->_render_table($grouped_items, $group_stats);

=cut
#**********************************************************
sub _render_table {
  my ($self, $grouped_items, $group_stats) = @_;

  my $table = $self->{html}->table({
    width       => '100%',
    caption     => $self->{lang}{ARTICLES},
    ID          => 'STORAGE_ITEMS',
    class       => 'table table-hover table-striped',
    title       => [ map {$self->{col_titles}->{$_} // $_} @{$self->{main_fields}} ],
    MENU        => "$self->{lang}{ADD}:get_index=storage_main&full=1&add_article=1:add",
    EXPORT      => 1,
    IMPORT      => "?get_index=storage_main&add_article=1&import=1&header=2",
    SHOW_COLS   => { $self->{lang}{ARTICLES} => $self->{col_titles} },
    ACTIVE_COLS => { map {$_ => 1} @{$self->{sub_fields}} },
  });
  my $counter = 0;

  foreach my $group_key (keys %{$grouped_items}) {
    $counter++;

    my $items = $grouped_items->{$group_key};
    my $stats = $group_stats->{$group_key};

    next if !$self->{show_empty_groups} && $stats->{items_count} == 0;

    $self->_add_group_row($table, $group_key, $stats, $counter);

    if ($stats->{items_count} > 1 || !$self->{collapse_single_items}) {
      $self->_add_subtable_row($table, $items, $counter, $stats);
    }
  }

  return $table->show();
}

#**********************************************************
=head2 _add_group_row($table, $group_key, $stats, $counter) - Add summary row for a group

  Arguments:
    $table      - HTML table object to add the row to
    $group_key  - Key identifying the group
    $stats      - Hashref of statistics for the group (from _calculate_group_stats)
    $counter    - Row counter used for unique IDs

  Example:

    $self->_add_group_row($table, $group_key, $stats, $counter);

=cut
#**********************************************************
sub _add_group_row {
  my ($self, $table, $group_key, $stats, $counter) = @_;

  my $first_item = $stats->{first_item};
  my @row_data;

  foreach my $field (@{$self->{main_fields}}) {
    my $value = $self->_get_group_field_value($field, $stats, $first_item);
    push @row_data, $value;
  }

  my $row_class = "clickable group-row";
  $row_class .= " table-warning" if @{$stats->{recent_items}} > 0;

  my $row_id = "group_$counter";

  $table->{row_extra} = qq{class="$row_class" data-toggle="collapse" data-target="#$row_id" style="cursor: pointer;"};
  $table->addrow(@row_data);
  delete $table->{row_extra};
}

#**********************************************************
=head2 _get_group_field_value($field, $stats, $first_item) - Get value for a group field

  Arguments:
    $field      - Name of the field to retrieve
    $stats      - Hashref of statistics for the group (from _calculate_group_stats)
    $first_item - Hashref of the first item in the group

  Returns:
    Value corresponding to the requested field:
      - Uses group statistics for TOTAL_COUNT, WITH_SERIAL, WITHOUT_SERIAL
      - Otherwise, returns the value from the first item in the group
      - Returns empty string if field not found

  Example:

    my $value = $self->_get_group_field_value('TOTAL_COUNT', $stats, $first_item);

=cut
#**********************************************************
sub _get_group_field_value {
  my ($self, $field, $stats, $first_item) = @_;

  return $stats->{total_count} if $field eq 'TOTAL_COUNT';
  return $stats->{with_serial} if $field eq 'WITH_SERIAL';
  return $stats->{without_serial} if $field eq 'WITHOUT_SERIAL';

  return $first_item->{lc($field)} // '';
}

#**********************************************************
=head2 _add_subtable_row($table, $items, $counter, $stats) - Add subtable row for group items

  Arguments:
    $table    - HTML table object to add the row to
    $items    - Arrayref of items in the group
    $counter  - Row counter used for unique IDs
    $stats    - Hashref of group statistics (from _calculate_group_stats)

  Example:

    $self->_add_subtable_row($table, $items, $counter, $stats);

=cut
#**********************************************************
sub _add_subtable_row {
  my ($self, $table, $items, $counter, $stats) = @_;

  my $subtable_html = $self->_generate_subtable($items, $stats);
  my $row_id = "group_$counter";
  my $collapse_class = ($stats->{items_count} == 1 && $self->{collapse_single_items})
    ? "collapse show" : "collapse";

  $table->{row_extra} = qq{class="$collapse_class bg-light" id="$row_id"};
  $table->{extra} = qq{colspan="@{[ scalar @{$self->{main_fields}} ]}"};

  $table->addrow($subtable_html);

  delete $table->{row_extra};
  delete $table->{extra};
}

#**********************************************************
=head2 _generate_subtable($items, $stats) - Generate HTML subtable for group items

  Arguments:
    $items - Arrayref of items in the group
    $stats - Hashref of group statistics (from _calculate_group_stats)

  Returns:
    HTML string representing a subtable of individual items
    - Uses configured sub_fields for columns
    - Highlights recent items if highlight_recent_items is enabled

  Example:

    $self->_generate_subtable($items, $stats);

=cut
#**********************************************************
sub _generate_subtable {
  my ($self, $items, $stats) = @_;

  my $subtable = $self->{html}->table({
    width => '100%',
    class => 'table table-sm table-borderless mb-0',
    title => [ map {$self->{col_titles}->{$_} // $_} @{$self->{sub_fields}} ],
  });

  foreach my $item (@$items) {
    my @row_data;

    foreach my $field (@{$self->{sub_fields}}) {
      my $value = $self->_get_subtable_field_value($field, $item);
      push @row_data, $value;
    }

    my $row_class = ($self->{highlight_recent_items} && $self->_is_recent_item($item))
      ? "table-success" : '';

    $subtable->{row_extra} = qq{class="$row_class"} if $row_class;
    $subtable->addrow(@row_data);
    delete $subtable->{row_extra};
  }

  return $subtable->show();
}

#**********************************************************
=head2 _get_subtable_field_value($field, $item) - Get value for a subtable field

  Arguments:
    $field - Name of the subtable field
    $item  - Hashref representing a single item

  Returns:
    Value corresponding to the requested field:
      - For 'SIA_ID', returns actions dropdown HTML
      - For 'SIA_COUNT', returns formatted count table HTML
      - For 'DATE', returns formatted date string
      - Otherwise, returns the item's field value or empty string if not present

  Example:

    my $value = $self->_get_subtable_field_value('DATE', $item);

=cut
#**********************************************************
sub _get_subtable_field_value {
  my ($self, $field, $item) = @_;

  return $self->_generate_actions_dropdown($item) if $field eq 'SIA_ID';
  return $self->_generate_count_table($item) if $field eq 'SIA_COUNT';

  my $value = $item->{lc($field)} // '';

  if ($field eq 'DATE' && $value) {
    $value = $self->_format_date($value);
  }

  return $value;
}

#**********************************************************
=head2 _generate_actions_dropdown($item) - Generate HTML actions dropdown for an item

  Arguments:
    $item - Hashref representing a single item (must contain fields like id, article_name, sia_count, storage_id, supplier_id)

  Returns:
    HTML string representing a dropdown menu with action buttons for the item:
      - INFO, DIVIDE, DELETE (if permitted)
      - TO_ACCOUNTABILITY, TO_RESERVE, TO_DISCARD, TO_INNER_USE
      - TRANSFER_ITEM, REMOVE_LEFTOVERS
      - LOG, QrCode

  Example:

    my $dropdown_html = $self->_generate_actions_dropdown($item);

=cut
#**********************************************************
sub _generate_actions_dropdown {
  my ($self, $item) = @_;

  my $id = $item->{id} || $item->{storage_main_id} || '';
  my $article_name = $item->{article_name} || '';
  my $count = $item->{sia_count} || '';
  my $storage_id = $item->{storage_id} || '';
  my $supplier_id = $item->{supplier_id} || '';

  my $storage_full_access = !defined($Storage->{STORAGE_ADMIN_PERMISSIONS});

  return '' if ($storage_id && !$storage_full_access && !defined($Storage->{STORAGE_ADMIN_PERMISSIONS}{$storage_id}));

  my @buttons;

  if ($count && $count < 2) {
    push @buttons, $self->{html}->button($self->{lang}{INFO}, "get_index=storage_main&full=1&add_article=1&chg=$id&sn=1", { class => 'dropdown-item' });
  }
  else {
    push @buttons, $self->{html}->button($self->{lang}{DIVIDE}, "get_index=storage_main&start_divide=$id&full=1",
      { class => 'dropdown-item cursor-pointer' });
    push @buttons, $self->{html}->button($self->{lang}{INFO}, "get_index=storage_main&full=1&add_article=1&chg=$id&sn=1", { class => 'dropdown-item' });
  }

  if ($storage_full_access || $Storage->{STORAGE_ADMIN_PERMISSIONS}{$storage_id}) {

    if ($self->{admin}{permissions}{0}{5}) {
      push @buttons, $self->{html}->button($self->{lang}{DEL}, "get_index=storage_main&full=1&add_article=1&del=$id", {
        class   => 'dropdown-item cursor-pointer',
        MESSAGE => $self->{lang}{DEL} . " $article_name?"
      });
    }

    push @buttons, $self->{html}->button($self->{lang}{TO_ACCOUNTABILITY}, "get_index=storage_main&full=1&accountability=$id", { class => 'dropdown-item' });
    push @buttons, $self->{html}->button($self->{lang}{TO_RESERVE}, "get_index=storage_main&full=1&reserve=$id", { class => 'dropdown-item' });
    push @buttons, $self->{html}->button($self->{lang}{TO_DISCARD}, "get_index=storage_main&full=1&discard=$id", { class => 'dropdown-item' });
    push @buttons, $self->{html}->button($self->{lang}{TO_INNER_USE}, "get_index=storage_main&full=1&inner_use=$id", { class => 'dropdown-item' });

    push @buttons, $self->{html}->button($self->{lang}{TRANSFER_ITEM}, "get_index=storage_main&&move=1&incoming_article_id=$id&supplier_id=$supplier_id&header=2&storage_id=$storage_id",
      { LOAD_TO_MODAL => 1, class => 'dropdown-item cursor-pointer' });

    push @buttons, $self->{html}->button($self->{lang}{REMOVE_LEFTOVERS}, "get_index=storage_main&full=1&&del_leftover=$id",
      { MESSAGE => $self->{lang}{REMOVE_LEFTOVERS} . " $article_name?", class => 'dropdown-item' });
  }

  push @buttons, $self->{html}->button($self->{lang}{LOG}, "get_index=storage_log&full=1&STORAGE_MAIN_ID=$id&search=1", { class => 'dropdown-item' });
  push @buttons, $self->{html}->button("QrCode", "get_index=storage_main&qr_code=$id&header=2", { target => '_blank', class => 'dropdown-item' });

  my $span_caret = $self->{html}->element('span', '', { class => 'caret' });

  my $dropdown_button = $self->{html}->element('button', ($self->{lang}{ACTIONS_LIST} || 'Дії') . $span_caret, {
    class           => 'btn btn-default btn-block dropdown-toggle',
    id              => "dropdownMenu_$id",
    type            => 'button',
    'data-toggle'   => 'dropdown',
    'aria-haspopup' => 'true',
    'aria-expanded' => 'false',
    'data-boundary' => 'window'
  });

  my $dropdown_menu = $self->{html}->element('div', join('', @buttons), {
    class             => 'dropdown-menu',
    'aria-labelledby' => "dropdownMenu_$id"
  });

  return $self->{html}->element('div', $dropdown_button . $dropdown_menu, { class => "dropdown" });
}

#**********************************************************
=head2 _generate_count_table($item) - Generate mini count table for an item

  Arguments:
    $item - Hashref representing a single item (fields include sia_count, inner_use_count, instalation_count, discard_count, reserve_count, accountability_count, measure_name, total)

  Returns:
    HTML string representing a compact table with counts:
      - INSTALLED, ACCOUNTABILITY, RESERVED, DISCARDED, INNER_USE, LEFTOVER, TOTAL

  Example:

    my $count_table = $self->_generate_count_table($item);

=cut
#**********************************************************
sub _generate_count_table {
  my ($self, $item) = @_;

  my $sia_count = $item->{sia_count} || 0;
  my $inner_use_count = $item->{inner_use_count} || 0;
  my $installation_count = $item->{instalation_count} || 0;
  my $discard_count = $item->{discard_count} || 0;
  my $reserve_count = $item->{reserve_count} || 0;
  my $accountability_count = $item->{accountability_count} || 0;
  my $measure_name = ::_translate($item->{measure_name} || '');
  my $total = $item->{total} || 0;

  my $table = $self->{html}->table({
    width  => '100%',
    title  => [ '-', '-' ],
    ID     => 'STORAGE_MINI_TOTAL',
    MENU   => "",
    EXPORT => 0,
  });

  $table->addrow($self->{lang}{INSTALLED}, $installation_count . " " . $measure_name);
  $table->addrow($self->{lang}{ACCOUNTABILITY}, $accountability_count . " " . $measure_name);
  $table->addrow($self->{lang}{RESERVED}, $reserve_count . " " . $measure_name);
  $table->addrow($self->{lang}{DISCARDED}, $discard_count . " " . $measure_name);
  $table->addrow($self->{lang}{INNER_USE}, $inner_use_count . " " . $measure_name);
  $table->addrow($self->{lang}{LEFTOVER}, $total . " " . $measure_name);
  $table->addrow($self->{lang}{TOTAL}, ($sia_count + $installation_count + $discard_count + $inner_use_count) . " " . $measure_name);

  return $table->show();
}

#**********************************************************
=head2 _format_date($date_str) - Format a date string for display

  Arguments:
    $date_str - String in format "YYYY-MM-DD HH:MM:SS"

  Returns:
    Formatted HTML string:
      - Date on one line
      - Time in smaller, muted text below
    - If input does not match expected format, returns it unchanged

  Example:

    $self->_format_date('2025-08-21 14:35:00');

=cut
#**********************************************************
sub _format_date {
  my ($self, $date_str) = @_;

  if ($date_str =~ /^(\d{4}-\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})$/) {
    return "$1<br><small class='text-muted'>$2</small>";
  }

  return $date_str;
}

1;
