package Employees;

=head1 NAME

  Employees - module for Employees configuration

=head1 SYNOPSIS

  use Employees;
  my $Employees = Employees->new($db, $admin, \%conf);

=cut

use strict;
use parent 'dbcore';
my ($admin, $CONF);


#*******************************************************************
=head2 new() - initialization

=cut
#*******************************************************************
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

#*******************************************************************
=head2 position_add() - add rule to table ring_rule

  Arguments:
    %$attr
      NAME             - position's name;
      SUBORDINATION    - the higher postion;

  Returns:
    $self object

  Examples:
    $Employees->position_add({
      NAME             => $FORM{NAME},
      SUBORDINATION    => $FORM{SUBORDINATION},
    });

=cut

#*******************************************************************
sub position_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_positions', {%$attr});

  return $self;
}

#*******************************************************************

=head2 position_del () - delete position from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->position_del( {ID => 1} );

=cut

#*******************************************************************
sub position_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_positions', $attr);

  return $self;
}


#**********************************************************

=head2 function position_list() - get articles list

  Arguments:
    $attr
      SUBORDINATION -
  Returns:
    @list

  Examples:
    my $list = $Employees->position_list({COLS_NAME=>1});

=cut

#**********************************************************
sub position_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{SUBORDINATION})) {
    push @WHERE_RULES, "ep.subordination='$attr->{SUBORDINATION}'";
  }
  my @search_fields = (
    [ 'ID',            'INT',  'ID',               1],
    [ 'POSITION',      'STR',  'position',         1],
    [ 'SUBORDINATED',  'STR',  'subordinated',     1],
    [ 'SUBORDINATION', 'INT',  'subordination',    1],
    [ 'VACANCY',       'INT',  'vacancy',          1],
  );

  my $WHERE = $self->search_former($attr, \@search_fields, {
    WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $sql = <<"SQL";
     SELECT
       ep.id,
       ep.position,
       (SELECT COUNT(id) FROM employees_profile WHERE position_id = ep.id) as total,
       ep.vacancy,
       (SELECT position FROM employees_positions WHERE id = ep.subordination) as subordinated,
       ep.subordination
       FROM employees_positions AS ep
       $WHERE
       ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list_hash} if $attr->{LIST2HASH};

  return $self->{list};
}


#**********************************************************
=head2 position_info() - get position info

  Arguments:
    $attr
      ID - position identifier
  Returns:
    $self object

  Examples:
    my $list = $Employees->position_info({ ID => 1 });

=cut
#**********************************************************
sub position_info {
  my ($self, $attr) = @_;

  if ($attr->{ID}) {
    my $sql = <<'SQL';
    SELECT * FROM employees_positions WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#**********************************************************
=head2 function position_change() - get articles list

  Arguments:
    $attr
      ID            - position identifier;
      POSITION      - position name;
      SUBORDINATION - id of highier position;

  Returns:
    $self object

  Examples:
    my $list = $Employees->position_change({ ID       => 2,
                                             POSITION => "Admin",
                                             SUBORDINATION => 1 });

=cut
#**********************************************************
sub position_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_positions',
    DATA         => $attr
  });

  return $self;
}


#*******************************************************************
=head2 geo_add() - add rule to table ring_rule

  Arguments:
    %$attr
      NAME             - position's name;
      SUBORDINATION    - the higher postion;

  Returns:
    $self object

  Examples:
    $Employees->geo_add({
      STREET_ID          => 1,
      EMPLOYEE_ID        => 2,

    });

=cut
#*******************************************************************
sub geo_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_geolocation', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function geo_del() - delete geolocation from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->geo_del( {EMPLOYEE_ID => 1} );

=cut

#*******************************************************************
sub geo_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_geolocation', undef, {EMPLOYEE_ID => $attr->{EMPLOYEE_ID}});

  return $self;
}


#**********************************************************

=head2 function geo_list() - get geo list

  Arguments:
    $attr
      SUBORDINATION -
  Returns:
    @list

  Examples:
    my $list = $Employees->geo_list({COLS_NAME=>1});

=cut

#**********************************************************
sub geo_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  if (defined($attr->{EMPLOYEE_ID})) {
    push @WHERE_RULES, "eg.employee_id='$attr->{EMPLOYEE_ID}'";
  }

  my $WHERE = $self->search_former($attr, [
   [ 'EMPLOYEE_ID',  'INT',  'eg.employee_id',    1],
   [ 'STREET_ID',    'INT',  'eg.street_id',      1],
   [ 'BUILD_ID',     'INT',  'eg.build_id',       1],
   [ 'DISTRICT_ID',  'INT',  'eg.district_id',    1],
  ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $sql = <<"SQL";
     SELECT eg.employee_id,
            eg.street_id,
            eg.build_id,
            eg.district_id
            FROM employees_geolocation AS eg
            $WHERE
            ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list};
}

#**********************************************************
=head2 employees_geolocation_list()

  Arguments:
    $attr
  Returns:
    @list

  Examples:

=cut
#**********************************************************
sub employees_geolocation_list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'EMPLOYEE_ID',   'INT', 'eg.employee_id',   1 ],
    [ 'STREET_ID',     'INT', 'eg.street_id',     1 ],
    [ 'BUILD_ID',      'INT', 'eg.build_id',      1 ],
    [ 'DISTRICT_ID',   'INT', 'eg.district_id',   1 ]
  ], { WHERE => 1 });

  my $sql = <<"SQL";
    SELECT eg.employee_id, eg.street_id, eg.build_id, eg.district_id,
    SUBSTRING_INDEX(d.path, CONCAT('/', eg.district_id), 1) AS district_path, IF(eg.build_id, s.id, null) AS build_street
    FROM employees_geolocation eg
    LEFT JOIN builds b ON eg.build_id = b.id
    LEFT JOIN streets s ON b.street_id = s.id OR eg.street_id = s.id
    LEFT JOIN districts d ON d.id = s.district_id OR eg.district_id = d.id
    $WHERE
    ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 time_sheet_list()

  Arguments:
    $attr

=cut
#**********************************************************
sub time_sheet_list {
  my ($self, $attr) = @_;
  my @WHERE_RULES;

  if($attr->{DATE_START}){
    push @WHERE_RULES, "ts.date >= '$attr->{DATE_START}'";
  }

  if($attr->{DATE_END}){
   push @WHERE_RULES, "ts.date <= '$attr->{DATE_END}'";
  }

  if($attr->{BY_AID}){
   push @WHERE_RULES, "ts.aid = '$attr->{BY_AID}'"; 
  }

  if($attr->{POSITION} && $attr->{POSITION} ne '_SHOW'){
    push @WHERE_RULES, "a.position = '$attr->{POSITION}'";
  }

  if($attr->{WITH_POSITION} ){
    push @WHERE_RULES, "a.position > 0";
  }

  push(@WHERE_RULES, "a.disable = 0");

  my $WHERE = $self->search_former($attr, [
      ['GID',          'INT',  'a.gid',    ],
      ['POSITION',     'INT',  'a.position',    ],
      ['AID',          'INT',  'ts.aid'    ],
      ['DATE',         'DATE', 'ts.date'   ]
    ],
    { WHERE       => 1,
    }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
     SELECT a.aid, a.name,
      ts.work_time,
      ts.overtime,
      ts.extra_fee,
      ts.day_type,
      ts.date,
      a.position,
      a.id AS a_login
    FROM admins a
    LEFT JOIN admins_time_sheet ts ON (a.aid=ts.aid)
    $WHERE;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $list;
}


#**********************************************************
=head2 time_sheet_add($attr)

=cut
#**********************************************************
sub time_sheet_add {
  my ($self, $attr) = @_;

  my @admins_arr = split(/,\s?/x, $attr->{AIDS});
   my @MULTI_QUERY = ();

  foreach my $aid (@admins_arr) {
    if ( !defined $attr->{$aid.'_WORK_TIME'}
        && !defined $attr->{$aid.'_OVERTIME'}
        && !defined $attr->{$aid.'_EXTRA_FEE'}
        && !defined $attr->{$aid.'_DAY_TYPE'}) {
      next;
    }

    push @MULTI_QUERY, [ $aid,
                         (int($attr->{$aid.'_WORK_TIME'}) > 24) ? 24 : int($attr->{$aid.'_WORK_TIME'}),
                         (int($attr->{$aid.'_OVERTIME'})  > 24) ? 24 : int($attr->{$aid.'_OVERTIME'}),
                         (int($attr->{$aid.'_EXTRA_FEE'}) > 24) ? 24 : int($attr->{$aid.'_EXTRA_FEE'}),
                         int($attr->{$aid.'_DAY_TYPE'}),
                         $attr->{DATE}
                       ];
  }

  my $sql = <<'SQL';
    REPLACE INTO admins_time_sheet (aid, work_time, overtime, extra_fee, day_type, date)
    VALUES (?, ?, ?, ?, ?, ?);
SQL

  $self->query($sql, undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#*******************************************************************
=head2 question_add() - add new question to table employees_profile_question

  Arguments:
    %$attr
      QUESTION    - Question what you add;
      POSITION_ID - Position ID;
      ID          - Question ID;

  Returns:
    $self object

  Examples:
    $Employees->question_add({
      QUESTION           => 'What your name?',
      POSITION_ID        => $FORM{POSITION_ID}
    });

=cut

#*******************************************************************
sub question_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_profile_question', {%$attr});

  return $self;
}

#**********************************************************
=head2 function question_del() - delete question from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->question_del( {ID => 1} );

=cut
#**********************************************************
sub question_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_profile_question', $attr, {ID => $attr->{ID}});
  return $self;
}

#**********************************************************
=head2 function questions_list() - get articles list

  Arguments:
    $attr
      ID - 
  Returns:
    @list

  Examples:
    my $list = $Employees->questions_list({COLS_NAME=>1});

=cut

#**********************************************************
sub questions_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
   [ 'ID',          'INT',  'pq.id',            1],
   [ 'QUESTION',    'STR',  'pq.question',      1],
   [ 'POSITION_ID', 'INT',  'pq.position_id',   1],
   [ 'POSITION',    'STR',   'ep.position',     1],

    ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $sql = <<"SQL";
    SELECT  pq.id,
            pq.position_id,
            ep.position,
            pq.question
            FROM employees_profile_question AS pq
            LEFT JOIN employees_positions AS ep ON ep.id=pq.position_id
            $WHERE
            ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  my $list=$self->{list};
  return  $list || [];
}

