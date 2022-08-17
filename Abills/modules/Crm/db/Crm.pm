package Crm;
=head1 NAME

  Cashbox - module for CRM

=head1 SYNOPSIS

  use Cashbox;
  my $Cashbox = Cashbox->new($db, $admin, \%conf);

=cut

use strict;
use parent qw(dbcore);

my ($admin, $CONF);

#*******************************************************************
=head2 new()

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#**********************************************************
=head2 crm_lead_add() - add new lead

  Arguments:
    $attr  -

  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_add {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    use Address;
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID         => $attr->{STREET_ID},
      ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD}
    });
    $attr->{BUILD_ID} = $Address->{LOCATION_ID};
  }

  $self->query_add('crm_leads', { %$attr, DATE => $attr->{DATE} || 'NOW()' });
  my $insert_id = $self->{INSERT_ID} || 0;

  if ($insert_id) {
    $self->crm_action_add("INSERT_ID: $insert_id", { ID => $insert_id, TYPE => 1 });
    $self->{INSERT_ID} = $insert_id;
  }

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
 #**********************************************************
sub crm_lead_change {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{STREET_ID} && $attr->{ADD_ADDRESS_BUILD}) {
    use Address;
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID         => $attr->{STREET_ID},
      ADD_ADDRESS_BUILD => $attr->{ADD_ADDRESS_BUILD}
    });
    $attr->{BUILD_ID} = $Address->{LOCATION_ID};
  }

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'crm_leads',
    DATA            => $attr,
    SKIP_LOG        => 1,
    GET_CHANGES_LOG => 1
  });

  $self->crm_action_add($self->{CHANGES_LOG}, { %{$attr}, TYPE => 2 }) if ($self->{CHANGES_LOG} || $attr->{CHANGES_LOG});

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_leads', $attr);
  $self->crm_action_add("DELETED: $attr->{ID}", { ID => $attr->{ID}, TYPE => 4 }) if !$self->{errno};

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT *, cl.id as lead_id FROM crm_leads cl
    LEFT JOIN users u ON (u.uid = cl. uid)
      WHERE cl.id = ?;", undef,
      { COLS_NAME => 1, COLS_UPPER=> 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 crm_lead_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_lead_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;

  my @WHERE_RULES = ();

  push @WHERE_RULES, "cl.date >= '$attr->{FROM_DATE}'" if ($attr->{FROM_DATE});
  push @WHERE_RULES, "cl.date <= '$attr->{TO_DATE}'" if ($attr->{TO_DATE});
  push @WHERE_RULES, "cl.phone LIKE '\%$attr->{PHONE_SEARCH}\%'" if ($attr->{PHONE_SEARCH});
  push @WHERE_RULES, "(cl.domain_id='$self->{admin}{DOMAIN_ID}')" if ($self->{admin}{DOMAIN_ID});
  push @WHERE_RULES, "((SELECT COUNT(DISTINCT cl2.id) FROM crm_leads cl2 WHERE cl2.phone <> '' AND cl2.phone=cl.phone) > 1
  OR (SELECT COUNT(DISTINCT cl2.id) FROM crm_leads cl2 WHERE cl2.email <> '' AND cl2.email=cl.email) > 1)" if ($attr->{DUBLICATE});

  push @WHERE_RULES, "cl.responsible='$admin->{AID}'" if (! $attr->{SKIP_RESPOSIBLE} && (!$admin->{permissions}{7} || !$admin->{permissions}{7}{4}));


  if ($attr->{LEAD_ID}) {
    $SORT = 'lead_id';
    $DESC = 'DESC';
  }

  $attr->{SKIP_DEL_CHECK} = 1;
  $attr->{SEARCH_COLUMNS} = $attr->{SEARCH_COLUMNS} && ref $attr->{SEARCH_COLUMNS} eq 'ARRAY' ? $attr->{SEARCH_COLUMNS} : ();
  my $build_delimiter = $attr->{BUILD_DELIMITER} || $self->{conf}{BUILD_DELIMITER} || ', ';
  my $search_columns = [
    [ 'LEAD_ID',          'INT',   'cl.id as lead_id',               1 ],
    [ 'USER_LOGIN',       'STR',   'u.id as user_login',             1 ],
    [ 'FIO',              'STR',   'cl.fio',                         1 ],
    [ 'PHONE',            'STR',   'cl.phone',                       1 ],
    [ 'EMAIL',            'STR',   'cl.email',                       1 ],
    [ 'COMPANY',          'STR',   'cl.company',                     1 ],
    [ 'LEAD_CITY',        'STR',   'cl.city as lead_city',           1 ],
    [ 'RESPONSIBLE',      'INT',   'cl.responsible',                 1 ],
    [ 'ADMIN_NAME',       'STR',   'a.name as admin_name',           1 ],
    [ 'SOURCE',           'INT',   'cl.source',                      1 ],
    [ 'SOURCE_NAME',      'STR',   'cls.name as source_name',        1 ],
    [ 'DATE',             'DATE',  'cl.date',                        1 ],
    [ 'CURRENT_STEP',     'INT',   'cl.current_step',                1 ],
    [ 'CURRENT_STEP_NAME','STR',   'cps.name as current_step_name',  1 ],
    [ 'STEP_COLOR',       'STR',   'cps.color as step_color',        1 ],
    [ 'ADDRESS',          'STR',   'cl.address',                     1 ],
    [ 'BUILD_ID',         'INT',   'cl.build_id',                    1 ],
    [ 'ADDRESS_FLAT',     'STR',   'cl.address_flat',                1 ],
    [ 'LAST_ACTION',      'STR',   'cl.id as last_action',           1 ],
    [ 'PRIORITY' ,        'STR',   'cl.priority',                    1 ],
    [ 'PERIOD',           'DATE',  'cl.date as period',              1 ],
    [ 'SOURCE',           'INT',   'cl.source',                      1 ],
    [ 'COMMENTS',         'STR',   'cl.comments',                      ],
    [ 'TAG_IDS' ,         'STR',   'cl.tag_ids',                     1 ],
    [ 'DOMAIN_ID',        'INT',   'cl.domain_id',                   0 ],
    [ 'CL_UID',           'INT',   'cl.uid',                         0 ],
    [ 'COMPETITOR_ID',    'INT',   'cl.competitor_id',               1 ],
    [ 'COMPETITOR_NAME',  'STR',   'cc.name AS competitor_name',     1 ],
    [ 'TP_ID',            'INT',   'cl.tp_id',                       1 ],
    [ 'TP_NAME',          'STR',   'cct.name AS tp_name',            1 ],
    [ 'ASSESSMENT',       'INT',   'cl.assessment',                  1 ],
    [ 'LEAD_ADDRESS',     'STR',
      "IF(cl.build_id, CONCAT(districts.name, '$build_delimiter', streets.name, '$build_delimiter', builds.number), '') AS lead_address",  1 ],
    [ 'ADDRESS_FULL',     'STR',
      "IF(cl.build_id, CONCAT(districts.name, '$build_delimiter', streets.name, '$build_delimiter', builds.number, '$build_delimiter', cl.address_flat), '') AS address_full",  1 ],
    [ 'WATCHER',          'INT',   'clw.aid',                        0 ],
  ];

  map push(@{$search_columns}, $_), @{$attr->{SEARCH_COLUMNS}};

  my $WHERE = $self->search_former($attr, $search_columns, {
    WHERE             => 1,
    USERS_FIELDS_PRE  => 1,
    SKIP_USERS_FIELDS => [ 'FIO', 'PHONE', 'EMAIL', 'COMMENTS', 'DOMAIN_ID', 'ADDRESS_FULL' ],
    WHERE_RULES       => \@WHERE_RULES,
  });

  my $EXT_TABLES = $self->{EXT_TABLES};

  # if ($attr->{LEAD_ADDRESS}) {
  #   $EXT_TABLES .= " LEFT JOIN districts ON (districts.id=streets.district_id) ";
  # }

  if ($attr->{LEAD_ADDRESS} || $attr->{ADDRESS_FULL}) {
    $EXT_TABLES .= "LEFT JOIN builds ON (builds.id=cl.build_id)";
    $EXT_TABLES .= "LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
  }
  if($self->{SEARCH_FIELDS} =~ /company\./) {
    $EXT_TABLES .= 'LEFT JOIN companies company FORCE INDEX FOR JOIN (`PRIMARY`) ON (u.company_id=company.id)';
  }

  if($attr->{WATCHER}) {
    $EXT_TABLES .= 'LEFT JOIN crm_leads_watchers clw ON (clw.lead_id = cl.id)';
  }

  my $sql =  "SELECT DISTINCT
    $self->{SEARCH_FIELDS}
    cl.uid, cl.id
    FROM crm_leads as cl
    LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
    LEFT JOIN crm_competitors cc ON (cc.id = cl.competitor_id)
    LEFT JOIN crm_competitors_tps cct ON (cl.tp_id = cct.id AND cc.id = cct.competitor_id)
    LEFT JOIN crm_progressbar_steps cps ON (cps.step_number = cl.current_step)
    LEFT JOIN admins a ON (a.aid = cl.responsible)
    LEFT JOIN users u ON (u.uid = cl.uid)
    $EXT_TABLES
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;";

  $self->query($sql, undef, $attr );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
    FROM crm_leads as cl
    LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
    LEFT JOIN crm_progressbar_steps cps ON (cps.step_number = cl.current_step)
    LEFT JOIN admins a ON (a.aid = cl.responsible)
    LEFT JOIN users u ON (u.uid = cl.uid)
    $EXT_TABLES
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}


