=head1 NAME

   NAS managment functions

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Defs;
use Abills::Base qw(in_array convert int2ip ip2int ssh_cmd);
use Nas;

my %auth_types = (
  0  => 'DB',
  1  => 'System'
);

our $db;
our %lang;
our $base_dir;
our %permissions;
our @state_colors;
our Abills::HTML $html;
our Admins $admin;

my $Nas = Nas->new($db, \%conf, $admin);

#**********************************************************
=head2 form_nas() - Nas managment

=cut
#**********************************************************
sub form_nas {
  #my $Nas = Nas->new($db, \%conf, $admin);

  if ($FORM{NAS_ID}) {
    my $nas_id = $FORM{NAS_ID};
    $Nas->info({ NAS_ID => $nas_id });

    if(_error_show($Nas, { MESSAGE => "NAS_ID: $nas_id" })) {
      return 1;
    }

    $pages_qs .= "&NAS_ID=$nas_id&subf=". ($FORM{subf} || '');

    $LIST_PARAMS{NAS_ID} = $nas_id;
    my %F_ARGS = (NAS => $Nas);

    my @nas_menu = (
      $lang{INFO}  . "::NAS_ID=$nas_id",
      'IP Pools'   . ":63:NAS_ID=$nas_id",
      $lang{STATS} . ":64:NAS_ID=$nas_id",
      'RADIUS Test'. "::NAS_ID=$nas_id&radtest=1",
      'Console'    . "::NAS_ID=$nas_id&console=1&full=1",
    );

    #my $result;

    if ($FORM{ext_info}) {
      load_module('Equipment', $html);

      return 0;
    }
    elsif ($Nas->{NAS_TYPE} && $Nas->{NAS_TYPE} eq 'chillispot') {
      if (-f "../wrt_configure.cgi") {
        $ENV{HTTP_HOST} =~ s/\:(\d+)//g;
        $Nas->{EXTRA_PARAMS} = $html->tpl_show(
          templates('form_nas_configure'),
          {
            %$Nas,
            CONFIGURE_DATE => "wget -O /tmp/setup.sh http://$ENV{HTTP_HOST}/hotspot/wrt_configure.cgi?" . (($Nas->{DOMAIN_ID}) ? "DOMAIN_ID=$Nas->{DOMAIN_ID}\\\&" : '') . "NAS_ID=$Nas->{NAS_ID}; chmod 755 /tmp/setup.sh; /tmp/setup.sh",
            PARAM1         => "wget -O /tmp/setup.sh http://$ENV{HTTP_HOST}/hotspot/wrt_configure.cgi?DOMAIN_ID=$admin->{DOMAIN_ID}\\\&NAS_ID=$Nas->{NAS_ID}",
            PARAM2         => "; chmod 755 /tmp/setup.sh; /tmp/setup.sh",
          },
          { OUTPUT2RETURN => 1 }
        );
      }
      else {
        $html->message('info', $lang{INFO}, "Install wrt_configure.cgi ");
      }
    }
    elsif ($Nas->{NAS_TYPE} && $Nas->{NAS_TYPE} =~ /mikrotik/){
      push @nas_menu, "Hotspot::NAS_ID=$Nas->{NAS_ID}&mikrotik_hotspot=1";
    }

    $Nas->{CHANGED}  = "($lang{CHANGED}: $Nas->{CHANGED})";
    $Nas->{NAME_SEL} = $html->form_main(
      {
        CONTENT => $html->form_select(
          'NAS_ID',
          {
            SELECTED  => $FORM{NAS_ID},
            SEL_LIST  => $Nas->list({ %LIST_PARAMS, NAS_ID => undef, COLS_NAME => 1 }),
            SEL_KEY   => 'nas_id',
            SEL_VALUE => 'nas_name,nas_ip',
          }
        ),
        HIDDEN => {
          index => '62',
          AID   => $FORM{AID} || undef,
          subf  => $FORM{subf}
        },
        SUBMIT => { show => "$lang{SHOW}" },
        class   => 'navbar-form navbar-right',
      }
    );

    if (in_array('Equipment', \@MODULES)) {
      my $equpment_index = get_function_index('equipment_info');
      $Nas->{EQUIPMENT}  = $html->button($lang{EXTRA}, "index=$equpment_index&NAS_ID=$Nas->{NAS_ID}&ext_info=1", { class => 'btn btn-info btn-xs' });
      push @nas_menu, $lang{EXTRA}.':'.$equpment_index.":NAS_ID=$Nas->{NAS_ID}&ext_info=1::$equpment_index";
    }

    if (in_array('Snmputils', \@MODULES)) {
      load_module('Snmputils', $html);
      push @nas_menu, 'SNMP:' . (get_function_index('snmp_info_form')). ":NAS_ID=$Nas->{NAS_ID}&console=1&full=1";
    }

    func_menu(
      {
        $lang{NAME} => $Nas->{NAME_SEL}
      },
      \@nas_menu,
      { f_args => \%F_ARGS }
    );

    if ($FORM{subf}) {
      return 0;
    }
    elsif ($FORM{console}) {
      return form_nas_console($Nas);
    }
    elsif($FORM{radtest}) {
      return form_nas_test($Nas);
    }
    elsif($FORM{mikrotik_hotspot}) {
      return mikrotik_hotspot_configure($Nas);
    }

    elsif ($FORM{change} && $permissions{4} && $permissions{4}{2}) {
      if ($FORM{MAC} && $FORM{MAC} !~ /^[a-f0-9\-\.:]+$/i) {
        $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} MAC: '$FORM{MAC}'");
      }

      $Nas->change({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });
      if (!$Nas->{errno}) {
        $html->message('info', $lang{CHANGED}, "$lang{CHANGED} $Nas->{NAS_ID}");
        if($conf{RESTART_RADIUS}) {
          cmd($conf{RESTART_RADIUS});
        }
      }
    }

    $Nas->{LNG_ACTION} = $lang{CHANGE};
    $Nas->{ACTION}     = 'change';

    form_nas_add({ NAS => $Nas });
  }
  elsif ($FORM{add_form}) {
    $Nas->{ACTION}     = 'add';
    $Nas->{LNG_ACTION} = $lang{ADD};
    form_nas_add({ NAS => $Nas });
  }
  elsif($FORM{search_form}) {
    form_nas_search({ STANDART => 1 });
  }
  elsif ($FORM{add} && $permissions{4} && $permissions{4}{1}) {
    if ($FORM{MAC} && $FORM{MAC} !~ /^[a-f0-9\-\.:]+$/i) {
      $html->message('err', $lang{ERROR}, "$lang{ERR_WRONG_DATA} MAC: '$FORM{MAC}'");
    }
    elsif(! $FORM{NAS_NAME}) {
      $FORM{NAS_NAME} = 'NAS_'.$FORM{NAS_IP};
    }

    $Nas->add({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{ADDED} $lang{NAS}\n IP: '$FORM{IP}'\n $lang{NAME}: '$FORM{NAS_NAME}'\n".
          $html->button("$lang{MANAGE}", "index=$index&NAS_ID=$Nas->{INSERT_ID}", { BUTTON => 1 }) );
      #Restart Section
      if($conf{RESTART_RADIUS}) {
        cmd($conf{RESTART_RADIUS});
      }
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Nas->del($FORM{del});
    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED} [$FORM{del}]");
    }
  }
  elsif($FORM{wrt_configure}) {
    form_wrt_configure();
    return 0;
  }

  _error_show($Nas);

  my %info = ();
  my @rows = (
    "$lang{GROUPS}:",
    sel_nas_groups(),
    $html->form_input("1", "$lang{SHOW}", { TYPE => 'submit' })
  );

  foreach my $val ( @rows ) {
    $info{ROWS} .= $html->element('div', $val, { class => 'form-group' });
  }

  my $report_form = $html->element('div', $info{ROWS}, {
      class => 'navbar navbar-default form-inline'
    });

  my %equipment_filter = ();
  if (in_array('Equipment', \@MODULES)) {
    require Equipment;
    Equipment->import();
    my $Equipment = Equipment->new($db, $admin, \%conf);
    my $list = $Equipment->_list({ COLS_NAME => 1, PAGE_ROWS => 100000 });
    foreach my $line (@$list) {
      $equipment_filter{$line->{nas_id}}=$lang{YES};
    }
  }

  print $html->form_main(
      {
        CONTENT => $report_form,
        HIDDEN  => { index => "$index", },
        class   => 'form-inline'
      }
    );

  if($FORM{search}) {
    form_search({ CONTROL_FORM => 1 });
  }
  elsif($FORM{GID}) {
    $LIST_PARAMS{GID} = $FORM{GID};
    $LIST_PARAMS{PAGE_ROWS} = 1000;
  }

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} if ($admin->{DOMAIN_ID});
  $LIST_PARAMS{SHORT} = 1;

  my %status_hash = (
    0 => $lang{ENABLE},
    1 => $lang{DISABLE},
    2 => $lang{NOT_ACTIVE}
  );

  result_former({
      INPUT_DATA      => $Nas,
        FUNCTION        => 'list',
        BASE_FIELDS     => 0,
        DEFAULT_FIELDS  => 'NAS_ID,NAS_NAME,NAS_IDENTIFIER,NAS_IP,NAS_TYPE,DISABLE,DESCR',
        MAP             => (! $FORM{UID}) ? 1 : undef,
        MAP_FIELDS      => 'NAS_ID,NAS_NAME,NAS_IP',
        MAP_ICON        => 'nas',
        #      MAP_FILTERS     => { id => 'search_link:msgs_admin:UID,chg={ID}' },
        FUNCTION_FIELDS => ((in_array('Dhcphosts', \@MODULES)) ? 'dhcphosts_hosts:$lang{USERS}:nas_id:&VIEW=1&search=1&search_form=1,' : ''). 'form_ip_pools:IP_Pool:nas_id,form_nas:change:nas_id,'. ((($permissions{4} && $permissions{4}{3})) ? 'del' : ''),
        MULTISELECT     => (in_array('Equipment', \@MODULES)) ? 'NAS_ID:nas_id' : '',
        EXT_TITLES      => {
        nas_id           => 'ID',
        nas_name         => $lang{NAME},
        nas_identifier   => 'NAS-Identifier',
        nas_ip           => 'IP',
        nas_type         => $lang{TYPE},
        disable          => $lang{DISABLE},
        descr            => $lang{DESCRIBE},
        nas_group_name   => $lang{GROUP},
        domain_id        => 'DOMAIN_ID',
        alive            => 'Alive',
        mac              => 'MAC',
        mng_host_port    => 'MNG_HOST_PORT',
        mng_user         => 'MNG_USER',
        nas_mng_password => 'MNG_PASSWORD',
        number           => "$lang{NUM}",
        flors            => "$lang{ADDRESS} $lang{FLORS}",
        entrances        => "$lang{ADDRESS} $lang{ENTRANCES}",
        flats            => "$lang{ADDRESS} $lang{FLATS}",
        street_name      => "$lang{ADDRESS} $lang{STREETS}",
        #users_count      => "$lang{CONNECTED} $lang{USERS}",
        #users_connections=> "$lang{DENSITY_OF_CONNECTIONS}",
        added            => "$lang{ADDED}",
        location_id      => "LOCATION ID"
      },
        SKIP_USER_TITLE => 1,
        SELECT_VALUE    => {
        auth_type => \%auth_types,
        disable   => \%status_hash,
      },
        FILTER_COLS => {
        users_count => 'search_link:form_search:LOCATION_ID,type=11',
      },
        TABLE => {
        width      => '100%',
        caption    => $lang{NAS},
        qs         => $pages_qs,
        SHOW_FULL_LIST => 1,
        ID         => 'NAS_LIST',
        EXPORT     => 1,
        SELECT_ALL => (in_array('Equipment', \@MODULES)) ? "nas_list:NAS_ID:$lang{SELECT_ALL}" : '',
        MENU       => "$lang{ADD}:add_form=1&index=" . get_function_index('form_nas') . ':add' . ";$lang{SEARCH}:search_form=1&index=" . get_function_index('form_nas') . "&type=13:search"
      },
        MAKE_ROWS    => 1,
        TOTAL        => 1
    });

  return 1 ;
}

