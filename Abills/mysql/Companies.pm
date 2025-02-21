package Companies;

=head1 NAME

  Companies

=cut

use strict;
use parent qw(dbcore);
use Users;
use Conf;
use Bills;

my $users;
my $admin;
my $CONF;
my $MODULE = 'Companies';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db = shift;
  ($admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  $users = Users->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 add($attr) - Add companies

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{NAME}) {
    $self->{errno} = 8;
    $self->{errstr} = 'ERROR_ENTER_NAME';
    return $self;
  }

  if ($attr->{CONTRACT_TYPE}) {
    my (undef, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  require Info_fields;
  Info_fields->import();
  my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});

  $attr = $Info_fields->info_field_attach_add({ %$attr, COMPANY_PREFIX => 1 });

  $self->query_add('companies', { %$attr,
    REGISTRATION => $attr->{REGISTRATION} || 'NOW()',
  });

  if ($self->{errno}) {
    return $self;
  }

  $self->{COMPANY_ID} = $self->{INSERT_ID};

  if ($attr->{CREATE_BILL}) {
    $self->change({
      DISABLE         => int($attr->{DISABLE} || 0),
      ID              => $self->{COMPANY_ID},
      CREATE_BILL     => 1,
      CREATE_EXT_BILL => $attr->{CREATE_EXT_BILL}
    });
  }

  $admin->{MODULE} = $MODULE;

  my @info = ('CREATE_BILL', 'CREDIT', 'BANK_NAME', 'BANK_ACCOUNT', 'BANK_BIC', 'COR_BANK_ACCOUNT', 'TAX_NUMBER', 'REPRESENTATIVE');
  my %actions_history = ();

  foreach my $param (@info) {
    next if !$attr->{$param};
    $actions_history{$param} = $attr->{$param};
  }

  $admin->action_add(0, join(", ", map {"$_: $actions_history{$_}"} keys %actions_history), { TYPE => 1 });

  return $self;
}

#**********************************************************
=head2 change($attr) Change

  Arguments:
    $attr
      ID - Main parameter

  Resturn:
    $self

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;

  if (!defined($attr->{DISABLE})) {
    $attr->{DISABLE} = 0;
  }

  if ($attr->{CREATE_BILL}) {
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({
      COMPANY_ID => $self->{ID} || $attr->{ID},
      UID        => 0
    });
    if ($Bill->{errno}) {
      $self->{errno} = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{BILL_ID} = $Bill->{BILL_ID};

    if ($attr->{CREATE_EXT_BILL}) {
      $Bill->create({ COMPANY_ID => $self->{ID} || $attr->{ID} });
      if ($Bill->{errno}) {
        $self->{errno} = $Bill->{errno};
        $self->{errstr} = $Bill->{errstr};
        return $self;
      }
      $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
    }
  }
  elsif ($attr->{CREATE_EXT_BILL}) {
    my $Bill = Bills->new($self->{db}, $admin, $CONF);
    $Bill->create({ COMPANY_ID => $self->{ID} });

    if ($Bill->{errno}) {
      $self->{errno} = $Bill->{errno};
      $self->{errstr} = $Bill->{errstr};
      return $self;
    }
    $attr->{EXT_BILL_ID} = $Bill->{BILL_ID};
  }

  $attr->{DOMAIN_ID} = $admin->{DOMAIN_ID};

  require Info_fields;
  Info_fields->import();
  my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
  $attr = $Info_fields->info_field_attach_add({ %$attr, COMPANY_PREFIX => 1 });

  my ($prefix, $sufix);
  if ($attr->{CONTRACT_TYPE}) {
    ($prefix, $sufix) = split(/\|/, $attr->{CONTRACT_TYPE});
    $attr->{CONTRACT_SUFIX} = $sufix;
  }

  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'companies',
    DATA         => $attr
  });

  $admin->{MODULE} = $MODULE;

  my @info = ('CREATE_BILL', 'CREDIT', 'BANK_NAME', 'BANK_ACCOUNT', 'BANK_BIC', 'COR_BANK_ACCOUNT', 'TAX_NUMBER', 'REPRESENTATIVE');
  my %actions_history = ();

  foreach my $param (@info) {
    next if !$attr->{$param};
    $actions_history{$param} = $attr->{$param};
  }

  $admin->action_add(0, join(", ", map {"$_: $actions_history{$_}"} keys %actions_history), { TYPE => 2 });

  $self->info($attr->{ID});

  return $self;
}

