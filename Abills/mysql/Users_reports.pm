package Users_reports;

=head1 NAME

  Users reports

=cut

use strict;
use parent 'dbcore';
use Conf;

my $admin;
my $CONF;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db) = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = '';

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 report_users_summary($attr)

  Argumnets:

  Results:
    $self

=cut
#**********************************************************
sub report_users_summary {
  my $self = shift;

  my @WHERE_RULES = ();
  if ($admin->{GID}) {
    $admin->{GID} =~ s/,/;/g;
    push @WHERE_RULES, @{$self->search_expr($admin->{GID}, 'INT', 'u.gid')};
  }

  if ($admin->{DOMAIN_ID}) {
    push @WHERE_RULES, @{$self->search_expr($admin->{DOMAIN_ID}, 'INT', 'u.domain_id')};
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' AND ', @WHERE_RULES) : '';

  $self->query("SELECT COUNT(*) AS total_users,
      SUM(IF(u.disable>0, 1, 0)) AS disabled_users,
      SUM(IF(u.credit>0, 1, 0)) AS creditors_count,
      SUM(IF(u.credit>0, u.credit, 0)) AS creditors_sum,
      SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, 1, 0)) AS debetors_count,
      SUM(IF(IF(company.id IS NULL, b.deposit, cb.deposit)<0, b.deposit, 0)) AS debetors_sum
    FROM users u
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    WHERE u.deleted=0 $WHERE
    ;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 report_users_disabled($attr) - report for users disabled

  Arguments:
    $attr
  Returns:
    $self

=cut
#**********************************************************
sub report_users_disabled {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 10000;

  my @WHERE_RULES = ("u.disable <> 0");

  my $WHERE = $self->search_former($attr, [
    [ 'ID',           'INT',  'u.id',           1 ],
    [ 'DISABLE',      'INT',  'u.disable',      1 ],
    [ 'DISABLE_DATE', 'DATE', 'u.disable_date', 1 ],
  ],
    { WHERE => 1, WHERE_RULES => \@WHERE_RULES }
  );

  $self->query("
    SELECT
      DATE_FORMAT(u.disable_date, '%Y-%m') AS disable_date,
      SUM(IF(u.disable=1, 1, 0)) as disable,
      SUM(IF(u.disable=2, 1, 0)) as not_active,
      SUM(IF(u.disable=3, 1, 0)) as hold_up,
      SUM(IF(u.disable=4, 1, 0)) as non_payment,
      SUM(IF(u.disable=5, 1, 0)) as err_small_deposit
    FROM users u
    $WHERE
    GROUP BY disable_date
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} || [];
}


#**********************************************************
=head2 all_data_for_report($attr) - get all data per month

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub all_data_for_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
    months.month  as month,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') <= CONCAT(?,'-', months.month)),0) AS count_all_users,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') = CONCAT(?,'-', months.month)),0)  AS count_new_users,
    IFNULL((SELECT SUM(p.sum)
      FROM payments p
      WHERE DATE_FORMAT(p.date, '%Y-%m') = CONCAT(?, '-', months.month)
      AND NOT p.method = '4'), 0)                AS payments_for_every_month,
    IFNULL((SELECT COUNT(distinct internet.uid)
      FROM internet_main internet
      WHERE DATE_FORMAT(internet.registration, '%Y-%m') <= CONCAT(?, '-', months.month)), 0) AS count_activated_users,
    IFNULL((SELECT SUM(f.sum)
      FROM  fees f
      WHERE (DATE_FORMAT(f.date, '%Y-%m')=CONCAT(?, '-', months.month))),0) as fees_sum,
    IFNULL(( SELECT COUNT(internet2.id)
      FROM internet_main internet2
      JOIN tarif_plans tr ON internet2.tp_id=tr.tp_id
      WHERE (DATE_FORMAT(internet2.registration, '%Y-%m')<=CONCAT(?, '-', months.month) AND internet2.disable=0)),0) AS total_active_services,
    IFNULL(( SELECT SUM(tr.month_fee)
      FROM internet_main internet2
      JOIN tarif_plans tr ON internet2.tp_id=tr.tp_id
      WHERE (DATE_FORMAT(internet2.registration, '%Y-%m')<=CONCAT(?, '-', months.month) AND internet2.disable=0)),0) AS month_fee_sum
    FROM (SELECT '01' AS month
      UNION SELECT '02' AS month
      UNION SELECT '03' AS month
      UNION SELECT '04' AS month
      UNION SELECT '05' AS month
      UNION SELECT '06' AS month
      UNION SELECT '07' AS month
      UNION SELECT '08' AS month
      UNION SELECT '09' AS month
      UNION SELECT '10' AS month
      UNION SELECT '11' AS month
      UNION SELECT '12' AS month) as months
    GROUP BY month;",
    undef,
    { %{$attr}, Bind => [ $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR}, $attr->{YEAR} ] }
  );

  return $self->{list} || {};
}

#**********************************************************
=head2 all_new_report($attr) - get all data per month

  Arguments:
    $attr -

  Returns:

=cut
#**********************************************************
sub all_new_report {
  my $self = shift;
  my ($attr) = @_;

  $self->query("SELECT
    months.month  as month,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') <= CONCAT(?,'-', months.month)),0) AS count_all_users,
    IFNULL((SELECT COUNT(u.uid)
      FROM users u
      WHERE DATE_FORMAT(u.registration, '%Y-%m') = CONCAT(?,'-', months.month)),0)  AS count_new_users
    FROM (SELECT '01' AS month
      UNION SELECT '02' AS month
      UNION SELECT '03' AS month
      UNION SELECT '04' AS month
      UNION SELECT '05' AS month
      UNION SELECT '06' AS month
      UNION SELECT '07' AS month
      UNION SELECT '08' AS month
      UNION SELECT '09' AS month
      UNION SELECT '10' AS month
      UNION SELECT '11' AS month
      UNION SELECT '12' AS month) as months
    GROUP BY month;",
    undef,
    { %{$attr}, Bind => [ $attr->{YEAR}, $attr->{YEAR} ] }
  );

  return $self->{list} || {};
}


1;