#**********************************************************
=head2 form_nas_add() - nas add

=cut
#**********************************************************
sub form_nas_add {
  #my ($attr) = @_;
  #my $Nas = $attr->{NAS};

  $Nas->{SEL_TYPE} = $html->form_select(
    'NAS_TYPE',
    {
      SELECTED => $Nas->{NAS_TYPE},
      SEL_HASH => nas_types_list(),
      SORT_KEY => 1
    }
  );

  $Nas->{SEL_NAS_MODEL} = $html->form_select(
    'NAS_MODEL',
    {
      SELECTED => $Nas->{NAS_MODEL},
      SEL_HASH => undef,
      SORT_KEY => 1
    }
  );

  $Nas->{SEL_AUTH_TYPE} = $html->form_select(
    'NAS_AUTH_TYPE',
    {
      SELECTED  => $Nas->{NAS_AUTH_TYPE},
      SEL_HASH  => \%auth_types,
    }
  );

  $Nas->{NAS_EXT_ACCT} = $html->form_select(
    'NAS_EXT_ACCT',
    {
      SELECTED     => $Nas->{NAS_EXT_ACCT},
      SEL_ARRAY    => [ '---', 'IPN' ],
      ARRAY_NUM_ID => 1
    }
  );

  $Nas->{NAS_DISABLE} = ($Nas->{NAS_DISABLE} && $Nas->{NAS_DISABLE} > 0) ? ' checked' : '';

  if ($conf{ADDRESS_REGISTER}) {
    $Nas->{ADDRESS_FORM} = $html->tpl_show(templates('form_address_sel'), $Nas, { OUTPUT2RETURN => 1, ID => 'form_address_sel' });
  }
  else {
    my $countries_hash;
    ($countries_hash, $Nas->{COUNTRY_SEL}) = sel_countries({ COUNTRY => $Nas->{COUNTRY} });

    $Nas->{ADDRESS_FORM} = $html->tpl_show(templates('form_address'), $Nas, { OUTPUT2RETURN => 1, ID => 'form_address' });
  }

  $Nas->{ADDRESS_FORM} = $html->tpl_show(templates('form_show_hide'),
    {
      CONTENT => $Nas->{ADDRESS_FORM},
      NAME    => $lang{ADDRESS},
      ID      => 'ADDRESS_FORM',
    },
    { OUTPUT2RETURN => 1 });

  $Nas->{NAS_GROUPS_SEL} = sel_nas_groups({ GID => $Nas->{GID} });

  if ($Nas->{NAS_ID}) {
    $Nas->{NAS_ID_FORM}=$html->tpl_show(templates('form_row'), { ID => "",
        NAME  => 'ID',
        VALUE => $html->b($Nas->{NAS_ID}) . $Nas->{CHANGED} }, { OUTPUT2RETURN => 1 });
  }

  $html->tpl_show(templates('form_nas'), $Nas, { ID => 'form_nas' });

  return 1;
}


