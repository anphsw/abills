=head1 NAME

  User manage

=cut

use warnings FATAL => 'all';
use strict;
use Abills::Base qw(in_array date_diff sec2date
  gen_time check_time show_hash int2byte);
use Abills::Defs;
use Attach;

our $db;
our $html;
our %lang;
our $admin;
our %permissions;
our @MONTHES;
our @WEEKDAYS;
our %uf_menus;
our %module;
our $ui;
our @bool_vals;
our @state_colors;
our @status;

my @priority_colors = ('btn-default', 'btn-info', 'btn-success', 'btn-warning', 'btn-danger');

#**********************************************************
=head2 form_users($attr) - User account managment form

=cut
#**********************************************************
sub form_users {
  my ($attr) = @_;

  if ($FORM{PRINT_CONTRACT}) {
    load_module('Docs', $html);
    docs_contract({ SEND_EMAIL => ($FORM{SEND_EMAIL}) ? 1 : 0 });
    return 1;
  }
  elsif ($FORM{SEND_SMS_PASSWORD}) {
    load_module('Sms', $html);
    my Users $user_info = $users->info($FORM{UID}, { SHOW_PASSWORD => 1 });
    my $pi        = $users->pi({ UID => $FORM{UID} });
    my $message   = $html->tpl_show(_include('sms_password_recovery', 'Sms'), { %$user_info, %$pi }, { OUTPUT2RETURN => 1 });
    my $sms_id    = sms_send(
      {
        NUMBER => $users->{PHONE},
        MESSAGE=> $message,
        UID    => $users->{UID},
      });

    if ( $sms_id ) {
      $html->message('info', "$lang{INFO}", "$lang{PASSWD} SMS $lang{SENDED}". (($sms_id > 1) ? "\n ID: $sms_id" : '') );
    }
    return 1;
  }
  elsif($FORM{import}) {
    if ($FORM{add}) {
      my $import_accounts = import_former(\%FORM);
      my $total = $#{ $import_accounts } + 1;

      my $main_id = 'UID';
      if(! $import_accounts->[0]->{UID}) {
        if ($import_accounts->[0]->{LOGIN}) {
          $main_id = 'LOGIN';
        }
        elsif($import_accounts->[0]->{MAIN_ID}) {
          $main_id = $import_accounts->[0]->{MAIN_ID};
        }
      }

      require Bills;
      Bills->import();
      my $Bills = Bills->new($db, $admin, \%conf);

      foreach my $_user (@$import_accounts) {
        my $list = $users->list({ LOGIN    => '_SHOW',
                                  $main_id => $_user->{$main_id},
                                  BILL_ID  => ($_user->{DEPOSIT}) ? '_SHOW' : undef,
                                  COLS_NAME=> 1
                                });

        if($users->{TOTAL} > 0) {
          if ($_user->{DEPOSIT}) {
            $Bills->change({ BILL_ID => $list->[0]->{bill_id}, DEPOSIT => $_user->{DEPOSIT} });
          }
          $users->change($list->[0]->{uid}, { %$_user, UID => $list->[0]->{uid} });
          $users->pi_change({ %$_user, UID => $list->[0]->{uid} });
          print $html->button($list->[0]->{login}, "index=15&UID=$list->[0]->{uid}") . " ($list->[0]->{uid})' Ok". $html->br();
        }
      }

      $html->message('info', $lang{INFO}, "$lang{ADDED}\n $lang{FILE}: $FORM{UPLOAD_FILE}{filename}\n Size: $FORM{UPLOAD_FILE}{Size}\n Count: $total");

      return 1
    }

    my $import_fields = $html->form_select('IMPORT_FIELDS',
      {
        SELECTED    => $FORM{IMPORT_FIELDS},
        SEL_ARRAY   => [ 'LOGIN',
          'FIO',
          'PHONE',
          'ADDRESS_STREET',
          'ADDRESS_BUILD',
          'ADDRESS_FLAT',
          'PASPORT_NUM',
          'PASPORT_DATE',
          'PASPORT_GRANT',
          'CONTRACT_ID',
          'CONTRACT_DATE',
          'EMAIL',
          'COMMENTS'
        ],
        EX_PARAMS   => 'multiple="multiple"'
      });

    my $encode = $html->form_select(
      'ENCODE',
      {
        SELECTED  => $FORM{ENCODE},
        SEL_ARRAY => [ '', 'win2utf8', 'utf82win', 'win2koi', 'koi2win', 'win2iso', 'iso2win', 'win2dos', 'dos2win' ],
      }
    );

    my $extra_row = $html->tpl_show(templates('form_row'), { ID => 'ENCODE',
        NAME  => $lang{ENCODE},
        VALUE => $encode }, { OUTPUT2RETURN => 1 });

    $html->tpl_show(templates('form_import'), {
        IMPORT_FIELDS     => 'LOGIN,CONTRACT_ID,FIO,PHONE,ADDRESS_STREET,ADDRESS_BUILD,ADDRESS_FLAT,PASPORT_NUM,PASPORT_GRANT',
        CALLBACK_FUNC     => 'form_users',
        IMPORT_FIELDS_SEL => $import_fields,
        EXTRA_ROWS        => $extra_row
      } );

    return 1;
  }
  elsif($FORM{bill_correction}) {
    my $user_info = $attr->{USER_INFO};
    form_bill_correction($user_info);
    return 1;
  }
  elsif($FORM{SUMMARY_SHOW}) {
    if ($FORM{EXPORT}) {
      print "Content-Type: application/json; charset=utf8\n\n";
      print user_full_info();
    }
    else {
      my $user_info;
      $user_info->{METRO_PANELS} = user_full_info();
      $user_info->{HTML_STYLE}   = $html->{HTML_STYLE} || 'default_adm';
      $html->tpl_show(templates('form_client_view_metro'), $user_info);
    }
    return 1;
  }

  if ($attr->{USER_INFO}) {
    my Users $user_info = $attr->{USER_INFO};
    if (_error_show($user_info)) {
      return 0;
    }
    #Make service menu
    if (defined($FORM{newpassword})) {
      if (form_passwd({ USER_INFO => $user_info })) {
        return 0;
      }
    }

    if ($FORM{change}) {
      if (!$permissions{0}{4}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
        return 0;
      }

      if (!$permissions{0}{9} && defined($user_info->{CREDIT}) && defined($FORM{CREDIT}) && $user_info->{CREDIT} != $FORM{CREDIT}) {
        $html->message('err', $lang{ERROR}, "$lang{CHANGE} $lang{CREDIT} $lang{ERR_ACCESS_DENY}");
        delete($FORM{CREDIT});
      }

      if (!$permissions{0}{11} && defined($FORM{REDUCTION}) && $user_info->{REDUCTION} != $FORM{REDUCTION}) {
        $html->message('err', $lang{ERROR}, "$lang{REDUCTION} $lang{ERR_ACCESS_DENY}");
        delete($FORM{REDUCTION});
      }

      if ($permissions{0}{13} && $user_info->{DISABLE} == 2) {
        $FORM{DISABLE} = 2;
      }

      if ($conf{FIXED_FEES_DAY} &&  $FORM{ACTIVATE} && $FORM{ACTIVATE} ne '0000-00-00') {
        my $d = (split(/-/, $FORM{ACTIVATE}))[2];
        if (in_array($d, ['1', '01', '29', '30', '31' ])) {
          $html->message('info', $lang{CHANGE}, "$lang{ACTIVATE} $FORM{ACTIVATE}->0000-00-00");
          $FORM{ACTIVATE}='0000-00-00';
        }
      }

      $user_info->change($user_info->{UID}, {%FORM});
      if ($user_info->{errno}) {
        _error_show($user_info);
        user_form();
        return 0;
      }
      else {
        $html->message('info', $lang{CHANGED}, $lang{CHANGED} .' ' . ($users->{info} || '') );
        if (defined($FORM{FIO})) {
          $users->pi_change({%FORM});
        }

        $user_info->{CREDIT}=$FORM{CREDIT} if ($FORM{CREDIT} && $user_info->{CREDIT} != $FORM{CREDIT});
        cross_modules_call('_payments_maked', { USER_INFO => $user_info, CHANGE_CREDIT => 1 });

        #External scripts
        if ($conf{external_userchange}) {
          if (!_external($conf{external_userchange}, \%FORM)) {
            return 0;
          }
        }
        if ($attr->{REGISTRATION}) {
          return 0;
        }
      }
    }
    elsif ($FORM{del_user} && $FORM{COMMENTS} && $index == 15 && $permissions{0}{5}) {
      user_del({ USER_INFO => $user_info });
      return 0;
    }
    else {
      #if (!$permissions{0}{4}) {
      #  @action = ();
      #}
      #else {
      #  @action = ('change', $lang{CHANGE});
      #}
      delete($FORM{add});
      user_form({ USER_INFO => $user_info });
      user_services({ USER_INFO => $user_info });
      user_pi({ %$attr, USER_INFO => $user_info });
    }

    return 0;
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }

    if ($FORM{newpassword}) {
      if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
      }
      elsif ($FORM{newpassword} eq $FORM{confirm}) {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
      elsif ($FORM{newpassword} ne $FORM{confirm}) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_CONFIRM}");
      }
      else {
        $FORM{PASSWORD} = $FORM{newpassword};
      }
    }

    $FORM{REDUCTION} = 100 if ($FORM{REDUCTION} && $FORM{REDUCTION} > 100);

    # Add not confirm status
    if ($permissions{0}{13}) {
      $FORM{DISABLE}=2;
    }

    if ($conf{FIXED_FEES_DAY} &&  $FORM{ACTIVATE} && $FORM{ACTIVATE} ne '0000-00-00') {
      my $d = (split(/-/, $FORM{ACTIVATE}))[2];

      if (in_array($d, [1, 29, 30, 31 ])) {
        $html->message('info', $lang{CHANGE}, "$lang{ACTIVATE} $FORM{ACTIVATE}->0000-00-00");
        $FORM{ACTIVATE}='0000-00-00';
      }
    }

    my Users $user_info = $users->add({%FORM});
    if (_error_show($users, { MESSAGE =>
        "$lang{LOGIN}: " . (($users->{errno} && $users->{errno} == 7) ? $html->button($FORM{LOGIN}, "index=11&LOGIN=$FORM{LOGIN}") : '$FORM{LOGIN}' )
      })) {

      if ($FORM{NOTIFY_FN}) {
        my $fn = $FORM{NOTIFY_FN};
        if (defined(&$fn)) {
          $fn->({ %FORM, NOTIFY_ID => $FORM{NOTIFY_ID} });
        }
      }

      delete($FORM{add});
      return 0;
    }
    else {
      $html->message('info', $lang{ADDED}, "$lang{ADDED} '$user_info->{LOGIN}' / [$user_info->{UID}]");
      if ($conf{external_useradd}) {
        if (!_external($conf{external_useradd}, {%FORM})) {
          return 1;
        }
      }

      $user_info = $users->info($user_info->{UID}, { SHOW_PASSWORD => 1 });
      $LIST_PARAMS{UID} = $user_info->{UID};
      $FORM{UID}        = $user_info->{UID};
      user_pi({ %$attr, REGISTRATION => 1 });

      $user_info->pi({ UID => $users->{UID} });
      $html->tpl_show(templates('form_user_info'), $user_info);

      if ($FORM{NOTIFY_FN}) {
        my $fn = $FORM{NOTIFY_FN};
        if (defined(&$fn)) {
          &{ \&{$fn} }( { %FORM, NOTIFY_ID => $FORM{NOTIFY_ID} } );
        }
      }

      if ($FORM{COMPANY_ID}) {
        form_companie_admins($attr);
      }
      return 1;
    }
  }
  #Multi user operations
  elsif ($FORM{MULTIUSER}) {
    my @multiuser_arr = split(/, /, $FORM{IDS} || q{});
    #my $count         = 0;
    my %CHANGE_PARAMS = (
      SKIP_STATUS_CHANGE => $FORM{DISABLE} ? undef : 1
    );
    while (my ($k, undef) = each %FORM) {
      if ($k =~ /^MU_(\S+)/) {
        my $val = $1;
        $CHANGE_PARAMS{$val} = $FORM{$val};
      }
    }

    if (!defined($FORM{DISABLE})) {
      $CHANGE_PARAMS{UNCHANGE_DISABLE} = 1;
    }
    else {
      $CHANGE_PARAMS{DISABLE} = $FORM{MU_DISABLE} || 0;
    }

    if ($#multiuser_arr < 0) {
      $html->message('err', $lang{MULTIUSER_OP}, "$lang{SELECT_USER}");
    }
    elsif (scalar keys %CHANGE_PARAMS < 1) {
      #$html->message('err', $lang{MULTIUSER_OP}, "$lang{SELECT_USER}");
    }
    else {
      foreach my $uid (@multiuser_arr) {
        if ($FORM{DEL} && $FORM{MU_DEL}) {
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
      $html->message('info', $lang{MULTIUSER_OP}, "$lang{TOTAL}: " . ($#multiuser_arr + 1) . " IDS: $FORM{IDS}");
    }
  }

  return 1;
}

#**********************************************************
=head2 form_bill_correction($attr) - Personal information form

=cut
#**********************************************************
sub form_bill_correction {
  my ($attr) = @_;

  if (! $permissions{0} || ! $permissions{0}{15}) {
    $html->message('err', $lang{ERROR}, $lang{ERR_ACCESS_DENY});
    return 1;
  }

  $attr->{ACTION}='change_bill';
  $attr->{LNG_ACTION}=$lang{CHANGE};
  if ($FORM{change_bill}) {
    require Bills;
    Bills->import();
    my $Bill = Bills->new($db, $admin, \%conf);
    $Bill->change(\%FORM);
    if (! _error_show($Bill)) {
      $html->message('info', $lang{INFO}, $lang{CHANGED});
      $attr->{DEPOSIT}=sprintf("%.2f", $FORM{DEPOSIT});
    }
  }

  print $html->tpl_show(templates('form_bill_deposit'), $attr);

  return 1;
}

#**********************************************************
=head2 user_pi($attr) - Personal information form

=cut
#**********************************************************
sub form_social_networks {
  my($network_info)=@_;

  my ($network, $id) = split(/, /, $network_info);
  $html->message( 'info', $lang{INFO}, $network_info);
  use Abills::Auth::Core;
  my $Auth = Abills::Auth::Core->new( {
      CONF      => \%conf,
      AUTH_TYPE => ucfirst($network) } );

  if ($Auth->can( 'get_info' )) {
    $Auth->get_info( { CLIENT_ID => $id } );

    if($Auth->{errno}) {
      $html->message( 'err', $lang{ERROR}, "$Auth->{errno} $Auth->{errstr}");
    }

    my $table = $html->table(
      {
        width      => '400',
      }
    );

    foreach my $key (sort keys %{ $Auth->{result}  }) {
      my $result = '';
      if(ref $Auth->{result}->{$key} eq 'HASH') {
        $result = show_hash($Auth->{result}->{$key}, { OUTPUT2RETURN => 1, DELIMITER => $html->br() });
      }
      else {
        Encode::_utf8_off($Auth->{result}->{$key});
        $result = $Auth->{result}->{$key};
      }
      $table->addrow($key, $result);
    }
    print $table->show();
  }

  return 1;
}

#**********************************************************
=head2 user_pi($attr) - Personal information form

=cut
#**********************************************************
sub user_pi {
  my ($attr) = @_;

  my $Attach = Attach->new($db, $admin, \%conf);

  my Users $user;
  if ($attr->{USER_INFO}) {
    $user = $attr->{USER_INFO};
  }
  elsif($FORM{UID}) {
    $user = $users->info($FORM{UID});
  }
  elsif($users) {
    $user = $users;
  }

  if ($FORM{REG} && $conf{SENDER_ENABLED} && $FORM{DEFAULT_CONTACT_TYPES}){

    my @default_types = split( /,\s+/, $FORM{DEFAULT_CONTACT_TYPES} );

    foreach my $contact_type_id ( @default_types ){
      my $contact = $FORM{"CONTACT_TYPE_$contact_type_id"};
      if ( $contact && $contact ne '' ){
        $user->contacts_add( {
                TYPE_ID => $contact_type_id,
                VALUE   => $contact,
                UID     => $FORM{UID}
            }
        );
        _error_show( $user );
      }
    }

  }

  if ($FORM{SOCIAL_INFO}) {
    form_social_networks($FORM{SOCIAL_INFO});
  }
  elsif ($FORM{PHOTO}) {
    form_image_mng($user);
    return 0;
  }
  elsif ($FORM{ATTACHMENT}) {
    if ($FORM{del}) {
      if ($FORM{ATTACHMENT} =~ /(.+):(.+)/) {
        $FORM{TABLE}      = $1 . '_file';
        $FORM{ATTACHMENT} = $2;
      }

      $Attach->attachment_del(
        {
          ID    => $FORM{ATTACHMENT},
          TABLE => $FORM{TABLE},
          UID   => $user->{UID}
        }
      );

      if ( ! $users->{errno} ) {
        $html->message('info', $lang{INFO}, "$lang{FILE} '$FORM{ATTACHMENT}' $lang{DELETED}");
      }

      return 1;
    }

    form_show_attach();
    return 1;
  }
  elsif ($FORM{address}) {
    form_address_sel();
  }
  elsif ($FORM{add}) {
    if (!$permissions{0}{1}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }

    $user->pi_add({%FORM});
    if ( !$user->{errno} ){
      return 0 if ($attr->{REGISTRATION});
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    if (!$permissions{0}{4}) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_ACCESS_DENY}");
      return 0;
    }

    $user->pi_change({%FORM});
    if (!$user->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED}");
    }
  }
  elsif ( $FORM{CONTACTS} ){
    return user_contacts_renew();
  }

  _error_show($user);

  my $user_pi = $users->pi();

  $user_pi->{SHOW_PRETTY_USER_CONTACTS} = $conf{SENDER_ENABLED};

  if ($user_pi->{TOTAL} < 1 && $permissions{0}{1}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'add';
      $user_pi->{LNG_ACTION} = $lang{ADD};
    }
  }
  elsif ($permissions{0}{4}) {
    if ($attr->{ACTION}) {
      $user_pi->{ACTION}     = $attr->{ACTION};
      $user_pi->{LNG_ACTION} = $attr->{LNG_ACTION};
    }
    else {
      $user_pi->{ACTION}     = 'change';
      $user_pi->{LNG_ACTION} = $lang{CHANGE};
    }
    $user_pi->{ACTION} = 'change';
  }

  $index = 30 if (!$attr->{MAIN_USER_TPL});
  #Info fields
  $user_pi->{INFO_FIELDS} = form_info_field_tpl({ VALUES  => $user_pi });

  if (in_array('Docs', \@MODULES)) {
    if ($user_pi->{UID}){
      $user_pi->{PRINT_CONTRACT} = $html->button( "$lang{PRINT}",
        "qindex=15&UID=$user_pi->{UID}&PRINT_CONTRACT=$user_pi->{UID}" . (($conf{DOCS_PDF_PRINT}) ? '&pdf=1' : ''),
        { ex_params => ' target=new', class => 'print' } );
    }

    if ($conf{DOCS_CONTRACT_TYPES}) {
      $conf{DOCS_CONTRACT_TYPES} =~ s/\n//g;
      my (@contract_types_list) = split(/;/, $conf{DOCS_CONTRACT_TYPES});

      my %CONTRACTS_LIST_HASH = ();
      $FORM{CONTRACT_SUFIX} = "|$user_pi->{CONTRACT_SUFIX}" if ($user_pi->{CONTRACT_SUFIX});
      foreach my $line (@contract_types_list) {
        my ($prefix, $sufix, $name) = split(/:/, $line);
        $prefix =~ s/ //g;
        $CONTRACTS_LIST_HASH{"$prefix|$sufix"} = $name;
      }

      $user_pi->{CONTRACT_TYPE} = $html->form_select(
        'CONTRACT_TYPE',
        {
          SELECTED => $FORM{CONTRACT_SUFIX},
          SEL_HASH => { '' => '', %CONTRACTS_LIST_HASH },
          NO_ID    => 1,
          ID       => 'CONTRACT_TYPE'
        }
      );

      $user_pi->{CONTRACT_TYPE} = $html->tpl_show(templates('form_row'), { ID => "CONTRACT_TYPE",
          NAME  => $lang{TYPE},
          VALUE => $user_pi->{CONTRACT_TYPE} }, { OUTPUT2RETURN => 1 });
    }
  }

  if ($conf{ACCEPT_RULES}) {
    $user_pi->{ACCEPT_RULES_FORM} .= $html->tpl_show(templates('form_row'), {
        ID       => 'ACCEPT_RULES',
        NAME     => $lang{ACCEPT_RULES},
        VALUE    => ($user_pi->{ACCEPT_RULES}) ? $lang{YES} : $lang{NO},
        BG_COLOR => ($user_pi->{ACCEPT_RULES}) ? '' : 'bg-warning'
      },
      { OUTPUT2RETURN => 1 });
  }

  if ($conf{ADDRESS_REGISTER}) {
    my $location_id = $FORM{LOCATION_ID} || $user_pi->{LOCATION_ID};
    my $Address;

    if ($FORM{LOCATION_ID}) {
      require Address;
      Address->import();
      $Address = Address->new($db, $admin, \%conf);

      $Address->address_info($FORM{LOCATION_ID} || $user_pi->{LOCATION_ID});
    }
    else {
      $Address = {};
    }

    if ($location_id) {
      if ($user_pi->{COORDX} && $user_pi->{COORDX} == 0) {
        $user_pi->{MAP_BTN} = $html->button("$lang{MAP} $lang{ADD}", "get_index=maps_add_2&LOCATION_ID=$location_id&header=1&LOCATION_TYPE=BUILD", { class => 'btn btn-default btn-xs', target => '_map' });
      }
      else {
        $user_pi->{MAP_BTN} = $html->button($lang{MAP}, "get_index=maps_show_poins&show_build=". ($location_id || q{})
            ."&UID=". ($FORM{UID} || q{}) . "&header=1", { class => 'btn btn-default btn-xs', target => '_map' });
      }
    }
    $Address->{FLAT_CHECK_FREE} = 1;
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address_sel'), { %FORM, %$user_pi, %$Address },
      { OUTPUT2RETURN => 1, ID => 'form_address_sel' });
  }
  else {
    my $countries_hash;
    ($countries_hash, $user_pi->{COUNTRY_SEL}) = sel_countries({ NAME    => 'COUNTRY_ID',
        COUNTRY => $user_pi->{COUNTRY_ID} });
    $user_pi->{ADDRESS_TPL} = $html->tpl_show(templates('form_address'), $user_pi, { OUTPUT2RETURN => 1 });
  }

  if ($user_pi->{SHOW_PRETTY_USER_CONTACTS}){

    my $user_contacts_list = $users->contacts_list(
        {
            UID       => $FORM{UID},
            VALUE     => '_SHOW',
            PRIORITY  => '_SHOW',
            TYPE      => '_SHOW',
            HIDDEN    => '0'
        }
    );
    _error_show( $users );

    my $user_contact_types = $users->contact_types_list( { SHOW_ALL_COLUMNS => 1, COLS_NAME => 1, HIDDEN    => '0', } );
    _error_show( $users );

    # Translate type names
    foreach my $type ( @{$user_contact_types} ){
      $type->{name} = $lang{$type->{name}} || $type->{name};
    }

    $user_pi->{CONTACTS} = _build_user_contacts_form( $user_contacts_list, $user_contact_types );
    # Show contacts block
    $user_pi->{SHOW_PRETTY_USER_CONTACTS} = 'block';
  }
  else {
    #Hide contacts block
    $user_pi->{SHOW_PRETTY_USER_CONTACTS} = 'none';
  }

  $html->tpl_show(templates('form_pi'), { %$attr, UID => $LIST_PARAMS{UID}, %$user_pi }, { ID => 'form_pi' });

  return 1;
}