#**********************************************************
=head2 crm_add_progressbar_step() -

  Arguments:
     -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_progressbar_step_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_progressbar_steps', {%$attr});

  return $self;
}

#*******************************************************************
=head2 function crm_progressbar_step_info() - get information about step

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    my $step_info = $Cashbox->crm_progressbar_step_info({ ID => 1 });

=cut
#*******************************************************************
sub crm_progressbar_step_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM crm_progressbar_steps
      WHERE id = ?;", undef, { INFO => 1, Bind => [ $attr->{ID} ] }
  );

  return $self;
}

#*******************************************************************

=head2 function crm_progressbar_step_delete() - delete cashbox

  Arguments:
    $attr

  Returns:

  Examples:
    $Crm->crm_progressbar_step_delete( {ID => 1} );

=cut

#*******************************************************************
sub crm_progressbar_step_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_progressbar_steps', $attr);

  return $self;
}

#*******************************************************************
=head2 function crm_progressbar_step_delete() - change step's information in datebase

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Crm->crm_progressbar_step_delete({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut
#*******************************************************************
sub crm_progressbar_step_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_progressbar_steps',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************
=head2 crm_progressbar_step_list() - get list of all comings

  Arguments:
    $attr

  Returns:
    @list

  Examples:
    my @list = $Cashbox->crm_progressbar_step_list({ COLS_NAME => 1});

=cut
#*******************************************************************
sub crm_progressbar_step_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if($self->{admin}{DOMAIN_ID}){
    push @WHERE_RULES,
      "(domain_id='$self->{admin}{DOMAIN_ID}')";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',          'INT', 'id',           1 ],
      [ 'STEP_NUMBER', 'INT', 'step_number',  1 ],
      [ 'NAME',        'STR', 'name',         1 ],
      [ 'COLOR',       'STR', 'color',        1 ],
      [ 'DESCRIPTION', 'STR', 'description',  1 ],
      [ 'DOMAIN_ID',   'INT', 'domain_id',    0 ],
    ],
    {
      WHERE => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    id
    FROM crm_progressbar_steps
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM crm_progressbar_steps
   $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 leads_source_add() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_leads_sources', {%$attr});

  return $self;
}

#**********************************************************
=head2 crm_lead_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
 #**********************************************************
 sub leads_source_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_leads_sources',
      DATA         => $attr
    }
  );

  return $self;
 }

