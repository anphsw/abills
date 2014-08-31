package Docs;
# Documents functions functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");
my $MODULE = 'Docs';

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $admin->{MODULE} = $MODULE;
  my $self = {};
  bless($self, $class);
  $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} = 30 if (!$CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD});
  $CONF->{DOCS_INVOICE_ORDERS}=12 if (! $CONF->{DOCS_INVOICE_ORDERS});
  $CONF->{DOCS_ACCOUNT_EXPIRE_DAY}=0 if (! $CONF->{DOCS_ACCOUNT_EXPIRE_DAY});
  
  $self->{db}=$db;
  
  return $self;
}

#**********************************************************
# Default values
#**********************************************************
sub invoice_defaults {
  my $self = shift;

  %DATA = (
    SUM             => '0.00',
    COUNTS          => 1,
    UNIT            => 1,
    PAYMENT_ID      => 0,
    PHONE           => '',
    VAT             => '',
    DEPOSIT         => 0,
    DELIVERY_STATUS => 0,
    EXCHANGE_RATE   => 0,
    DOCS_CURRENCY   => 0,
    CUSTOMER        => '',
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# docs_receipt_list
#**********************************************************
sub docs_receipt_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  @WHERE_RULES = ("d.id=o.receipt_id");

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'd.uid'                               ],
      ['LOGIN',          'STR', 'u.id'                                ],    
      ['SUM',            'INT', 'o.price * o.counts'                  ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                           ],
      ['PAYMENT_ID',     'INT', 'd.payment_id',                       ],
      ['DOC_ID',         'INT', 'd.receipt_num',                      ],
      ['AID',            'INT', 'a.id',                               ],
      ['CUSTOMER',       'STR', 'd.customer',                         ],
      ['FROM_DATE|TO_DATE','INT', "date_format(d.date, '%Y-%m-%d')"   ],
      ['PHONE',          'INT', 'if (d.phone<>0, d.phone, pi.phone)', 'if (d.phone<>0, d.phone, pi.phone) AS phone'   ],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1
    }    
    );

  if ($attr->{ORDERS_LIST}) {
    $self->query2("SELECT  o.receipt_id,  o.orders,  o.unit,  o.counts,  o.price,  o.fees_id
      FROM  (docs_receipts d, docs_receipt_orders o) 
     $WHERE;"
    );

    return $self->{list} if ($self->{TOTAL} < 1);
    my $list = $self->{list};
    return $list;
  }

  $self->query2("SELECT d.receipt_num, 
     d.date, 
     if(d.customer='-' or d.customer='', pi.fio, d.customer) AS customer, 
     sum(o.price * o.counts) AS total_sum, 
     u.id AS login, 
     a.name AS admin_name, 
     d.created, 
     p.method AS payment_method, 
     $self->{SEARCH_FIELDS}
     p.id AS payment_id,
     d.uid, 
     d.id
    FROM (docs_receipts d, docs_receipt_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE
    GROUP BY d.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query2("SELECT count(DISTINCT d.receipt_num) AS total
    FROM (docs_receipts d, docs_receipt_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN payments p ON (d.payment_id=p.id)
    $WHERE", undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
# docs_receipt_new
#**********************************************************
sub docs_receipt_new {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'f.uid'                              ],
      ['LOGIN',          'STR', 'u.id'                               ],      
      ['BILL_ID',        'INT', 'f.bill_id'                          ],
      ['COMPANY_ID',     'INT', 'u.company_id',                      ],
      ['AID',            'INT', 'f.aid',                             ],
      ['ID',             'INT', 'f.id',                              ],
      ['A_LOGIN',        'STR', 'a.id',                              ],
      ['SUM',            'INT', 'f.sum',                             ],
      ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
      ['METHOD',         'INT', 'f.method',                          ],
      ['DESCRIBE',       'STR', 'f.dsc',                             ],
      ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                  ],
      ['DATE',           'DATE', 'date_format(f.date, \'%Y-%m-%d\')',  ],
      ['FROM_DATE|TO_DATE','DATE', 'date_format(f.date, \'%Y-%m-%d\')'   ],
      ['MONTH',          'DATE', "date_format(f.date, '%Y-%m')"   ],
    ],
    { WHERE => 1,
    }    
    );

  $self->query2("SELECT f.id, u.id, f.date, f.dsc, f.sum, io.fees_id,
f.last_deposit, 
f.method, f.bill_id, if(a.name is NULL, 'Unknown', a.name), 
INET_NTOA(f.ip), f.uid, f.inner_describe 
FROM fees f 
LEFT JOIN users u ON (u.uid=f.uid) 
LEFT JOIN admins a ON (a.aid=f.aid) 
LEFT JOIN docs_receipt_orders io ON (io.fees_id=f.id) 
$WHERE
GROUP BY f.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub docs_receipt_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query2("SELECT 
   d.receipt_num,
   d.date,
   d.customer,
   sum(o.price * o.counts) AS total_sum, 
   d.phone,
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   a.name AS admin,
   u.id AS login,
   d.created,
   d.by_proxy_seria,
   d.by_proxy_person,
   d.by_proxy_date,
   d.id AS doc_id,
   d.uid,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day AS expire_date,
   d.payment_id,
   d.deposit,
   d.delivery_status,
   d.exchange_rate,
   d.currency

    FROM (docs_receipts d)
    LEFT JOIN  docs_receipt_orders o ON (d.id=o.receipt_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id='$id' $WHERE
    GROUP BY d.id;",
    undef,
    { INFO => 1 }
  );

  $self->{AMOUNT_FOR_PAY} = ($self->{DEPOSIT} < 0) ? abs($self->{DEPOSIT}) : 0 - $self->{DEPOSIT};

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{RECEIPT_NUM};
    $self->query2("SELECT receipt_id, orders, unit, counts, price, fees_id, '$self->{LOGIN}'
      FROM docs_receipt_orders WHERE receipt_id='$id'"
    );
    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub docs_receipt_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });

  if ($attr->{ORDER}) {
    push @{ $attr->{ORDERS} }, "$attr->{ORDER}|0|1|$attr->{SUM}";
  }

  if (!$attr->{ORDERS} && !$attr->{IDS}) {
    $self->{errno}  = 1;
    $self->{errstr} = "No orders";
    return $self;
  }

  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{RECEIPT_NUM} = ($attr->{RECEIPT_NUM}) ? $attr->{RECEIPT_NUM} : $self->docs_nextid({ TYPE => 'RECEIPT' });

  $self->query2("INSERT INTO docs_receipts (receipt_num, date, created, customer, phone, aid, uid,
    by_proxy_seria,
    by_proxy_person,
    by_proxy_date,
    payment_id,
    deposit,
    delivery_status,
    exchange_rate, currency)
      values ('$DATA{RECEIPT_NUM}', $DATA{DATE}, now(), '$DATA{CUSTOMER}', '$DATA{PHONE}', 
      '$admin->{AID}', '$DATA{UID}',
      '$DATA{BY_PROXY_SERIA}',
      '$DATA{BY_PROXY_PERSON}',
      '$DATA{BY_PROXY_DATE}',
      '$DATA{PAYMENT_ID}',
      '$DATA{DEPOSIT}',
      '$DATA{DELIVERY_STATUS}',
      '$DATA{EXCHANGE_RATE}', '$DATA{DOCS_CURRENCY}'
      );", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  if ($attr->{ORDERS}) {
    foreach my $line (@{ $attr->{ORDERS} }) {
      my ($order, $unit, $count, $sum, $fees_id) = split(/\|/, $line, 4);

      $self->query2("INSERT INTO docs_receipt_orders (receipt_id, orders, counts, unit, price, fees_id)
        values ('$self->{DOC_ID}', '$order', '$count', '$unit', '$sum', '$fees_id')", 'do'
      );
    }
  }
  else {
    my @ids = split(/, /, $attr->{IDS});
    foreach my $id (@ids) {
      my $sql = "INSERT INTO docs_receipt_orders (receipt_id, orders, counts, unit, price, fees_id)
        values ($self->{DOC_ID}, '" . $DATA{ 'ORDER_' . $id } . "', '" . ((!$DATA{ 'COUNT_' . $id }) ? 1 : $DATA{ 'COUNT_' . $id }) . "', '" . $DATA{ 'UNIT_' . $id } . "', '" . $DATA{ 'SUM_' . $id } . "', '" . $DATA{ 'FEES_ID_' . $id } . "')";
      $self->query2("$sql");
    }
  }

  return $self if ($self->{errno});
  $self->docs_receipt_info($self->{DOC_ID});
  return $self;
}

