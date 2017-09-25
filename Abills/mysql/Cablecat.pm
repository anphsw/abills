package Cablecat;

=head1 NAME

Cablecat - module for cables accounting and management

=head2 VERSION

  VERSION = 7.49

=cut

use strict;
use warnings 'FATAL' => 'all';
use parent 'main';
our $VERSION = 7.49;

use Abills::Base qw/_bp/;

my %unusual_table_names = (
  'cablecat_connecters' => 'cablecat_wells'
);

my $instance = undef;
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
sub new {
  unless (defined $instance) {
    my $class = shift;
  
    my ($db, $admin, $CONF) = @_;
  
    my $self = {
      db    => $db,
      admin => $admin,
      conf  => $CONF,
    };
  
    bless( $self, $class );
    $instance = $self;
  }
  
  return $instance;
}



#**********************************************************
=head2 AUTOLOAD

  Because all namings are standart, 'add', 'change', 'del', 'info' can be generated automatically.
  
=head2 SYNOPSIS

  AUTOLOAD is called when undefined function was called in Package::Foo.
  global $AUTOLOAD var is filled with full name of called undefined function (Package::Foo::some_function)
  
  Because in this module DB tables and columns are named same as template variables, in all logic for custom operations
  the only thing that changes is table name.
  
  We can parse it from called function name and generate 'add', 'change', 'del', 'info' functions on the fly
   
=head2 USAGE

  You should use this function as usual, nothing changes in webinterface logic.
  Just call $Cablecat->cable_types_info($cable_type_id)
  
  Arguments:
    arguments are typical for operations, assuming we are working with ID column as primary key
    
  Returns:
    returns same result as usual operation functions ( Generally nothing )

=cut
#**********************************************************
sub AUTOLOAD {
  our $AUTOLOAD;
  my ($entity_name, $operation) = $AUTOLOAD =~ /.*::(.*)_(add|del|change|info|full|count|next)$/;
  
  return if $AUTOLOAD =~ /::DESTROY$/;

  die "Undefined function $AUTOLOAD. ()" unless ($operation && $entity_name);
  
  my ($self, $data, $attr) = @_;
  
  my $table = lc(__PACKAGE__) . '_' . $entity_name;
  
  # Check for not standart table namings
  if (exists $unusual_table_names{$table}){ $table = $unusual_table_names{$table} };
  
  if ($self->{debug}){
    _bp($table, { data => $data, attr => $attr});
  }
  
  if ($operation eq 'add'){
    $data->{INSTALLED} ||= '0000-00-00 00:00:00';
    $data->{CREATED} = (exists $data->{CREATED} && !$data->{CREATED}) ? '0000-00-00 00:00:00' : undef;
    
    $self->query_add( $table, $data );
    return $self->{errno} ? 0 : $self->{INSERT_ID};
  }
  elsif ($operation eq 'del'){
    return $self->query_del( $table, $data, $attr );
  }
  elsif ($operation eq 'change'){
    return $self->changes2( {
        CHANGE_PARAM => $data->{_CHANGE_PARAM} || 'ID',
        TABLE        =>  $table,
        DATA         => $data,
      } );
  }
  elsif ($operation eq 'info'){
    my $list_func_name = $entity_name . "_list";
    
    if ($data && ref $data ne 'HASH'){
      $attr->{ID} = $data
    }
    
    my $list = $self->$list_func_name({
      SHOW_ALL_COLUMNS => 1,
      COLS_UPPER => 1,
      COLS_NAME => 1,
      PAGE_ROWS => 1,
      %{ $attr ? $attr : {} }
    });
    
    return $list->[0] || { };
  }
  elsif ($operation eq 'full'){
    my $WHERE = '';
    my @WHERE_BIND = ();
    if ($data->{WHERE}){
      $WHERE = 'WHERE ' . join ( ' AND ', map { push (@WHERE_BIND, $data->{WHERE}{$_}); "$_ = ?" } keys %{$data->{WHERE}} );
    }
    $self->query2(qq{
      SELECT * FROM cablecat_$entity_name $WHERE
    }, undef, { COLS_NAME => 1, Bind => \@WHERE_BIND });
  
    return [] if $self->{errno};
  
    return $self->{list} || [];
  }
  elsif ($operation eq 'count' || $operation eq 'next'){
    my $WHERE = '';
    my $type_id = $data->{TYPE_ID};
    
    # After connecters was moved to wells, should change logic
    if ($entity_name eq 'connecters'){
      $entity_name = 'wells';
      $type_id = 2;
    }
    
    if ($type_id){
      $WHERE = qq{WHERE type_id=$type_id};
    }
    
    my $requested = ($operation eq 'count')
                      ? 'COUNT(*)'
                      : 'MAX(id) + 1';
    
    $self->query2(qq{
      SELECT $requested FROM cablecat_$entity_name $WHERE
    } );
    return -1 if $self->{errno};
    
    return $self->{list}[0][0] || 0;
  }
}


#**********************************************************
=head2 get_join_sql($alias, $join_table, $join_alias, $table_field, $join_field)

  Arguments:
   
    $alias        - table 1 alias
    $join_table   - table 2 full name
    $join_alias   - table 2 alias
    $table_field  - table 1 field to join on
    $join_field   - table 2 field to join on
    $attr         - hash_ref
      CHECK_SEARCH_FIELDS - boolean, will check if join is needed
    
  Returns:
    string - part of SQL query for join
    if $attr->{CHECK_SEARCH_FIELDS} is specified, and no join needed, will return '';
    