#**********************************************************
=head2 leads_source_delete() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_leads_sources', $attr);

  return $self;
}

#**********************************************************
=head2 leads_source_info() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query(
    "SELECT * FROM crm_leads_sources
      WHERE id = ?;", undef, { COLS_NAME=>1, COLS_UPPER=> 1, Bind => [ $attr->{ID} ] }
  );

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 leads_source_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub leads_source_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if($self->{admin}{DOMAIN_ID}){
    push @WHERE_RULES,
      "(cls.domain_id='$self->{admin}{DOMAIN_ID}')";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'cls.id',       1 ],
      [ 'NAME',       'STR',    'cls.name',     1 ],
      [ 'COMMENTS',   'STR',    'cls.comments', 1 ],
      [ 'DOMAIN_ID',  'INT',    'cls.domain_id',0 ],
    ],
    {
      WHERE => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    cls.id
    FROM crm_leads_sources as cls
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
    FROM crm_leads_sources as cls
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 progressbar_comment_add() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub progressbar_comment_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_progressbar_step_comments', {%$attr});

  return $self;
}

#**********************************************************
=head2 progressbar_comment_delete()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub progressbar_comment_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_progressbar_step_comments', $attr);

  return $self;
}

#**********************************************************
=head2 progressbar_comment_list() -

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub progressbar_comment_list  {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 99999;

  if($self->{admin}{DOMAIN_ID}){
    push @WHERE_RULES,
      "(cpsc.domain_id='$self->{admin}{DOMAIN_ID}')";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',            'INT',    'cpsc.id',                1 ],
      [ 'STEP_ID',       'INT',    'cpsc.step_id',           1 ],
      [ 'LEAD_ID',       'INT',    'cpsc.lead_id',           1 ],
      [ 'MESSAGE',       'STR',    'cpsc.message',           1 ],
      [ 'DATE',          'DATE',   'cpsc.date',              1 ],
      [ 'ADMIN',         'STR',    'a.id as admin',          1 ],
      [ 'ACTION',        'STR',    'ca.name as action',      1 ],
      [ 'AID',           'INT',    'cpsc.aid',               1 ],
      [ 'LEAD_FIO',      'STR',    'cl.fio as lead_fio',     1 ],
      [ 'PLANNED_DATE',  'DATE',   'cpsc.planned_date',      1 ],
      [ 'DOMAIN_ID',     'INT',    'cpsc.domain_id',         0 ],
      [ 'PRIORITY',      'STR',    'cpsc.priority',          1 ],
    ],
    {
      WHERE => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    cpsc.id
    FROM crm_progressbar_step_comments cpsc
    LEFT JOIN admins a ON (a.aid = cpsc.aid)
    LEFT JOIN crm_actions ca ON (ca.id = cpsc.action_id)
    LEFT JOIN crm_leads cl ON (cl.id = cpsc.lead_id)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
    FROM crm_progressbar_step_comments cpsc
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list;
}


#**********************************************************
=head2 crm_actions_add() - add new action

  Arguments:
     NAME   - name of the action
     ACTION - action
    
  Returns:
    $self

  Examples:
  
=cut
#**********************************************************
sub crm_actions_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_actions', {%$attr});

  return $self;
}

#*******************************************************************
=head2 crm_actions_change() - change action

  Arguments:
    $attr

  Returns:
    $self object

  Examples:
    $Crm->crm_action_change({
      ID     => 1,
      NAME   => 'TEST'
    });


=cut

#*******************************************************************
sub crm_actions_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_actions',
      DATA         => $attr
    }
  );

  return $self;
}

#*******************************************************************

=head2  crm_actions_delete() - delete action

  Arguments:
    $attr

  Returns:

  Examples:
    $Cashbox->crm_action_delete( {ID => 1} );

=cut

#*******************************************************************
sub crm_actions_delete {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_actions', $attr);

  return $self;
}

#**********************************************************
=head2 crm_actions_list($attr) - return list of actions

  Arguments:
    $attr -

  Returns:

  Examples:

=cut
#**********************************************************
sub crm_actions_list {
  my $self = shift;
  my ($attr) = @_;

  my @WHERE_RULES = ();
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  if($self->{admin}{DOMAIN_ID}){
    push @WHERE_RULES,
      "(ca.domain_id='$self->{admin}{DOMAIN_ID}')";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'ca.id',       1 ],
      [ 'NAME',       'STR',    'ca.name',     1 ],
      [ 'ACTION',     'STR',    'ca.action',   1 ],
      [ 'DOMAIN_ID',  'INT',    'ca.domain_id',0 ],
    ],
    {
      WHERE => 1,
      WHERE_RULES => \@WHERE_RULES,
    }
  );

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    ca.id
    FROM crm_actions as ca
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
    FROM crm_actions as ca
    $WHERE",
    undef,
    { INFO => 1 }
  );

  return $list || [];
}