#**********************************************************
=head2 function question_change() - 

  Arguments:
    $attr
      QUESTION    - Question what you add;
      POSITION_ID - Position ID;
      ID          - Question ID;

  Returns:
    $self object

  Examples:
    my $list = $Employees->question_change({ ID       => 2,
                                             QUESTION => "What?",
                                             POSITION_ID => 1 });

=cut
#**********************************************************
sub question_change {
  my ($self, $attr) = @_;

  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_profile_question',
      DATA         => $attr
    });

  return $self;
}

#**********************************************************
=head2 function question_info() - get question_info

  Arguments:
    $attr
      ID - question identifier
  Returns:
    $self object

  Examples:
    my $list = $Employees->question_info({ ID => 1 });

=cut
#**********************************************************
sub question_info {
  my ($self, $attr) = @_;

  if ($attr->{ID}) {
    my $sql = <<'SQL';
      SELECT * FROM employees_profile_question
      WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#*******************************************************************
=head2 function profile_add() - add new question to table employees_profile_question

  Arguments:
    %$attr
      POSITION_ID    - Position ID;
      FIO           - ;
      DATE_OF_BIRTH -
      EMAIL         -
      PHONE         -

  Returns:
    $self object

  Examples:
    $Employees->profile_add({
      POSITION_ID   - $FORM{P_ID};
      FIO           - Brolaf Anna Anna;
      DATE_OF_BIRTH -
      EMAIL         - zila@gmail.com
      PHONE         - 380876876
    });

=cut

#*******************************************************************
sub profile_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_profile', {%$attr});

  return $self;
}

#**********************************************************
=head2 function profile_del () - delete profile from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->profile_del( {ID => 1} );

=cut
#**********************************************************
sub profile_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_profile', $attr, {ID => $attr->{ID}});

  return $self;
}

#**********************************************************
=head2 profile_change()

  Arguments:
    $attr
      POSITION_ID   - Position ID;
      FIO           - 
      DATE_OF_BIRTH -
      EMAIL         - 
      PHONE         - 

  Returns:
    $self object

  Examples:
    my $list = $Employees->profile_change({
       POSITION_ID   - $FORM{P_ID};
       FIO           - Brolaf Anna Anna;
       DATE_OF_BIRTH -
       EMAIL         - zila@gmail.com
       PHONE         - 380876876

=cut
#**********************************************************
sub profile_change {
  my ($self, $attr) = @_;

  $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_profile',
      DATA         => $attr
    });

  return $self;
}

#**********************************************************
=head2 function profile_list() - get articles list

  Arguments:
    $attr
      POSITION_ID   - Position ID;
      FIO           - 
      DATE_OF_BIRTH -
      EMAIL         - 
      PHONE         - 
  Returns:
    @list

  Examples:
    my $list = $Employees->profile_list({COLS_NAME=>1});

=cut

#**********************************************************
sub profile_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC        = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $PG          = ($attr->{PG})        ? $attr->{PG}        : 0;


  my $WHERE = $self->search_former($attr, [
   ['ID',           'INT',  'p.id',             1],
   ['POSITION_ID', ' INT',  'p.position_id',    1],
   ['FIO',          'STR',  'p.fio',            1], 
   ['SUBORDINATION','STR',  'ep.subordination', 1],
   ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $sql = <<"SQL";
    SELECT p.id,
            p.fio,
            p.rating,
            ep.position,
            p.phone,
            p.email,
            p.position_id
            FROM employees_profile AS p
            LEFT JOIN employees_positions AS ep ON ep.id=p.position_id
            $WHERE
            ORDER BY $SORT $DESC
            LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

my $list=$self->{list};
return $list;
}

#**********************************************************
=head2 function profile_info() - get position info

  Arguments:
    $attr
      ID - position identifier
  Returns:
    $self object

  Examples:
    my $list = $Employees->profile_info({ ID => 1 });

=cut
#**********************************************************
sub profile_info {
  my ($self, $attr) = @_;

  if ($attr->{ID}) {
    my $sql = <<'SQL';
      SELECT * FROM employees_profile WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#*******************************************************************
=head2 function reply_add() - add new question to table employees_profile_question

  Arguments:
    %$attr
      QUESTION_ID - Question ID;
      PROFILE_ID  -  Profile ID;
      REPLY       - Question reply;

  Returns:
    $self object

  Examples:
    $Employees->reply_add({
      QUESTION_ID           - ;
      PROFILE_ID -
      REPLY 
    });

=cut

#*******************************************************************
sub reply_add{
  my ($self, $attr) = @_;

  $self->query_add('employees_profile_reply', {%$attr});

  return $self;
}

#**********************************************************
=head2 function reply_list() - get articles list

  Arguments:
    $attr
      QUESTION_ID - Question ID;
      PROFILE_ID  -  Profile ID;
      REPLY       - Question reply;
  Returns:
    @list

  Examples:
    my $list = $Employees->reply_list({COLS_NAME=>1});

=cut

#**********************************************************
sub reply_list{
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC        = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
   ['QUESTION_ID',  'INT',  'p.question_id',    1],
   ['PROFILE_ID', '  INT',  'p.profile_id',     1],
   ['REPLY',        'STR',  'p.reply',          1], 
   ],
  { WHERE       => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  my $sql = <<"SQL";
    SELECT p.reply,
           p.profile_id,
           pq.question
           FROM employees_profile_reply AS p
           LEFT JOIN employees_profile_question AS pq ON pq.id = question_id
           $WHERE
           ORDER BY $SORT $DESC
           LIMIT $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list=$self->{list};
  return $list;
}

#**********************************************************
=head2 rfid_log_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub rfid_log_list{
  my ($self, $attr) = @_;
  
  my $SORT = $attr->{SORT} || 'id';
  my $DESC = ($attr->{DESC}) ? '' : 'DESC';
  my $PG = $attr->{PG} || '0';
  my $PAGE_ROWS = $attr->{PAGE_ROWS} || 25;
  
  my $search_columns = [
    ['ID',             'INT',        'erl.id'              ,1 ],
    ['DATETIME',       'DATE',       'erl.datetime'        ,1 ],
    ['RFID',           'INT',        'erl.rfid'            ,1 ],
    ['ADMIN',          'STR',        'a.id AS admin'       ,1 ],
    ['ADMIN_NAME',     'STR',        'a.name AS admin_name',1 ],
    ['AID',            'INT',        'erl.aid AS admin_id' ,1 ]
  ];

  my @WHERE_RULES;
  if($attr->{DATE}){
    push @WHERE_RULES, "DATETIME >= '$attr->{DATE} 00:00:01' && DATETIME <= '$attr->{DATE} 23:59:59'";
  }

  if($attr->{INTERVAL}){
    my ($START_DATE, $END_DATE) = split('/', $attr->{INTERVAL}, 2);
    push @WHERE_RULES, "DATETIME >= '$START_DATE 00:00:01' && DATETIME <= '$END_DATE 23:59:59'";
  }
  
  my $WHERE =  $self->search_former($attr, $search_columns, { WHERE => 1, WHERE_RULES => \@WHERE_RULES });

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} erl.id
    FROM employees_rfid_log erl
    LEFT JOIN admins a ON (erl.aid=a.aid)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, { COLS_NAME => 1, %{ $attr ? $attr : {}}} );

  return [ ] if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $sql = <<"SQL";
      SELECT COUNT(*) AS total FROM employees_rfid_log as erl $WHERE
SQL

    $self->query($sql, undef, { INFO => 1 });
  }

  return $list || [];
}

#*******************************************************************
=head2 function rfid_log_add() - add rfid log entry
  Arguments:
    $attr

  Returns:
   1

=cut
#*******************************************************************
sub rfid_log_add {
  my ($self, $attr) = @_;
  
  $self->query_add('employees_rfid_log', {%$attr});
  
  return $self;
}

#*******************************************************************
=head2 function rfid_log_del() - delete rfid log entry
  Arguments:
    $attr

  Returns:
   1

=cut
#*******************************************************************
sub rfid_log_del {
  my ($self, $attr) = @_;
  
  $self->query_del('employees_rfid_log', $attr);
  
  return 1;
}

#**********************************************************
=head2 daily_note_add() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub daily_note_add {
  my ($self, $attr) = @_;
  $self->query_add('employees_daily_notes', {%$attr});

  return $self;
}

#**********************************************************
=head2 daily_note_del() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub daily_note_del {
  my ($self, $attr) = @_;
  
  $self->query_del('employees_daily_notes', undef, $attr);
  
  return 1;
}


#**********************************************************
=head2 daily_note_info() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub daily_note_info {
  my ($self, $attr) = @_;

  if ($attr->{DAY}) {
    my $sql = <<"SQL";
      SELECT * FROM employees_daily_notes
      WHERE day = ? and aid = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{DAY}, $attr->{AID} ] } );
  }

  return $self;
}

#**********************************************************
=head2 daily_note_change() -

  Arguments:
     -
  Returns:

=cut
#**********************************************************
sub daily_note_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'DAY',
    SECOND_PARAM => 'AID',
    TABLE        => 'employees_daily_notes',
    DATA         => $attr
  });

  return $self;
}
 
#**********************************************************
=head2 employees_vacations_add() -
 
   Arguments:
     attr -
   Returns:
 
   Examples:
 
=cut
#*********************************************************
sub employees_vacations_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_vacations', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function list_coming() - get list of all comings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->list_coming({ COLS_NAME => 1});

=cut
#*******************************************************************
sub employees_vacations_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
      [ 'ID',         'INT', 'ev.id',         1 ],
      [ 'ADMIN',      'STR', 'a.id as admin', 1 ],
      [ 'START_DATE', 'STR', 'ev.start_date', 1 ],
      [ 'END_DATE',   'STR', 'ev.end_date',   1 ],
      [ 'AID',        'INT', 'ev.aid',        1 ],
    ],
    { WHERE => 1, }
  );

  if ($attr->{START_DATE} && $attr->{START_DATE} ne '_SHOW' && $attr->{END_DATE} && $attr->{END_DATE} ne '_SHOW') {
    push @WHERE_RULES, "ev.start_date>='$attr->{START_DATE}' || ev.end_date<='$attr->{END_DATE}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT  $self->{SEARCH_FIELDS} ev.id
    FROM employees_vacations ev
    LEFT JOIN admins a ON (ev.aid=a.aid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_vacations
SQL

  $self->query($sql, undef,{ INFO => 1 });

  return $list;
}

#*******************************************************************

=head2 function employees_vacations_del() - delete position from db
  Arguments:
    $attr

  Returns:

  Examples:
    $Employee->employees_vacations_del( {ID => 1} );

=cut

#*******************************************************************
sub employees_vacations_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_vacations', $attr);

  return $self;
}

#**********************************************************
=head2 function employees_vacations_info() - get vacation info

  Arguments:
    $attr
      ID - 
  Returns:
    $self object

  Examples:
    my $list = $Employees->employees_vacations_info({ ID => 1 });

=cut
#**********************************************************
sub employees_vacations_info {
  my ($self, $attr) = @_;

  if ($attr->{ID}) {
    my $sql = <<'SQL';
      SELECT * FROM employees_vacations WHERE id = ?
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#**********************************************************
=head2 function employees_vacations_change() - get articles list

  Arguments:
    $attr
  

  Returns:
    $self object

  Examples:
    $Employees->employees_vacations_change({ ID       => 2});

=cut
#**********************************************************
sub employees_vacations_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_vacations',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 employees_duty_add() -

  Arguments:
     -
  Returns:
=cut
#**********************************************************
sub employees_duty_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_duty', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function employees_duty_list() -

  Arguments:
    $attr

  Returns:
    @list

  Examples:

=cut

#*******************************************************************
sub employees_duty_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'desc';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr,[
      [ 'ID',         'INT', 'ed.id',         1 ],
      [ 'ADMIN',      'STR', 'a.name as admin', 1 ],
      [ 'START_DATE', 'STR', 'ed.start_date', 1 ],
      [ 'DURATION',   'INT', 'ed.duration',   1 ],
      [ 'AID',        'INT', 'ed.aid',        1 ],
    ],
    { WHERE => 1, }
  );

  if ($attr->{START_DATE} && $attr->{START_DATE} ne '_SHOW' && $attr->{END_DATE} && $attr->{END_DATE} ne '_SHOW') {
    push @WHERE_RULES, "ev.start_date>='$attr->{START_DATE}' || ev.end_date<='$attr->{END_DATE}'";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT  $self->{SEARCH_FIELDS} ed.id
    FROM employees_duty ed
    LEFT JOIN admins a ON (ed.aid=a.aid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_duty
SQL

  $self->query($sql, undef,{ INFO => 1 });

  return $list;
}

#*******************************************************************
=head2 function employees_duty_del() -

  Arguments:
    $attr

  Returns:
=cut

#*******************************************************************
sub employees_duty_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_duty', $attr);

  return $self;
}

#**********************************************************
=head2 employees_duty_change() -

  Arguments:
     -
  Returns:

=cut
#**********************************************************
sub employees_duty_change{
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_duty',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 function employees_duty_info() -

  Arguments:
    $attr
      ID -  identifier
  Returns:
    $self object

  Examples:


=cut
#**********************************************************
sub employees_duty_info {
  my ($self, $attr) = @_;

  if ($attr->{ID}) {
    my $sql = <<"SQL";
      SELECT * FROM employees_duty WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] } );
  }

  return $self;
}

#**********************************************************
=head2 employees_department_list()

  Arguments:
    attr - hash of attributes{
      ID -
    }
=cut
#**********************************************************
sub employees_department_list {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr,[
      [ 'ID',        'INT',   'ed.id',        1 ],
      [ 'NAME',      'STR',   'ed.name',      1 ],
      [ 'POSITIONS', 'STR',   'ed.positions', 1 ],
      [ 'COMMENTS',  'STR',   'ed.comments',  1 ],
    ],
    { WHERE => 1, }
  );

  my $sql = <<"SQL";
   SELECT
    $self->{SEARCH_FIELDS}
     ed.id
    FROM employees_department as ed
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total
    FROM employees_department
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 employees_department_add() - add bonus type

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_department_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_department', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function employees_department_del() - delete department

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_department_del( {ID => 1} );

=cut
#*******************************************************************
sub employees_department_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_department', $attr);

  return $self;
}

#**********************************************************
=head2 employees_department_info()

  Arguments:
     -

=cut
#**********************************************************
sub employees_department_info {
  my ($self, $attr) = @_;

  my $bonus_type_info = $self->employees_department_list({%$attr, COLS_NAME => 1});

  if($bonus_type_info && ref $bonus_type_info eq 'ARRAY' && scalar @{$bonus_type_info} == 1){
    return $bonus_type_info->[0];
  }
  else{
    return {};
  }
}

#*******************************************************************
=head2 function employees_department_change() - change

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employyes->employees_department_change({
      ID     => 1,
      NAME   => 'TEST'
    });

=cut
#*******************************************************************
sub employees_department_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_department',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 employees_ext_params_save($attr) - add ext_params to db

  Arguments:
    $attr -

  Returns:
    self object
=cut
#**********************************************************
sub employees_ext_params_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_ext_params', $attr);

  return $self;
}

#**********************************************************

=head2  employees_ext_params_list() - get ex_params list

  Arguments:
    $attr

  Returns:
    list

=cut

#**********************************************************
sub employees_ext_params_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_fields = (
    [ 'AID',           'INT', 'exp.aid',          1 ],
    [ 'SUM',           'INT', 'exp.sum',          1 ],
    [ 'DAY_NUM',       'INT', 'exp.day_num',      1 ],
    [ 'STATUS',        'INT', 'exp.status',       1 ],
    [ 'PHONE',         'INT', 'exp.phone',        1 ],
    [ 'MOB_COMMENT',   'STR', 'exp.mob_comment',  1 ],
    [ 'NAME',          'STR', 'a.name',           1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_fields,
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    });

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} exp.id
           FROM employees_ext_params AS exp
           LEFT JOIN admins AS a ON exp.aid=a.aid
           $WHERE
           ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list};
}

#**********************************************************
=head2  employees_ext_params_info() - get ext params info

  Arguments:
    $attr
      AID - employee aid
  Returns:
    $self object

=cut
#**********************************************************
sub employees_ext_params_info {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_ext_params
    WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2  employees_ext_params_change() - change ext params info

  Arguments:
    $attr
      ID - ext_param id
  Returns:
    Result

=cut
#**********************************************************
sub employees_ext_params_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_ext_params',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2  employees_ext_params_del() - delete ext params info

  Arguments:
    $attr
      ID - employee aid
  Returns:
    $self object

=cut
#**********************************************************
sub employees_ext_params_del {
  my ($self, $id) = @_;

  $self->query_del('employees_ext_params', { ID => $id });

  return $self;
}

#**********************************************************
=head2 employees_mobile_report_add($attr) - add report info about mobile pay

  Arguments:
    $attr -

  Returns:
    self object
=cut
#**********************************************************
sub employees_mobile_report_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_mobile_reports', { %$attr });

  return $self;
}

#**********************************************************
=head2 employees_mobile_report($attr) - get info list about mobile pay

  Arguments:
    $attr -
      SORT - column for fa fa-sort-up
      DESC - DESC / ASC
  Returns:
    list
=cut
#**********************************************************
sub employees_mobile_report_list {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_fields = (
    [ 'ID',             'INT', 'emr.id',                  1 ],
    [ 'EMPLOYEE_NAME',  'STR', 'a.name AS employee_name', 1 ],
    [ 'PHONE',          'INT', 'emr.phone',               1 ],
    [ 'SUM',            'INT', 'emr.sum',                 1 ],
    [ 'DATE',           'DATE', 'emr.date',               1 ],
    [ 'TRANSACTION_ID', 'INT', 'emr.transaction_id',      1 ],
    [ 'STATUS',         'INT', 'emr.status',              1 ],
    [ 'AID',            'INT', 'emr.aid',                   ],
    ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(emr.date, '%Y-%m-%d')" ],
  );

  my $WHERE = $self->search_former($attr, \@search_fields,
    { WHERE       => 1,
      WHERE_RULES => \@WHERE_RULES
    });

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} emr.id
    FROM employees_mobile_reports AS emr
    LEFT JOIN admins AS a ON emr.aid=a.aid
    $WHERE
    ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list};
}

#**********************************************************
=head2  employees_mobile_report_change() - change mobile report status

  Arguments:
    $attr
      ID - report id
  Returns:
    Result

