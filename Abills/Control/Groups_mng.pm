=head1 NAME

  Groups manage

=cut

use warnings FATAL => 'all';
use strict;
use Abills::Defs;
use Abills::Base qw(in_array);

our (
  $db,
  %lang,
  $admin,
  %permissions,
  @bool_vals,
);

our Abills::HTML $html;
our Users $users;

#**********************************************************
=head2 form_groups() - users groups

=cut
#**********************************************************
sub form_groups {

  if ($FORM{add_form}) {
    $LIST_PARAMS{PAGE_ROWS}=9999;
    if ($permissions{0} && !$permissions{0}{28}) {
      $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
      return 0
    }
    $users->{ACTION}     = 'add';
    $users->{LNG_ACTION} = $lang{ADD};
    if(in_array('Multidoms', \@MODULES)) {
      load_module('Multidoms', $html);
      $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), { ID    => '',
          NAME  => "DOMAIN_ID",
          VALUE => multidoms_domains_sel({ SHOW_ID => 1, DOMAIN_ID => $admin->{DOMAIN_ID} })
        },
        { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_groups'), $users);
    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }
    elsif ($permissions{0} && !$permissions{0}{28}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
    }
    else {
      $users->group_add({%FORM});
      if (!$users->{errno}) {
        $html->message( 'info', $lang{ADDED}, "$lang{ADDED} [". ($FORM{GID} || q{}) ."]" );
      }
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message( 'err', $lang{ERROR}, $lang{ERR_ACCESS_DENY} );
      return 0;
    }

    $users->group_change($FORM{chg}, {%FORM});
    if (!$users->{errno}) {
      $html->message( 'info', $lang{CHANGED}, "$lang{CHANGED} ". ($FORM{chg} || q{}));
    }
  }
  elsif (defined($FORM{GID}) || $FORM{chg}) {
    if ($FORM{chg}) {
      $FORM{GID} = $FORM{chg};
      delete($FORM{chg});
    }

    $users->group_info($FORM{GID});

    $LIST_PARAMS{GID} = $users->{GID};
    delete $LIST_PARAMS{GIDS};
    $pages_qs = '&GID=' . ($users->{GID} || $FORM{GID}) . (($FORM{subf}) ? "&subf=$FORM{subf}" : q{} );

    my $groups = $html->form_main(
      {
        CONTENT => $html->form_select(
          'GID',
          {
            SELECTED  => $users->{GID} || $FORM{GID},
            SEL_LIST  => $users->groups_list({ 
              GID             => '_SHOW',
              NAME            => '_SHOW',
              DESCR           => '_SHOW',
              ALLOW_CREDIT    => '_SHOW',
              DISABLE_PAYSYS  => '_SHOW',
              DISABLE_CHG_TP  => '_SHOW',
              USERS_COUNT     => '_SHOW',
              COLS_NAME => 1
            }),
            SEL_KEY   => 'gid',
            NO_ID     => 1
          }
        ),
        HIDDEN => { index => $index },
        SUBMIT => { show  => $lang{SHOW} },
        class  => 'navbar-form navbar-right',
      }
    );

    func_menu(
      {
        $lang{NAME} => $groups
      },
      [
        $lang{CHANGE}   . '::GID=' . ($users->{GID} || $FORM{GID}) . ':change',
        $lang{USERS}    . ':11:GID=' . ($users->{GID} || $FORM{GID}) . ':users',
        $lang{PAYMENTS} . ':2:GID=' . ($users->{GID} || $FORM{GID}) . ':payments',
        $lang{FEES}     . ':3:GID=' . ($users->{GID} || $FORM{GID}) . ':fees',
      ]
    );

    if (!$permissions{0}{4}) {
      return 0;
    }

    $users->{ACTION}        = 'change';
    $users->{LNG_ACTION}    = $lang{CHANGE};
    $users->{SEPARATE_DOCS} = ($users->{SEPARATE_DOCS})  ? 'checked' : '';
    $users->{ALLOW_CREDIT}  = ($users->{ALLOW_CREDIT})   ? 'checked' : '';
    $users->{DISABLE_PAYSYS}= ($users->{DISABLE_PAYSYS}) ? 'checked' : '';
    $users->{DISABLE_PAYMENTS}= ($users->{DISABLE_PAYMENTS}) ? 'checked' : '';
    $users->{DISABLE_CHG_TP}= ($users->{DISABLE_CHG_TP}) ? 'checked' : '';
    $users->{BONUS}         = ($users->{BONUS}) ? 'checked' : '';
    $users->{GID_DISABLE}   = 'disabled';

    if(in_array('Multidoms', \@MODULES)) {
      load_module('Multidoms', $html);
      $users->{DOMAIN_FORM} = $html->tpl_show(templates('form_row'), { ID    => '',
          NAME  => "DOMAIN_ID",
          VALUE => multidoms_domains_sel({ SHOW_ID => 1, DOMAIN_ID => $users->{DOMAIN_ID} })
        },
        { OUTPUT2RETURN => 1 });
    }

    $html->tpl_show(templates('form_groups'), $users);

    return 0;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS} && $permissions{0}{5}) {
    $users->list({ GID => $FORM{del} });

    if ($users->{TOTAL} && $users->{TOTAL} > 0 && $FORM{del} > 0) {
      $html->message( 'info', $lang{DELETED}, $lang{USER_EXIST} );
    }
    else {
      $users->group_del($FORM{del});
      if (!$users->{errno}) {
        $html->message( 'info', $lang{DELETED}, "$lang{DELETED} GID: $FORM{del}" );
      }
    }
  }

  _error_show($users);

  my %ext_titles = (
    'id'                => '#',
    'name'              => $lang{NAME},
    'users_count'       => $lang{USERS},
    'descr'             => $lang{DESCRIBE},
    'allow_credit'      => "$lang{ALLOW} $lang{CREDIT}",
    'disable_paysys'    => "$lang{DISABLE} Paysys",
    'disable_payments'  => "$lang{DISABLE} $lang{PAYMENTS} $lang{CASHBOX}",
    'disable_chg_tp'    => "$lang{DISABLE} $lang{USER_CHG_TP}",
  );

  my ($table, $list) = result_former({
    INPUT_DATA      => $users,
    FUNCTION        => 'groups_list',
    BASE_FIELDS     => 0,
    DEFAULT_FIELDS  => 'G_NAME,DISABLE_PAYMENTS,DISABLE_PAYMENTS,USERS_COUNT,NAME,DESCR,ALLOW_CREDIT,DISABLE_PAYSYS,DISABLE_CHG_TP',
    HIDDEN_FIELDS   => 'GID',
    FUNCTION_FIELDS => 'change,del',
    EXT_TITLES      => \%ext_titles,
    SKIP_USER_TITLE => 1,
    FILTER_VALUES   => {
      allow_credit => sub {
        my ($allow_credit) = @_;
        return $bool_vals[ $allow_credit ];
      },
      disable_paysys => sub {
        my ($disable_paysys) = @_;
        return $bool_vals[ $disable_paysys ];
      },
      disable_payments => sub {
        my ($disable_payments) = @_;
        return $bool_vals[ $disable_payments ];
      },
      disable_chg_tp => sub {
        my ($disable_chg_tp) = @_;
        return $bool_vals[ $disable_chg_tp ];
      },
      users_count => sub {
        my ($users_count, $line) = @_;

        my $users_count_button = $html->button($users_count, "index=7&GID=$line->{gid}&search_form=1&search=1&type=11");
        return $users_count_button if ($users_count && $users_count > 0);

        return 0;
      }
    },
    TABLE  => {
      width   => '100%',
      caption => $lang{GROUPS},
      ID      => 'GROUPS',
      qs      => $pages_qs,
      EXPORT  => 1,
      MENU    => "$lang{ADD}:index=$index&add_form=1:add"
    },
    MAKE_ROWS  => 1,
    TOTAL      => 1,
  });

  return 1;
}


1;