#**********************************************************
=head2 crm_actions_info()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_actions_info {
  my $self = shift;
  my ($attr) = @_;

  my $action_info = $self->crm_actions_list({%$attr});

  if($action_info && ref $action_info eq 'ARRAY' && scalar @{$action_info} == 1){
    return $action_info->[0];
  }
  else{
    return ();
  }
}

#**********************************************************
=head2 crm_update_lead_tags($attr)

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub crm_update_lead_tags {
  my $self = shift;
  my ($attr) = @_;

  $self->query("UPDATE `crm_leads` SET tag_ids='$attr->{TAG_IDS}' WHERE id=?;",
    "do",
    {
      Bind => [
        $attr->{LEAD_ID}
      ]
    });

  return $self;
}

#**********************************************************
=head2 crm_step_number_leads()

  Arguments:
     -

  Returns:

=cut
#**********************************************************
sub crm_step_number_leads {
  my $self = shift;

  $self->query("SELECT step_number,id
    FROM crm_progressbar_steps;",
    undef,
    { LIST2HASH => 'step_number,id' });

  return $self->{list_hash} || {};
}

#**********************************************************
=head2 crm_competitor_add() - add new competitor

  Arguments:
    $attr  -

  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitor_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_competitors', $attr);

  return $self;
}

#**********************************************************
=head2 crm_competitor_del() - del competitor

  Arguments:
    $attr  -

  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitor_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_competitors', $attr);

  return $self;
}

#**********************************************************
=head2 crm_competitor_list()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitor_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'cc.id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;

  my $EXT_TABLE = '';
  my @WHERE_RULES = ();

  if ($attr->{BUILD_ID}) {
    push @WHERE_RULES, "ccg.build_id = $attr->{BUILD_ID}";
  }
  elsif ($attr->{STREET_ID}) {
    push @WHERE_RULES, "(b.street_id = $attr->{STREET_ID} OR ccg.street_id = $attr->{STREET_ID})";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=ccg.build_id)';
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(s.district_id = $attr->{DISTRICT_ID} OR ccg.district_id = $attr->{DISTRICT_ID})";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=ccg.build_id)';
    $EXT_TABLE .= 'LEFT JOIN streets s ON (s.id=b.street_id OR s.id=ccg.street_id)';
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',               'INT', 'cc.id',              1 ],
      [ 'NAME',             'STR', 'cc.name',            1 ],
      [ 'DESCR',            'STR', 'cc.descr',           1 ],
      [ 'SITE',             'STR', 'cc.site',            1 ],
      [ 'COLOR',            'STR', 'color',              1 ],
      [ 'CONNECTION_TYPE',  'STR', 'cc.connection_type', 1 ],
    ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cc.id FROM crm_competitors cc
    LEFT JOIN crm_competitor_geolocation ccg ON (ccg.competitor_id=cc.id)
    $EXT_TABLE
    $WHERE
    GROUP BY cc.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total FROM crm_competitors cc $WHERE", undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 crm_competitor_info()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitor_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM crm_competitors cc WHERE cc.id = ?;", undef, { COLS_NAME => 1, COLS_UPPER => 1, Bind => [ $attr->{ID} ] });

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 crm_competitor_change()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitor_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'crm_competitors',
    DATA         => $attr
  });

  return $self;
}

#**********************************************************
=head2 crm_competitor_add() - add new competitor

  Arguments:
    $attr  -

  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_tps_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_competitors_tps', $attr);

  return $self;
}

#**********************************************************
=head2 crm_competitor_del() - del competitor

  Arguments:
    $attr  -

  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_tps_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_competitors_tps', $attr);

  return $self;
}

#**********************************************************
=head2 crm_competitor_list()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_tps_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'cct.id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'cct.id';

  my $EXT_TABLE = '';
  my @WHERE_RULES = ();

  if ($attr->{BUILD_ID}) {
    push @WHERE_RULES, "cctg.build_id = $attr->{BUILD_ID}";
  }
  elsif ($attr->{STREET_ID}) {
    push @WHERE_RULES, "(b.street_id = $attr->{STREET_ID} OR cctg.street_id = $attr->{STREET_ID})";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=cctg.build_id)';
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(s.district_id = $attr->{DISTRICT_ID} OR cctg.district_id = $attr->{DISTRICT_ID})";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=cctg.build_id)';
    $EXT_TABLE .= 'LEFT JOIN streets s ON (s.id=b.street_id OR s.id=cctg.street_id)';
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',              'INT', 'cct.id',                     1 ],
      [ 'NAME',            'STR', 'cct.name',                   1 ],
      [ 'SPEED',           'INT', 'cct.speed',                  1 ],
      [ 'MONTH_FEE',       'INT', 'cct.month_fee',              1 ],
      [ 'DAY_FEE',         'INT', 'cct.day_fee',                1 ],
      [ 'COMPETITOR_ID',   'INT', 'cct.competitor_id',          1 ],
      [ 'COMPETITOR_NAME', 'STR', 'cc.name AS competitor_name', 1 ],
    ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cct.id
    FROM crm_competitors_tps cct
    LEFT JOIN crm_competitors cc ON (cc.id = cct.competitor_id)
    LEFT JOIN crm_competitor_tps_geolocation cctg ON (cct.id = cctg.tp_id)
    $EXT_TABLE
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query("SELECT COUNT(*) AS total FROM crm_competitors_tps cct $WHERE", undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2 crm_competitor_info()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_tps_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT * FROM crm_competitors_tps cct WHERE cct.id = ?;", undef, { COLS_NAME => 1, COLS_UPPER => 1, Bind => [ $attr->{ID} ] });

  if (! $self->{list} ) {
    return {};
  }

  return $self->{list}->[0] || {};
}