=cut
#**********************************************************
sub get_join_sql($$$$$;$) {
  my $self = shift;
  my ( $alias, $join_table, $join_alias, $table_field, $join_field, $attr) = @_;
  
  $attr //= {};
  
  if ($attr->{CHECK_SEARCH_FIELDS} && $self->{SEARCH_FIELDS} && $self->{SEARCH_FIELDS} !~ /$join_alias\./){
    return '';
  }
  
  return qq{\nLEFT JOIN $join_table $join_alias ON ($alias.$table_field = $join_alias.$join_field)};
  
}
#**********************************************************
=head2 cables_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub cables_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',                  'INT'          ,'cc.id'                            ,1 ],
    [ 'NAME',                'STR'          ,'cc.name'                          ,1 ],
    [ 'CABLE_TYPE',          'STR'          ,'cct.name'                         ,'cct.name AS cable_type' ],
    [ 'COMMENTS',            'STR'          ,'mp.comments'                      ,1 ],
    [ 'CREATED',             'DATE'         ,'mp.created'                       ,1 ],
    [ 'WELL_1',              'STR'          ,'cw1.name'                         ,'cw1.name AS well_1' ],
    [ 'WELL_2',              'STR'          ,'cw2.name'                         ,'cw2.name AS well_2' ],
    [ 'FIBERS_COUNT',        'INT'          ,'cct.fibers_count'                 ,1 ],
    [ 'MODULES_COUNT',       'INT'          ,'cct.modules_count'                ,1 ],
    [ 'LENGTH',              'INT'          ,'cc.length'                        ,1 ],
    [ 'RESERVE',             'INT'          ,'cc.reserve'                       , 1 ],
  
    [ 'POLYLINE_ID',         'INT'          ,'mline.id AS polyline_id'          ,1 ],
    [ 'POINT_ID',            'INT'          ,'cc.point_id'                      ,1 ],
    [ 'WELL_1_ID',           'INT'          ,'cc.well_1'                        ,'cc.well_1 AS well_1_id' ],
    [ 'WELL_2_ID',           'INT'          ,'cc.well_2'                        ,'cc.well_2 AS well_2_id' ],
    [ 'TYPE_ID',             'STR'          ,'cc.type_id'                       , 1 ],
    [ 'MODULES_COLORS_NAME', 'STR'          ,'ccs_m.name AS modules_colors_name', 1 ],
    [ 'MODULES_COLORS',      'STR'          ,'ccs_m.colors AS modules_colors'   , 1 ],
    [ 'FIBERS_COLORS_NAME',  'STR'          ,'ccs_f.name AS fibers_colors_name' , 1 ],
    [ 'FIBERS_COLORS',       'STR'          ,'ccs_f.colors AS fibers_colors'    , 1 ],
    [ 'OUTER_COLOR',         'STR'          ,'cct.outer_color'                  , 1 ],
    [ 'LENGTH_CALCULATED',   'INT'          ,'mline.length AS length_calculated', 1 ],
    [ 'LINE_WIDTH',          'INT'          ,'cct.line_width'                   , 1 ],
    
    [ 'DISTRICT_ID',         'INT'          ,'d.id'                             ,'d.id AS district_id' ],
    [ 'STREET_ID',           'INT'          ,'s.id'                             ,'s.id AS street_id '  ],
    [ 'LOCATION_ID',         'INT'          ,'b.id'                             ,'b.id AS builds_id'   ],
    
  ];
  
  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';
    
    if ( $self->{SEARCH_FIELDS} =~ /(?:cw1|cw2)\./ ) {
      $EXT_TABLES .= qq{
        LEFT JOIN cablecat_wells cw1 ON (cc.well_1=cw1.id)
        LEFT JOIN cablecat_wells cw2 ON (cc.well_2=cw2.id)
      }
    }
    if ( $self->{SEARCH_FIELDS} =~ /(?:mline|mp)\./ ) {
      $EXT_TABLES .= qq{
        LEFT JOIN maps_points mp ON (cc.point_id=mp.id)
        LEFT JOIN maps_polylines mline ON (mline.object_id=mp.id)
      }
    }
    if ( $self->{SEARCH_FIELDS} =~ /cct\./ ) {
      $EXT_TABLES .= "\n LEFT JOIN cablecat_cable_types cct ON (cc.type_id=cct.id)";
      
      # Joining color schemes needs params from cablecat_cable_types
      if ( $self->{SEARCH_FIELDS} =~ /ccs_m\./ ) {
        $EXT_TABLES .= "\n LEFT JOIN cablecat_color_schemes ccs_m ON (ccs_m.id=cct.modules_color_scheme_id)";
      }
      if ( $self->{SEARCH_FIELDS} =~ /ccs_f\./ ) {
        $EXT_TABLES .= "\n LEFT JOIN cablecat_color_schemes ccs_f ON (ccs_f.id=cct.color_scheme_id)"
      }
    }
    if ($self->{SEARCH_FIELDS} =~ / (?:d|s|b)\./){
      
      # Join maps points if hasn't joined yet
      if ($EXT_TABLES !~ 'LEFT JOIN maps_points mp'){
        $EXT_TABLES .= "\n LEFT JOIN maps_points mp ON (cc.point_id=mp.id)";
      }
      
      $EXT_TABLES .= qq{
        LEFT JOIN builds    b ON (b.id=mp.location_id)
        LEFT JOIN streets   s ON (s.id=b.street_id)
        LEFT JOIN districts d ON (d.id=s.district_id)
      };
    }
    
    {
      FROM => "cablecat_cables cc $EXT_TABLES"
    }
  };
  
  return $self->_cablecat_list('cables', $attr);
}