#**********************************************************
=head2 user_form($attr) - Main user form

=cut
#**********************************************************
sub user_form {
  my ($attr) = @_;

  $index = 15 if (!$attr->{ACTION} && !$attr->{REGISTRATION});
  my $user_info = $attr->{USER_INFO};

  if ($FORM{STATMENT_ACCOUNT}) {
    load_module('Docs', $html);
    docs_statement_of_account();
    exit;
  }
  elsif ($FORM{add} || $FORM{change}) {
    return form_users($attr);
  }
  elsif (!$attr->{USER_INFO}) {
    $user = Users->new($db, $admin, \%conf);

    if ($FORM{COMPANY_ID}) {
      use Customers;
      my $customers = Customers->new($db, $admin, \%conf);
      my $company = $customers->company->info($FORM{COMPANY_ID});
      $user_info->{COMPANY_ID} = $FORM{COMPANY_ID};
      $user_info->{EXDATA} =  $html->tpl_show(templates('form_row'), { ID => "",
          NAME  => $lang{COMPANY},
          VALUE => (($company->{COMPANY_ID} && $company->{COMPANY_ID} > 0) ? $html->button($company->{COMPANY_NAME}, "index=13&COMPANY_ID=$company->{COMPANY_ID}", { BUTTON => 1 }) : '') }, { OUTPUT2RETURN => 1 });
    }

    if ($admin->{GID}) {
      $user_info->{GID} = sel_groups();
    }
    else {
      $FORM{GID} = $attr->{GID};
      delete $attr->{GID};
      $user_info->{GID} = sel_groups({ SKIP_MUULTISEL => 1 });
    }

    $user_info->{EXDATA} .= $html->tpl_show(templates('form_user_exdata_add'), { %$user_info, %$attr, CREATE_BILL => ' checked' }, { OUTPUT2RETURN => 1 });
    $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill_add'), { CREATE_EXT_BILL => ' checked' }, { OUTPUT2RETURN => 1 }) if ($conf{EXT_BILL_ACCOUNT});

    if ($user_info->{DISABLE} && $user_info->{DISABLE} > 0) {
      $user_info->{DISABLE} = ' checked';
      if ($user_info->{DISABLE} == 5) {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b("$lang{NOT} $lang{CONFIRM}"), $_COLORS[7]);
      }
      else {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b($lang{DISABLE}), $_COLORS[6]);
        $user_info->{DISABLE_COLOR} = 'bg-warning';
      }
    }
    else {
      $user_info->{DISABLE} = "$lang{ENABLE}";
    }

    $user_info->{MONTH_NAMES} = "'". join("', '", @MONTHES) . "'";
    $user_info->{WEEKDAY_NAMES} = "'". join("', '", $WEEKDAYS[7], @WEEKDAYS[1..6]). "'";

    my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1, ID => 'form_user' });

    $user_info->{PW_CHARS}  = $conf{PASSWD_SYMBOLS} || "abcdefhjmnpqrstuvwxyz23456789ABCDEFGHJKLMNPQRSTUVWYXZ";
    $user_info->{PW_LENGTH} = $conf{PASSWD_LENGTH}  || 6;

    $main_account .= $html->tpl_show(templates('form_password'), { %$user_info, %$attr }, { OUTPUT2RETURN => 1 });

    $main_account =~ s/<FORM.+>//ig;
    $main_account =~ s/<\/FORM>//ig;
    $main_account =~ s/<input.+type=submit.+>//ig;
    $main_account =~ s/<input.+index.+>//ig;
    $main_account =~ s/user_form/users_pi/ig;

    user_pi({ MAIN_USER_TPL => $main_account, %$attr });
  }
  else {
    $user_info = $attr->{USER_INFO};
    $FORM{UID} = $user_info->{UID};
    $user_info->{COMPANY_NAME} = "$lang{NOT_EXIST} ID: $user_info->{COMPANY_ID}" if ($user_info->{COMPANY_ID} && !$user_info->{COMPANY_NAME});

    if ($permissions{0}{12}) {
      $user_info->{DEPOSIT}='--';
    }
    else {
      if ($permissions{1}) {
        $user_info->{PAYMENTS_BUTTON} = $html->button('', "index=2&UID=". ($LIST_PARAMS{UID} || q{}),
          { class => 'btn btn-xs btn-default glyphicon glyphicon-plus-sign', TITLE => $lang{PAYMENTS} });
      }

      if ($permissions{2}) {
        $user_info->{FEES_BUTTON} = $html->button('', "index=3&UID=$LIST_PARAMS{UID}", { class => 'btn btn-xs btn-default glyphicon glyphicon-minus-sign', TITLE => $lang{FEES} });
      }

      if ($permissions{0}) {
        #my $as_index = get_function_index('docs_statement_of_account');
        $user_info->{PRINT_BUTTON} = $html->button('', "qindex=$index&STATMENT_ACCOUNT=$LIST_PARAMS{UID}&UID=$LIST_PARAMS{UID}&header=1", { class => 'btn btn-xs btn-default glyphicon glyphicon-print', TITLE => $lang{STATMENT_OF_ACCOUNT}, ex_params => 'target=_new' });
      }

      if (defined($user_info->{DEPOSIT})){
        $user_info->{DEPOSIT_MARK} = ($user_info->{DEPOSIT} > 0) ? 'label-primary' : 'label-danger';
      }
      else {
        $user_info->{DEPOSIT_MARK} = 'label-warning';
        $user_info->{DEPOSIT} = 'Not set';
      }
    }

    if ($permissions{0} && $permissions{0}{15}) {
      $user_info->{BILL_CORRECTION} = $html->button('', "index=$index&UID=$user_info->{UID}&bill_correction=1", { class => 'glyphicon glyphicon-wrench' });
    }

    $user_info->{EXDATA} = $html->tpl_show(templates('form_user_exdata'), $user_info, { OUTPUT2RETURN => 1, ID => 'form_user_exdata'  });

    $user_info->{REGISTRATION_FORM} = $html->tpl_show(templates('form_row'), { ID => '',
        NAME  => $lang{REGISTRATION},
        VALUE => $user_info->{REGISTRATION} }, { OUTPUT2RETURN => 1 });

    if ($conf{EXT_BILL_ACCOUNT} && $user_info->{EXT_BILL_ID}) {
      $user_info->{EXDATA} .= $html->tpl_show(templates('form_ext_bill'), $user_info, { OUTPUT2RETURN => 1, ID => 'ext_bill_id' });
    }

    if ( $user_info->{DISABLE} && $user_info->{DISABLE} > 0 ){
      if ($user_info->{DISABLE} == 1) {
        $user_info->{DISABLE_MARK} = $html->color_mark($html->b($lang{DISABLE}), $_COLORS[6]);
        $user_info->{DISABLE_COLOR} = 'bg-danger';

        my $list = $admin->action_list(
          {
            UID       => $user_info->{UID},
            TYPE      => 9,
            PAGE_ROWS => 1,
            SORT      => 1,
            DESC      => 'DESC'
          }
        );
        if ($admin->{TOTAL} > 0) {
          $user_info->{DISABLE_COMMENTS} = $list->[0][3];
        }
      }
      elsif ($user_info->{DISABLE} == 2) {
        if (! $permissions{0}{13}) {
          $user_info->{DISABLE_MARK} = $html->button($html->color_mark($html->b("$lang{REGISTRATION} $lang{CONFIRM}"), $_COLORS[8]), "index=$index&DISABLE=0&UID=$FORM{UID}&change=1", { BUTTON => 1 }) ;
        }
        else {
          $user_info->{DISABLE_MARK} = $html->color_mark($html->b("$lang{REGISTRATION} $lang{CONFIRM}"), $_COLORS[8]);
        }
      }

      $user_info->{DISABLE} = ' checked';
    }
    else {
      $user_info->{DISABLE} = '';
    }

    if ( $user_info->{EXPIRE} && $user_info->{EXPIRE} ne '0000-00-00' ){
      if (date_diff($user_info->{EXPIRE}, $DATE) > 1) {
        $user_info->{EXPIRE_COLOR} = 'bg-danger';
        $user_info->{EXPIRE_COMMENTS}="$lang{EXPIRE}";
      }
    }

    $user_info->{ACTION}     = 'change';
    $user_info->{LNG_ACTION} = $lang{CHANGE};

    if ($permissions{5}) {
      my $info_field_index = get_function_index('form_info_fields');
      $user_info->{ADD_INFO_FIELD} = $html->button("$lang{ADD} $lang{INFO_FIELDS}", "index=$info_field_index", { class => 'add', ex_params => ' target=_info_fields' });
    }

    if ($permissions{0}{3}) {
      $user_info->{PASSWORD} =
          ($FORM{SHOW_PASSWORD})
        ? "$lang{PASSWD}: '$user_info->{PASSWORD}'"
        : $html->button("$lang{SHOW} $lang{PASSWD}", "index=$index&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1", { BUTTON => 1 }) . ' ' . $html->button("$lang{CHANGE} $lang{PASSWD}", "index=" . get_function_index('form_passwd') . "&UID=$LIST_PARAMS{UID}", { BUTTON => 1 });
    }

    if (in_array('Sms', \@MODULES)) {
      $user_info->{PASSWORD} .= ' ' . $html->button("$lang{SEND} $lang{PASSWD} SMS", "index=$index&header=1&UID=$LIST_PARAMS{UID}&SHOW_PASSWORD=1&SEND_SMS_PASSWORD=1", { BUTTON => 1, MESSAGE => "$lang{SEND} $lang{PASSWD} SMS ?" });
    }

    $user_info->{MONTH_NAMES} = "'". join("', '", @MONTHES) . "'";
    $user_info->{WEEKDAY_NAMES} = "'". join("', '", $WEEKDAYS[7], @WEEKDAYS[1..6]). "'";

    if ($attr->{REGISTRATION}) {
      my $main_account = $html->tpl_show(templates('form_user'), { %$user_info, %$attr }, { ID => 'form_user', OUTPUT2RETURN => 1 });
      $main_account =~ s/<FORM.+>//ig;
      $main_account =~ s/<\/FORM>//ig;
      $main_account =~ s/<input.+type=submit.+>//ig;
      $main_account =~ s/<input.+index.+>//ig;
      $main_account =~ s/user_form/users_pi/ig;
      user_pi({ MAIN_USER_TPL => $main_account, %$attr });
    }
    else {
      $html->tpl_show(templates('form_user'), $user_info, { ID => 'form_user' });
    }
  }

  return 1;
}

