=head1 NAME

  IP Pools Mng

=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(int2ip ip2int);
require Abills::Misc;

our (
  $db,
  %conf,
  %lang,
  $admin,
  $html,
  #%permissions,
  $index,
  %FORM,
  $pages_qs,
  #%LIST_PARAMS,
  $SELF_URL
);

use Nas;
my $Nas = Nas->new($db, \%conf, $admin);


#**********************************************************
=head2 form_ip_pools() - Manage ip pools

  Arguments:
    $attr
      NAS

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub form_ip_pools {
  my ($attr) = @_;

  if ($FORM{import}) {
    return ip_pools_import(\%FORM);
  }

  if ($FORM{NAS_ID} && !$FORM{subf}) {
    $FORM{subf} = $index;
    $index      = get_function_index('form_nas');
    require Control::Nas_mng;
    return ::form_nas();
  }

  $Nas->{ACTION}     = 'add';
  $Nas->{LNG_ACTION} = $lang{ADD};

  if ($attr->{NAS}) {
    $Nas               = $attr->{NAS};
    $pages_qs          = "&NAS_ID=$Nas->{NAS_ID}";
  }

  if ($FORM{subf}) {
    $pages_qs .= "&subf=$FORM{subf}";
  }

  ip_pools_preprocess(\%FORM);

  if ($FORM{add}) {
    if ($FORM{POOL_SPEED} && !$FORM{BIT_MASK}) {
      $html->message('err', $lang{ERROR}, "SELECT_MASK");
    }
    elsif($FORM{NAME} || $FORM{IP}) {
      $Nas->ip_pools_add({ %FORM, GATEWAY => ip2int($FORM{GATEWAY}) });
      if (!$Nas->{errno}) {
        $FORM{chg} = $Nas->{INSERT_ID} || 0;
        ip_pools_mkips({ %FORM, IP_POOL => $Nas->{INSERT_ID} });
        $html->message('info', $lang{INFO}, "$lang{ADDED} [$FORM{chg}]");
      }
    }
  }
  elsif ($FORM{change}) {
    if ($FORM{POOL_SPEED} && !$FORM{BIT_MASK}) {
      $html->message('err', $lang{ERROR}, "Select Mask");
    }
    else {
      $Nas->ip_pools_change({
        %FORM,
        ID             => $FORM{chg},
        NAS_IP_SIP_INT => ip2int($FORM{NAS_IP_SIP}),
        GATEWAY        => ip2int($FORM{GATEWAY}),
        NEXT_POOL_ID   => $FORM{NEXT_POOL_ID} ? $FORM{NEXT_POOL_ID} : 0,
      });

      if (!$Nas->{errno}) {
        ip_pools_mkips({ %FORM, IP_POOL => $FORM{chg} });
      }
    }
  }
  elsif ($FORM{chg}) {
    $Nas->ip_pools_info($FORM{chg});

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGING}");
      $Nas->{ACTION}  = 'change';
      $Nas->{GATEWAY} = int2ip($Nas->{GATEWAY});
      my $netmask_binary = sprintf('%032b', $Nas->{NETMASK});
      $Nas->{BIT_MASK}     = index($netmask_binary, '0');
      $Nas->{BIT_MASK_NUM} = 32 - $Nas->{BIT_MASK} + 1;
      $Nas->{LNG_ACTION}   = "$lang{CHANGE}";
      $FORM{add_form}      = 1;
    }
  }
  elsif ($FORM{set}) {
    my @arr_ids = ();
    if ($FORM{ids}) {
      @arr_ids = split(', ', $FORM{ids});
    }

    $FORM{ids} = join(', ', _uniq(@arr_ids));

    $Nas->nas_ip_pools_set(\%FORM);

    if (!$Nas->{errno}) {
      $html->message('info', $lang{INFO}, "$lang{CHANGED}");
    }
  }
  elsif ($FORM{del} && $FORM{COMMENTS}) {
    my $nas_ip_pool = $Nas->nas_ip_pools_list({
      ID                => $FORM{del},
      IP_COUNT          => '_SHOW',
      INTERNET_IP_FREE  => '_SHOW',
    });
    $nas_ip_pool = $nas_ip_pool->[0];

    my $ip_count = ($nas_ip_pool->{ip_count}) ? $nas_ip_pool->{ip_count} : 0;
    my $ip_free = ($nas_ip_pool->{internet_ip_free}) ? $nas_ip_pool->{internet_ip_free} : 0;

    if ($ip_count == $ip_free){
      $Nas->remove_ippools_ips({
        DEL => $FORM{del}
      });
      $Nas->ip_pools_del($FORM{del});
      if (!$Nas->{errno}) {
        $html->message('info', $lang{INFO}, "$lang{DELETED} ID=$FORM{del}");
      }
    }
    else {
      my $ip_busy = $ip_count - $ip_free;
      my $internet_users_index = get_function_index('internet_users_list');
      my $internet_quantity_users = $html->button($ip_busy, "index=$internet_users_index&IP_POOL_ID=$FORM{del}",{BUTTON => 2, target => '_blank'});
      $html->message('danger', "$lang{ERROR_DELETE} ID=$FORM{del}", "$lang{NUMBER_OF_USERS}: $internet_quantity_users");
    }
  }
  _error_show($Nas);

  if ($FORM{add_form}) {
    form_ip_pools_add(\%FORM);
  }

  form_ip_pools_list($attr);

  return 1;
}