#**********************************************************
=head2 cable_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub cable_types_list {
  my ($self, $attr) = @_;
  
 $attr->{SEARCH_COLUMNS} = [
    [ 'ID',              'INT', 'cct.id',                   1 ],
    [ 'NAME',            'STR', 'cct.name',                 1 ],
    [ 'COLOR_SCHEME',    'STR', 'ccs.name AS color_scheme', 1 ],
    [ 'COMMENTS',        'STR', 'cct.comments',             1 ],
    [ 'FIBERS_COUNT',    'INT', 'cct.fibers_count',         1 ],
    [ 'MODULES_COUNT',   'INT', 'cct.modules_count',        1 ],
    [ 'COLOR_SCHEME_ID', 'INT', 'cct.color_scheme_id ',     1 ],
    [ 'OUTER_COLOR',     'STR', 'cct.outer_color',          1 ],
    [ 'LINE_WIDTH',      'INT', 'cct.line_width',           1 ],

 ];
  
  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = $self->get_join_sql('cct', 'cablecat_color_schemes', 'ccs', 'color_scheme_id', 'id', {CHECK_SEARCH_FIELDS => 1});
    {
      FROM => "cablecat_cable_types cct $EXT_TABLES"
    }
  };
  
  return $self->_cablecat_list('cable_types cct', $attr);
}

#**********************************************************
=head2 color_schemes_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub color_schemes_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',     'INT', 'id',     1 ],
    [ 'NAME',   'STR', 'name',   1 ],
    [ 'COLORS', 'STR', "colors", 1 ],
  ];
  
  return $self->_cablecat_list('color_schemes', $attr);
}

#**********************************************************
=head2 splitter_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub splitter_types_list{
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    ['ID',             'INT',      'id'                       ,1 ],
    ['NAME',           'STR',      'name'                     ,1 ],
    ['FIBERS_IN',      'INT',      "fibers_in"                ,1 ],
    ['FIBERS_OUT',     'INT',      "fibers_out"               ,1 ],
  ];
  
  return $self->_cablecat_list('splitter_types', $attr);
}

#**********************************************************
=head2 connecter_types_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub connecter_types_list{
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    ['ID',             'INT',        'id'                           ,1 ],
    ['NAME',           'STR',        'name'                         ,1 ],
    ['CARTRIDGES',     'INT',        'cartridges'                   ,1 ],
  ];

  return $self->_cablecat_list('connecter_types', $attr);
}


#**********************************************************
=head2 wells_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub wells_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',         'INT',      'cw.id',                 1 ],
    [ 'NAME',       'STR',      'cw.name',               1 ],
    [ 'TYPE',       'STR',      'cwt.name AS type',      1 ],
    [ 'ICON',       'STR',      'cwt.icon',              1 ],
    [ 'POINT_ID',   'INT',      'cw.point_id',           1 ],
    [ 'TYPE_ID',    'INT',      'cw.type_id',            1 ],
    [ 'PARENT_ID',  'INT',      'cw.parent_id',          1 ],
  ];
  
  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';
  
    $EXT_TABLES .= $self->get_join_sql(
      'cw', 'cablecat_well_types', 'cwt', 'type_id', 'id',
      {CHECK_SEARCH_FIELDS => 1}
    );
    
    {
      FROM => "cablecat_wells cw $EXT_TABLES"
    }
  };
  
  
  return $self->_cablecat_list('wells', $attr);
}

#**********************************************************
=head2 well_types_list($attr) - types for wells

  Arguments:
    $attr -
    
  Returns:
    
    
=cut
#**********************************************************
sub well_types_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',       'INT', 'id',       1 ],
    [ 'NAME',     'STR', 'name',     1 ],
    [ 'ICON',     'STR', 'icon',     1 ],
    [ 'COMMENTS', 'STR', 'comments', 1 ],
  ];
  
  return $self->_cablecat_list('well_types', $attr);
}

#**********************************************************
=head2 connecters_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub connecters_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  

  my $search_columns = [
    [ 'ID',             'INT',        'cw.id'                           ,1 ],
    [ 'NAME',           'STR',        'cw.name'                         ,1 ],
    [ 'TYPE',           'STR',        'cct.name AS connecter_type'      ,1 ],
    [ 'WELL_ID',        'INT',        'cw.parent_id'                    ,'cw.parent_id AS well_id' ],
    [ 'TYPE_ID',        'INT',        'cw.connecter_type_id'            ,1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  
  my $WHERE = $self->search_former( $attr, $search_columns);
  $WHERE = 'AND ' . $WHERE if ($WHERE);
  
  my $EXT_TABLES = '';
  if ($self->{SEARCH_FIELDS} =~ /cct\./){
    $EXT_TABLES .= "LEFT JOIN cablecat_connecter_types cct ON (cw.connecter_type_id=cct.id)";
  }
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} cw.id
   FROM cablecat_wells cw
    $EXT_TABLES
   WHERE type_id=2 $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {} }}
  );
  
  if ($self->{errno}){
    $self->{TOTAL} = -1;
    return [ ]
  };
  
  my $list = $self->{list} || [];
  $self->{TOTAL} = $self->connecters_count();
  return $list;
}

#**********************************************************
=head2 wells_coords($well_id) - coords for well

  Arguments:
    $well_id
    
  Returns:
    hash_ref
     COORDX
     COORDY
    