#**********************************************************
=head2 form_nas_console($NAS, $attr)

=cut
#**********************************************************
sub form_nas_console {
  my ($Nas_) = @_;

  my $result;
  my $col_delimeter = '';

  if ($FORM{ACTION}) {
    $Nas_->{NAS_MNG_IP_PORT}= $FORM{NAS_MNG_IP_PORT} if ($FORM{NAS_MNG_IP_PORT});
    $Nas_->{NAS_MNG_USER}   = $FORM{NAS_MNG_USER} if ($FORM{NAS_MNG_USER});

    my $wait_char = ']';

    require Log;
    Log->import('log_print');
    my $Log = Log->new($db, \%conf);
    $Log->{PRINT}=1;
    require Abills::Nas::Control;
    Abills::Nas::Control->import( qw/telnet_cmd3 rsh_cmd/ );
    #my $Nas_cmd = Abills::Nas::Control->new($db, \%conf);

    if($FORM{CMD} =~ /^([a-z]+):(.+)/) {
      $FORM{TYPE}= $1;
      $FORM{CMD} = $2;
    }

    if ($Nas_->{NAS_TYPE} =~ /mpd|accel/ || $FORM{TYPE} eq 'telnet') {

      if($Nas_->{NAS_TYPE} =~ /accel/) {
        $wait_char = '#';
        $col_delimeter = '\||\+';
      }

      my ($nas_ip, $nas_rad_port, $nas_telnet_port)=split(/:/, $Nas_->{NAS_MNG_IP_PORT});

      if (! $nas_telnet_port) {
        $nas_telnet_port = $nas_rad_port || 23;
      }
      my @exec_cmd = ();

      if($Nas_->{NAS_MNG_USER}) {
        push  @exec_cmd, "sername\t$Nas_->{NAS_MNG_USER}";
      }

      if($Nas_->{NAS_MNG_PASSWORD}) {
        push  @exec_cmd, "assword\t$Nas_->{NAS_MNG_PASSWORD}";
      }

      push @exec_cmd, "$wait_char\t$FORM{CMD}", "$wait_char\texit";

      my $res = Abills::Nas::Control::telnet_cmd3("$nas_ip:$nas_telnet_port", \@exec_cmd,
        { debug => $FORM{DEBUG}, LOG => $Log } );

      $result = [ split(/\n/, $res) ];
    }
    elsif($FORM{TYPE} eq 'rsh') {
      $result = Abills::Nas::Control::rsh_cmd($FORM{CMD}, { DEBUG => $FORM{DEBUG} || undef, %$Nas_ });
    }
    else {
      $FORM{CMD} =~ s/\\\"/\"/g;
      $result = ssh_cmd($FORM{CMD}, { %$Nas_, DEBUG => 1 });
    }

    my $table = $html->table({
        width      => '500',
        caption    => "$lang{RESULT}: $FORM{CMD}",
        ID         => 'CONSOLE_RESULT',
        EXPORT     => 1,
      });

    my $total_rows = 0;

    if ($Nas_->{NAS_TYPE} =~ /mikrotik/ && $FORM{CMD} eq '/ip firewall address-list print'){
      $col_delimeter = '\s+';
      shift @{ $result };
      pop @{ $result };
    }

    if($FORM{CMD} =~ /^sh sss session$/) {
      $col_delimeter = '\s+';
    }

    foreach my $line (@{ $result }) {
      next if (! $line);
      my @row = ();
      #      if($Nas->{NAS_TYPE} =~ /mikrotik/ && $line =~ /^\s?(\d+)\s/) {
      #        $table->{rowcolor}='bg-success';
      #      }
      #      else {
      #        $table->{rowcolor}=undef;
      #      }

      if($col_delimeter) {
        @row = split(/$col_delimeter/, $line);
      }
      else {
        $line =~ s/\s/\&nbsp;/g;
        push @row, $html->color_mark($line, 'code');
      }

      our $IPV4;
      if($Nas_->{NAS_TYPE} =~ /mikrotik/ && $FORM{CMD} eq '/ip firewall address-list print' && $row[3] =~ /$IPV4/){
        $row[4] = $html->button("<span class='glyphicon glyphicon-remove'></span>", undef,
          {
            class     => 'btn btn-xs btn-danger removeIpBtn',
            ex_params => "data-address-number=$row[1]",
            SKIP_HREF => 1,
          }
        );
      }
      elsif($FORM{CMD} =~ /^sh sss session$/) {
        if($#row > 6) {
          next;
        }
        if ($row[0] !~ /^Current/) {
          push @row, $html->button($lang{SHOW}, "index=$index&console=1&NAS_ID=$FORM{NAS_ID}&full=1&CMD=rsh:sh sss session uid $row[0]&ACTION=1");
        }
      }

      $table->addrow(@row);
      $total_rows++;
    }

    print $table->show();

    $table = $html->table(
      {
        width      => '100%',
        cols_align => [ 'right', 'right' ],
        rows       => [ [ "$lang{TOTAL}:", $html->b($total_rows) ] ]
      }
    );

    print $table->show();
  }

  my @quick_cmd = ();
  if ($Nas_->{NAS_TYPE} eq 'mpd5') {
    @quick_cmd = ('show radsrv', 'show sessions');
  }
  elsif($Nas_->{NAS_TYPE} =~ /accel/) {
    @quick_cmd = ('show sessions');
  }
  elsif($Nas_->{NAS_TYPE} =~ /mikrotik/) {
    @quick_cmd = ('export compact', 'ip firewall nat print',
      'queue tree print', 'queue type print', 'queue simple print',
      '/ip firewall address-list print');
  }
  elsif($Nas_->{NAS_TYPE} =~ /cisco/) {
    @quick_cmd = ('rsh:show run', 'rsh:sh sss session', 'rsh:show log', 'rsh:show interf', 'rsh:show arp',
      'rsh:show radius statistics', 'show radius server-group all', 'rsh:sh ver');
  }

  foreach my $cmd (@quick_cmd) {
    $Nas_->{QUICK_CMD} .= $html->button($cmd, "index=$index&console=1&NAS_ID=$FORM{NAS_ID}&full=1&CMD=$cmd&ACTION=1", { BUTTON => 1 });
  }

  $Nas_->{TYPE_SEL} = $html->form_select('TYPE',
    {
      SELECTED   => $FORM{TYPE},
      SEL_ARRAY  => [ 'telnet', 'ssh', 'rsh' ]
    }
  );

  $html->tpl_show(templates('form_nas_console'), { %$Nas_, %FORM }, { ID => 'form_nas_console' });

  return 1;
}