#**********************************************************
=head2 user_services($attr)

  Arguments:
    USER_INFO

  Return:

=cut
#**********************************************************
sub user_services {
  my ($attr) = @_;

  my $user_info = $attr->{USER_INFO};

  #Service tabs
  my @header_arr = ();
  foreach my $key (sort keys %menu_items) {
    if (defined($menu_items{$key}{20})) {
      if (in_array($module{$key}, \@MODULES)) {

        if (defined($module{$key})) {
          load_module($module{$key}, $html);
        }

        my $info= '';
        #Get quick info
        if (lc($module{$key}.'_quick_info')){
          $info = $html->badge( _function( 0, { IF_EXIST => 1, FN_NAME => lc( $module{$key} ) . '_quick_info' } ), { TYPE => 'alert-info' } );
        }

        push @header_arr, "$menu_items{$key}{20} ". ($info || '') .":#$module{$key}:role='tab' data-toggle='tab'";
      }
    }
  }

  print $html->table_header(\@header_arr, { TABS => 1 });

  my $active = ' active';
  delete ($FORM{search_form});

  if ($FORM{json}) {
    foreach my $module (@MODULES) {
      $FORM{MODULE} = $module;
      my $service_func_index = 0;
      foreach my $key (sort keys %menu_items) {
        if (defined($menu_items{$key}{20})) {
          $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
        }
      }

      if ($service_func_index) {
        $index = $service_func_index;
        _function($service_func_index, { USER_INFO => $user_info });
      }
    }

    return 1;
  }

  print "<div class='tab-content'>";

  foreach my $module (@MODULES) {
    my $service_start = 0;
    if ($FORM{DEBUG} && $FORM{DEBUG} > 4) {
      $service_start = check_time();
    }

    $FORM{MODULE} = $module;
    my $service_func_index = 0;
    my $service_func_menu  = '';
    foreach my $key (sort keys %menu_items) {
      if (defined($menu_items{$key}{20})) {
        $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
      }

      if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
        $service_func_menu .= $html->li($html->button($menu_items{$key}{$service_func_index}, "UID=$user_info->{UID}&index=$key", { class => '' }));
      }
    }

    if ($service_func_index) {
      print "<div class='tab-pane$active' id='$module'>";
      $active='';

      my $menu = $html->element('div',
        $html->element('ul', $service_func_menu, { class => 'nav navbar-nav' }),
        { class => 'navbar navbar-default' });

      $index = $service_func_index;
      _function($service_func_index, { USER_INFO => $user_info, MENU => $menu });

      if ($FORM{DEBUG} && $FORM{DEBUG} > 4) {
        print gen_time($service_start);
      }

      print "</div>\n";
    }
  }

  print "</div>";

  return 1;
}