#**********************************************************
=head2 crm_competitor_change()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_tps_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'crm_competitors_tps',
    DATA         => $attr
  });

  return $self;
}

#*******************************************************************
=head2 crm_add_competitor_geo($attr) - add geo info

  Arguments:
    %$attr

  Returns:
    $self object

  Examples:

=cut
#*******************************************************************
sub crm_add_competitor_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_competitor_geolocation', { %$attr });

  return $self;
}

#*******************************************************************
=head2 crm_del_competitor_geo() - delete geolocation from db

  Arguments:
    $attr

  Returns:

  Examples:

=cut
#*******************************************************************
sub crm_del_competitor_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_competitor_geolocation', undef, { competitor_id => $attr->{COMPETITOR_ID} });

  return $self;
}

#**********************************************************
=head2 crm_competitor_geo_list() - get geo list

  Arguments:
    $attr
  Returns:
    @list

  Examples:

=cut
#**********************************************************
sub crm_competitor_geo_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'COMPETITOR_ID', 'INT', 'ccg.competitor_id', 1 ],
    [ 'STREET_ID',     'INT', 'ccg.street_id',     1 ],
    [ 'BUILD_ID',      'INT', 'ccg.build_id',      1 ],
    [ 'DISTRICT_ID',   'INT', 'ccg.district_id',   1 ]
  ], { WHERE => 1 });

  $self->query(
    "SELECT ccg.competitor_id, ccg.street_id, ccg.build_id, ccg.district_id FROM crm_competitor_geolocation ccg $WHERE
      ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 crm_competitor_builds_list()

  Arguments:
    $attr
  Returns:
    @list

  Examples:

=cut
#**********************************************************
sub crm_competitor_builds_list {
  my $self = shift;
  my ($competitor_id) = @_;

  $self->query("SELECT b.id AS id, b.number AS number, s.name AS street_name, d.name AS district_name, d.id AS district_id, s.id AS street_id
    FROM builds b
    LEFT JOIN streets s  ON (s.id=b.street_id)
    LEFT JOIN districts d  ON (d.id=s.district_id)
    LEFT JOIN crm_competitor_geolocation ccg ON (ccg.build_id=b.id OR ccg.street_id=s.id OR ccg.district_id=d.id)
    WHERE competitor_id=?
    ORDER BY b.id;", undef, { COLS_NAME => 1, Bind => [ $competitor_id ] }
  );

  return $self->{list} || [];
}

#*******************************************************************
=head2 crm_add_competitor_tps_geo($attr) - add geo info

  Arguments:
    %$attr

  Returns:
    $self object

  Examples:

=cut
#*******************************************************************
sub crm_add_competitor_tps_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_competitor_tps_geolocation', { %$attr });

  return $self;
}

#*******************************************************************
=head2 crm_del_competitor_tps_geo() - delete geolocation from db

  Arguments:
    $attr

  Returns:

  Examples:

=cut
#*******************************************************************
sub crm_del_competitor_tps_geo {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('crm_competitor_tps_geolocation', undef, { tp_id => $attr->{TP_ID} });

  return $self;
}

#**********************************************************
=head2 crm_competitor_tps_geo_list() - get geo list

  Arguments:
    $attr
  Returns:
    @list

  Examples:

=cut
#**********************************************************
sub crm_competitor_tps_geo_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'TP_ID',       'INT', 'cctg.tp_id',       1 ],
    [ 'STREET_ID',   'INT', 'cctg.street_id',   1 ],
    [ 'BUILD_ID',    'INT', 'cctg.build_id',    1 ],
    [ 'DISTRICT_ID', 'INT', 'cctg.district_id', 1 ]
  ], { WHERE => 1 });

  $self->query(
    "SELECT cctg.tp_id, cctg.street_id, cctg.build_id, cctg.district_id FROM crm_competitor_tps_geolocation cctg $WHERE
      ORDER BY $SORT $DESC;", undef, $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 crm_lead_points_list() - lead points list

  Arguments:
    $attr
  Returns:
    @list

  Examples:

=cut
#**********************************************************
sub crm_lead_points_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my @WHERE_RULES = ();

  if ($admin->{permissions} && !$admin->{permissions}{7} || !$admin->{permissions}{7}{4}) {
    push @WHERE_RULES, "cl.responsible='$admin->{AID}'";
  }

  my $WHERE = $self->search_former($attr,[
    [ 'ID',            'INT',    'cl.id',            1 ],
    [ 'RESPONSIBLE',   'INT',    'cl.responsible',   1 ],
    [ 'COMPETITOR_ID', 'STR',    'cl.competitor_id', 1 ],
  ], {
    WHERE => 1,
    WHERE_RULES => \@WHERE_RULES
  });

  $self->query("SELECT cl.*, cps.color,cps.name AS step, builds.coordx, builds.coordy, cc.name AS competitor,
      SUM(plpoints.coordx)/COUNT(plpoints.coordx) AS coordy_2,
      SUM(plpoints.coordy)/COUNT(plpoints.coordy) AS coordx_2,
      cc.color AS competitor_color,
      CONCAT(districts.name, ',', streets.name, ',', builds.number) AS address_full
    FROM crm_leads as cl
    LEFT JOIN crm_competitors cc ON (cc.id = cl.competitor_id)
    LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
    LEFT JOIN crm_progressbar_steps cps ON (cps.step_number = cl.current_step)
    LEFT JOIN builds ON (builds.id=cl.build_id)
    LEFT JOIN streets ON (streets.id=builds.street_id)
    LEFT JOIN districts ON (districts.id=streets.district_id)
    LEFT JOIN maps_points mp ON (builds.id=mp.location_id)
    LEFT JOIN maps_point_types mt ON (mp.type_id=mt.id)
    LEFT JOIN maps_coords mc ON (mp.coord_id=mc.id)
    LEFT JOIN maps_polygons mgone ON (mgone.object_id=mp.id)
    LEFT JOIN maps_polygon_points plpoints ON(mgone.id=plpoints.polygon_id)
    $WHERE
    GROUP BY cl.id HAVING (coordx <> 0 AND coordy <> 0) OR (coordx_2 <> 0 AND coordy_2 <> 0)
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 crm_competitors_popular_tps_list ()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_popular_tps_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'cl.tp_id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'cl.tp_id';

  my $EXT_TABLE = '';
  my @WHERE_RULES = ();

  push @WHERE_RULES, "cl.tp_id <> 0";

  if ($attr->{BUILD_ID}) {
    push @WHERE_RULES, "cctg.build_id = $attr->{BUILD_ID}";
  }
  elsif ($attr->{STREET_ID}) {
    push @WHERE_RULES, "(b.street_id = $attr->{STREET_ID} OR cctg.street_id = $attr->{STREET_ID})";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=cctg.build_id)';
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "(s.district_id = $attr->{DISTRICT_ID} OR cctg.district_id = $attr->{DISTRICT_ID})";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=cctg.build_id)';
    $EXT_TABLE .= 'LEFT JOIN streets s ON (s.id=b.street_id OR s.id=cctg.street_id)';
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',              'INT', 'cct.id',                     1 ],
      [ 'NAME',            'STR', 'cct.name',                   1 ],
      [ 'MONTH_FEE',       'INT', 'cct.month_fee',              1 ],
      [ 'DAY_FEE',         'INT', 'cct.day_fee',                1 ],
      [ 'COMPETITOR_ID',   'INT', 'cct.competitor_id',          1 ],
      [ 'COMPETITOR_NAME', 'STR', 'cc.name AS competitor_name', 1 ],
    ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} COUNT(DISTINCT cl.id) as leads_number, cct.id
      FROM crm_leads as cl
      LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
      LEFT JOIN crm_competitors cc ON (cc.id = cl.competitor_id)
      LEFT JOIN crm_competitors_tps cct ON (cl.tp_id = cct.id AND cc.id = cct.competitor_id)
      LEFT JOIN crm_competitor_tps_geolocation cctg ON (cct.id = cctg.tp_id)
      $EXT_TABLE
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 crm_competitors_users_list ()

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_competitors_users_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{sort}) ? $attr->{sort} : 'avg_assessment';
  my $DESC = ($attr->{desc}) ? $attr->{desc} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;
  my $GROUP_BY = $attr->{GROUP_BY} || 'cl.competitor_id';

  my $EXT_TABLE = '';
  my @WHERE_RULES = ();

  push @WHERE_RULES, "cl.competitor_id <> 0";

  if ($attr->{BUILD_ID}) {
    push @WHERE_RULES, "cl.build_id = $attr->{BUILD_ID}";
  }
  elsif ($attr->{STREET_ID}) {
    push @WHERE_RULES, "b.street_id = $attr->{STREET_ID}";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=cl.build_id)';
  }
  elsif ($attr->{DISTRICT_ID}) {
    push @WHERE_RULES, "s.district_id = $attr->{DISTRICT_ID}";
    $EXT_TABLE = 'LEFT JOIN builds b ON (b.id=cl.build_id)';
    $EXT_TABLE .= 'LEFT JOIN streets s ON (s.id=b.street_id)';
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'COMPETITOR_ID',    'INT', 'cl.competitor_id',                                                                    1 ],
      [ 'COMPETITOR_NAME',  'STR', 'cc.name AS competitor_name',                                                          1 ],
      [ 'USERS',            'INT', 'COUNT(cl.id) AS users',                                                               1 ],
      [ 'AVG_ASSESSMENT',   'INT', 'ROUND(AVG(CASE WHEN cl.assessment > 0 THEN cl.assessment END), 1) AS avg_assessment', 1 ],
      [ 'TOTAL_ASSESSMENT', 'INT', 'COUNT(CASE WHEN cl.assessment > 0 THEN cl.assessment END) AS total_assessment',       1 ],
      [ 'LEAD_ID',          'INT', 'cl.id as lead_id',                                                                    1 ],
      [ 'FIO',              'STR', 'cl.fio',                                                                              1 ],
      [ 'PHONE',            'STR', 'cl.phone',                                                                            1 ],
      [ 'ASSESSMENT',       'INT', 'cl.assessment',                                                                       1 ],
    ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES, SKIP_USERS_FIELDS => ['FIO', 'PHONE'] }
  );


  $self->query(
    "SELECT $self->{SEARCH_FIELDS} cc.name AS competitor_name
      FROM crm_leads as cl
      LEFT JOIN crm_competitors cc ON (cc.id = cl.competitor_id)
      $EXT_TABLE
    $WHERE
    GROUP BY $GROUP_BY
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2  fields_add() - Add info

=cut
#**********************************************************
sub fields_add {
  my $self = shift;
  my ($attr) = @_;

  $attr->{SQL_FIELD} = "_" . $attr->{SQL_FIELD};
  my $table_name = $attr->{TP_INFO_FIELDS} ? 'crm_tp_info_fields' : 'crm_info_fields';

  $self->query_add($table_name, $attr);

  return $self;
}

#**********************************************************

=head2  fields_del() - Delete info

=cut

#**********************************************************
sub fields_del {
  my $self = shift;
  my $id = shift;
  my ($attr) = @_;

  my $table_name = $attr->{TP_INFO_FIELDS} ? 'crm_tp_info_fields' : 'crm_info_fields';

  $self->query_del($table_name, { ID => $id });

  return $self->{result};
}

#**********************************************************
=head2 fields_list($attr) - list
a
=cut
#**********************************************************
sub fields_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT', 'id',           1 ],
    [ 'NAME',         'STR', 'name',         1 ],
    [ 'SQL_FIELD',    'STR', 'sql_field',    1 ],
    [ 'TYPE',         'INT', 'type',         1 ],
    [ 'PRIORITY',     'INT', 'priority',     1 ],
    [ 'COMMENT',      'STR', 'comment',      1 ],
    [ 'REGISTRATION', 'INT', 'registration', 1 ]
  ], { WHERE => 1 });

  my $table_name = $attr->{TP_INFO_FIELDS} ? 'crm_tp_info_fields' : 'crm_info_fields';

  $self->query(
    "SELECT *
     FROM `$table_name`
     $WHERE
     ORDER BY $SORT $DESC;",
    undef,
    { COLS_NAME => 1, COLS_UPPER => 1 }
  );

  return $self->{list} || [];
}