#**********************************************************
=head2 form_nas_test()

=cut
#**********************************************************
sub form_nas_test {
  my Nas $Nas_ = shift;
  my ($attr) = @_;

#  if(! $Nas) {
#    $Nas = Nas->new($db, \%conf, $admin);
#  }

  my $comments;

  if ($FORM{runtest}) {
    my $ip    = $conf{RADIUS_TEST_IP} || '127.0.0.1';
    my $secret= $conf{RADIUS_TEST_SECRET} || 'secretpass';
    my ($mng_port, $second_port) = ('1812', '1812');

    my $request_type = 'ACCESS_REQUEST';

    if ($FORM{TYPE}) {
      if (!$Nas_->{NAS_MNG_IP_PORT}) {
        print "Radius Hangup failed. Can't find NAS IP and port. NAS: $Nas_->{NAS_ID}\n";
        return 'ERR:';
      }

      ($ip, $mng_port, $second_port) = split(/:/, $Nas_->{NAS_MNG_IP_PORT}, 3);
      $mng_port = 1700 if (!$mng_port);
      $request_type = $FORM{TYPE};
      $secret = $Nas_->{NAS_MNG_PASSWORD};
    }

    my $table = $html->table({
        width      => '100%',
        caption    => "RAD_REPLY $ip:$mng_port Secret: $Nas_->{NAS_MNG_PASSWORD}",
        title      => [ "KEY", "$lang{VALUE}" ],
        ID         => 'RAD_TEST_REPLY',
        class      => 'table',
        EXPORT     => 1,
      });

    my $type;
    require Radius;
    Radius->import();

    my $r = Radius->new(
      Host   => $ip,
      Secret => $secret,
      Debug  => $attr->{DEBUG} || 0
    ) or print $html->message('err', $lang{ERROR}, "Can't connect '$ip:$mng_port' $!");

    $conf{'dictionary'} = $base_dir . '/lib/dictionary' if (!$conf{'dictionary'});

    if (! $r->load_dictionary($conf{'dictionary'}) ) {
      $html->message('err', $lang{ERROR}, "Error load dictionary");
    }

    if($FORM{query_info}){
      my $q_info = $Nas_->query_info({ID => $FORM{query_info}});
      $FORM{RAD_REQUEST} = $q_info->{RAD_QUERY};
      $comments = $q_info->{COMMENTS};
    }

    my @pairs_arr = split(/[\r\n]/, $FORM{RAD_REQUEST});
    $FORM{RAD_REQUEST}='';
    $r->clear_attributes();

    foreach my $line (@pairs_arr) {
      my ($key, $val) = split(/=/, $line, 2);
      next if (! $key);
      $key =~ s/\s+//g;
      $val =~ s/^\s+//g;
      $val =~ s/\s+$//g;
      $val =~ s/^\\?\"//g;
      $val =~ s/\\?\"$//g;

      $r->add_attributes({ Name => $key, Value => $val });

      $table->addrow($key, $val);
      $FORM{RAD_REQUEST}.="$key = $val\n";
    }

    if ($FORM{RAD_REQUEST} !~ m/NAS-IP-Address/g ) {
      if (! $r->add_attributes({ Name => 'NAS-IP-Address', Value => $Nas_->{NAS_IP} }) ) {
        print "Error";
      }
      $table->addrow('NAS-IP-Address', $Nas_->{NAS_IP});
    }

    #    my $request_type = ($attr->{COA}) ? 'COA' : 'POD';
    #    if ($attr->{COA}) {
    #      $r->send_packet(COA_REQUEST) and $type = $r->recv_packet;
    #    }
    #    else {
    #      $r->send_packet(POD_REQUEST) and $type = $r->recv_packet;
    #    }

    $r->send_packet(1) and $type = $r->recv_packet;
    if (!defined $type) {
      # No responce from COA/POD server
      my $message = "No responce from $request_type server '$ip:$mng_port'";
      $html->message('err', $lang{ERROR}, "$message");
    }
    else {
      if($type == 3) {
        $table->{rowcolor}='bg-danger';
      }
      else {
        $table->{rowcolor}='bg-success';
      }

      $table->addrow("$lang{REPLY}", ($type == 3) ? 'ACCESS_REJECT' : 'ACCESS_ACCEPT' );

      for my $rad_attr ($r->get_attributes()) {
        $table->addrow($rad_attr->{'Name'}, $rad_attr->{'Value'});
      }
    }

    print $table->show();
  }

  if (! defined($FORM{RAD_REQUEST})) {
    $FORM{RAD_REQUEST} = 'User-Name=test';
  }

  print $html->tpl_show(templates('form_radtest'), { RAD_PAIRS => $FORM{RAD_REQUEST},
        COMMENTS  => $comments});

  if($FORM{SAVE}){
    $Nas_->add_radtest_query({
        COMMENTS   => $FORM{COMMENTS},
        RAD_QUERY  => $FORM{RAD_REQUEST},
        DATETIME   => 'NOW()'
      });
    if (!$Nas_->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }

  if($FORM{query_del}){
    $Nas_->del_query({ID => $FORM{query_del}});
    if ($Nas_->{errno}) {
      $html->message('err', "$lang{NOT} $lang{DELETE}", "$lang{ERROR}");
    }
  }

  my $query_list = $Nas_->query_list({COLS_NAME => 1});

  my $query_table = $html->table(
    {
      width   => '100%',
      caption => $lang{QUERY},
      title   => [ $lang{DATE}, $lang{COMMENTS}, $lang{QUERY} ],
      ID      => 'QUERY',
    }
  );

  foreach my $qr (@$query_list){
    $query_table->addrow(
      $qr->{datetime},
      $qr->{comments},
      $html->button("$lang{QUERY} $qr->{id}", "index=$index&NAS_ID=$FORM{NAS_ID}&radtest=1&query_info=$qr->{id}&runtest=1"),
      $html->button($lang{DEL}, "index=$index&NAS_ID=$FORM{NAS_ID}&radtest=1&query_del=$qr->{id}", { MESSAGE => "$lang{DEL} $qr->{id}?", class => 'del' })
    );
  }

  print $query_table->show();

  return 1;
}


#**********************************************************
=head2 form_wrt_configure($attr)

=cut
#**********************************************************
sub form_wrt_configure {

  #my $wrt_default = "$libpath/libexec/wrt_defaults.cfg.default";
  my $content     = '';

  if ($FORM{default}) {
    if (unlink("$conf{TPL_DIR}/wrt_defaults.cfg") == 1) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED}: '$conf{TPL_DIR}/wrt_defaults.cfg'");
    }
    else {
      $html->message('err', $lang{DELETED}, "$lang{ERROR} $!");
    }
  }
  elsif ($FORM{change}) {
    foreach my $key (sort { $a <=> $b } keys %FORM) {
      if ($key =~ /^\d+_wrt_/) {
        my $value = $FORM{$key};
        $key   =~ s/^\d+_wrt_//g;
        $key =~ s/(_\d+)//;
        $key = convert($key, { html2text => 1 });
        $value =~ s/\\\\/\\/g;
        $value =~ s/\\\"/\"/g;
        $value =~ s/\\\'/\'/g;
        #$value =~ s/&rsquo;/\\\'/g;
        $content .= qq{$key "$value"\n};
      }
    }

    file_op({ WRITE     => 1,
        FILENAME  => 'wrt_defaults.cfg',
        PATH      => $conf{TPL_DIR},
        CONTENT   => $content
      });
  }

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "WRT CONFIGURE",
      title      => [ "ID", "$lang{VALUE}", '-' ],
      cols_align => [ 'left', 'left', 'right', 'center:noprint' ],
      ID         => 'WRT_CONFIGURE',
      MENU       => "$lang{BACK}:NAS_ID=$FORM{nas}&index=$index:btn btn-xs btn-default"
    }
  );

  my $rows = file_op({ FILENAME => (-f "$conf{TPL_DIR}/wrt_defaults.cfg") ? 'wrt_defaults.cfg' : 'wrt_defaults.cfg.default',
      PATH     => (-f "$conf{TPL_DIR}/wrt_defaults.cfg") ? $conf{TPL_DIR} : '../../libexec/',
      ROWS     => 1
    });

  my %main_hash = ();
  my $i    = 0;

  foreach my $line (@$rows) {
    my ($key, $value)=split(/\s+/, $line, 2);
    $key  =~ s/^\"|\"$//g;
    $value=~ s/^\"|\"$//g;

    if ($key eq 'rc_startup') {
      $value = $html->form_textarea($i.'_'.'wrt_'.$key.(($main_hash{$key}) ? '_'.($main_hash{$key}+1) : '' ), $value);
    }
    else {
      $value = $html->form_input($i.'_'.'wrt_'.$key.(($main_hash{$key}) ? '_'.($main_hash{$key}+1) : '' ), $value);
    }

    $main_hash{$key}++;

    $table->addrow($key,
      $value
    );
    $i++;
  }

  print $html->form_main(
      {
        CONTENT => $table->show(),
        HIDDEN  => {
          index         => $index,
          nas           => $FORM{nas},
          wrt_configure => 1,
        },
        SUBMIT => { change => $lang{CHANGE},
          default=> $lang{DEFAULT}
        }
      }
    );

  return 1;
}