#**********************************************************
# docs_receipt_del
#**********************************************************
sub docs_receipt_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
    #$self->query2("DELETE FROM docs_receipt_orders WHERE receipt_id='$id'", 'do');
    #$self->query2("DELETE FROM docs_receipts WHERE uid='$id'", 'do');
  }
  else {
    $self->query2("DELETE FROM docs_receipt_orders WHERE receipt_id='$id'", 'do');
    $self->query2("DELETE FROM docs_receipts WHERE id='$id'", 'do');
  }

  return $self;
}


#**********************************************************
# invoices2payments
#**********************************************************
sub invoices2payments {
  my $self =shift;
  my ($attr) = @_;

  $self->query2("INSERT INTO docs_invoice2payments (invoice_id, payment_id, sum)
    VALUES ('$attr->{INVOICE_ID}', '$attr->{PAYMENT_ID}', '$attr->{SUM}')", 'do');

  return $self;
}


#**********************************************************
# invoices2payments_list
#**********************************************************
sub invoices2payments_list {
  my $self =shift;
  my ($attr) = @_;

  my $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  my $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{UNINVOICED}) {
    push @WHERE_RULES, '(i2p.invoice_id IS NULL OR p.sum>(SELECT sum(sum) FROM docs_invoice2payments WHERE payment_id=p.id))';
  }

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT',  'p.uid'                              ],
      ['INVOICE_ID',     'INT',  'i2p.invoice_id'                     ],
      ['PAYMENT_ID',     'INT',  'i2p.payment_id',                    ],
      ['DATE',           'DATE', 'date_format(d.date, \'%Y-%m-%d\')'  ],
      ['FROM_DATE|TO_DATE','DATE', 'date_format(d.date, \'%Y-%m-%d\')'],
    ],
    { WHERE => 1,
    	WHERE_RULES => \@WHERE_RULES
    }
    );

  $self->query2("SELECT p.id AS payment_id, p.date, p.dsc, 
      p.sum AS payment_sum, 
      i2p.sum AS invoiced_sum, 
      i2p.invoice_id, 
      p.uid,
      p.amount,
      d.invoice_num
     
from payments p
LEFT JOIN docs_invoice2payments i2p ON (p.id=i2p.payment_id)
LEFT JOIN docs_invoices d ON (d.id=i2p.invoice_id)
$WHERE
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr);

    my $list = $self->{list};
    return $list;
}

