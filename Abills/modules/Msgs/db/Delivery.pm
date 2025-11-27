package Msgs::db::Delivery;
=head NAME

  Msgs Delivery

=cut

use strict;
use parent qw(dbcore);

my $MODULE = 'Msgs';

#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  $admin->{MODULE} = $MODULE;
  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    module => $MODULE
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 msgs_delivery_add($attr) -

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub delivery_add {
  my ($self, $attr) = @_;

  $self->query_add('msgs_delivery', {
    %$attr,
    ADDED => 'NOW()',
    AID   => $self->{admin}->{AID},
  });

  $self->{DELIVERY_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
=head2 delivery_list($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_list {
  my ($self, $attr) = @_;

  delete($self->{SEARCH_FIELDS});

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_params = (
    [ 'ID',          'INT',      'id',            ],
    [ 'SEND_DATE',   'DATE',     'send_date',   1 ],
    [ 'SEND_TIME',   'TIME',     'send_time',   1 ],
    [ 'SUBJECT',     'STR',      'subject',       ],
    [ 'SEND_METHOD', 'INT',      'send_method', 1 ],
    [ 'PRIORITY',    'INT',      'priority',    1 ],
    [ 'STATUS',      'INT',      'status',      1 ],
    [ 'TEXT',        'STR',      'text',        1 ],
    [ 'ADDED',       'DATETIME', 'added',       1 ],
    [ 'AID',         'INT',      'aid',         1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1, });

  my $sql = <<"SQL";
SELECT
  id,
  $self->{SEARCH_FIELDS}
  subject
FROM msgs_delivery
  $WHERE
GROUP BY id
ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query("SELECT COUNT(*) AS total FROM msgs_delivery md $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 delivery_del($attr) -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub delivery_del {
  my ($self, $attr) = @_;

  $self->query_del('msgs_delivery', $attr);
  $self->query_del('delivery_users', undef, { mdelivery_id => $attr->{ID} });

  return $self;
}


#**********************************************************
=head2 delivery_info($id) -

  Arguments:
  $id

  Returns:

=cut
#**********************************************************
sub delivery_info {
  my ($self, $id) = @_;

  $self->query('SELECT * FROM msgs_delivery WHERE id= ? ;', undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 delivery_change($attr) -

  Arguments:
     $attr
  Returns:

=cut
#**********************************************************
sub delivery_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'msgs_delivery',
    DATA         => $attr
  });

  if(defined $attr->{STATUS} && $attr->{STATUS} == 0){
    $self->query('UPDATE msgs_delivery_users SET status = 0 WHERE mdelivery_id= ?;',
      undef, { Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#**********************************************************
=head2 user_list_add($attr)

  Arguments:
    $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub user_list_add {
  my ($self, $attr) = @_;

  my @ids = split(/,\s?/x, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id,
      $attr->{MDELIVERY_ID} || '',
      $attr->{SENDED_DATE} || '',
      $attr->{SEND_METHOD} || '',
      $attr->{STATUS} || 0,
    ];
  }

  $self->query("INSERT IGNORE INTO msgs_delivery_users (uid, mdelivery_id, sended_date, send_method, status) VALUES (?, ?, ?, ?, ?);",
    undef,
    { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 user_list($attr)

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub user_list {
  my ($self, $attr) = @_;

  delete $self->{COL_NAMES_ARR};

  my @search_params = (
    [ 'ID',           'INT', 'mdl.id'           ],
    [ 'UID',          'INT', 'u.uid'            ],
    [ 'STATUS',       'INT', 'mdl.status'       ],
    [ 'LOGIN',        'STR', 'u.id'             ],
    [ 'PASSWORD',     'STR', '', "DECODE(u.password, '$self->{conf}->{secretkey}') AS password"      ],
    [ 'MDELIVERY_ID', 'INT', 'mdl.mdelivery_id' ],
    [ 'FIO',          'STR', 'pi.fio'           ],
    [ 'EMAIL',        'STR', 'pi.email'         ],
  );

  my $WHERE = $self->search_former($attr, \@search_params, { WHERE => 1 });

  my $sql = <<"SQL";
SELECT mdl.id, u.id AS login,
       pi.fio,
       mdl.status,
       mdl.uid,
       $self->{SEARCH_FIELDS}
      pi.email
FROM msgs_delivery_users mdl
  INNER JOIN users u ON (u.uid=mdl.uid)
  LEFT JOIN users_pi pi ON (mdl.uid=pi.uid)
  $WHERE
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  $sql = <<"SQL";
SELECT COUNT(*) AS total
FROM msgs_delivery_users mdl
       INNER JOIN users u ON (u.uid=mdl.uid)
  $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 user_list_del($attr)

  Arguments:
     $attr
  Returns:

  Examples:

=cut
#**********************************************************
sub user_list_del {
  my ($self, $attr) = @_;

  $self->{admin}->{MODULE} = $MODULE;
  $self->query_del('msgs_delivery_users', $attr);

  return $self;
}

#**********************************************************
=head2 user_list_change($attr)

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub user_list_change {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ("mdelivery_id='$attr->{MDELIVERY_ID}'");

  my $WHERE = $self->search_former($attr, [
    [ 'UID', 'INT', 'uid' ],
    [ 'ID',  'INT', 'id'  ],
  ], { WHERE_RULES => \@WHERE_RULES });

  my $status = $attr->{STATUS} || 1;
  $self->query("UPDATE msgs_delivery_users SET status='$status' WHERE $WHERE;", 'do');

  return $self;
}


1;