#**********************************************************
=head2 form_nas_groups()

=cut
#**********************************************************
sub form_nas_groups {

  #my $Nas = Nas->new($db, \%conf, $admin);
  $Nas->{ACTION}     = 'add';
  $Nas->{LNG_ACTION} = $lang{ADD};

  if ($FORM{add}) {
    $Nas->nas_group_add({ %FORM, DOMAIN_ID => $admin->{DOMAIN_ID} });
    if (!$Nas->{errno}) {
      $html->message('info', $lang{ADDED}, "$lang{ADDED}");
    }
  }
  elsif ($FORM{change}) {
    $Nas->nas_group_change({%FORM});
    if (!$Nas->{errno}) {
      $html->message('info', $lang{CHANGED}, "$lang{CHANGED} [$Nas->{ID}] $Nas->{NAME}");
    }
  }
  elsif ($FORM{chg}) {
    $Nas->nas_group_info({ ID => $FORM{chg} });

    $Nas->{ACTION}     = 'change';
    $Nas->{LNG_ACTION} = $lang{CHANGE};
    $FORM{add_form}    = 1;
  }
  elsif (defined($FORM{del}) && $FORM{COMMENTS}) {
    $Nas->nas_group_del($FORM{del});
    if (!$Nas->{errno}) {
      $html->message('info', $lang{DELETED}, "$lang{DELETED} $users->{GID}");
    }
  }

  _error_show($Nas, { MESSAGE => "$lang{NAS}" });

  $Nas->{DISABLE} = ($Nas->{DISABLE}) ? ' checked' : '';
  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID} if ($admin->{DOMAIN_ID});

  if ($FORM{add_form}) {
    $html->tpl_show(templates('form_nas_group'), $Nas);
  }

  result_former({
      INPUT_DATA      => $Nas,
        FUNCTION        => 'nas_group_list',
        DEFAULT_FIELDS  => 'COUNTS',
        BASE_FIELDS     => 4,
        FUNCTION_FIELDS => 'form_nas:$lang{NAS}:gid:&search=1,change,del',
        SKIP_USER_TITLE => 1,
        SELECT_VALUE  => {
        disable => { 0 => "$lang{ENABLE}:$state_colors[0]",
          1 => "$lang{DISABLE}:$state_colors[1]"
        },
      },
        EXT_TITLES      => {
        id 	     => '#',
        name 	   => $lang{NAME},
        comments => $lang{COMMENTS},
        disable  => $lang{STATUS},
        counts   => $lang{NASS}
      },
        TABLE           => {
        width      => '100%',
        caption    => "$lang{NAS} $lang{GROUPS}",
        qs         => $pages_qs,
        ID         => 'NAS_GROUPS',
        EXPORT     => 1,
        MENU       => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
      },
        MAKE_ROWS    => 1,
        SEARCH_FORMER=> 1,
        TOTAL        => 1
    });

  return 1;
}

#**********************************************************
=head2 form_ip_pools() - Manage ip pools

  Arguments:
    $attr

