package Iptv;

# Iptv  managment functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

use Tariffs;
use Users;
use Fees;

my $MODULE = 'Iptv';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};

  bless($self, $class);
  $self->{db}=$db;

  return $self;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  if (defined($attr->{LOGIN})) {
    use Users;
    my $users = Users->new($self->{db}, $admin, $CONF);
    $users->info(0, { LOGIN => "$attr->{LOGIN}" });
    if ($users->{errno}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
      return $self;
    }

    $uid                      = $users->{UID};
    $self->{DEPOSIT}          = $users->{DEPOSIT};
    $self->{ACCOUNT_ACTIVATE} = $users->{ACTIVATE};
    $WHERE                    = "WHERE service.uid='$uid'";
  }

  $WHERE = "WHERE service.uid='$uid'";

  $self->query2("SELECT service.uid, 
   tp.name AS tp_name, 
   tp.tp_id, 
   service.filter_id, 
   service.cid,
   service.disable AS status,
   service.pin,
   service.vod,
   tp.gid AS tp_gid,
   tp.month_fee,
   tp.day_fee,
   tp.postpaid_monthly_fee,
   tp.payment_type,
   tp.period_alignment,
   tp.id AS tp_num,
   service.dvcrypt_id,
   service.expire AS iptv_expire
     FROM iptv_main service
     LEFT JOIN tarif_plans tp ON (service.tp_id=tp.tp_id)
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  my %DATA = (
    TP_ID          => 0,
    SIMULTANEONSLY => 0,
    STATUS         => 0,
    IP             => '0.0.0.0',
    NETMASK        => '255.255.255.255',
    SPEED          => 0,
    FILTER_ID      => '',
    CID            => '',
    CALLBACK       => 0,
    PORT           => 0,
    PIN            => '',
    DVCRYPT_ID     => '',
    
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => defaults() });

  if ($DATA{TP_ID} > 0 && !$DATA{STATUS}) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);
    $self->{TP_INFO} = $tariffs->info($DATA{TP_ID});

    $self->{TP_NUM}  = $tariffs->{ID};

    #Take activation price
    if ($tariffs->{ACTIV_PRICE} > 0) {
      my $user = Users->new($self->{db}, $admin, $CONF);
      $user->info($DATA{UID});

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });
      $tariffs->{ACTIV_PRICE} = 0;
    }
  }

  $self->query_add('iptv_main', { %$attr,
  	                              REGISTRATION => 'now()',
  	                              EXPIRE       => $attr->{IPTV_EXPIRE} 
  	                             });

  return $self if ($self->{errno});
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{EXPIRE}     = $attr->{IPTV_EXPIRE};
  $attr->{VOD}        = (!defined($attr->{VOD})) ? 0 : 1;
  $attr->{DISABLE}    = $attr->{STATUS};
  my $old_info        = $self->user_info($attr->{UID});
  $self->{OLD_STATUS} = $old_info->{STATUS};


  if ($attr->{TP_ID} && $old_info->{TP_ID} != $attr->{TP_ID}) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);

    $tariffs->info($old_info->{TP_ID});
    %{ $self->{TP_INFO_OLD} } = %{ $tariffs };
    $self->{TP_INFO} = $tariffs->info($attr->{TP_ID});
    my $user = Users->new($self->{db}, $admin, $CONF);

    $user->info($attr->{UID});
    if ($old_info->{STATUS} == 2 && (defined($attr->{STATUS}) && $attr->{STATUS} == 0) && $tariffs->{ACTIV_PRICE} > 0) {
      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{ACTIV_PRICE} && $tariffs->{PAYMENT_TYPE} == 0 && $tariffs->{POSTPAID_FEE} == 0) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{ACTIV_PRICE}, { DESCRIBE => "ACTIV TP" });

      $tariffs->{ACTIV_PRICE} = 0;
    }
    elsif ($tariffs->{CHANGE_PRICE} > 0) {

      if ($user->{DEPOSIT} + $user->{CREDIT} < $tariffs->{CHANGE_PRICE}) {
        $self->{errno} = 15;
        return $self;
      }

      my $fees = Fees->new($self->{db}, $admin, $CONF);
      $fees->take($user, $tariffs->{CHANGE_PRICE}, { DESCRIBE => "CHANGE TP" });
    }

    if ($tariffs->{AGE} > 0) {
      my $user = Users->new($self->{db}, $admin, $CONF);
      use POSIX qw(strftime);
      my $EXPITE_DATE = strftime("%Y-%m-%d", localtime(time + 86400 * $tariffs->{AGE}));
      $attr->{EXPIRE} = $EXPITE_DATE;
    }
  }
  elsif ($old_info->{STATUS} == 2 && $attr->{STATUS} == 0) {
    my $tariffs = Tariffs->new($self->{db}, $CONF, $admin);
    $self->{TP_INFO} = $tariffs->info($old_info->{TP_ID});
  }

  $attr->{JOIN_SERVICE} = ($attr->{JOIN_SERVICE}) ? $attr->{JOIN_SERVICE} : 0;

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'iptv_main',
#      FIELDS       => \%FIELDS,
#      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  $self->user_info($attr->{UID});
  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE from iptv_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES     = ("u.uid = service.uid");
  my $EXT_TABLE       = '';
  $self->{EXT_TABLES} = '';

  my $WHERE =  $self->search_former($attr, [
      ['FIO',            'STR', 'pi.fio',                           1 ],
      ['TP_NAME',        'STR', 'tp.name AS tp_name',               1 ],
      ['SERVICE_STATUS', 'INT', 'service.disable AS iptv_status',   1 ],
      ['CID',            'STR', 'service.cid',                      1 ],
      ['COMMENTS',       'STR', 'service.comments',                 1 ],
      ['ALL_FILTER_ID',  'STR', 'if(service.filter_id<>\'\', service.filter_id, tp.filter_id) AS filter_id', 1 ],
      ['FILTER_ID',      'STR', 'service.filter_id',                1 ],
      ['DVCRYPT_ID',     'INT', 'service.dvcrypt_id',               1 ],
      ['TP_ID',          'INT', 'service.tp_id',                    1 ],
      ['TP_CREDIT',      'INT', 'tp.credit:',             'tp_credit' ],
      ['PAYMENT_TYPE',   'INT', 'tp.payment_type',                  1 ],
      ['MONTH_PRICE',    'INT', 'ti_c.month_price',                 1 ],
      ['IPTV_EXPIRE',    'DATE','service.expire as iptv_expire',    1 ],
    ],
    { WHERE             => 1,
    	WHERE_RULES       => \@WHERE_RULES,
    	USERS_FIELDS      => 1,
    	SKIP_USERS_FIELDS => [ 'FIO' ]
    }
    );

  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});
  if ($attr->{SHOW_CONNECTIONS}) {
    $EXT_TABLE = "LEFT JOIN dhcphosts_hosts dhcp ON (dhcp.uid=u.uid)
                  LEFT JOIN nas  ON (nas.id=dhcp.nas)";

    $self->{SEARCH_FIELDS} = "nas.ip AS nas_ip, dhcp.ports, nas.nas_type, nas.mng_user, DECODE(nas.mng_password, '$CONF->{secretkey}') AS mng_password,";
    $self->{SEARCH_FIELDS_COUNT} += 5;
  }

  my $list;
  if ($attr->{SHOW_CHANNELS}) {
    $self->query2("SELECT  u.id AS login, 
        $self->{SEARCH_FIELDS}
        u.uid, 
        service.tp_id, 
        ti_c.channel_id, 
        c.num AS channel_num,
        c.name AS channel_name,
        ti_c.month_price
   from intervals i

     INNER JOIN iptv_ti_channels ti_c ON (i.id=ti_c.interval_id)
     INNER JOIN iptv_users_channels uc ON (ti_c.channel_id=uc.channel_id)
     INNER JOIN iptv_channels c ON (uc.channel_id=c.id)

     INNER JOIN users u ON (u.uid=uc.uid)
     INNER JOIN iptv_main service ON (u.uid = service.uid )

     INNER JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
     $EXT_TABLE
  $WHERE 
GROUP BY uc.uid, channel_id
ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    $list = $self->{list};
  }
  else {
    $self->query2("SELECT u.id AS login, 
      $self->{SEARCH_FIELDS}
      u.uid
     FROM (users u, iptv_main service)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id) 
     $EXT_TABLE
     $WHERE 
     GROUP BY u.uid
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
     undef,
     $attr
    );

    return $self if ($self->{errno});

    $list = $self->{list};

    if ($self->{TOTAL} >= 0) {
      $self->query2("SELECT count(u.id) AS total FROM (users u, iptv_main service) $WHERE", undef, { INFO => 1 });
    }
  }
  return $list;
}