=cut
#**********************************************************
sub wells_coords {
  my $self = shift;
  my ($well_id) = @_;
  
  $self->query2( "SELECT mc.coordx, mc.coordy
  FROM cablecat_wells cw
  LEFT JOIN maps_points mp ON (cw.point_id=mp.id)
  LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
  WHERE cw.id= ?
  LIMIT 1;", undef, {
      COLS_NAME  => 1,
      COLS_UPPER => 1,
      Bind       => [ $well_id ]
    }
  );
  
  return ($self->{errno}) ? {} : $self->{list}[0];
}

#**********************************************************
=head2 splitters_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub splitters_list{
  my ($self, $attr) = @_;

  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',        'cs.id'                           ,1 ],
    [ 'TYPE',           'STR',        'cst.name AS type'                ,1 ],
    [ 'WELL',           'INT',        'cw.name AS well'                 ,1 ],
    [ 'POINT_ID',       'INT',        'cs.point_id'                     ,1 ],
    [ 'CREATED',        'DATE',       'mp.created'                      ,1 ],
    [ 'PLANNED',        'INT',        'mp.planned'                      ,1 ],
    [ 'INSTALLED',      'INT',        'mp.installed'                    ,1 ],
    [ 'FIBERS_IN',      'STR',        'cst.fibers_in'                   ,1 ],
    [ 'FIBERS_OUT',     'STR',        'cst.fibers_out'                  ,1 ],
    [ 'WELL_ID',        'INT',        'cs.well_id'                      ,1 ],
    [ 'TYPE_ID',        'INT',        'cs.type_id'                      ,1 ],
    [ 'COMMUTATION_ID', 'INT',        'cs.commutation_id'               ,1 ],
    [ 'COMMUTATION_X',  'INT',        'cs.commutation_x'                ,1 ],
    [ 'COMMUTATION_Y',  'INT',        'cs.commutation_y'                ,1 ],

  ];
  
  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';
    
    $EXT_TABLES .= $self->get_join_sql(
      'cs', 'cablecat_splitter_types', 'cst', 'type_id', 'id',
      {CHECK_SEARCH_FIELDS => 1}
    );
  
    $EXT_TABLES .= $self->get_join_sql(
      'cs', 'cablecat_wells', 'cw', 'well_id', 'id',
      {CHECK_SEARCH_FIELDS => 1}
    );
  
    $EXT_TABLES .= $self->get_join_sql(
      'cs', 'maps_points', 'mp', 'point_id', 'id',
      {CHECK_SEARCH_FIELDS => 1}
    );
    
    {
      FROM => "cablecat_splitters cs $EXT_TABLES"
    }
  };
  
  return $self->_cablecat_list('splitters', $attr);
}

#**********************************************************
=head2 links_list($attr) - information what and where is linked

  Arguments:
    $attr -
    
  Returns:
    list
    
=cut
#**********************************************************
sub links_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    ['ID',             'INT',        'id'               ,1 ],
    ['COMMUTATION_ID', 'INT',        'commutation_id'   ,1 ],
    ['ELEMENT_1_ID',   'INT',        'element_1_id'     ,1 ],
    ['ELEMENT_2_ID',   'INT',        'element_2_id'     ,1 ],
    ['ELEMENT_1_TYPE', 'INT',        'element_1_type'   ,1 ],
    ['ELEMENT_1_TYPE', 'INT',        'element_2_type'   ,1 ],
    ['FIBER_NUM_1',    'INT',        'fiber_num_1'      ,1 ],
    ['FIBER_NUM_2',    'INT',        'fiber_num_2'      ,1 ],
    ['ELEMENT_1_SIDE', 'INT',        'element_1_side'   ,1 ],
    ['ELEMENT_2_SIDE', 'INT',        'element_2_side'   ,1 ],
    ['ATTENUATION',    'INT',        'attenuation'      ,1 ],
    ['DIRECTION',      'INT',        'direction'        ,1 ],
    ['COMMENTS',       'STR',        'comments'         ,1 ],
    ['GEOMETRY',       'STR',        'geometry'         ,1 ],
  ];
  
  return $self->_cablecat_list('links', $attr);
}

#**********************************************************
=head2 links_for_element_list($element_type, $element_id)

  Arguments:
    $element_type - string (CABLE, SPLITTER, CLIENT, CROSS, EQUIPMENT)
    $element_id   - int
    
  Returns:
    list
    
