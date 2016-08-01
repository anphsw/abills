package Hotspot;
use strict;
use warnings FATAL => 'all';

use parent "main";

my $MODULE = 'Hotspot';

use POSIX;


#**********************************************************
=head2 new($db, $admin, \%conf) - constructor for Hotspot DB object

=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 visits_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub visits_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID', 'STR', 'id', 1 ],
    [ 'FIRST_SEEN', 'DATE', 'first_seen', 1 ],
    [ 'BROWSER', 'STR', 'browser', 1 ]
  ];

  my $WHERE = '';

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    foreach my $search_column ( @$search_columns ) {
      my $name = $search_column->[0];
      $attr->{$name} = '_SHOW' if (!exists $attr->{$name});
    }
  }

  $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} id FROM hotspot_visits $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
    {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : { } }
    }
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 visits_count() - quick count

  Returns:
    Count of elements in table

=cut
#**********************************************************
sub visits_count  {
  my $self = shift;

  $self->query2("SELECT COUNT(*)FROM hotspot_visits");

  return -1 if $self->{errno};

  return $self->{list}->[0];
}


#**********************************************************
=head2 visits_info($id)

  Arguments:
    $id - id for hotspot_visits

  Returns:
    hash_ref

=cut
#**********************************************************
sub visits_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->visits_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0];
}

#**********************************************************
=head2 visits_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub visits_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'hotspot_visits', $attr, { REPLACE => 1 } );

  return 1;
}

#**********************************************************
=head2 visits_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub visits_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'hotspot_visits', $attr );

  return 1;
}

#**********************************************************
=head2 visits_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub visits_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_visits',
      DATA         => $attr,
    } );

  return 1;
}


#**********************************************************
=head2 logins_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub logins_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'hl.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = '';

  # TODO : user_btn from UID column

  my $search_columns = [
    [ 'ID', 'INT', 'hl.id', 1 ],
    [ 'UID', 'INT', 'hl.uid', 1 ],
    [ 'VISIT_ID', 'STR', 'hl.visit_id', 1 ],
    [ 'LOGIN_TIME', 'DATE', 'hl.login_time', 1 ],
    [ 'FIRST_SEEN', 'DATE', 'hv.first_seen', 1 ],
    [ 'SESSION_ID', 'STR', 'hv.id', 1 ],
    [ 'BROWSER', 'STR', 'hv.browser', 1 ],
  ];

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    foreach my $search_column ( @$search_columns ) {
      my $name = $search_column->[0];
      $attr->{$name} = '_SHOW' if (!exists $attr->{$name});
    }
  }

  $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query2(
    "SELECT $self->{SEARCH_FIELDS} hv.id
     FROM hotspot_logins hl
     LEFT JOIN hotspot_visits hv ON (hl.visit_id = hv.id)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef,
  {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list};
}

#**********************************************************
=head2 logins_info($id)

  Arguments:
    $id - id for logins

  Returns:
    hash_ref

=cut
#**********************************************************
sub logins_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->logins_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0];
}

#**********************************************************
=head2 logins_info_for_session($session_id) - Searches login by visit id

  Arguments:
    $session_id - session_id for logins as specified in hotspot_visits

  Returns:
    hash_ref

=cut
#**********************************************************
sub logins_info_for_session {
  my $self = shift;
  my ($session_id) = @_;

  my $list = $self->logins_list( { COLS_NAME => 1, VISIT_ID => $session_id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0];
}
#**********************************************************
=head2 logins_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub logins_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'hotspot_logins', $attr, { REPLACE => 1 } );

  return 1;
}

#**********************************************************
=head2 logins_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub logins_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'hotspot_logins', $attr );

  return 1;
}

#**********************************************************
=head2 logins_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub logins_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2( {
      CHANGE_PARAM => 'ID',
      TABLE        => 'hotspot_logins',
      DATA         => $attr,
    } );

  return 1;
}


1;