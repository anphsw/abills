=head1 NAME

  Multiusers operations

=cut

use strict;
use warnings;
use Abills::Base qw(in_array);

our(
  $db,
  %conf,
  $admin,
  %lang,
  @WEEKDAYS,
  @MONTHES
);

our Abills::HTML $html;

#********************************************************
=head2 form_multiuser($attr) - Companies amdin

  Arguments:
    $attr
      USER_INFO
      USERS_TABLE
      USERS_TOTAL_TABLE
      FORM_NAME - Main form name
      FORM - %FORM hash

  Results:
    TRUE or FALSE

=cut
#********************************************************
sub form_multiuser {
  my ($attr) = @_;

  my $form = $attr->{FORM};
  $html->{FORM_ID} = 'users_list';

  my $mu_comments_radio1_input = $html->form_input('optradio', 'append', { TYPE => 'radio', class => 'form-check-input', EX_PARAMS => 'id="radio1" checked' }) . "  $lang{APPEND}";
  my $mu_comments_radio2_input = $html->form_input('optradio', 'change', { TYPE => 'radio', class => 'form-check-input', EX_PARAMS => 'id="radio2"' }) . "  $lang{CHANGE}";
  my $mu_comments_radio1_label = $html->element('label', $mu_comments_radio1_input, { class => 'form-check-label', for => 'radio1' });
  my $mu_comments_radio2_label = $html->element('label', $mu_comments_radio2_input, { class => 'form-check-label', for => 'radio2' });
  my $mu_comments_radio1 = $html->element('div', $mu_comments_radio1_label, { class => 'form-check' });
  my $mu_comments_radio2 = $html->element('div', $mu_comments_radio2_label, { class => 'form-check' });
  my $mu_comments_radio_div = $html->element('div', $mu_comments_radio1 . $mu_comments_radio2, { class => 'col-md-6' });
  my $mu_comments_textarea = $html->element('textarea', $form->{COMMENTS_TEXT}, { name => "COMMENTS_TEXT", rows => "4", cols => "50", form => "users_list" });
  my $mu_comments_textarea_div = $html->element('div', $mu_comments_textarea, { class => 'col-md-6' });
  my $mu_comments_row = $html->element('div', $mu_comments_textarea_div . $mu_comments_radio_div, { class => 'row' });

  my @multi_operation = (
    [ $html->form_input('MU_GID', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{GROUP},
      sel_groups({ SKIP_MULTISELECT => 1 }) ],
    [ $html->form_input('MU_DISABLE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{DISABLE},
      $html->form_input('DISABLE', "1", { TYPE => 'checkbox', class => 'mr-1' }) . $lang{CONFIRM} ],
    [ $html->form_input('MU_DEL', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{DEL},
      $html->form_input('DEL', "1", { TYPE => 'checkbox', class => 'mr-1' }) . $lang{CONFIRM} ],
    [ $html->form_input('MU_ACTIVATE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{ACTIVATE},
      $html->date_fld2('ACTIVATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
    [ $html->form_input('MU_EXPIRE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{EXPIRE},
      $html->date_fld2('EXPIRE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
    [ $html->form_input('MU_CREDIT', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{CREDIT},
      $html->form_input('CREDIT', $form->{CREDIT}) ],
    [ $html->form_input('MU_CREDIT_DATE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . "$lang{CREDIT} $lang{DATE}",
      $html->date_fld2('CREDIT_DATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1, DATE => $form->{CREDIT_DATE} }) ],
    [ $html->form_input('MU_REDUCTION', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{REDUCTION},
      $html->form_input('REDUCTION', $form->{REDUCTION}, { TYPE => 'number', EX_PARAMS => "class='form-control' step='0.1'" }) ],
    [ $html->form_input('MU_REDUCTION_DATE', 1, { TYPE => 'checkbox', class => 'mr-1' }) . "$lang{REDUCTION} $lang{DATE}",
      $html->date_fld2('REDUCTION_DATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1, DATE => $form->{CREDIT_DATE} }) ],
    [ $html->form_input('MU_COMMENTS', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{COMMENTS}, $mu_comments_row ],
    [ '', $html->form_input('MULTIUSER', $lang{APPLY}, { TYPE => 'submit' }) ],
  );

  if (in_array('Msgs', \@MODULES)) {
    load_module('Msgs', $html);
    my $delivery_form = msgs_mu_delivery_form();
    if ($delivery_form) {
      @multi_operation = ([ $html->form_input('MU_DELIVERY', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{DELIVERY}, $delivery_form ],
        @multi_operation);
    }
  }

  #Ureport muliuser select options
  if (in_array('Ureports', \@MODULES)) {
    load_module('Ureports', $html);

    my $load_to_modal_btn = $html->button($lang{ADD}, 'qindex=' . get_function_index('ureports_multiuser_sel') .
      '&header=2&FORM_ID=users_list', {
      LOAD_TO_MODAL => 1,
      class         => 'btn btn-default',
    });

    @multi_operation = (
      [
        $html->form_input('MU_UREPORTS_TP', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{NOTIFICATIONS},
        $load_to_modal_btn
      ],
      @multi_operation,
    );
  }

  #Tags muliuser select options
  if (in_array('Tags', \@MODULES)) {
    load_module('Tags', $html);
    my $load_to_modal_btn = $html->button($lang{ADD}, 'qindex=' . get_function_index('tags_multiuser_form') .
      "&header=2&MULTIUSER_INDEX=$index&FORM_ID=users_list", {
      LOAD_TO_MODAL => 1,
      class         => 'btn btn-default',
    });

    my $mu_tags_radio1_input = $html->form_input('OPT_TAGS_RADIO', 'TAGS_APPEND', { TYPE => 'radio', class => 'form-check-input', EX_PARAMS => 'id="tags-radio-append"' }) . "  $lang{APPEND}";
    my $mu_tags_radio2_input = $html->form_input('OPT_TAGS_RADIO', 'TAGS_CHANGE', { TYPE => 'radio', class => 'form-check-input', EX_PARAMS => 'id="tags-radio-change" checked' }) . "  $lang{CHANGE}";
    my $mu_tags_radio1_label = $html->element('label', $mu_tags_radio1_input, { class => 'form-check-label', for => 'radio1' });
    my $mu_tags_radio2_label = $html->element('label', $mu_tags_radio2_input, { class => 'form-check-label', for => 'radio2' });
    my $mu_tags_radio1 = $html->element('div', $mu_tags_radio1_label, { class => 'form-check' });
    my $mu_tags_radio2 = $html->element('div', $mu_tags_radio2_label, { class => 'form-check' });
    my $mu_tags_radio_div = $html->element('div', $mu_tags_radio1 . $mu_tags_radio2, { class => 'col-md-6' });
    my $mu_tags_textarea_div = $html->element('div', $load_to_modal_btn, { class => 'col-md-6' });
    my $mu_tags_row = $html->element('div', $mu_tags_textarea_div . $mu_tags_radio_div, { class => 'row' });

    @multi_operation = (
      [
        $html->form_input('MU_TAGS', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{TAGS},
        $mu_tags_row
      ],
      @multi_operation,
    );
  }

  #Bonus muliuser select options
  if (in_array('Bonus', \@MODULES)) {
    load_module('Bonus', $html);

    @multi_operation = (
      [
        $html->form_input('MU_BONUS', 1, { TYPE => 'checkbox', class => 'mr-1' }) . $lang{BONUS},
        $html->form_input('BONUS', '', { TYPE => 'number', EX_PARAMS => "class='form-control' step='0.1'" }),
      ],
      @multi_operation,
    );
  }

  if (in_array('Discounts', \@MODULES)) {
    load_module('Discounts', $html);
    @multi_operation = (discounts_mu_form(), @multi_operation);
  }

  my Abills::HTML $table3 = $html->table({
    caption    => $lang{MULTIUSER_OP},
    HIDE_TABLE => 1,
    rows       => \@multi_operation,
    ID         => 'USER_MANAGMENT'
  });

  my $main_table = ($attr->{USERS_TABLE} && ref $attr->{USERS_TABLE} eq 'Abills::HTML') ? $attr->{USERS_TABLE}->show({ OUTPUT2RETURN => 1 }) : ($attr->{USERS_TABLE} || q{});
  my $total_table = (!$admin->{MAX_ROWS} && $attr->{USERS_TOTAL_TABLE}) ? $attr->{USERS_TOTAL_TABLE}->show({ OUTPUT2RETURN => 1, DUBLICATE_DATA => 1 }) : '';
  my $multioperation_form = $table3->show({ OUTPUT2RETURN => 1, DUBLICATE_DATA => 1 });

  print $html->form_main({
    CONTENT => $main_table
      . $total_table
      . $multioperation_form,
    HIDDEN  => {
      #UID   => $attr->{UID},
      index => 11,
    },
    NAME    => $attr->{FORM_NAME} || 'users_list',
    class   => 'hidden-print',
    ID      => 'users_list',
  });

  return 1;
}

#**********************************************************
=head2 form_multiuser_actions($attr) - Multiuser operation

  Arguments:
    $attr
      FORM

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub form_multiuser_actions {
  my ($attr)=@_;

  my $form = $attr->{FORM};
  my @multiuser_list = split(/,\s/x, $form->{IDS} || q{});
  my $result;

  my %CHANGE_PARAMS = (
    SKIP_STATUS_CHANGE => ($form->{DISABLE}) ? undef : 1
  );

  if ($form->{MU_COMMENTS}) {
    append_comments(\@multiuser_list, $form->{COMMENTS_TEXT});
    delete($form->{MU_COMMENTS});
  }

  while (my ($k, undef) = each %{ $form }) {
    if ($k =~ m/^MU_(\S+)/x) {
      my $val = $1;
      $CHANGE_PARAMS{$val} = $form->{$val};
    }
  }

  if (!defined($form->{DISABLE})) {
    $CHANGE_PARAMS{UNCHANGE_DISABLE} = 1;
  }
  else {
    $CHANGE_PARAMS{DISABLE} = $form->{MU_DISABLE} || 0;
  }

  if ($#multiuser_list < 0) {
    $html->message('err', $lang{MULTIUSER_OP}, $lang{SELECT_USER});
  }
  elsif ($form->{MU_TAGS} && in_array('Tags', \@MODULES)) {
    require Tags;
    my $Tags = Tags->new($db, $admin, \%conf);

    foreach my $id (@multiuser_list) {
      $Tags->tags_user_change({
        IDS     => $form->{TAGS_IDS},
        UID     => $id,
        REPLACE => $form->{OPT_TAGS_RADIO} && $form->{OPT_TAGS_RADIO} eq 'TAGS_APPEND' ? 1 : 0
      });
      $html->message('err', $lang{INFO}, "$lang{TAGS} $lang{NOT} $lang{ADDED} UID:$id") if ($Tags->{errno});
    }
  }
  elsif (defined($form->{MU_UREPORTS_TP} && in_array('Ureports', \@MODULES))) {
    require Ureports::Services;
    my $Ureports_services = Ureports::Services->new($db, $admin, \%conf);
    $Ureports_services->ureport_add_multiple_users({
      %$form,
      R_IDS  => $form->{R_IDS},
      TP_ID  => $form->{UREPORTS_TP},
      STATUS => $form->{UREPORTS_STATUS},
      UIDS   => [ split(',\s?', $form->{IDS}) ],
      TYPE   => [ split(',\s?', $form->{UREPORTS_TYPE}) ]
    });

    $html->message('err', $lang{INFO}, "$lang{TARIF_PLAN} $lang{NOT} $lang{ADDED} UID:$Ureports_services->{FAILED_USERS}") if ($Ureports_services->{FAILED_USERS});
    $html->message('info', $lang{INFO}, "$Ureports_services->{TOTAL} $lang{ADDED}") if ($Ureports_services->{TOTAL});
  }
  elsif (defined($form->{MU_BONUS} && in_array('Bonus', \@MODULES)) && $form->{MU_BONUS} == 1) {
    load_module('Bonus', $html);
    bonus_multi_add($form);
  }
  elsif ($form->{MU_DELIVERY} || $form->{DELIVERY_CREATE}) {
    load_module('Msgs', $html);
    msgs_mu_delivery_add($form)
  }
  elsif ($form->{MU_DISCOUNTS}) {
    load_module('Discounts', $html);
    $result = discounts_mu_add($form);
  }
  elsif (scalar keys %CHANGE_PARAMS < 1) {
    #$html->message('err', $lang{MULTIUSER_OP}, "$lang{SELECT_USER}");
  }
  else {
    foreach my $uid (@multiuser_list) {
      if ($form->{DEL} && $form->{MU_DEL}) {
        my $user_info = $users->info($uid);
        user_del({ USER_INFO => $user_info });

        _error_show($users);
      }
      else {
        $users->change($uid, { UID => $uid, %CHANGE_PARAMS });
        if (_error_show($users)) {
          return 0;
        }
      }
    }
    $result->{''} = { message => " IDS: $form->{IDS} " };
  }


  if ($result && ref $result eq 'HASH') {
    my $result_message = q{};
    foreach my $id (keys %$result) {
      $result_message .= $html->br(). "$id -> ". ($result->{$id}{message} || 'Ok');
    }

    $html->message('info', $lang{MULTIUSER_OP}, "$lang{TOTAL}: " . ($#multiuser_list + 1) .  $result_message );
  }

  return 1;
}

1;