package Cams;
=name2

  Cams

=VERSION

  VERSION = 0.01

=cut

use strict;
use warnings FATAL => 'all';

use parent 'main';

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new{
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
    MODULE => 'Cams'
  };

  bless( $self, $class );

  return $self;
}

#**********************************************************
=head2 users_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub users_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'UID', 'INT', 'uid', 1 ],
    [ 'CREATED', 'DATE', 'created', 1 ],
    [ 'TP_ID', 'INT', 'tp_id', 1 ]
  ];

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @{$search_columns};
  }

  my $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query2( "SELECT $self->{SEARCH_FIELDS} uid FROM cams_main $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : { }} }
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 user_info($id)

  Arguments:
    $id - id for cams_users

  Returns:
    hash_ref

=cut
#**********************************************************
sub user_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->users_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0];
}

#**********************************************************
=head2 user_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add( 'cams_main', $attr );

  return 1;
}

#**********************************************************
=head2 users_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub users_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'cams_main', $attr );

  return 1;
}

#**********************************************************
=head2 user_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes2( {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_main',
      DATA         => $attr,
    } );

  return 1;
}

#**********************************************************
=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub tp_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? 'DESC' : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;


  my $search_columns = [
    ['ID',            'INT',   'ctp.id'                 ,1 ],
    ['NAME',          'STR',   'ctp.name'               ,1 ],
    ['STREAMS_COUNT', 'INT',   'ctp.streams_count'      ,1 ],
    ['ABON_ID',       'INT',   'ctp.abon_id'            ,1 ],
    ['ABON_NAME',     'STR',   'atp.name as abon_name'  ,1 ],

    # TODO: JOIN Abon params
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query2( "SELECT $self->{SEARCH_FIELDS} ctp.id FROM cams_tp ctp LEFT JOIN abon_tariffs atp ON (ctp.id=atp.id) $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    COLS_UPPER => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};


  return $self->{list};
}

#**********************************************************
=head2 tp_info($id)

  Arguments:
    $id - id for tp

  Returns:
    hash_ref

=cut
#**********************************************************
sub tp_info{
  my $self = shift;
  my ($id) = @_;

  my $list = $self->tp_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0];
}

#**********************************************************
=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub tp_add{
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('cams_tp', $attr);

  return 1;
}

#**********************************************************
=head2 tp_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub tp_del{
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('cams_tp', $attr);

  return 1;
}

#**********************************************************
=head2 tp_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub tp_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes2({
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_tp',
      DATA         => $attr,
    });

  return 1;
}

#**********************************************************
=head2 streams_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub streams_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $search_columns = [
    [ 'ID', 'INT', 'id', 1 ],
    [ 'NAME', 'STR', 'name', 1 ],
    [ 'IP', 'STR', 'INET_NTOA(ip) AS ip', 1 ],
    [ 'IP_NUM', 'IP', 'ip as ip_num', ],
    [ 'LOGIN', 'STR', 'login', 1 ],
    [ 'PASSWORD', 'STR', 'DECODE(password, "' . $self->{conf}{secretkey} . '") as password', 1 ],
    [ 'URL', 'STR', 'url', 1 ]
  ];

  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @{$search_columns};
  }

  my $WHERE = $self->search_former( $attr, $search_columns,
    {
      WHERE => 1
    }
  );

  $self->query2( "SELECT $self->{SEARCH_FIELDS} id FROM cams_streams $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
    , undef, {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      %{ $attr ? $attr : { }} }
  );

  return [ ] if ($self->{errno});

  return $self->{list};
}

#**********************************************************
=head2 streams_info($id)

  Arguments:
    $id - id for streams

  Returns:
    hash_ref

=cut
#**********************************************************
sub streams_info {
  my $self = shift;
  my ($id) = @_;

  my $list = $self->streams_list( { COLS_NAME => 1, ID => $id, SHOW_ALL_COLUMNS => 1, COLS_UPPER => 1 } );

  return $list->[0];
}

#**********************************************************
=head2 streams_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub streams_add {
  my $self = shift;
  my ($attr) = @_;

  my %pass_attr = ();
  if ($attr->{PASSWORD}){
    %pass_attr = ( PASSWORD => "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" );
  }

  $self->query_add( 'cams_streams', {
    %{ $attr ? $attr : {} },
    %pass_attr
    });

  return $self->{INSERT_ID};
}

#**********************************************************
=head2 streams_del($attr)

  Arguments:
    $attr - hash_ref

  Returns:
   1

=cut
#**********************************************************
sub streams_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del( 'cams_streams', $attr );

  return 1;
}

#**********************************************************
=head2 streams_change($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    1

=cut
#**********************************************************
sub streams_change {
  my $self = shift;
  my ($attr) = @_;

  my %pass_attr = ();
  if ($attr->{PASSWORD}){
    %pass_attr = ( PASSWORD => "ENCODE('$attr->{PASSWORD}', '$self->{conf}->{secretkey}')" );
  }

  $self->changes2( {
      CHANGE_PARAM => 'ID',
      TABLE        => 'cams_streams',
      DATA         => { %{ $attr ? $attr : {} }, %pass_attr },
    } );

  return 1;
}

1;