package Mail;

# Mails
#

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
@access_actions
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw(
@access_actions
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

# User name expration
@access_actions = ('OK', 'REJECT', 'DISCARD', 'ERROR');

use main;
@ISA = ("main");

#**********************************************************
# Init
#**********************************************************
sub new {
  my $class = shift;
  my $db    = shift;
  ($admin, $CONF) = @_;

  $admin->{MODULE} = 'Mail';
  my $self = {};
  bless($self, $class);

  $self->{db}=$db;

  if ($CONF->{DELETE_USER}) {
    $self->mbox_del(0, { UID => $CONF->{DELETE_USER} });
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_add {
  my $self = shift;
  my ($attr) = @_;
  %DATA = $self->get_data($attr);

  $DATA{ANTIVIRUS} = (defined($attr->{ANTIVIRUS})) ? 0 : 1;
  $DATA{ANTISPAM}  = (defined($attr->{ANTISPAM}))  ? 0 : 1;

  $self->query2("INSERT INTO mail_boxes 
    (username,  domain_id, descr, maildir, create_date, change_date, mails_limit, box_size, status, 
     uid, 
     antivirus, antispam, expire, password) values
    ('$DATA{USERNAME}', '$DATA{MAIL_DOMAIN_ID}', '$DATA{COMMENTS}', '$DATA{MAILDIR}', now(), now(), 
     '$DATA{MAILS_LIMIT}', '$DATA{BOX_SIZE}', '$DATA{DISABLE}', 
    '$DATA{UID}', 
    '$DATA{ANTIVIRUS}', '$DATA{ANTISPAM}', '$DATA{EXPIRE}', 
    ENCODE('$DATA{PASSWORD}', '$CONF->{secretkey}'));", 'do'
  );

  return $self if ($self->{errno});

  $self->{MBOX_ID} = $self->{INSERT_ID};

  if ($DATA{MAIL_DOMAIN_ID}) {
    $self->domain_info({ MAIL_DOMAIN_ID => $DATA{MAIL_DOMAIN_ID} });
  }
  else {
    $self->{DOMAIN} = '';
  }

  $self->{USER_EMAIL} = $DATA{USERNAME} . '@' . $self->{DOMAIN};

  $admin->action_add($DATA{UID}, "ADD $self->{USER_EMAIL}");

  return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($CONF->{DELETE_USER}) {
    $self->query2("DELETE FROM mail_boxes 
      WHERE uid='$CONF->{DELETE_USER}';", 'do'
    );
  }
  else {
    $self->query2("DELETE FROM mail_boxes 
      WHERE id='$id' and uid='$attr->{UID}';", 'do'
    );
  }

  $admin->action_add($attr->{UID}, "$attr->{UID}", { TYPE => 10 });
  return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    MBOX_ID     => 'id',
    USERNAME    => 'username',
    DOMAIN_ID   => 'domain_id',
    COMMENTS    => 'descr',
    MAILDIR     => 'maildir',
    CREATE_DATE => 'create_date',
    CHANGE_DATE => 'change_date',
    BOX_SIZE    => 'box_size',
    MAILS_LIMIT => 'mails_limit',
    DISABLE     => 'status',
    UID         => 'uid',
    ANTIVIRUS   => 'antivirus',
    ANTISPAM    => 'antispam',
    EXPIRE      => 'expire',
    PASSWORD    => 'password'
  );

  $attr->{ANTIVIRUS} = (defined($attr->{ANTIVIRUS})) ? 0 : 1;
  $attr->{ANTISPAM}  = (defined($attr->{ANTISPAM}))  ? 0 : 1;
  $attr->{DISABLE}   = (defined($attr->{DISABLE}))   ? 1 : 0;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'MBOX_ID',
      TABLE        => 'mail_boxes',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->mbox_info($attr),
      DATA         => $attr
    }
  );

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

  my $WHERE = ($attr->{UID}) ? "and mb.uid='$attr->{UID}'" : '';

  $self->query2("SELECT 
   mb.username,  
   mb.domain_id, 
   md.domain, 
   mb.descr AS comments, 
   mb.maildir, 
   mb.create_date, 
   mb.change_date, 
   mb.mails_limit, 
   mb.box_size, 
   mb.status AS disable, 
   mb.uid,
   mb.antivirus, 
   mb.antispam,
   mb.expire,
   mb.id AS mbox_id
   FROM mail_boxes mb
   LEFT JOIN mail_domains md ON  (md.id=mb.domain_id) 
   WHERE mb.id='$attr->{MBOX_ID}' $WHERE;",
   undef,
   { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub mbox_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  my $WHERE =  $self->search_former($attr, [
      ['FIO',          'STR', 'pi.fio',                  ],
      ['USERNAME',     'INT', 'mb.username',             ],
      ['DOMAIN',       'INT', 'mb.username',             ],
      ['DESCR',         'STR', 'mb.descr',                ],
      ['mails_limit',  'INT', 'mb.mails_limit',          ],
      ['box_size',     'INT', 'mb.box_size',             ],
      ['antivirus',    'INT', 'mb.antivirus',            ], 
      ['antispam',     'INT', 'mb.antispam',             ],
      ['status',       'INT', 'mb.status',               ],
      ['create_date',  'INT', 'mb.create_date',          ],      
    ],
    { WHERE       => 1,
    	WHERE_RULES => \@WHERE_RULES,
    	USERS_FIELDS=> 1,
    	SKIP_USERS_FIELDS=> [ 'FIO' ]
    }    
    );

  my $EXT_TABLES = '';
  $EXT_TABLES = $self->{EXT_TABLES} if ($self->{EXT_TABLES});

  if ($self->{SEARCH_FIELDS}=~/pi\./) {
    $EXT_TABLES .= 'LEFT JOIN users_pi pi ON (u.uid = pi.uid)';
  }

  $self->query2("SELECT mb.username, md.domain, u.id, mb.descr, mb.mails_limit, 
        mb.box_size,
        mb.antivirus, 
        mb.antispam, mb.status, 
        mb.create_date, mb.change_date, mb.expire, mb.maildir, 
        mb.uid, 
        mb.id
      FROM mail_boxes mb
        LEFT JOIN mail_domains md ON  (md.id=mb.domain_id)
        LEFT JOIN users u ON  (mb.uid=u.uid) 
        $EXT_TABLES
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM mail_boxes mb $WHERE", 
      undef, { INFO => 1 });
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

  $self->query_add('mail_domains', { %DATA,
  	                                 CREATE_DATE => 'now()', 
  	                                 CHANGE_DATE => 'now()'
  	                                });
  return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_del {
  my $self = shift;
  my ($id) = @_;

  $self->query2("DELETE FROM mail_domains 
    WHERE id='$id';", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    MAIL_DOMAIN_ID => 'id',
    DOMAIN         => 'domain',
    COMMENTS       => 'comments',
    CHANGE_DATE    => 'change_date',
    DISABLE        => 'status',
    BACKUP_MX      => 'backup_mx',
    TRANSPORT      => 'transport'
  );

  $attr->{BACKUP_MX} = (!defined($attr->{BACKUP_MX})) ? 0 : 1;

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'MAIL_DOMAIN_ID',
      TABLE        => 'mail_domains',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->domain_info($attr),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT domain, comments, create_date, change_date, status AS disable, 
  backup_mx,
  transport,
  id
   FROM mail_domains WHERE id='$attr->{MAIL_DOMAIN_ID}';", undef, { INFO => 1 }   
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub domain_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my @WHERE_RULES = ();

  if (defined($attr->{BACKUP_MX})) {
    push @WHERE_RULES, "md.backup_mx='$attr->{BACKUP_MX}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT md.domain, md.comments, md.status, md.backup_mx, md.transport, md.create_date, 
      md.change_date, count(*) as mboxes, md.id
        FROM mail_domains md
        LEFT JOIN mail_boxes mb ON  (md.id=mb.domain_id) 
        $WHERE
        GROUP BY md.id
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef, $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= 0) {
    $self->query2("SELECT count(*) AS total FROM mail_domains md $WHERE", undef, { INFO => 1 });
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

  $self->query_add('mail_aliases', { %DATA,
  	                                 CREATE_DATE => 'now()', 
  	                                 CHANGE_DATE => 'now()'
  	                                });

  return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_del {
  my $self = shift;
  my ($id, $attr) = @_;
  $self->query2("DELETE FROM mail_aliases  WHERE id='$id';", 'do');
  return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    ADDRESS       => 'address',
    GOTO          => 'goto',
    COMMENTS      => 'comments',
    CHANGE_DATE   => 'change_date',
    DISABLE       => 'status',
    MAIL_ALIAS_ID => 'id'
  );

  $attr->{DISABLE} = (! $attr->{DISABLE}) ? 0 : 1;


  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'MAIL_ALIAS_ID',
      TABLE        => 'mail_aliases',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->alias_info($attr),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT address,  goto, comments, create_date, change_date, status AS disable, id AS mail_alias_id
   FROM mail_aliases WHERE id='$attr->{MAIL_ALIAS_ID}';"
   , undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub alias_list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();
  $WHERE       = '';

  $self->query2("SELECT ma.address, ma.goto, ma.comments, ma.status, ma.create_date, 
      ma.change_date, ma.id
        FROM mail_aliases ma
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM mail_aliases $WHERE", undef, { INFO => 1 });
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
    $DATA{FACTION} = $access_actions[ $DATA{MACTION} ];
  }

  $self->query2("INSERT INTO mail_access (pattern, action, status, comments, change_date)
           VALUES ('$DATA{PATTERN}', '$DATA{ACTION}', '$DATA{DISABLE}', '$DATA{COMMENTS}', now());", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub access_del {
  my $self = shift;

  my ($id, $attr) = @_;

  $self->query2("DELETE FROM mail_access WHERE id='$id';", 'do');
  return $self;
}

#**********************************************************
#
#**********************************************************
sub access_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    PATTERN  => 'pattern',
    ACTION   => 'action',
    DISABLE  => 'status',
    COMMENTS => 'comments'
  );

  if ($attr->{MACTION} == 3) {
    $attr->{ACTION} = "$access_actions[$attr->{MACTION}]:$attr->{CODE} $attr->{MESSAGE}";
  }
  else {
    $attr->{ACTION} = $access_actions[ $attr->{MACTION} ];
  }

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'MAIL_ACCESS_ID',
      TABLE        => 'mail_access',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->access_info($attr),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub access_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT pattern, action AS faction, status AS disable, comments, change_date, id AS mail_access_id
   FROM mail_access WHERE pattern='$attr->{PATTERN}';",
   undef, { INFO => 1 }
  );

  ($self->{FACTION}, $self->{CODE}, $self->{MESSAGE}) = split(/:| /, $self->{FACTION}, 3);

  return $self;
}

#**********************************************************
#
#**********************************************************
sub access_list {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = '';

  $self->query2("SELECT pattern, action, comments, status, change_date, id
        FROM mail_access
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS}) {
    $self->query2("SELECT count(*) AS total FROM mail_access $WHERE", undef, { INFO => 1 });
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

  $self->query_add('mail_transport', { %DATA,
  	                                   change_date => 'now()' 
  	                                 }); 

  return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_del {
  my $self = shift;
  my ($id, $attr) = @_;

  $self->query2("DELETE FROM mail_transport WHERE id='$id';", 'do');
  return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    DOMAIN            => 'domain',
    TRANSPORT         => 'transport',
    COMMENTS          => 'comments',
    MAIL_TRANSPORT_ID => 'id'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'MAIL_TRANSPORT_ID',
      TABLE        => 'mail_transport',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->transport_info($attr),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT domain, transport, comments, change_date, id AS mail_transport_id
   FROM mail_transport WHERE id='$attr->{MAIL_TRANSPORT_ID}';",
   undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub transport_list {
  my $self = shift;
  my ($attr) = @_;

  $WHERE = '';

  $self->query2("SELECT domain, transport, comments, change_date, id
        FROM mail_transport
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM mail_transport $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub spam_replace {
  my $self = shift;
  my ($attr) = @_;
  %DATA = $self->get_data($attr);

  $self->spam_del(
    0,
    {
      USER_NAME  => "$DATA{USER_NAME}",
      PREFERENCE => "$DATA{PREFERENCE}"
    }
  );

  $self->query2("INSERT INTO mail_spamassassin (username, preference, value, comments, create_date, change_date) 
   values ('$DATA{USER_NAME}', '$DATA{PREFERENCE}', '$DATA{VALUE}', '$DATA{COMMENTS}', now(), now());", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_add {
  my $self = shift;
  my ($attr) = @_;
  %DATA = $self->get_data($attr);

  $self->query2("INSERT INTO mail_spamassassin (username, preference, value, comments, create_date, change_date) 
   values ('$DATA{USER_NAME}', '$DATA{PREFERENCE}', '$DATA{VALUE}', '$DATA{COMMENTS}', now(), now());", 'do'
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_del {
  my $self = shift;
  my ($id, $attr) = @_;

  if ($attr->{USER_NAME} && $attr->{PREFERENCE}) {
    $WHERE = "username='$attr->{USER_NAME}' and preference='$attr->{PREFERENCE}'";
  }
  else {
    $WHERE = "prefid='$id'";
  }

  $self->query2("DELETE FROM mail_spamassassin WHERE $WHERE;", 'do');
  return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_change {
  my $self = shift;
  my ($attr) = @_;

  my %FIELDS = (
    USER_NAME   => 'user_name',
    PREFERENCE  => 'preference',
    VALUE       => 'value',
    COMMENTS    => 'comments',
    CHANGE_DATE => 'change_date',
    ID          => 'prefid'
  );

  $self->changes(
    $admin,
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'mail_spamassassin',
      FIELDS       => \%FIELDS,
      OLD_INFO     => $self->spam_info($attr),
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_info {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("SELECT username AS user_name, preference, value, comments, create_date, change_date
   FROM mail_spamassassin WHERE prefid='$attr->{ID}';", undef, { INFO => 1 }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_list {
  my $self = shift;
  my ($attr) = @_;

  @WHERE_RULES = ();
  $WHERE       = '';

  if ($attr->{USER_NAME}) {
    $attr->{USER_NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "username LIKE '$attr->{USER_NAME}'";
  }

  if ($attr->{PREFERENCE}) {
    $attr->{PREFERENCE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "preference LIKE '$attr->{PREFERENCE}'";
  }

  if ($attr->{VALUE}) {
    $attr->{VALUE} =~ s/\*/\%/ig;
    push @WHERE_RULES, "value LIKE '$attr->{VALUE}'";
  }

  if ($attr->{COMMENTS}) {
    $attr->{COMMENTS} =~ s/\*/\%/ig;
    push @WHERE_RULES, "comments LIKE '$attr->{COMMENTS}'";
  }

  $WHERE = "WHERE " . join(' and ', @WHERE_RULES) if ($#WHERE_RULES > -1);

  $self->query2("SELECT username, preference, value, comments, change_date, prefid
        FROM mail_spamassassin
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
   undef,
   $attr        
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query2("SELECT count(*) AS total FROM mail_spamassassin $WHERE", undef, { INFO => 1 });
  }

  return $list;
}

#**********************************************************
#
#**********************************************************
sub spam_awl_del {
  my $self = shift;
  my ($attr) = @_;

  if ($attr->{TYPE}) {
    $WHERE = '';

    if ($attr->{TYPE} eq 'USER') {
      $attr->{VALUE} =~ s/\*/\%/ig;
      $WHERE = "username LIKE '$attr->{VALUE}'";
    }
    elsif ($attr->{TYPE} eq 'EMAIL') {
      $attr->{VALUE} =~ s/\*/\%/ig;
      $WHERE = "email LIKE '$attr->{VALUE}'";
    }
    elsif ($attr->{TYPE} eq 'IP') {
      $attr->{VALUE} =~ s/\*/\%/ig;
      $WHERE = "IP LIKE $attr->{VALUE}";
    }
    elsif ($attr->{TYPE} eq 'COUNT') {
      my $value = $self->search_expr($attr->{VALUE}, 'INT');
      $WHERE = "count$value";
    }
    elsif ($attr->{TYPE} eq 'SCORE') {
      my $value = $self->search_expr($attr->{VALUE}, 'INT');
      $WHERE = "totscore$value";
    }

    $self->query2("DELETE FROM mail_awl WHERE $WHERE;", 'do');
  }
  else {
    my @selected = split(/, /, $attr->{IDS});

    foreach my $line (@selected) {
      my ($username, $email) = split(/\|/, $line, 2);
      $self->query2("DELETE FROM mail_awl WHERE username='$username' and email='$email';", 'do');
    }
  }

  return $self;
}

#**********************************************************
#
#**********************************************************
sub spam_awl_list {
  my $self = shift;
  my ($attr) = @_;

  $SORT      = ($attr->{SORT})      ? $attr->{SORT}      : 1;
  $DESC      = ($attr->{DESC})      ? $attr->{DESC}      : '';
  $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  @WHERE_RULES = ();

  if ($attr->{USER_NAME}) {
    $attr->{USER_NAME} =~ s/\*/\%/ig;
    push @WHERE_RULES, "username LIKE '$attr->{USER_NAME}'";
  }

  if ($attr->{EMAIL}) {
    $attr->{EMAIL} =~ s/\*/\%/ig;
    push @WHERE_RULES, "email LIKE '$attr->{EMAIL}'";
  }

  if ($attr->{SCORE}) {
    my $value = $self->search_expr($attr->{SCORE}, 'INT');
    push @WHERE_RULES, "totscore$value";
  }

  if ($attr->{COUNT}) {
    my $value = $self->search_expr($attr->{COUNT}, 'INT');
    push @WHERE_RULES, "count$value";
  }

  $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  $self->query2("SELECT username, email, ip, count, totscore
        FROM mail_awl
        $WHERE
        ORDER BY $SORT $DESC
        LIMIT $PG, $PAGE_ROWS;",
    undef,
    $attr
  );

  return $self if ($self->{errno});

  my $list = $self->{list};

  if ($self->{TOTAL} >= $attr->{PAGE_ROWS} || $PG > 0) {
    $self->query2("SELECT count(*) FROM mail_awl $WHERE", undef, { INFO => 1 });
  }

  return $list;
}
1
