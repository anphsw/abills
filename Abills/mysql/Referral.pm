package Referral;

=head1 NAME

  Referral SQL

=cut

use strict;
use parent qw( dbcore );

my $conf;

use constant {
  conf_prefix => 'REFERRAL_',
};

my $default_values = {
  MAX_LEVEL          => '0',
  DISCOUNT_COEF      => '0',
  DISCOUNT_NEXT_COEF => '0',
  BONUS_AMOUNT       => '0',
  PAYMENT_ARREARS    => '0',
  BONUS_BILL         => '0',
  PERIOD             => '0',
  REPL_PERCENT     => '0',
};

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

  my $self = { };
  bless( $self, $class );

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  $conf = Conf->new( $self->{db}, $self->{admin}, $self->{conf}, { SKIP_CONF => 1 } );

  return $self;
}

#**********************************************************
=head2 settings_get()

  Arguments:
    $attr
      PARAM - specify name of the only param you want to get

  Returns:
    list

=cut
#**********************************************************
sub settings_get{
  my $self = shift;
  my $attr = shift;

  my $param = $attr->{PARAM} || conf_prefix . '*';
  my $list = $conf->config_list( {
      PARAM     => $param,
      CONF_ONLY => 1,
      COLS_NAME => 1
    } );

  unless ( $attr->{PARAM} ){
    #check for existence of all params
    if ( ref $list ne 'ARRAY' ){
      $list = [ ];
    }
    if ( scalar @{$list} < scalar keys %{ $default_values } ){
      _settings_define( { ALREADY_DEFINED => $list} );
    }
  }

  return _transform_to_hash( $list, { NAME_KEY => 'param', VAL_KEY => 'value' } );
}

#**********************************************************
=head2 max_level_set($all_params)

  Arguments:
    $all_params - arr_ref,  list of new parameters

  Returns:
    1;

  #TODO: When there will be a lot of params, check if need to change

=cut
#**********************************************************
sub settings_set{
  my $self = shift;
  my ($all_params) = @_;

  my %new_params = ();

  #filtering non existent params
  foreach my $param_name ( keys %{$all_params} ){
    if ( defined $default_values->{$param_name} ){
      $new_params{conf_prefix . $param_name} = $all_params->{$param_name};
    }
  }

  foreach my $key ( keys %new_params ){
    my $params = {
      PARAM => $key,
      VALUE => $new_params{$key}
    };

    $params->{REPLACE} = 1;
    $conf->config_add( $params );
  }

  return $conf;
}

#**********************************************************
=head2 settings_define($attr)

  Defines unexistent configuration variables

  Arguments:
    $attr - hash_ref
      ALREADY_DEFINED - list

  Returns:
    1

=cut
#**********************************************************
sub _settings_define{
  my ($attr) = @_;

  my $defined_params = { };
  foreach my $element ( @{ $attr->{ALREADY_DEFINED} } ){
    $defined_params->{$element->{param}} = 1;
  }

  foreach my $param ( keys %{$default_values} ){
    unless ( defined $defined_params->{conf_prefix . $param} ){
      $conf->add( {
          PARAM => conf_prefix . $param,
          VALUE => "$default_values->{$param}"
        } );

      $conf->config_add( {
          PARAM => conf_prefix . $param,
          VALUE => "$default_values->{$param}"
        } );
    }
  }

  return 1;
}

#**********************************************************
=head2 list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
      [ 'UID', 'INT', 'r.uid' ],
      [ 'REFERRAL', 'INT', 'r.referrer', ],
    ],
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT
       r.uid, r.referrer,
        IF(pi.fio='', u.id, CONCAT( pi.fio, ' (', u.id, ')' )) AS id
     FROM referral_main r
       INNER JOIN users u ON (r.uid=u.uid)
       LEFT JOIN users_pi pi ON (r.uid=pi.uid)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self;
}