#**********************************************************
=head2 del($company_id)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($company_id) = @_;

  $self->query_del('companies', { ID => $company_id });

  $admin->{MODULE} = $MODULE;

  $admin->action_add(0, "DELETED COMPANY: $company_id", { TYPE => 10 });

  return $self;
}

#**********************************************************
=head2 info($company_id) - Info

  Arguments:
    $company_info

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($company_id) = @_;

  my @search_fields = ();
  my $EXT_TABLES = '';

  require Info_fields;
  Info_fields->import();
  my $Info_fields = Info_fields->new($self->{db}, $admin, $CONF);
  my $info_fields_list = $Info_fields->fields_list({ COMPANY => 1, COLS_NAME => 1 });

  foreach my $field (@{$info_fields_list}) {
    my $field_name = $field->{sql_field};
    my $type = $field->{type} || 0;
    next if ($type ne '2');
    push(@search_fields,
      "`$field_name\_list`.name AS `$field_name`",
      "`$field_name` AS `$field_name\_id`"
    );
    $EXT_TABLES .= "LEFT JOIN `$field_name" . "_list` ON (c.`$field_name` = `$field_name" . "_list`.id)";
  }

  my $search_fields = q{};

  if ($#search_fields > -1) {
    $search_fields = join(', ', @search_fields) .', ';
  }

  $self->query("SELECT c.*, $search_fields
     b.deposit
    FROM companies c
    LEFT JOIN bills b ON (c.bill_id=b.id)
    $EXT_TABLES
    WHERE c.id= ? ;",
    undef,
    { INFO => 1,
      Bind => [
        $company_id
      ] }
  );

  if ($self->{TOTAL} < 1) {
    $self->{errno} = 2;
    $self->{errstr} = 'ERROR_NOT_EXIST';
    return $self;
  }

  if ($CONF->{EXT_BILL_ACCOUNT} && $self->{EXT_BILL_ID} > 0) {
    $self->query("SELECT b.deposit AS ext_bill_deposit, b.uid AS ext_bill_owner
     FROM bills b WHERE id= ? ;",
      undef,
      { INFO => 1, Bind => [ $self->{EXT_BILL_ID} ] }
    );
  }

  return $self;
}

