package Docs;
# Users manage functions
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');

@EXPORT = qw();

@EXPORT_OK = ();
%EXPORT_TAGS = ();

use main;
@ISA  = ("main");


#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  my $self = { };
  bless($self, $class);
  #$self->{debug}=1;
  return $self;
}



#**********************************************************
# Default values
#**********************************************************
sub account_defaults {
  my $self = shift;

  %DATA = ( SUM    => '0.00',
            COUNTS => 1,
            UNIT   => 1
          );   
 
  $self = \%DATA;
  return $self;
}




#**********************************************************
# accounts_list
#**********************************************************
sub accounts_list {
  my $self = shift;
  my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';


 @WHERE_RULES = ("d.id=o.acct_id");
 
 if($attr->{LOGIN_EXPR}) {
 	 require Users;
	 push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
  }
 
 if ($attr->{FROM_DATE}) {
    push @WHERE_RULES, "(date_format(d.date, '%Y-%m-%d')>='$attr->{FROM_DATE}' and date_format(d.date, '%Y-%m-%d')<='$attr->{TO_DATE}')";
  }

 if ($attr->{ACCT_ID}) {
 	  my $value = $self->search_expr($attr->{ACCT_ID}, 'INT');
    push @WHERE_RULES, "d.acct_id$value";
  }

 if ($attr->{SUM}) {
 	  my $value = $self->search_expr($attr->{SUM}, 'INT');
    push @WHERE_RULES, "o.price * o.counts$value";
  }

 
 #DIsable
 if ($attr->{UID}) {
   push @WHERE_RULES, "d.uid='$attr->{UID}'"; 
 }
 

 $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES)  : '';


  $self->query($db,   "SELECT d.acct_id, d.date, d.customer,  sum(o.price * o.counts), u.id, a.name, d.created, d.uid, d.id
    FROM docs_acct d, docs_acct_orders o
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    $WHERE
    GROUP BY d.acct_id 
    ORDER BY $SORT $DESC;");


 return $self->{list}  if ($self->{TOTAL} < 1);
 my $list = $self->{list};


 $self->query($db, "SELECT count(*)
    FROM docs_acct d, docs_acct_orders o    
    LEFT JOIN users u ON (d.uid=u.uid)
    $WHERE");

 my $a_ref = $self->{list}->[0];

 ($self->{TOTAL}) = @$a_ref;

	return $list;
}

#**********************************************************
# accounts_list
#**********************************************************
sub account_nextid {
  my $self = shift;
  my ($attr) = @_;

  $self->query($db,   "SELECT max(d.acct_id), count(*) FROM docs_acct d
    WHERE YEAR(date)=YEAR(curdate());");

  my $a_ref = $self->{list}->[0];
  ($self->{NEXT_ID},
   $self->{TOTAL}) = @$a_ref;
 
  $self->{NEXT_ID}++;
	return $self->{NEXT_ID};
}


#**********************************************************
# Bill
#**********************************************************
sub account_add {
	my $self = shift;
	my ($attr) = @_;
  
 
  %DATA = $self->get_data($attr, { default => \%DATA }); 
  $DATA{DATE}    = ($attr->{DATE})    ? "'$attr->{DATE}'" : 'now()';
  $DATA{ACCT_ID} = ($attr->{ACCT_ID}) ? $attr->{ACCT_ID}  : $self->account_nextid();

  

  $self->query($db, "insert into docs_acct (acct_id, date, created, customer, phone, aid, uid)
      values ('$DATA{ACCT_ID}', $DATA{DATE}, now(), \"$DATA{CUSTOMER}\", \"$DATA{PHONE}\", 
      \"$admin->{AID}\", \"$DATA{UID}\");", 'do');
 
  return $self if($self->{errno});
  $self->{DOC_ID}=$self->{INSERT_ID};

  $self->query($db, "INSERT INTO docs_acct_orders (acct_id, orders, counts, unit, price)
      values ($self->{DOC_ID}, \"$DATA{ORDERS}\", '$DATA{COUNTS}', '$DATA{UNIT}',
 '$DATA{SUM}')", 'do');

  return $self if($self->{errno});
  
  $self->{ACCT_ID}=$DATA{ACCT_ID};
  $self->account_info($self->{DOC_ID});

  #push @{$self->{ORDERS}}, "$DATA{ACCT_ID}|$DATA{COUNTS}|$DATA{UNIT}|$DATA{SUM}";
  

	return $self;
}


#**********************************************************
# Bill
#**********************************************************
sub account_del {
	my $self = shift;
	my ($id, $attr) = @_;

   $self->query($db, "DELETE FROM docs_acct_orders WHERE acct_id='$id'", 'do');
   $self->query($db, "DELETE FROM docs_acct WHERE id='$id'", 'do');

	return $self;
}

#**********************************************************
# Bill
#**********************************************************
sub account_info {
	my $self = shift;
	my ($id, $attr) = @_;


  $self->query($db, "SELECT d.acct_id, 
   d.date, 
   d.customer,  
   sum(o.price * o.counts), 
   u.id, 
   a.name, 
   d.created, 
   d.uid, 
   d.id
    FROM docs_acct d, docs_acct_orders o
    LEFT JOIN users u ON (d.uid=u.uid)
    LEFT JOIN admins a ON (d.aid=a.aid)
    WHERE d.id=o.acct_id and d.id='$id'
    GROUP BY d.id;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];
  ($self->{ACCT_ID}, 
   $self->{DATE}, 
   $self->{CUSTOMER}, 
   $self->{SUM}
  )= @$ar;
	
 
  $self->{NUMBER}=$self->{ACCT_ID};
 
  $self->query($db, "SELECT acct_id, orders, counts, unit, price
   FROM docs_acct_orders WHERE acct_id='$id'");
  
  $self->{ORDERS}=$self->{list};

	return $self;
}


#**********************************************************
# change()
#**********************************************************
sub account_change {
  my $self = shift;
  my ($attr) = @_;
  
  my %FIELDS = (ACCT_ID     => 'acct_id',
                DATE        => 'date',
                CUSTOMER    => 'customer',
                SUM         => 'sum',
                ID          => 'id',
                UID         => 'uid'
             );


  $self->changes($admin,  { CHANGE_PARAM => 'ID',
                   TABLE        => 'docs_acct',
                   FIELDS       => \%FIELDS,
                   OLD_INFO     => $self->account_info($attr->{DOC_ID}),
                   DATA         => $attr
                  } );

  return $self->{result};
}









1