#**********************************************************
# invoices_list
#**********************************************************
sub invoices_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  delete $self->{ORDERS};

  my @WHERE_RULES = ();

  if ($SORT == 1 && ! $attr->{DESC}) {
    $SORT = "2 DESC, 1";
    $DESC = "DESC";
  }

  if ($attr->{UNINVOICED}) {
    my $WHERE = '';
    
    if ($attr->{PAYMENT_ID}) {
      $WHERE = "AND p.id='$attr->{PAYMENT_ID}'";
    }
    
    $self->query2("SELECT p.id, p.date, p.dsc, 
      p.sum AS payment_sum, 
      sum(i2p.sum) AS invoiced_sum, 
      if (i2p.sum IS NULL, p.sum, p.sum - sum(i2p.sum)) AS remains,
      i2p.invoice_id, 
      p.uid
      
     FROM payments p
     LEFT JOIN docs_invoice2payments i2p ON (p.id=i2p.payment_id)
     WHERE p.uid='$attr->{UID}' 
       AND (i2p.invoice_id IS NULL OR p.sum>(SELECT sum(sum) FROM docs_invoice2payments WHERE payment_id=p.id))
       $WHERE
    GROUP BY p.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr);

    my $list = $self->{list};
    return $list;
  }

  if ($attr->{PAID_STATUS}) {
    $attr->{UNPAIMENT}=$attr->{PAID_STATUS};
  }

  my $HAVING = '';
  if ($attr->{UNPAIMENT}) {
    my $st = '<>';
    if ($attr->{UNPAIMENT} == 2) {
          push @WHERE_RULES, "(
       ( (SELECT sum(sum) FROM  docs_invoice2payments WHERE invoice_id=d.id)
       =
        (SELECT sum(orders.counts*orders.price) FROM docs_invoice_orders orders WHERE orders.invoice_id=d.id)))" . (( $attr->{ID} ) ? "d.id='$attr->{ID}'" : '');
    }
    else {
#      push @WHERE_RULES, "(i2p.sum IS NULL OR 
#       ( (SELECT sum(sum) FROM  docs_invoice2payments WHERE invoice_id=d.id)
#       <>
#        (SELECT sum(orders.counts*orders.price) FROM docs_invoice_orders orders WHERE orders.invoice_id=d.id)))" . (( $attr->{ID} ) ? "d.id='$attr->{ID}'" : '');
       $HAVING = "HAVING total_sum - if(payment_sum<>'', payment_sum, 0)  > 0";
    }
  }

  #if ($attr->{CONTRACT_ID}) {
  #  push @WHERE_RULES, '(' . join('', @{ $self->search_expr($attr->{CONTRACT_ID}, 'STR', 'concat(pi.contract_sufix,pi.contract_id)') }) . ' OR ' . join('', @{ $self->search_expr($attr->{CONTRACT_ID}, 'STR', 'concat(c.contract_sufix,c.contract_id)') }) . ')';
  #}

  my $WHERE = $self->search_former($attr, [
      ['LOGIN',          'STR', 'u.id AS login',                   1 ],
      ['ID',             'INT', 'd.id'                               ],
      ['CUSTOMER',       'STR', 'd.customer'                         ],
      ['DOC_ID',         'INT', 'd.invoice_num'                      ],
      ['SUM',            'INT', 'o.price * o.counts'                 ],
      ['REPRESENTATIVE', 'STR', 'company.representative',          1 ],
      ['PAYMENT_METHOD', 'INT', 'p.method AS payment_method',      1 ],
      ['PAYMENT_ID',     'INT', 'd.payment_id',                      ],
      ['EXT_ID',         'INT', 'p.ext_id',                        1 ],
      ['AID',            'INT', 'a.id',       'a.name AS admin_name' ],
      ['CREATED',        'DATE','d.created',                       1 ],
      ['ALT_SUM',        'INT', 'if (d.exchange_rate>0, sum(o.price * o.counts) * d.exchange_rate, 0.00) AS alt_sum', 1 ],
      ['EXCHANGE_RATE',  'INT', 'd.exchange_rate',                 1 ],
      ['CURRENCY',       'INT', 'd.currency',                      1 ],
      ['COMPANY_ID',     'INT', 'u.company_id',                    1 ],
      ['DOCS_DEPOSIT',   'INT', 'd.deposit',  'd.deposit AS docs_deposit' ],
      ['CONTRACT_ID',    'INT', 'if(u.company_id=0, concat(pi.contract_sufix,pi.contract_id), concat(company.contract_sufix,company.contract_id)) AS contract_id', 1], 
      ['DATE',           'DATE', "date_format(d.date, '%Y-%m-%d')"   ],
      ['FROM_DATE|TO_DATE','DATE', "date_format(d.date, '%Y-%m-%d')" ],
      ['FULL_INFO',      '',    '', "pi.address_street, pi.address_build, pi.address_flat, if (d.phone<>0, d.phone, pi.phone) AS phone,
   pi.contract_id, pi.contract_date,  if(u.company_id > 0, company.bill_id, u.bill_id) AS bill_id,  pi.email,  pi.fio" ],
      ['UID',            'INT', 'd.uid',                           1 ],
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1,
    	SKIP_USERS_FIELDS=> [ 'UID' ]
    }
    );

  my $EXT_TABLES  = $self->{EXT_TABLES};

  if ($self->{SEARCH_FIELDS} =~ /p\./) {
  	$EXT_TABLES .= " 	
  	LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)  	
  	";
  }

  $self->query2("SELECT d.invoice_num, 
     d.date, 
     if(d.customer='-' or d.customer='', pi.fio, d.customer) AS customer,
     sum(o.price * o.counts) AS total_sum, 
     (SELECT sum(i2p.sum) FROM docs_invoice2payments i2p
              WHERE d.id=i2p.invoice_id
      ) AS payment_sum,
     $self->{SEARCH_FIELDS}
     d.payment_id,
     d.uid, 
     d.id     
    FROM docs_invoices d
    INNER JOIN  docs_invoice_orders o ON (d.id=o.invoice_id)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.id
    $HAVING
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};
  
  $self->query2("SELECT count(distinct d.id) AS total_invoices,
     count(distinct d.uid) AS total_users,
     SUM((SELECT SUM(o.price * o.counts) FROM docs_invoice_orders o WHERE o.invoice_id=d.id)) AS total_sum, 
     SUM((SELECT SUM(i2p.sum)  FROM docs_invoice2payments i2p
         WHERE d.id=i2p.invoice_id
      )) AS payment_sum
    FROM docs_invoices d
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN companies company ON (u.company_id=company.id)
    $WHERE
    ",
    undef,
    { INFO => 1 }
  );

  if ($attr->{ORDERS_LIST}) {
    $self->query2("SELECT  o.invoice_id,  o.orders,  o.unit,  o.counts,  o.price,  o.fees_id
      FROM  docs_invoice_orders o
     WHERE o.invoice_id IN (SELECT d.id
    FROM docs_invoices d
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    LEFT JOIN companies company ON (u.company_id=company.id)
    $WHERE);",
     undef,
     $attr
    );
    
    foreach my $line ( @{  $self->{list} } ) {
      if (ref $line eq 'HASH') {
        push @{ $self->{ORDERS}{int($line->{invoice_id})} }, $line;  
      }
    }
  }

  $self->{TOTAL}=$self->{TOTAL_INVOICES};
  
  return $list;
}

