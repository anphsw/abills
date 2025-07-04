=head1 Ring

Megogo - module for redial users

=head1 Synopsis

use Ring;

my $Ring = Ring->new($db, $admin, \%conf);

=cut

package Ring;

use strict;
use parent qw(dbcore);

our $VERSION = 0.04;

my ($admin, $CONF);

#*******************************************************************

=head2 function new() - initialize Ring object

  Arguments:
    $db    -
    $admin -
    %conf  -
  Returns:
    $self object

  Examples:
    $Ring = Ring->new($db, $admin, \%conf);

=cut

#*******************************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#*******************************************************************

=head2 function rule_add() - add rule to table ring_rule

  Arguments:
    %$attr
      $NAME    - rule's name;
      $DATE    - date, when rule will turn on;
      $COMMENT - comments for rule;
  Returns:
    $self object

  Examples:
    $Ring->rule_add({
      NAME    => $FORM{NAME},
      DATE    => $FORM{DATE},
      COMMENT => $FORM{COMMENT}
    });

=cut

#*******************************************************************
sub rule_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ring_rules', { %$attr });

  return $self;
}

#*******************************************************************
=head2 function rule_del() - delete rule's information from datebase

  Arguments:
    $attr

  Returns:

  Examples:
    $Ring->rule_del( {ID => 1} );

=cut
#*******************************************************************
sub rule_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ring_rules', $attr);

  return $self;
}

#*******************************************************************
=head2 function rule_select() - get info about the rule from table ring_rule

  Arguments:
    %$attr
      RULE_ID - identifier;
  Returns:
    $self object

  Examples:
    my $rule_info = $Ring->rule_select({ RULE_ID => 1});

=cut
#*******************************************************************
sub rule_select {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{RULE_ID}) {
    $self->query(
      "SELECT * FROM ring_rules
      WHERE id = ?;",
      undef,
        { INFO => 1,
          Bind => [ $attr->{RULE_ID} ]
        }
    );
  }

  return $self;
}

#*******************************************************************
=head2 function rule_change() - change rule's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Ring->rule_change({
      %FORM
    });

=cut
#*******************************************************************
sub rule_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'ring_rules',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2 function rule_list() - get list of rules

  Arguments:
    %$attr

  Returns:
    $self object

  Examples:
    $list = $Ring->rule_list( {} );

=cut
#*******************************************************************
sub rule_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{DATE_NOW}) {
    push @WHERE_RULES, "(DATE_START <= '$attr->{DATE_NOW}' AND DATE_END >= '$attr->{DATE_NOW}')";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT', 'id',            1 ],
    [ 'NAME',       'STR', 'name',          1 ],
    [ 'DATE_START', 'DATE', 'date_start',   1 ],
    [ 'DATE_END',   'DATE', 'date_end',     1 ],
    [ 'TIME_START', 'STR', 'time_start',    1 ],
    [ 'TIME_END',   'STR', 'time_end',      1 ],
    [ 'FILE',       'STR', 'file',          1 ],
    [ 'MESSAGE',    'STR', 'message',       1 ],
    [ 'COMMENT',    'STR', 'comment',       1 ],
    [ 'EVERY_MONTH','INT', 'every_month',   1 ],
    [ 'UPDATE_DAY', 'INT', 'update_day',    1 ],
    [ 'SQL_QUERY',  'STR', 'sql_query',     1 ],
  ],
    {
      WHERE => 1,
    }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' AND ', @WHERE_RULES) : '';

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} id
    FROM ring_rules
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
     FROM ring_rules
     $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2 function user_add() - add user to table ring_users_filters

  Arguments:
    %$attr
      UID     - user's identifier;
      R_ID    - rule's identifier;
      DATE    - date;
      STATUS  - call status;
  Returns:
    $self object

  Examples:
    $Ring->user_add({
      UID   => 1,
      R_ID  => 1
    });

=cut
#*******************************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('ring_users_filters', { %$attr });

  return $self;
}

#*******************************************************************
=head2 function users_rule() - get list of users for rule

  Arguments:
    %$attr

  Returns:
    $self object

  Examples:
    $list = $Ring->users_rule( {COLS_NAME => 1} );

=cut
#*******************************************************************
sub users_rule {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();
  my $EXT_TABLES = '';

  my $WHERE = $self->search_former($attr, [
    [ 'UID',       'INT', 'ruf.uid', 1 ],
    [ 'R_ID',      'INT', 'ruf.r_id', 1 ],
    [ 'TIME',      'STR', 'ruf.time', 1 ],
    [ 'DATE',      'DATE', 'ruf.date', 1 ],
    [ 'STATUS',    'INT', 'ruf.status', 1 ],
    [ 'COMMENTS',  'STR', 'ruf.comments', 1 ],
    [ 'AID',       'STR', 'a.name', 'a.name AS a_name' ],
    [ 'FIO',       'STR', "CONCAT_WS(' ', pi.fio, pi.fio2, pi.fio3) AS fio", 1 ],
    [ 'PHONE',     'STR', 'ruf.phone',    1 ],
  ],
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    }
  );

  $EXT_TABLES .= 'LEFT JOIN admins a ON (a.aid=ruf.aid)' if ($attr->{AID});
  $EXT_TABLES .= 'LEFT JOIN users_pi pi ON (pi.uid=ruf.uid)' if ($attr->{FIO});

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
     $self->{SEARCH_FIELDS}
     ruf.uid
     FROM ring_users_filters ruf
     $EXT_TABLES
     $WHERE
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr,
    { INFO => 1 }
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
    FROM ring_users_filters ruf
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2 function user_change() - change rule's information in datebase

  Arguments:
    $attr
      R_ID   - rule's identifier
      UID    - user's identifier
      STATUS - call status
      DATE   - call date

  Returns:
    $self object

  Examples:
    $Ring->user_change({
      R_ID => 1,
      UID  => 1,
      STATUS => 2,
      DATE   => $DATE
    });

=cut
#*******************************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'UID,R_ID',
      TABLE        => 'ring_users_filters',
      DATA         => $attr,
    }
  );

  return $self;
}

#*******************************************************************
=head2 function user_del() - delete rule's information from datebase

  Arguments:
    $attr

  Returns:

  Examples:
    $Ring->user_del( {UID => 1} );

=cut

#*******************************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('ring_users_filters', $attr, { UID => $attr->{UID}, R_ID => $attr->{R_ID} });

  return $self;
}

#**********************************************************
=head2 users_add_by_rule($attr)

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub users_add_by_rule {
  my $self = shift;
  my ($attr) = @_;

  $self->query("$attr->{SQL_QUERY}", undef, { COLS_NAME => 1 });
  my $list = $self->{list};

  foreach my $item (@$list) {
    $self->query_add('ring_users_filters', { UID => $item->{uid}, R_ID => $attr->{R_ID} });
  }

  return 1;
}

1
