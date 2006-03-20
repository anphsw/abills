package Mail;
# Mails
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
@access_actions
);

use Exporter;
$VERSION = 2.00;
@ISA = ('Exporter');





@EXPORT = qw(
  @access_actions
);

@EXPORT_OK = ();
%EXPORT_TAGS = ();

# User name expration
my $usernameregexp = "^[a-z0-9.][a-z0-9.-]*\$"; # configurable;
@access_actions = ('OK', 'REJECT', 'DISCARD', 'ERROR');

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
  return $self;
}



#**********************************************************
#
#**********************************************************
sub mbox_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 
	
	
	$self->query($db, "INSERT INTO mail_boxes 
    (username,  domain_id, descr, maildir, create_date, change_date, mails_limit, box_size, status, 
     uid, 
     antivirus, antispam, expire) values
    ('$DATA{USERNAME}', '$DATA{DOMAIN_ID}', '$DATA{COMMENTS}', '$DATA{MAILDIR}', now(), now(), 
     '$DATA{MAILS_LIMIT}', '$DATA{BOX_SIZE}', '$DATA{DISABLE}', 
    '$DATA{UID}', 
    '$DATA{ANTIVIRUS}', '$DATA{ANTISPAM}', '$DATA{EXPIRE}');", 'do');
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_del {
	my $self = shift;
	my ($id, $attr) = @_;

	$self->query($db, "DELETE FROM mail_boxes 
    WHERE id='$id';", 'do');
	
	return $self;
}


#**********************************************************
#
#**********************************************************
sub mbox_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (MBOX_ID      => 'id',
	              USERNAME     => 'username',  
	              DOMAIN_ID    => 'domain_id',
	              COMMENTS     => 'descr', 
	              MAILDIR      => 'maildir', 
	              CREATE_DATE  => 'create_date', 
	              CHANGE_DATE  => 'change_date', 
	              BOX_SIZE     => 'box_size',
	              MAILS_LIMIT  => 'mails_limit',
	              DISABLE      => 'status', 
	              UID          => 'uid', 
	              ANTIVIRUS    => 'antivirus', 
	              ANTISPAM     => 'antispam',
	              EXPIRE       => 'expire'
	              );
	
  $attr->{ANTIVIRUS} = (defined($attr->{ANTIVIRUS})) ? 1 : 0;
  $attr->{ANTISPAM} = (defined($attr->{ANTISPAM})) ? 1 : 0;
	
 	$self->changes($admin, 
 	              { CHANGE_PARAM => 'MBOX_ID',
	                TABLE        => 'mail_boxes',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->mbox_info($attr),
	                DATA         => $attr
		              } );


	

	return $self;
}






#**********************************************************
#
#**********************************************************
sub defaults {
	my $self = shift;
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT mb.username,  mb.domain_id, md.domain, mb.descr, mb.maildir, mb.create_date, 
   mb.change_date, 
   mb.mails_limit, 
   mb.box_size, 
   mb.status, 
   mb.uid,
   mb.antivirus, 
   mb.antispam,
   mb.expire,
   mb.id
   FROM mail_boxes mb
   LEFT JOIN mail_domains md ON  (md.id=mb.domain_id) 
   WHERE mb.id='$attr->{MBOX_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{USERNAME}, 
   $self->{DOMAIN_ID}, 
   $self->{DOMAIN}, 
   $self->{COMMENTS}, 
   $self->{MAILDIR}, 
   $self->{CREATE_DATE}, 
   $self->{CHANGE_DATE}, 
   $self->{MAILS_LIMIT},    
   $self->{BOX_SIZE}, 
   $self->{DISABLE}, 
   $self->{UID}, 
   $self->{ANTIVIRUS}, 
   $self->{ANTISPAM},
   $self->{EXPIRE},
   $self->{MBOX_ID}
  )= @$ar;
	
  #$self->{QUOTA} =~ s/C|S//g;
  #($self->{MAILS_LIMIT}, $self->{BOX_SIZE}) = split(/,/, $self->{QUOTA});

	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_list {
	my $self = shift;
	my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

 if (defined($attr->{UID})) {
 	  $WHERE .= ($WHERE ne '') ?  " and mb.uid='$attr->{UID}' " : "WHERE mb.uid='$attr->{UID}' ";
  }
 
 if ($attr->{FIRST_LETTER}) {
    $WHERE .= ($WHERE ne '') ?  " and mb.username LIKE '$attr->{FIRST_LETTER}%' " : "WHERE mb.username LIKE '$attr->{FIRST_LETTER}%' ";
  }
	
	
	$self->query($db, "SELECT mb.username, md.domain, u.id, mb.descr, mb.mails_limit, 
	      mb.box_size,
	      mb.antivirus, 
	      mb.antispam, mb.status, 
	      mb.create_date, mb.change_date, mb.expire, mb.maildir, 
	      mb.uid, mb.id
        FROM mail_boxes mb
        LEFT JOIN mail_domains md ON  (md.id=mb.domain_id)
        LEFT JOIN users u ON  (mb.uid=u.uid) 
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
    $self->query($db, "SELECT count(*) FROM mail_boxes mb $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}


#**********************************************************
#
#**********************************************************
sub domain_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 
	
	$self->query($db, "INSERT INTO mail_domains (domain, comments, create_date, change_date, status)
           VALUES ('$DATA{DOMAIN}', '$DATA{COMMENTS}', now(), now(), '$DATA{STATUS}');", 'do');
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_del {
	my $self = shift;
	my ($id) = @_;

	$self->query($db, "DELETE FROM mail_domains 
    WHERE id='$id';", 'do');
	
	return $self;
}


#**********************************************************
#
#**********************************************************
sub domain_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (MAIL_DOMAIN_ID   => 'id',
	              DOMAIN       => 'domain',
	              COMMENTS     => 'comments', 
	              CHANGE_DATE  => 'change_date', 
	              DISABLE      => 'status'
	              );
	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_DOMAIN_ID',
	                TABLE        => 'mail_domains',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->domain_info($attr),
	                DATA         => $attr
		              } );

	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_info {
	my $self = shift;
	my ($attr) = @_;
	
	
	print "aaaaaaaa $attr->{MAIL_DOMAIN_ID}";
	
  $self->query($db, "SELECT domain, comments, create_date, change_date, status, id
   FROM mail_domains WHERE id='$attr->{MAIL_DOMAIN_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{DOMAIN}, 
   $self->{COMMENTS}, 
   $self->{CREATE_DATE}, 
   $self->{CHANGE_DATE}, 
   $self->{DISABLE},
   $self->{MAIL_DOMAIN_ID}
  )= @$ar;
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_list {
	my $self = shift;
	my ($attr) = @_;

 $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
 $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';
 $PG = ($attr->{PG}) ? $attr->{PG} : 0;
 $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;
 	
	my $WHERE;
	
	$self->query($db, "SELECT md.domain, md.comments, md.status, md.create_date, 
	    md.change_date, count(*) as mboxes, md.id
        FROM mail_domains md
        LEFT JOIN mail_boxes mb ON  (md.id=mb.domain_id) 
        $WHERE
        GROUP BY md.id
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $PAGE_ROWS) {
    $self->query($db, "SELECT count(*) FROM mail_domains md $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub alias_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 
	
	$self->query($db, "INSERT INTO mail_aliases (address, goto,  create_date, change_date, status)
           VALUES ('$DATA{ADDRESS}', '$DATA{GOTO}', now(), now(), '$DATA{STATUS}');", 'do');

	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_del {
	my $self = shift;
	my ($id, $attr) = @_;
	$self->query($db, "DELETE FROM mail_aliases  WHERE id='$id';", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub alias_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (MAIL_ADDRESS  => 'address',
	              GOTO          => 'goto',
	              COMMENTS      => 'comments', 
	              CHANGE_DATE   => 'change_date', 
	              DISABLE       => 'status',
	              MAIL_ALIAS_ID => 'id'
	              );
	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_ALIAS_ID',
	                TABLE        => 'mail_aliases',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->alias_info($attr),
	                DATA         => $attr
		              } );

	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT address,  goto, comments, create_date, change_date, status, id
   FROM mail_aliases WHERE id='$attr->{MAIL_ALIAS_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{ADDRESS}, 
   $self->{GOTO}, 
   $self->{COMMENTS}, 
   $self->{CREATE_DATE}, 
   $self->{CHANGE_DATE}, 
   $self->{DISABLE},
   $self->{MAIL_ALIAS_ID}
  )= @$ar;
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_list {
	my $self = shift;
	my ($attr) = @_;
	
	$self->query($db, "SELECT ma.address, ma.goto, ma.comments, ma.status, ma.create_date, 
	    ma.change_date, ma.id
        FROM mail_aliases ma
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
    $self->query($db, "SELECT count(*) FROM mail_aliases $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}




#**********************************************************
#
#**********************************************************
sub access_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 

  if ($DATA{MACTION} == 3) {
  	 $DATA{FACTION} = "$access_actions[$DATA{MACTION}]:$DATA{CODE} $DATA{MESSAGE}";
    }
  else {
  	 $DATA{FACTION} = $access_actions[$DATA{MACTION}];
    }


  $self->query($db, "INSERT INTO mail_access (pattern, action, status, comments, change_date)
           VALUES ('$DATA{PATTERN}', '$DATA{FACTION}', '$DATA{DISABLE}', '$DATA{COMMENTS}', now());", 'do');

	return $self;
}

#**********************************************************
#
#**********************************************************
sub access_del {
	my $self = shift;
	
	my ($id, $attr) = @_;

	$self->query($db, "DELETE FROM mail_access WHERE id='$id';", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub access_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (PATTERN      => 'pattern',
	              ACTION       => 'action',
	              DISABLE      => 'status',
	              COMMENTS     => 'comments'
	              );
	
  if ($attr->{MACTION} == 3) {
  	 $attr->{ACTION} = "$access_actions[$attr->{MACTION}]:$attr->{CODE} $attr->{MESSAGE}";
    }
  else {
  	 $attr->{ACTION} = $access_actions[$attr->{MACTION}];
    }

	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_ACCESS_ID',
	                TABLE        => 'mail_access',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->access_info($attr),
	                DATA         => $attr
		              } );

	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub access_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT pattern, action, status, comments, change_date, id
   FROM mail_access WHERE pattern='$attr->{PATTERN}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{PATTERN}, 
   $self->{FACTION},
   $self->{DISABLE},
   $self->{COMMENTS},
   $self->{CHANGE_DATE},
   $self->{MAIL_ACCESS_ID}
  )= @$ar;
	
	($self->{FACTION}, $self->{CODE}, $self->{MESSAGE})=split(/:| /, $self->{FACTION}, 3);
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub access_list {
	my $self = shift;
	my ($attr) = @_;
	
	$self->query($db, "SELECT pattern, action, comments, status, change_date, id
        FROM mail_access
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
    $self->query($db, "SELECT count(*) FROM mail_access $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}



#**********************************************************
#
#**********************************************************
sub transport_add {
	my $self = shift;
	my ($attr) = @_;
  %DATA = $self->get_data($attr); 


  $self->query($db, "INSERT INTO mail_transport (domain, transport, comments, change_date) 
   values ('$DATA{DOMAIN}', '$DATA{TRANSPORT}', '$DATA{COMMENTS}', now());", 'do');

	return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_del {
	my $self = shift;
	my ($id, $attr) = @_;

	$self->query($db, "DELETE FROM mail_transport WHERE id='$id';", 'do');
	return $self;
}


#**********************************************************
#
#**********************************************************
sub transport_change {
	my $self = shift;
	my ($attr) = @_;


	my %FIELDS = (DOMAIN             => 'domain',
	              TRANSPORT          => 'transport',
	              COMMENTS           => 'comments',
	              MAIL_TRANSPORT_ID  => 'id'
	              );
	
 	$self->changes($admin, { CHANGE_PARAM => 'MAIL_TRANSPORT_ID',
	                TABLE        => 'mail_transport',
	                FIELDS       => \%FIELDS,
	                OLD_INFO     => $self->transport_info($attr),
	                DATA         => $attr
		              } );
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_info {
	my $self = shift;
	my ($attr) = @_;
	
	
  $self->query($db, "SELECT domain, transport, comments, change_date, id
   FROM mail_transport WHERE id='$attr->{MAIL_TRANSPORT_ID}';");

  if ($self->{TOTAL} < 1) {
     $self->{errno} = 2;
     $self->{errstr} = 'ERROR_NOT_EXIST';
     return $self;
   }

  my $ar = $self->{list}->[0];

  ($self->{DOMAIN}, 
   $self->{TRANSPORT},
   $self->{COMMENTS},
   $self->{CHANGE_DATE},
   $self->{MAIL_TRANSPORT_ID}
  )= @$ar;
	
	
	return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_list {
	my $self = shift;
	my ($attr) = @_;
	
	$self->query($db, "SELECT domain, transport, comments, change_date, id
        FROM mail_transport
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;");
 
  return $self if($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
    $self->query($db, "SELECT count(*) FROM mail_transport $WHERE");
    my $a_ref = $self->{list}->[0];
    ($self->{TOTAL}) = @$a_ref;
   }

  return $list;
}


1