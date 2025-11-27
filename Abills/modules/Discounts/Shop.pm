=head1 NAME

 For discounts shop if exist $conf{DISCOUNTS_SHOP}

=cut

use strict;
use warnings FATAL => 'all';
use Discounts;

our (
  $db,
  $admin,
  %conf,
  %lang,
  $html,
  $users,
  %FORM,
);

my $Discounts = Discounts->new($db, $admin, \%conf);

#**********************************************************
=head2 discounts_shop_add() - function for adding shop discounts

  Arguments:
    attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub discounts_shop_add {

  my $action = 'add';
  my $action_lang = "$lang{ADD}";
  my %DISCOUNT;

  if ($FORM{add}) {
    $Discounts->discount_add({ %FORM });
    if (!$Discounts->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{DISCOUNT_ADDED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{DISCOUNT_NOT_ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Discounts->discount_change({ %FORM });
    if (!$Discounts->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{DISCOUNT_CHANGED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{DISCOUNT_NOT_CHANGED}");
    }
  }

  if ($FORM{chg}) {
    my $discount_info = $Discounts->discount_info({ ID => $FORM{chg} });
    $html->message("info", "$lang{CHANGE_DATA}");

    if (!$Discounts->{errno}) {
      $action = 'change';
      $action_lang = "$lang{CHANGE}";
      $DISCOUNT{NAME} = $discount_info->{NAME};
      $DISCOUNT{SIZE} = $discount_info->{SIZE};
      $DISCOUNT{COMMENTS} = $discount_info->{COMMENTS};
      $DISCOUNT{ID} = $FORM{chg};
    }
  }

  if ($FORM{del}) {
    $Discounts->discount_delete({ ID => $FORM{del} });

    if (!$Discounts->{errno}) {
      $html->message("success", "$lang{SUCCESS}", "$lang{DISCOUNT_DELETED}");
    }
    else {
      $html->message("err", "$lang{ERROR}", "$lang{DISCOUNT_NOT_DELETED}");
    }
  }

  $html->tpl_show(_include('discounts_discounts_add', 'Discounts'), {
    %DISCOUNT,
    ACTION      => $action,
    ACTION_LANG => $action_lang,
  });

  result_former({
    INPUT_DATA      => $Discounts,
    FUNCTION        => 'discount_list',
    BASE_FIELDS     => 4,
    DEFAULT_FIELDS  => "id, name, size, comments",
    FUNCTION_FIELDS => 'change, del',
    EXT_TITLES      => {
      'name'     => $lang{NAME},
      'id'       => 'ID',
      'size'     => "$lang{SIZE}(%)",
      'comments' => $lang{COMMENTS}
    },
    TABLE           => {
      width   => '100%',
      caption => $lang{DISCOUNTS},
      qs      => $pages_qs,
      ID      => 'DISCOUNTS',
      header  => '',
      EXPORT  => 1,
      #MENU    => "$lang{ADD}:index=" . get_function_index('ring_rule_add') . ':add' . ";$lang{SEARCH}:index=$index&search_form=1:search;",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    MODULE          => 'Discounts',
    TOTAL           => 1
  });

  return 1;
}

#**********************************************************
=head2 discounts_user_shop_service() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub discounts_user_shop_service {

  if ($FORM{change}) {
    $Discounts->discount_user_change(\%FORM);

    if (!$Discounts->{errno}) {
      $html->message('success', "$lang{SUCCESS}", "$lang{DISCOUNT_CHANGED}");
    }
    else {
      $html->message('err', "$lang{ERROR}", "$lang{DISCOUNT_NOT_CHANGED}");
    }
  }

  my $discounts_list = $Discounts->discounts_user_list({ %FORM, COLS_NAME => 1 });

  my $table = $html->table({
    width   => '100%',
    caption => "$lang{DISCOUNTS}",
    title   => [ '-', "$lang{NAME}", "$lang{SIZE}(%)", $lang{DATE}, $lang{COMMENTS} ],
    #FIELDS_IDS => $Tags->{COL_NAMES_ARR},
    qs      => $pages_qs,
    ID      => 'DISCOUNT_USER',
  });

  foreach my $line (@$discounts_list) {
    $table->addrow(
      $html->form_input(
        'IDS',
        $line->{id},
        {
          TYPE  => 'CHECKBOX',
          STATE => ($line->{date}) ? 1 : undef
        }
      ),
      $line->{name},
      $line->{size},
      $line->{date},
      $line->{comments}
    );
  }

  my $action = $html->form_input('change', "$lang{CHANGE}", { TYPE => 'submit' });

  $table->{extra} = 'colspan=5 align=\'center\'';
  $table->addrow($action);

  print $html->form_main({
    CONTENT => $table->show({ OUTPUT2RETURN => 1 }),
    HIDDEN  => {
      index => $index,
      UID   => $FORM{UID},
    },
    NAME    => 'DISCOUNT_USER',
    ID      => 'DISCOUNT_USER'
  });

  return 1;
}

#**********************************************************
=head2 discounts_user($attr)

  Arguments:
    $attr -

  Returns:
    -
=cut
#**********************************************************
sub discounts_user {
  my $qrcode_hash = sprintf("%0*d", 13, $user->{UID});

  my $Bar_code = Barcode::Code128->new->FNC1;

  my $text = $Bar_code . $qrcode_hash;
  my $code = HTML::Barcode::Code128->new(
    text      => $text,
    show_text => 0
  );

  my $fio_user = $Discounts->discounts_user_query({
    UID => $user->{UID}
  });

  my $logo = '<span style="color: red;">A</span>BillS';

  if (sprintf("%.2f", $user->{DEPOSIT}) < 0.01) {
    $html->message('err', $lang{ERROR}, $lang{WARR_DEPOSIT});
  }
  else {
    $html->tpl_show(
      _include('discounts_user_card', 'Discounts'), {
      CARD_SIGN => $lang{CARD_ABON},
      FIO       => $fio_user->{list}->[0]->{fio},
      UID       => $user->{UID},
      CODE_SCAN => $code->render,
      LOGO      => $logo,
    });
  }

  return 1;
}

1;

