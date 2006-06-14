package Users;
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

# User name expration
my $usernameregexp = "^[a-z0-9_][a-z0-9_-]*\$"; # configurable;

use main;
@ISA  = ("main");


my $uid;
#**********************************************************
# Init 
#**********************************************************
sub new {
  my $class = shift;
  ($db, $admin, $CONF) = @_;
  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if($#WHERE_RULES > -1);
  
  $CONF->{MAX_USERNAME_LENGTH} = 10 if (! defined($CONF->{MAX_USERNAME_LENGTH}));
  
  if (defined($CONF->{USERNAMEREGEXP})) {
  	$usernameregexp=$CONF->{USERNAMEREGEXP};
   }

  my $self = { };

  bless($self, $class);
  
  return $self;
}





#**********************************************************
# User information
# info()
#**********************************************************
sub info {
  my $self = shift;
  my ($uid, $attr) = @_;

  my $WHERE;
    
  if (defined($attr->{LOGIN}) && defined($attr->{PASSWORD})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}' and DECODE(u.password, '$CONF->{secretkey}')='$attr->{PASSWORD}'";
    #$PASSWORD = "if(DECODE(password, '$SECRETKEY')='$attr->{PASSWORD}', 0, 1)";
   }
  elsif(defined($attr->{LOGIN})) {
    $WHERE = "WHERE u.id='$attr->{LOGIN}'";
   }
  else {
    $WHERE = "WHERE u.uid='$uid'";
   }


  $self->query($db, "SELECT u.uid,
   u.gid, 
   g.name,
   u.id, u.activate, u.expire, u.credit, u.reduction, 
   u.registration, 
   u.disable,
   if(u.company_id > 0, cb.id, b.id),
   if(c.name IS NULL, b.deposit, cb.deposit),
   u.company_id,
   if(c.name IS NULL, 'N/A', c.name), 
   if(c.name IS NULL, u.bill_id, c.bill_id)

     FROM users u
     LEFT JOIN bills b ON (u.bill_id=b.id)
     LEFT JOIN groups g ON (u.gid=g.gid)
     LEFT JOIN companies c ON (u.company_id=c.id)
     LEFT JOIN bills cb ON (c.bill_id=cb.id)
     $WHERE;");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{UID},
   $self->{GID},
   $self->{G_NAME},
   $self->{LOGIN}, 
   $self->{ACTIVATE}, 
   $self->{EXPIRE}, 
   $self->{CREDIT}, 
   $self->{REDUCTION}, 
   $self->{REGISTRATION}, 
   $self->{DISABLE}, 
   $self->{BILL_ID}, 
   $self->{DEPOSIT}, 
   $self->{COMPANY_ID},
   $self->{COMPANY_NAME},
 )= @$ar;
  
  
  return $self;
}


