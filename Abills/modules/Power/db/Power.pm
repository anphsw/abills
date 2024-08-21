package Power::db::Power;

=head1 NAME

  Power

=head1 SYNOPSIS

  use Power::db::Power;

  my $Power = Power::db::Power->new($db, $admin, \%conf);

=cut

use strict;
our $VERSION = 0.01;
use parent qw(dbcore);

my ($admin, $CONF);

#**********************************************************
=head2 function new()

  Returns:
    $self object

  Examples:
    my $Power = Power::db::Power->new($db, $admin, \%conf);

=cut
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 function power_genset_type_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_type_add({%FORM});

=cut
#**********************************************************
sub power_genset_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_genset_types', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_types_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_genset_types_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_genset_types_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',              'INT',   'pgt.id',                   1 ],
    [ 'NAME',            'STR',   'pgt.name',                 1 ],
    [ 'DESCRIPTION',     'STR',   'pgt.description',          1 ],
    [ 'LITRES_PER_HOUR', 'INT',   'pgt.litres_per_hour',      1 ],
    [ 'PHASE',           'INT',   'pgt.phase',                1 ],
    [ 'POWER_KVA',       'INT',   'pgt.power_kva',            1 ],
    [ 'POWER_KW',        'INT',   'pgt.power_kw',             1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pgt.id
      FROM power_genset_types pgt
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_genset_types pgt
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_genset_type_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_genset_type_del({ ID => 1 });

=cut
#**********************************************************
sub power_genset_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_genset_types', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_type_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_genset_type_info({ ID => 1 });

=cut
#**********************************************************
sub power_genset_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_genset_types WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_genset_type_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_type_change({%FORM});

=cut
#**********************************************************
sub power_genset_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_genset_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function power_fueltank_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_fueltank_add(\%FORM);

=cut
#**********************************************************
sub power_fueltank_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_fueltanks', $attr);

  return $self;
}

#**********************************************************
=head2 function power_fueltanks_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_fueltanks_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_fueltanks_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',              'INT',   'pf.id',          1 ],
    [ 'NAME',            'STR',   'pf.name',        1 ],
    [ 'DESCRIPTION',     'STR',   'pf.description', 1 ],
    [ 'LITRES',          'INT',   'pf.litres',      1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pf.id
      FROM power_fueltanks pf
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_fueltanks pf
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_fueltank_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_fueltank_del({ ID => 1 });

=cut
#**********************************************************
sub power_fueltank_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_fueltanks', $attr);

  return $self;
}

#**********************************************************
=head2 function power_fueltank_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_fueltank_info({ ID => 1 });

=cut
#**********************************************************
sub power_fueltank_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_fueltanks WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_fueltank_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_fueltank_change({%FORM});

=cut
#**********************************************************
sub power_fueltank_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_fueltanks',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function power_service_type_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_service_type_add(\%FORM);

=cut
#**********************************************************
sub power_service_type_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_service_types', $attr);

  return $self;
}

#**********************************************************
=head2 function power_service_types_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_service_types_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_service_types_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',              'INT',   'pst.id',          1 ],
    [ 'NAME',            'STR',   'pst.name',        1 ],
    [ 'DESCRIPTION',     'STR',   'pst.description', 1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pst.id
      FROM power_service_types pst
      $WHERE
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_service_types pst
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_service_type_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_service_type_del({ ID => 1 });

=cut
#**********************************************************
sub power_service_type_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_service_types', $attr);

  return $self;
}

#**********************************************************
=head2 function power_service_type_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_service_type_info({ ID => 1 });

=cut
#**********************************************************
sub power_service_type_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_service_types WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_service_type_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_service_type_change({%FORM});

=cut
#**********************************************************
sub power_service_type_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_service_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function power_genset_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_add(\%FORM);

=cut
#**********************************************************
sub power_genset_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_gensets', $attr);

  return $self;
}