=cut
#**********************************************************
sub links_for_element_list {
  my ($self, $element_type, $element_id, $attr) = @_;
  
  my $search_columns = [
    ['ID',             'INT',        'cl.id'               ,1 ],
    ['COMMUTATION_ID', 'INT',        'cl.commutation_id'   ,1 ],
    ['FIBER_NUM_1',    'INT',        'cl.fiber_num_1'      ,1 ],
    ['FIBER_NUM_1',    'INT',        'cl.fiber_num_1'      ,1 ],
    ['ELEMENT_1_SIDE', 'INT',        'cl.element_1_side'   ,1 ],
    ['ELEMENT_2_SIDE', 'INT',        'cl.element_2_side'   ,1 ],
    ['ATTENUATION',    'INT',        'cl.attenuation'      ,1 ],
    ['COMMENTS',       'STR',        'cl.comments'         ,1 ],
    ['DIRECTION',      'INT',        'cl.direction'        ,1 ],
    ['GEOMETRY',       'STR',        'cl.geometry'         ,1 ],
  ];
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE = $self->search_former($attr // {}, $search_columns);
  
  $self->query2("SELECT
     ? AS element_1_type,
     ? AS element_1_id,
     IF( cl.element_1_type=?, cl.element_2_type, cl.element_1_type) AS element_2_type,
     IF( cl.element_1_id=?, cl.element_2_id, cl.element_1_id ) AS element_2_id,
     $self->{SEARCH_FIELDS} cl.id
  FROM cablecat_links cl
  WHERE
   (cl.element_1_type=? OR cl.element_2_type=?)
     AND
   (cl.element_1_id=? OR cl.element_2_id=?) " . ($WHERE ? "AND $WHERE" : ''),
    undef,
    {
      COLS_NAME => 1,
      Bind      => [
        $element_type, $element_id,
        $element_type, $element_id,
        $element_type, $element_type,
        $element_id, $element_id
      ]
    }
  );
  
  return $self->{list} || [];
}

#**********************************************************
=head2 has_link_for_elements_fiber($element_type, $element_id, $fiber_num) -

  Arguments:
    $element_type -
    $element_id   -
    $fiber_num    -
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_link_for_elements_fiber {
  my ($self, $type, $id, $num) = @_;
  
  $self->query2("
  SELECT COUNT(*)
  FROM cablecat_links
  WHERE
   (element_1_type=? OR element_2_type=?)
     AND
   (element_1_id=? OR element_2_id=?)
     AND
   (fiber_num_1=? OR fiber_num_2=?)
     ",
  undef,
    {
      Bind => [ $type, $type, $id, $id, $num, $num ]
    }
  );
  
  if ($self->{errno}){
    return -1;
  }
  
  return $self->{list}[0] || -1;
}

#**********************************************************
=head2 connecters_links_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub connecters_links_list{
  my ($self, $attr) = @_;
  
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'ccl.id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  
  my $search_columns = [
    ['ID',             'INT',    'ccl.id'                                ,1 ],
    ['CONNECTER_1_ID', 'INT',    'ccl.connecter_1 AS connecter_1_id'     ,1 ],
    ['CONNECTER_2_ID', 'INT',    'ccl.connecter_2 AS connecter_2_id'     ,1 ],
    ['CONNECTER_1',    'STR',    'cc1.name AS connecter_1'               ,1 ],
    ['CONNECTER_2',    'STR',    'cc2.name AS connecter_2'               ,1 ],
  ];
  
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  my $EXT_TABLES = '';
  
  if ($self->{SEARCH_FIELDS} =~ /(?:cc1|cc2)\./){
    $EXT_TABLES .= qq{
      LEFT JOIN cablecat_wells cc1 ON (cc1.id=ccl.connecter_1)
      LEFT JOIN cablecat_wells cc2 ON (cc2.id=ccl.connecter_2)
    };
  }
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} ccl.id
   FROM cablecat_connecters_links ccl
   $EXT_TABLES
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
      COLS_NAME => 1,
      %{ $attr ? $attr : {}}}
  );
  
  return [] if $self->{errno};
  
  
  return $self->{list} || [];
}

#**********************************************************
=head2 cross_types_list($attr) -

=cut
#**********************************************************
sub cross_types_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',   'ccrt.id'               ,1 ],
    [ 'NAME',           'STR',   'ccrt.name'             ,1 ],
    [ 'CROSS_TYPE_ID',  'INT',   'ccrt.cross_type_id'    ,1 ],
    [ 'PANEL_TYPE_ID',  'INT',   'ccrt.panel_type_id'    ,1 ],
    [ 'RACK_HEIGHT',    'INT',   'ccrt.rack_height'      ,1 ],
    [ 'PORTS_COUNT',    'INT',   'ccrt.ports_count'      ,1 ],
    [ 'PORTS_TYPE_ID',  'INT',   'ccrt.ports_type_id'    ,1 ],
    [ 'POLISH_TYPE_ID', 'INT',   'ccrt.polish_type_id'   ,1 ],
    [ 'FIBER_TYPE_ID',  'INT',   'ccrt.fiber_type_id'    ,1 ],
  ];
  
  return $self->_cablecat_list('cross_types ccrt', $attr);
}

#**********************************************************
=head2 crosses_list($attr) -

=cut
#**********************************************************
sub crosses_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',        'ccr.id'                           ,1 ],
    [ 'NAME',           'STR',        'ccr.name'                         ,1 ],
    [ 'TYPE',           'STR',        'ccrt.name AS type'                ,1 ],
    [ 'WELL',           'INT',        'cw.name as well'                  ,1 ],
    [ 'POINT_ID',       'INT',        'cw.point_id'                      ,1 ],
    [ 'TYPE_ID',        'INT',        'ccr.type_id'                      ,1 ],
    [ 'WELL_ID',        'INT',        'ccr.well_id'                      ,1 ],
    [ 'CROSS_TYPE_ID',  'INT',        'ccrt.cross_type_id'               ,1 ],
    [ 'PANEL_TYPE_ID',  'INT',        'ccrt.panel_type_id'               ,1 ],
    [ 'RACK_HEIGHT',    'INT',        'ccrt.rack_height'                 ,1 ],
    [ 'PORTS_COUNT',    'INT',        'ccrt.ports_count'                 ,1 ],
    [ 'PORTS_TYPE_ID',  'INT',        'ccrt.ports_type_id'               ,1 ],
    [ 'POLISH_TYPE_ID', 'INT',        'ccrt.polish_type_id'              ,1 ],
    [ 'FIBER_TYPE_ID',  'INT',        'ccrt.fiber_type_id'               ,1 ],
  ];
  
  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';
    
    if ( $self->{SEARCH_FIELDS} =~ /ccrt\./ ) {
      $EXT_TABLES .= qq{
        LEFT JOIN cablecat_cross_types ccrt ON (ccr.type_id=ccrt.id)
      }
    }
  
    if ( $self->{SEARCH_FIELDS} =~ /cw\./ ) {
      $EXT_TABLES .= qq{
        LEFT JOIN cablecat_wells cw ON (ccr.well_id=cw.id)
      }
    }
    
    {
      FROM => "cablecat_crosses ccr $EXT_TABLES"
    }
  };
  
  return $self->_cablecat_list('crosses', $attr);
  
}