#**********************************************************
=head2 user_ext_menu($uid, $LOGIN, $attr) - User extra menu

=cut
#**********************************************************
sub user_ext_menu {
  my ($uid, $LOGIN, $attr) = @_;

  if (! $uid){
    return '[unknown user]'
  }

  if ($FORM{xml} || $FORM{csv} || $FORM{json} || $FORM{EXPORT_CONTENT}) {
    return $LOGIN;
  }

  my $payments_menu = (defined($permissions{1})) ? $html->li($html->button($lang{PAYMENTS}, "UID=$uid&index=2")) : '';
  my $fees_menu     = (defined($permissions{2})) ? $html->li($html->button($lang{FEES},     "UID=$uid&index=3")) : '';

  my $second_menu    = '';
  my %userform_menus = (
    22 => $lang{LOG},
    21 => $lang{COMPANY},
    12 => $lang{GROUP},
    18 => $lang{NAS},
    20 => $lang{SERVICES},
    19 => $lang{BILL}
  );

  $userform_menus{17} = $lang{PASSWD} if ($permissions{0}{3});

  while (my ($k, $v) = each %uf_menus) {
    $userform_menus{$k} = $v;
  }

  #Make service menu
  my $service_menu       = '';
  my $service_func_index = 0;
  my $service_func_menu  = '';
  foreach my $key (sort keys %menu_items) {
    if (defined($menu_items{$key}{20})) {
      $service_func_index = $key if (($FORM{MODULE} && $FORM{MODULE} eq $module{$key} || !$FORM{MODULE}) && $service_func_index == 0);
      $service_menu .= $html->li( $html->button($menu_items{$key}{20}, "UID=$uid&index=$key") );
    }

    if ($service_func_index > 0 && $menu_items{$key}{$service_func_index}) {
      $service_func_menu .= $html->button($menu_items{$key}{$service_func_index}, "UID=$uid&index=$key");
    }
  }

  foreach my $k (sort { $b <=> $a } keys %userform_menus) {
    my $v   = $userform_menus{$k};
    my $url = "index=$k&UID=$uid";
    my $name   = (defined($FORM{$k})) ? $html->b($v) : $v;
    $second_menu .= $html->li($html->button($name, "$url"));
  }

  my $show_login = ($attr->{SHOW_LOGIN}) ? $html->li($html->b($html->button($LOGIN, "index=15&UID=$uid"))) : '';

  my $ext_menu = qq{
<div class='btn-group'>
  <a class='btn btn-sm btn-default dropdown-toggle' data-toggle='dropdown' href='#'><span class='glyphicon glyphicon-user'></span></a>
  <ul class='dropdown-menu multi-level' role='menu' aria-labelledby='dropdownMenu' >
    $show_login
    $payments_menu
    $fees_menu
    <li class='dropdown-submenu'>
     <a tabindex='-1' href='#'>$lang{SERVICES} &gt;&gt;</a>
       <ul class='dropdown-menu'>
         $service_menu
       </ul>
    </li>
    <li class='divider'></li>
    <li class='dropdown-submenu'>
     <a tabindex='-1' href='#'>$lang{OTHER} &gt;&gt;</a>
       <ul class='dropdown-menu'>
         $second_menu
       </ul>
    </li>
  </ul>
</div>
};

  my $return = $ext_menu;

  if ($attr->{SHOW_UID}) {
    $return .= $html->button($html->b($LOGIN), "index=15&UID=$uid") . " (UID: $uid) ";
  }
  else {
    $return .= $html->button($LOGIN, "index=15&UID=$uid" . (($attr->{EXT_PARAMS}) ? "&$attr->{EXT_PARAMS}" : ''), { TITLE => $attr->{TITLE} });
  }

  return $return;
}

#**********************************************************
=head2 user_info($uid, $attr) - User info panel

=cut
#**********************************************************
sub user_info {
  my ($uid, $attr) = @_;

  my $user_info = $users->info($uid, \%FORM);
  my @admin_groups = split(/,s?/, $admin->{GID});

  if($uid && $users->{errno}) {
    if (! $attr || ! $attr->{QUITE}) {
      _error_show($users, { MESSAGE => "$lang{USER} '$uid' "  });
    }
    return $users;
  }
  elsif (! $users->{TOTAL} && !$FORM{UID}) {
    return 0;
  }
  elsif( $#admin_groups > -1 && $admin_groups[0] && ! in_array($users->{GID}, \@admin_groups)) {
    $html->message('err', $lang{ERROR}, "Access deny GID: $users->{GID} not allow");
    return 0;
  }
  else {
    if($users->{errno}) {
      if (!$attr || !$attr->{QUITE}) {
        _error_show( $users, { MESSAGE => "$lang{USER} '$uid' " } );
      }
      return $users;
    }
    $uid = $user_info->{UID};
  }

  if ($LIST_PARAMS{FIO} && $LIST_PARAMS{FIO} ne '_SHOW') {
    $LIST_PARAMS{FIO}='_SHOW';
  }

  my $del_class = '';
  my $deleted   = '';
  my $domain_id = '';

  if ($user_info->{DELETED}) {
    $deleted   = $html->b($lang{DELETED});
    $del_class = ' alert-danger';
  }

  my $ext_menu  = user_ext_menu($uid, $user_info->{LOGIN}, { SHOW_UID => 1 });

  if (! $admin->{DOMAIN_ID} && $user_info->{DOMAIN_ID}) {
    $domain_id = " DOMAIN: $user_info->{DOMAIN_ID}";
  }

  my $pre_button  = $html->button(" ", "index=$index&UID=$uid&PRE=$uid",  { class=> 'pull-left btn btn-sm btn-default glyphicon glyphicon-arrow-left', TITLE => $lang{BACK} } );
  my $next_button = $html->button(" ", "index=$index&UID=$uid&NEXT=$uid", { class=> 'pull-right btn btn-sm btn-default glyphicon glyphicon-arrow-right', TITLE => $lang{NEXT} } );

  #show tags
  my $user_tags   = '';
  if (in_array('Tags', \@MODULES)) {
    require Tags;
    Tags->import();
    my $Tags = Tags->new($db, $admin, \%conf);

    my $list  = $Tags->tags_user({ NAME      => '_SHOW',
        PRIORITY  => '_SHOW',
        DATE      => '_SHOW',
        UID       => $uid,
        COLS_NAME => 1
      });

    my @tags_arr = ();

    foreach my $line (@$list) {
      if ($line->{date}) {
        push @tags_arr, $html->element('span', $line->{name}, { class => "btn btn-xs $priority_colors[$line->{priority}]" });
      }
    }

    $user_tags = ((@tags_arr) ? join(" ", @tags_arr) : '')
        . $html->element('span', '', { class => "btn btn-xs glyphicon glyphicon-tags",
        title   => "$lang{ADD} Tag",
        onclick => "loadToModal('$SELF_URL?qindex=".get_function_index('tags_user')."&UID=$uid&header=2&FORM_NAME=USERS_TAG')"
    });
  }

  my $full_info = $html->button('', "index=$index&UID=$uid&SUMMARY_SHOW=1", { class => 'glyphicon glyphicon-th-large' });

  $user_info->{TABLE_SHOW} = $html->element('div', "$pre_button $ext_menu $full_info $domain_id $deleted $user_tags  $next_button",
    { class => "well well-sm$del_class sticky" });

  #main function button
  if (! $FORM{step} ) {
    my @header_arr = ("$lang{MAIN}:index=15&UID=$uid",
      "$lang{INFO}:index=30&UID=$uid");

    if (defined($permissions{1})) {
      push @header_arr, "$lang{PAYMENTS}:UID=$uid&index=2";
    }

    if (defined($permissions{2})) {
      push @header_arr, "$lang{FEES}:UID=$uid&index=3";
    }

    #my $second_menu    = '';
    my %userform_menus = (
      103=> $lang{SHEDULE},
      22 => $lang{LOG},
      21 => $lang{COMPANY},
      12 => $lang{GROUP},
      18 => $lang{NAS},
      #20 => $lang{SERVICES},
      19 => $lang{BILL}
    );

    $userform_menus{17} = $lang{PASSWD} if ($permissions{0}{3});

    while (my ($k, $v) = each %uf_menus) {
      $userform_menus{$k} = $v;
    }

    foreach my $k (sort { $b <=> $a } keys %userform_menus) {
      my $v   = $userform_menus{$k};
      my $url = "index=$k&UID=$uid";
      my $active = (defined($FORM{$k})) ? $html->b($v) : $v;

      my $info = '';
      if ($functions{$k} eq 'msgs_admin') {
        load_module("Msgs", $html);
        my $count=msgs_new({ ADMIN_UNREAD => $uid });
        if ($count && $count > 0) {
          $info=$html->badge($count, { TYPE => 'alert-danger' });
        }
      }
      elsif($functions{$k} eq 'form_shedule') {
        require Shedule;
        Shedule->import();

        my $Shedule = Shedule->new($db, $admin, \%conf);

        $Shedule->list({ UID  => $uid });
        if ($Shedule->{TOTAL}) {
          $info = $html->badge($Shedule->{TOTAL}, { TYPE => 'alert-warning' });
        }
      }

      push @header_arr, "$active $info:$url";
    }

    my $full_delete = '';
    if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8} && ($user_info->{DELETED})) {
      push @header_arr, "$lang{UNDELETE}:index=15&del_user=1&UNDELETE=1&UID=$uid:MESSAGE=$lang{UNDELETE} $lang{USER}: $user_info->{LOGIN} / $uid";
      $full_delete = "&FULL_DELETE=1";
    }

    push @header_arr, "$lang{DEL}:index=15&del_user=1&UID=$uid$full_delete:MESSAGE=$lang{USER}: $user_info->{LOGIN} / $uid" if (defined($permissions{0}{5}));
    $user_info->{TABLE_SHOW} .= $html->table_header(\@header_arr, { TABS => 1, SHOW_ONLY => 7, USE_INDEX => 1 });
    # End main function
  }

  $LIST_PARAMS{UID} = $uid;
  $FORM{UID}        = $uid;
  $pages_qs         = "&UID=$uid";
  $pages_qs        .= "&subf=$FORM{subf}" if ($FORM{subf});

  return $user_info;
}


#**********************************************************
=head2 form_users_list($attr)