#**********************************************************
=head2 fields_change($attr) - change

=cut
#**********************************************************
sub fields_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{REGISTRATION} //= 0;

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => $attr->{TP_INFO_FIELDS} ? 'crm_tp_info_fields' : 'crm_info_fields',
    DATA         => $attr,
  });

  return $self->{result};
}

#**********************************************************
=head2 field_info()

  Arguments:

  Returns:

=cut
#**********************************************************
sub field_info {
  my $self = shift;
  my $id = shift;
  my ($attr) = @_;

  my $table_name = $attr->{TP_INFO_FIELDS} ? 'crm_tp_info_fields' : 'crm_info_fields';

  $self->query("SELECT cif.* FROM $table_name cif WHERE cif.id = ?;", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 lead_field_add($attr) - add lead info field
  Arguments:
    $attr
      FIELD_ID
      FIELD_TYPE

  Returns:
    $self
=cut
#**********************************************************
sub lead_field_add {
  my $self = shift;
  my ($attr) = @_;

  my @column_types = (
    " varchar(120) not null default ''",
    " int(11) NOT NULL default '0'",
    " smallint unsigned NOT NULL default '0' ",
    " text not null ",
    " tinyint(11) NOT NULL default '0' ",
    " content longblob NOT NULL",
    " varchar(100) not null default ''",
    " int(11) unsigned NOT NULL default '0'",
    " varchar(12) not null default ''",
    " varchar(120) not null default ''",
    " varchar(20) not null default ''",
    " varchar(50) not null default ''",
    " varchar(50) not null default ''",
    " int unsigned NOT NULL default '0' ",
    " INT(11) UNSIGNED NOT NULL DEFAULT '0' REFERENCES users(uid) ",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " varchar(120) not null default ''",
    " tinyint(2) not null default '0' ",
    " DATE not null default '0000-00-00' ",
  );

  $attr->{FIELD_TYPE} = 0 if (!$attr->{FIELD_TYPE});

  my $column_type  = $column_types[ $attr->{FIELD_TYPE} ] || " varchar(120) not null default ''";


  my $table = $attr->{TP_INFO_FIELDS} ? 'crm_competitors_tps' : 'crm_leads';

  $self->query('ALTER TABLE ' . $table . ' ADD COLUMN ' .'_' . $attr->{FIELD_ID} . " $column_type;", 'do');

  if (!$self->{errno} || ($self->{errno} && $self->{errno} == 3)) {
    if ($attr->{FIELD_TYPE} == 2) {
      $attr->{FIELD_ID} = 'tp_' . $attr->{FIELD_ID} if $attr->{TP_INFO_FIELDS};
      $self->query("CREATE TABLE _crm_$attr->{FIELD_ID}_list (
        id smallint unsigned NOT NULL primary key auto_increment,
        name varchar(120) not null default 0
        ) DEFAULT CHARSET=$self->{conf}->{dbcharset};", 'do'
      );
    }
  }

  return $self;
}

#**********************************************************
=head2 lead_field_del($attr)

  Arguments:
    $attr
      FIELD_ID
  Returns:
    Object

=cut
#**********************************************************
sub lead_field_del {
  my $self = shift;
  my ($attr) = @_;

  my $table = $attr->{TP_INFO_FIELDS} ? 'crm_competitors_tps' : 'crm_leads';

  $self->query("ALTER TABLE $table DROP COLUMN `$attr->{FIELD_ID}`;", 'do');

  if (!$self->{errno} || $self->{errno} == 3) {
    # my $Conf = Conf->new($self->{db}, $admin, $self->{conf});
    #
    # $Conf->config_del("$attr->{SECTION}$attr->{FIELD_ID}");
  }

  return $self;
}

#**********************************************************
=head2 info_list_add($attr)

=cut
#**********************************************************
sub info_list_add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{LIST_TABLE_NAME}) {
    $self->{errno} = 300;
    $self->{errstr} = 'NO list table';
    return $self;
  }

  $attr->{LIST_TABLE_NAME} = '_tp' . $attr->{LIST_TABLE_NAME} if $attr->{TP_INFO_FIELDS};

  $self->query_add("_crm$attr->{LIST_TABLE_NAME}_list", $attr);

  return $self;
}

#**********************************************************
=head2 info_list_del($attr) - Info list del value

=cut
#**********************************************************
sub info_list_del {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LIST_TABLE_NAME} = '_tp' . $attr->{LIST_TABLE_NAME} if $attr->{TP_INFO_FIELDS};

  $self->query_del("_crm$attr->{LIST_TABLE_NAME}_list", $attr);

  return $self;
}

#**********************************************************
=head2 info_lists_list($attr)