#**********************************************************
=head2 set_cable_well_link($cable_id, $first_well, $second_well) - Sets two wells for a cable

  Arguments:
    $cable_id    - cable to operate with
    $first_well  - first well for link
    $second_well - second well for link
    
  Returns:
    1 - if success
    
=cut
#**********************************************************
sub set_cable_well_link {
  my ($self, $cable_id, $first_well_id, $second_well_id) = @_;
  
  $self->query2("SELECT id, well_1, well_2 FROM cablecat_cables WHERE id=? ", undef, { Bind => [ $cable_id ], COLS_NAME => 1 });
  return 0 if $self->{errno} || !defined $self->{list}[0];
  
  my $cable = $self->{list}[0];
  
  # Already linked
  return 0 if ($cable->{well_1} && $cable->{well_2});
  
  $self->changes2( {
    CHANGE_PARAM => 'ID',
    TABLE        =>  'cablecat_cables',
    DATA         => {
      ID     => $cable_id,
      WELL_1 => $first_well_id,
      WELL_2 => $second_well_id
    },
  });
  
  return 1;
}

#**********************************************************
=head2 break_cable($cable_id, $well_id) - breaks cable in 2 parts

  Arguments:
    $cable_id - Cable to operate with
    $well_id  - New well (optional)
    
  Returns:
     array( $cable_id, $cable_id ) - two new cables id
    
=cut
#**********************************************************
sub break_cable {
  my ($self, $cable_id, $middle_well_id) = @_;
  
  return 'Wrong coords' unless ($cable_id);
  
  # Get current
  $self->query2("SELECT id, name, type_id, well_1, well_2, point_id FROM cablecat_cables WHERE id=? ", undef,
    { Bind => [ $cable_id ], COLS_NAME => 1, COLS_UPPER => 1 });
  return qq{Cant find cable $cable_id} if ($self->{errno} || !defined $self->{list}->[0]);
  
  my $cable = $self->{list}->[0];
  # Storing only params
  delete $cable->{ID};
  
  # In transaction, add two new cables and delete old one
  my DBI $db = $self->{db}->{db};
  $db->{AutoCommit} = 0;
  $self->{db}->{TRANSACTION} = 1;
  
  # Rollback transaction and return error string
  my $exit_with_error = sub {
    $db->rollback();
    $db->{AutoCommit} = 1;
    return $_[0];
  };

  $self->query_add('cablecat_cables', {
      %{$cable},
      NAME   => $cable->{name} . '_a',
      WELL_1 => $cable->{well_1},
      WELL_2 => $middle_well_id
    });
  
  # Check for errors and save new id
  $exit_with_error->('Can\'t add new cable 1') if $self->{errno} || !$self->{INSERT_ID};
  my $first_new_id = $self->{INSERT_ID};
  
  $self->query_add('cablecat_cables', {
      %{$cable},
      NAME   => $cable->{name} . '_b',
      WELL_1 => $middle_well_id,
      WELL_2 => $cable->{well_2}
    });
  # Check for errors and save new id
  $exit_with_error->('Can\'t add new cable 2') if $self->{errno} || !$self->{INSERT_ID};
  my $second_new_id = $self->{INSERT_ID};
  
  $self->query_del('cablecat_cables', { ID => $cable_id });
  $exit_with_error->('Can\'t delete old cable') if $self->{errno};
  
  $db->commit();
  $db->{AutoCommit} = 1;
  
  # M aybe somewhere upper we nee this walue
  $cable->{ID} = $cable_id;
  
  return [ $cable, $first_new_id, $second_new_id ];
}

#**********************************************************
=head2 get_cables_for_well($well_id) - Get list of all cables for well

  Arguments:
    $attr - hash_ref
      WELL_ID - int
    
  Returns:
    list [{id, name, well_1, well_2}] - cables
    
=cut
#**********************************************************
sub get_cables_for_well {
  my ($self, $attr) = @_;
  
  my $well_id = $attr->{WELL_ID} || return [];
  
  if ($attr->{SHORT}) {
    $self->query2( qq{
      SELECT id, name, well_1 AS well_1_id, well_2 AS well_2_id
      FROM cablecat_cables
      WHERE (well_1=? OR well_2=?)
    }, undef, { Bind => [ $well_id, $well_id ], COLS_NAME => 1 } );
  }
  else {
    $self->query2( qq{
      SELECT cc.id, cc.name, cc.well_1 AS well_1_id, cc.well_2 AS well_2_id, cw1.name AS well_1, cw2.name AS well_2
      FROM cablecat_cables cc
      LEFT JOIN cablecat_wells cw1 ON (cc.well_1=cw1.id)
      LEFT JOIN cablecat_wells cw2 ON (cc.well_2=cw2.id)
      WHERE (cc.well_1=? OR cc.well_2=?)
     }, undef, { Bind => [ $well_id, $well_id ], COLS_NAME => 1 } );
  }
  return [] if $self->{errno};
  
  return $self->{list} || [];
}

#**********************************************************
=head2 commutations_add($attr) - Add commutation scheme and cables in scheme

  Arguments:
    $attr -
    
  Returns:
    1
    
