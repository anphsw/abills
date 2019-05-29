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

  $self->query_add('crm_leads', {%$attr, DATE => $attr->{DATE} || 'NOW()'});

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

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'crm_leads',
      DATA         => $attr
    }
  );

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
      WHERE cl.id = ?;", undef, {COLS_NAME => 1, COLS_UPPER=> 1, Bind => [ $attr->{ID} ] }
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

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 999999;

  my @WHERE_RULES = ();

  if($attr->{FROM_DATE}){
    push @WHERE_RULES, "date >= '$attr->{FROM_DATE}'";
  }

  if($attr->{TO_DATE}){
    push @WHERE_RULES, "date <= '$attr->{TO_DATE}'";
  }

#  if($attr->{SOURCE_ID}){
#    push @WHERE_RULES, "source = '$attr->{SOURCE_ID}'";
#  }

  if($attr->{PHONE_SEARCH}){
    push @WHERE_RULES, "cl.phone LIKE '\%$attr->{PHONE_SEARCH}\%'";
  }

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'LEAD_ID',          'INT',   'cl.id as lead_id',               1 ],
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
      [ 'LAST_ACTION',      'STR',   'cl.id as last_action',           1 ],
      [ 'PRIORITY' ,        'STR',   'cl.priority',                    1 ],
      [ 'PERIOD',           'DATE',  'cl.date as period',                        1 ],
      [ 'SOURCE',         'INT',   'cl.source',                   1 ],
      [ 'COMMENTS',         'STR',   'cl.comments',                      ],
      [ 'TAG_IDS' ,        'STR',   'cl.tag_ids',                      1 ],
    ],
    {
      WHERE             => 1,
      USERS_FIELDS_PRE  => 1,
      SKIP_USERS_FIELDS => ['FIO', 'PHONE', 'EMAIL', 'COMMENTS', 'DOMAIN_ID'],
      WHERE_RULES       => \@WHERE_RULES,
    }
  );


#  $WHERE .= ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
    $self->{SEARCH_FIELDS}
    cl.id as lead_id, cl.uid, cl.id
    FROM crm_leads as cl
    LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
    LEFT JOIN crm_progressbar_steps cps ON (cps.step_number = cl.current_step)
    LEFT JOIN admins a ON (a.aid = cl.responsible)
    LEFT JOIN users u ON (u.uid = cl.uid)
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT COUNT(*) AS total
   FROM crm_leads as cl
   LEFT JOIN crm_leads_sources cls ON (cls.id = cl.source)
    LEFT JOIN crm_progressbar_steps cps ON (cps.step_number = cl.current_step)
    LEFT JOIN admins a ON (a.aid = cl.responsible)
    LEFT JOIN users u ON (u.uid = cl.uid)
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
  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 2;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',          'INT', 'id',           1 ],
      [ 'STEP_NUMBER', 'INT', 'step_number',  1 ],
      [ 'NAME',        'STR', 'name',         1 ],
      [ 'COLOR',       'STR', 'color',        1 ],
      [ 'DESCRIPTION', 'STR', 'description',  1 ],
    ],
    { WHERE => 1, }
  );

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query(
    "SELECT
    id,
    step_number,
    name,
    color,
    description
    FROM crm_progressbar_steps 
    $WHERE
    ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list};

  return $self->{list} if ($self->{TOTAL} < 1);

  $self->query(
    "SELECT count(*) AS total
   FROM crm_progressbar_steps",
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

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'cls.id',       1 ],
      [ 'NAME',       'STR',    'cls.name',     1 ],
      [ 'COMMENTS',   'STR',    'cls.comments', 1 ],
    ],
    { WHERE => 1, }
  );

  $self->query(
    "SELECT
    cls.id,
    cls.name,
    cls.comments
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
   FROM crm_leads_sources",
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

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 'id';
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : 'DESC';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 99999;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'cpsc.id',           1 ],
      [ 'STEP_ID',    'INT',    'cpsc.step_id',      1 ],
      [ 'LEAD_ID',    'INT',    'cpsc.lead_id',      1 ],
      [ 'MESSAGE',    'STR',    'cpsc.message',      1 ],
      [ 'DATE',       'DATE',   'cpsc.date',         1 ],
      [ 'ADMIN',      'STR',    'a.id as admin',     1 ],
      [ 'ACTION',     'STR',    'ca.name as action', 1 ],
      [ 'AID',        'INT',    'cpsc.aid', 1 ],
      [ 'LEAD_FIO',   'STR',    'cl.fio as lead_fio', 1 ],
      [ 'PLANNED_DATE',       'DATE',   'cpsc.planned_date',         1 ],
    ],
    { WHERE => 1, }
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
   FROM crm_progressbar_step_comments",
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
=head2 crm_actions_list() - return list of actions

  Arguments:
    ATTRIBUTES -
  Returns:

  Examples:

=cut
#**********************************************************
sub crm_actions_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT        = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC        = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG          = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS   = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former(
    $attr,
    [
      [ 'ID',         'INT',    'ca.id',       1 ],
      [ 'NAME',       'STR',    'ca.name',     1 ],
      [ 'ACTION',     'STR',    'ca.action',   1 ],
    ],
    { WHERE => 1, }
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
   FROM crm_actions",
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

  $self->query("UPDATE `crm_leads` SET tag_ids='$attr->{TAG_IDS}' WHERE id=?",
    "do",
    {
      Bind => [
        $attr->{LEAD_ID}
      ]
    });

  return $self;
}

1