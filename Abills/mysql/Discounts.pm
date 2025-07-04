=head1 NAME

  Discounts - module for discounts

=head1 SYNOPSIS

  use Discounts;
  my $Discounts = Discounts->new($db, $admin, \%conf);

=cut

package Discounts;

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#*******************************************************************
=head2 function new()

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = 'Discounts';

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 add_discount() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub add_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('discounts_discounts', { %$attr });

  return $self;
}

#*******************************************************************

=head2 function list_discount() - get list of all discounts

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Discounts->list_discount({ COLS_NAME => 1});

=cut

#*******************************************************************
sub list_discount {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query(
    "SELECT * FROM discounts_discounts
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total
   FROM discounts_discounts",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2 function info_discount() - get information about discount

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $disc_info = $Discounts->info_discount({ ID => 1 });

=cut

#*******************************************************************
sub info_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM discounts_discounts
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function change_discount() - change discount's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Discounts->change_discount({
      ID     => 1,
      SIZE   => 10,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub change_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'discounts_discounts',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2 function delete_discount() - delete discount

  Arguments:
    $attr

  Returns:

  Examples:
    $Discounts->delete_discount( {ID => 1} );

=cut

#*******************************************************************
sub delete_discount {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('discounts_discounts', $attr);

  return $self;
}


#**********************************************************
=head2 user_discounts() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub user_discounts_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->query("SELECT dd.name,
       dud.date,
       dd.size,
       dd.comments,
       dd.id
     FROM discounts_discounts dd
     LEFT JOIN discounts_user_discounts dud ON (dud.discount_id = dd.id AND dud.uid='$attr->{UID}')
     GROUP BY dd.id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
=head2 discount_user_change($attr)

=cut
#**********************************************************
sub discount_user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->discounts_user_del($attr);

  if ($attr->{IDS}) {
    my @ids_arr = split(/,\s+/x, $attr->{IDS} || '');
    my @MULTI_QUERY = ();

    for (my $i; $i <= $#ids_arr; $i++) {
      my $id = $ids_arr[$i];

      push @MULTI_QUERY, [
        $attr->{ 'UID' },
        $id
      ];
    }

    $self->query("INSERT INTO discounts_user_discounts (uid, discount_id, date)
        VALUES (?, ?, curdate());",
      undef,
      { MULTI_QUERY => \@MULTI_QUERY });
  }

  return $self;
}

#**********************************************************
# user_del()
#**********************************************************
sub discounts_user_del {
  my $self = shift;
  my ($attr) = @ _;

  $self->query_del('discounts_user_discounts', undef, { uid => $attr->{UID},
  });

  # $self->{admin}->action_add( $attr->{UID}, "", { TYPE => 10 } );

  return $self;
}

#**********************************************************
=head2 discounts_user_query($attr)

  Arguments:
     UID - User ID

  Returns:

=cut
#**********************************************************
sub discounts_user_query {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT fio FROM users_pi WHERE uid = ?",
    undef, { COLS_NAME => 1, Bind => [ $attr->{UID} ] });

  return $self;
}


#**********************************************************
=head2 user_add() - add user discount

  Arguments:
    $attr -
  Returns:
    $self object

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('discounts_main', { %$attr, AID => $self->{admin}->{AID} });

  $self->{admin}->action_add( $attr->{UID},
    "ID:$self->{INSERT_ID}, SUM:$attr->{SUM}, PERCENT:$attr->{PERCENT}, FROM_DATE:$attr->{FROM_DATE}, TO_DATE:$attr->{TO_DATE}, TYPE:$attr->{TYPE}",
    { TYPE => 1 } );

  return $self;
}

#*******************************************************************

=head2 user_info() - get information about user discount

  Arguments:
    $attr

  Returns:
    $self object

=cut

#*******************************************************************
sub user_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM discounts_main
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************
=head2 user_change($attr) - change user's discounts

  Arguments:
   $attr

  Returns:
    $self

=cut
#*******************************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'discounts_main',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2  user_del(ID) - delete user's discounts

  Arguments:
    ID

  Returns:
   $self

=cut
#*******************************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('discounts_main', $attr);
  $self->{admin}->action_add( $attr->{UID}, "DELETED: $attr->{ID}", { TYPE => 10 } );

  return $self;
}

