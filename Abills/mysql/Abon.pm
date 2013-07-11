package Abon;

# Periodic payments  managment functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw();

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

use main;
@ISA = ("main");

my $MODULE = 'Abon';


#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $admin->{MODULE} = $MODULE;

  if ($CONF->{DELETE_USER}) {
    $self->{UID} = $CONF->{DELETE_USER};
    $self->del({ UID => $CONF->{DELETE_USER} });
  }

  $self->{db}=$db;

  return $self;
}

#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("DELETE from abon_user_list WHERE uid='$self->{UID}';", 'do');

  $admin->action_add($self->{UID}, "$self->{UID}", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# User information
# info()
#**********************************************************
sub tariff_info {
  my $self = shift;
  my ($id) = @_;

  my @WHERE_RULES = ("id='$id'");
  my $WHERE       = '';

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT 
   name,
   period,
   price,
   payment_type,
   period_alignment,
   nonfix_period, 
   ext_bill_account,
   id,
   priority,
   create_account,
   fees_type,
   notification1,
   notification2,
   notification_account,
   alert,
   alert_account,
   ext_cmd,
   activate_notification,
   vat,
   discount,
   manual_activate,
   user_portal
     FROM abon_tariffs
   $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = (
    ID       => 0,
    PERIOD   => 0,
    SUM      => '0.00',
    DISCOUNT => 1
  );

  $self = \%DATA;
  return $self;
}

#**********************************************************
# add()
#**********************************************************
sub tariff_add {
  my $self = shift;
  my ($attr) = @_;

  %DATA = $self->get_data($attr);
   
  $self->query_add('abon_tariffs', \%DATA);

  return $self if ($self->{errno});
  $admin->system_action_add("ABON_ID:$DATA{ID}", { TYPE => 1 });
  return $self;
}

#**********************************************************
# change()
#**********************************************************
sub tariff_change {
  my $self = shift;
  my ($attr) = @_;

  $attr->{CREATE_ACCOUNT}        = 0 if (!$attr->{CREATE_ACCOUNT});
  $attr->{FEES_TYPE}             = 0 if (!$attr->{FEES_TYPE});
  $attr->{NOTIFICATION_ACCOUNT}  = 0 if (!$attr->{NOTIFICATION_ACCOUNT});
  $attr->{ALERT}                 = 0 if (!$attr->{ALERT});
  $attr->{ALERT_ACCOUNT}         = 0 if (!$attr->{ALERT_ACCOUNT});
  $attr->{PERIOD_ALIGNMENT}      = 0 if (!$attr->{PERIOD_ALIGNMENT});
  $attr->{ACTIVATE_NOTIFICATION} = 0 if (!$attr->{ACTIVATE_NOTIFICATION});
  $attr->{VAT}                   = 0 if (!$attr->{VAT});
  $attr->{NONFIX_PERIOD}         = 0 if (!$attr->{NONFIX_PERIOD});
  $attr->{DISCOUNT}              = 0 if (!$attr->{DISCOUNT});
  $attr->{EXT_BILL_ACCOUNT}      = 0 if (!$attr->{EXT_BILL_ACCOUNT});
  $attr->{USER_PORTAL}           = 0 if (!$attr->{USER_PORTAL});
  $attr->{MANUAL_ACTIVATE}       = 0 if (!$attr->{MANUAL_ACTIVATE});

  $attr->{ID}=$attr->{ABON_ID};

  $self->changes(
    $admin,
    {
      CHANGE_PARAM    => 'ID',
      TABLE           => 'abon_tariffs',
      DATA            => $attr,
      EXT_CHANGE_INFO => "ABON_ID:$attr->{ABON_ID}"
    }
  );

  $self->tariff_info($attr->{ABON_ID});
  return $self->{result};
}

#**********************************************************
# Delete user info from all tables
# del(attr);
#**********************************************************
sub tariff_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE from abon_tariffs WHERE id='$id';", 'do');
  $admin->system_action_add("ABON_ID:$id", { TYPE => 10 });
  return $self->{result};
}