=cut
#**********************************************************
sub form_ip_pools {
  my ($attr) = @_;
#  my $Nas;
#
#  if (! $attr->{NAS}) {
#    $Nas = Nas->new($db, \%conf, $admin);
#  }

  if ($FORM{NAS_ID} && ! $FORM{subf}) {
    $FORM{subf} = $index;
    $index      = get_function_index('form_nas');
    form_nas();
    return 0;
  }

  if ($attr->{NAS}) {
    $Nas->{ACTION}     = 'add';
    $Nas->{LNG_ACTION} = "$lang{ADD}";
    $Nas = $attr->{NAS};
    $pages_qs = "&NAS_ID=$Nas->{NAS_ID}";
  }

  if ($FORM{BIT_MASK} && !$FORM{NAS_IP_COUNT}) {
    my $mask = 0b0000000000000000000000000000001;
    $FORM{COUNTS} = sprintf("%d", $mask << ($FORM{BIT_MASK} - 1)) - 3;
    my $netmask = int2ip(4294967296 - sprintf("%d", $mask << ($FORM{BIT_MASK}-1)));

    my @addrb=split(/\./,$FORM{NAS_IP_SIP});
    my ( $addrval ) = unpack( "N", pack( "C4",@addrb ) );

    my @maskb=split(/\./,$netmask);
    my ( $maskval ) = unpack( "N", pack( "C4",@maskb ) );

    # calculate network address
    my $netwval = ( $addrval & $maskval );

    # convert network address to IP address
    my @netwb=unpack( "C4", pack( "N",$netwval ) );
    $netwb[3]++;
    $FORM{NAS_IP_SIP}=join(".",@netwb);
  }

  if ($FORM{add}) {
    if ($FORM{POOL_SPEED} && !$FORM{BIT_MASK}) {
      $html->message('err', "$lang{ERROR}", "Select Mask");
    }
    else {
      $Nas->ip_pools_add({%FORM});
      if (!$Nas->{errno}) {
        $FORM{chg}=$Nas->{INSERT_ID} || 0;
        $html->message('info', $lang{INFO}, "$lang{ADDED} [$FORM{chg}]");
      }
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{POOL_SPEED} && !$FORM{BIT_MASK}) {
      $html->message('err', "$lang{ERROR}", "Select Mask");
    }
    else {
      $Nas->ip_pools_change(
        {
          %FORM,
          ID             => $FORM{chg},
          NAS_IP_SIP_INT => ip2int($FORM{NAS_IP_SIP})
        }
      );

      if (!$Nas->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{CHANGED}");
      }
    }
  }
  elsif ($FORM{chg}) {
    $Nas->ip_pools_info($FORM{chg});

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
      $Nas->{ACTION}     = 'change';
      $Nas->{LNG_ACTION} = "$lang{CHANGE}";
      $FORM{add_form}=1;
    }
  }
  elsif ($FORM{set}) {
    $Nas->nas_ip_pools_set({%FORM});

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    $Nas->ip_pools_del($FORM{del});

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{DELETED}");
    }
  }
  else {
    #$Nas = Nas->new($db, \%conf);
    $Nas->{ACTION}     = 'add';
    $Nas->{LNG_ACTION} = "$lang{ADD}";
  }

  if ($FORM{add_form}) {
    $Nas->{STATIC} = ' checked' if ($Nas->{STATIC});
    $Nas->{BIT_MASK} = $html->form_select(
      'BIT_MASK',
      {
        SELECTED     => $FORM{BIT_MASK},
        SEL_ARRAY    => [ '-----', 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16 ],
        ARRAY_NUM_ID => 1
      }
    );

    $Nas->{NEXT_POOL_ID_SEL} = $html->form_select(
      'NEXT_POOL_ID',
      {
        SELECTED      => $Nas->{NEXT_POOL_ID} || $FORM{NEXT_POLL_ID} ,
        SEL_LIST      => $Nas->nas_ip_pools_list({ PAGE_ROWS => 200, COLS_NAME => 1 }),
        SEL_KEY       => 'id',
        SEL_VALUE     => 'pool_name',
        NO_ID         => 1,
        MAIN_MENU     => get_function_index('form_ip_pools'),
        MAIN_MENU_AGRV=> "chg=". ($Nas->{NEXT_POOL_ID} || ''),
        SEL_OPTIONS   => { '--' => '' }
      }
    );
    $html->tpl_show(templates('form_ip_pools'), { %FORM, %$Nas, INDEX => 63 });
  }

  _error_show($Nas);

  my $list  = $Nas->nas_ip_pools_list({%LIST_PARAMS, COLS_NAME => 1 });
  my $table = $html->table(
    {
      width      => '100%',
      caption    => "NAS IP POOLs",
      title      => [ 'ID', "NAS", "$lang{NAME}", "$lang{BEGIN}", "$lang{END}", "$lang{COUNT}", "$lang{FREE}",  "$lang{PRIORITY}", "$lang{SPEED} (Kbits)", '-', '-' ],
      cols_align => [ 'right', 'left', 'right', 'right', 'right', 'right', 'center', 'center' ],
      qs         => $pages_qs,
      pages      => $Nas->{TOTAL},
      ID         => 'NAS_IP_POOLS',
      EXPORT     => 1,
      MENU       => "$lang{ADD}:index=63&add_form=1&$pages_qs:add",
    }
  );

  foreach my $line (@$list) {
    my $delete = $html->button($lang{DEL}, "index=". get_function_index('form_ip_pools') ."$pages_qs&del=$line->{id}", { MESSAGE => "$lang{DEL} POOL $line->{id}?", class => 'del' });
    my $change = $html->button($lang{CHANGE}, "index=". get_function_index('form_ip_pools') ."$pages_qs&chg=$line->{id}&add_form=1", { class => 'change' });
    $table->{rowcolor} = ($FORM{chg} && $line->{id} eq $FORM{chg}) ? 'active' : undef;

    $table->addrow(
      $html->b($line->{id}).' '.(($line->{static}) ? 'static' : $html->form_input('ids', $line->{id}, { TYPE => 'checkbox', STATE => ($line->{active_nas_id}) ? 'checked' : undef })),
      $html->button($line->{nas_name}, "index=". get_function_index('form_nas') ."&NAS_ID=$line->{active_nas_id}"),
      $line->{pool_name},
      $line->{first_ip},
      $line->{last_ip},
      $line->{ip_count},
      $line->{ip_free},
      $line->{priority},
      $line->{speed},
      $change,
      $delete);
  }

  print $html->form_main(
      {
        CONTENT => $table->show(),
        HIDDEN  => {
          index  => 63,
          NAS_ID => $FORM{NAS_ID} || '',
        },
        SUBMIT => { ($FORM{NAS_ID}) ? ( set => $lang{SET} ) : () }
      }
    );

  return 1;
}

#**********************************************************
=head2 form_nas_stats($attr)