#**********************************************************
# pi_add()
#**********************************************************
sub pi_add {
  my $self = shift;
  my ($attr) = @_;
  
  defaults();  
  %DATA = $self->get_data($attr, { default => $self }); 
  
  if($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
    
  $self->query($db,  "INSERT INTO users_pi (uid, fio, phone, address_street, address_build, address_flat, 
          email, contract_id, comments)
           VALUES ('$DATA{UID}', '$DATA{FIO}', '$DATA{PHONE}', \"$DATA{ADDRESS_STREET}\", 
            \"$DATA{ADDRESS_BUILD}\", \"$DATA{ADDRESS_FLAT}\",
            '$DATA{EMAIL}', '$DATA{CONTRACT_ID}',
            '$DATA{COMMENTS}' );", 'do');
  
  return $self if ($self->{errno});
  
  $admin->action_add("$DATA{UID}", "ADD PIf");
  return $self;
}



#**********************************************************
# Personal inforamtion
# personal_info()
#**********************************************************
sub pi {
	my $self = shift;
  my ($attr) = @_;
  
  my $UID = ($attr->{UID}) ? $attr->{UID} : $self->{UID};
  
  
  $self->query($db, "SELECT pi.fio, 
  pi.phone, 
  pi.address_street, 
  pi.address_build,
  pi.address_flat,
  pi.email,  
  pi.contract_id,
  pi.comments
    FROM users_pi pi
    WHERE pi.uid='$UID';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{FIO}, 
   $self->{PHONE}, 
   $self->{ADDRESS_STREET}, 
   $self->{ADDRESS_BUILD}, 
   $self->{ADDRESS_FLAT}, 
   $self->{EMAIL}, 
   $self->{CONTRACT_ID},
   $self->{COMMENTS}
  )= @$ar;
	
	
	return $self;
}

#**********************************************************
# Personal Info change
#
#**********************************************************
sub pi_change {
	my $self   = shift;
  my ($attr) = @_;


my %FIELDS = (EMAIL          => 'email',
              FIO            => 'fio',
              PHONE          => 'phone',
              ADDRESS_BUILD  => 'address_build',
              ADDRESS_STREET => 'address_street',
              ADDRESS_FLAT   => 'address_flat',
              COMMENTS       => 'comments',
              UID            => 'uid',
              CONTRACT_ID    => 'contract_id'
             );

	$self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users_pi',
		                FIELDS       => \%FIELDS,
		              OLD_INFO     => $self->pi({ UID => $attr->{UID} }),
		                DATA         => $attr
		              } );

	
	return $self;
}


#**********************************************************
# defauls user settings
#**********************************************************
sub defaults {
  my $self = shift;

  %DATA = ( LOGIN => '', 
   ACTIVATE       => '0000-00-00', 
   EXPIRE         => '0000-00-00', 
   CREDIT         => 0, 
   REDUCTION      => '0.00', 
   SIMULTANEONSLY => 0, 
   DISABLE        => 0, 
   COMPANY_ID     => 0,
   GID            => 0,
   DISABLE        => 0,
   PASSWORD       => '');
 
  $self = \%DATA;
  return $self;
}


#**********************************************************
# groups_list()
#**********************************************************
sub groups_list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 
 $self->query($db, "select g.gid, g.name, g.descr, count(u.uid) FROM groups g
        LEFT JOIN users u ON  (u.gid=g.gid) 
        GROUP BY g.gid
        ORDER BY $SORT $DESC");

 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(*) FROM groups");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

 return $list;
}


#**********************************************************
# group_info()
#**********************************************************
sub group_info {
 my $self = shift;
 my ($gid) = @_;
 
 $self->query($db, "select g.name, g.descr FROM groups g WHERE g.gid='$gid';");

 return $self if ($self->{errno});

 my $a_ref = $self->{list}->[0];

 ($self->{G_NAME},
 	$self->{G_DESCRIBE}) = @$a_ref;
 
 $self->{GID}=$gid;

 return $self;
}