#**********************************************************
=head2 list($attr) - List

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $attr->{SKIP_DEL_CHECK} = 1;
  $attr->{_COMPANY_LIST}  = 1;

  my @WHERE_RULES = ();
  my $WHERE = $self->search_former($attr, [
    [ 'COMPANY_NAME', 'STR', 'company.name', ],
    [ 'DEPOSIT', 'INT', 'cb.deposit', 1 ],
    [ 'CREDIT', 'INT', 'company.credit', 1 ],
    [ 'USERS_COUNT', 'INT', 'COUNT(u.uid) AS users_count', 1 ],
    [ 'CREDIT_DATE', 'DATE', 'company.credit_date', 1 ],
    [ 'ADDRESS', 'STR', 'company.address', 1 ],
    [ 'REGISTRATION', 'DATE', 'company.registration', 1 ],
    [ 'DISABLE', 'INT', 'company.disable AS status', 1 ],
    [ 'CONTRACT_ID', 'INT', 'company.contract_id', 1 ],
    [ 'CONTRACT_DATE', 'DATE', 'company.contract_date', 1 ],
    [ 'CONTRACT_SUFIX', 'STR', 'company.contract_sufix', 1 ],
    [ 'ID', 'INT', 'company.id' ],
    [ 'BILL_ID', 'INT', 'company.bill_id', 1 ],
    [ 'TAX_NUMBER', 'STR', 'company.tax_number', 1 ],
    [ 'BANK_ACCOUNT', 'STR', 'company.bank_account', 1 ],
    [ 'BANK_NAME', 'STR', 'company.bank_name', 1 ],
    [ 'COR_BANK_ACCOUNT', 'STR', 'company.cor_bank_account', 1 ],
    [ 'BANK_BIC', 'STR', 'company.bank_bic', 1 ],
    [ 'PHONE', 'STR', 'company.phone', 1 ],
    [ 'VAT', 'INT', 'company.vat', 1 ],
    [ 'EXT_BILL_ID', 'INT', 'company.ext_bill_id', 1 ],
    [ 'DOMAIN_ID', 'INT', 'company.domain_id', 1 ],
    [ 'REPRESENTATIVE', 'STR', 'company.representative', 1 ],
    [ 'LOCATION_ID', 'INT', 'company.location_id', 1 ],
    [ 'ADDRESS_FLAT', 'STR', 'company.address_flat', 1 ],
    [ 'COMPANY_ADMIN', 'INT', 'ca.uid', 'ca.uid AS company_admin' ],
    [ 'COMPANY_ID', 'INT', 'company.id', ],
    [ 'EDRPOU', 'STR', 'company.edrpou', 1 ],
    [ 'COMMENTS', 'STR', 'company.comments', 1 ],
    #['DOMAIN_ID',      'INT',  'company.domain_id',     1 ],
  ],
    {
      WHERE_RULES       => \@WHERE_RULES,
      USERS_FIELDS_PRE  => 1,
      #USE_USER_PI      => 1,
      SKIP_USERS_FIELDS => [ 'DEPOSIT', 'CREDIT', 'BILL_ID', 'CREDIT_DATE', 'ADDRESS',
        'REGISTRATION', 'CONTRACT_ID', 'CONTRACT_DATE', 'PHONE', 'FIO',
        'DOMAIN_ID', 'LOCATION_ID', 'ADDRESS_FLAT', 'DOMAIN_ID', 'COMPANY_NAME', 'EDRPOU', 'COMMENTS'
      ],
      WHERE             => 1,
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES};
  if ($attr->{COMPANY_ADMIN}) {
    $EXT_TABLE .= "LEFT JOIN companie_admins ca ON (ca.company_id=company.id)";
  }

  $self->query("SELECT company.name, $self->{SEARCH_FIELDS} company.id
    FROM companies company
    LEFT JOIN users u ON (u.company_id=company.id)
    $EXT_TABLE
    $WHERE
    GROUP BY company.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  if ($self->{TOTAL} > 0 || $PG > 0) {
    $self->query("SELECT COUNT(DISTINCT company.id) AS total
    FROM companies company
    LEFT JOIN users u ON (u.company_id=company.id)
    $EXT_TABLE
    $WHERE;",
      undef,
      { INFO => 1 });
  }

  return $list;
}

#**********************************************************
=head2 admins_list($attr)

=cut
#**********************************************************
sub admins_list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
  my $PG = ($attr->{PG}) ? $attr->{PG} : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, "u.uid='$attr->{UID}'";
  }

  if ($attr->{GET_ADMINS}) {
    push @WHERE_RULES, "ca.uid>0";
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "c.id='$attr->{COMPANY_ID}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' AND ', @WHERE_RULES) : q{};

  $self->query("SELECT IF(ca.uid IS null, 0, 1) AS is_company_admin,
      u.id AS login,
      pi.fio,
      (SELECT GROUP_CONCAT(value SEPARATOR ';') FROM `users_contacts` uc WHERE uc.uid=u.uid AND type_id=9) AS email,
      u.uid,
      ca.company_id
    FROM companies  c
    INNER JOIN users u ON (u.company_id=c.id)
    LEFT JOIN companie_admins ca ON (ca.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    $WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  my $list = $self->{list} || [];

  return $list;
}

#**********************************************************
=head2 admins_change($attr)

=cut
#**********************************************************
sub admins_change {
  my $self = shift;
  my ($attr) = @_;

  my @ADMINS = split(/,\s?/, $attr->{IDS});

  $self->query_del('companie_admins', undef, { company_id => $attr->{COMPANY_ID} });

  foreach my $uid (@ADMINS) {
    $self->query_add('companie_admins', {
      %$attr,
      UID => $uid
    });
  }

  return $self;
}

#**********************************************************
=head2 admins_del($attr)

=cut
#**********************************************************
sub admins_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query_del('companie_admins', undef, { UID => $attr->{UID} || '--' });

  return $self;
}

1
