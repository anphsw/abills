package Tags;

=head2

  Tags

=cut

use strict;
use parent qw(dbcore);
my $MODULE = 'Tags';

#**********************************************************
# Init
#**********************************************************
sub new{
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $admin->{MODULE} = $MODULE;
  $self->{db}      = $db;
  $self->{admin}   = $admin;
  $self->{conf}    = $CONF;

  return $self;
}

#**********************************************************
=head2 info($id) TAG information

=cut
#**********************************************************
sub info{
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query("SELECT t.*, GROUP_CONCAT(DISTINCT tr.aid) AS aid FROM tags t
   LEFT JOIN tags_responsible tr ON (tr.tags_id = t.id)
   WHERE t.id = ? ;", undef, {
    INFO => 1,
    Bind => [ $id ]
  });

  # declare field with the same name like during manage
  $self->{RESPONSIBLE} = $self->{AID};

  return $self;
}

#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tags', $attr);
  $self->{admin}->system_action_add("TAG_ID:$self->{INSERT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 change()

=cut
#**********************************************************
sub change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'tags',
    DATA            => $attr,
    EXT_CHANGE_INFO => "TAG_ID:$attr->{ID}"
  });

  return $self;
}

#**********************************************************
=head2 del($id); Delete user info from all tables

=cut
#**********************************************************
sub del{
  my $self = shift;
  my ($id) = @_;

  $self->query_del('tags', { ID => $id });

  $self->{admin}->system_action_add( "TAG_ID:$id", { TYPE => 10 } );
  return $self;
}

#**********************************************************
=head2 list()

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $EXT_TABLE = $self->{EXT_TABLES} || '';

  my $WHERE = $self->search_former( $attr, [
      [ 'NAME',           'STR',    't.name',                                     1 ],
      [ 'COMMENTS',       'STR',    't.comments',                                 1 ],
      [ 'PRIORITY',       'int',    't.priority',                                 1 ],
      [ 'ID',             'INT',    't.id',                                         ],
      [ 'ID_RESPONSIBLE', 'INT',    'tr.id AS id_responsible',                    1 ],
      [ 'RESPONSIBLE',    'INT',    'GROUP_CONCAT(DISTINCT a.id) AS responsible', 1 ],
      [ 'TAGS_ID',        'INT',    'tr.tags_id',                                 1 ],
      [ 'COLOR',          'STR',    't.color',                                    1 ],
      [ 'EXPIRE_DAYS',    'INT',    't.expire_days',                              1 ],
    ], { WHERE => 1 },
  );

  if ($attr->{RESPONSIBLE_ADMIN}) {
    $EXT_TABLE .= "LEFT JOIN tags_responsible AS tr FORCE INDEX FOR JOIN (`tags_id_fk`) ON t.id = tr.tags_id
                  LEFT JOIN  admins AS a ON tr.aid = a.aid";
  }

  $self->query("SELECT $self->{SEARCH_FIELDS} t.id
     FROM tags AS t
     $EXT_TABLE
     $WHERE
      GROUP BY t.id
      ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list_hash} if ($attr->{LIST2HASH});

  return $self->{list} || [];
}

#**********************************************************
=head2 tags_user($attr)