=cut
#**********************************************************
sub commutations_add {
  my ($self, $attr) = @_;
  
  $self->query_add( 'cablecat_commutations', $attr );
  
  return 0 if $self->{errno};
  
  my $new_id = $self->{INSERT_ID};
  if ( $attr->{CABLE_IDS} && $new_id ) {
    my @cable_ids = split(/, ?/, $attr->{CABLE_IDS});
    $self->query2( "INSERT INTO cablecat_commutation_cables (commutation_id, connecter_id, cable_id)
        VALUES (?, ?, ?);",
      undef,
      { MULTI_QUERY => [ map { [ $new_id, $attr->{CONNECTER_ID}, $_ ] } @cable_ids ] } );
  }
  
  return !defined $self->{errno};
}


#**********************************************************
=head2 commutations_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub commutations_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['ID',             'INT',        'cc.id'                                                ,1 ],
    ['CONNECTER_ID',   'STR',        'cc.connecter_id'                                      ,1 ],
    ['CONNECTER',      'STR',        'ccon.name as connecter'                               ,1 ],
    ['WELL',           'STR',        'cw.name as well'                                      ,1 ],
    ['WELL_ID',        'INT',        'ccon.parent_id as well_id'                            ,1 ],
    ['CABLE_IDS',      'STR',        'cmc.cable_id', 'GROUP_CONCAT(cmc.cable_id) AS cable_ids' ],
    ['CABLES',         'STR',        'GROUP_CONCAT(ccab.name) AS cables'                    ,1 ],
    ['CREATED',        'DATE',       'cc.created'                                           ,1 ],
  ];
  
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  my $EXT_TABLES = '';
  my $EXT_GROUP  = '';
  
  my $join_cables = $self->get_join_sql(
    'cmc', 'cablecat_cables', 'ccab', 'cable_id', 'id',
    {CHECK_SEARCH_FIELDS => 1}
  );
  my $join_commutation_cables = $self->get_join_sql(
    'cc', 'cablecat_commutation_cables', 'cmc',  'id', 'commutation_id',
    {CHECK_SEARCH_FIELDS => ($join_cables ? 0 : 1)}
  );
  
  if ($join_cables || $join_commutation_cables){
    $EXT_TABLES .= $join_commutation_cables;
    $EXT_TABLES .= $join_cables;
    $EXT_GROUP .= 'GROUP BY cmc.commutation_id'
  }
  
  $EXT_TABLES .= $self->get_join_sql(
    'cc', 'cablecat_wells', 'ccon', 'connecter_id', 'id',
    {CHECK_SEARCH_FIELDS => 1}
  );
  
  $EXT_TABLES .= $self->get_join_sql(
    'ccon', 'cablecat_wells', 'cw', 'parent_id', 'id',
    {CHECK_SEARCH_FIELDS => 1}
  );
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} cc.id
   FROM cablecat_commutations cc
   $EXT_TABLES
   $WHERE
   $EXT_GROUP
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list} // [];
}

#**********************************************************
=head2 commutation_cables_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub commutation_cables_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'commutation_id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['COMMUTATION_ID',     'INT',    'comcab.commutation_id'     ,1 ],
    ['CONNECTER_ID',       'INT',    'comcab.connecter_id'       ,1 ],
    ['CONNECTER',          'INT',    'cw.name AS connecter'    ,1 ],
    ['CABLE_ID',           'INT',    'comcab.cable_id'           ,1 ],
    ['CABLE_NAME',         'STR',    'cc.name AS cable_name'     ,1 ],
  ];
  
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  
  my $EXT_TABLES = '';
  if ($self->{SEARCH_FIELDS} =~ /cc\./){
    $EXT_TABLES = "LEFT JOIN cablecat_cables cc ON (comcab.cable_id = cc.id)"
  }
  
  if ($self->{SEARCH_FIELDS} =~ /cw\./){
    $EXT_TABLES = "LEFT JOIN cablecat_wells cw ON (comcab.connecter_id = cw.id)"
  }
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} comcab.commutation_id
   FROM cablecat_commutation_cables comcab
   $EXT_TABLES
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    %{ $attr ? $attr : {}}}
  );

  return [] if $self->{errno};

  return $self->{list} || [];
}

#**********************************************************
=head2 commutation_links_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub commutation_links_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['ID',             'INT',        'id'               ,1 ],
    ['COMMUTATION_ID', 'INT',        'commutation_id'   ,1 ],
    
    ['CABLE_ID_1',     'INT',        'cable_id_1'       ,1 ],
    ['FIBER_NUM_1',    'INT',        'fiber_num_1'      ,1 ],
    ['CABLE_SIDE_1',   'INT',        'cable_side_1'     ,1 ],
    
    ['CABLE_ID_2',     'INT',        'cable_id_2'       ,1 ],
    ['FIBER_NUM_2',    'INT',        'fiber_num_2'      ,1 ],
    ['CABLE_SIDE_2'  , 'INT',        'cable_side_2'     ,1 ],
    
    ['ATTENUATION',    'INT',        'attenuation'      ,1 ],
    ['DIRECTION',      'INT',        'direction'        ,1 ],
    ['COMMENTS',       'STR',        'comments'         ,1 ],
    ['GEOMETRY',       'STR',        'geometry'         ,1 ],
  ];
  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1 });
  my @BIND_VALUES = ();
  
  if ($attr->{CABLE_IDS} && ref $attr->{CABLE_IDS} eq 'ARRAY') {
    my @cable_ids = @{$attr->{CABLE_IDS}};
    $WHERE .= ($WHERE) ? ' AND ' : ' WHERE ';
    my $bind_placeholders = join (',', map { '?' } @cable_ids );
  
    $WHERE .= "cable_id_1 IN ( $bind_placeholders ) OR cable_id_2 IN ( $bind_placeholders )";
    push(@BIND_VALUES, @cable_ids, @cable_ids);
  }
  
  $self->query2( "SELECT $self->{SEARCH_FIELDS} id
   FROM cablecat_commutation_links
   $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;", undef, {
    COLS_NAME => 1,
    Bind      =>  \@BIND_VALUES ,
    %{ $attr ? $attr : {}}}
  );
  
  if ($self->{errno}){
    $self->{TOTAL} = -1;
    return [ ]
  };
  
  my $list = $self->{list} || [];
  $self->{TOTAL} = $self->commutation_links_count();
  return $list;
}