=cut
#**********************************************************
sub form_nas_stats {
  my ($attr) = @_;

  if ($attr->{NAS}) {
    $Nas = $attr->{NAS};
  }
  elsif ($FORM{NAS_ID}) {
    $FORM{subf} = $index;
    form_nas();
    return 0;
  }
#  else {
#    $Nas = Nas->new($db, \%conf, $admin);
#  }

  require Dv_Sessions;
  Dv_Sessions->import();
  require Log;
  Log->import();
  my $Log = Log->new($db, \%conf);
  my $Dv_Sessions = Dv_Sessions->new($db, $admin, \%conf);

  my $last_session = $Log->log_list({COLS_NAME => 1,
      NAS_ID => $FORM{NAS_ID},
      SORT => 1,
      LOG_TYPE => 6,
      DESC => 'desc',
      PAGE_ROWS => 1});

  my $first_session = $Log->log_list({COLS_NAME => 1,
      NAS_ID => $FORM{NAS_ID},
      SORT => 1,
      LOG_TYPE => 6,
      PAGE_ROWS => 1});

  my $false_connect     = $Log->log_list({COLS_NAME => 1,
      NAS_ID => $FORM{NAS_ID},
      DATE => $FORM{DATE} || $DATE,
      LOG_TYPE => 4});

  my $success_connect   = $Log->log_list({COLS_NAME => 1,
      NAS_ID => $FORM{NAS_ID},
      DATE => $FORM{DATE} || $DATE,
      LOG_TYPE => 6});

  my $users_online = $Dv_Sessions->online({COLS_NAME=>1, NAS_ID => $FORM{NAS_ID}});

  my @users_succ_connect = [];
  my $success_conects = 0;

  if($Log->{TOTAL}){
    foreach my $user (@$success_connect){
      if(!(in_array($user->{user}, \@users_succ_connect))){
        $success_conects++;
        push(@users_succ_connect, $user->{user});
      }
    }
  }

  $html->tpl_show(templates('form_nas_stats'), {
      USERS_ONLINE           => $#{$users_online} + 1,
      DATE                   => $FORM{DATE}                 || $DATE,
      LAST_CONNECT           => $last_session->[0]->{date}  || 0,
      FIRST_CONNECT          => $first_session->[0]->{date} || 0,
      SUC_CONNECTS_PER_DAY   => $success_conects            || 0,
      SUC_ATTEMPTS_PER_DAY   => $#{$success_connect} + 1    || 0,
      FALSE_ATTEMPTS_PER_DAY => $#{$false_connect}   + 1    || 0,
      FUNC_INDEX             => get_function_index('dv_error'),
      LOG_WARN               => 4,
      LOG_INFO               => 6,
    });

  my $table = $html->table(
    {
      width      => '100%',
      caption    => "$lang{STATS}",
      title      => [ "NAS", "NAS_PORT", "$lang{SESSIONS}", "$lang{LAST_LOGIN}", "$lang{AVG}", "$lang{MIN}", "$lang{MAX}" ],
      cols_align => [ 'left', 'right', 'right', 'right', 'right', 'right', 'right' ],
      ID         => 'NAS_STATS',
    }
  );

  my $list = $Nas->stats({%LIST_PARAMS});

  foreach my $line (@$list) {
    $table->addrow($html->button($line->[0], "index=62&NAS_ID=$line->[7]"), $line->[1], $line->[2], $line->[3], $line->[4], $line->[5], $line->[6]);
  }

  print $table->show();

  return 1;
}

#**********************************************************
=head2 mikrotik_hotspot_configure($Nas)

  Arguments:
    $Nas - billing NAS object

  Returns:

=cut
#**********************************************************
sub mikrotik_hotspot_configure {
  my ($Nas_) = @_;

  require Abills::Nas::Mikrotik;

  my $show_result = sub { $html->message('info', shift) };

  my $mikrotik = Abills::Nas::Mikrotik->new( $Nas_, \%conf, {
      FROM_WEB => 1,
      MESSAGE_CALLBACK => $show_result
    });

  if (!$mikrotik){
    $html->message('err', $lang{ERR_WRONG_DATA}, "NAS_IP_PORT_MNG");
  }

  $html->message( "info", "Hotspot configure" );

  unless ( $mikrotik->has_access() ) {
    #
    #    # Trying to upload key
    #    if ($FORM{ADDRESS} && $FORM{ADDRESS} ne ''){
    #      cmd("$main::base_dir/misc/mikrotik/mikrotik_hotspot.pl IP_ADDRESS=$FORM{ADDRESS} UPLOAD_KEY=y");
    #
    #      $html->message("Uploaded key for 'abills_admin' to Mikrotik $FORM{ADDRESS}");
    #    }
    #    else {
    #
    my $wiki_mikrotik_ssh_access_link = $html->button($lang{HELP}, undef, {
        GLOBAL_URL => 'http://abills.net.ua/wiki/doku.php/abills:docs:nas:mikrotik:ssh',
        target => '_blank',
        BUTTON => 1
      });

    $html->message( 'warn', $lang{ERROR},
      "$lang{ERR_ACCESS_DENY} : " . $html->br() . "User: $Nas_->{NAS_MNG_USER}". $html->br() . $wiki_mikrotik_ssh_access_link );
    return 0;
  }

  my %default_arguments = (
    #    'INTERFACE'        => 'wlan0',
    'ADDRESS'          => '192.168.4.1',
    'NETWORK'          => '192.168.4.0',
    'NETMASK'          => '24',
    'MIKROTIK_GATEWAY' => '192.168.0.1',
    'DHCP_RANGE'       => '192.168.4.3-192.168.4.254',
    'MIKROTIK_DNS'     => '8.8.8.8',
    'HOTSPOT_DNS_NAME' => 'hotspot.abills.net'
  );

  if ( $FORM{action} ) {

    my @walled_garden_hosts = ();
    # Read walled garden hosts from FORM
    my $walled_garden_hosts_count = $FORM{WALLED_GARDEN_ENTRIES} || '';
    if ($walled_garden_hosts_count && $walled_garden_hosts_count =~ /^\d+$/){
      for (my $i = 0; $i < $walled_garden_hosts_count; $i++){
        push (@walled_garden_hosts, $FORM{"WALLED_GARDEN_$i"}) if ($FORM{"WALLED_GARDEN_$i"});
      }
    }

    my $result = $mikrotik->configure_hotspot({
        INTERFACE          => $FORM{INTERFACE},
        DHCP_RANGE         => $FORM{DHCP_RANGE},
        ADDRESS            => $FORM{ADDRESS},
        NETWORK            => $FORM{NETWORK},
        NETMASK            => $FORM{NETMASK},
        GATEWAY            => $FORM{GATEWAY},
        DNS                => $FORM{DNS},
        DNS_NAME           => $FORM{DNS_NAME},
        BILLING_IP_ADDRESS => $FORM{BILLING_IP_ADDRESS},
        RADIUS_SECRET      => $Nas_->{NAS_MNG_PASSWORD},
        WALLED_GARDEN      => \@walled_garden_hosts
      });

    if ($result){
      $html->message('info', $lang{SUCCESS});
    }

    return 1;
  }

  my $interfaces_list = $mikrotik->interfaces_list({ type => 'ether' });

  if (defined $interfaces_list && ref $interfaces_list eq 'ARRAY' && scalar @$interfaces_list == 0){
    $interfaces_list = [ { name => 'ether0'}, {name => 'ether1'}, {name => 'wlan0'}  ];
  }
  my $interface_select = $html->form_select('INTERFACE',{
      SELECTED  => $FORM{HOTSPOT_INTERFACE} || '',
      SEL_LIST  => $interfaces_list,
      SEL_KEY   => 'name',
      SEL_VALUE => 'name',
      NO_ID => 1
    });

  $html->tpl_show( templates( 'form_mikrotik_hotspot' ), { INTERFACE_SELECT => $interface_select, %default_arguments, %FORM } );

  return 1;
}

#**********************************************************
=head2 sel_nas_groups

=cut
#**********************************************************
sub sel_nas_groups {
  my ($attr) = @_;

#  my $Nas = Nas->new($db, \%conf);
  my $gid = $attr->{GID} || $FORM{GID} || '';

  my $GROUPS_SEL = $html->form_select(
    'GID',
    {
      SELECTED       => $gid,
      SEL_LIST       => $Nas->nas_group_list({ DOMAIN_ID => $admin->{DOMAIN_ID}, COLS_NAME => 1 }),
      SEL_OPTIONS    => { '' => '' },
      MAIN_MENU      => get_function_index('form_nas_groups'),
      MAIN_MENU_AGRV => "chg=$gid"
    }
  );

  return $GROUPS_SEL;
}