=cut
#**********************************************************
sub tags_user{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;

  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former( $attr, [
      [ 'TAG_ID',     'INT', 't.id',                            ],
      [ 'LAST_ABON',  'INT', 'tu.date',                         ],
      [ 'USERS_SUM',  'INT', 'SUM(tu.uid) AS tu.users_sum',     ],
      [ 'END_DATE',   'DATE','tu.end_date',       'tu.end_date AS end_date', ],
      [ 'RESPONSIBLE','INT', 'GROUP_CONCAT(DISTINCT a.id) AS responsible', 1 ],
      [ 'EXPIRE_DAYS','INT', 't.expire_days',                 1 ],
    ], { WHERE => 1 });

  my $EXT_TABLE = '';
  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ($attr->{RESPONSIBLE}) {
    $EXT_TABLE .= "LEFT JOIN tags_responsible AS tr FORCE INDEX FOR JOIN (`tags_id_fk`) ON t.id = tr.tags_id
                  LEFT JOIN  admins AS a ON tr.aid = a.aid";
  }

  $self->query( "SELECT t.name,
       tu.date,
       t.comments,
       t.priority,
       t.color,
       t.id,
       $self->{SEARCH_FIELDS}
       tu.uid
     FROM tags t
     LEFT JOIN tags_users tu ON (tu.tag_id = t.id AND tu.uid='$attr->{UID}')
     $EXT_TABLE
     $WHERE
     GROUP BY t.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  $WHERE .= (! $WHERE) ? "WHERE tu.uid='$attr->{UID}'" : " AND tu.uid='$attr->{UID}'";

  if ( $self->{TOTAL} > 0 ){
    $self->query( "SELECT COUNT(DISTINCT tu.uid) AS total
     FROM tags t
     LEFT JOIN tags_users tu ON (tu.tag_id = t.id)
     $WHERE
     GROUP BY tu.uid", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
=head2 tags_user_change($attr)

=cut
#**********************************************************
sub tags_user_change{
  my $self = shift;
  my ($attr) = @_;

  my $old_tags = {};
  my $old_info = $self->tags_list({ UID => $attr->{UID}, COLS_NAME => 1 });
  map $old_tags->{$_->{id}} = $_->{date}, @{$old_info};

  $self->{admin}{MODULE} = $MODULE;
  $self->user_del({ %$attr, SKIP_LOG => 1 }) if !$attr->{REPLACE};

  if ($attr->{IDS}) {
    my @ids_arr = split(/,\s?/, $attr->{IDS} || '');
    my @end_date_arr = split(/,\s?/, $attr->{END_DATE} || '');
    my @MULTI_QUERY = ();

    for (my $i = 0; $i <= $#ids_arr; $i++) {
      my $id = $ids_arr[$i];
      my $end_date = $end_date_arr[$i] || '0000-00-00';

      push @MULTI_QUERY, [ $attr->{ 'UID' }, $id, $old_tags->{$id} ? $old_tags->{$id} : $main::DATE, $end_date ];
    }

    my $action = $attr->{REPLACE} ? 'REPLACE' : 'INSERT';
    $self->query("$action INTO tags_users (uid, tag_id, date, end_date) VALUES (?, ?, ?, ?);",
      undef, { MULTI_QUERY => \@MULTI_QUERY });
  }
  $attr->{IDS} //= '';
  $self->{admin}->action_add( $attr->{UID}, (join(',', keys(%{$old_tags})) || '') . " -> $attr->{IDS}", { TYPE => 1 } );

  return $self;
}

#**********************************************************
=head2 user_del($attr)

  Arguments:
    $attr
      UID
      TAG_ID

=cut
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @ _;

  if ($attr->{TAG_ID}) {
    my @delete_attr = ($attr->{UID}, $attr->{TAG_ID});

    $self->query('DELETE FROM tags_users WHERE uid = ? AND tag_id = ?;', 'do', {
      Bind => \@delete_attr
    });
  }
  else {
    $self->query_del('tags_users', undef, { uid => $attr->{UID} });
  }

  if($self->{AFFECTED} && $self->{AFFECTED} > 0 && !$attr->{SKIP_LOG}) {
    $self->{admin}->{MODULE}=$MODULE;
    $self->{admin}->action_add($attr->{UID}, "", { TYPE => 10 });
  }

  return $self;
}

#**********************************************************
=head2 user_add($attr)

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('tags_users', $attr);
  $self->{admin}->system_action_add("USER TAG_ID:$self->{INSERT_ID}", { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 tags_list($attr)

=cut
#**********************************************************
sub tags_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $self->{EXT_TABLES} = '';

  my $WHERE = $self->search_former($attr, [
      [ 'FIO',        'STR',    'up.fio',     ],
      [ 'TAG_ID',     'INT',    't.id',       ],
      [ 'LAST_ABON',  'INT',    'tu.date',    ],
      [ 'UID',        'INT',    'tu.uid',     ],
      [ 'NAME',       'STR',    't.name',     ],
      [ 'PRIORITY',   'INT',    't.priority', ],
      [ 'COMMENTS',   'STR',    't.comments', ],
      [ 'LOGIN',      'STR',    'u.id',       ],
      [ 'DISABLE',    'INT',    'u.disable',  ],
      [ 'DATE',       'DATE',   'tu.date',    ],
      [ 'END_DATE',   'DATE',   'tu.end_date', 1],
    ], { WHERE => 1 }
  );

  my $EXT_TABLE = '';
  $EXT_TABLE = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  $self->query( "SELECT t.name,
       tu.date,
       tu.end_date,
       t.comments,
       t.priority,
       t.id,
       u.disable,
       u.uid,
       u.id as login
     FROM tags_users tu
     RIGHT JOIN tags t ON (t.id=tu.tag_id)
     LEFT JOIN users u ON (u.uid=tu.uid)
     $EXT_TABLE
     $WHERE
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 add_responsible($attr)

  Arguments:
    AID       - admin id
    TAGS_ID   - tags id

  Returns:
    -

=cut
#**********************************************************
sub add_responsible {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{ID};

  $self->query_del('tags_responsible', undef, { TAGS_ID => $attr->{ID} });
  return $self if !$attr->{AID};

  my @MULTI_QUERY = ();
  my @ids = split(/,\s?/, $attr->{AID});

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $id, $attr->{ID} ];
  }

  $self->query(
    "INSERT INTO tags_responsible (aid, tags_id) VALUES (?, ?);",
    undef, { MULTI_QUERY => \@MULTI_QUERY }
  );

  return $self;
}

#**********************************************************
=head2 del_responsible($id)

  Arguments:
    $id         - id tag

  Returns:
    -

=cut
#**********************************************************
sub del_responsible{
  my $self = shift;
  my ($id) = @_;

  $self->query_del( 'tags_responsible', undef, { TAGS_ID => $id } );

  return $self;
}

#**********************************************************
=head2 user_tags_info() - get tag user for responsible admin

  Arguments:
    AID         - Admin id

  Returns:
    list tags responsibel second admin

=cut
#**********************************************************
sub user_tags_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT tu.uid, tu.tag_id, GROUP_CONCAT(DISTINCT t.name) AS name, GROUP_CONCAT(DISTINCT tu.tag_id) AS tags
    FROM tags_users AS tu
    LEFT JOIN tags AS t ON tu.tag_id = t.id
    LEFT JOIN tags_responsible AS tr ON t.id = tr.tags_id
    LEFT JOIN admins AS a ON tr.aid = a.aid
      WHERE a.aid = ?
      GROUP BY tu.uid", undef, {
    COLS_NAME => 1,
    Bind      => [ $attr->{AID} ]
  });

  return $self->{list} || [];
}

#**********************************************************
=head2 responsible_tag_list() - get list responsible tags

  Arguments:
    ID         - 
    AID        - responsible admin for tags
    TAGS_ID    - id tags who has responsible

  Returns:
    list tags responsible

=cut
#**********************************************************
sub responsible_tag_list {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = $self->search_former( $attr, [
      ['ID',        'INT',    'tr.id',      1 ],
      ['AID',       'INT',    'tr.aid',     1 ],
      ['TAGS_ID',   'INT',    'tr.tags_id', 1 ],
    ], { WHERE => 1 }
  );

  $self->query("SELECT $self->{SEARCH_FIELDS} tr.id 
    FROM tags_responsible AS tr
    $WHERE", undef, {
    COLS_NAME => 1
  });

  return $self->{list} || [];
}

#**********************************************************
=head2 report_list($attr)

=cut
#**********************************************************
sub report_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  $SORT = 4 if ($attr->{SORT} && $attr->{SORT} == 5);

  $self->query( "
    SELECT
      t.name,
      SUM(IF(u.disable=0, 1, 0)) AS active,
      SUM(IF(u.disable=1, 1, 0)) AS disable,
      COUNT(u.uid) AS usr_tags,
      t.priority,
      t.id,
      (SELECT COUNT(tag_id) AS tags_total FROM tags_users) AS tags_total
     FROM tags_users tu
     RIGHT JOIN tags t ON (t.id=tu.tag_id)
     LEFT JOIN users u ON (u.uid=tu.uid)
     GROUP BY t.name
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

1;
