package Netlist;

#Nas Server configuration and managing

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use main;
use Socket;

@ISA = ("main");
my $CONF;
my $admin;
my $SECRETKEY = '';

sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;
  my $self = {};
  bless($self, $class);
  
  $self->{db}=$db;
  
  return $self;
}

#**********************************************************
# list
#**********************************************************
sub groups_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @list = ();
  $self->query2("SELECT ng.name, ng.comments, count(ni.ip), ng.id
    FROM netlist_groups ng
    LEFT JOIN netlist_ips ni ON (ng.id=ni.gid)
    GROUP BY ng.id
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  if ($self->{errno}) {
    return \@list;
  }

  return $self->{list};
}

#**********************************************************
# Add
#**********************************************************
sub group_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query_add('netlist_groups', $attr);
  $self->{GID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub group_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'netlist_groups',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub group_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM netlist_groups WHERE id='$id';", 'do');

  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub group_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("SELECT *
    FROM netlist_groups
    WHERE id='$id';",
    undef,
    { INFO => 1 }
  );


  return $self;
}

#**********************************************************
# list
#**********************************************************
sub ip_list() {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
        ['GID',     'INT', 'ni.gid'                   ],
        ['IP',      'INT', "INET_ATON('$attr->{IP}')" ],
        ['STATUS',  'INT', 'ni.status',               ], 
        ['HOSTNAME','STR', 'ni.hostname'              ]
      ],
      { WHERE       => 1  }    
    );

  $self->query2("SELECT ni.ip AS ip_num, INET_NTOA(ni.netmask) AS netmask, ni.hostname, 
      ni.descr,
      ng.name, 
      ni.status, DATE_FORMAT(ni.date, '%Y-%m-%d') AS date, INET_NTOA(ni.ip) AS ip
    FROM netlist_ips ni
    LEFT JOIN netlist_groups ng ON (ng.id=ni.gid)
    $WHERE
    GROUP BY ni.ip
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(*) AS total
    FROM netlist_ips ni
    LEFT JOIN netlist_groups ng ON (ng.id=ni.gid)
    $WHERE;",
    undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# Add
#**********************************************************
sub ip_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);

  $self->query_add('netlist_ips', { %$attr,
  	                                AID  => $admin->{AID},
  	                                DATE => 'now()'
  	                              });

  return $self;
}

#**********************************************************
# change
#**********************************************************
sub ip_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    IP_NUM   => 'ip',
    NETMASK  => 'netmask',
    HOSTNAME => 'hostname',
    GID      => 'gid',
    STATUS   => 'status',
    COMMENTS => 'comments',
    IP       => 'ip',
    DESCR    => 'descr'
  );

  if ($attr->{IDS}) {
    my @ids_array = split(/, /, $attr->{IDS});
    foreach my $a (@ids_array) {
      $attr->{IP_NUM} = $a;
      $attr->{HOSTNAME} = gethostbyaddr(inet_aton($a), AF_INET) if ($attr->{RESOLV});

      $self->changes(
        $admin,
        {
          CHANGE_PARAM => 'IP_NUM',
          TABLE        => 'netlist_ips',
          FIELDS       => \%FIELDS,
          OLD_INFO     => $self->ip_info($attr->{IP_NUM}, $attr),
          DATA         => $attr
        }
      );

      return $self if ($self->{errno});

    }
    return 0;
  }

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'IP_NUM',
      TABLE        => 'netlist_ips',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->ip_info($attr->{IP_NUM}, $attr),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
# del
#**********************************************************
sub ip_del {
  my $self = shift;
  my ($ip) = @_;

  $self->query2("DELETE FROM netlist_ips WHERE ip='$ip';", 'do');

  return $self;
}

#**********************************************************
# Info
#**********************************************************
sub ip_info {
  my $self = shift;
  my ($ip, $attr) = @_;

  $self->query2("SELECT INET_NTOA(ip) AS ip, 
       INET_NTOA(netmask) AS netmask,
       hostname,
       gid,
       status,
       comments,
       descr,
       ip AS ip_num
    FROM netlist_ips
    WHERE ip='$ip';",
    undef,
    { INFO => 1 }
  );

  return $self;
}

1
