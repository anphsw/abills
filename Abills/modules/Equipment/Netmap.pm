use strict;
use warnings FATAL => 'all';
use Abills::Base qw(_bp load_pmodule int2ip json_former);
use Internet;
use Users;

our Equipment $Equipment;

our (
  $db,
  $html,
  %conf,
  %lang,
  $admin,
);

my $Internet = Internet->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

#********************************************************
=head2 network_map($attr)

=cut
#********************************************************
sub network_map {

  my %nodes = ();
  my @edges = ();

  my $nas_list = $Equipment->_list({
    NAS_IP      => '_SHOW',
    NAS_NAME    => '_SHOW',
    NAS_ID      => '_SHOW',
    STATUS      => '_SHOW',
    PORTS       => '_SHOW',
    TYPE_ID     => '_SHOW',
    VENDOR_NAME => '_SHOW',
    MODEL_NAME  => '_SHOW',
    PAGE_ROWS   => 9999,
    COLS_NAME   => 1
  });
  _error_show($Equipment);

  foreach my $line (@$nas_list) {
    my $online = $Internet->user_list({
      NAS_ID    => $line->{nas_id},
      ONLINE    => '_SHOW',
      COLS_NAME => 1
    });

    $nodes{$line->{nas_id}} = {
      data => {
        label   => ($line->{nas_name} || '') . " ($line->{nas_id})",
        ip      => $line->{nas_ip},
        state   => $line->{status},
        ports   => $line->{ports},
        type_id => $line->{type_id},
        vendor  => $line->{vendor_name},
        model   => $line->{model_name},
        online  => $online->[0]->{online},
        nas_id  => $line->{nas_id}
      },
    };

    my $uplink_ports = $Equipment->port_list({
      NAS_ID    => $line->{nas_id},
      UPLINK    => '!0',
      PORT      => '_SHOW',
      COLS_NAME => 1
    });
    _error_show($Equipment);

    if ($uplink_ports && ref $uplink_ports eq 'ARRAY') {
      foreach (@$uplink_ports) {
        $Equipment->_info($_->{uplink});
        if (!$Equipment->{TOTAL}) {
          next;
        }

        push @edges, { source => $_->{uplink}, target => $line->{nas_id}, name => $_->{port} };
      }
    }
  }

  my $positions = $Equipment->equipment_netmap_positions_list({
    COORDX    => '_SHOW',
    COORDY    => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 65000
  });
  foreach my $position (@{$positions}) {
    my $nas_id = $position->{nas_id};
    next if !$nas_id || !$nodes{$nas_id};

    $nodes{$nas_id}{data}{position} = { 'x' => $position->{coordx}, 'y' => $position->{coordy} };
  }

  my %rec_hash = (nodes => \%nodes, edges => \@edges);

  my $types_hash = {};
  my $types = $Equipment->type_list({ COLS_NAME => 1 });
  map $types_hash->{$_->{id}} = { NAME => $_->{name}, MODELS => [] }, @{$types};

  my $models = $Equipment->model_list({ TYPE_ID => '_SHOW', COLS_NAME => 1, PAGE_ROWS => 10000 });
  foreach my $model (@{$models}) {
    next if !$model->{type_id} || !$types_hash->{$model->{type_id}};

    push @{$types_hash->{$model->{type_id}}{MODELS}}, {
      ID   => $model->{id},
      NAME => join(' : ', ($model->{vendor_name} || '', $model->{model_name} || ''))
    };
  }

  my $json_string = json_former(\%rec_hash);

  my $status_hash = json_former({
    0 => $lang{ENABLE},
    1 => $lang{DISABLE},
    2 => $lang{NOT_ACTIVE},
    3 => $lang{ERROR},
    4 => $lang{BREAKING}
  });

  $html->tpl_show(_include('equipment_netmap', 'Equipment'), {
    TYPES            => json_former($types_hash),
    EQUIPMENT_ADD_FORM => equipment_add_form({ RETURN_ADD_FORM => 1 }),
    DATA             => $json_string,
    STATUS_LANG_HASH => $status_hash
  });

  return 1;
}

#********************************************************
=head2 user_route($attr)