#**********************************************************
=head2 tp_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub tp_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
    [ 'ID', 'INT', 'r.id', 1 ],
    [ 'NAME', 'str', 'r.name', 1 ],
    [ 'BONUS_AMOUNT', 'INT', 'r.bonus_amount', 1 ],
    [ 'PAYMENT_ARREARS', 'INT', 'r.payment_arrears', 1 ],
    [ 'PERIOD', 'INT', 'r.period', 1],
    [ 'REPL_PERCENT', 'INT', 'r.repl_percent', 1],
    [ 'BONUS_BILL', 'INT', 'r.bonus_bill', 1],
  ],
    {
      WHERE => 1
    }
  );

  $self->query(
    "SELECT
     $self->{SEARCH_FIELDS} r.id
     FROM referral_tp r
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{list} || [];
}

#**********************************************************
=head2 request_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub request_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my $GROUP_BY = $attr->{GROUP_BY} || '';
  my $WHERE = $self->search_former( $attr, [
    [ 'ID', 'INT', 'r.id as referral_request', 1 ],
    [ 'FIO', 'STR', 'r.fio', 1 ],
    [ 'phone', 'STR', 'r.phone', 1 ],
    [ 'ADDRESS', 'STR', 'r.address', 1 ],
    [ 'STATUS', 'INT', 'r.status', 1],
    [ 'UID', 'INT', 'r.referrer as uid', 1],
    [ 'REFERRER', 'INT', 'r.referrer', 1],
    [ 'LOGIN', 'STR', 'u.id as login', 1],
    [ 'DATE', 'STR', 'r.date', 1],
    [ 'TP_ID', 'INT', 'r.tp_id as referral_tp', 1],
    [ 'TP_NAME', 'INT', 'rt.name as tp_name', 1],
    [ 'REFERRAL_UID', 'INT', 'r.referral_uid', 1],
    ['FROM_DATE|TO_DATE', 'DATE', "DATE_FORMAT(r.date, '%Y-%m-%d')" ],
  ],
    {
      WHERE => 1
    }
  );


  $self->query(
    "SELECT
     $self->{SEARCH_FIELDS} r.id
     FROM referral_requests r
     LEFT JOIN users u ON (u.uid = r.referrer)
     LEFT JOIN referral_tp rt ON (r.tp_id = rt.id)
    $WHERE $GROUP_BY ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{list} || [];
}


#**********************************************************
=head2 tp_info($id)

  Arguments:
    id

  Returns:

=cut
#**********************************************************

sub tp_info{
  my $self = shift;
  my ($id) = @_;

  $self->query("SELECT * FROM referral_tp WHERE id = ? ",
    undef,
    {
      INFO => 1,
      Bind => [ $id ],
    }
  );

  return $self;
}

#**********************************************************
=head2 log_list($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub log_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
    [ 'ID', 'INT', 'rl.id' ],
    [ 'UID', 'INT', 'rl.uid', 1 ],
    [ 'DATE', 'STR', 'rl.date', 1 ],
    [ 'REFERRAL_REQUEST', 'STR', 'rl.referral_request', 1 ],
    [ 'TP_ID', 'INT', 'rr.tp_id', 1 ],
    [ 'REFERRER', 'INT', 'rr.referrer', 1 ],
  ],
    {
      WHERE => 1
    }
  );

  if($attr->{COUNT}){
    $self->query("SELECT rr.referrer, COUNT(rl.id) as count, rl.uid, rl.id, rr.tp_id, rl.referral_request
    FROM referral_log rl
    LEFT JOIN referral_requests rr ON (rl.referral_request = rr.id)
    GROUP BY uid;", undef, $attr);
    return $self->{list};
  }

  $self->query(
    "SELECT
       $self->{SEARCH_FIELDS}, rl.id
     FROM referral_log rl
     LEFT JOIN referral_requests rr ON (rl.referral_request = rr.id)
    $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;
     ",
    undef,
    $attr
  );

  return $self->{LIST};
}

#**********************************************************
=head2 info($uid, $attr)

  Arguments:
    $uid   - uid of user
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub info{
  my $self = shift;
  my ($uid) = @_;

  my $list = $self->list( { UID => $uid, COLS_NAME => 1 } )->{list};

  return $list->[0];
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'referral_main', $attr, { REPLACE => 1 } );
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add_request{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'referral_requests', $attr, { REPLACE => 1 } );
}