#**********************************************************
=head2 function power_gensets_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_gensets_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_gensets_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT',   'pg.id',          1 ],
    [ 'ADDRESS_FULL',     'STR',   "CONCAT_WS(', ', GROUP_CONCAT(DISTINCT dfp.name ORDER BY dfp.path SEPARATOR ', '), s.name, b.number) AS address_full",    1 ],
    [ 'STATE',        'INT',   'pg.state',       1 ],
    [ 'LAST_START',   'STR',   'MAX(pgr.start_date) as last_start',       1 ],
    [ 'TYPE_ID',      'INT',   'pg.type_id',     1 ],
    [ 'TYPE',         'STR',   'pgt.name', 'pgt.name AS type', 1 ],
    [ 'BUILD_ID',     'INT',   'pg.build_id',    1 ],
    [ 'FUELTANK_ID',  'INT',   'pg.fueltank_id', 1 ],
    [ 'FUELTANK',     'STR',   'pf.name', 'pf.name AS fueltank', 1 ],
    [ 'FUEL_LITRES',     'STR',   'pf.litres', 'pf.litres AS fuel_litres', 1 ],
    [ 'LITRES',       'INT',   'pg.litres',      1 ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pg.id
      FROM power_gensets pg
      LEFT JOIN power_genset_types pgt ON (pgt.id = pg.type_id)
      LEFT JOIN power_fueltanks pf ON (pf.id = pg.fueltank_id)
      LEFT JOIN builds b ON b.id = pg.build_id
      LEFT JOIN streets s ON s.id = b.street_id
      LEFT JOIN districts d ON d.id = s.district_id
      LEFT JOIN districts AS dfp ON FIND_IN_SET(dfp.id, REPLACE(d.path, '/', ',')) > 0
      LEFT JOIN power_genset_runs pgr ON pgr.genset_id = pg.id
      $WHERE
      GROUP BY pg.id
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_gensets pg
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_genset_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_genset_del({ ID => 1 });

=cut
#**********************************************************
sub power_genset_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_gensets', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_genset_info({ ID => 1 });

=cut
#**********************************************************
sub power_genset_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_gensets WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_genset_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_change({%FORM});

=cut
#**********************************************************
sub power_genset_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{STATE} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_gensets',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function power_genset_run_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_run_add({%FORM});

=cut
#**********************************************************
sub power_genset_run_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_genset_runs', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_runs_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_genset_runs_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_genset_runs_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',              'INT',   'pgr.id',                   1 ],
    [ 'GENSET_ID', 'INT',   'pgr.genset_id',      1 ],
    [ 'ADDRESS_FULL',      'STR',   "CONCAT_WS(', ', GROUP_CONCAT(DISTINCT dfp.name ORDER BY dfp.path SEPARATOR ', '), s.name, b.number) AS address_full",    1 ],
    [ 'TYPE',              'STR',   'pgt.name', 'pgt.name AS type', 1 ],
    [ 'START_DATE',           'DATE',   'pgr.start_date',                1 ],
    [ 'STOP_DATE',       'DATE',   'pgr.stop_date',            1 ],
    [ 'TYPE_ID',        'INT',   'pgr.type_id',             1 ],
    [ 'RESULT',        'INT',   'pgr.result',             1 ],
    [ 'STATE',        'INT',   'pg.state',       1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE',  "DATE_FORMAT(pgr.start_date, '%Y-%m-%d')" ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pgr.id
      FROM power_genset_runs pgr
      LEFT JOIN power_gensets pg ON pg.id = pgr.genset_id
      LEFT JOIN power_genset_types pgt ON (pgt.id = pg.type_id)
      LEFT JOIN builds b ON b.id = pg.build_id
      LEFT JOIN streets s ON s.id = b.street_id
      LEFT JOIN districts d ON d.id = s.district_id
      LEFT JOIN districts AS dfp ON FIND_IN_SET(dfp.id, REPLACE(d.path, '/', ',')) > 0
      $WHERE
      GROUP BY pgr.id
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_genset_runs pgr
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_genset_run_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_genset_run_del({ ID => 1 });

=cut
#**********************************************************
sub power_genset_run_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_genset_runs', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_run_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_genset_run_info({ ID => 1 });

=cut
#**********************************************************
sub power_genset_run_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_genset_runs WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_genset_run_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_run_change({%FORM});

=cut
#**********************************************************
sub power_genset_run_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_genset_runs',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function power_genset_service_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_service_add({%FORM});

=cut
#**********************************************************
sub power_genset_service_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_genset_services', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_services_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_genset_services_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_genset_services_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',                'INT',   'pgs.id',                       1 ],
    [ 'GENSET_ID',         'INT',   'pgs.genset_id',                1 ],
    [ 'ADDRESS_FULL',      'STR',   "CONCAT_WS(', ', GROUP_CONCAT(DISTINCT dfp.name ORDER BY dfp.path SEPARATOR ', '), s.name, b.number) AS address_full",    1 ],
    [ 'TYPE',              'STR',   'pgt.name', 'pgt.name AS type', 1 ],
    [ 'SERVICE_DATE',      'DATE',  'pgs.service_date',             1 ],
    [ 'SERVICE_NAME',      'STR',   'pst.name AS service_name',     1 ],
    [ 'SERVICE_TYPE_ID',   'INT',   'pgs.service_type_id',          1 ],
    [ 'DESCRIPTION',       'STR',   'pgs.description',              1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE',  "DATE_FORMAT(pgs.service_date, '%Y-%m-%d')" ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pgs.id
      FROM power_genset_services pgs
      LEFT JOIN power_service_types pst ON pst.id = pgs.service_type_id
      LEFT JOIN power_gensets pg ON pg.id = pgs.genset_id
      LEFT JOIN power_genset_types pgt ON (pgt.id = pg.type_id)
      LEFT JOIN builds b ON b.id = pg.build_id
      LEFT JOIN streets s ON s.id = b.street_id
      LEFT JOIN districts d ON d.id = s.district_id
      LEFT JOIN districts AS dfp ON FIND_IN_SET(dfp.id, REPLACE(d.path, '/', ',')) > 0
      $WHERE
      GROUP BY pgs.id
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_genset_services pgs
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_genset_service_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_genset_service_del({ ID => 1 });

=cut
#**********************************************************
sub power_genset_service_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_genset_services', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_service_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_genset_service_info({ ID => 1 });

=cut
#**********************************************************
sub power_genset_service_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_genset_services WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_genset_service_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_service_change({%FORM});

=cut
#**********************************************************
sub power_genset_service_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_genset_services',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function power_genset_refuel_add()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_refuel_add({%FORM});

=cut
#**********************************************************
sub power_genset_refuel_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('power_genset_refuels', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_refuels_list()

  Arguments:
    $attr

  Returns:
    \@list -
  Examples:
    my $list = $Power->power_genset_refuels_list({COLS_NAME=>1});

=cut
#**********************************************************
sub power_genset_refuels_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = $attr->{PG} ? $attr->{PG} : 0;
  my $PAGE_ROWS = $attr->{PAGE_ROWS} ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT',   'pgf.id',             1 ],
    [ 'GENSET_ID',     'INT',   'pgf.genset_id',      1 ],
    [ 'DATE',          'DATE',  'pgf.date',     1 ],
    [ 'ADDRESS_FULL',      'STR',   "CONCAT_WS(', ', GROUP_CONCAT(DISTINCT dfp.name ORDER BY dfp.path SEPARATOR ', '), s.name, b.number) AS address_full",    1 ],
    [ 'TYPE',              'STR',   'pgt.name', 'pgt.name AS type', 1 ],
    [ 'GENSET_LITRES', 'INT',   'pg.litres AS genset_litres', 1 ],
    [ 'LITRES',        'INT',   'pgf.litres',         1 ],
    [ 'LITRES_BEFORE', 'INT',   'pgf.litres_before',  1 ],
    [ 'LITRES_AFTER',  'INT',   'pgf.litres_after',   1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE',  "DATE_FORMAT(pgf.date, '%Y-%m-%d')" ],
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} pgf.id
      FROM power_genset_refuels pgf
      LEFT JOIN power_gensets pg ON pg.id = pgf.genset_id
      LEFT JOIN power_genset_types pgt ON (pgt.id = pg.type_id)
      LEFT JOIN builds b ON b.id = pg.build_id
      LEFT JOIN streets s ON s.id = b.street_id
      LEFT JOIN districts d ON d.id = s.district_id
      LEFT JOIN districts AS dfp ON FIND_IN_SET(dfp.id, REPLACE(d.path, '/', ',')) > 0
      $WHERE
      GROUP BY pgf.id
      ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  my $list = $self->{list} || [];

  $self->query("SELECT COUNT(*) AS total FROM power_genset_refuels pgf
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 function power_genset_refuel_del()

  Arguments:
    $attr

  Returns:

  Examples:
    $Power->power_genset_refuel_del({ ID => 1 });

=cut
#**********************************************************
sub power_genset_refuel_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('power_genset_refuels', $attr);

  return $self;
}

#**********************************************************
=head2 function power_genset_refuel_info()

  Arguments:
    $attr
      id  - type identifier

  Returns:
    $self object

  Examples:
    $Power->power_genset_refuel_info({ ID => 1 });

=cut
#**********************************************************
sub power_genset_refuel_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM power_genset_refuels WHERE id= ? ;",
    undef,
    {
      INFO => 1,
      Bind => [ $attr->{ID} ]
    }
  );

  return $self;
}

#**********************************************************
=head2 function power_genset_refuel_change()

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Power->power_genset_refuel_change({%FORM});

=cut
#**********************************************************
sub power_genset_refuel_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'power_genset_refuels',
    DATA         => $attr
  });

  return $self;
}

1;