=cut
#**********************************************************
sub form_users_list {
  #my ($attr) = @_;

  if (!$permissions{0}{2}) {
    return 0;
  }

  if( $FORM{MULTIUSER} ) {
    form_users();
  }

  if ($FORM{COMPANY_ID} && !$FORM{change}) {
    print $html->br($html->b("$lang{COMPANY}:") . $FORM{COMPANY_ID});
    $pages_qs .= "&COMPANY_ID=$FORM{COMPANY_ID}";
    $LIST_PARAMS{COMPANY_ID} = $FORM{COMPANY_ID};
  }

  if ($FORM{letter}) {
    $LIST_PARAMS{LOGIN} = "$FORM{letter}*";
    $pages_qs .= "&letter=$FORM{letter}";
  }

  my @statuses = ($lang{ALL},
    $lang{ACTIV},
    $lang{DEBETORS},
    $lang{DISABLE},
    $lang{EXPIRE},
    $lang{CREDIT},
    $lang{NOT_ACTIVE},
    $lang{PAID},
    $lang{UNPAID});

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    push @statuses, $lang{DELETED},;
  }

  my $i            = 0;
  my $users_status = 0;
  my @status_bar_arr = ();

  $FORM{USERS_STATUS}=0 if (! defined($FORM{USERS_STATUS}));
  my $qs = '';
  foreach my $name (@statuses) {
    my $active = '';
    if (defined($FORM{USERS_STATUS}) && $FORM{USERS_STATUS} =~ /^\d+$/ && $FORM{USERS_STATUS} == $i) {
      $LIST_PARAMS{USER_STATUS} = 1;
      if ($i == 1) {
        $LIST_PARAMS{ACTIVE} = 1;
      }
      elsif ($i == 2) {
        $LIST_PARAMS{DEPOSIT} = '<0';
      }
      elsif ($i == 3) {
        $LIST_PARAMS{DISABLE} = 1;
      }
      elsif ($i == 4) {
        $LIST_PARAMS{EXPIRE} = "<=$DATE;>0000-00-00";
      }
      elsif ($i == 5) {
        $LIST_PARAMS{CREDIT} = ">0";
      }
      elsif ($i == 6) {
        $LIST_PARAMS{DISABLE} = 2;
      }
      elsif ($i == 7) {
        $LIST_PARAMS{PAID} = 1;
      }
      elsif ($i == 8) {
        $LIST_PARAMS{UNPAID} = 1;
      }
      elsif ($i == 9) {
        $LIST_PARAMS{DELETED} = 1;
      }

      $pages_qs   .= "&USERS_STATUS=$i";
      $users_status = $i;
      $active      = 'active';
    }
    else {
      $qs = $pages_qs;
      $qs =~ s/\&USERS_STATUS=\d//;
    }

    push @status_bar_arr, "$name:index=$index&USERS_STATUS=$i$qs";
    $i++;
  }
  my Abills::HTML $table;
  my $list;
  ($table, $list) = result_former({
    INPUT_DATA      => $users,
    FUNCTION        => 'list',
    BASE_FIELDS     => 1,
    DEFAULT_FIELDS  => 'LOGIN,FIO,DEPOSIT,CREDIT,LOGIN_STATUS',
    FUNCTION_FIELDS => 'form_payments, form_fees',
    TABLE => {
      width      => '100%',
      FIELDS_IDS => $users->{COL_NAMES_ARR},
      caption    => "$lang{USERS} - " . $statuses[$users_status],
      cols_align => [ 'left', 'left', 'right', 'right', 'center', 'right', 'center:noprint', 'center:noprint' ],
      qs         => $pages_qs,
      ID         => 'USERS_LIST',
      SELECT_ALL => ($permissions{0}{7}) ? "users_list:IDS:$lang{SELECT_ALL}" : undef,
      header     => \@status_bar_arr,
      EXPORT     => 1,
      IMPORT     => "$SELF_URL?get_index=form_users&import=1&header=2",
      MENU       => "$lang{ADD}:index=" . get_function_index('form_wizard') . ':add' . ";$lang{SEARCH}:index=" . get_function_index('form_search') . ":search",
    }
    });

  if (_error_show($users)) {
    return 0;
  }
  elsif ($users->{TOTAL} && $users->{TOTAL} == 1 && ! $FORM{SKIP_FULL_INFO}) {
    $FORM{index} = 15;

    if (!$FORM{UID}) {
      $FORM{UID} = $list->[0]->{uid};
      if (! $FORM{LOGIN} || $FORM{LOGIN} =~ /\*/) {
        delete $FORM{LOGIN};
        $ui = user_info($FORM{UID});
        print $ui->{TABLE_SHOW} if ($ui->{TABLE_SHOW});
      }
    }

    form_users({ USER_INFO => $ui });

    return 1;
  }
  elsif (! $users->{TOTAL}) {
    $html->message('err', $lang{ERROR}, "$lang{USER} $lang{NOT_EXIST}");
    return 0;
  }

  print $html->letters_list({ pages_qs => $pages_qs });

  my $search_color_mark;
  if ($FORM{UNIVERSAL_SEARCH}) {
    $search_color_mark=$html->color_mark($FORM{UNIVERSAL_SEARCH}, $lang{COLORS}[6]);
  }

  my $countries_hash;

  if ( ! $conf{ADDRESS_REGISTER} ) {
    ($countries_hash, undef) = sel_countries();
  }

  my $base_fields = 1;
  foreach my $line (@$list) {
    my $uid      = $line->{uid};
    my $payments = ($permissions{1}) ? $html->button($lang{PAYMENTS}, "index=2&UID=$uid", { class => 'payments' }) : '';
    my $fees     = ($permissions{2}) ? $html->button($lang{FEES}, "index=3&UID=$uid", { class => 'fees' }) : '';

    if ($FORM{UNIVERSAL_SEARCH}) {
      $line->{fio} =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{fio});
      $line->{login}  =~ s/(.*)$FORM{UNIVERSAL_SEARCH}(.*)/$1$search_color_mark$2/ if ($line->{login});
    }

    my @fields_array = ();
    for ($i = $base_fields; $i < $base_fields+$users->{SEARCH_FIELDS_COUNT}; $i++) {
      if ($conf{EXT_BILL_ACCOUNT} && $users->{COL_NAMES_ARR}->[$i] eq 'ext_bill_deposit') {
        $line->{ext_bill_deposit} = ($line->{ext_bill_deposit} < 0) ? $html->color_mark($line->{ext_bill_deposit}, 'text-danger') : $line->{ext_bill_deposit};
      }
      elsif ($users->{COL_NAMES_ARR}->[$i] eq 'deleted') {
        $line->{deleted} = $html->color_mark($bool_vals[ $line->{deleted} ], ($line->{deleted} == 1) ? $state_colors[ $line->{deleted} ] : '');
      }
      elsif($users->{COL_NAMES_ARR}->[$i] eq 'deposit') {
        $line->{$users->{COL_NAMES_ARR}->[$i]} =  ($permissions{0}{12}) ? '--' : (($line->{deposit} ? $line->{deposit} : 0) + ($line->{credit} || 0) < 0) ? $html->color_mark($line->{deposit}, 'text-danger') : $line->{deposit},
      }
      elsif($users->{COL_NAMES_ARR}->[$i] eq 'tags') {
        $line->{$users->{COL_NAMES_ARR}->[$i]} =  ' '. $html->element('span', $line->{tags}, { class => "btn btn-xs $priority_colors[$line->{priority}]" });
      }
      elsif($users->{COL_NAMES_ARR}->[$i] eq 'last_payment' && $line->{last_payment}) {
        my($date, undef) = split(/ /, $line->{last_payment});

        if($date && $DATE eq $date) {
          $line->{last_payment}=$html->color_mark($line->{last_payment}, 'text-danger');
        }
      }
      elsif($users->{COL_NAMES_ARR}->[$i] eq 'country_id') {
        $line->{$users->{COL_NAMES_ARR}->[$i]} = $countries_hash->{$line->{$users->{COL_NAMES_ARR}->[$i]}};
      }
      elsif ($FORM{UNIVERSAL_SEARCH}) {
        if ($FORM{UNIVERSAL_SEARCH} && $line->{$users->{COL_NAMES_ARR}->[$i]}){
          $line->{$users->{COL_NAMES_ARR}->[$i]} =~ s/(.{0,100})$FORM{UNIVERSAL_SEARCH}(.{0,100})/$1$search_color_mark$2/;
        }
      }

      if ($users->{COL_NAMES_ARR}->[$i] eq 'login_status') {
        push @fields_array, $table->td($status[ $line->{login_status} ], { class => $state_colors[ $line->{login_status} ], align => 'center' });
      }
      else {
        push @fields_array, $table->td($line->{$users->{COL_NAMES_ARR}->[$i]});
      }
    }

    @fields_array = ($table->td(user_ext_menu($uid, $line->{login})), @fields_array);

    if ($permissions{0}{7}) {
      @fields_array = ($table->td($html->form_input('IDS', "$uid", { TYPE => 'checkbox', FORM_ID => 'users_list' })), @fields_array);
    }

    $table->addtd(
      @fields_array,
      $table->td($payments),
      $table->td($fees),
    );
  }

  my @totals_rows = (
    [ $html->button("$lang{TOTAL}:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ],
    [ $html->button("$lang{EXPIRE}:", "index=$index&USERS_STATUS=4"), $html->b($users->{TOTAL_EXPIRED}) ],
    [ $html->button("$lang{DISABLE}:", "index=$index&USERS_STATUS=3"), $html->b($users->{TOTAL_DISABLED}) ]
  );

  if ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) {
    $users->{TOTAL} -= $users->{TOTAL_DELETED} || 0;
    $totals_rows[0]  = [ $html->button("$lang{TOTAL}:", "index=$index&USERS_STATUS=0"), $html->b($users->{TOTAL}) ];
    push @totals_rows, [ $html->button("$lang{DELETED}:", "index=$index&USERS_STATUS=9"), $html->b($users->{TOTAL_DELETED}) ],;
  }

  my $table2 = $html->table(
    {
      width      => '100%',
      cols_align => [ 'right', 'right' ],
      rows       => \@totals_rows
    }
  );

  if ($permissions{0}{7} && ! $FORM{EXPORT_CONTENT}) {
    $html->{FORM_ID}='users_list';
    my $table3 = $html->table(
      {
        width      => '100%',
        caption    => $lang{MULTIUSER_OP},
        cols_align => [ 'left', 'left' ],
        rows       => [
          [ $html->form_input('MU_GID',         1, { TYPE => 'checkbox', }) . $lang{GROUP},     sel_groups({ SKIP_MUULTISEL => 1 }) ],
          [ $html->form_input('MU_DISABLE',     1, { TYPE => 'checkbox', }) . $lang{DISABLE},   $html->form_input('DISABLE',     "1", { TYPE => 'checkbox', }) . $lang{CONFIRM} ],
          [ $html->form_input('MU_DEL',         1, { TYPE => 'checkbox', }) . $lang{DEL},       $html->form_input('DEL',         "1", { TYPE => 'checkbox', }) . $lang{CONFIRM} ],
          [ $html->form_input('MU_ACTIVATE',    1, { TYPE => 'checkbox', }) . $lang{ACTIVATE},  $html->date_fld2('ACTIVATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
          [ $html->form_input('MU_EXPIRE',      1, { TYPE => 'checkbox', }) . $lang{EXPIRE},    $html->date_fld2('EXPIRE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1 }) ],
          [ $html->form_input('MU_CREDIT',      1, { TYPE => 'checkbox', }) . $lang{CREDIT},    $html->form_input('CREDIT',      $FORM{CREDIT}) ],
          [ $html->form_input('MU_CREDIT_DATE', 1, { TYPE => 'checkbox', }) . "$lang{CREDIT} $lang{DATE}", $html->date_fld2('CREDIT_DATE', { FORM_NAME => 'users_list', WEEK_DAYS => \@WEEKDAYS, MONTHES => \@MONTHES, NO_DEFAULT_DATE => 1, DATE => $FORM{CREDIT_DATE} }) ],
          [ '', $html->form_input('MULTIUSER', "$lang{CHANGE}", { TYPE => 'submit' }) ],
        ],
        ID => 'USER_MANAGMENT'
      }
    );

    print $html->form_main(
        {
          CONTENT => $table->show({ OUTPUT2RETURN => 1 })
            . ((!$admin->{MAX_ROWS}) ? $table2->show({ OUTPUT2RETURN => 1 }) : '')
            . $table3->show({ OUTPUT2RETURN => 1 })
          ,
          HIDDEN  => {
            index       => 11,
            #FULL_DELETE => ($admin->{permissions}->{0} && $admin->{permissions}->{0}->{8}) ? 1 : undef,
          },
          NAME    => 'users_list',
          class   => 'hidden-print',
          ID      => 'users_list',
        }
      );
  }
  else {
    print $table->show();
    print $table2->show() if (!$admin->{MAX_ROWS});
  }

  return 1;
}

#**********************************************************
=head2 user_del($attr)

=cut
#**********************************************************
sub user_del {
  my ($attr) = @_;

  my Users $user_info = $attr->{USER_INFO};

  if ($FORM{UNDELETE}) {
    $user_info->change($user_info->{UID}, { UID => $user_info->{UID}, DELETED => 0 });
    $html->message('info', $lang{UNDELETE}, "UID: [$user_info->{UID}] $lang{UNDELETE} $user_info->{LOGIN}");
    return 0;
  }

  $user_info->del({%FORM});
  $conf{DELETE_USER} = $user_info->{UID};

  if (! _error_show($user_info)) {
    if ($conf{external_userdel}) {
      if (!_external($conf{external_userdel}, { %FORM, %$user_info })) {
        $html->message('err', $lang{DELETED}, "External cmd: $conf{external_userdel}");
      }
    }
    $html->message('info', $lang{DELETED}, "UID: $user_info->{UID}\n $lang{DELETED} $user_info->{LOGIN}");
  }

  if ($FORM{FULL_DELETE}) {
    my $mods = '';
    foreach my $mod (@MODULES) {
      $mods .= "$mod,";
      load_module($mod, $html);

      my $function = lc($mod) . '_user_del';
      if (defined(&$function)) {
        &{ \&$function }($user_info->{UID}, $user_info);
      }
    }

    if (! _error_show($user_info)) {
      if ($conf{external_userdel}) {
        if (!_external($conf{external_userdel}, { %FORM, %$user_info })) {
          $html->message('err', $lang{DELETED}, "External cmd: $conf{external_userdel}");
        }
      }

      $html->message('info', $lang{DELETED}, "UID: $user_info->{UID}\n $lang{MODULES}: $mods");
    }
  }

  return 1;
}

#**********************************************************
=head2 user_group($attr)

=cut
#**********************************************************
sub user_group {
  my ($attr) = @_;
  my $user = $attr->{USER_INFO};

  if ( ! $user ) {
    $html->message('err', $lang{ERROR}, 'No user information');
    return 1;
  }

  $user->{SEL_GROUPS} = sel_groups({
      GID            => ($user && $user->{GID}) ? $user->{GID} : undef,
      SKIP_MUULTISEL => 1
    });
  $html->tpl_show(templates('form_chg_group'), $user);

  return 1;
}

#**********************************************************
=head2 user_company($attr)

=cut
#**********************************************************
sub user_company {
  my ($attr) = @_;
  my $user_info = $attr->{USER_INFO};
  require Customers;
  Customers->import();
  my $customer = Customers->new($db, $admin, \%conf);
  my $company  = $customer->company();

  form_search(
    {
      SIMPLE        => { $lang{COMPANY} => 'COMPANY_NAME' },
        HIDDEN_FIELDS => { UID       => $FORM{UID} }
    }
  );

  my $list  = $company->list({%LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      title      => [ "$lang{NAME}", "$lang{DEPOSIT}", '-' ],
      cols_align => [ 'right', 'left', 'center:noprint' ],
      qs         => $pages_qs,
      pages      => $company->{TOTAL},
      ID         => 'COMPANY_LIST'
    }
  );

  $FORM{UID} = 0 if (!$FORM{UID});

  $table->addrow($lang{DEFAULT}, '', $html->button("$lang{DEL}", "index=" . get_function_index('form_users') . "&change=1&UID=$FORM{UID}&COMPANY_ID=0", { class => 'del' }),);

  foreach my $line (@$list) {
    $table->{rowcolor} = ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? 'active' : undef;
    $table->addrow(
        ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? $html->b( $line->{name} ) : $line->{name}
      ,
      $line->{deposit},
        ($user_info->{COMPANY_ID} && $user_info->{COMPANY_ID} == $line->{id}) ? '' : $html->button( "$lang{CHANGE}",
          "index=" . get_function_index( 'form_users' ) . "&change=1&UID=$FORM{UID}&COMPANY_ID=$line->{id}",
          { class => 'add' } ),
    );
  }

  print $table->show();
}

#**********************************************************
=head2 user_full_info($attr) - Show user json info

=cut
#**********************************************************
sub user_full_info {

  my ($base_slides, $active_slides) = form_slides_info();
  my $content;
  my $info     = '';
  my @info_arr = ();

  for(my $slide_num=0; $slide_num <= $#{ $base_slides }; $slide_num++ ) {
    my @content_arr = ();

    my $slide_name   = $base_slides->[$slide_num]->{ID};

    if (scalar keys %$active_slides > 0 && ! $active_slides->{$slide_name} ) {
      next;
    }

    my $field_info;
    if($base_slides->[$slide_num]->{FN} && defined(&{$base_slides->[$slide_num]{FN}})) {
      my $fn = $base_slides->[$slide_num]->{FN};
      $field_info = &{ \&$fn }({ UID => $FORM{UID} });
    }

    if ($base_slides->[$slide_num]{SLIDES}) {
      foreach my $slide_line ( @{ $field_info } ) {
        foreach my $filed_name ( @{ $base_slides->[$slide_num]->{SLIDES} }) {
          while(my ($k, $v) = each %$filed_name) {
            push @info_arr, '"'. ((defined($v)) ? $v : q{}) .'" : "'. ((defined($slide_line->{$k})) ? $slide_line->{$k} : q{}) . '"';
          }
        }
        push @content_arr, '{'. join(', ', @info_arr) .'}';
      }

      $content = '"SLIDES": [ '. join(",\n", @content_arr ) .' ]' ;
    }
    else {
      foreach my $field_name ( keys %{ $base_slides->[$slide_num]{FIELDS} } ) {
        push @content_arr, qq{"$base_slides->[$slide_num]{FIELDS}->{$field_name}" : "}. (defined($field_info->{$field_name}) ? $field_info->{$field_name} : $field_name ) . qq{" };
      }

      $content = '"CONTENT" : {'. join(",\n", @content_arr) . '}' ;
    }

    foreach my $field_name ( keys %{ $base_slides->[$slide_num]{FIELDS} } ) {
      push @content_arr, qq{"$base_slides->[$slide_num]{FIELDS}->{$field_name}" : "}. (defined($field_info->{$field_name}) ? $field_info->{$field_name} : $field_name ) . qq{" };
    }

    my $slide_info =  qq/
  "NAME": "$slide_name",
  "HEADER": "/. (($base_slides->[$slide_num]->{HEADER}) ? $base_slides->[$slide_num]->{HEADER} : $slide_name ) . qq/",
  "SIZE": "/. (($active_slides->{$slide_name} && $active_slides->{$slide_name}->{SIZE}) ? $active_slides->{$slide_name}->{SIZE} : 1 ) . qq/",
  "PROPORTION": 2,
  $content /;
    push @info_arr, "{ $slide_info }";
  }

  $info = "[". join(",\n", @info_arr) ."]";

  return $info;
}

#**********************************************************
=head2 quick_info_user() User information for slides

=cut
#**********************************************************
sub quick_info_user {
  my ($attr)  = @_;

  $users->info($attr->{UID});

  return $users;
}

#**********************************************************
=head2 quick_info_portal_session() User portal sessions

=cut
#**********************************************************
sub quick_info_portal_session {
  my ($attr)  = @_;

  $users->web_session_info({ UID => $attr->{UID} });
  $users->{DATETIME}=sec2date($users->{DATETIME});

  return $users;
}

#**********************************************************
=head2 quick_info_pi() User personal  information for slides

=cut
#**********************************************************
sub quick_info_pi {
  my ($attr)  = @_;

  $users->pi({ UID => $attr->{UID} });

  return $users;
}

#**********************************************************
=head2 quick_info_payments() User personal  information for slides

=cut
#**********************************************************
sub quick_info_payments {
  my ($attr)  = @_;

  my $Payments = Finance->payments($db, $admin, \%conf);

  my $list = $Payments->list({ UID    => $attr->{UID},
      DATETIME     => '_SHOW',
      SUM          => '_SHOW',
      METHOD       => '_SHOW',
      LAST_DEPOSIT => '_SHOW',
      COLS_NAME    => 1,
      COLS_UPPER   => 1,
      PAGE_ROWS    => 1
    });

  my $result = $list->[0];

  return $result;
}

#**********************************************************
=head2 quick_info_fees() User personal  information for slides

=cut
#**********************************************************
sub quick_info_fees {
  my ($attr)  = @_;

  my $Fees = Finance->fees($db, $admin, \%conf);

  my $list = $Fees->list({
      UID    => $attr->{UID},
      DATETIME     => '_SHOW',
      SUM          => '_SHOW',
      LAST_DEPOSIT => '_SHOW',
      METHOD       => '_SHOW',
      COLS_NAME    => 1,
      COLS_UPPER   => 1,
      PAGE_ROWS    => 1
    });

  my $result = $list->[0];

  return $result;
}

#**********************************************************
=head2 form_slides_info() - Slides information
=cut
#**********************************************************
sub form_slides_info {

  my @base_slides = (
    { ID     => 'MAIN_INFO',
      HEADER => "$lang{USER}",
      FIELDS => {
        LOGIN  => $lang{LOGIN},
        DEPOSIT=> $lang{DEPOSIT},
        CREDIT => $lang{CREDIT},
        UID    => 'UID',
        DISABLE=> $lang{DISABLE},
      },
      FN      => 'quick_info_user',
    },
    { ID     => 'PERSONAL_INFO',
      HEADER => $lang{USER_INFO},
      FIELDS => {
        EMAIL       => 'e-mail',
        FIO         => $lang{FIO},
        PHONE       => $lang{PHONE},
        CONTRACT_ID => $lang{CONTRACT},
        COMMENTS    => $lang{COMMENTS},
      },
      FN      => 'quick_info_pi'
    },
    { ID     => 'INFO_FIELDS',
      HEADER => $lang{INFO_FIELDS},
      FIELDS => {
      },
      FN      => 'quick_info_info_fields'
    },
    { ID     => 'PAYMENTS',
      HEADER => $lang{PAYMENTS},
      FIELDS => {
        DATETIME     => $lang{DATE},
        SUM          => $lang{SUM},
        METHOD       => $lang{PAYMENT_METHOD},
        LAST_DEPOSIT => $lang{DEPOSIT}
      },
      FN      => 'quick_info_payments'
    },
    { ID     => 'FEES',
      HEADER => $lang{FEES},
      FIELDS => {
        DATETIME     => $lang{DATE},
        SUM          => $lang{SUM},
        METHOD       => $lang{TYPE},
        LAST_DEPOSIT => $lang{DEPOSIT}
      },
      FN      => 'quick_info_fees'
    },
    { ID     => 'PORTAL_SESSION',
      HEADER => 'USER_PORTAL',
      FIELDS => {
        DATETIME    => $lang{DATE},
        LOGIN       => 'LOGIN',
        REMOTE_ADDR => 'IP',
        ACTIVATE    => $lang{ACTIVE},
        SID         => 'sid'
      },
      FN      => 'quick_info_portal_session'
    },
  );

  foreach my $module (@MODULES) {
    load_module($module, $html);
    my $fn = lc($module) . '_quick_info';
    if (defined(&$fn)) {
      my $slide_info = &{ \&$fn }({ GET_PARAMS => 1 });
      $slide_info->{FN} = $fn;
      $slide_info->{ID} = uc($module);
      push @base_slides, $slide_info;
    }
  }

  require Admin_slides;
  my $Admin_slides = Admin_slides->new($db, $admin, \%conf);

  if ($FORM{action}) {
    $Admin_slides->add(\%FORM);
  }

  my $list = $Admin_slides->list({ AID       => $admin->{AID},
      SIZE      => '_SHOW',
      PRIORITY  => '_SHOW',
      COLS_NAME => 1
    });

  my %admin_slides = ();

  foreach my $line (@$list) {
    $admin_slides{$line->{slide_name}}{$line->{field_id}} = 1;
    $admin_slides{$line->{slide_name}}{'w_'. $line->{field_id}} = $line->{field_warning};
    $admin_slides{$line->{slide_name}}{'c_'. $line->{field_id}} = $line->{field_comments};
    $admin_slides{$line->{slide_name}}{'PRIORITY'}              = $line->{priority};
    $admin_slides{$line->{slide_name}}{'SIZE'}                  = $line->{size};
  }

  return \@base_slides, \%admin_slides;
}

#**********************************************************
=head2 form_wizard($attr) - User registration wizards

  Arguments:
    $attr

  Result:
    TRUE or FALSE


=cut
#**********************************************************
sub form_wizard {
#  my ($attr) = @_;

  # Function name:module:describe
  my %steps = ();

  $index = get_function_index('form_wizard');
  my DBI $db_ = $db->{db};

  if ($conf{REG_WIZARD}) {
    $conf{REG_WIZARD} =~ s/[\r\n]+//g;
  }
  else {
    $conf{REG_WIZARD} = "user_form::$lang{ADD} $lang{USER}"
      .  ";form_payments::$lang{PAYMENTS}";

    $conf{REG_WIZARD} .= ';dv_user:Dv:Internet'                 if (in_array('Dv',   \@MODULES));
    $conf{REG_WIZARD} .= ";dhcphosts_user:Dhcphosts:IPoE/DHCP"  if (in_array('Dhcphosts', \@MODULES));
    $conf{REG_WIZARD} .= ";abon_user:Abon:$lang{ABON}"          if (in_array('Abon', \@MODULES));
    $conf{REG_WIZARD} .= ";form_fees_wizard::$lang{FEES}";
    $conf{REG_WIZARD} .= ";iptv_user:Iptv:$lang{TV}"            if (in_array('Iptv', \@MODULES));
    $conf{REG_WIZARD} .= ";msgs_admin_add:Msgs:$lang{MESSAGES}" if (in_array('Msgs', \@MODULES));
  }

  my @arr = split(/;\s?/, ';' . $conf{REG_WIZARD});
  for (my $i = 1 ; $i <= $#arr ; $i++) {
    $steps{$i} = $arr[$i];
  }

  my $return     = 0;
  my $reg_output = '';
  START:
  delete $FORM{OP_SID};
  if (!$FORM{step}) {
    $FORM{step} = 1;
  }
  elsif ($FORM{back}) {
    $FORM{step} = $FORM{step} - 2;
  }
  elsif ($FORM{update}) {
    $FORM{step}--;
    $FORM{back} = 1;
  }

  if ($FORM{UID}) {
    $LIST_PARAMS{UID} = $FORM{UID};
    $users->info($FORM{UID});
    $users->pi({ UID => $FORM{UID} });
  }

  #Make functions
  if ($FORM{step} > 1 && !$FORM{back}) {
    $html->{NO_PRINT} = 1;
    #REG:

    $db->{TRANSACTION}=1;
    $db_->{AutoCommit} = 0;

    my $step = $FORM{step} - 1;
    # $fn, $module, $describe
    my ($fn, $module, undef) = split(/:/, $steps{$step}, 3);

    if ($module) {
      if (in_array($module, \@MODULES)) {
        load_module($module, $html);
      }
      else {
        next;
      }
    }

    if (! $FORM{change}) {
      $FORM{add} = 1;
    }
    else {
      $FORM{next} = 1;
    }

    $FORM{UID} = $LIST_PARAMS{UID} if (!$FORM{UID} && $LIST_PARAMS{UID});

    #    $FORM{DEBUG}=1;
    if ($FORM{DEBUG}) {
      print $html->br() . "Function: $fn ". $html->br();
      while(my($k, $v)=each %FORM) {
        print "$k, $v". $html->br();
      }
    }

    $return = &{ \&$fn }({ REGISTRATION => 1, USER_INFO => ($FORM{UID}) ? $users : undef });

    $LIST_PARAMS{UID} = $FORM{UID};
    print "<b>Return: $return</b>". $html->br() if ($FORM{DEBUG});

    # Error
    if (! $return) {
      $db_->rollback();
      $FORM{step}      += 1;
      $FORM{back}       = 1;
      $html->{NO_PRINT} = undef;
      $FORM{add}        = undef;
      $FORM{change}     = undef;
      $reg_output       = $html->{OUTPUT};
      goto START;
    }
    else {
      $db_->commit();
    }

    $FORM{add}        = undef;
    $FORM{change}     = undef;
    $html->{NO_PRINT} = undef;

    $reg_output = $html->{OUTPUT};
  }

  my ($fn, $module);
  if($FORM{step}) {
    ($fn, $module) = split(/:/, $steps{ $FORM{step} }, 3);
  }
  my @rows = ();

  foreach my $i (sort keys %steps) {
    my $describe = (split(/:/, $steps{$i}, 3))[2];
    my $active = '';
    if ($i < $FORM{step}) {
      $active = 'btn-success';
    }
    elsif ($i == $FORM{step}) {
      $active = 'btn-primary';
    }
    else {
      $active = 'disabled';
    }

    push @rows, $html->button("$lang{STEP}: $i $describe", "index=$index&back=1". (($FORM{UID}) ? "&UID=$FORM{UID}" : '' ). "&step=" . ($i + 2), { class => 'btn btn-default '. $active });
  }

  if ($FORM{finish}) {
    $reg_output = '';
  }

  print $html->element('div', join('', @rows), { class => "btn-group btn-group-justified sticky" });
  print $reg_output;

  if (!$steps{ $FORM{step} } || $FORM{finish} || (!$FORM{next} && $FORM{step} == 2 && !$FORM{back})) {
    $html->message('info', $lang{INFO}, "$lang{REGISTRATION_COMPLETE}");
    undef $FORM{UID};
    undef $FORM{LOGIN};
    form_users({ USER_INFO => $users });
    return 0;
  }

  if ($module) {
    if (in_array($module, \@MODULES)) {
      load_module($module, $html);
    }
    else {
      $FORM{step}++;
      goto START;
    }
  }

  $FORM{step}++;

  if($fn eq 'form_payments' && ! $FORM{SUM}) {
    $FORM{SUM}=0;
  }

  &{ \&$fn }(
    {
      %FORM,
      ACTION       => 'next',
      REGISTRATION => 1,
      #USER        => \%FORM,
      USER_INFO    => ($FORM{UID})            ? $users   : undef,
      LNG_ACTION   => ($steps{ $FORM{step} }) ? "$lang{NEXT}" : "$lang{REGISTRATION_COMPLETE}",
      BACK_BUTTON  => (($FORM{TP_ID}) ? $html->form_input('TP_ID', "$FORM{TP_ID}", { TYPE => 'hidden' }) : '') .(   ($FORM{step} > 2) ? $html->form_input('finish', "$lang{FINISH}", { TYPE =>  ($steps{ $FORM{step} }) ? 'submit' : 'hidden' }) . ' ' . $html->form_input('back', "$lang{BACK}", { TYPE => 'submit' })
                                                                                                                                      : (!$FORM{back}) ? $html->form_input('add', "$lang{FINISH}", { TYPE => 'submit' })
                                                                                                                                                       : $html->form_input('change', "$lang{FINISH}", { TYPE => 'submit' })),
      UID          => $FORM{UID},
      SUBJECT      => $lang{REGISTRATION}
    }
  );

  return 1;
}


#**********************************************************
=head2 form_contact_types()

=cut
#**********************************************************
sub form_contact_types{

  my $show_add_form = '';
  my $contact_type = { };

  if ( $FORM{show_add_form} ){
    $show_add_form = 1;
  }
  elsif ( $FORM{chg} ){

    $contact_type = $users->contact_types_info($FORM{chg});
    _error_show( $users );

    $contact_type->{CHANGE_ID} = "ID";

    $show_add_form = 1;
  }
  elsif ( $FORM{add} ){
    $users->contact_types_add( \%FORM );
    $html->message( 'info', $lang{ADDED} ) if (!_error_show( $users ));
  }
  elsif ( $FORM{change} ){
    $FORM{IS_DEFAULT} = '0' if (!$FORM{IS_DEFAULT});
    $users->contact_types_change( \%FORM );
    $html->message( 'info', $lang{CHANGED} ) if (!_error_show( $users ));
  }
  elsif ( $FORM{del} ){
    $users->contact_types_del( { ID => $FORM{del} } );
    $html->message( 'info', $lang{DELETED} ) if (!_error_show( $users ));
  }

  if ( $show_add_form ){

    $contact_type->{IS_DEFAULT_CHECKED} = $contact_type->{IS_DEFAULT} ? 'checked="checked"' : q{};

    $html->tpl_show( templates( "form_contact_types" ), {
            %{$contact_type},
            SUBMIT_BTN_NAME   => ($FORM{chg}) ? "$lang{CHANGE}" : "$lang{ADD}",
            SUBMIT_BTN_ACTION => ($FORM{chg}) ? "change" : "add"
        } );
  }

  my $default_fields = 'ID,NAME,IS_DEFAULT';
  my $filter_cols = { map { $_, '_translate' } split ( ",", uc $default_fields ) };

  my ($table) = result_former( {
        INPUT_DATA          => $users,
            FUNCTION        => 'contact_types_list',
            #            BASE_FIELDS     => 3,
            DEFAULT_FIELDS  => $default_fields,
            FILTER_COLS     => $filter_cols,
            FUNCTION_FIELDS => 'change,del',
            SKIP_USER_TITLE => 1,
            EXT_FIELDS      => 0,
            EXT_TITLES      =>
            {
                id           => '#',
                name       => $lang{NAME},
                is_default => $lang{DEFAULT}
            },

            TABLE           =>
            {
                width   => '100%',
                caption => "$lang{CONTACTS} $lang{TYPE}",
                ID      => "CONTACT_TYPES_TABLE",
                EXPORT  => 1,
                MENU    => "$lang{ADD}:index=$index&show_add_form=1:add"
            },

            MAKE_ROWS       => 1,
            SEARCH_FORMER   => 1,
            MODULE          => 'Events',
      } );

  print $table->show();

}

#**********************************************************
=head2 _build_user_contacts_form($user_contacts_list)

  Arguments:
    $user_contacts_list -

  Returns:

=cut
#**********************************************************
sub _build_user_contacts_form{
  my ($user_contacts_list, $user_contacts_types_list) = @_;

  my $in_reg_wizard = ($FORM{UID}) ? 0 : 1;
  my $default_types_string = q{};

  # In reg wizard, show default types
  if ( $in_reg_wizard ){
    my @default_contacts = ();
    my @default_type_ids = ();

    my @default_types = grep { $_->{is_default} } @{$user_contacts_types_list};

    foreach my $default_type ( @default_types ){
      push( @default_contacts,
          {
              type_id => $default_type->{id},
              value   => ''
          }
      );
      push( @default_type_ids, $default_type->{id} );
    }

    $user_contacts_list = \@default_contacts;
    $default_types_string = join( ", ", @default_type_ids );
  }

  # Try to load fastest possible JSON module or fail
  my $json;

  my $json_load_error = load_pmodule( "JSON", { RETURN => 1 } );
  if ( $json_load_error ){
    print $json_load_error;
    return 0;
  }
  else{
    $json = JSON->new()->utf8(0);
  }

  my $contacts_json = $json->encode( {
          contacts => $user_contacts_list,
          options  => {
              callback_index => $index,
              types          => $user_contacts_types_list,
              uid            => $FORM{UID},
              in_reg_wizard  => $in_reg_wizard
          }
      } );

  my $user_contacts_template = $html->tpl_show(
      templates( 'form_user_contacts' ),
      {
          DEFAULT_TYPES => $default_types_string,
          JSON          => qq{ "json" : $contacts_json }
      },
      { OUTPUT2RETURN => 1 }
  );

  return $user_contacts_template;
}

#**********************************************************
=head2 user_contacts_renew()

=cut
#**********************************************************
sub user_contacts_renew{

  my $message = $lang{ERROR};
  my $status = 1;

  return 0 unless ($FORM{uid} && $FORM{CONTACTS});

  if ( my $error = load_pmodule( "JSON", { RETURN => 1 } ) ){
    print $error;
    return 0;
  }

  my $json = JSON->new();

  $FORM{CONTACTS} =~ s/\\\"/\"/g;

  my $contacts = $json->decode( $FORM{CONTACTS} );
  my DBI $db_ = $users->{db}->{db};
  if ( ref $contacts eq 'ARRAY' ){
    $db_->{AutoCommit} = 0;

    $users->contacts_del( { UID => $FORM{uid} } );
    if ( $users->{errno} ){
      $db_->rollback();
      $status = $users->{errno};
      $message = $users->{sql_errstr};
    }
    else{
      foreach my $contact ( @{$contacts} ){
        $users->contacts_add( { %{$contact}, UID => $FORM{uid} } );
      }

      if ( $users->{errno} ){
        $db_->rollback();
        $status = $users->{errno};
        $message = $users->{sql_errstr};
      }
      else{
        $db_->commit();
        $db_->{AutoCommit} = 1;
      }

      $message = $lang{CHANGED};
      $status = 0;
    }
  }

  print qq[
    {
      "status" : $status,
      "message" :  "$message"
    }
  ];
}

#**********************************************************
=head2 form_info_field_tpl($attr) - Info fields tp form

  Arguments:
    COMPANY  - Company info fields
    VALUES   - Info field value hash_ref

  Returns:
    Return formed form

=cut
#**********************************************************
sub form_info_field_tpl {
  my ($attr) = @_;

  my @field_result = ();

  my $prefix = $attr->{COMPANY} ? 'ifc*' : 'ifu*';
  my $list = $Conf->config_list(
    {
      PARAM => $prefix,
      SORT  => 2
    }
  );
  my $uid = $FORM{UID} || q{};

  foreach my $line (@$list) {
    my $field_id = '';

    if ($line->[0] =~ /$prefix(\S+)/) {
      $field_id = $1;
    }

    my ($position, $type, $name, $user_portal, $can_be_changed_by_user) = split(/:/, $line->[1]);
    next if ($attr->{CALLED_FROM_CLIENT_UI} && !$user_portal);

    my $input      = '';
    my $field_name = uc($field_id);
    if (!defined($type)) {
      $type = 0;
    }

    my $disabled_ex_params = ($attr->{CALLED_FROM_CLIENT_UI} && !$can_be_changed_by_user) ? 'disabled="disabled"' : '';

    #Select
    if ($type == 2) {
      $input = $html->form_select(
        "$field_name",
        {
          SELECTED => $attr->{VALUES}->{$field_name} || $FORM{$field_name},
          SEL_LIST    => $users->info_lists_list({ LIST_TABLE => $field_id . '_list', COLS_NAME => 1 }),
          SEL_OPTIONS => { ''                                 => '--' },
          NO_ID       => 1,
          ID          => $field_id,
          EX_PARAMS   => $disabled_ex_params,
          OUTPUT2RETURN  => 1
        }
      );
    }

    #Checkbox
    elsif ($type == 4) {
      $input = $html->form_input(
        $field_name,
        1,
        {
          TYPE  => 'checkbox',
          STATE => (($attr->{VALUES} && $attr->{VALUES}->{$field_name}) || $FORM{$field_name}) ? 1 : undef,
          ID    => $field_id,
          EX_PARAMS => ((!$attr->{SKIP_DATA_RETURN}) ? "data-return='1' " : '') . $disabled_ex_params,
          OUTPUT2RETURN  => 1
        }
      );
    }

    #'ICQ',
    elsif ($type == 8) {
      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
          SIZE => 10,
          ID => $field_id,
          EX_PARAMS => $disabled_ex_params,
          OUTPUT2RETURN  => 1
        });
      if ($attr->{VALUES}->{$field_name}) {
        #
        $input .= " <a href=\"http://www.icq.com/people/about_me.php?uin=$attr->{VALUES}->{$field_name}\"><img  src=\"http://status.icq.com/online.gif?icq=$attr->{VALUES}->{$field_name}&img=21\" border='0'></a>";
      }
    }

    #'URL',
    elsif ($type == 9) {
      $input = $html->element(
        'div',
        $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { ID => $field_id, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN  => 1 })
          . $html->element(
          'span',
          $html->button(
            $lang{GO},
            "",
            {
              GLOBAL_URL => $attr->{VALUES}->{$field_name},
              ex_params  => ' target=' . ($attr->{VALUES}->{$field_name} || '_new'),
            }
          ),
          { class => 'input-group-addon' }
        ),
        { class => 'input-group' }
      );
    }

    #'PHONE',
    #'E-Mail'
    #'SKYPE'
    elsif ($type == 12) {
      $input = $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { SIZE => 20, ID => $field_name, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN  => 1 });
      if ($attr->{VALUES}->{$field_name}) {
        $input .=
          qq{  <script type="text/javascript" src="http://download.skype.com/share/skypebuttons/js/skypeCheck.js"></script>  <a href="skype:abills.support?call"><img src="http://mystatus.skype.com/smallclassic/$attr->{VALUES}->{$field_name}" style="border: none;" width="114" height="20"/></a>};
      }
    }
    elsif ($type == 3) {
      $input = $html->form_textarea($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, { ID => $field_id, EX_PARAMS => $disabled_ex_params, OUTPUT2RETURN  => 1 });
    }
    elsif ($type == 13) {
      my $Attach = Attach->new($db, $admin, \%conf);
      $input = "<div class='input-group'>" . $html->form_input($field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_id}, { TYPE => 'file', ID => $field_id });

      if ($attr->{VALUES}->{$field_name}) {
        my $file_id = $attr->{VALUES}->{$field_name} || q{};
        $Attach->attachment_info({ ID => $file_id, TABLE => $field_id . '_file' });
        if ($Attach->{TOTAL}) {
          $input .= $html->element(
            'span',
            $html->button("$Attach->{FILENAME}, " . int2byte($Attach->{FILESIZE}), "qindex=" . get_function_index('user_pi') . "&ATTACHMENT=$field_id:$file_id", { BUTTON => 1 })
              . (($Attach->{FILENAME} && $permissions{0}{5}) ? $html->button('', "index=" . get_function_index('user_pi') . "&ATTACHMENT=$field_id:$file_id&del=1" . (($uid) ? "&UID=$uid" : ''), { class => 'del', MESSAGE => "$lang{DELETED}: $Attach->{FILENAME} ?" }) : ''),
            { class => 'input-group-addon' }
          );
        }
      }

      $input .= "</div>";
    }

    #Photo
    elsif ($type == 15) {
      $input = $html->button('', "index=$index&PHOTO=$uid&UID=$uid", { class => 'glyphicon glyphicon-camera' });
      if (-f "$conf{TPL_DIR}/if_image/" . $uid . '.jpg') {
        $input .= $html->element('span', '', { class => 'glyphicon glyphicon-user' });
      }
    }

    #Social network
    #Icons
    # fa fa-vk
    # fa fa-odnoklassniki
    # fa fa-facebook
    # fa fa-twitter
    # fa fa-google-plus
    elsif ($type == 16) {

      next if ($attr->{CALLED_FROM_CLIENT_UI}); # Social icons already displaying in "Password" tab

      my $values = ($attr->{VALUES} && $attr->{VALUES}->{$field_name}) ? $attr->{VALUES}->{$field_name} : ($FORM{$field_id} || '');
      my ($k, $val) = split(/, /, $values);
      $input = "<div class='form-group'>
      <div class='col-md-5'>"
        . $html->form_select(
        $field_name,
        {
          SELECTED  => $k,
          SEL_ARRAY => [ 'facebook', 'vk', 'twitter', 'ok', 'instagram', 'google' ],
          SEL_OPTIONS => { '' => '--' },
        }
      )
        . "</div><div class='col-md-7'>"
        . "<div class='input-group'>"
        . $html->form_input($field_name, $val, { ID => $field_id, OUTPUT2RETURN  => 1 });

      if ($val) {
        $input .= $html->element('span', $html->button('', "index=" . get_function_index('user_pi') . "&UID=$uid&SOCIAL_INFO=$k, $val", { class => 'info' }), { class => 'input-group-addon' });
      }

      $input .= "</div></div></div>";
    }
    else {
      if ($attr->{VALUES}->{$field_name}) {
        $attr->{VALUES}->{$field_name} =~ s/\"/\&quot;/g;
      }
      $input = $html->form_input( $field_name, $attr->{VALUES}->{$field_name} || $FORM{$field_name}, {
          ID            => $field_id,
          EX_PARAMS     => $disabled_ex_params,
          OUTPUT2RETURN => 1
        } );
    }

    $attr->{VALUES}->{ 'FORM_' . $field_name } = $input;

    push @field_result,
      $html->tpl_show(
        templates('form_row'),
        {
          ID    => "$field_id",
          NAME  => (_translate($name)),
          VALUE => $input
        },
        { OUTPUT2RETURN => 1, ID => "$field_id" }
      );
  }

  my $info = join((($FORM{json}) ? ',' : ''), @field_result);

  return $info;
}

