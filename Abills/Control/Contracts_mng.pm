=head1 NAME

  Users contracts web functions

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %lang,
  %conf,
  @MONTHES_LIT,
  %permissions,
);

use Abills::Base qw(decode_base64);

our Abills::HTML $html;
our Users $users;

#**********************************************************
=head2 user_contract($attr)

=cut
#**********************************************************
sub user_contract {

  my $uid = $FORM{UID};
  return '' unless ($uid);

  if ($FORM{print_add_contract}) {
    _print_user_contract(\%FORM);
  }
  elsif ($FORM{signature}) {
    $users->contracts_change($FORM{sign}, { SIGNATURE => $FORM{signature} });
    $html->message('info', $lang{SIGNED});
  }
  elsif ($FORM{sign}) {
    $html->tpl_show(templates('signature'), {});
    return 1;
  }
  elsif ($FORM{del}) {
    $users->contracts_del({ UID => $uid, ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $users->contracts_change($FORM{chg}, \%FORM);
  }
  elsif ($FORM{chg}) {
    my $list = $users->contracts_list({ UID => $uid, ID => $FORM{chg}, COLS_UPPER => 1 });
    if ($users->{TOTAL} != 0) {
      $html->tpl_show(templates('form_user_contract'), { 
        BTN_NAME  => 'change',
        BTN_VALUE => $lang{CHANGE},
        TYPE_SEL  => _contract_type_select($list->[0]->{type}),
        %{$list->[0]} 
      });
    }
  }
  elsif ($FORM{add}) {
    $html->tpl_show(templates('form_user_contract'), {
      BTN_NAME  => 'adding',
      BTN_VALUE => $lang{ADD},
      TYPE_SEL  => _contract_type_select('0'),
    });
  }
  elsif ($FORM{adding}) {
    $users->contracts_add(\%FORM);
  }

  print _user_contracts_table($FORM{UID});
  return 1;
}

#**********************************************************
=head2 _user_contracts_table($attr)

=cut
#**********************************************************
sub _user_contracts_table {
  my ($uid, $attr) = @_;

  $uid = $FORM{UID} unless ($uid); 
  return '' unless ($uid);

  my $f_index;

  if ($attr->{UI}) {
    $f_index = 10;
    $users = $attr->{USER_INFO} if ($attr->{USER_INFO});
  }
  else {
    $f_index = get_function_index('user_contract');
  }

  my $list = $users->contracts_list({ UID => $uid });

  my $table = $html->table({
    width               => '100%',
    caption             => "$lang{CONTRACTS} / $lang{ADDITION}",
    border              => 1,
    title_plain         => [ $lang{NAME}, "#", $lang{DATE}, $lang{SIGNATURE} ],
    ID                  => 'USER_CONTRACTS',
    HAS_FUNCTION_FIELDS => 1,
    ( $attr->{UI} ? {} : MENU => "$lang{ADD}:index=" . get_function_index('user_contract') . "&add=1&UID=$uid:add" ),
  });

  foreach my $line (@$list) {
    my $sign_button = $line->{signature} ? $lang{SIGNED} : $html->button($lang{SIGN}, "qindex=" . $f_index .
      "&UID=$uid&sign=$line->{id}&header=2", { class => 'btn btn-secondary' });

    my $print_button  = '';
    my $edit_button   = '';
    my $delete_button = '';

    if (($permissions{0} && $permissions{0}{4}) || $attr->{UI}) {
      $print_button = $html->button('', "qindex=" . $f_index . "&UID=$uid&print_add_contract=$line->{id}&pdf=1", {
        ICON      => 'fas fa-print',
        target    => '_new',
        ex_params => "data-tooltip='$lang{PRINT}' data-tooltip-position='right'"
      });

      $edit_button = $html->button('', "index=" . $f_index . "&chg=$line->{id}&UID=$uid", {
        ICON      => 'fa fa-pencil-alt',
        ex_params => "data-tooltip='$lang{EDIT}' data-tooltip-position='right'"
      });

      $delete_button = $html->button('', "index=" . $f_index . "&del=$line->{id}&UID=$uid", {
        ICON      => 'fa fa-trash text-danger',
        ex_params => "data-tooltip='$lang{DEL}' data-tooltip-position='right'"
      });
    }

    $table->addrow($line->{name}, $line->{number}, $line->{date}, $sign_button, ($attr->{UI} ? $print_button : $print_button . $edit_button . $delete_button) );
  }

  my $result = $table->show({OUTPUT2RETURN => 1});

  return $result;
}

#**********************************************************
=head2 contracts_type()

=cut
#**********************************************************
sub contracts_type {

  if ($FORM{del}) {
    $users->contracts_type_del({ ID => $FORM{del} });
  }
  elsif ($FORM{change}) {
    $users->contracts_type_change($FORM{chg}, \%FORM);
  }
  elsif ($FORM{chg}) {
    my $list = $users->contracts_type_list({ ID => $FORM{chg}, COLS_UPPER => 1 });
    if ($users->{TOTAL} && $users->{TOTAL} > 0) {
       $html->tpl_show(templates('form_user_contracts_type'), { BTN_NAME => 'change', BTN_VALUE => $lang{CHANGE}, %{$list->[0]} });
    }
  }
  elsif ($FORM{add}) {
    $html->tpl_show(templates('form_user_contracts_type'), { BTN_NAME => 'adding', BTN_VALUE => $lang{ADD} });
  }
  elsif ($FORM{adding}) {
    $users->contracts_type_add(\%FORM);
  }

  print _contract_type_table();

  return 1;
}

#**********************************************************
=head2 _contract_type_table($attr)

=cut
#**********************************************************
sub _contract_type_table {
  
  my $list = $users->contracts_type_list({});

  my $table = $html->table({
    width               => '100%',
    caption             => "$lang{TYPES} $lang{CONTRACTS}",
    border              => 1,
    title_plain         => [ $lang{NAME}, $lang{TEMPLATE} ],
    ID                  => 'CONTRACTS_TYPE',
    HAS_FUNCTION_FIELDS => 1,
    MENU                => "$lang{ADD}:index=" . get_function_index('contracts_type') . "&add=1:add",
  });

  foreach my $line (@$list) {
    my $edit_button = $html->button('', "index=" . get_function_index('contracts_type') . "&chg=$line->{id}",
            { ICON => 'fa fa-pencil-alt', ex_params => "data-tooltip='$lang{EDIT}' data-tooltip-position='top'" });
    my $delete_button = $html->button('', "index=" . get_function_index('contracts_type') . "&del=$line->{id}",
            { ICON => 'fa fa-trash text-danger', ex_params => "data-tooltip='$lang{DEL}' data-tooltip-position='top'" });
    $table->addrow($line->{name}, $line->{template}, $edit_button . $delete_button);
  }

  my $result = $table->show({OUTPUT2RETURN => 1});

  return $result;
}

#**********************************************************
=head2 _contract_type_select($attr)

=cut
#**********************************************************
sub _contract_type_select {
  my ($selected) = @_;

  my $list = $users->contracts_type_list({});

  if ($users->{TOTAL} == 0) {
    my $add_btn = $html->button(
      " $lang{ADD} $lang{TYPE} $lang{CONTRACTS}",
      'add=1&index=' . get_function_index('contracts_type'),
      {
        class => 'btn btn-warning',
        ADD_ICON  => 'fa fa-plus'
  
      }
    );
    return $add_btn;
  }

  my $result = $html->form_select('TYPE', {
    SELECTED      => ($selected || ''),
    SEL_LIST      => $list,
    NO_ID         => 1,
    OUTPUT2RETURN => 1
  });

  return $result;
}

#**********************************************************
=head2 _print_user_contract($attr)

=cut
#**********************************************************
sub _print_user_contract {
  my ($attr) = @_;

  my $uid = $attr->{UID} || '_SHOW';
  my $id = $attr->{print_add_contract} || $attr->{ID};
  my $days_in_month = days_in_month({ DATE => next_month({ DATE => $main::DATE }) });

  if ($attr->{USER_OBJ}) {
    $users = $attr->{USER_OBJ};
  }

  if ($attr->{USER_PORTAL}) {
    require Users;
    Users->import();
    $users = Users->new($db, $admin, \%conf);
  }
  load_module('Docs');
  my $list = $users->contracts_list({ UID => $uid, ID => $id, NUMBER => '_SHOW', COLS_UPPER => 1 });
  $uid = $list->[0]->{UID};
  $users->info($uid, {SHOW_PASSWORD => 1});
  $users->pi({ UID => $uid });

  my $contract_info = {};
  my ($y, $m, $d) = split( /-/, $list->[0]->{DATE} || $DATE, 3 );
  $contract_info->{CONTRACT_DATE_ADD} = "$y-$m-$d";
  $contract_info->{CONTRACT_DATE_LIT_ADD} = "$d " . $MONTHES_LIT[ int( $m ) - 1 ] . " $y $lang{YEAR_SHORT}";
  $contract_info->{CONTRACT_DATE_EURO_STANDART_ADD} = "$d.$m.$y";
  ($y, $m, $d) = split( /-/, $DATE, 3 );
  $contract_info->{DATE_LIT} = "$d " . $MONTHES_LIT[ int( $m ) - 1 ] . " $y $lang{YEAR_SHORT}";
  $contract_info->{CONTRACT_ID_ADD} = $list->[0]->{NUMBER} || '';
  if ($users->{CONTRACT_DATE}) {
    my ($contract_y, $contract_m, $contract_d) = split(/-/, $users->{CONTRACT_DATE} || $DATE, 3);
    $contract_info->{CONTRACT_DATE_LIT} = "$contract_d " . $MONTHES_LIT[ int($contract_m) - 1 ] . " $contract_y $lang{YEAR_SHORT}";
    $contract_info->{CONTRACT_DATE_EURO_STANDART} = "$contract_d.$contract_m.$contract_y";
  }

  my $company_info = {};

  if ($users->{COMPANY_ID}) {
    require Companies;
    Companies->import();
    my $Company = Companies->new($db, $admin, \%conf);
    $company_info = $Company->info($users->{COMPANY_ID});
  }

  #Modules info
  my $cross_modules_return = cross_modules('docs', { UID => $uid, FULL_INFO => 1});
  my $service_num = 1;
  foreach my $module (sort keys %$cross_modules_return) {
    if (ref $cross_modules_return->{$module} eq 'ARRAY') {
      next if ($#{$cross_modules_return->{$module}} == -1);
      my $module_num = 1;
      foreach my $line (@{$cross_modules_return->{$module}}) {
        my $sum = (($line->{day} // 0) * $days_in_month) + ($line->{month} // 0);
        my $tp_name = $line->{tp_name};

        my $module_info = uc($module) . (($module_num) ? "_$module_num" : '');
        $contract_info->{ "SUM_" . $module_info }   = $sum || 0;
        $contract_info->{ "NAME_" . $module_info } = $tp_name || q{};
        $contract_info->{"DOCS_ABON_" . $module_info }   = sprintf("%.2f", $sum || 0);
        $contract_info->{"DOCS_TPNAME_" . $module_info } = $tp_name || q{};
        $contract_info->{ "SERVICE_SUM_" . $service_num } = $sum || 0;
        $contract_info->{ "SERVICE_NAME_" . $service_num } = $tp_name || q{};
        $contract_info->{"DOCS_SERVICE_SUM_" . $service_num } = sprintf("%.2f", $sum || 0);
        $contract_info->{"DOCS_SERVICE_NAME_" . $service_num } = $tp_name || q{};

        if ($module eq 'Abon'){
          $contract_info->{"DOCS_ABON_". uc($module) .'_ID_'.$line->{id} }   = sprintf("%.2f", $sum || 0);
          $contract_info->{"DOCS_TPNAME_" . uc($module) .'_ID_'.$line->{id} } = $tp_name || q{};
        }
        $service_num++;
        $module_num++;

        if ($line->{extra}) {
          foreach my $param ( keys %{ $line->{extra} }) {
            if ($module eq 'Abon'){
              $contract_info->{"DOCS_". uc($module) .'_'. uc($param)} = $line->{extra}->{$param} || q{};
              $contract_info->{"DOCS_". uc($module) .'_'. uc($param).'_ID_'.$line->{id}} = $line->{extra}->{$param} || q{};
            }
            else{
              $contract_info->{"DOCS_". uc($module) .'_'. uc($param)} = $line->{extra}->{$param} || q{};
            }
          }
        }
      }
    }
  }

  if ($attr->{USER_PORTAL}) {
    return $contract_info;
  }

  if ($attr->{pdf}) {
    my $sig_img = "$conf{TPL_DIR}/sig.png";
    if ($list->[0]->{SIGNATURE}) {
      if (open( my $fh, '>', $sig_img)) {
        binmode $fh;
        my ($data) = $list->[0]->{SIGNATURE} =~ m/data:image\/png;base64,(.*)/;
        print $fh decode_base64($data);
        close $fh;
      }
    }
    else {
      # open( my $fh, '>', $sig_img);
      # close $fh;
    }

    my $html_obj;
    if (ref $html ne 'Abills::PDF') {
      $html_obj = $html;
      require Abills::PDF;
      my $pdf = Abills::PDF->new({
        NO_PRINT => defined($attr->{'NO_PRINT'}) ? $attr->{'NO_PRINT'} : 1,
        CONF     => \%conf,
        CHARSET  => $conf{default_charset}
      });
      $html = $pdf;
    }

    my $contract = $html->tpl_show("$conf{TPL_DIR}/$list->[0]->{template}",
      { %$contract_info, %$users, %$company_info, %{$list->[0]}, FIO_S => $users->{FIO} },
      { TITLE => 'Contract', OUTPUT2RETURN => $attr->{OUTPUT2RETURN} ? 1 : 0 });
    unlink $sig_img;

    $html = $html_obj if ($html_obj);

    return $contract if $contract;
  }
  else {
    my $contract = $html->tpl_show(templates($list->[0]->{template}),
      { %$contract_info, %$users, %$company_info, %{$list->[0]} },
      { OUTPUT2RETURN => $attr->{OUTPUT2RETURN} ? 1 : 0 });

    return $contract if $contract;
  }

  return 1;
}

1