#**********************************************************
# list()
#**********************************************************
sub tariff_list {
  my $self = shift;
  my ($attr) = @_;
  @WHERE_RULES = ();

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}           : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}           : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}             : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? int($attr->{PAGE_ROWS}) : 25;

  if ($attr->{IDS}) {
    push @WHERE_RULES, "abon_tariffs.id IN ($attr->{IDS})";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT name, price, period, payment_type, 
     priority,
     period_alignment,
     count(ul.uid) AS user_count,
     abon_tariffs.id AS tp_id,
     fees_type,
     create_account,
     ext_cmd,
     activate_notification,
     vat,
     abon_tariffs.discount,
     manual_activate,
     user_portal,
     \@nextfees_date := if (nonfix_period = 1, 
      if (period = 0, curdate() + INTERVAL 2 DAY, 
       if (period = 1, curdate() + INTERVAL 2 MONTH, 
         if (period = 2, curdate() + INTERVAL 6 MONTH, 
           if (period = 3, curdate() + INTERVAL 12 MONTH, 
             if (period = 4, curdate() + INTERVAL 2 YEAR, 
               '-'
              )
            )
          )
        )
       ),
      if (period = 0, curdate()+ INTERVAL 1 DAY, 
       if (period = 1, DATE_FORMAT(curdate() + INTERVAL 2 MONTH, '%Y-%m-01'), 
         if (period = 2, CONCAT(YEAR(curdate() + INTERVAL 6 MONTH), '-' ,(QUARTER((curdate() + INTERVAL 6 MONTH))*6-2), '-01'), 
           if (period = 3, CONCAT(YEAR(curdate() + INTERVAL 12 MONTH), '-', if(MONTH(curdate() + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'), 
             if (period = 4, DATE_FORMAT(curdate() + INTERVAL 2 YEAR, '%Y-01-01'), 
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon_date
     FROM abon_tariffs
     LEFT JOIN abon_user_list ul ON (abon_tariffs.id=ul.tp_id)
     $WHERE
     GROUP BY abon_tariffs.id
     ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
# user_list()
#**********************************************************
sub user_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ("u.uid=ul.uid", "at.id=ul.tp_id");

  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'STR', 'u.id') };
  }

  if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

  if ($attr->{GIDS}) {
    push @WHERE_RULES, "u.gid IN ($attr->{GIDS})";
  }
  elsif ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

  if ( !$admin->{permissions}->{0}
    || !$admin->{permissions}->{0}->{8}
    || ($attr->{USER_STATUS} && !$attr->{DELETED}))
  {
    push @WHERE_RULES, @{ $self->search_expr(0, 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }
  elsif ($attr->{DELETED}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }

  if ($attr->{ABON_ID}) {
    push @WHERE_RULES, "at.id='$attr->{ABON_ID}'";
  }

  if (defined($attr->{MANUAL_FEE})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{MANUAL_FEE}", 'INT', 'ul.manual_fee') };
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT u.id AS login, pi.fio, at.name AS tp_name, ul.comments, at.price, at.period,
     ul.date, 
     if (at.nonfix_period = 1, 
      if (at.period = 0, ul.date+ INTERVAL 1 DAY, 
       if (at.period = 1, ul.date + INTERVAL 1 MONTH, 
         if (at.period = 2, ul.date + INTERVAL 3 MONTH, 
           if (at.period = 3, ul.date + INTERVAL 6 MONTH, 
             if (at.period = 4, ul.date + INTERVAL 1 YEAR, 
               '-'
              )
            )
          )
        )
       )
      ,
      
      if (at.period = 0, ul.date+ INTERVAL 1 DAY, 
       if (at.period = 1, DATE_FORMAT(ul.date + INTERVAL 1 MONTH, '%Y-%m-01'), 
         if (at.period = 2, CONCAT(YEAR(ul.date + INTERVAL 3 MONTH), '-' ,(QUARTER((ul.date + INTERVAL 3 MONTH))*3-2), '-01'), 
           if (at.period = 3, CONCAT(YEAR(ul.date + INTERVAL 6 MONTH), '-', if(MONTH(ul.date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'), 
             if (at.period = 4, DATE_FORMAT(ul.date + INTERVAL 1 YEAR, '%Y-01-01'), 
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon,
     ul.manual_fee,
     u.uid, 
     at.id AS tp_id
     FROM (users u, abon_user_list ul, abon_tariffs at)
     LEFT JOIN users_pi pi ON u.uid = pi.uid
     $WHERE
     GROUP BY ul.uid, ul.tp_id
     ORDER BY $SORT $DESC
     LIMIT $PG, $PAGE_ROWS;",
  undef,
  $attr
  );
  my $list = $self->{list};

  if ($self->{TOTAL} > 0) {
    $self->query2("SELECT count(u.uid) AS total
     FROM (users u, abon_user_list ul, abon_tariffs at)
     $WHERE", undef, { INFO => 1 }
    );
  }

  return $list;
}

#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_list {
  my $self = shift;
  my ($uid, $attr) = @_;

  # @WHERE_RULES = ("ul.uid='$uid'");
  # $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES)  : '';
  $self->query2("SELECT at.id, 
      at.name, 
      if(ul.comments <> '', ul.comments, '') AS comments, 
      at.price, 
      at.period, 
      sum(ul.service_count) AS service_count,
      max(ul.date) AS date, 
      if (at.nonfix_period = 1, 
      if (at.period = 0, ul.date+ INTERVAL 1 DAY, 
       if (at.period = 1, ul.date + INTERVAL 1 MONTH, 
         if (at.period = 2, ul.date + INTERVAL 3 MONTH, 
           if (at.period = 3, ul.date + INTERVAL 6 MONTH, 
             if (at.period = 4, ul.date + INTERVAL 1 YEAR, 
               '-'
              )
            )
          )
        )
       ),      
      \@next_abon := if (at.period = 0, ul.date+ INTERVAL 1 DAY, 
       if (at.period = 1, DATE_FORMAT(ul.date + INTERVAL 1 MONTH, '%Y-%m-01'), 
         if (at.period = 2, CONCAT(YEAR(ul.date + INTERVAL 3 MONTH), '-' ,(QUARTER((ul.date + INTERVAL 3 MONTH))*3-2), '-01'), 
           if (at.period = 3, CONCAT(YEAR(ul.date + INTERVAL 6 MONTH), '-', if(MONTH(ul.date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'), 
             if (at.period = 4, DATE_FORMAT(ul.date + INTERVAL 1 YEAR, '%Y-01-01'), 
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon,
   ul.manual_fee,   
   max(ul.discount) AS discount,
   count(ul.uid) AS active_service,
   ul.notification1,
   ul.notification1_account_id,
   ul.notification2,
   ul.create_docs,
   ul.send_docs,
   at.manual_activate,
   if (\@next_abon < curdate(), 1, 0) AS missing
     FROM abon_tariffs at
     LEFT JOIN abon_user_list ul ON (at.id=ul.tp_id and ul.uid='$uid')
     GROUP BY at.id
     ORDER BY $SORT $DESC;",
   undef,
   $attr
  );

  my $list = $self->{list};

  return $list;
}

#**********************************************************
# user_tariff_change()
#**********************************************************
sub user_tariff_change {
  my $self = shift;
  my ($attr) = @_;

  my $abon_add = '';
  my $abon_del = '';
 
  $admin->{MODULE} = $MODULE;
 
  if ($attr->{CHANGE_INFO}) {
    $self->query2("UPDATE abon_user_list SET 
      comments='$attr->{COMMENTS}', 
      discount='$attr->{DISCOUNT}', 
      create_docs='$attr->{CREATE_DOCS}', 
      send_docs='$attr->{SEND_DOCS}', 
      service_count='$attr->{SERVICE_COUNT}',
      manual_fee='$attr->{MANUAL_FEE}'
      WHERE uid='$attr->{UID}' AND tp_id='$attr->{TP_ID}';
      ", 'do');

    $admin->action_add($attr->{UID}, "ADD: $abon_add DEL: $abon_del", { TYPE => 3 });
    return $self;
  }
  elsif($attr->{ACTIVATE}) {
    $self->query2("UPDATE abon_user_list SET 
      date='$attr->{ABON_DATE}'
      WHERE uid='$attr->{UID}' AND tp_id='$attr->{ACTIVATE}';
      ", 'do');    
    return 0;
  }
  elsif ($attr->{DEL}) {
    $self->query2("DELETE from abon_user_list WHERE uid='$attr->{UID}' AND tp_id IN ($attr->{DEL});", 'do');
    $abon_del = "$attr->{DEL}";
  }

  my @tp_array = split(/, /, $attr->{IDS});

  foreach my $tp_id (@tp_array) {
    my $date = '';

    if ($attr->{ 'DATE_' . $tp_id } && $attr->{ 'DATE_' . $tp_id } ne '0000-00-00' && $attr->{ 'PERIOD_' . $tp_id }) {
      $date = "
      if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 0, '" . $attr->{ 'DATE_' . $tp_id } . "' -  INTERVAL 1 DAY, 
       if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 1, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 1 MONTH, 
         if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 2, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 3 MONTH, 
           if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 3, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 6 MONTH, 
             if (" . $attr->{ 'PERIOD_' . $tp_id } . " = 4, '" . $attr->{ 'DATE_' . $tp_id } . "' - INTERVAL 1 YEAR, 
               curdate()
              )
            )
          )
        )
       )";
    }
    elsif ($attr->{ 'DATE_' . $tp_id } && $attr->{ 'DATE_' . $tp_id } ne '0000-00-00') {
      $date = $attr->{ 'DATE_' . $tp_id };
    }
    else {
      $date = 'curdate()';
    }

    $self->query2("INSERT INTO abon_user_list (uid, tp_id, comments, date, discount, create_docs, send_docs, service_count, manual_fee) 
     VALUES ('$attr->{UID}', '$tp_id', '" . $attr->{ 'COMMENTS_' . $tp_id } . "', $date, '" . $attr->{ 'DISCOUNT_' . $tp_id } . "',
     '" . $attr->{ 'CREATE_DOCS_' . $tp_id } . "', '" . $attr->{ 'SEND_DOCS_' . $tp_id } . "', '". $attr->{'SERVICE_COUNT_'. $tp_id} ."', '" . $attr->{ 'MANUAL_FEE_' . $tp_id } . "');", 'do'
    );
    $abon_add .= "$tp_id, ";
  }

  $admin->{MODULE} = $MODULE;
  $admin->action_add($attr->{UID}, "ADD: $abon_add DEL: $abon_del", { TYPE => 3 });
  return $self;
}

#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_del {
  my $self = shift;
  my ($attr) = @_;

  my $WHERE = '';
  if ($attr->{TP_IDS}) {
    $WHERE = "tp_id IN ($attr->{TP_IDS})";
  }
  else {
    $WHERE = "tp_id='$attr->{TP_ID}'";
  }

  $self->query2("DELETE from abon_user_list WHERE uid='$attr->{UID}' AND $WHERE;", 'do');

  $admin->action_add($attr->{UID}, "$attr->{TP_IDS}");
  return $self;
}

#**********************************************************
# user_tariffs()
#**********************************************************
sub user_tariff_update {
  my $self = shift;
  my ($attr) = @_;

  my $DATE = ($attr->{DATE}) ? "'$attr->{DATE}'" : "now()";

  #
  if ($attr->{NOTIFICATION}) {
    my $set = '';
    if ($attr->{NOTIFICATION} == 1) {
      $set = "notification1=$DATE";
      if ($attr->{NOTIFICATION_ACCOUNT_ID}) {
        $set .= ", notification1_account_id='$attr->{NOTIFICATION_ACCOUNT_ID}'";
      }
    }
    elsif ($attr->{NOTIFICATION} == 2) {
      $set = "notification2=$DATE";
    }

    $self->query2("UPDATE abon_user_list SET $set
     WHERE uid='$attr->{UID}' and tp_id='$attr->{TP_ID}';", 'do'
    );
  }
  else {
    $self->query2("UPDATE abon_user_list SET date=$DATE, 
     notification1='0000-00-00',
     notification1_account_id='0',
     notification2='0000-00-00'
     WHERE uid='$attr->{UID}' and tp_id='$attr->{TP_ID}';", 'do'
    );
  }

  return $self;
}

#**********************************************************
# Periodic
#**********************************************************
sub periodic_list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();
  if ($attr->{LOGIN}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{LOGIN}, 'INT', 'u.id') };
  }

  if ($attr->{TP_ID}) {
    push @WHERE_RULES, @{ $self->search_expr($attr->{TP_ID}, 'INT', 'ul.tp_id') };
  }

  if (defined($attr->{DELETED})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }

  if (defined($attr->{LOGIN_STATUS})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{LOGIN_STATUS}", 'INT', 'u.disable', { EXT_FIELD => 1 }) };
  }

  if (defined($attr->{MANUAL_FEE})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{MANUAL_FEE}", 'INT', 'ul.manual_fee') };
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{UID}", 'INT', 'u.uid') };
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "AND " . join(' and ', @WHERE_RULES) : '';

  my $EXT_TABLE = '';

  $self->query2("SELECT at.period, at.price, u.uid, 
  if(u.company_id > 0, c.bill_id, u.bill_id) AS bill_id,
  u.id AS login, 
  at.id AS tp_id, 
  at.name AS tp_name,
  if(c.name IS NULL, b.deposit, cb.deposit) AS deposit,
  if(u.credit, u.credit,
    if (c.credit <> 0, c.credit, 0) ) AS credit,
  u.disable,
  at.payment_type,
  ul.comments,
  \@last_fees_date := if(ul.date='0000-00-00', curdate(), ul.date),
  \@fees_date := if (at.nonfix_period = 1, 
      if (at.period = 0, \@last_fees_date+ INTERVAL 1 DAY, 
       if (at.period = 1, \@last_fees_date + INTERVAL 1 MONTH, 
         if (at.period = 2, \@last_fees_date + INTERVAL 3 MONTH, 
           if (at.period = 3, \@last_fees_date + INTERVAL 6 MONTH, 
             if (at.period = 4, \@last_fees_date + INTERVAL 1 YEAR, 
               '-'
              )
            )
          )
        )
       ),
      if (at.period = 0, \@last_fees_date + INTERVAL 1 DAY, 
       if (at.period = 1, DATE_FORMAT(\@last_fees_date + INTERVAL 1 MONTH, '%Y-%m-01'), 
         if (at.period = 2, CONCAT(YEAR(\@last_fees_date + INTERVAL 3 MONTH), '-' ,(QUARTER((\@last_fees_date + INTERVAL 3 MONTH))*3-2), '-01'), 
           if (at.period = 3, CONCAT(YEAR(\@last_fees_date + INTERVAL 6 MONTH), '-', if(MONTH(\@last_fees_date + INTERVAL 6 MONTH) > 6, '06', '01'), '-01'), 
             if (at.period = 4, DATE_FORMAT(\@last_fees_date + INTERVAL 1 YEAR, '%Y-01-01'), 
               '-'
              )
            )
          )
        )
       )
      ) AS abon_date,
   at.ext_bill_account,
   if(u.company_id > 0, c.ext_bill_id, u.ext_bill_id) AS ext_bill_id,
   at.priority,
   
   fees_type,
   create_account,
   if (at.notification1>0, \@fees_date - interval at.notification1 day, '0000-00-00') AS notification1,
   if (at.notification2>0, \@fees_date - interval at.notification2 day, '0000-00-00') AS notification2,
   at.notification_account,
   if (at.alert > 0, \@fees_date, '0000-00-00'),
   at.alert_account,
   pi.email,
   ul.notification1_account_id,
   at.ext_cmd,
   at.activate_notification,
   at.vat,
   \@nextfees_date := if (at.nonfix_period = 1, 
      if (at.period = 0, \@last_fees_date+ INTERVAL 2 DAY, 
       if (at.period = 1, \@last_fees_date + INTERVAL 2 MONTH, 
         if (at.period = 2, \@last_fees_date + INTERVAL 6 MONTH, 
           if (at.period = 3, \@last_fees_date + INTERVAL 12 MONTH, 
             if (at.period = 4, \@last_fees_date + INTERVAL 2 YEAR, 
               '-'
              )
            )
          )
        )
       ),
      if (at.period = 0, \@last_fees_date+ INTERVAL 1 DAY, 
       if (at.period = 1, DATE_FORMAT(\@last_fees_date + INTERVAL 2 MONTH, '%Y-%m-01'), 
         if (at.period = 2, CONCAT(YEAR(\@last_fees_date + INTERVAL 6 MONTH), '-' ,(QUARTER((\@last_fees_date + INTERVAL 6 MONTH))*6-2), '-01'), 
           if (at.period = 3, CONCAT(YEAR(\@last_fees_date + INTERVAL 12 MONTH), '-', if(MONTH(\@last_fees_date + INTERVAL 12 MONTH) > 12, '06', '01'), '-01'), 
             if (at.period = 4, DATE_FORMAT(\@last_fees_date + INTERVAL 2 YEAR, '%Y-01-01'), 
               '-'
              )
            )
          )
        )
       )
      ) AS next_abon_date,
    if(ul.discount>0, ul.discount,
     if(at.discount=1, u.reduction, 0)) AS discount,
     ul.create_docs,
     ul.send_docs,
     ul.service_count,
     ul.manual_fee
  FROM (abon_tariffs at, abon_user_list ul, users u)
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     LEFT JOIN users_pi pi ON (pi.uid=u.uid)
WHERE
at.id=ul.tp_id and
ul.uid=u.uid
$WHERE
AND u.deleted='0'
ORDER BY at.priority;",
undef,
$attr
  );

  my $list = $self->{list};

  return $list;
}

1