=cut
#**********************************************************
sub info_lists_list {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LIST_TABLE_NAME} = '_tp' . $attr->{LIST_TABLE_NAME} if $attr->{TP_INFO_FIELDS};

  $self->query("SELECT id, name FROM `_crm$attr->{LIST_TABLE_NAME}_list` ORDER BY name;", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 info_list_info($id, $attr)

=cut
#**********************************************************
sub info_list_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $attr->{LIST_TABLE_NAME} = '_tp' . $attr->{LIST_TABLE_NAME} if $attr->{TP_INFO_FIELDS};

  $self->query("SELECT id, name FROM `_crm$attr->{LIST_TABLE_NAME}_list` WHERE id= ? ;", undef, { INFO => 1, Bind => [ $id ] });

  return $self;
}

#**********************************************************
=head2 info_list_change($id, $attr)

=cut
#**********************************************************
sub info_list_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{LIST_TABLE_NAME} = '_tp' . $attr->{LIST_TABLE_NAME} if $attr->{TP_INFO_FIELDS};

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => "_crm$attr->{LIST_TABLE_NAME}_list",
    DATA         => $attr
  });

  return $self->{result};
}


#**********************************************************
=head2 crm_action_add($actions, $attr) - Add crm actions

  Arguments:
    $actions - Action describe
    $attr -
      MODULE
      TYPE

  Results:
    $self

=cut
#**********************************************************
sub crm_action_add {
  my $self = shift;
  my ($actions, $attr) = @_;

  $self->query_add('crm_admin_actions', {
    AID         => $self->{admin}{AID},
    IP          => $self->{admin}{IP} || '0.0.0.0',
    LID         => $attr->{ID},
    DATETIME    => 'NOW()',
    ACTIONS     => $actions,
    ACTION_TYPE => ($attr->{TYPE}) ? $attr->{TYPE}   : ''
  });

  return $self;
}

#**********************************************************
=head2 crm_action_del($action_id)

=cut
#**********************************************************
sub crm_action_del {
  my $self = shift;
  my ($action_id) = @_;

  $self->query_del('crm_admin_actions', { ID => $action_id });

  return $self;
}

#**********************************************************
=head2 crm_action_list($attr)

=cut
#**********************************************************
sub crm_action_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 'ca.id';
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former($attr, [
    ['ACTIONS',           'STR',  'ca.actions',                                       1 ],
    ['LID',               'INT',  'ca.lid',                                           1 ],
    ['TYPE',              'INT',  'ca.action_type',                                   1 ],
    ['IP',                'IP',   'ca.ip', 'INET_NTOA(ca.ip) AS ip',                  1 ],
    ['DATETIME',          'DATE', 'ca.datetime',                                      1 ],
    ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(ca.datetime, '%Y-%m-%d')",             1 ],
    ['AID',               'INT',  'ca.aid',                                           1 ],
    ['ADMIN',             'STR',  'a.id', 'a.id AS admin',                            1 ],
    ['LEAD_FIO',          'STR',  'cl.fio', 'cl.fio AS lead_fio',                     1 ]
  ], { WHERE => 1 });

  $self->query(
    "SELECT $self->{SEARCH_FIELDS} ca.id
     FROM crm_admin_actions ca
      LEFT JOIN admins a ON (ca.aid=a.aid)
      LEFT JOIN crm_leads cl ON (ca.lid=cl.id)
      $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  $self->query("SELECT COUNT(*) AS total FROM crm_admin_actions ca
    LEFT JOIN admins a ON (ca.aid=a.aid)
    $WHERE;",
    undef,
    { INFO => 1 }
  );

  return $list;
}

#**********************************************************
=head2 crm_users_by_lead_email($id)

=cut
#**********************************************************
sub crm_users_by_lead_email {
  my $self = shift;
  my $id = shift;

  $self->query(
    "SELECT cl.id, cl.email, uc.uid, cl.uid AS lead_uid, u.id AS login FROM crm_leads cl
     LEFT JOIN users_contacts uc on (uc.value <> '' AND cl.email=uc.value)
     LEFT JOIN users u ON (u.uid=uc.uid)
     WHERE cl.email <> '' AND cl.id = ?;",
    undef, { INFO => 1, Bind => [ $id ] }
  );

  return $self;
}

#**********************************************************
=head2 crm_lead_watch_add ($lead_id, $attr)

  Argumenst:
    $attr
      AID
      LEAD_ID

  Results:
    $self

=cut
#**********************************************************
sub crm_lead_watch_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('crm_leads_watchers', {
      %$attr,
      AID      => $attr->{AID} || $admin->{AID},
      LEAD_ID => $attr->{LEAD_ID},
      ADD_DATE => 'NOW()'
  });

  return $self->{list};

}

#**********************************************************
=head2 crm_lead_watch_del ($attr)

  Arguments:
    $attr
      LEAD_ID
      AID
=cut
#**********************************************************
sub crm_lead_watch_del {
  my $self = shift;
  my ($attr) = @_;

  my $admin_id = q{};
  if ($attr->{AID}) {
    $admin_id = $admin->{AID};
  }

  $self->query_del('crm_leads_watchers', undef, { AID => $admin_id, LEAD_ID => $attr->{LEAD_ID} });

  return $self->{list};

}

#**********************************************************
=head2 crm_lead_watch_list ($attr)
  Arguments:
    $attr
      LEAD_ID
      AID
=cut
#**********************************************************
sub crm_lead_watch_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
      [ 'LEAD_ID',  'INT', 'lead_id' ],
      [ 'AID',      'INT', 'aid'     ],
  ], { WHERE => 1 });

  $self->query("SELECT lead_id, aid
    FROM crm_leads_watchers
    $WHERE
    ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

1