#**********************************************************
# docs_nextid
#**********************************************************
sub docs_nextid {
  my $self = shift;
  my ($attr) = @_;

  my $sql = '';

  my $date = ($attr->{DATE} =~ /\d{4}-\d{2}-\d{2}/) ? "'$attr->{DATE}'" : 'curdate()';

  if ($attr->{TYPE} eq 'INVOICE') {
    $sql = "SELECT max(d.invoice_num), count(*) FROM docs_invoices d
     WHERE YEAR(date)=YEAR($date);";
  }
  elsif ($attr->{TYPE} eq 'RECEIPT') {
    $sql = "SELECT max(d.receipt_num), count(*) FROM docs_receipts d
     WHERE YEAR(date)=YEAR($date);";
  }
  elsif ($attr->{TYPE} eq 'TAX_INVOICE') {
    $sql = "SELECT max(d.tax_invoice_id), count(*) FROM docs_tax_invoices d
     WHERE YEAR(date)=YEAR($date);";
  }
  elsif ($attr->{TYPE} eq 'ACT') {
    $sql = "SELECT max(d.act_id), count(*) FROM docs_acts d
     WHERE YEAR(date)=YEAR($date);";
  }

  $self->query2("$sql");

  ($self->{NEXT_ID}, $self->{TOTAL}) = @{ $self->{list}->[0] };

  $self->{NEXT_ID}++;
  return $self->{NEXT_ID};
}