#**********************************************************
=head2 ip_pools_preprocess($attr) - Manage ip pools

  Arguments:
    $attr

  Results:
    $attr

=cut
#**********************************************************
sub ip_pools_preprocess {
  my($attr)=@_;

  my @bit_masks = ('-----', 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16);
  my $mask = 0b0000000000000000000000000000001;

  if ($FORM{BIT_MASK}) {
    $FORM{NETMASK} = int2ip(4294967296 - sprintf("%d", $mask << (32 - $bit_masks[ $FORM{BIT_MASK} ])));
  }

  if ($FORM{BIT_MASK} && !$FORM{COUNTS}) {
    $FORM{COUNTS} = sprintf("%d", $mask << ($FORM{BIT_MASK} - 1)) - 2;
    my $netmask = int2ip(4294967296 - sprintf("%d", $mask << ($FORM{BIT_MASK} - 1)));

    my @addrb = split(/\./x, $FORM{NAS_IP_SIP} || '0.0.0.0');
    my ($addrval) = unpack("N", pack("C4", @addrb));

    my @maskb = split(/\./x, $netmask);
    my ($maskval) = unpack("N", pack("C4", @maskb));

    # calculate network address
    my $netwval = ($addrval & $maskval);

    # convert network address to IP address
    my @netwb = unpack("C4", pack("N", $netwval));
    $netwb[3]++;
    $FORM{NAS_IP_SIP} = join(".", @netwb);
  }

  return $attr;
}