#**********************************************************
=head2 commutation_equipment_ids($commutation_id) - returns ids of all equipment existing on commutation

  Arguments:
     $commutation_id - (optionally) filter by commutation
    
  Returns:
    array_ref
    
=cut
#**********************************************************
sub commutation_equipment_ids {
  my ($self, $commutation_id ) = @_;
  
  my $WHERE = '';
  my @BIND = ();
  
  if ($commutation_id){
    $WHERE = 'WHERE id=?';
    push @BIND, $commutation_id;
  }
  
  $self->query2("SELECT nas_id FROM cablecat_commutation_equipment $WHERE;");
  
  # MAYBE: if will receive error for no [0] element, should additionaly use grep
  my @ids_list = map { $_->[0] } @{$self->{list} || []};
  
  return wantarray ? @ids_list : \@ids_list;
}

#**********************************************************
=head2 commutation_equipment_list($attr) -

=cut
#**********************************************************
sub commutation_equipment_list {
  my ($self, $attr) = @_;
  
  $attr->{SEARCH_COLUMNS} = [
    [ 'ID',             'INT',        'ce.id'                          ,1 ],
    [ 'NAS_ID',         'STR',        'ce.nas_id'                      ,1 ],
    [ 'MODEL_ID',       'STR',        'eq.model_id'                    ,1 ],
    [ 'MODEL_NAME',     'STR',        'em.model_name'                  ,1 ],
    [ 'PORTS',          'STR',        'em.ports'                       ,1 ],
    [ 'COMMUTATION_ID', 'INT',        'ce.commutation_id'              ,1 ],
    [ 'COMMUTATION_X',  'INT',        'ce.commutation_x'               ,1 ],
    [ 'COMMUTATION_Y',  'INT',        'ce.commutation_y'               ,1 ],
  ];
  
  $attr->{SEARCH_FIELDS_FILTER} = sub {
    my $EXT_TABLES = '';
    
    $EXT_TABLES .= $self->get_join_sql(
      'ce', 'equipment_infos', 'eq', 'nas_id', 'nas_id',
      {CHECK_SEARCH_FIELDS => 1}
    );
    
    $EXT_TABLES .= $self->get_join_sql(
      'eq', 'equipment_models', 'em', 'model_id', 'id',
      {CHECK_SEARCH_FIELDS => 1}
    );
    
    {
      FROM => "cablecat_commutation_equipment ce $EXT_TABLES"
    }
  };
  
  return $self->_cablecat_list('commutation_equipment', $attr);
}

#**********************************************************
=head2 _cablecat_list($attr)

  Abstracts code for list

  Arguments :
    $attr - list attr
      SEARCH_COLUMNS - search_columns
  
  Returns :
    $list

  Side effects:
    writes TOTAL to $self

=cut
#**********************************************************
sub _cablecat_list{
  my ($self, $entity, $attr) = @_;
  
  my $SORT = $attr->{SORT} || '1';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  if (!$attr->{PAGE_ROWS} && exists $self->{conf}{CABLECAT_LIST_SIZE} && $self->{conf}{CABLECAT_LIST_SIZE}){
    $PAGE_ROWS = $self->{conf}{CABLECAT_LIST_SIZE};
  }
  
  my @search_columns = @{ $attr->{SEARCH_COLUMNS} ? $attr->{SEARCH_COLUMNS} : [] };
  
  if ( $attr->{SHOW_ALL_COLUMNS} ) {
    map { $attr->{$_->[0]} = '_SHOW' unless (exists $attr->{$_->[0]}) } @search_columns;
  }
  elsif (!exists($attr->{ID}) && $search_columns[0] && $search_columns[0][0] eq 'ID') {
    $attr->{ID} = '_SHOW';
  }
  
  my $WHERE = $self->search_former( $attr, \@search_columns,  { WHERE => 1 } );
  
  # Removing last comma symbol
  $self->{SEARCH_FIELDS} =~ s/, $//;
  
  # Calls back
  my $FROM = '';
  # Allows to apply new JOIN regarding to search fields
  if (defined $attr->{SEARCH_FIELDS_FILTER}){
    my $attr2 = $attr->{SEARCH_FIELDS_FILTER}->();
    $FROM       = "FROM $attr2->{FROM}" if exists $attr2->{FROM};
  }
  else {
    $FROM = 'FROM cablecat_' . $entity;
  }
  
  # Get total
  $self->query2("SELECT COUNT(*) $FROM $WHERE");
  
  if ( $self->{errno} ) {
    $self->{TOTAL} = -1;
    return [ ];
  }
  
  my $total = $self->{list}->[0]->[0];
  
  # Get list
  $self->query2( "SELECT $self->{SEARCH_FIELDS} $FROM
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;"
    , undef, {
      COLS_NAME => 1,
      %{ $attr ? $attr : { }}
    });
  
  $self->{TOTAL} = $total;
  
  return $self->{list} || [];
}

sub DESTROY{};
1;