#**********************************************************
# group_info()
#**********************************************************
sub group_change {
 my $self = shift;
 my ($gid, $attr) = @_;
 

 my %FIELDS = (GID => 'gid',
               G_NAME => 'name',
               G_DESCRIBE => 'descr');

 $self->changes($admin, { CHANGE_PARAM => 'GID',
		               TABLE        => 'groups',
		               FIELDS       => \%FIELDS,
		               OLD_INFO     => $self->group_info($attr->{GID}),
		               DATA         => $attr
		              } );


 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_add {
 my $self = shift;
 my ($attr) = @_;

 %DATA = $self->get_data($attr); 
 $self->query($db, "INSERT INTO groups (gid, name, descr)
    values ('$DATA{GID}', '$DATA{G_NAME}', '$DATA{G_DESCRIBE}');", 'do');

 return $self;
}



#**********************************************************
# group_add()
#**********************************************************
sub group_del {
 my $self = shift;
 my ($id) = @_;

 $self->query($db, "DELETE FROM groups WHERE gid='$id';", 'do');
 return $self;
}


#**********************************************************
# list()
#**********************************************************
sub list {
 my $self = shift;
 my ($attr) = @_;
 my @list = ();

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 $self->{SEARCH_FIELDS} = '';
 $self->{SEARCH_FIELDS_COUNT}=0;

 
 undef @WHERE_RULES;
 my $search_fields = '';

 

 if($attr->{DISABLE}) {
   $self->query($db, "SELECT u.id, pi.fio, if(company.id IS NULL, b.deposit, b.deposit), 
      u.credit, tp.name, u.disable, 
      u.uid, u.company_id, u.email, u.tp_id, if(l.start is NULL, '-', l.start)
     FROM users u, bills b
     LEFT JOIN users_pi pi ON u.uid = dv.id
     LEFT JOIN tarif_plans tp ON  (tp.id=u.tp_id) 
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     LEFT JOIN dv_log l ON  (l.uid=u.uid) 
     WHERE  
        u.bill_id=b.id
        and (b.deposit+u.credit-tp.credit_tresshold<=0
        and tp.hourp+tp.df+tp.abon>=0)
        or (
        (u.expire<>'0000-00-00' and u.expire < CURDATE())
        AND (u.activate<>'0000-00-00' and u.activate > CURDATE())
        )
        or u.disable=1
     GROUP BY u.uid
     ORDER BY $SORT $DESC;");

   my $list = $self->{list};
   return $list;
  }

 # Start letter 
 if ($attr->{FIRST_LETTER}) {
    push @WHERE_RULES, "u.id LIKE '$attr->{FIRST_LETTER}%'";
  }
 elsif ($attr->{LOGIN}) {
    push @WHERE_RULES, "u.id='$attr->{LOGIN}'";
  }
 # Login expresion
 elsif ($attr->{LOGIN_EXPR}) {
    $attr->{LOGIN_EXPR} =~ s/\*/\%/ig;
    push @WHERE_RULES, "u.id LIKE '$attr->{LOGIN_EXPR}'";
  }
 

 if ($attr->{PHONE}) {
    my $value = $self->search_expr($attr->{PHONE}, 'INT');
    push @WHERE_RULES, "pi.phone$value";
    $self->{SEARCH_FIELDS} = 'pi.phone, ';
    $self->{SEARCH_FIELDS_COUNT}++;
  }

 if ($attr->{DEPOSIT}) {
    my $value = $self->search_expr($attr->{DEPOSIT}, 'INT');
    push @WHERE_RULES, "b.deposit$value";
  }


 if ($attr->{COMMENTS}) {
 	$attr->{COMMENTS} =~ s/\*/\%/ig;
 	push @WHERE_RULES, "pi.comments LIKE '$attr->{COMMENTS}'";
  }    


 if ($attr->{FIO}) {
    $attr->{FIO} =~ s/\*/\%/ig;
    push @WHERE_RULES, "pi.fio LIKE '$attr->{FIO}'";
  }

 # Show debeters
 if ($attr->{DEBETERS}) {
    push @WHERE_RULES, "b.deposit<0";
  }

 # Show debeters
 if ($attr->{COMPANY_ID}) {
    push @WHERE_RULES, "u.company_id='$attr->{COMPANY_ID}'";
  }

 # Show groups
 if ($attr->{GID}) {
    push @WHERE_RULES, "u.gid='$attr->{GID}'";
  }

#Activate
 if ($attr->{ACTIVATE}) {
   my $value = $self->search_expr("'$attr->{ACTIVATE}'", 'INT');
   push @WHERE_RULES, "(u.activate='0000-00-00' or u.activate$value)"; 
 }

#Expire
 if ($attr->{EXPIRE}) {
   my $value = $self->search_expr("'$attr->{EXPIRE}'", 'INT');
   push @WHERE_RULES, "(u.expire='0000-00-00' or u.expire$value)"; 
 }

#DIsable
 if ($attr->{DISABLE}) {
   push @WHERE_RULES, "u.disable='$attr->{DISABLE}'"; 
 }
 
 
 
 $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
 
#Show last paymenst

 if ($attr->{PAYMENTS}) {

    my $value = $self->search_expr($attr->{PAYMENTS}, 'INT');
    push @WHERE_RULES, "max(p.date)$value";
    $self->{SEARCH_FIELDS} = 'max(p.date), ';
    $self->{SEARCH_FIELDS_COUNT}++;

   my $HAVING = ($#WHERE_RULES > -1) ?  "HAVING " . join(' and ', @WHERE_RULES) : '';

   $self->query($db, "SELECT u.id, 
       pi.fio, if(company.id IS NULL, b.deposit, b.deposit), u.credit, u.disable, 
       $self->{SEARCH_FIELDS}
       u.uid, 
       u.company_id, 
       pi.email, 
       u.activate, 
       u.expire
     FROM users u
     LEFT JOIN payments p ON (u.uid = p.uid)
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     GROUP BY u.uid     
     $HAVING 

     ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

   return $self if($self->{errno});



   my $list = $self->{list};

   if ($self->{TOTAL} > 0) {
     shift @WHERE_RULES;
     my $value = $self->search_expr($attr->{PAYMENTS}, 'INT');
     push @WHERE_RULES, "p.date$value";
     $WHERE = ($#WHERE_RULES > -1) ?  "WHERE " . join(' and ', @WHERE_RULES) : '';
    
     $self->query($db, "SELECT count(DISTINCT u.uid) FROM users u 
       LEFT JOIN payments p ON (u.uid = p.uid)
      $WHERE;");
      my $a_ref = $self->{list}->[0];
      ($self->{TOTAL}) = @$a_ref;
    }

 	  return $list
  }
 
 $self->query($db, "SELECT u.id, 
      pi.fio, if(company.id IS NULL, b.deposit, b.deposit), u.credit, u.disable, 
      $self->{SEARCH_FIELDS}
      u.uid, u.company_id, pi.email, u.activate, u.expire
     FROM users u
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN companies company ON  (u.company_id=company.id) 
     
     $WHERE ORDER BY $SORT $DESC LIMIT $PG, $PAGE_ROWS;");

 return $self if($self->{errno});



 my $list = $self->{list};

 if ($self->{TOTAL} > 0) {
    $self->query($db, "SELECT count(u.id) FROM users u 
     LEFT JOIN users_pi pi ON (u.uid = pi.uid)
     LEFT JOIN bills b ON u.bill_id = b.id
     LEFT JOIN companies company ON  (u.company_id=company.id) 
    $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}


#**********************************************************
# Add to deposit
#**********************************************************
sub add2deposit {
	my $self = shift;
	my ($sum) = @_;
	
 $self->query($db, "UPDATE users SET deposit=deposit+$sum 
     WHERE uid='$self->{UID}';");

  return $self;	
}

#**********************************************************
# add()
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;
  

  defaults();  
  %DATA = $self->get_data($attr, { default => $self }); 


  if ($DATA{LOGIN} eq '') {
     $self->{errno} = 8;
     $self->{errstr} = 'ERROR_ENTER_NAME';
     return $self;
   }
  elsif (length($DATA{LOGIN}) > $CONF->{MAX_USERNAME_LENGTH}) {
     $self->{errno} = 9;
     $self->{errstr} = 'ERROR_LONG_USERNAME';
     return $self;
   }

  #ERROR_SHORT_PASSWORD
  elsif($DATA{LOGIN} !~ /$usernameregexp/) {
     $self->{errno} = 10;
     $self->{errstr} = 'ERROR_WRONG_NAME';
     return $self; 	
   }
  elsif($DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/) {
      $self->{errno} = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
     }
   }
  
  $DATA{DISABLE} = int($DATA{DISABLE});
  $self->query($db,  "INSERT INTO users (id, activate, expire, credit, reduction, 
           registration, disable, company_id, gid, password)
           VALUES ('$DATA{LOGIN}', '$DATA{ACTIVATE}', '$DATA{EXPIRE}', '$DATA{CREDIT}', '$DATA{REDUCTION}', 
           now(),  '$DATA{DISABLE}', 
           '$DATA{COMPANY_ID}', '$DATA{GID}', 
           ENCODE('$DATA{PASSWORD}', '$CONF->{secretkey}')
            );", 'do');
  
  return $self if ($self->{errno});
  
  $self->{UID} = $self->{INSERT_ID};
  $self->{LOGIN} = $DATA{LOGIN};

  $admin->action_add("$self->{UID}", "ADD $DATA{LOGIN}");



  if ($attr->{CREATE_BILL}) {
  	#print "create bill";
  	$self->change($self->{UID}, { 
  		 DISABLE => int($DATA{DISABLE}),
  		 UID     => $self->{UID},
  		 create  => 'yes' });
  }

  return $self;
}




#**********************************************************
# change()
#**********************************************************
sub change {
  my $self = shift;
  my ($uid, $attr) = @_;
  
  my %FIELDS = (UID         => 'uid',
              LOGIN       => 'id',
              ACTIVATE    => 'activate',
              EXPIRE      => 'expire',
              CREDIT      => 'credit',
              REDUCTION   => 'reduction',
              SIMULTANEONSLY => 'logins',
              COMMENTS    => 'comments',
              COMPANY_ID  => 'company_id',
              DISABLE     => 'disable',
              GID         => 'gid',
              PASSWORD    => 'password',
              BILL_ID     => 'bill_id'
             );
 
  my $old_info = $self->info($attr->{UID});
  
  if($attr->{create}){
  	 use Bills;
  	 my $Bill = Bills->new($db, $admin, $CONF);
  	 $Bill->create({ UID => $self->{UID} });
     if($Bill->{errno}) {
       $self->{errno}  = $Bill->{errno};
       $self->{errstr} =  $Bill->{errstr};
       return $self;
      }
     #$DATA{BILL_ID}=$Bill->{BILL_ID};
     $attr->{BILL_ID}=$Bill->{BILL_ID};
     $attr->{DISABLE}=$old_info->{DISABLE};
   }
  
  
	$self->changes($admin, { CHANGE_PARAM => 'UID',
		                TABLE        => 'users',
		                FIELDS       => \%FIELDS,
		                OLD_INFO     => $old_info,
		                DATA         => $attr
		              } );


  return $self->{result};
}



#**********************************************************
# Delete user info from all tables
#
# del(attr);
#**********************************************************
sub del {
  my $self = shift;
  my ($attr) = @_;

  my @clear_db = ('admin_actions', 
                  'fees', 
                  'payments', 
                  'users_nas', 
                  'messages',
                  'docs_acct',
                  'dv_log',
                  'users',
                  'users_pi');

  foreach my $table (@clear_db) {
     $self->query($db, "DELETE from $table WHERE uid='$self->{UID}';", 'do');
     $self->{info} .= "$table, ";
    }

  $admin->action_add($self->{UID}, "DELETE $self->{UID}:$self->{LOGIN}");
  return $self->{result};
}

#**********************************************************
# list_allow nass
#**********************************************************
sub nas_list {
  my $self = shift;
  my $list;
  $self->query($db, "SELECT nas_id FROM users_nas WHERE uid='$self->{UID}';");


  if ($self->{TOTAL} > 0) {
    $list = $self->{list};
   }
  else {
    $self->query($db, "SELECT nas_id FROM tp_nas WHERE tp_id='$self->{TARIF_PLAN}';");
    $list = $self->{list};
   }

	return $list;
}


#**********************************************************
# list_allow nass
#**********************************************************
sub nas_add {
 my $self = shift;
 my ($nas) = @_;
 
 $self->nas_del();
 foreach my $line (@$nas) {
   $self->query($db, "INSERT INTO users_nas (nas_id, uid) VALUES ('$line', '$self->{UID}');", 'do');
  }
  
  $admin->action_add($self->{UID}, "NAS ". join(',', @$nas) );
  return $self;
}

#**********************************************************
# nas_del
#**********************************************************
sub nas_del {
  my $self = shift;
  
  $self->query($db, "DELETE FROM users_nas WHERE uid='$self->{UID}';", 'do');	
  return $self if($db->err > 0);

  $admin->action_add($self->{UID}, "DELETE NAS");
  return $self;
}



1