#**********************************************************
=head2 nas_types_list()

  List build in nas servers

  Extra server adding using $conf{nas_servers}

=cut
#**********************************************************
sub nas_types_list {

  my %nas_descr = (
    '3com_ss'    => "3COM SuperStack Switch",
    'nortel_bs'  => "Nortel Baystack Switch",
    'asterisk'   => "Asterisk",
    'usr'        => "USR Netserver 8/16",
    'pm25'       => 'LIVINGSTON portmaster 25',
    'ppp'        => 'FreeBSD ppp demon',
    'exppp'      => 'FreeBSD ppp demon with extended futures',
    'dslmax'     => 'ASCEND DSLMax',
    'celan'      => 'CeLAN Switch',
    'expppd'     => 'pppd deamon with extended futures',
    'edge_core'  => 'EdgeCore Switch',
    'eltex_smg'  => 'Eltex SMG',
    'radpppd'    => 'pppd version 2.3 patch level 5.radius.cbcp',
    'lucent_max' => 'Lucent MAX',
    'hp'         => 'HP Switch',
    'mac_auth'   => 'MAC auth',
    'mpd'        => 'MPD with kha0s patch',
    'mpd4'       => 'MPD 4.xx',
    'mpd5'       => 'MPD 5.xx',
    'ipcad'      => 'IP accounting daemon with Cisco-like ip accounting export',
    'lepppd'     => 'Linux PPPD IPv4 zone counters',
    'pppd'       => 'pppd + RADIUS plugin (Linux)',
    'pppd_coa'   => 'pppd + RADIUS plugin + radcoad (Linux)',
    'accel_ppp'  => 'Linux accel-ppp',
    'accel_ipoe' => 'Linux accel-ipoe',
    'gnugk'      => 'GNU GateKeeper',
    'cid_auth'   => 'Auth clients by CID',
    'cisco'      => 'Cisco',
    'cisco_voip' => 'Cisco Voip',
    'cisco_isg'  => 'Cisco ISG',
    'cisco_air'  => 'Cisco Aironets',
    'gpon'       => 'Huawei MA56**',
    'epon'       => 'BDCOM p3100',
    'dell'       => 'Dell Switch',
    'patton'     => 'Patton RAS 29xx',
    'bsr1000'    => 'CMTS Motorola BSR 1000',
    'mikrotik'   => 'Mikrotik (http://www.mikrotik.com)',
    'mikrotik_dhcp'   => 'Mikrotik DHCP service',
    'dlink_pb'   => 'Dlink IP-MAC-Port Binding',
    'other'      => 'Other nas server',
    'chillispot' => 'Chillispot (www.chillispot.org)',
    'openvpn'    => 'OpenVPN with RadiusPlugin',
    'vlan'       => 'Vlan managment',
    'qbridge'    => 'Q-BRIDGE',
    'dhcp'       => 'DHCP FreeRadius in DHCP mode',
    'ls_pap2t'   => 'Linksys pap2t',
    'ls_spa8000' => 'Linksys spa8000',
    'redback'    => 'Ericsson Smart Edge SE100 (Redback)',
    'mx80'       => 'Juniper MX80',
    'ipv6'       => 'ipv6',
    'unifi'      => 'Ubiquiti Unifi controler',
    'eltex'      => 'Eltex'
  );

  if ($conf{nas_servers}) {
    %nas_descr = (%nas_descr, %{ $conf{nas_servers} });
  }

  return \%nas_descr;
}

#**********************************************************
=head2 form_nas_search($attr)

=cut
#**********************************************************
sub form_nas_search {
  my ($attr) = @_;

  my $sub_template = '';
  my $results = 'No results yet';
  my $has_result_now = 0;

  if ( defined $FORM{NAS_SEARCH} && $FORM{NAS_SEARCH} == 0 ) {

    if ( $FORM{UID} ) {

      # Check for location_id on this user
      my $list = $users->list( {
          UID         => $FORM{UID},
          LOCATION_ID => '_SHOW',
          COLS_NAME   => 1
        } );

      if ( $users->{TOTAL} && $list->[0]->{build_id} ) {
        my $table_caption = " $list->[0]->{address_street}, $list->[0]->{address_build}";
        my $nases_list = $Nas->list( {
            %FORM,
            LOCATION_ID => $list->[0]->{build_id},
            COLS_NAME   => 1
          } );

        my $nases_table = form_nas_search_nas_table($nases_list, $table_caption);
        $results = $nases_table if (defined $nases_table);

        $has_result_now = defined $nases_table;
      }
    }
  }
  elsif ( defined $FORM{NAS_SEARCH} && $FORM{NAS_SEARCH} == 1 ) {
    my $nases_list = $Nas->list( {
        %FORM,
        COLS_NAME => 1
      } );
    print form_nas_search_nas_table($nases_list, '');
    return 1;
  }

  # Assembly search form
  $Nas->{SEL_TYPE} = $html->form_select(
    'NAS_TYPE',
    {
      SELECTED    => $Nas->{NAS_TYPE},
      SEL_HASH    => nas_types_list(),
      SEL_OPTIONS => { '' => $lang{ALL} },
      SORT_KEY    => 1
    }
  );
  $Nas->{NAS_GROUPS_SEL} = sel_nas_groups( { GID => $Nas->{GID} } );

  $sub_template = $html->tpl_show( templates( 'form_search_nas' ), {
      %{$Nas},
      POPUP      => ($attr->{STANDART}) ? '' : 1,
      SEARCH_BTN => ($attr->{STANDART}) ? $html->form_input( 'search', $lang{SEARCH}, { TYPE => 'submit' } ) : '',
    }, { OUTPUT2RETURN => 1 } );

  if ( $attr->{STANDART} ) {
    print $sub_template;
    return $sub_template;
  }
  else {
    return $html->tpl_show( templates( 'form_popup_window' ),
      {
        SUB_TEMPLATE     => $sub_template,
        RESULTS          => $results,
        OPEN_RESULT      => $has_result_now,
        CALLBACK_FN_NAME => ''
      } );
  }
}

sub form_nas_search_nas_table {
  my ($nases_list, $table_caption) = @_;

  return unless ($nases_list);
  $table_caption ||= '';

  my $result = '';

  my $table = $html->table(
    {
      width       => '100%',
      caption     => $lang{NAS} . ': ' . $table_caption,
      title_plain => [ 'ID', $lang{NAME}, 'IP', $lang{TYPE}, 'mac' ],
      cols_align  => [ 'left', 'right', 'center' ],
      pages       => scalar @{$nases_list},
      ID          => 'NAS_SEARCH'
    }
  );

  if ( $nases_list && scalar @{$nases_list} > 0 ) {
    foreach my $line ( @{$nases_list} ) {
      $table->addrow(
        $line->{nas_id},
        "<div class='clickSearchResult' name='$line->{nas_name}'>$line->{nas_name}</div>",
        $line->{nas_ip},
        $line->{nas_type},
        $line->{mac},
      );
    }

    $result = $table->show();
  }

  return $result;
}

1;
