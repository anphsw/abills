package Nas_manage;

=head1 NAME

  NAS Server configuration and managing

=cut

use strict;
use parent 'dbcore';

#**********************************************************
=head2 new($db, \%conf, $admin)

=cut
#**********************************************************
sub new {
  my ($class, $db, $CONF, $admin) = @_;

  my $self = {
    db    => $db,
    conf  => $CONF,
    admin => $admin
  };
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 radtest_query_add($attr) - add query to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->radtest_query_add({
      COMMENTS   => 'test',
      RAD_QUERY  => 'User-Name=test',
      DATETIME   => 'NOW()'
    });

    $nas->radtest_query_add({
      %FORM
    });

=cut
#**********************************************************
sub radtest_query_add {
  my ($self, $attr) = @_;

  $self->query_add('radtest_history', { %$attr });

  return $self;
}

#**********************************************************
=head2 radtest_query_list($attr) - queries list

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $query_list = $nas->query_list({COLS_NAME => 1});

=cut
#**********************************************************
sub radtest_query_list {
  my ($self, $attr) = @_;

  my $sql = <<"SQL";
SELECT * FROM `radtest_history`
SQL

  $self->query_list($sql, $attr);

  my $list = $self->{list};

  return [] if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total FROM radtest_history",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 radtest_query_del() - del query from datebase

  Arguments:
    ID   - query identificator

  Returns:
    $self object

  Examples:
    $nas->radtest_query_del({ID => $FORM{query_del}});

=cut
#**********************************************************
sub radtest_query_del {
  my ($self, $attr) = @_;

  $self->query_del('radtest_history', $attr);

  return $self;
}

#***************************************************************
=head2 radtest_query_info($attr) - query info from datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->radtest_query_info({ID => $FORM{query_info}});

=cut
#***************************************************************
sub radtest_query_info {
  my ($self, $attr) = @_;

  $self->query("SELECT * FROM `radtest_history` WHERE id = ?;",
    undef, {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    });

  return $self;
}

#**********************************************************
=head2 radtest_query_add($attr) - add query to datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_add({
      COMMENTS   => 'test',
      RAD_QUERY  => 'User-Name=test',
      DATETIME   => 'NOW()'
    });

    $nas->nas_cmd_add({
      %FORM
    });

=cut
#**********************************************************
sub nas_cmd_add {
  my ($self, $attr) = @_;

  $self->query_add('nas_cmd', { %$attr });

  return $self;
}

#**********************************************************
=head2 nas_cmd_del($attr) - del query from datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_del({ID => $FORM{del}});

=cut
#**********************************************************
sub nas_cmd_del {
  my ($self, $attr) = @_;

  $self->query_del('nas_cmd', $attr);

  return $self;
}

#***************************************************************
=head2 nas_cmd_info($attr) - query info from datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $nas->nas_cmd_info({ID => $FORM{ID}});

=cut
#***************************************************************
sub nas_cmd_info {
  my ($self, $attr) = @_;

  $self->query("SELECT * FROM nas_cmd WHERE id = ?;",
    undef,
    { INFO => 1,
      Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#**********************************************************
=head2 nas_cmd_list($attr) - queries list

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $cmd_list = $Nas->nas_cmd_list({COLS_NAME => 1});

=cut
#**********************************************************
sub nas_cmd_list {
  my ($self, $attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  my @search_params = (
    ['ID',             'INT',  'id',         1 ],
    ['NAS_ID',         'INT',  'nas_id',     1 ],
    ['CMD',            'STR',  'cmd',        1 ],
    ['TYPE',           'STR',  'type',       1 ],
    ['COMMENTS',       'STR',  'comments',   1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    {
      WHERE            => 1,
      WHERE_RULES      => \@WHERE_RULES,
    }
  );

  my $sql = <<"SQL";
SELECT
  id,
  nas_id,
  cmd,
  type,
  comments
  FROM nas_cmd
  $WHERE
  ORDER BY $SORT $DESC
  LIMIT $PG, $PAGE_ROWS;
SQL


  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return [] if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total FROM nas_cmd",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 nas_cmd_change($attr)

=cut
#**********************************************************
sub nas_cmd_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'nas_cmd',
    DATA         => $attr,
  });

  return $self;
}


1;