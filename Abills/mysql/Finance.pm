package Finance;

=head NAME

  Finance module
    fees
    payments

=cut

use strict;
use parent 'dbcore';

#**********************************************************
# Init Finance module
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless( $self, $class );

  return $self;
}

#**********************************************************
# fees
#**********************************************************
#@returns Fees
sub fees{
  my (undef, $db, $admin, $CONF) = @_;

  require Fees;
  Fees->import();
  my $Fees = Fees->new( $db, $admin, $CONF );

  return $Fees;
}


#**********************************************************
# Init 
#**********************************************************
#@returns Payments
sub payments {
  my (undef, $db, $admin, $CONF) = @_;

  require Payments;
  Payments->import();
  my $Payments = Payments->new( $db, $admin, $CONF);

  return $Payments;
}

#**********************************************************
=head2 exchange_list($attr)

=cut
#**********************************************************
sub exchange_list{
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $sql = <<"SQL";
  SELECT money, short_name, rate, iso, changed, id
    FROM exchange_rate
    ORDER BY $SORT $DESC;
SQL

  $self->query($sql, undef, $attr );

  return $self->{list};
}


#**********************************************************
=head2 exchange_add($attr)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub exchange_add{
  my ($self, $attr) = @_;

  my $money = (defined( $attr->{ER_NAME} )) ? $attr->{ER_NAME} : '';
  my $short_name = (defined( $attr->{ER_SHORT_NAME} )) ? $attr->{ER_SHORT_NAME} : '';
  my $rate = (defined( $attr->{ER_RATE} )) ? $attr->{ER_RATE} : '0';

  my $sql = <<'SQL';
INSERT INTO exchange_rate (money, short_name, rate, iso, changed)
values (?, ?, ?, ?, NOW());
SQL

  my @binds = (
    $money,
    $short_name,
    $rate,
    $attr->{ISO}
  );

  $self->query($sql, 'do', { Bind => \@binds } );

  return $self if ($self->{errno});

  $self->exchange_log_add({
    RATE_ID => $self->{INSERT_ID},
    RATE    => $rate
  });

  $self->{admin}->{MODULE} = '';
  $self->{admin}->system_action_add( "$money/$short_name/$rate", { TYPE => 41 } );

  return $self;
}


#**********************************************************
=head2 exchange_del($id)

  Arguments:
    $id

  Results:
    $self

=cut
#**********************************************************
sub exchange_del{
  my ($self, $id) = @_;

  $self->query_del( 'exchange_rate', { ID => $id } );

  $self->{admin}->system_action_add( $id, { TYPE => 42 } );

  return $self;
}

#**********************************************************
=head2 exchange_change($id, $attr)

  Arguments:
    $id
    $attr

  Results:
    $self

=cut
#**********************************************************
sub exchange_change{
  my ($self, $id, $attr) = @_;

  my $money = (defined( $attr->{ER_NAME} )) ? $attr->{ER_NAME} : '';
  my $short_name = (defined( $attr->{ER_SHORT_NAME} )) ? $attr->{ER_SHORT_NAME} : '';
  my $rate = (defined( $attr->{ER_RATE} )) ? $attr->{ER_RATE} : '0';

  my $sql = <<'SQL';
UPDATE exchange_rate
SET
  money     = ?,
  short_name= ?,
  rate      = ?,
  iso       = ?,
  changed   = NOW()
WHERE id = ? ;
SQL

  my @binds = (
    $money,
    $short_name,
    $rate,
    $attr->{ISO},
    $id
  );

  $self->query($sql, 'do', { Bind => \@binds  } );

  if ($self->{errno}) {
    return $self
  }

  $self->exchange_log_add({
    RATE_ID => $id,
    RATE    => $rate
  });

  $self->{admin}->system_action_add( "$money/$short_name/$rate", { TYPE => 41 } );

  return $self;
}

#**********************************************************
=head2 exchange_info($id, $attr)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub exchange_info {
  my ($self, $id, $attr) = @_;

  my $WHERE = '';
  if ( $attr->{SHORT_NAME} ){
    $WHERE = "short_name='$attr->{SHORT_NAME}'";
  }
  elsif ( $attr->{ISO} ){
    $WHERE = "iso='$attr->{ISO}'";
  }
  else{
    $WHERE = "id='$id'";
  }

  my $sql = <<"SQL";
SELECT money AS er_name,
       short_name AS er_short_name,
       rate AS er_rate,
       iso,
       changed
FROM exchange_rate
WHERE $WHERE;
SQL

  $self->query($sql,  undef,  { INFO => 1 } );

  return $self;
}


#**********************************************************
=head2 exchange_log_list($attr)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub exchange_log_list{
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG   = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $self->{COL_NAMES_ARR} = undef;

  my @WHERE_RULES = ();

  if ( $attr->{DATE} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{DATE}, 'DATE', 'rl.date' ) };
  }

  if ( $attr->{ID} ){
    push @WHERE_RULES, @{ $self->search_expr( $attr->{ID}, 'INT', 'r.id' ) };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join( ' and ', @WHERE_RULES ) : '';

  my $sql = <<"SQL";
SELECT rl.date, r.money, rl.rate, rl.id, r.iso
FROM exchange_rate_log rl
       LEFT JOIN exchange_rate  r ON (r.id=rl.exchange_rate_id)
  $WHERE
ORDER BY $SORT $DESC
LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, $attr );

  return $self->{list};
}

#**********************************************************
=head2 exchange_log_add($id)

  Arguments:
    $attr

  Results:
    $self

=cut
#**********************************************************
sub exchange_log_add{
  my ($self, $attr) = @_;

  $self->query_add('exchange_rate_log', {
    %$attr,
    DATE             => 'NOW()',
    EXCHANGE_RATE_ID => $attr->{RATE_ID}
  });

  return $self;
}

#**********************************************************
=head2 exchange_log_del($id)

  Arguments:
    $id

  Results:
    $self

=cut
#**********************************************************
sub exchange_log_del{
  my ($self, $id) = @_;

  $self->query_del('exchange_rate_log', { ID => $id });

  $self->{admin}->system_action_add($id, { TYPE => 42 });

  return $self;
}

1;