#**********************************************************
=head2 form_show_attach($attr)
=cut
#**********************************************************
sub form_show_attach {
  require Attach;
  Attach->import();
  my $Attach = Attach->new($db, $admin, \%conf);

  if ($FORM{ATTACHMENT} =~ /(.+):(.+)/) {
    $FORM{TABLE}      = $1 . '_file';
    $FORM{ATTACHMENT} = $2;
  }

  $Attach->attachment_info(
    {
      ID    => $FORM{ATTACHMENT},
      TABLE => $FORM{TABLE},
      UID   => $user->{UID}
    }
  );

  if (! $Attach->{TOTAL}) {
    print "Content-Type: text/html\n\n";
    print "$lang{ERROR}: $lang{ATTACHMENT} $lang{NOT_EXIST}\n";
    return 0;
  }

  if($conf{ATTACH2FILE} && $Attach->{CONTENT} =~ /FILENAME: (.+)/) {
    my $filename = $1 || q{};
    $conf{ATTACH2FILE}="$conf{TPL_DIR}/attach/";
    $Attach->{CONTENT} = file_op({
        FILENAME => "$conf{ATTACH2FILE}/$filename",
        PATH     => "$conf{TPL_DIR}/attach/",
      });
  }

  print "Content-Type: $Attach->{CONTENT_TYPE}; filename=\"$Attach->{FILENAME}\"\n" . "Content-Disposition: attachment; filename=\"$Attach->{FILENAME};\" size=$Attach->{FILESIZE};" . "\n\n";
  print $Attach->{CONTENT};

  return 1;
}


1;