#**********************************************************
# invoice_new
#**********************************************************
sub invoice_new {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'f.uid'                              ],
      ['LOGIN',          'STR', 'u.id'                               ],
      ['BILL_ID',        'INT', 'f.bill_id'                          ],
      ['COMPANY_ID',     'INT', 'u.company_id',                      ],
      ['AID',            'INT', 'f.aid',                             ],
      ['ID',             'INT', 'f.id',                              ],
      ['A_LOGIN',        'STR', 'a.id',                              ],
      ['SUM',            'INT', 'f.sum',                             ],
      ['DOMAIN_ID',      'INT', 'u.domain_id',                       ],
      ['METHOD',         'INT', 'f.method',                          ],
      ['DESCRIBE',       'STR', 'f.dsc',                             ],
      ['INNER_DESCRIBE', 'STR', 'f.inner_describe',                  ],
      ['MONTH',          'DATE', "date_format(f.date, '%Y-%m')"      ],
      ['DATE',           'DATE', 'date_format(f.date, \'%Y-%m-%d\')' ],
      ['FROM_DATE|TO_DATE','DATE', 'date_format(f.date, \'%Y-%m-%d\')' ],
    ],
    { WHERE => 1,
    }
    );

  $self->query2("SELECT f.id, 
      u.id AS login, 
      f.date, 
      f.dsc, 
      f.sum, 
      ao.fees_id,
   f.last_deposit, 
   f.method, 
   f.bill_id, 
   if(a.name is NULL, 'Unknown', a.name) AS admin_name, 
   INET_NTOA(f.ip) as ip, 
f.uid, 
f.inner_describe 
FROM fees f 
LEFT JOIN users u ON (u.uid=f.uid) 
LEFT JOIN admins a ON (a.aid=f.aid) 
LEFT JOIN docs_invoice_orders ao ON (ao.fees_id=f.id) 
$WHERE
GROUP BY f.id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr    
  );

  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub invoice_add {
  my $self = shift;
  my ($attr) = @_;

  invoice_defaults();
  
  $CONF->{DOCS_INVOICE_ORDERS}=12 if (! $CONF->{DOCS_INVOICE_ORDERS});

  %DATA             = $self->get_data($attr, { default => \%DATA });
  $DATA{DATE}       = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{CUSTOMER}   = '' if (!$DATA{CUSTOMER});
  $DATA{PHONE}      = '' if (!$DATA{PHONE});
  $DATA{VAT}        = '' if (!$DATA{VAT});
  $DATA{PAYMENT_ID} = 0  if (!$DATA{PAYMENT_ID});
  
  if (! $attr->{IDS} && $DATA{SUM}) {
    $attr->{IDS}    = 1;
    $DATA{SUM_1}    = $DATA{SUM} || 0;
    $DATA{COUNTS_1} = (!$DATA{COUNTS}) ?  1 : $DATA{COUNTS};
    $DATA{UNIT_1}   = (!$DATA{UNIT}) ? 0 : $DATA{UNIT};
    $DATA{ORDER_1}  = $DATA{ORDER} || '';
  }

  my @ids_arr       = split(/, /, $attr->{IDS} || '');
  my $orders        = $#ids_arr + 1;
  my $order_number  = 0;
  my @invoice_num_arr = ();

  while( $order_number <= $orders ) {
    $DATA{INVOICE_NUM} = ($attr->{INVOICE_NUM}) ? $attr->{INVOICE_NUM} : $self->docs_nextid({ TYPE => 'INVOICE', %$attr });
    return $self if ($self->{errno});

    $self->query2("INSERT INTO docs_invoices (invoice_num, date, created, customer, phone, aid, uid, payment_id, vat, deposit, 
    delivery_status, exchange_rate, currency)
      values ('$DATA{INVOICE_NUM}', $DATA{DATE}, now(), \"$DATA{CUSTOMER}\", \"$DATA{PHONE}\", 
      '$admin->{AID}', '$DATA{UID}', '$DATA{PAYMENT_ID}', '$DATA{VAT}', '$DATA{DEPOSIT}', 
      '$DATA{DELIVERY_STATUS}', '$DATA{EXCHANGE_RATE}', '$DATA{DOCS_CURRENCY}');", 'do'
    );

    return $self if ($self->{errno});
    $self->{DOC_ID}      = $self->{INSERT_ID};
    $self->{INVOICE_NUM} = $DATA{INVOICE_NUM};
    push @invoice_num_arr, $self->{DOC_ID};
    
    if ($attr->{IDS}) {
      for( my $order_num=0; $order_num<$CONF->{DOCS_INVOICE_ORDERS}; $order_num++) {
        my $id = shift @ids_arr;
        next if (! $id);
        
        if (! $DATA{ 'ORDER_' . $id } && $DATA{ 'SUM_' . $id } == 0) {
          next;  
        }

        $DATA{ 'COUNTS_' . $id } = 1 if (!$DATA{ 'COUNTS_' . $id });
        if ($DATA{REVERSE_CURRENCY}) {
          $DATA{ 'SUM_' . $id } = $DATA{ 'SUM_' . $id }/$DATA{EXCHANGE_RATE};
        }

        $DATA{ 'SUM_' . $id } =~ s/\,/\./g;
        if ($DATA{ER} && $DATA{ER} != 1) {
          $DATA{ 'SUM_' . $id } = $DATA{ 'SUM_' . $id } / $DATA{ER};
        }

        $self->query2("INSERT INTO docs_invoice_orders (invoice_id, orders, counts, unit, price, fees_id)
            values (" . $self->{'DOC_ID'} . ", \"" . $DATA{ 'ORDER_' . $id } . "\", '" . $DATA{ 'COUNTS_' . $id } . "', '" . ($DATA{ 'UNIT_' . $id } || 0) . "',
            '" . $DATA{ 'SUM_' . $id } . "','" . ($DATA{ 'FEES_ID_' . $id } || 0) . "')", 'do');
      }
      $orders-=$CONF->{DOCS_INVOICE_ORDERS};
      delete ($attr->{INVOICE_NUM});
    }
    $order_number++; 
    return $self if ($self->{errno});
    $self->invoice_info($self->{DOC_ID});
  } ;

  $self->{DOC_IDS} = join(',', @invoice_num_arr);

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub invoice_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query2("SELECT invoice_num, uid FROM docs_invoices WHERE id='$id'", undef, { INFO => 1 });
    $self->query2("DELETE FROM docs_invoice2payments WHERE invoice_id='$id'", 'do');
    $self->query2("DELETE FROM docs_invoice_orders WHERE invoice_id='$id'", 'do');
    $self->query2("DELETE FROM docs_invoices WHERE id='$id'", 'do');
  }

  $admin->{MODULE}='Docs';
  $admin->action_add("$self->{UID}", "$id:$self->{INVOICE_NUM}", { TYPE => 18 });  

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub invoice_info {
  my $self = shift;
  my ($id, $attr) = @_;
  
  undef $self->{ORDERS};
  
  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';
  $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} = 30 if (!$CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD});
  $self->query2("SELECT d.invoice_num, 
   d.date, 
   d.customer,  
   \@TOTAL_SUM := sum(o.price * o.counts) / if(count(DISTINCT p.id)>0,count(DISTINCT p.id),1)  AS total_sum , 
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   u.id AS login, 
   a.name AS admin, 
   d.created, 
   d.uid, 
   d.id AS doc_id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   if (d.phone<>0, d.phone, pi.phone) AS phone,
   pi.contract_id,
   pi.contract_date,
   if($CONF->{DOCS_ACCOUNT_EXPIRE_DAY}>0, date_format(d.date, '%Y-%m-$CONF->{DOCS_ACCOUNT_EXPIRE_DAY}')
       ,d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day) AS expire_date,
   u.company_id,
   c.name company_name,
   d.payment_id,
   p.method as payment_method_id,
   p.ext_id,
   d.deposit,
   d.delivery_status,
   d.exchange_rate,
   d.currency,
   \@CHARGED := sum(if (o.fees_id>0, o.price * o.counts, 0)) AS charged_sum,
   \@TOTAL_SUM - \@CHARGED AS pre_payment,
   c.phone AS company_phone,
   (SELECT sum(i2p.sum) FROM docs_invoice2payments i2p
              WHERE d.id=i2p.invoice_id
      ) AS payment_sum
    FROM (docs_invoices d, docs_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN companies c ON (u.company_id=c.id)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    LEFT JOIN docs_invoice2payments i2p ON (d.id=i2p.invoice_id)
    LEFT JOIN payments p ON (i2p.payment_id=p.id)
    WHERE d.id=o.invoice_id and d.id='$id' $WHERE
    GROUP BY d.id;",
    undef,
    { INFO => 1 }
  );

  $self->{AMOUNT_FOR_PAY} = ($self->{DEPOSIT} > 0) ? $self->{TOTAL_SUM} - $self->{DEPOSIT} : $self->{TOTAL_SUM} + $self->{DEPOSIT};

  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{INVOICE_ID};

    $self->query2("SELECT invoice_id, orders, counts, unit, price, fees_id, '$self->{LOGIN}'
     FROM docs_invoice_orders WHERE invoice_id='$id'"
    );

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub invoice_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    INVOICE_NUM     => 'invoice_num',
    DATE            => 'date',
    CUSTOMER        => 'customer',
    SUM             => 'sum',
    ID              => 'id',
    UID             => 'uid',
    PAYMENT_ID      => 'payment_id',
    DELIVERY_STATUS => 'delivery_status'
  );

  my $old_info = $self->invoice_info($attr->{ID});

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'docs_invoices',
      FIELDS          => \%FIELDS,
      OLD_INFO        => $old_info,
      DATA            => $attr,
      EXT_CHANGE_INFO => 'ACCT'
    }
  );

  return $self;
}