#**********************************************************
=head2 tp_add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub tp_add{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'referral_tp', $attr, { REPLACE => 1 } );
}

#**********************************************************
=head2 add($attr)

  Arguments:
    $attr - hash_ref

  Returns:

=cut
#**********************************************************
sub add_log{
  my $self = shift;
  my ($attr) = @_;

  return $self->query_add( 'referral_log', $attr, { REPLACE => 1 } );
}

#**********************************************************
=head2 del($id)

  Arguments:


  Returns:

=cut
#**********************************************************
sub del{
  my $self = shift;
  my ($id) = @_;

  return $self->query_del( 'referrals_main', { UID => $id } );
}

#**********************************************************
=head2 del($id)

  Arguments:


  Returns:

=cut
#**********************************************************
sub del_request{
  my $self = shift;
  my ($id) = @_;

  return $self->query_del( 'referral_requests', { ID => $id } );
}


#**********************************************************
=head2 tp_del($id)

  Arguments:


  Returns:

=cut
#**********************************************************
sub tp_del{
  my $self = shift;
  my ($id) = @_;

  return $self->query_del( 'referral_tp', { ID => $id } );
}

#**********************************************************
=head2 change($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub change{
  my $self = shift;
  my ($attr) = @_;

  return $self->changes( $attr );
}


#**********************************************************
=head2 change_request($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub change_request{
  my $self = shift;
  my ($attr) = @_;

  return $self->changes( {
    CHANGE_PARAM => 'ID',
    TABLE        => 'referral_requests',
    DATA         => $attr
  } );
}

#**********************************************************
=head2 tp_change($attr)

  Arguments:


  Returns:

=cut
#**********************************************************
sub tp_change{
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'referral_tp',
      DATA         => $attr
    }
  );
}

#**********************************************************
=head2 get_user_info($uid)

  Arguments:
    $uid - Users ID

  Returns:
    hash_ref
      UID => 'FIO ( ID )'

=cut
#**********************************************************
sub get_user_info{
  my $self = shift;
  my ($uid) = @_;

  delete $self->{COLS_NAME_ARR};
  delete $self->{COL_NAMES_ARR};

  $self->query( "
  SELECT
     u.uid,
     u.id AS login,
     pi.fio AS fio,
     IF(pi.fio='', u.id, CONCAT( pi.fio, ' (', u.id, ')' )) AS id
   FROM users u
   INNER JOIN users_pi pi ON (u.uid=pi.uid)
   WHERE u.uid = ?
  ", undef, { COLS_NAME => 1, Bind => [ $uid ] } );

  my $list = $self->{list};

  if ( ref $list eq 'ARRAY' && scalar @{$list} > 0 ){
    return $list->[0] || {};
  }

  return {};
}

#**********************************************************
=head2 get_referrers_list() - get all users who are referrers

  Arguments:


  Returns:
    list of all users who are referrers

=cut
#**********************************************************
sub get_referrers_list{
  my $self = shift;

  delete $self->{COL_NAMES_ARR};

  $self->query( "
  SELECT DISTINCT(u.uid),
     u.id AS login,
     pi.fio AS fio,
     IF(pi.fio='', u.id, CONCAT( pi.fio, ' (', u.id, ')' )) AS id
   FROM users u
   INNER JOIN referral_main r ON (r.referrer=u.uid)
   LEFT JOIN users_pi pi ON (u.uid=pi.uid)
  ", undef, { COLS_NAME => 1 } );

  return $self->{list} || [];
}

#**********************************************************
=head2 transform_to_hash($list, $attr)

  Transforms arr_ref of hash_ref to one hash_ref

  Arguments:
    $list - DB list, arr_ref of hash_ref
    $attr
      NAME_KEY
      VAL_KEY

  Returns:
    hash_ref

=cut
#**********************************************************
sub _transform_to_hash{
  my ($list, $attr) = @_;

  my $name_key = $attr->{NAME_KEY};
  my $val_key = $attr->{VAL_KEY};

  if ( !$list || scalar @{$list} == 0 ){
    return { };
  }

  my $result = { };

  foreach my $element ( @{$list} ){
    $result->{$element->{$name_key}} = $element->{$val_key};
  }

  return $result
}

1;
