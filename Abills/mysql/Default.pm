=head1 NAME

  Default - example for DB package module

=head1 SYNOPSIS

  use Default;
  my $Default = Default->new($db, $admin, \%conf);

  db_table - table for example. Change for your table from database

=cut

package Default;

use strict;
use parent qw(dbcore);

#*******************************************************************
=head2 new() - create new object

=cut
#*******************************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  $admin->{MODULE} = 'Default';

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 add($attr) - add item to table

   Function name 'default_add' or 'add'

  Arguments:
    $attr

  Returns:
    $self object

  Example:
    $Default->add({ NAME => 'New name', DATE => '2026-03-31' });

=cut
#**********************************************************
sub add {
  my ($self, $attr) = @_;

  $self->query_add('db_table', { %$attr });

  return $self;
}

#*******************************************************************
=head2 list($attr) - list of items from table

  Function name 'default_list' or 'list'

  Arguments:
    $attr

  Returns:
    $list

  Example:
    my $default_list = $Default->list({ ID => '_SHOW', NAME => '_SHOW', COLS_NAME => 1 });

=cut
#*******************************************************************
sub list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID',            'INT',  'dt.id',               1 ],
    [ 'NAME',          'STR',  'dt.name',             1 ],
    [ 'DATE',          'DATE', 'dt.date',             1 ],
  ];

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE => 1,
  });

  my $sql = <<"SQL";
    SELECT *
    FROM db_table dt
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM db_table dt $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#*******************************************************************
=head2 info($attr) - get information by ID from table

  Function name 'default_info' or 'info'

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $default_info = $Default->info({ ID => 1 });

=cut
#*******************************************************************
sub info {
  my ($self, $attr) = @_;

  my $sql = <<"SQL";
SELECT * FROM db_table
WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#*******************************************************************
=head2 change($attr) - change item's information in table

  Function name 'default_change' or 'change'

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Default->change({
      ID     => 1,
      NAME   => 'New Name',
      DATE   => '2026-03-31'
    });

=cut
#*******************************************************************
sub change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'db_table',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2 del($attr) - delete item by ID

  Function name 'default_del' or 'del'

  Arguments:
    $attr

  Returns:

  Examples:
    $Default->delete({ ID => 1 });

=cut
#*******************************************************************
sub del {
  my ($self, $attr) = @_;

  $self->query_del('db_table', $attr);

  return $self;
}

1;