#**********************************************************
=head2 form_ip_pools_list($attr) - Manage ip pools

  Arguments:
    $attr

  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub form_ip_pools_list {
  #my ($attr) = @_;

  my $list_next_pool = $Nas->nas_ip_pools_list({
    PAGE_ROWS => 500,
    POOL_NAME => '_SHOW',
  });

  $index = get_function_index('form_ip_pools');

  my %ext_titles = (
    id               => '#',
    nas_name         => 'NAS',
    pool_name        => $lang{NAME},
    first_ip         => $lang{BEGIN},
    last_ip          => $lang{END},
    ip_count         => $lang{COUNT},
    internet_ip_free => $lang{FREE},
    internet_dynamic_ip_free => "DYNAMIC $lang{FREE}",
    priority         => $lang{PRIORITY},
    speed            => "$lang{SPEED} (Kbits)",
    ip_skip          => $lang{IP_SKIP},
    netmask          => $lang{MASK},
    ipv6_prefix      => 'IPV6 ' . $lang{PREFIX},
    ipv6_net_mask    => 'IPV6 Net ' . $lang{MASK},
    ipv6_mask        => 'IPV6 User ' . $lang{MASK},
    ipv6_temp        => 'IPV6 ' . $lang{TEMPLATE},
    ipv6_pd          => 'IPV6 PD ' . $lang{PREFIX},
    ipv6_pd_net_mask => 'IPV6 PD Net ' . $lang{MASK},
    ipv6_pd_mask     => 'IPV6 PD User ' . $lang{MASK},
    ipv6_pd_temp     => 'IPV6 PD ' . $lang{TEMPLATE},
    guest            => $lang{GUEST},
    comments         => $lang{COMMENTS},
    static           => $lang{STATIC},
    dns              => 'DNS',
    vlan             => 'Vlan',
    next_pool        => $lang{NEXT_POOL},
    gateway          => $lang{DEFAULT_GATEWAY},
  );

  my %filter_values = (
    id        => sub {
      my ($id, $line) = @_;

      my $static = ($line->{static}) ? $html->badge('static',
        { TYPE => 'badge-secondary align-text-top' }) : '';

      my $select_checkbox = $html->form_input(
        'ids',
        $line->{id},
        {
          class   => 'checked_ippool_' . $line->{id},
          TYPE    => 'checkbox',
          FORM_ID => 'IP_POOLS_CHECKBOXES_FORM',
          STATE   => ($line->{active_nas_id}) ? 'checked' : undef
        }
      );

      my $checked_id = $id . '&nbsp;' . $select_checkbox . '&nbsp;' . $static;
      ($html && $html->{TYPE} && $html->{TYPE} eq 'html') ? $checked_id : $id;
    },
    pool_name => sub {
      my ($name, $line) = @_;

      my $internet_users_index = get_function_index('internet_users_list');
      my $users_button = $html->button($name,
        "index=$internet_users_index&IP_POOL=$line->{id}&search=1&search_form=1");

      return $line->{static} ? $users_button : $name;
    },
    nas_name  => sub {
      my ($name, $line) = @_;
      ($line->{nas_id} && $line->{active_nas_id})
        ? $html->button($name, "index=62&NAS_ID=$line->{active_nas_id}")
        : '';
    },
    netmask   => sub {
      my ($netmask) = @_;
      return int2ip($netmask);
    },
    guest     => sub {
      my ($guest) = @_;
      if ($guest) {
        return $html->element('label', '', { class => 'fa fa-check' });
      }
      else {
        return $html->element('label', '', { class => 'fa fa-times' });
      }
    },
    static    => sub {
      my ($static) = @_;
      if ($static) {
        return $html->element('label', '', { class => 'fa fa-check' });
      }
      else {
        return $html->element('label', '', { class => 'fa fa-times' });
      }
    },
    next_pool => sub {
      my ($next_pool) = @_;

      foreach my $pool_value (@$list_next_pool) {
        return $pool_value->{pool_name} if ($next_pool && $pool_value->{id} && $pool_value->{id} == $next_pool);
      }
    },
    gateway   => sub {
      my ($gateway) = @_;
      return int2ip($gateway);
    }
  );

  my Abills::HTML $pools_table;
  ($pools_table, undef) = result_former({
    INPUT_DATA      => $Nas,
    FUNCTION        => 'nas_ip_pools_list',
    DEFAULT_FIELDS  => 'ID,NAS_NAME,POOL_NAME,FIRST_IP,LAST_IP,IP_COUNT,' . (in_array('Internet', \@MODULES) ? 'INTERNET_IP_FREE,INTERNET_DYNAMIC_IP_FREE,' : 'IP_FREE'),
    HIDDEN_FIELDS   => 'STATIC,ACTIVE_NAS_ID,NAS',
    FUNCTION_FIELDS => 'change, del',
    SKIP_USER_TITLE => 1,
    EXT_TITLES      => \%ext_titles,
    FILTER_VALUES   => \%filter_values,
    TABLE           => {
      width          => '100%',
      caption        => "NAS IP POOLs",
      SHOW_FULL_LIST => 1,
      qs             => $pages_qs,
      ID             => 'NAS_IP_POOLS',
      EXPORT         => 1,
      IMPORT         => "$SELF_URL?get_index=form_ip_pools&import=1&header=2",
      MENU           => "$lang{ADD}:index=$index&add_form=1&$pages_qs:add",
    },
    MAKE_ROWS       => 1,
    SEARCH_FORMER   => 1,
    TOTAL           => 1,
    OUTPUT2RETURN   => 1
  });

  delete $FORM{show_columns};

  $html->tpl_show(templates('form_ippools_nas'), { TABLE_IPPOOLS => $pools_table, IDS => $FORM{ids} });

  print $html->form_main({
    ID     => 'IP_POOLS_CHECKBOXES_FORM',
    HIDDEN => {
      index  => get_function_index('form_ip_pools'),
      NAS_ID => $FORM{NAS_ID} || '',
    },
    SUBMIT => { ($FORM{NAS_ID}) ? (set => $lang{SET}) : () }
  });

  return 1;
}