=cut
#**********************************************************
sub employees_mobile_report_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_mobile_reports',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 employees_add_cashbox() - add new cashbox

  Arguments:

  Returns:
    $self
  Examples:
    $Employees->employees_add_cashbox({ %FORM });
=cut

#**********************************************************
sub employees_add_cashbox {
  my ($self, $attr) = @_;

  $self->query_add('employees_cashboxes', { %$attr });

  return $self;
}

#*******************************************************************
=head2 employees_info_cashbox() - get information about cashbox

  Arguments:
    $attr:
      ID - cashbox id
  Returns:
    $self object

  Examples:
    $Employees->employees_info_cashbox({ ID => 1 });

=cut
#*******************************************************************
sub employees_info_cashbox {
  my ($self, $attr) = @_;

  my $sql = <<"SQL";
    SELECT ec.comments,
       ec.name,
       ec.aid,
       a.name AS name_admin,
       GROUP_CONCAT(eca.department) AS department,
       GROUP_CONCAT(eca.aid) AS admins
    FROM employees_cashboxes ec
    LEFT JOIN admins a ON (a.aid = ec.aid)
    LEFT JOIN employees_cashboxes_admins eca ON (ec.id = eca.cashbox_id)
    WHERE ec.id = ?
    GROUP BY ec.id;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#*******************************************************************

=head2 employees_change_cashbox() - change cashbox's information in database

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_change_cashbox({
      ID     => 1,
      NAME   => 'TEST'
    });

=cut

#*******************************************************************
sub employees_change_cashbox {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_cashboxes',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2 employees_delete_cashbox() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_delete_cashbox( {ID => 1} );

=cut

#*******************************************************************
sub employees_delete_cashbox {
  my ($self, $attr) = @_;

  $self->query_del('employees_cashboxes', $attr);

  return $self;
}

#*******************************************************************
=head2 employees_list_cashbox() - get list of all cashboxes

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_cashbox({ COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_list_cashbox {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT} && $attr->{SORT} < 5) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;
  my @WHERE_RULES = ();

  if ($attr->{AID}){
    $admin->info($admin->{AID});
    if ($admin->{DEPARTMENT}) {
      push @WHERE_RULES, "eca.department = $admin->{DEPARTMENT}";
    }
  }


  my $WHERE = $self->search_former($attr, [
    [ 'ID',             'INT',  'emc.id',                          1 ],
    [ 'NAME',           'STR',  'emc.name',                        1 ],
    [ 'ADMIN_DEFAULT',  'STR',  'a.name as admin_default',         1 ],
    [ 'COMMENTS',       'STR',  'emc.comments',                    1 ],
    [ 'ADMINS',         'STR',  'admins',                          1 ],
    [ 'AID',            'INT',  'eca.aid',                         1 ],
    [ 'DEPARTMENT',     'STR',  'eca.department',                  1 ],
  ],
    { WHERE_RULES => \@WHERE_RULES,
      WHERE => 1 }
  );

  my $sql = <<"SQL";
    SELECT emc.id,
    emc.name,
    a.name as admin_default,
    GROUP_CONCAT(DISTINCT ac.name SEPARATOR ', ') as admins,
    GROUP_CONCAT(DISTINCT ed.name SEPARATOR ', ') as department,
    emc.comments
    FROM employees_cashboxes emc
    LEFT JOIN admins a ON (a.aid = emc.aid)
    LEFT JOIN employees_cashboxes_admins eca ON (emc.id = eca.cashbox_id)
    LEFT JOIN employees_department ed ON (ed.id = eca.department)
    LEFT JOIN admins ac ON (ac.aid = eca.aid)
    $WHERE
    GROUP BY emc.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0) {
    $sql = <<'SQL';
      SELECT COUNT(*) AS total FROM employees_cashboxes
SQL

    $self->query($sql, undef, { INFO => 1 });
  }
  return $list;
}

#*******************************************************************
=head2 employees_payments_cashbox() - get list of all cashboxes

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_payments_cashbox({ COLS_NAME => 1});

=cut
#*******************************************************************
sub employees_payments_cashbox {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 100;
  my @WHERE_RULES = ();

  $admin->info($self->{admin}->{AID}, { SHORT => 1 });
  if ($admin->{DEPARTMENT}) {
    push @WHERE_RULES, "eca.department = $admin->{DEPARTMENT}";
  }

  my $EXT_TABLES = '';

  if ($attr->{AID}){
    $EXT_TABLES .= 'LEFT JOIN employees_cashboxes_admins eca ON (emc.id = eca.cashbox_id)';
  }

  my $WHERE = $self->search_former($attr, [
    [ 'NAME',     'STR',  'emc.name',       1 ],
    [ 'ADMIN',    'STR',  'a.name as admin',1 ] ,
    [ 'AID',      'INT',  'eca.aid',        1 ] ,
    [ 'COMMENTS', 'STR',  'emc.comments',   1 ],
  ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  my $sql = <<"SQL";
    SELECT emc.id,
      emc.name,
      emc.aid AS aid_default,
      a.name as admin,
      emc.comments
    FROM employees_cashboxes emc
    LEFT JOIN admins a ON (a.aid = emc.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY emc.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************

=head2 employees_add_type() - add type, coming or spending

  Arguments:
    $attr -
      spending - if it is spending type
      coming   - if it is coming type
  Returns:

  Examples:
    $Employees->employees_add_type({ %FORM, SPENDING => 1 });
    $Employees->employees_add_type({ %FORM, COMING   => 1 });

=cut

#**********************************************************
sub employees_add_type {
  my ($self, $attr) = @_;

  if ($attr->{SPENDING}) {
    $self->query_add('employees_spending_types', {%$attr});
  }

  if ($attr->{COMING}) {
    $self->query_add('employees_coming_types', {%$attr});
  }

  if ($attr->{MOVING}) {
    $self->query_add('employees_moving_types', {%$attr});
  }

  return $self;
}

#*******************************************************************

=head2 employees_list_spending_type() - get list spending types

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_spending_type({ COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_list_spending_type {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{AID}){
    push @WHERE_RULES, "(esta.aid='$attr->{AID}' OR esta.aid IS NULL)";
  }

  my $WHERE = $self->search_former($attr, [
    [ 'ID',       'INT', 'est.id',       1 ],
    [ 'NAME',     'STR', 'est.name',     1 ],
    [ 'COMMENTS', 'STR', 'est.comments', 1 ],
    [ 'ADMINS',   'STR', 'GROUP_CONCAT(a.name SEPARATOR \', \') as admins',  1 ],
  ],
    { WHERE_RULES => \@WHERE_RULES,
      WHERE => 1, });

  my $sql = <<"SQL";
    SELECT
     $self->{SEARCH_FIELDS}
     est.id
    FROM employees_spending_types est
    LEFT JOIN employees_spending_types_admins esta ON est.id = esta.type_id
    LEFT JOIN admins a ON (a.aid = esta.aid)
    $WHERE
    GROUP BY est.id
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_spending_types
SQL

  $self->query($sql, { INFO => 1 });

  return $list;
}

#*******************************************************************

=head2 employees_delete_type() - delete type, spending or coming

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_delete_type( {ID => 1, SPENDING => 1} );
    $Employees->employees_delete_type( {ID => 1, SPENDING => 1} );

=cut

#*******************************************************************
sub employees_delete_type {
  my ($self, $attr) = @_;

  if ($attr->{SPENDING}) {
    $self->query_del('employees_spending_types', $attr);
  }

  if ($attr->{COMING}) {
    $self->query_del('employees_coming_types', $attr);
  }

  if ($attr->{MOVING}) {
    $self->query_del('employees_moving_types', $attr);
  }

  return $self;
}

#*******************************************************************

=head2 employees_info_type() - get information type, spending or coming

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $spend_type_info  = $Employees->employees_info_type({ ID => 1, SPENDING => 1 });
    my $coming_type_info = $Employees->employees_info_type({ ID => 1, COMING   => 1 });

=cut

#*******************************************************************
sub employees_info_type {
  my ($self, $attr) = @_;
  my $sql = '';

  if ($attr->{SPENDING}) {
    $sql = <<'SQL';
      SELECT *, GROUP_CONCAT(DISTINCT esta.aid SEPARATOR ',') as admins
      FROM employees_spending_types est
      LEFT JOIN employees_spending_types_admins esta ON est.id = esta.type_id
      WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  if ($attr->{COMING}) {
    $sql = <<'SQL';
    SELECT * FROM employees_coming_types WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  if ($attr->{MOVING}) {
    $sql = <<'SQL';
      SELECT * FROM employees_moving_types WHERE id = ?;
SQL

    $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });
  }

  return $self;
}

#*******************************************************************

=head2 employees_change_type() - change type, coming or spending

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_change_type({ COMING   => 1, %FORM });
    $Employees->employees_change_type({ SPENDING => 1, %FORM });

=cut

#*******************************************************************
sub employees_change_type {
  my ($self, $attr) = @_;

  if ($attr->{SPENDING}) {
    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_spending_types',
      DATA         => $attr
    });
  }

  if ($attr->{COMING}) {
    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_coming_types',
      DATA         => $attr
    });
  }

  if ($attr->{MOVING}) {
    $self->changes({
      CHANGE_PARAM => 'ID',
      TABLE        => 'employees_moving_types',
      DATA         => $attr
    });
  }

  return $self;
}

#*******************************************************************

=head2 function employees_list_coming_type() - get list of coming types

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_coming_type({ COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_list_coming_type {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',             'INT', 'id',             1 ],
    [ 'NAME',           'STR', 'name',           1 ],
    [ 'DEFAULT_COMING', 'INT', 'default_coming', 1 ],
    [ 'COMMENTS',       'STR', 'comments',       1 ],
  ],
    {
      WHERE => 1,
    });

  my $sql = <<"SQL";
    SELECT * FROM employees_coming_types
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total
    FROM employees_coming_types
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 employees_add_spending() - add spending

  Arguments:
    $attr -
  Returns:

  Examples:
    $Employees->employees_add_spending({%FORM});
=cut
#**********************************************************
sub employees_add_spending {
  my ($self, $attr) = @_;

  $self->query_add('employees_spending', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function employees_delete_spending() - delete spending

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_delete_spending( {ID => 1} );

=cut
#*******************************************************************
sub employees_delete_spending {
  my ($self, $attr) = @_;

  $self->query_del('employees_spending', $attr);

  return $self;
}

#*******************************************************************
=head2 employees_info_spending() - get information about spending

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_spending = $Employees->employees_info_spending({ ID => 1 });
=cut
#*******************************************************************
sub employees_info_spending {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_spending
    WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#*******************************************************************
=head2 function employees_change_spending() - change spending

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_change_spending({
      ID       => 1,
      AMOUNT   => 100
    });
=cut

#*******************************************************************
sub employees_change_spending {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_spending',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2 function employees_list_spending() - get list of spendings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_spending({ COLS_NAME => 1});
=cut

#*******************************************************************
sub employees_list_spending {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 50;

  if ($attr->{CASHBOX_ID}) {
    push @WHERE_RULES, "cs.cashbox_id = '$attr->{CASHBOX_ID}'";
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "date >= '$attr->{FROM_DATE}'";
  }

  if ($attr->{TO_DATE}) {
    push @WHERE_RULES, "date <= '$attr->{TO_DATE}'";
  }

  if($attr->{SPENDING_TYPE_ID}){
    push @WHERE_RULES, "spending_type_id = '$attr->{SPENDING_TYPE_ID}'";
  }

  push @WHERE_RULES, "(esta.aid='$self->{admin}->{AID}' OR esta.aid IS NULL)";

  $admin->info($self->{admin}->{AID});
  if ($admin->{DEPARTMENT}) {
    push @WHERE_RULES, "(eca.aid='$self->{admin}->{AID}' OR eca.department = $admin->{DEPARTMENT})";
  }
  else {
    push @WHERE_RULES, "(eca.aid='$self->{admin}->{AID}')";
  }

  my @search_fields = (
    [ 'ID',                 'INT',    'cs.id',                          1 ],
    [ 'AMOUNT',             'DOUBLE', 'cs.amount',                      1 ],
    [ 'SPENDING_TYPE_NAME', 'STR',    'cst.name as spending_type_name', 1 ],
    [ 'SPENDING_TYPE_ID',   'STR',    'cs.spending_type_id',            1 ],
    [ 'CASHBOX_NAME',       'STR',    'cc.name as cashbox_name',        1 ],
    [ 'DATE',               'STR',    'cs.date',                        1 ],
    [ 'ADMIN',              'STR',    'a.name as admin',                1 ] ,
    [ 'COMMENTS',           'STR',    'cs.comments',                    1 ],
    [ 'AID',                'INT',    'esta.aid',                       1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_fields,{ WHERE => 1 });

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT
    cs.id,
    cs.amount,
    cc.name as cashbox_name,
    cst.name as spending_type_name,
    cs.date,
    a.name as admin,
    ad.name as admin_spending,
    cs.comments,
    cs.spending_type_id,
    cs.cashbox_id
    FROM employees_spending as cs
    LEFT JOIN employees_spending_types cst ON (cst.id = cs.spending_type_id)
    LEFT JOIN employees_spending_types_admins esta ON cst.id = esta.type_id
    LEFT JOIN employees_cashboxes cc ON (cc.id = cs.cashbox_id)
    LEFT JOIN admins a ON (a.aid = cs.aid)
    LEFT JOIN admins ad ON (ad.aid = cs.admin_spending)
    LEFT JOIN employees_cashboxes_admins eca ON cc.id = eca.cashbox_id
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT count(*) AS total FROM employees_spending
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 employees_add_coming() - add coming

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_add_coming {
  my ($self, $attr) = @_;

  $self->query_add('employees_coming', {%$attr});

  return $self;
}
#*******************************************************************
=head2 function employees_delete_coming() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_delete_coming( {ID => 1} );

=cut
#*******************************************************************
sub employees_delete_coming {
  my ($self, $attr) = @_;

  $self->query_del('employees_coming', $attr);

  return $self;
}

#*******************************************************************
=head2 function employees_info_coming() - get information about coming

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_coming = $Employees->employees_info_coming({ ID => 1 });
=cut
#*******************************************************************
sub employees_info_coming {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_coming WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#*******************************************************************
=head2 function employees_change_coming() - change

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_change_coming({
      ID     => 1,
      AMOUNT   => 100
    });
=cut

#*******************************************************************
sub employees_change_coming {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_coming',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2 function employees_list_coming() - get list of all comings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_coming({ COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_list_coming {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if ($attr->{CASHBOX_ID}) {
    push @WHERE_RULES, "cac.cashbox_id = '$attr->{CASHBOX_ID}'";
  }

  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "date >= '$attr->{FROM_DATE}'";
  }

  if ($attr->{TO_DATE}) {
    push @WHERE_RULES, "date <= '$attr->{TO_DATE}'";
  }

  if($attr->{COMING_TYPE_ID}){
    push @WHERE_RULES, "coming_type_id = '$attr->{COMING_TYPE_ID}'";
  }

  if ($attr->{PAYMENT_ID}) {
    push @WHERE_RULES, "cac.payment_id = '$attr->{PAYMENT_ID}'";
  }

  $admin->info($self->{admin}->{AID});
  if ($admin->{DEPARTMENT}) {
    push @WHERE_RULES, "(eca.aid='$self->{admin}->{AID}' OR eca.department = $admin->{DEPARTMENT})";
  }
  else {
    push @WHERE_RULES, "(eca.aid='$self->{admin}->{AID}')";
  }

  my @search_fields = (
    [ 'ID',               'INT',    'cs.id',                        1 ],
    [ 'AMOUNT',           'DOUBLE', 'cs.amount',                    1 ],
    [ 'COMING_TYPE_NAME', 'STR',    'cct.name as coming_type_name', 1 ],
    [ 'CASHBOX_NAME',     'STR',    'cc.name as cashbox_name',      1 ],
    [ 'DATE',             'STR',    'cs.date',                      1 ],
    [ 'ADMIN',            'STR',    'a.name as admin',              1 ],
    [ 'COMMENTS',         'STR',    'cac.comments',                 1 ],
    [ 'LOGIN',            'STR',    'u.login',                      1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_fields, {
     WHERE       => 1,
     USE_USER_PI => 1,
   });

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT
    cac.id,
    cac.amount,
    cc.name as cashbox_name,
    cct.name as coming_type_name,
    cac.date,
    a.name as admin,
    u.id as login,
    cac.comments,
    cac.uid,
    cac.coming_type_id,
    cac.cashbox_id
    FROM employees_coming as cac
    LEFT JOIN employees_coming_types cct ON (cct.id = cac.coming_type_id)
    LEFT JOIN employees_cashboxes cc ON (cc.id = cac.cashbox_id)
    LEFT JOIN employees_cashboxes_admins eca ON cc.id = eca.cashbox_id
    LEFT JOIN admins a ON (a.aid = cac.aid)
    LEFT JOIN users u ON (u.uid = cac.uid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_coming
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 employees_list_coming_report()

  Arguments:
     $attr
=cut
#**********************************************************
sub employees_list_coming_report {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "date >= '$attr->{FROM_DATE}'";
  }

  if ($attr->{TO_DATE}) {
    push @WHERE_RULES, "date <= '$attr->{TO_DATE}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT date, count(id) as total_count, sum(amount) as total_sum FROM employees_coming
    $WHERE
    GROUP BY date
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || ();
}

#**********************************************************
=head2 employees_list_spending_report()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_list_spending_report {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "date >= '$attr->{FROM_DATE}'";
  }

  if ($attr->{TO_DATE}) {
    push @WHERE_RULES, "date <= '$attr->{TO_DATE}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
    SELECT date, count(id) as total_count, sum(amount) as total_sum FROM employees_spending
    $WHERE
    GROUP BY date
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || ();
}

#**********************************************************
=head2 employees_add_bet() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_add_bet {
  my ($self, $attr) = @_;

  $self->query_add('employees_bet', {%$attr});

  return $self;
}

#*******************************************************************

=head2 function employees_info_bet() -

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_coming = $Employees->employees_info_bet({ AID => 1 });

=cut

#*******************************************************************
sub employees_info_bet {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_bet WHERE aid = ?;
SQL

  $self->query($sql, undef, { COLS_NAME => 1, COLS_UPPER => 1, Bind => [ $attr->{AID} ] });

  return $self->{list}[0];
}

#*******************************************************************

=head2 function employees_del_bet() - change

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_del_bet({
      AID     => 1,
      AMOUNT   => 100
    });


=cut

#*******************************************************************
sub employees_del_bet {
  my ($self, $attr) = @_;

  $self->query_del('employees_bet', undef, { aid => $attr->{AID} });

  return $self;
}


#**********************************************************
=head2 employees_add_payed_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_add_payed_salary {
  my ($self, $attr) = @_;

  $self->query_add('employees_salaries_payed', {%$attr, DATE => 'NOW()'});

  return $self;
}

#**********************************************************
=head2 employees_info_payed_salary() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_info_payed_salary {
  my ($self, $attr) = @_;
  my $sql = '';

  if($attr->{ID}){
    $sql = <<'SQL';
      SELECT
       csp.aid,
       csp.month,
       csp.year,
       csp.bet,
       csp.date,
       csp.spending_id,
       csp.id
      FROM employees_salaries_payed as csp
      WHERE csp.id = ?;
SQL

    $self->query($sql, undef, { COLS_NAME => 1, Bind => [ $attr->{ID} ] });
  }
  else{
    $sql = <<'SQL';
      SELECT
      csp.aid,
      csp.month,
      csp.year,
      csp.bet,
      csp.date,
      csp.spending_id,
      csp.id
      FROM employees_salaries_payed as csp
      WHERE aid = ? and month = ? and year = ?;
SQL

    $self->query($sql, undef, {
      COLS_NAME => 1,
      Bind      => [ $attr->{AID}, $attr->{MONTH}, $attr->{YEAR} ]
    });
  }

  return $self->{list} || [];
}

#**********************************************************
=head2 employees_payed_salaries_list()

  Arguments:
     attr -  hash with arguments
     {
       ID    - salarie's identifier
       BET   - salarie's payment amount
       YEAR  - salarie's payment year
       MONTH - salarie's payment month
       DATE  - date, when payment created
       ADMIN_NAME - admin's name
       AID        - admin's indetifier
       SHOW_ALL_COLUMNS - return list with all columns
     }

  Returns:
    list - list of payed salaries

  Example:
    Return list of all salaries with all columns
    $Employees->employees_payed_salaries_list({COLS_NAME => 1, SHOW_ALL_COLUMNS => 1});

    Return list of all salaries in first month in 2018 year
    $Employees->employees_payed_salaries_list({COLS_NAME => 1, YEAR => 2018, MONTH => 1});

=cut
#**********************************************************
sub employees_payed_salaries_list {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG})   ? $attr->{PG}   : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 99999999999;

  my $search_columns =  [
    [ 'ID',         'INT',  'csp.id',               1 ],
    [ 'ADMIN_NAME', 'STR',  'a.name as admin_name', 1 ],
    [ 'BET',        'INT',  'csp.bet',              1 ],
    [ 'YEAR',       'INT',  'csp.year',             1 ],
    [ 'MONTH',      'INT',  'csp.month',            1 ],
    [ 'DATE',       'DATE', 'csp.date',             1 ],
    [ 'AID',        'INT',  'csp.aid',              1 ],
    [ 'SPENDING_ID','INT',  'csp.spending_id',      1 ],
  ];

  if ($attr->{SHOW_ALL_COLUMNS}){
    map { $attr->{$_->[0]} = '_SHOW' unless exists $attr->{$_->[0]} } @$search_columns;
  }

  my $WHERE =  $self->search_former($attr, $search_columns,
    {
      WHERE => 1
    }
  );

  my $sql = <<"SQL";
    SELECT
    $self->{SEARCH_FIELDS}
     csp.id
    FROM employees_salaries_payed as csp
    LEFT JOIN admins a ON (a.aid = csp.aid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_salaries_payed
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 employees_delete_payed_salary()

  Arguments:
     attr -  with arguments hash
     {
       ID  - delete salary by ID
     }

  Returns:
    self

  Example:
    $Employees->employees_delete_payed_salary({ ID => 1 });

=cut
#**********************************************************
sub employees_delete_payed_salary {
  my ($self, $attr) = @_;

  my $old_info = {};
  if($attr->{ID}){
    $old_info = $self->employees_payed_salaries_list({ ID => $attr->{ID}, SHOW_ALL_COLUMNS => 1, COLS_NAME => 1 });
  }
  else{
    $old_info = $self->employees_payed_salaries_list({ SPENDING_ID => $attr->{SPENDING_ID}, SHOW_ALL_COLUMNS => 1, COLS_NAME => 1 });

    if($old_info->[0]{id}){
      $attr->{ID} = $old_info->[0]{id};
    }
    else{
      return 0;
    }
  }

  $self->query_del('employees_salaries_payed', $attr);

  $self->{admin}{MODULE}='Employees';
  $self->{admin}->system_action_add("SALARY! AID:$old_info->[0]{aid}; BET:$old_info->[0]{bet};YEAR-MONTH:$old_info->[0]{year}-$old_info->[0]{month};DATE: $old_info->[0]{date}", { TYPE => 10, MODULE => 'Employees' });

  return $self;
}


#**********************************************************
=head2 employees_add_reference_works() -

  Arguments:
    $attr -

=cut
#**********************************************************
sub employees_add_reference_works {
  my ($self, $attr) = @_;

  $self->query_add('employees_reference_works', {%$attr});

  return $self;
}

#**********************************************************
=head2 employees_change_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_change_reference_works {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_reference_works',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 employees_info_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_info_reference_works {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_reference_works WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#**********************************************************
=head2 employees_delete_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_delete_reference_works {
  my ($self, $attr) = @_;

  $self->query_del('employees_reference_works', $attr);

  return $self;
}

#**********************************************************
=head2 employees_list_reference_works() -

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_list_reference_works {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @search_fields = (
    [ 'ID',       'INT',    'crw.id',       1 ],
    [ 'NAME',     'STR',    'crw.name',     1 ],
    [ 'SUM',      'DOUBLE', 'crw.sum',      1 ],
    [ 'TIME',     'INT',    'crw.time',     1 ],
    [ 'UNITS',    'STR',    'crw.units',    1 ],
    [ 'DISABLED', 'STR',    'crw.disabled', 1 ],
    [ 'COMMENTS', 'STR',    'crw.comments', 1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_fields, { WHERE => 1 });

  my $sql = <<"SQL";
    SELECT
    crw.id,
    crw.name,
    crw.sum,
    crw.time,
    crw.units,
    crw.disabled,
    crw.comments
    FROM employees_reference_works as crw
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_reference_works
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 employees_reference_works_info($id, $attr)

=cut
#**********************************************************
sub employees_reference_works_info{
  my ($self, $id) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_reference_works WHERE id= ? ;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 employees_works_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub employees_works_list{
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_fields = (
    [ 'ID',         'INT', 'w.id',                                                    1 ],
    [ 'DATE',       'DATE','w.date',                                                  1 ],
    [ 'EMPLOYEE',   'STR', 'employee.name', 'employee.name AS employee'                 ],
    [ 'WORK_ID',    'INT', 'w.work_id',                                               1 ],
    [ 'WORK',       'INT', 'crw.name',   'crw.name AS work'                             ],
    [ 'RATIO',      'STR', 'w.ratio',     'w.ratio'                                     ],
    [ 'EXTRA_SUM',  'INT', 'w.extra_sum',                                             1 ],
    [ 'SUM',        'INT', 'w.sum', 'if(w.extra_sum > 0, w.extra_sum, w.sum) AS sum'    ],
    [ 'COMMENTS',   'INT', 'w.comments',                                              1 ],
    [ 'PAID',       'INT', 'w.paid',                                                  1 ],
    [ 'ADMIN_NAME', 'STR', 'a.login',     'a.name AS admin_name'                        ],
    [ 'EMPLOYEE_ID','INT', 'w.employee_id',                                             ],
    [ 'FROM_DATE|TO_DATE','DATE', "DATE_FORMAT(w.date, '%Y-%m-%d')",                    ],
    [ 'FEES_ID',    'INT', 'w.fees_id',                                               1 ],
    [ 'WORK_DONE',  'INT', 'w.work_done',                                             1 ],
    [ 'EXT_ID',     'INT', 'w.ext_id',                                                1 ],
    [ 'WORK_AID',   'INT', 'w.employee_id AS work_aid',                               1 ],
    [ 'SALARY',     'INT', 'eb.bet AS salary',                                        1 ],
  );

  my $WHERE = $self->search_former($attr, \@search_fields, { WHERE => 1});

  my $ext_table = '';
  if ($attr->{SALARY}) {
    $ext_table .= <<'EXT_TABLE';
      LEFT JOIN employees_bet AS eb ON eb.aid = w.employee_id
EXT_TABLE
  }

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} w.aid, w.id
    FROM employees_works w
    $ext_table
    LEFT JOIN admins a ON (a.aid=w.aid)
    LEFT JOIN admins employee ON (employee.aid=w.employee_id)
    LEFT JOIN employees_reference_works AS crw ON (crw.id = w.work_id)
    $WHERE
    GROUP BY w.id
    ORDER BY $SORT $DESC
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};
  $sql = <<"SQL";
   SELECT COUNT(*) AS total, SUM(if(w.extra_sum > 0, w.extra_sum, w.sum)) AS total_sum
   FROM employees_works w
   LEFT JOIN admins a ON (a.aid=w.aid)
   LEFT JOIN employees_reference_works AS crw ON (crw.id = w.work_id)
   $WHERE
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 employees_works_add($attr)

=cut
#**********************************************************
sub employees_works_add {
  my ($self, $attr) = @_;

  my %params = ();
  my @MULTI_QUERY = ();

  $params{WORK_ID} = $attr->{WORK_ID} ? [ split(/,\s?/x, $attr->{WORK_ID}) ] : [];
  $params{RATIO} = $attr->{RATIO} ? [ split(/,\s?/x, $attr->{RATIO}) ] : [];
  $params{FEES_ID} = $attr->{FEES_ID} ? [ split(/,\s?/x, $attr->{FEES_ID}) ] : [];

  for (my $i = 0 ; $i <= $#{$params{WORK_ID}}; $i++) {
    if (!$attr->{EXTRA_SUM}) {
      $self->employees_info_reference_works({ ID => $params{WORK_ID}[$i] });
      $attr->{SUM} = $self->{SUM} * ($params{RATIO}[$i] || 1) if $self->{TOTAL};
    }

    push @MULTI_QUERY, [ $attr->{DATE}, $attr->{EMPLOYEE_ID}, $params{WORK_ID}[$i], $params{RATIO}[$i], $attr->{SUM} || 0,
      $attr->{EXTRA_SUM} || 0, $attr->{COMMENTS}, $attr->{EXT_ID}, $admin->{AID}, $attr->{WORK_DONE} || 0,
      $params{FEES_ID}[$i] || 0];
  }

  my $sql = <<'SQL';
    INSERT INTO employees_works (date, employee_id, work_id, ratio,
     sum, extra_sum, comments, ext_id, aid, work_done, fees_id)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
SQL

  $self->query($sql, undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 employees_works_change($attr)

=cut
#**********************************************************
sub employees_works_change{
  my ($self, $attr) = @_;

  if(! $attr->{EXTRA_PRICE}) {
    $self->employees_info_reference_works({ ID => $attr->{WORK_ID} });
    if($self->{TOTAL}) {
      $attr->{SUM} = $self->{SUM} * ($attr->{RATIO} || 1);
    }
  }

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_works',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 employees_works_del($id, $attr)

=cut
#**********************************************************
sub employees_works_del{
  my ($self, $id, $attr) = @_;

  $self->query_del( 'employees_works', $attr, { ID => $id } );

  return $self;
}

#**********************************************************
=head2 employees_works_info($id, $attr)

=cut
#**********************************************************
sub employees_works_info{
  my ($self,$id) = @_;

  my $sql = <<'SQL';
    SELECT * FROM employees_works WHERE id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 employees_time_norms_add() - add new norms for year

  Arguments:
    WORKING_NORMS - ref array of hashes
       [{
        MONTH => 1,
        HOURS => 10,
        DAYS  => 1
        }]
     YEAR - year of data set

  Returns:
    $self

  Examples:
    $Employees->employees_time_norms_add({
    YEAR => 2018,
    WORKING_NORMS => [
    {MONTH => 1, HOURS => 10, DAYS => 2},
    {MONTH => 2, HOURS => 10, DAYS => 2},
    ]
    });

=cut
#**********************************************************
sub employees_time_norms_add {
  my ($self, $attr) = @_;

  my $working_norms_arr = $attr->{WORKING_NORMS};
  my @MULTI_QUERY = ();

  foreach my $working_norm (@$working_norms_arr) {
    push @MULTI_QUERY, [ $attr->{YEAR},
      $working_norm->{MONTH},
      $working_norm->{HOURS},
      $working_norm->{DAYS},
    ];
  }

  my $sql = <<'SQL';
    REPLACE INTO employees_working_time_norms (year, month, hours, days)
    VALUES (?, ?, ?, ?);
SQL

  $self->query($sql, undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 employees_time_norms_list() - list of data sets

  Arguments:
    YEAR  - sets of data for year
    MONTH - sets of data for month

  Returns:
    $self

  Examples:
  my $working_time_norms = $Employees->employees_time_norms_list({
    YEAR      => 2018,
    MONTH     => '_SHOW',
    HOURS     => '_SHOW',
    DAYS      => '_SHOW',
    COLS_NAME => 1,
  });

=cut
#**********************************************************
sub employees_time_norms_list {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr,[
      [ 'YEAR',   'INT',    'cwtn.year',  1 ],
      [ 'MONTH',  'INT',    'cwtn.month', 1 ],
      [ 'HOURS',  'INT',    'cwtn.hours', 1 ],
      [ 'DAYS',   'INT',    'cwtn.days',  1 ],
    ],
    { WHERE => 1, }
  );

  my $sql = <<"SQL";
    SELECT
    $self->{SEARCH_FIELDS}
     cwtn.year
    FROM employees_working_time_norms as cwtn
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_working_time_norms
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 employees_bonus_types_list()

  Arguments:
    attr - hash of attributes{
      ID -
    }

  Returns:

=cut
#**********************************************************
sub employees_bonus_types_list {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr,[
      [ 'ID',       'INT',   'cbt.id',       1 ],
      [ 'NAME',     'NAME',  'cbt.name',     1 ],
      [ 'AMOUNT',   'INT',   'cbt.amount',   1 ],
      [ 'COMMENTS', 'STR',   'cbt.comments', 1 ],
    ],
    { WHERE => 1, }
  );

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} cbt.id
    FROM employees_bonus_types as cbt
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_bonus_types
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 employees_bonus_type_add() - add bonus type

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_bonus_type_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_bonus_types', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function employees_bonus_type_del() - delete bonus type

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_bonus_type_del( {ID => 1} );

=cut
#*******************************************************************
sub employees_bonus_type_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_bonus_types', $attr);

  return $self;
}

#**********************************************************
=head2 employees_bonus_type_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub employees_bonus_type_info {
  my ($self, $attr) = @_;

  my $bonus_type_info = $self->employees_bonus_types_list({%$attr, COLS_NAME => 1});

  if($bonus_type_info && ref $bonus_type_info eq 'ARRAY' && scalar @{$bonus_type_info} == 1){
    return $bonus_type_info->[0];
  }
  else{
    return {};
  }
}

#*******************************************************************

=head2 function employees_bonus_type_change() - change

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_bonus_type_change({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub employees_bonus_type_change {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_bonus_types',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 employees_salary_bonus_list()

  Arguments:
    attr - hash of attributes{
      ID -
    }

  Returns:

=cut
#**********************************************************
sub employees_salary_bonus_list {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;

  my @search_fields = (
    [ 'ID',         'INT', 'csb.id',                 1 ],
    [ 'ADMIN_NAME', 'STR', 'a.name as admin_name',   1 ],
    [ 'BONUS_NAME', 'STR', 'cbt.name as bonus_name', 1 ],
    [ 'AID',        'INT', 'csb.aid',                1 ],
    [ 'AMOUNT',     'INT', 'csb.amount',             1 ],
    [ 'MONTH',      'INT', 'csb.month',              1 ],
    [ 'YEAR',       'INT', 'csb.year',               1 ],
    [ 'YEAR_MONTH', 'STR', 'CONCAT(csb.year, "-", csb.month)', 1],
  );

  my $WHERE = $self->search_former($attr, \@search_fields, { WHERE => 1});

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} csb.id
    FROM employees_salary_bonus as csb
    LEFT JOIN admins a ON (csb.aid = a.aid)
    LEFT JOIN employees_bonus_types cbt ON (csb.bonus_type_id = cbt.id)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  $sql = <<"SQL";
    SELECT COUNT(*) AS total, SUM(csb.amount) as total_bonus_amount
    FROM employees_salary_bonus csb
    LEFT JOIN admins a ON (csb.aid = a.aid)
    LEFT JOIN employees_bonus_types cbt ON (csb.bonus_type_id = cbt.id)
    $WHERE
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 employees_bonus_type_add() - add bonus type

  Arguments:
    $attr -
  Returns:

  Examples:

=cut
#**********************************************************
sub employees_salary_bonus_add {
  my ($self, $attr) = @_;

  $self->query_add('employees_salary_bonus', {%$attr, DATE => 'NOW()'});

  return $self;
}

#*******************************************************************
=head2 function employees_salary_bonus_del() - delete bonus type

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_salary_bonus_del( {ID => 1} );

=cut
#*******************************************************************
sub employees_salary_bonus_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_salary_bonus', $attr);

  return $self;
}

#*******************************************************************

=head2 function employees_info_moving() - get information about moving

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $info_moving = $Employees->employees_info_moving({ ID => 1 });

=cut

#*******************************************************************
sub employees_info_moving {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
     SELECT ecm.amount,
       ecm.date,
       ecm.comments,
       emt.name as moving_type_name,
       ecm.id_spending,
       ecm.id_coming,
       emt.spending_type,
       emt.coming_type,
       ecm.moving_type_id,
       ecm.cashbox_spending,
       ecm.cashbox_coming,
       (SELECT name FROM employees_cashboxes as ec WHERE ecm.cashbox_spending = ec.id) as name_spending,
       (SELECT name FROM employees_cashboxes as ec WHERE ecm.cashbox_coming = ec.id) as name_coming
    FROM employees_cashboxes_moving as ecm
    LEFT JOIN employees_moving_types emt ON (ecm.moving_type_id = emt.id)
    WHERE ecm.id = ?;
SQL

  $self->query($sql, undef, { INFO => 1, Bind => [ $attr->{ID} ] });

  return $self;
}

#*******************************************************************
=head2 function employees_change_moving() - change moving

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Employees->employees_change_moving({
      ID       => 1,
      AMOUNT   => 100
    });
=cut

#*******************************************************************
sub employees_change_moving {
  my ($self, $attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'employees_cashboxes_moving',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************

=head2 function employees_delete_moving() - delete moving

  Arguments:
    $attr

  Returns:

  Examples:
    $Employees->employees_delete_moving( {ID => 1} );

=cut

#*******************************************************************
sub employees_delete_moving {
  my ($self, $attr) = @_;

  $self->query_del('employees_cashboxes_moving', $attr);

  return $self;
}
#**********************************************************

=head2 employees_add_moving() - add moving

  Arguments:
    $attr -
  Returns:

  Examples:
    $Employees->employees_add_moving({%FORM});
=cut

#**********************************************************
sub employees_add_moving {
  my ($self, $attr) = @_;

  $self->query_add('employees_cashboxes_moving', {%$attr});

  return $self;
}
#*******************************************************************

=head2 employees_list_moving_type() - get list moving types

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_moving_type({ COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_list_moving_type {
  my ($self, $attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    [ 'ID',            'INT', 'emt.id',            1 ],
    [ 'NAME',          'STR', 'emt.name',          1 ],
    [ 'COMMENTS',      'STR', 'emt.comments',      1 ],
  ],
    { WHERE => 1, });

  my $sql = <<"SQL";
    SELECT
     emt.id,
     emt.name AS  name,
     emt.comments,
     est.name AS spending_name,
     est.id AS spending_id,
     ect.id AS coming_id,
     ect.name AS coming_name
    FROM employees_moving_types as emt
    LEFT JOIN employees_spending_types as est ON (emt.spending_type = est.id)
    LEFT JOIN employees_coming_types as ect ON (emt.coming_type = ect.id)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_moving_types
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#*******************************************************************
=head2 function employees_list_moving() - get list of all moving

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_list_moving({ COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_list_moving {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY    = 'ecm.id';

  push @WHERE_RULES, "(eca.aid='$self->{admin}->{AID}')";

  if ($self->{admin}->{DEPARTMENT}) {
    push @WHERE_RULES, " eca.department = $self->{admin}->{DEPARTMENT}";
  }

  my $WHERE = $self->search_former($attr,[
      [ 'AMOUNT',           'DOUBLE', 'cs.amount',                    1 ],
      [ 'MOVING_TYPE_NAME', 'STR',    'emt.name as moving_type_name', 1 ],
      [ 'NAME_SPENDING',    'STR',    'cc.name as cashbox_spending',  1 ],
      [ 'NAME_COMING',      'STR',    'cc.name as cashbox_coming',    1 ],
      [ 'DATE',             'STR',    'cs.date',                      1 ],
      [ 'ADMIN',            'STR',    'a.name as admin',              1 ],
      [ 'COMMENTS',         'STR',    'cac.comments',                 1 ],
    ],
    {
      WHERE       => 1,
      USE_USER_PI => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  my $sql = <<"SQL";
    SELECT
    ecm.id,
    ecm.amount,
    (SELECT name FROM employees_cashboxes as ec WHERE ecm.cashbox_spending = ec.id) as name_spending,
    (SELECT name FROM employees_cashboxes as ec WHERE ecm.cashbox_coming = ec.id) as name_coming,
    ecm.date,
    emt.name as moving_type_name,
    a.name as admin,
    ecm.comments
    FROM  employees_cashboxes_moving as ecm
    LEFT JOIN admins a ON (a.aid = ecm.aid)
    LEFT JOIN employees_moving_types emt ON (ecm.moving_type_id = emt.id)
    LEFT JOIN employees_cashboxes_admins eca ON (ecm.cashbox_spending = eca.cashbox_id OR ecm.cashbox_coming = eca.cashbox_id)
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $sql = <<'SQL';
    SELECT COUNT(*) AS total FROM employees_cashboxes_moving
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}
#**********************************************************
=head2 coming_default_type($attr)

=cut
#**********************************************************
sub coming_default_type {
  my ($self) = @_;
  my $sql = <<'SQL';
    UPDATE employees_coming_types SET default_coming = 0;
SQL

  $self->query($sql);

  return $self;
}

#**********************************************************
=head2 employees_works_by_type_list($attr) - list of tp services

  Arguments:
    $attr

=cut
#**********************************************************
sub employees_works_by_type_list{
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my @search_fields = (
    [ 'ID',                'INT',  'w.id',                                                      1 ],
    [ 'WORK_ID',           'INT',  'w.work_id',                                                 1 ],
    [ 'WORK',              'INT',  'crw.name', 'crw.name AS work',                              1 ],
    [ 'TOTAL_WORKS',       'INT',  'COUNT(w.id) AS total_works',                                1 ],
    [ 'WORKS_SUM',         'INT',  'sum(if(w.extra_sum > 0, w.extra_sum, w.sum)) AS works_sum', 1 ],
    [ 'ADMIN_NAME',        'STR',  'a.login', 'a.name AS admin_name',                           1 ],
    [ 'EMPLOYEE_AID',      'INT',  'employee.aid AS employee_aid',                              1 ],
    [ 'FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(w.date, '%Y-%m-%d')",                           1 ],
    [ 'WORK_DONE',         'INT',  'w.work_done',                                               1 ],
    [ 'TOTAL_DONE',        'INT',  'SUM(w.work_done) AS total_done',                            1 ],
    [ 'PERFORMERS',        'STR',  'GROUP_CONCAT(DISTINCT employee .name) AS performers',       1 ]
  );

  my $WHERE = $self->search_former($attr, \@search_fields, { WHERE => 1 });

  my $sql = <<"SQL";
    SELECT $self->{SEARCH_FIELDS} w.id
    FROM employees_works w
    LEFT JOIN admins a ON (a.aid=w.aid)
    LEFT JOIN admins employee ON (employee.aid=w.employee_id)
    LEFT JOIN employees_reference_works AS crw ON (crw.id = w.work_id)
    $WHERE
    GROUP BY w.work_id
    ORDER BY $SORT $DESC
SQL

  $self->query($sql, undef, $attr);

  my $list = $self->{list};
  $sql = <<"SQL";
    SELECT COUNT(*) AS total, SUM(IF(w.extra_sum > 0, w.extra_sum, w.sum)) AS total_sum
    FROM employees_works w
    LEFT JOIN admins a ON (a.aid=w.aid)
    LEFT JOIN admins employee ON (employee.aid=w.employee_id)
    LEFT JOIN employees_reference_works AS crw ON (crw.id = w.work_id)
    $WHERE
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list;
}

#**********************************************************
=head2 employees_work_for_map($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub employees_work_for_map {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
    SELECT ew.*, mm.id, u.uid, b.id AS build_id, a.id AS admin, crw.name,
       IF(b.coordx <> 0, b.coordx , SUM(plpoints.coordy)/COUNT(plpoints.polygon_id)) AS coordx,
       IF(b.coordy <> 0, b.coordy , SUM(plpoints.coordx)/COUNT(plpoints.polygon_id)) AS coordy
    FROM employees_works ew
       LEFT JOIN admins a ON (a.aid=ew.aid)
       LEFT JOIN admins employee ON (employee.aid=ew.employee_id)
       LEFT JOIN employees_reference_works AS crw ON (crw.id = ew.work_id)
       LEFT JOIN msgs_messages mm ON (mm.id = ew.ext_id)
       LEFT JOIN users u ON (mm.uid = u.uid)
       LEFT JOIN users_pi up ON (up.uid = u.uid)
       LEFT JOIN builds b ON (b.id = up.location_id OR b.id = mm.location_id)
       LEFT JOIN maps_points mp ON (b.id=mp.location_id)
       LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
       LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
       LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
       LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
    GROUP BY ew.id HAVING (coordx <> 0 AND coordy <> 0);
SQL

  $self->query($sql, undef, $attr);

  return $self->{list} || [];

}

#**********************************************************
=head2 employees_cashbox_admins_add() - add admins to cashbox

  Arguments:
    IDS
    CASHBOX_ID
    ADMINS - add admins
    DEPARTMENT - add department
  Returns:
    $self
=cut
#**********************************************************
sub employees_cashbox_admins_add {
  my ($self, $attr) = @_;

  my @ids = split(/,\s+/x, $attr->{IDS});
  my @MULTI_QUERY = ();
  my $sql = '';

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{CASHBOX_ID}, $id];
  }

  if ($attr->{ADMINS}) {
    $sql = <<'SQL';
    INSERT INTO employees_cashboxes_admins (cashbox_id, aid) VALUES (?, ?);
SQL
  }
  if ($attr->{DEPARTMENT}) {
    $sql = <<'SQL';
    INSERT INTO employees_cashboxes_admins (cashbox_id, department) VALUES (?, ?);
SQL
  }

  $self->query($sql, undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 employees_cashbox_admins_del() - delete admins from cashbox

  Arguments:
    cashbox_id
  Returns:
    $self
=cut
#**********************************************************
sub employees_cashbox_admins_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_cashboxes_admins', undef, $attr);

  return $self;
}

#*******************************************************************

=head2 employees_total_balance() - get total balances with coming and spending

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Employees->employees_total_balance({ CASHBOX_IDS => '1;2', COLS_NAME => 1});

=cut

#*******************************************************************
sub employees_total_balance {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'CASHBOX_IDS',        'INT',  'ec.id',         1 ],
  ], { WHERE => 1 });

  my $sql = <<"SQL";
    SELECT
    ec.id, ec.name,
    (SELECT SUM(amount) FROM employees_coming WHERE cashbox_id=ec.id) AS total_coming,
    (SELECT SUM(amount) FROM employees_spending WHERE cashbox_id=ec.id) AS total_spending
    FROM employees_cashboxes ec
    $WHERE
    GROUP BY ec.id
    ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr, );

  return $self->{list} || [];
}

#**********************************************************
=head2 employees_spending_types_admins_add() - add admins to spending type

  Arguments:
    IDS
    TYPE_ID
  Returns:
    $self
=cut
#**********************************************************
sub employees_spending_types_admins_add {
  my ($self, $attr) = @_;

  my @ids = split(/,\s+/x, $attr->{IDS});
  my @MULTI_QUERY = ();

  foreach my $id (@ids) {
    push @MULTI_QUERY, [ $attr->{TYPE_ID}, $id];
  }

  my $sql = <<'SQL';
    INSERT INTO employees_spending_types_admins (type_id, aid) VALUES (?, ?);
SQL

  $self->query($sql, undef, { MULTI_QUERY => \@MULTI_QUERY });

  return $self;
}

#**********************************************************
=head2 employees_spending_types_admins_del() - delete admins from spending type

  Arguments:
    TYPE_ID
  Returns:
    $self
=cut
#**********************************************************
sub employees_spending_types_admins_del {
  my ($self, $attr) = @_;

  $self->query_del('employees_spending_types_admins', undef, $attr);

  return $self;
}


1;