=cut
#********************************************************
sub user_route {
  my ($attr) = @_;
  $attr //= {};
  my $user_uid = $attr->{UID} || $FORM{UID} || return '';

  my $user_info = $Users->info($user_uid);
  my $intenet_info = $Internet->user_list({
    UID => $user_uid,
    IP  => '_SHOW',
    NAS_ID => '_SHOW',
    COLS_NAME => 1
  });
  my %nodes = ();
  my %edges = ();

  if($intenet_info->[0]->{nas_id}) {
    my $user_node = $Equipment->port_list({
      NAS_ID    => $intenet_info->[0]->{nas_id},
      UPLINK    => '_SHOW',
      STATUS    => '_SHOW',
      COLS_NAME => 1
    });
    _error_show($Equipment);

    unless ($Equipment->{TOTAL} > 0) {
      $html->message('err', $lang{ERROR}, "user is not assigned to any port");
      return 1;
    };
    my $user_nas = $user_node->[0]->{nas_id} || 0;
    my $user_login = $user_info->{LOGIN};
    my $current_nas = $user_node->[0]->{nas_id};
    $nodes{0} = {
      'name'    => $user_login,
      'type_id' => 0,
      'state'   => $user_node->[0]->{status},
      'ip'      => int2ip($intenet_info->[0]->{ip_num})
    };
    $edges{0} = { target => 0, name => $user_node->[0]->{uplink}, source => $user_nas };

    while (42) {
      my $nas_info = $Equipment->_list({
        NAS_ID      => $current_nas,
        NAS_IP      => '_SHOW',
        NAS_NAME    => '_SHOW',
        STATUS      => '_SHOW',
        PORTS       => '_SHOW',
        TYPE_ID     => '_SHOW',
        VENDOR_NAME => '_SHOW',
        MODEL_NAME  => '_SHOW',
        PAGE_ROWS   => 9999,
        COLS_NAME   => 1
      });

      unless ($Equipment->{TOTAL} > 0) {
        $html->message('err', $lang{ERROR}, "NAS_NOT_FOUND");
        return 1;
      }

      if ($nas_info->[0] && $nodes{$nas_info->[0]->{nas_id}}) {
        last;
      }

      if ($nas_info->[0]->{nas_id}) {
        my $online = $Internet->user_list({
          NAS_ID    => $nas_info->[0]->{nas_id},
          ONLINE    => '_SHOW',
          COLS_NAME => 1
        });

        $nodes{$nas_info->[0]->{nas_id}} = {
          'name'    => ($nas_info->[0]->{nas_name} || '') . " ($nas_info->[0]->{nas_id})",
          'ip'      => $nas_info->[0]->{nas_ip},
          'state'   => $nas_info->[0]->{status},
          'ports'   => $nas_info->[0]->{ports},
          'type_id' => $nas_info->[0]->{type_id},
          'vendor'  => $nas_info->[0]->{vendor_name},
          'model'   => $nas_info->[0]->{model_name},
          'online'  => $online->[0]->{online},
        };
      }
      my $uplink_port = $Equipment->port_list({
        NAS_ID    => $current_nas,
        UPLINK    => '!0',
        PORT      => '_SHOW',
        COLS_NAME => 1
      });

      if ($Equipment->{TOTAL} < 1) {
        last;
      }

      if ($current_nas && $uplink_port->[0] && $uplink_port->[0]->{uplink}) {
        $edges{$current_nas} = { source => $uplink_port->[0]->{uplink}, target => $current_nas, name => $uplink_port->[0]->{port} };
      }

      $current_nas = $uplink_port->[0]->{uplink};
    }
  }

  my %rec_hash = ('nodes' => \%nodes, 'edges' => \%edges);

  # _bp('asd', \%rec_hash);

  load_pmodule('JSON');
  JSON->import();
  my $json_string = JSON::to_json(\%rec_hash);
  my $status_hash = JSON::to_json({
    0 => $lang{ENABLE},
    1 => $lang{DISABLE},
    2 => $lang{NOT_ACTIVE},
    3 => $lang{ERROR},
    4 => $lang{BREAKING}
  });

  $html->tpl_show(_include('equipment_netmap', 'Equipment'), {
    DATA             => $json_string,
    STATUS_LANG_HASH => $status_hash
  });

  return 1;
}

1;