#**********************************************************
=head2 form_ip_pools($attr) - Manage ip pools

  Arguments:
    $attr

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub form_ip_pools_add {
  my ($attr) = @_;

  $Nas->{STATIC} = ' checked' if ($Nas->{STATIC});
  $Nas->{GUEST}  = ' checked' if ($Nas->{GUEST});
  my @bit_masks = ('-----', 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16);

  $Nas->{BIT_MASK} = $html->form_select(
    'BIT_MASK',
    {
      SELECTED => $Nas->{BIT_MASK_NUM} || $attr->{BIT_MASK} || 9,    # 24,
      SEL_ARRAY    => \@bit_masks,
      ARRAY_NUM_ID => 1
    }
  );

  my $list_next_pool = $Nas->nas_ip_pools_list({
    PAGE_ROWS => 500,
    POOL_NAME => '_SHOW',
  });

  $Nas->{NEXT_POOL_ID_SEL} = $html->form_select(
    'NEXT_POOL_ID',
    {
      SELECTED  => $Nas->{NEXT_POOL_ID} || $attr->{NEXT_POLL_ID} || 0,
      SEL_LIST  => $list_next_pool,
      SEL_KEY   => 'id',
      SEL_VALUE => 'pool_name',
      NO_ID     => 1,
      MAIN_MENU => get_function_index('form_ip_pools'),
      MAIN_MENU_ARGV => "chg=" . ($Nas->{NEXT_POOL_ID} || ''),
      SEL_OPTIONS => { '--' => '' }
    }
  );

  $Nas->{IPV6_BIT_MASK} = $html->form_select(
    'IPV6_MASK',
    {
      SELECTED     => $Nas->{IPV6_MASK} || $attr->{IPV6_MASK} || 64,
      SEL_ARRAY    => [ 32..128  ]
    }
  );

  $Nas->{IPV6_NET_BIT_MASK} = $html->form_select(
    'IPV6_NET_MASK',
    {
      SELECTED     => $Nas->{IPV6_NET_MASK} || $attr->{IPV6_NET_MASK} || 64,
      SEL_ARRAY    => [ 32..128  ]
    }
  );

  $Nas->{IPV6_PD_BIT_MASK} = $html->form_select(
    'IPV6_PD_MASK',
    {
      SELECTED     => $Nas->{IPV6_PD_MASK} || $attr->{IPV6_PD_MASK} || 64,
      SEL_ARRAY    => [ 32..128  ]
    }
  );

  $Nas->{IPV6_PD_NET_BIT_MASK} = $html->form_select(
    'IPV6_PD_NET_MASK',
    {
      SELECTED     => $Nas->{IPV6_PD_NET_MASK} || $attr->{IPV6_PD_NET_MASK} || 64,
      SEL_ARRAY    => [ 32..128  ]
    }
  );

  if ($Nas->{IP} && ! $attr->{chg}) {
    $Nas->{IP}=join('.', (split(/\./x, int2ip($Nas->{IP})))[0..2] ) .'.'.'2';
  }

  $html->tpl_show(templates('form_ip_pools'), {
    %{$attr},
    %{$Nas},
    INDEX         => 63
  });

  return 1;
}


#**********************************************************
=head2 ip_pools_import($attr)

  Arguments:
    $attr

  Return:

=cut
#**********************************************************
sub ip_pools_import {
  my ($attr)=@_;

  if ($attr->{add}) {
    my $import_info = import_former( $attr );
    my $total = $#{ $import_info } + 1;

    my $ip_list = $Nas->ip_pools_list({ COLS_NAME => 1 });

    my %ippools_hash = map { $_->{ip} => $_->{id} } @{$ip_list};

    if ($import_info) {
      import_ip($import_info, %ippools_hash);
    }

    $html->message( 'info', $lang{INFO},
      "$lang{ADDED}\n $lang{FILE}: $attr->{UPLOAD_FILE}{filename}\n Size: $attr->{UPLOAD_FILE}{Size}\n Count: $total" );
    return 1;
  }

  $html->tpl_show(templates('form_import'), {
    IMPORT_FIELDS     => 'IP',
    CALLBACK_FUNC     => 'form_ip_pools',
  });

  return 1;
}

#**********************************************************
=head2 import_ip($import_info, %ippools_hash)

  Arguments:
    import_info   - import ip pools
    ippools_hash  - ip pools in system

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub import_ip {
  my ($import_info, %ippools_hash) = @_;

  foreach my $ip_import (@$import_info) {
    if ($ip_import) {
      add_ip_import($ip_import, %ippools_hash);
    }
  }

  return 1;
}

#**********************************************************
=head2 add_ip_import($attr)

  Arguments:
    ip_tmp  - ip push in system
    ip_hash - hash ip pools in system

  Return:
    -

=cut
#**********************************************************
sub add_ip_import {
  my ($ip_tmp, %ip_hash) = @_;
  my @bit_masks = (32, 31, 30, 29, 28, 27, 26, 25, 24,
    23, 22, 21, 20, 19, 18, 17, 16);

  my @ip_and_mask;

  if (ref($ip_tmp) eq 'HASH' && $ip_tmp->{IP}) {
    $ip_tmp->{IP} =~ s/,//gx;
    if ($ip_tmp->{IP} =~ /\//xm) {
      @ip_and_mask = split(/\//x, $ip_tmp->{IP});
    }
    else {
      push @ip_and_mask, $ip_tmp->{IP};
    }
  }
  else {
    if ($ip_tmp =~ /\//xm) {
      @ip_and_mask = split(/\//x, $ip_tmp);
    }
    else {
      push @ip_and_mask, $ip_tmp;
    }
  }

  unless ($ip_hash{ $ip_and_mask[0] }) {

    my %mask_hash = map{ $_ => $_ } @bit_masks;

    my $mask = 0b0000000000000000000000000000001;
    my $mask_network = int2ip(4294967296 - sprintf("%d", $mask << (32 - $mask_hash{ $ip_and_mask[1] || 24 } ) ) );
    my $count_ip = sprintf("%d", $mask << (32 - $ip_and_mask[1])) - 2;

    $Nas->ip_pools_add({
      IP        => $ip_and_mask[0],
      NETMASK   => $mask_network,
      COUNTS    => $count_ip,
      NAME      => "Ippools: " . $ip_and_mask[0]
    });
  }

  return 1;
}

#**********************************************************
=head2 _uniq() -

  Arguments:
    -
  Return:
    -

=cut
#**********************************************************
sub _uniq {
  my %seen;
  grep { !$seen{$_}++ } @_;
}

#**********************************************************
=head2 ip_pools_mkips($attr) -

  Arguments:
    $attr
      IP_POOL

  Return:
    TRUE or FALSE

=cut
#**********************************************************
sub ip_pools_mkips {
  my ($attr)=@_;

  my $ip_pool = $attr->{IP_POOL};

  $Nas->remove_ippools_ips({
    POOL_ID => "$ip_pool"
  });

  if ($attr->{STATIC}) {
    return 1;
  }

  $Nas->divide_ips({
    FIRST   => ip2int($attr->{IP}),
    COUNT   => $attr->{COUNTS},
    POOL_ID => $ip_pool
  });

  $html->message('info', $lang{INFO}, $lang{CHANGED});

  if ($attr->{IP_SKIP}) {
    my @arr_ip_skip = split(/,\s?|;\s?/x, $attr->{IP_SKIP});
    foreach my $element_ip (@arr_ip_skip) {
      $Nas->remove_ippools_ips({
        IPPOOL_ID => $ip_pool,
        IP        => ip2int($element_ip)
      });
    }
  }

  return 1;
}

1;