#**********************************************************
# User information
# info()
#**********************************************************
sub user_tp_channels_list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();

  #DIsable
  if (defined($attr->{STATUS})) {
    push @WHERE_RULES, "service.disable='$attr->{STATUS}'";
  }

  if (defined($attr->{LOGIN_STATUS})) {
    push @WHERE_RULES, "u.disable='$attr->{LOGIN_STATUS}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $list = $self->{list};
  return $self if ($self->{errno});

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(u.id) AS total FROM (users u, iptv_main service) $WHERE", undef, { INFO => 1 });
  }

  return $self->{list};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub channel_info {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = "WHERE id='$attr->{ID}'";

  $self->query2("SELECT id,
   name,
   num AS number,
   port,
   comments AS describe,
   disable
     FROM iptv_channels
   $WHERE;",
   undef,
   { INFO => 1 }
  );


  return $self;
}

#**********************************************************
#
#**********************************************************
sub channel_defaults {
  my $self = shift;

  my %DATA = (
    ID       => 0,
    NAME     => '',
    NUMBER   => 0,
    PORT     => 0,
    DESCRIBE => '',
    DISABLE  => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub channel_add {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => channel_defaults() });

  $self->query2("INSERT INTO iptv_channels (name,
   num,
   port,
   comments,
   disable
             )
        VALUES (
   '$DATA{NAME}', 
   '$DATA{NUMBER}', 
   '$DATA{PORT}', 
   '$DATA{DESCRIBE}',
   '$DATA{DISABLE}'
       );", 'do'
  );

  return $self if ($self->{errno});

  $admin->system_action_add("CH:$DATA{NUMBER}", { TYPE => 1 });
  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub channel_add_stalker {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr, { default => channel_defaults() });

  $self->query2("INSERT INTO $CONF->{IPTV_STALKET_DB}.itv (name,
   num,
   port,
   comments,
   disable
             )
        VALUES (
   '$DATA{NAME}', 
   '$DATA{NUMBER}', 
   '$DATA{PORT}', 
   '$DATA{DESCRIBE}',
   '$DATA{DISABLE}'
         );", 'do'
  );

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub channel_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ID       => 'id',
    NAME     => 'name',
    NUMBER   => 'num',
    PORT     => 'port',
    DESCRIBE => 'comments',
    DISABLE  => 'disable'

  );

  my $old_info = $self->channel_info({ ID => $attr->{ID} });

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'iptv_channels',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $old_info,
      DATA         => $attr
    }
  );

  return $self if ($self->{errno});

  $self->channel_info({ ID => $attr->{ID} });

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub channel_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE from iptv_channels WHERE id='$id';", 'do');

  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub channel_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
        [ 'DISABLE',      'INT',  'disable'  ],
        [ 'PORT',         'INT',  'port'     ],
        [ 'DESCRIBE',     'STR',  'comments' ],
        [ 'NUMBER',       'INT',  'number'   ],
        [ 'NAME',         'STR',  'name'     ],
    ],
    { 
    	WHERE       => 1,
    }    
    );

  $self->query2("SELECT num, name,   comments, port,
   disable, id
     FROM iptv_channels
     $WHERE 
     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(*) AS total FROM iptv_channels $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub tp_defaults {
  my $self = shift;

  my %DATA = (
    ID       => 0,
    NAME     => '',
    NUMBER   => 0,
    PORT     => 0,
    DESCRIBE => '',
    DISABLE  => 0
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_channels {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $self->query2("DELETE FROM iptv_users_channels WHERE uid='$DATA{UID}'", 'do'),

  my @ids = split(/, /, $attr->{IDS});

  foreach my $id (@ids) {
    $self->query2("INSERT INTO iptv_users_channels 
     ( uid, tp_id, channel_id, changed)
        VALUES ( '$DATA{UID}',  '$DATA{TP_ID}', '$id', now());", 'do'
    );
  }

  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub user_channels_list {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT uid, tp_id, channel_id, changed FROM iptv_users_channels 
     WHERE tp_id='$attr->{TP_ID}' and uid='$attr->{UID}';",
     undef,
     $attr
  );

  $self->{USER_CHANNELS} = $self->{TOTAL};
  return $self->{list};
}

#**********************************************************
# add()
#**********************************************************
sub channel_ti_change {
  my $self = shift;
  my ($attr) = @_;

  my %DATA = $self->get_data($attr);

  $self->query2("DELETE FROM iptv_ti_channels WHERE interval_id='$attr->{INTERVAL_ID}'", 'do'),

  my @ids = split(/, /, $attr->{IDS});

  foreach my $id (@ids) {
    $self->query2("INSERT INTO iptv_ti_channels 
     ( interval_id, channel_id, month_price, day_price, mandatory)
        VALUES ( '$DATA{INTERVAL_ID}',  '$id', '" . $DATA{ 'MONTH_PRICE_' . $id } . "', 
        '" . $DATA{ 'DAY_PRICE_' . $id } . "', '" . $DATA{ 'MANDATORY_' . $id } . "');", 'do'
    );
  }

  return $self if ($self->{errno});

  #$admin->action_add("$DATA{UID}", "ACTIVE");
  return $self;
}

#**********************************************************
# list()
#**********************************************************
sub channel_ti_list {
  my $self   = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
        [ 'DISABLE',      'INT',  'disable'  ],
        [ 'PORT',         'INT',  'port'     ],
        [ 'DESCRIBE',     'STR',  'comments' ],
        [ 'NUMBER',       'INT',  'number'   ],
        [ 'NAME',         'STR',  'name'     ],
        [ 'IDS',          'INT',  'c.id'     ],
        [ 'ID',           'INT',  'c.id'     ],        
        [ 'USER_INTERVAL_ID', 'INT',  'ic.interval_id' ],
        [ 'MANDATORY',    'STR',  'ic.mandatory'   ],                        
    ],
    { 
    	WHERE       => 1,
    }    
    );

  $self->query2("SELECT if (ic.channel_id IS NULL, 0, 1) AS interval_channel_id,
   c.num AS channel_num,
   c.name,
   c.comments,
   ic.month_price,
   ic.day_price,
   ic.mandatory,
   c.port,
   c.disable, 
   c.id AS channel_id
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (id=ic.channel_id and ic.interval_id='$attr->{INTERVAL_ID}')
     $WHERE
     ORDER BY $SORT $DESC ;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(*) AS total, sum(if (ic.channel_id IS NULL, 0, 1)) AS active 
     FROM iptv_channels c
     LEFT JOIN iptv_ti_channels ic ON (c.id=ic.channel_id and ic.interval_id='$attr->{INTERVAL_ID}')
     $WHERE
    ",
    undef,
    { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub reports_channels_use {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $sql = "SELECT c.num,  c.name, count(uc.uid), sum(if(if(company.id IS NULL, b.deposit, cb.deposit)>0, 0, 1))
FROM iptv_channels c
LEFT JOIN iptv_users_channels uc ON (c.id=uc.channel_id)
LEFT JOIN users u ON (uc.uid=u.uid)
LEFT JOIN bills b ON (u.bill_id = b.id)
LEFT JOIN companies company ON  (u.company_id=company.id) 
LEFT JOIN bills cb ON  (company.bill_id=cb.id)
GROUP BY c.id
ORDER BY $SORT $DESC ";

  #  $sql = "select c.num, c.name, count(*), c.id
  #FROM iptv_channels c
  #LEFT JOIN iptv_ti_channels ic  ON (c.id=ic.channel_id)
  #LEFT JOIN intervals i ON (ic.interval_id=i.id)
  #LEFT JOIN tarif_plans tp ON (tp.tp_id=i.tp_id)
  #LEFT JOIN iptv_main u ON (tp.tp_id=u.tp_id)
  #group BY c.id
  #     ORDER BY $SORT $DESC ;";

  $self->query2($sql);

  return $self if ($self->{errno});

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Add channel to stalker middleware
#**********************************************************
sub stalker_channel_add {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr);

  for (keys %DATA){
    if ($DATA{$_} eq 'on'){
      $DATA{$_} = 1; 
    }
  }
    
    if($DATA{STATUS} == 1) {
      $DATA{STATUS} = 0;  
    }
    else {
      $DATA{STATUS} = 1;  
    }

$self->query2("INSERT INTO $CONF->{IPTV_STALKET_DB}.itv(
  name,
  number,
  use_http_tmp_link,
  wowza_tmp_link,
  wowza_dvr,
  censored,
  base_ch,
  bonus_ch,
  hd,
  cost,
  cmd, 
  mc_cmd,
  enable_wowza_load_balancing,
  enable_tv_archive,
  enable_monitoring,
  monitoring_url,
  descr,
  tv_genre_id, 
  status,
  xmltv_id,
  service_id,
  volume_correction,
  correct_time
)    
VALUES 
(
  '$DATA{NAME}', 
  '$DATA{NUMBER}', 
  '$DATA{USE_HTTP_TMP_LINK}', 
  '$DATA{WOWZA_TMP_LINK}',
  '$DATA{WOWZA_DVR}', 
  '$DATA{CENSORED}', 
  '$DATA{BASE_CH}', 
  '$DATA{BONUS_CH}', 
  '$DATA{HD}',
  '$DATA{COST}', 
  '$DATA{CMD}', 
  '$DATA{MC_CMD}', 
  '$DATA{ENABLE_WOWZA_LOAD_BALANCING}', 
  '$DATA{ENABLE_TV_ARCHIVE}',
  '$DATA{ENABLE_MONITORING}', 
  '$DATA{MONITORING_URL}', 
  '$DATA{DESCR}', 
  '$DATA{TV_GENRE_ID}', 
  '$DATA{STATUS}',
  '$DATA{XMLTV_ID}', 
  '$DATA{SERVICE_ID}', 
  '$DATA{VOLUME_CORRECTION}',
  '$DATA{CORRECT_TIME}' 
);", 'do'                                                       
);
  return 0;  
}

#**********************************************************
# Delete channel from stalker DB
#**********************************************************
sub stalker_channel_del {
  my $self = shift;
  my ($attr) = @_;
  
  %DATA = $self->get_data($attr);

  $self->query2("DELETE from $CONF->{IPTV_STALKET_DB}.itv WHERE name LIKE '$DATA{STALKER_NAME}';", 'do');
  $self->query2("DELETE from iptv_channels WHERE id='$DATA{ABILLS_ID}';", 'do');
  return $self->{result};  

}

#**********************************************************
# Stalker channel list
#**********************************************************
sub stalker_channel_list {
  my $self = shift;
  my ($attr) = @_;
  
  my @WHERE_RULES  = ();
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  
  if(defined($attr->{ID})) {
      push @WHERE_RULES, "id='$attr->{ID}'";
  }
  if(defined($attr->{NAME})) {
      push @WHERE_RULES, "name LIKE '$attr->{NAME}'";
  }    
  if(defined($attr->{NUMBER})) {
      push @WHERE_RULES, "number LIKE '$attr->{NUMBER}'";
  }  
 
  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
 
  $self->query2("SELECT
      name,
      number,
      use_http_tmp_link,
      wowza_tmp_link,
      wowza_dvr,
      censored,
      base_ch,
      bonus_ch,
      hd,
      cost,
      cmd, 
      mc_cmd,
      enable_wowza_load_balancing,
      enable_tv_archive,
      enable_monitoring,
      monitoring_url,
      descr,
      tv_genre_id, 
      status,
      xmltv_id,
      service_id,
      volume_correction,
      correct_time
    FROM $CONF->{IPTV_STALKET_DB}.itv
    $WHERE
    ORDER BY $SORT $DESC;");
  return $self->{list};
}

#**********************************************************
# Stalker channel info
#**********************************************************
sub stalker_channel_info {
  my $self = shift;
  my ($attr) = @_;
 
   %DATA = $self->get_data($attr); 

  $self->query2("SELECT
      name,
      number,
      use_http_tmp_link,
      wowza_tmp_link,
      wowza_dvr,
      censored,
      base_ch,
      bonus_ch,
      hd,
      cost,
      cmd, 
      mc_cmd,
      enable_wowza_load_balancing,
      enable_tv_archive,
      enable_monitoring,
      monitoring_url,
      descr,
      tv_genre_id, 
      status,
      xmltv_id,
      service_id,
      volume_correction,
      correct_time,
      name,
      number
    FROM $CONF->{IPTV_STALKET_DB}.itv
    WHERE name LIKE '$attr->{NAME}';");

  ( $self->{NAME},
    $self->{NUMBER},
    $self->{USE_HTTP_TMP_LINK},
    $self->{WOWZA_TMP_LINK},
    $self->{WOWZA_DVR},
    $self->{CENSORED},
    $self->{BASE_CH},
    $self->{BONUS_CH},
    $self->{HD},
    $self->{COST},
    $self->{CMD},
    $self->{MC_CMD},
    $self->{ENABLE_WOWZA_LOAD_BALANCING},
    $self->{ENABLE_TV_ARCHIVE},
    $self->{ENABLE_MONITORING},
    $self->{MONITORING_URL},
    $self->{DESCR},
    $self->{TV_GENRE_ID_SELECT},
    $self->{STATUS},
    $self->{XMLTV_ID},
    $self->{SERVICE_ID},
    $self->{VOLUME_CORRECTION},
    $self->{CORRECT_TIME},
    $self->{CHANGE_PARAM},
    $self->{OLD_NUMBER}    
  )= @{ $self->{list}->[0] };

  return $self;  
}


#**********************************************************
# Stalker change channels
#**********************************************************
sub stalker_change_channels {
  my $self = shift;
  my ($attr) = @_; 

  %DATA = $self->get_data($attr);

  for (keys %DATA){
    if ($DATA{$_} eq 'on'){
      $DATA{$_} = 1; 
    }
  }

  if($DATA{STATUS} == 1) {
    $DATA{STATUS} = 0;  
  }
  else {
    $DATA{STATUS} = 1;  
  }

$self->query2( 
  "UPDATE $CONF->{IPTV_STALKET_DB}.itv SET
    name                        = '$DATA{NAME}',
    number                      = '$DATA{NUMBER}',
    use_http_tmp_link           = '$DATA{USE_HTTP_TMP_LINK}',
    wowza_tmp_link              = '$DATA{WOWZA_TMP_LINK}',
    wowza_dvr                   = '$DATA{WOWZA_DVR}',
    censored                    = '$DATA{CENSORED}',
    base_ch                     = '$DATA{BASE_CH}',
    bonus_ch                    = '$DATA{BONUS_CH}',
    hd                          = '$DATA{HD}',
    cost                        = '$DATA{COST}',
    cmd                         = '$DATA{CMD}', 
    mc_cmd                      = '$DATA{MC_CMD}',
    enable_wowza_load_balancing = '$DATA{ENABLE_WOWZA_LOAD_BALANCING}',
    enable_tv_archive           = '$DATA{ENABLE_TV_ARCHIVE}',
    enable_monitoring           = '$DATA{ENABLE_MONITORING}',
    monitoring_url              = '$DATA{MONITORING_URL}',
    descr                       = '$DATA{DESCR}',
    tv_genre_id                 = '$DATA{TV_GENRE_ID}', 
    status                      = '$DATA{STATUS}',
    xmltv_id                    = '$DATA{XMLTV_ID}',
    service_id                  = '$DATA{SERVICE_ID}',
    volume_correction           = '$DATA{VOLUME_CORRECTION}',
    correct_time                = '$DATA{CORRECT_TIME}'
  WHERE name LIKE '$DATA{CHANGE_PARAM}';", 'do'                                                       
);
  return $self;
}


#**********************************************************
# online()
#**********************************************************
sub online {
  my $self = shift;
  my ($attr) = @_;

  
  my $EXT_TABLE = '';
  $admin->{DOMAIN_ID} = 0 if (!$admin->{DOMAIN_ID});
  if ($attr->{COUNT}) {
    my $WHERE     = '';
    if ($attr->{ZAPED}) {
      $WHERE = 'WHERE c.status=2';
    }
    else {
      $WHERE = 'WHERE ((c.status=1 or c.status>=3) AND c.status<11)';
    }

    $self->query2("SELECT  count(*) AS total FROM iptv_calls c $WHERE;", undef, { INFO => 1 });
    return $self;
  }

  my $port_id          = 0;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @WHERE_RULES = ();

  if ($attr->{ZAPED}) {
    push @WHERE_RULES, "c.status=2";
  }
  elsif ($attr->{ALL}) {

  }
  elsif ($attr->{STATUS}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{STATUS}", 'INT', 'c.status') };
  }
  else {
    push @WHERE_RULES, "((c.status=1 or c.status>=3) AND c.status<11)";
  }

  if ($attr->{FILTER}) {
  	$attr->{$attr->{FILTER_FIELD}} = $attr->{FILTER};
  }

   my $WHERE =  $self->search_former($attr, [
      ['LOGIN',           'STR',  'u.id AS login',                                  ],
      ['FIO',             'STR',  'pi.fio',                                       1 ],
      ['STARTED',         'DATE', 'if(date_format(c.started, "%Y-%m-%d")=curdate(), date_format(c.started, "%H:%i:%s"), c.started) AS started', 1],
      ['NAS_PORT_ID',     'INT', 'c.nas_port_id',                                 1 ],
      ['CLIENT_IP_NUM',   'INT', 'c.framed_ip_address',    'c.framed_ip_address AS ip_num' ],
      ['DURATION',        'INT', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started))', 'SEC_TO_TIME(UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started)) AS duration' ],
      ['CID',             'STR', 'c.CID',                                         1 ],
      ['DV_CID',          'STR', 'service.cid',                                   1 ],
      ['NETMASK',         'IP',  'service.netmask',        'INET_NTOA(service.netmask) AS netmask'],
      ['TP_ID',           'INT', 'service.tp_id',                                 1 ],
      ['CALLS_TP_ID',     'INT', 'c.tp_id AS calls_tp_id',                        1 ],
      ['CONNECT_INFO',    'STR', 'c.CONNECT_INFO',                                1 ],
      ['SPEED',           'INT', 'service.speed',                                 1 ],
      ['SUM',             'INT', 'c.sum AS session_sum',                          1 ],
      ['STATUS',          'INT', 'c.status',                                      1 ],
#    ['ADDRESS_FULL',    '' ($CONF->{ADDRESS_REGISTER}) ? 'concat(streets.name,\' \', builds.number, \'/\', pi.address_flat) AS ADDRESS' : 'concat(pi.address_street,\' \', pi.address_build,\'/\', pi.address_flat) AS ADDRESS',
      ['GID',              'INT', 'u.gid',                                        1 ],
      ['TURBO_MODE',       'INT', 'c.turbo_mode',                                 1 ],
      ['JOIN_SERVICE',     'INT', 'c.join_service',                               1 ],
      ['PHONE',            'STR', 'pi.phone',                                     1 ],
      ['CLIENT_IP',        'IP',  'c.framed_ip_address',    'INET_NTOA(c.framed_ip_address) AS ip' ],
      ['UID',              'INT', 'u.uid',                                        1 ],
      ['NAS_IP',           'IP',  'nas_ip',                 'INET_NTOA(c.nas_ip_address) AS nas_ip'],
      ['DEPOSIT',          'INT', 'if(company.name IS NULL, b.deposit, cb.deposit) AS deposit',     1],
      ['CREDIT',           'INT', 'if(u.company_id=0, u.credit, if (u.credit=0, company.credit, u.credit)) AS credit', 1 ],
      ['ACCT_SESSION_TIME','INT', 'UNIX_TIMESTAMP() - UNIX_TIMESTAMP(c.started) AS acct_session_time',1 ],
      ['DURATION_SEC',     'INT', 'if(c.lupdated>0, c.lupdated - UNIX_TIMESTAMP(c.started), 0) AS duration_sec', 1 ],
      ['FILTER_ID',        'STR', 'if(service.filter_id<>\'\', service.filter_id, tp.filter_id) AS filter_id',  1 ],
      ['SESSION_START',    'INT', 'UNIX_TIMESTAMP(started) AS started_unixtime',  1 ],
      ['DISABLE',          'INT', 'u.disable AS login_status',                    1 ],
      ['DV_STATUS',        'INT', 'service.disable AS service_status',            1 ],

      ['TP_NAME',          'STR', 'tp.name AS tp_name',                           1 ],
      ['TP_BILLS_PRIORITY','INT', 'tp.bills_priority',                            1 ],
      ['TP_CREDIT',        'INT', 'tp.credit AS tp_credit',                       1 ],
      ['NAS_NAME',         'STR', 'nas.name',                                     1 ],
      ['PAYMENT_METHOD',   'INT', 'tp.payment_type',                              1 ],
      ['EXPIRED',          'DATE',"if(u.expire>'0000-00-00' AND u.expire <= curdate(), 1, 0) AS expired", 1 ],
      ['EXPIRE',           'DATE','u.expire',                                     1 ],

      ['IP',                'IP',  'service.ip',          'INET_NTOA(service.ip) AS ip' ],
      ['NETMASK',           'IP',  'service.netmask',     'INET_NTOA(service.netmask) AS netmask' ],
      ['SIMULTANEONSLY',    'INT', 'service.logins',                              1 ],
      ['PORT',              'INT', 'service.port',                                1 ],
      ['FILTER_ID',         'STR', 'service.filter_id',                           1 ],
      ['STATUS',            'INT', 'service.disable',                             1 ],
      ['IPTV_EXPIRE',       'INT', 'service.expire AS iptv_expire',               1 ],      
      ['USER_NAME',         'STR', 'c.user_name',                                 1 ],
      ['SESSION_IDS',       'STR', 'c.acct_session_id',                           1 ],
      ['FRAMED_IP_ADDRESS', 'IP',  'c.framed_ip_address',                         1 ],
      ['NAS_ID',            'INT', 'c.nas_id',                                    1 ],
      ['GUEST',             'INT', 'c.guest',                                     1 ],
      ['ACCT_SESSION_ID',   'STR', 'c.acct_session_id',                           1 ],
      ['LAST_ALIVE',        'INT', 'UNIX_TIMESTAMP() - c.lupdated AS last_alive', 1 ],
      ['ONLINE_BASE',  	    '',    '', 'c.CID, c.acct_session_id, UNIX_TIMESTAMP() - c.lupdated AS last_alive, c.uid' ]
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }    
    );

    foreach my $field ( keys %$attr ) {
      if (! $field) {
        print "iptv_calls/online: Wrong field name\n";
      }
      elsif ($field =~ /TP_BILLS_PRIORITY|TP_NAME|FILTER_ID|TP_CREDIT|PAYMENT_METHOD/ && $EXT_TABLE !~ /tarif_plans/) {
        $EXT_TABLE .= " LEFT JOIN tarif_plans tp ON (tp.tp_id=service.tp_id)";
      }
      elsif ($field =~ /NAS_NAME/ && $EXT_TABLE !~ / nas /) {
        $EXT_TABLE .= "LEFT JOIN nas ON (nas.id=c.nas_id)";
      }
      elsif ($field =~ /FIO|PHONE/ && $EXT_TABLE !~ / users_pi /) {
        $EXT_TABLE .= "LEFT JOIN users_pi pi ON (pi.uid=u.uid)";
      }
    }

  $self->query2("SELECT u.id AS login, $self->{SEARCH_FIELDS}  c.nas_id
 FROM iptv_calls c
 LEFT JOIN users u     ON (u.uid=c.uid)
 LEFT JOIN iptv_main service  ON (service.uid=u.uid)

 LEFT JOIN bills b ON (u.bill_id=b.id)
 LEFT JOIN companies company ON (u.company_id=company.id)
 LEFT JOIN bills cb ON (company.bill_id=cb.id)
 $EXT_TABLE

 $WHERE
 ORDER BY $SORT $DESC;", 
 undef,
 $attr
  );

  my %dub_logins = ();
  my %dub_ports  = ();
  my %nas_sorted = ();

  if ($self->{TOTAL} < 1) {
    $self->{dub_ports}  = \%dub_ports;
    $self->{dub_logins} = \%dub_logins;
    $self->{nas_sorted} = \%nas_sorted;
    return $self->{list};
  }

  my $list = $self->{list};
  foreach my $line (@$list) {
    push @{ $nas_sorted{$line->{nas_id}} }, $line ;
  }

  $self->{dub_ports}  = \%dub_ports;
  $self->{dub_logins} = \%dub_logins;
  $self->{nas_sorted} = \%nas_sorted;

  return $self->{list};
}


#**********************************************************
# online_add()
#**********************************************************
sub online_add {
  my $self = shift;
	my ($attr) = @_;

  $self->query2("INSERT INTO iptv_calls (started, uid, framed_ip_address, nas_id, nas_ip_address, status, acct_session_id, tp_id, CID)
      VALUES (now(), 
      '$attr->{UID}', 
      INET_ATON('". (($attr->{IP}) ? $attr->{IP} : '0.0.0.0' ) ."'), 
      '$attr->{NAS_ID}', 
      INET_ATON('". (($attr->{NAS_IP_ADDRESS}) ? $attr->{NAS_IP_ADDRESS} : '0.0.0.0' ) ."'), 
      '$attr->{STATUS}', 
      '$attr->{ACCT_SESSION_ID}', 
      '$attr->{TP_ID}',
      '$attr->{CID}'
      );", 'do'
  );

  return $self;
}

#**********************************************************
# online()
#**********************************************************
sub online_count {
  my $self = shift;
  my ($attr) = @_;

  my $EXT_TABLE = '';
  my $WHERE = '';
  if($attr->{DOMAIN_ID}) {
    $EXT_TABLE = ' INNER JOIN users u ON (c.uid=u.uid)';
    $WHERE = " AND u.domain_id='$attr->{DOMAIN_ID}'";
  }

  $self->query2("SELECT n.id, n.name, n.ip, n.nas_type,  
   sum(if (c.status=1 or c.status>=3, 1, 0)),
   count(distinct c.uid),
   sum(if (status=2, 1, 0)), 
   sum(if (status>3, 1, 0))
 FROM iptv_calls c  
 INNER JOIN nas n ON (c.nas_id=n.id)
 $EXT_TABLE
 WHERE c.status<11 $WHERE
 GROUP BY c.nas_id
 ORDER BY $SORT $DESC;"
  );

  my $list = $self->{list};
  $self->{ONLINE}=0;
  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT 1, count(c.uid) AS total_users,  
      sum(if (c.status=1 or c.status>=3, 1, 0)) AS online,
      sum(if (c.status=2, 1, 0)) AS zaped
   FROM iptv_calls c 
   $EXT_TABLE
   WHERE c.status<11 $WHERE
   GROUP BY 1;",
   undef,
   { INFO => 1 }
    );
   $self->{TOTAL} = $self->{TOTAL_USERS};
  }

  return $list;
}


#**********************************************************
# online_update
#**********************************************************
sub online_update {
  my $self = shift;
  my ($DATA) = @_;

  $self->query2("UPDATE iptv_calls SET
      lupdated=UNIX_TIMESTAMP()
    WHERE
      acct_session_id='$DATA->{ACCT_SESSION_ID}' and 
      uid='$DATA->{UID}' and
      CID='$DATA->{CID}';", 'do'
  );

  return $self;
}


#**********************************************************
# online_del()
#**********************************************************
sub online_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{SESSIONS_LIST}) {
    my $session_list = join("', '", @{ $attr->{SESSIONS_LIST} });
    $WHERE = "acct_session_id in ( '$session_list' )";

    if ($attr->{QUICK}) {
      $self->query2("DELETE FROM iptv_calls WHERE $WHERE;", 'do');
      return $self;
    }
  }

  @WHERE_RULES= ();
  
  if ($attr->{CID}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{CID}", 'STR', 'CID') };
  }

  if ($#WHERE_RULES > -1) {
    my $WHERE = join(' and ', @WHERE_RULES);
    $self->query2("DELETE FROM iptv_calls WHERE $WHERE;", 'do');
  }

  return $self;
}

1