#**********************************************************
# Del documents
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE FROM docs_invoice_orders WHERE invoice_id IN (SELECT id FROM docs_invoices WHERE uid='$attr->{UID}')", 'do');
  $self->query2("DELETE FROM docs_invoices WHERE uid='$attr->{UID}'",                                                          'do');
  $self->query2("DELETE FROM docs_receipt_orders WHERE receipt_id IN (SELECT id FROM docs_receipts WHERE uid='$attr->{UID}')", 'do');
  $self->query2("DELETE FROM docs_receipts WHERE uid='$attr->{UID}'",                                                          'do');

  return $self;
}

#**********************************************************
# tax_invoice_list
#**********************************************************
sub tax_invoice_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'd.uid'                              ],
      ['DOC_ID',         'INT', 'd.tax_invoice_id'                   ],
      ['SUM',            'INT', 'o.price * o.counts',                             ],
      ['MONTH',          'DATE', "date_format(d.date, '%Y-%m')"      ],
      ['DATE',           'DATE', 'date_format(d.date, \'%Y-%m-%d\')' ],
      ['FROM_DATE|TO_DATE','DATE', 'date_format(d.date, \'%Y-%m-%d\')' ],
    ],
    { WHERE => 1,
    }
    );

  my $EXT_TABLES = '';
  if ($attr->{FULL_INFO}) {
    $EXT_TABLES = "LEFT JOIN users u ON (d.uid=u.uid)
      LEFT JOIN users_pi pi ON (pi.uid=u.uid)";

    $self->{EXT_FIELDS} = ",
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)),
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day";
  }

  $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT d.tax_invoice_id, 
    d.date, 
    c.name AS company_name, 
    sum(o.price * o.counts) AS total_sum, 
    a.name AS admin_name, 
    d.created, 
    d.uid, 
    d.company_id, 
    d.id 
    $self->{EXT_FIELDS}
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $EXT_TABLES
    $WHERE
    GROUP BY d.tax_invoice_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query2("SELECT count(DISTINCT d.tax_invoice_id) AS total, sum(o.price*o.counts) AS sum
    FROM (docs_tax_invoices d)
    LEFT JOIN docs_tax_invoice_orders o ON (d.id=o.tax_invoice_id)
    LEFT JOIN companies c ON (d.company_id=c.id)
    $WHERE",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
# tax_invoice_reports
#**********************************************************
sub tax_invoice_reports {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ('u.uid=d.uid');

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'd.uid'                               ],
      ['LOGIN',          'STR', 'u.id'                                ],    
      ['SUM',            'INT', 'o.price * o.counts'                  ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                           ],
      ['PAYMENT_ID',     'INT', 'd.payment_id',                       ],
      ['DOC_ID',         'INT', 'd.tax_invoice_id',                   ],
      ['AID',            'INT', 'a.id',                               ],
      ['CUSTOMER',       'STR', 'd.customer',                         ],
      ['MONTH','INT',    "date_format(d.date, '%Y-%m')"               ],
      ['FROM_DATE|TO_DATE','DATE', "date_format(d.date, '%Y-%m-%d')"   ],
      ['PHONE',          'INT', 'if (d.phone<>0, d.phone, pi.phone)', 'if (d.phone<>0, d.phone, pi.phone) AS phone'   ],
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1
    }    
    );

  $self->query2("SELECT 0, DATE_FORMAT(d.date, '%d%m%Y'), d.receipt_num, pi.fio,
    pi._inn, 
    ROUND(sum(inv_orders.price*counts), 2), 
    ROUND(sum(inv_orders.price*counts) - sum(inv_orders.price*counts) /6, 2),  
    ROUND(sum(inv_orders.price*counts) / 6, 2), 
    '-',  'X', '-', 'X', '-', 'X'

FROM (users u, docs_receipts d)
LEFT JOIN users_pi pi ON (d.uid=pi.uid)
LEFT JOIN docs_receipt_orders inv_orders ON (inv_orders.receipt_id=d.id)
$WHERE
GROUP BY d.id
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;"
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });
  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID} : $self->docs_nextid({ TYPE => 'TAX_INVOICE' });

  return $self if ($self->{errno});

  $self->query2("insert into docs_tax_invoices (tax_invoice_id, date, created, aid, uid, company_id)
      values ('$DATA{DOC_ID}', $DATA{DATE}, now(), \"$admin->{AID}\", \"$DATA{UID}\", '$DATA{COMPANY_ID}');", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  if (!$attr->{IDS}) {

  }

  if ($attr->{IDS}) {
    my @ids_arr = split(/, /, $attr->{IDS});

    foreach my $id (@ids_arr) {
      if (! $DATA{ 'ORDER_' . $id } && $DATA{ 'SUM_' . $id } == 0) {
        next;  
      }

      $DATA{ 'COUNTS_' . $id } = 1 if (!$DATA{ 'COUNTS_' . $id });      
      $self->query2("INSERT INTO docs_tax_invoice_orders (tax_invoice_id, orders, counts, unit, price)
         values (" . $self->{'DOC_ID'} . ", \"" . $DATA{ 'ORDER_' . $id } . "\", '" . $DATA{ 'COUNTS_' . $id } . "', '" . $DATA{ 'UNIT_' . $id } . "',
       '" . $DATA{ 'SUM_' . $id } . "')", 'do'
      );
    }
  }

  return $self if ($self->{errno});

  $self->tax_invoice_info($self->{DOC_ID});

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query2("DELETE FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'", 'do');
    $self->query2("DELETE FROM docs_tax_invoices WHERE id='$id'", 'do');
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub tax_invoice_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query2("SELECT d.tax_invoice_id, 
   d.date, 
   sum(o.price * o.counts) AS total_sum, 
   if(d.vat>0, FORMAT(sum(o.price * o.counts) / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   u.id AS login, 
   c.name AS admin, 
   d.created, 
   d.uid, 
   d.id AS doc_id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day As expire_date
   
    FROM (docs_tax_invoices d, docs_tax_invoice_orders o)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.tax_invoice_id and d.id='$id' $WHERE
    GROUP BY d.id;",
    undef,
    { INFO => 1 }
  );


  if ($self->{TOTAL} > 0) {
    $self->{NUMBER} = $self->{INVOICE_NUM};

    $self->query2("SELECT tax_invoice_id, orders, counts, unit, price
     FROM docs_tax_invoice_orders WHERE tax_invoice_id='$id'"
    );

    $self->{ORDERS} = $self->{list};
  }

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub tax_invoice_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'docs_tax_invoices',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# acts_list
#**********************************************************
sub acts_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE =  $self->search_former($attr, [
      ['UID',            'INT', 'd.uid'                               ],
      ['SUM',            'INT', 'd.sum'                               ],
      ['PAYMENT_METHOD', 'INT', 'p.method',                           ],
      ['PAYMENT_ID',     'INT', 'd.payment_id',                       ],
      ['DOC_ID',         'INT', 'd.act_id',                           ],
      ['AID',            'INT', 'a.id',                               ],
      ['CUSTOMER',       'STR', 'd.customer',                         ],
      ['MONTH','INT',    "date_format(d.date, '%Y-%m')"               ],
      ['FROM_DATE|TO_DATE','DATE', "date_format(d.date, '%Y-%m-%d')"   ],
    ],
    { WHERE       => 1,
    	USERS_FIELDS=> 1
    }    
    );

  $self->query2("SELECT d.act_id, d.date, company.name AS company_name, 
      d.sum, 
      a.name AS admin_name, 
      d.created, d.uid, d.company_id, d.id
    FROM docs_acts d
    LEFT JOIN companies company  ON (d.company_id=company.id)
    LEFT JOIN users u ON (u.company_id=company.id)
    LEFT JOIN admins a ON (d.aid=a.aid)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    $WHERE
    GROUP BY d.act_id 
    ORDER BY $SORT $DESC
    LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  $self->{SUM} = 0.00;
  return $self->{list} if ($self->{TOTAL} < 1);
  my $list = $self->{list};

  $self->query2("SELECT count(DISTINCT d.act_id) AS total, sum(d.sum) AS sum
    FROM docs_acts d
      LEFT JOIN companies company ON (d.company_id=company.id)
      LEFT JOIN users u ON (u.company_id=company.id)
      LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN bills cb ON (company.bill_id=cb.id)
    $WHERE",
    undef, { INFO => 1 }
  );

  return $list;
}

#**********************************************************
# Bill
#**********************************************************
sub act_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr, { default => \%DATA });
  $DATA{DATE} = ($attr->{DATE}) ? "'$attr->{DATE}'" : 'now()';
  $DATA{DOC_ID} = ($attr->{DOC_ID}) ? $attr->{DOC_ID} : $self->docs_nextid({ TYPE => 'ACT' });

  $self->query2("insert into docs_acts (act_id, date, created, aid, uid, company_id, sum)
      values ('$DATA{DOC_ID}', $DATA{DATE}, now(), \"$admin->{AID}\", \"$DATA{UID}\", '$DATA{COMPANY_ID}', '$DATA{SUM}');", 'do'
  );

  return $self if ($self->{errno});
  $self->{DOC_ID} = $self->{INSERT_ID};

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub act_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($id == 0 && $attr->{UID}) {
  }
  else {
    $self->query2("DELETE FROM docs_acts WHERE id='$id'", 'do');
  }

  return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub act_info {
  my $self = shift;
  my ($id, $attr) = @_;

  $WHERE = ($attr->{UID}) ? "and d.uid='$attr->{UID}'" : '';

  $self->query2("SELECT d.act_id, 
   d.date, 
   date_format(d.date, '%Y-%m') AS month,
   d.sum AS total_sum, 
   if(d.vat>0, FORMAT(d.sum / ((100+d.vat)/ d.vat), 2), FORMAT(0, 2)) AS vat,
   u.id AS login, 
   a.name AS admin, 
   d.created, 
   d.uid, 
   d.id AS doc_id,
   pi.fio,
   pi.address_street,
   pi.address_build,
   pi.address_flat,
   pi.phone,
   c.contract_id,
   c.contract_date,
   d.company_id,
   c.name AS company_name,
   d.date + interval $CONF->{DOCS_ACCOUNT_EXPIRE_PERIOD} day AS expire_date

    FROM (docs_acts d)
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN users_pi pi ON (pi.uid=u.uid)
    LEFT JOIN companies c ON (c.id=d.company_id)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id='$id' $WHERE
    GROUP BY d.id;",
    undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub act_change {
  my $self = shift;
  my ($attr) = @_;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'docs_acts',
      DATA         => $attr
    }
  );

  return $self->{result};
}

#**********************************************************
# User information
# user_info()
#**********************************************************
sub user_info {
  my $self = shift;
  my ($uid, $attr) = @_;

  $WHERE = "WHERE service.uid='$uid'";
  
  $CONF->{DOCS_PRE_INVOICE_PERIOD}=10 if (! defined($CONF->{DOCS_PRE_INVOICE_PERIOD}));
  
  $self->query2("SELECT service.uid, 
   service.send_docs, 
   service.periodic_create_docs, 
   service.email, 
   service.comments,
   service.personal_delivery,
   service.invoicing_period,
   service.invoice_date,
   if (u.activate='0000-00-00'  or '$CONF->{FIXED_FEES_DAY}' <> '',  service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day, service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day) AS next_invoice_date
     FROM docs_main service
   INNER JOIN users u ON (u.uid=service.uid) 
   $WHERE;", undef, { INFO => 1 }
  );


  return $self;
}


#**********************************************************
# add()
#**********************************************************
sub user_add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('docs_main', $attr);

  return $self if ($self->{errno});
  $admin->action_add("$DATA{UID}", "", { TYPE => 1 });
  return $self;
}

#**********************************************************
# user_change()
#**********************************************************
sub user_change {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{CHANGE_DATE}) {
    $attr->{SEND_DOCS}            = (!defined($attr->{SEND_DOCS}))            ? 0 : 1;
    $attr->{PERIODIC_CREATE_DOCS} = (!defined($attr->{PERIODIC_CREATE_DOCS})) ? 0 : 1;
    $attr->{PERSONAL_DELIVERY}    = (!defined($attr->{PERSONAL_DELIVERY}))    ? 0 : 1;
  }

  $admin->{MODULE} = $MODULE;
  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'UID',
      TABLE        => 'docs_main',
      DATA         => $attr
    }
  );

  $self->user_info($attr->{UID});
  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# user_del(attr);
#**********************************************************
sub user_del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE from iptv_main WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub user_list {
  my $self   = shift;
  my ($attr) = @_;
  my @list   = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  $CONF->{DOCS_PRE_INVOICE_PERIOD}=10 if (! defined($CONF->{DOCS_PRE_INVOICE_PERIOD}));
  
  my @WHERE_RULES = (  );

  if ($attr->{PRE_INVOICE_DATE}) {
    if ($attr->{PRE_INVOICE_DATE} =~ /(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})/) {
      my $from_date = $1;
      my $to_date   = $2;

      push @WHERE_RULES, "( 
      (u.activate='0000-00-00'
           AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day>='$from_date'
           AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day<='$to_date'
      )
      OR ( u.activate<>'0000-00-00'
           AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day>='$from_date' 
           AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day<='$to_date' 
      ))";      
    }
    elsif($attr->{PRE_INVOICE_DATE} ne '_SHOW') {
       push @WHERE_RULES,  '('. @{ $self->search_expr("$attr->{PRE_INVOICE_DATE}", "DATE","u.activate='0000-00-00' AND service.invoice_date + INTERVAL service.invoicing_period MONTH - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day") }[0] . ' OR '. 
       @{ $self->search_expr("$attr->{PRE_INVOICE_DATE}", "DATE", "u.activate<>'0000-00-00' AND service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period DAY - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day") }[0] .')';
    }
  }

  my $EXT_TABLES  = $self->{EXT_TABLES};

  my $WHERE =  $self->search_former($attr, [
      ['COMMENTS',            'STR',  'service.comments',   'service.comments AS service_comments' ],
      ['INVOICE_DATE',        'DATE', 'service.invoice_date'              ],
      ['EMAIL',               'STR',  'service.email',                    ],
      ['PERIODIC_CREATE_DOCS','INT',  'service.periodic_create_docs',     ],
      ['SEND_DOCS',           'INT',  'service.send_docs',                ],
      ['PERSONAL_DELIVERY',   'INT',  'service.personal_delivery',        ],
      ['INVOICING_PERIOD',    'INT',  'service.invoicing_period',         ],
      ['PERIODIC_CREATE_DOCS','INT',  'service.periodic_create_docs',     ],
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1
    }    
    );

  my $list;

  $self->query2("select u.id AS login, 
     pi.fio, 
     if(company.id IS NULL, b.deposit, cb.deposit) AS deposit, 
     if(u.company_id=0, u.credit, 
          if (u.credit=0, company.credit, u.credit)) AS credit, 
     u.disable AS login_status, 
     service.invoice_date, 
     if(u.activate='0000-00-00', 
       service.invoice_date + INTERVAL service.invoicing_period MONTH,
       service.invoice_date + INTERVAL 30*service.invoicing_period+service.invoicing_period-1 DAY) - INTERVAL $CONF->{DOCS_PRE_INVOICE_PERIOD} day AS pre_invoice_date,
     service.invoicing_period,  
     (service.invoice_date + INTERVAL service.invoicing_period MONTH) AS next_invoice_date,     
     $self->{SEARCH_FIELDS}
     service.email, 
     service.send_docs,
     u.activate,
     service.uid
   FROM users u
   INNER JOIN docs_main service ON (u.uid=service.uid)
   LEFT JOIN users_pi pi ON (u.uid = pi.uid)
   LEFT JOIN bills b ON (u.bill_id = b.id)
   LEFT JOIN companies company ON  (u.company_id=company.id) 
   LEFT JOIN bills cb ON  (company.bill_id=cb.id)
   $WHERE 
   ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr
  );

  return $self if ($self->{errno});

  $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(u.id) AS total  FROM users u, docs_main service
      $WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}

1