#*******************************************************************

=head2  user_list ($attr) - list of user's discounts

  Arguments:
    $attr
      HASH_RETURN - return user's discounts as a hash (ID => NAME)

  Returns:
    $list or $list_hash

=cut

#*******************************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : '1';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;
  my $EXT_TABLES = '';

  if ($attr->{LOGIN}){
    $EXT_TABLES .= 'LEFT JOIN users u ON (u.uid=dm.uid)';
    $attr->{UID} = '_SHOW',
  }

  my @search_columns = (
    [ 'FROM_DATE',        'DATE',  'dm.from_date',              1 ],
    [ 'TO_DATE',          'DATE',  'dm.to_date',                1 ],
    [ 'LOGIN',            'STR',   'u.id AS login',             1 ],
    [ 'MODULE',           'STR',   'dm.module',                 1 ],
    [ 'TP_ID',            'INT',   'dm.tp_id',                  1 ],
    [ 'PERCENT',          'INT',   'dm.percent',                1 ],
    [ 'SUM',              'DOUBLE','dm.sum',                    1 ],
    [ 'STATUS',           'INT',   'dm.status',                 1 ],
    [ 'AID',              'INT',   'dm.aid',                    1 ],
    [ 'TYPE',             'INT',   'dm.type',                   1 ],
    [ 'COMMENTS',         'STR',   'dm.comments',               1 ],
    [ 'UID',              'INT',   'dm.uid',                    1 ],
    [ 'REG_DATE',         'DATE',  'dm.reg_date',               1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_columns, {
    WHERE         => 1,
  });

  $self->query("
    SELECT
      $self->{SEARCH_FIELDS}
      dm.id
    FROM discounts_main dm
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("
    SELECT COUNT(*) AS total
    FROM discounts_main dm
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2  reports ($attr) -  discount's reports

  Arguments:
    $attr

  Returns:
    $list

=cut
#*******************************************************************
sub reports {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : '1';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;
  my @WHERE_RULES = ();
  my $EXT_TABLES = '';
  my $GROUP_BY = '';
  my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';

  if($attr->{FROM_REG_DATE_TO_REG_DATE}){
    push @WHERE_RULES, "DATE_FORMAT(dm.reg_date, '%Y-%m-%d')>='$attr->{FROM_REG_DATE}'
                      AND DATE_FORMAT(dm.reg_date, '%Y-%m-%d')<='$attr->{TO_REG_DATE}'";
  }

  my $report_type = $attr->{REPORT_TYPE} || q{};

  if ($attr->{GID} || $attr->{GID_NAME}){
    $EXT_TABLES .= ' LEFT JOIN `groups` g ON (g.gid=u.gid)';
  }
  $attr->{UID} = '_SHOW' if ($attr->{LOGIN});
  if ($attr->{A_NAME} || $report_type eq 'ADMINS'){
    $EXT_TABLES .= "\nLEFT JOIN admins a ON (a.aid=dm.aid)";
  }
  if ($attr->{TAGS}){
    $EXT_TABLES .= "\nLEFT JOIN tags_users tu ON (tu.uid=dm.uid)
                      RIGHT JOIN tags t ON (t.id=tu.tag_id)";
    $attr->{TAG_NAME} = '_SHOW',
  }
  if ($attr->{ADDRESS_FULL} || $attr->{DISTRICT_ID} ) {
    $EXT_TABLES .= "\nLEFT JOIN users_pi pi ON (pi.uid=dm.uid)";
    $EXT_TABLES .= "\nLEFT JOIN builds b ON (b.id=pi.location_id)
                    \nLEFT JOIN streets s ON (s.id=b.street_id)
                    \nLEFT JOIN districts d ON (d.id=s.district_id)";
  }
  if ($report_type eq 'ADMINS') {
    $GROUP_BY = "GROUP BY dm.aid, month";
    $attr->{MONTH} = '_SHOW',
  }

  my @search_columns = (
    [ 'FROM_DATE',        'DATE',  'dm.from_date',                    1 ],
    [ 'TO_DATE',          'DATE',  'dm.to_date',                      1 ],
    [ 'MONTH',            'DATE',  "DATE_FORMAT(dm.from_date, '%Y-%m') AS month", 1 ],
    [ 'LOGIN',            'STR',   'u.id AS login',                   1 ],
    [ 'MODULE',           'STR',   'dm.module',                       1 ],
    [ 'TP_ID',            'INT',   'dm.tp_id',                        1 ],
    [ 'PERCENT',          'INT',   'dm.percent',                      1 ],
    [ 'SUM',              'DOUBLE','dm.sum',                          1 ],
    [ 'STATUS',           'INT',   'dm.status',                       1 ],
    [ 'AID',              'INT',   'dm.aid',                          1 ],
    [ 'TYPE',             'INT',   'dm.type',                         1 ],
    [ 'COMMENTS',         'STR',   'dm.comments',                     1 ],
    [ 'UID',              'INT',   'dm.uid',                          1 ],
    [ 'REG_DATE',         'DATE',  'dm.reg_date',                     1 ],
    [ 'A_NAME',           'STR',   'a.name',          'a.name AS a_name'],
    [ 'A_LOGIN',          'STR',   'a.id',            'a.id AS a_login' ],
    [ 'COUNT_DISCOUNTS',  'STR',   "COUNT(dm.id) AS count_discounts",  "COUNT(dm.id) AS count_discounts" ],
    [ 'GID',              'STR',   'u.gid',                           1 ],
    [ 'GID_NAME',         'STR',   'g.name',       'g.name AS gid_name' ],
    [ 'TAGS',             'STR',    'tu.tag_id',                      1 ],
    [ 'TAGS_NAME',        'STR',    "\n(SELECT GROUP_CONCAT(DISTINCT t.name SEPARATOR ', ') FROM tags_users tu LEFT JOIN tags t ON (t.id=tu.tag_id) WHERE dm.uid=tu.uid) AS tags_name", 1 ],
    [ 'DISTRICT_ID',      'INT',    'd.id',       'd.id AS district_id' ],
    [ 'STREET_ID',        'INT',    's.id',        's.id AS street_id ' ],
    [ 'LOCATION_ID',      'INT',    'b.id',         'b.id AS builds_id' ],
    [ 'ADDRESS_FULL',     'STR',    "IF(pi.location_id, CONCAT(d.name, '$build_delimiter', s.name, '$build_delimiter', b.number, '$build_delimiter', pi.address_flat), '')
                                  AS address_full",  1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_columns, {
    WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES,
  });

  $self->query("
  SELECT
    $self->{SEARCH_FIELDS}
    dm.id
  FROM discounts_main dm
  LEFT JOIN users u ON (u.uid=dm.uid)
  $EXT_TABLES
  $WHERE
  $GROUP_BY
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  if ($report_type eq 'ADMINS') {
    return $list;
  }

  $self->query("
    SELECT COUNT(*) AS total
    FROM discounts_main dm
    LEFT JOIN users u ON (u.uid=dm.uid)
    $EXT_TABLES
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************

=head2  report_chart ($attr) - chart with user's discounts by month

  Arguments:
    $attr

  Returns:
    $list

=cut

#*******************************************************************
sub report_chart {

  my $self = shift;
  my ($attr) = @_;

  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 1000;
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'month';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr,[
      [ 'FROM_DATE',        'DATE',  'dm.from_date',              1 ],
      [ 'LOGIN',            'STR',   'u.id AS login',             1 ],
      [ 'MODULE',           'STR',   'dm.module',                 1 ],
      [ 'TP_ID',            'INT',   'dm.tp_id',                  1 ],
      [ 'PERCENT',          'INT',   'dm.percent',                1 ],
      [ 'SUM',              'DOUBLE','dm.sum',                    1 ],
      [ 'STATUS',           'INT',   'dm.status',                 1 ],
      [ 'AID',              'INT',   'dm.aid',                    1 ],
      [ 'TYPE',             'INT',   'dm.type',                   1 ],
    ],
    { WHERE  => 1 }
  );

  $self->query("
   SELECT
    DATE_FORMAT(dm.from_date, '%Y-%m') as month,
    COUNT(id) AS quantity
    FROM discounts_main dm
    $WHERE
    GROUP BY month
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  return $self->{list};
}

1;
