package main;
#Main SQL function

use strict;
use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $VERSION
$db
$admin
$CONF
%DATA
$OLD_DATA
@WHERE_RULES
$WHERE

$SORT
$DESC
$PG
$PAGE_ROWS
);

use Exporter;
$VERSION = 2.00;
@ISA     = ('Exporter');

@EXPORT = qw(
$db
$admin
$CONF
@WHERE_RULES
$WHERE
%DATA
%OLD_DATA

$SORT
$DESC
$PG
$PAGE_ROWS
);

@EXPORT_OK   = ();
%EXPORT_TAGS = ();

$db          = undef;
$admin       = undef;
$CONF        = undef;
@WHERE_RULES = ();
$WHERE       = '';
%DATA        = ();
$OLD_DATA    = ();      #all data

$SORT      = 1;
$DESC      = '';
$PG        = 0;
$PAGE_ROWS = 25;

my $query_count = 0;
use DBI;
use Abills::Base qw(ip2int int2ip in_array);

#**********************************************************
# Connect to DB
#**********************************************************
sub connect {
  my $class = shift;
  my $self  = {};
  my ($dbhost, $dbname, $dbuser, $dbpasswd, $attr) = @_;

  bless($self, $class);
  #my %conn_attrs = (PrintError => 0, RaiseError => 1, AutoCommit => 1);
  
  if ($self->{db} = DBI->connect_cached("DBI:mysql:database=$dbname;host=$dbhost;mysql_client_found_rows=0", "$dbuser", "$dbpasswd")) {
    $self->{db}->{mysql_auto_reconnect} = 1;
    #For mysql 5 or highter
    $self->{db}->do("SET NAMES " . $attr->{CHARSET}) if ($attr->{CHARSET});
    my $sql_mode = ($attr->{SQL_MODE}) ? $attr->{SQL_MODE} : 'NO_ENGINE_SUBSTITUTION';
    $self->{db}->do("SET sql_mode='$sql_mode';");
  } 
  else {
    print "Content-Type: text/html\n\nError: Unable connect to DB server '$dbhost:$dbname'\n";
    $self->{error} = $DBI::errstr;
    my $a = `echo "Connection Error: $DBI::errstr" >> /tmp/sql_errors `;
  }

  $self->{query_count} = 0;

  return $self;
}

sub disconnect {
  my $self = shift;
  $self->{db}->disconnect;
  return $self;
}

#**********************************************************
#
#**********************************************************
sub db_version {
  my $self = shift;
  my ($attr) = @_;

  my $version = $db->get_info(18);
  if ($version =~ /^(\d+\.\d+)/) {
    $version = $1;
  }

  return $version;
}

#**********************************************************
#  do
# type. do
#       list
#**********************************************************
sub query2 {
  my $self = shift;
  my ($query, $type, $attr) = @_;

  my $db = $self->{db};
 
  if ( $attr->{DB_REF} ) {
    $db = $attr->{DB_REF};
  }

  $self->query($db, $query, $type, $attr);

  return $self;
}

#**********************************************************
#  do
# type. do
#       list
#**********************************************************
sub query {
  my $self = shift;
  my ($db, $query, $type, $attr) = @_;

  $self->{errstr} = undef;
  $self->{errno}  = undef;
  $self->{TOTAL}  = 0;

  print "<pre><code>\n$query\n</code></pre>\n" if ($self->{debug});
  
  if(! $db){
    require Log;
    Log->import('log_print');

    log_print(undef, 'LOG_ERR', '', "\n$query\n --$self->{sql_errno}\n --$self->{sql_errstr}\nundefined \$db", { NAS => 0, LOG_FILE => "/tmp/sql_errors" });
    return $self;
  }

  if (defined($attr->{test})) {
    return $self;
  }

  my $q;

  my @Array = ();

  # check bind params for bin input
  if ($attr->{Bind}) {
    foreach my $Data (@{ $attr->{Bind} }) {
      push(@Array, $Data);
    }
  }
  
  $self->{AFFECTED}=0;
  if ($type && $type eq 'do') {
    $self->{AFFECTED} = $db->do($query, undef, @Array);
    if (defined($db->{'mysql_insertid'})) {
      $self->{INSERT_ID} = $db->{'mysql_insertid'};
    }
  }
  else {
    if ($attr->{MULTI_QUERY}) {
      foreach my $line (@{ $attr->{MULTI_QUERY} }) {
        $q->execute(@$line);
        if ($db->err) {
          $self->{errno}      = 3;
          $self->{sql_errno}  = $db->err;
          $self->{sql_errstr} = $db->errstr;
          $self->{errstr}     = $db->errstr;
          return $self->{errno};
        }
      }
    }
    else {
      $q = $db->prepare($query);
      if (!$db->err) {
        $q->execute();
      }
      $self->{TOTAL} = $q->rows;
    }
    #$self->{Q} = $q;
    #$self->{QS}++;
  }

  if ($db->err) {
    if ($db->err == 1062) {
      $self->{errno}  = 7;
      $self->{errstr} = 'ERROR_DUBLICATE';
    }
    else {
      $self->{sql_errno}  = $db->err;
      $self->{sql_errstr} = $db->errstr;
      $self->{errno}      = 3;
      $self->{errstr}     = 'SQL_ERROR';    # . ( ($self->{db}->strerr) ? $self->{db}->strerr : '' );
      require Log;
      Log->import('log_print');
      log_print(undef, 'LOG_ERR', '', "\n$query\n --$self->{sql_errno}\n --$self->{sql_errstr}\n --AutoCommit: $db->{AutoCommit}\n", { NAS => 0, LOG_FILE => "/tmp/sql_errors" });
    }
    return $self;
  }

  if ($self->{TOTAL} > 0) {
    my @rows = ();

    if ($attr->{COLS_NAME}) {
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };
      while (my $row = $q->fetchrow_hashref()) {
        if ($attr->{COLS_UPPER}) {
          my $row2;
          while(my($k,$v)=each %$row) {
            $row2->{uc($k)}=$v;
          }
          $row = { %$row2, %$row };
        }
        push @rows, $row;
      }      
    }
    elsif ($attr->{INFO}) {
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };          
      while (my $row = $q->fetchrow_hashref()) {
        while(my ($k, $v) = each %$row ) {
          $self->{ uc($k) }=$v;
        }
      }
    }
    else {
      while (my @row = $q->fetchrow()) {
        push @rows, \@row;
      }
    }
    $self->{list} = \@rows;
  }
  else {
    delete $self->{list};
    if ($attr->{INFO}) {
      $self->{errno}  = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
    }
  }

  $self->{query_count}++;
  return $self;
}

#**********************************************************
# get_data
#**********************************************************
sub get_data {
  my $self = shift;
  my ($params, $attr) = @_;
  my %DATA;

  if (defined($attr->{default})) {
    %DATA = %{ $attr->{default} };
  }

  while (my ($k, $v) = each %$params) {
    next if (!$params->{$k} && defined($DATA{$k}));
    $v =~ s/^ +|[ \n]+$//g if ($v);
    $DATA{$k} = $v;
  }

  return %DATA;
}





#**********************************************************
# search_expr($self, $value, $type)
#
# type of fields
#  IP -  IP Address
#  INT - integer
#  STR - string
#  DATE - Date
# data delimiters 
# , - or
# ; - and
#**********************************************************
sub search_former {
  my $self = shift;
  my ($data, $search_params, $attr)=@_;

  my @WHERE_RULES                = ();
  $self->{SEARCH_FIELDS}         = '';
  $self->{SEARCH_FIELDS_COUNT}   = 0;
  @{ $self->{SEARCH_FIELDS_ARR} }= ();
  
  
  foreach my $search_param (@$search_params) {
    my ($param, $field_type, $sql_field, $show, $ex_params)=@$search_param;
    my $param2 = '';
    if ($param =~ /^(.*)\|(.*)$/) {
      $param  = $1;
      $param2 = $2;
    }

    if($data->{$param} || ($field_type eq 'INT' && defined($data->{$param}) && $data->{$param} ne '')) {
      if ($sql_field eq '') {
        $self->{SEARCH_FIELDS} .= "$show, ";
        $self->{SEARCH_FIELDS_COUNT}++;
        push @{ $self->{SEARCH_FIELDS_ARR} }, $show;
       }
      elsif ($param2) {
        push @WHERE_RULES, "($sql_field>='$data->{$param}' and $sql_field<='$data->{$param2}')";
      }
      else {
        push @WHERE_RULES, @{ $self->search_expr($data->{$param}, "$field_type", "$sql_field", { EXT_FIELD => $show }) };
      }
    }
  }

  if ($attr->{USERS_FIELDS}) {
    push @WHERE_RULES, @{ $self->search_expr_users({ %$data, 
                             EXT_FIELDS => [
                                            'FIO',
                                            'DEPOSIT',
                                            'CREDIT',
                                            'CREDIT_DATE', 
                                            'PHONE',
                                            'EMAIL',
                                            'ADDRESS_FLAT',
                                            'PASPORT_DATE',
                                            'PASPORT_NUM', 
                                            'PASPORT_GRANT',
                                            'CITY', 
                                            'ZIP',
                                            'GID',
                                            'CONTRACT_ID',
                                            'COMPANY_ID',
                                            'CONTRACT_SUFIX',
                                            'CONTRACT_DATE',
                                            'EXPIRE',
                                            'REDUCTION',
                                            'REDUCTION_DATE',
                                            'COMMENTS',
                                            'BILL_ID',
                                            'LOGIN_STATUS',
                                            
                                            'ACTIVATE',
                                            'EXPIRE',
                                            'REGISTRATION',
                                             ],
                             SKIP_USERS_FIELDS => $attr->{SKIP_USERS_FIELDS},
                             SUPPLEMENT=> 1 
                         }) };
  }

  if ($attr->{WHERE_RULES}) {
    push @WHERE_RULES, @{ $attr->{WHERE_RULES} };
  }

  my $WHERE = ($#WHERE_RULES > -1) ?  (($attr->{WHERE}) ? 'WHERE ' : '') . join(' and ', @WHERE_RULES) : '';

  return $WHERE;
}

#**********************************************************
# search_expr($self, $value, $type)
#
# type of fields
#  IP -  IP Address
#  INT - integer
#  STR - string
#  DATE - Date
# data delimiters 
# , - or
# ; - and
#**********************************************************
sub search_expr {
  my $self = shift;
  my ($value, $type, $field, $attr) = @_;

  if ($attr->{EXT_FIELD}) {
    $self->{SEARCH_FIELDS} .= ($attr->{EXT_FIELD} ne '1') ? "$attr->{EXT_FIELD}, " : "$field, ";
    $self->{SEARCH_FIELDS_COUNT}++;

    push @{ $self->{SEARCH_FIELDS_ARR} }, ($attr->{EXT_FIELD} ne '1') ? split(', ', $attr->{EXT_FIELD}) : "$field";
  }
  my @result_arr = ();
  if (! defined($value)) {
    $value = '';
  }

  return \@result_arr if ( $value eq '_SHOW');

  if ($field) {
    $field =~ s/ (as) ([a-z0-9_]+)//gi;
  }
  $value = '' if (! defined($value)); 
  my $delimiter = ($value =~ s/;/,/g) ? 'and' : 'or';
  
  if ($value && $delimiter eq 'and' && $value !~ /[<>=]+/) {
    my @val_arr = split(/,/, $value);
    $value = "'" . join("', '", @val_arr) . "'";
    return ["$field IN ($value)"];
  }
  
  my @val_arr = split(/,/, $value) if (defined($value));

  foreach my $v (@val_arr) {
    my $expr = '=';
    if ($type eq 'DATE') {
      if($v =~ /(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})/) {
        my $from_date = $1;
        my $to_date   = $2;
        if ($field) {
          push @result_arr, "($field>='$from_date' AND $field<='$to_date')" ;
        }
        next;
      }
      elsif ($v =~ /([=><!]{0,2})(\d{2})[\/\.\-](\d{2})[\/\.\-](\d{4})/) {
        $v = "$1$4-$3-$2";
      }
      elsif ($v eq '*') {
        $v = ">=0000-00-00";
      }
    }

    if ($type eq 'INT' && $v =~ s/\*/\%/g) {
      $expr = ' LIKE ';
    }
    elsif ($v =~ s/^!//) {
      $expr = ' <> ';
    }
    elsif ($type eq 'STR') {
      $expr = '=';
      if ($v =~ /\\\*/) {
        $v = '*';
      }
      else {
        if ($v =~ s/\*/\%/g) {
          $expr = ' LIKE ';
        }
      }
    }
    elsif ($v =~ s/^([<>=]{1,2})//) {
      $expr = $1;
    }

    if ($type eq 'IP') {
      if ($value =~ m/\*/g) {
        my ($i, $first_ip, $last_ip);
        my @p = split(/\./, $value);
        for ($i = 0 ; $i < 4 ; $i++) {
          if ($p[$i] =~ /(\d{0,2})\*/) {
            $first_ip .= $1 . '0';
            $last_ip  .= '255';
          }
          else {
            $first_ip .= $p[$i];
            $last_ip  .= $p[$i];
          }
          if ($i != 3) {
            $first_ip .= '.';
            $last_ip  .= '.';
          }
        }
        push @result_arr, "($field>=INET_ATON('$first_ip') and $field<=INET_ATON('$last_ip'))";
        return \@result_arr;
      }
      else {      
        $v = "INET_ATON('$v')";
      }
    }
    else {
      $v = "'$v'";
    }

    $value = $expr . $v;

    push @result_arr, "$field$value" if ($field);
  }

  if ($field) {
    if ($type ne 'INT') {
      if ($#result_arr > -1) {
        return [ '(' . join(" $delimiter ", @result_arr) . ')' ];
      }
      else {
        return [];
      }
    }
    return \@result_arr;
  }

  return [ $value ];
}

#**********************************************************
# change_constructor($self, $uid, $attr)
# $attr
#  CHANGE_PARAM - chenging param
#  TABLE        - changing table
#  \%FIELDS     - fields of table
#  ...          - data
#  OLD_INFO     - OLD infomation for compare
#**********************************************************
sub changes {
  my $self = shift;
  my ($admin, $attr) = @_;

  my $TABLE        = $attr->{TABLE};
  my $CHANGE_PARAM = $attr->{CHANGE_PARAM};
  my $FIELDS       = $attr->{FIELDS};
  my %DATA         = $self->get_data($attr->{DATA});
  my $db           = $self->{db};



  if (!$DATA{UNCHANGE_DISABLE}) {
    $DATA{DISABLE} = (defined($DATA{'DISABLE'}) && $DATA{DISABLE} ne '') ? $DATA{DISABLE} : undef;
  }

  if (defined($DATA{EMAIL}) && $DATA{EMAIL} ne '') {
    if ($DATA{EMAIL} !~ /(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/) {
      $self->{errno}  = 11;
      $self->{errstr} = 'ERROR_WRONG_EMAIL';
      return $self;
    }
  }

  $OLD_DATA = $attr->{OLD_INFO};
  if ($OLD_DATA->{errno}) {
    print  "Old date errors: $OLD_DATA->{errno} '$TABLE' $attr->{CHANGE_PARAM}=$DATA{$CHANGE_PARAM}\n";
    print %DATA;
    $self->{errno}  = $OLD_DATA->{errno};
    $self->{errstr} = $OLD_DATA->{errstr};
    return $self;
  }

  if (! $attr->{OLD_INFO} && ! $FIELDS ) {
      my $sql = "SELECT * FROM $TABLE WHERE ". lc($attr->{CHANGE_PARAM})."='".$DATA{$attr->{CHANGE_PARAM}}."';";
      if($self->{debug}) {
        print $sql;  
      }
      my $q = $db->prepare($sql);
      $q->execute();
      my @inserts_arr = ();
  
      while (defined(my $row = $q->fetchrow_hashref())) {
        while(my ($k, $v) = each %$row ) {
          my $field_name = uc($k);
          if ($field_name eq 'IP') {
            $v = int2ip($v);
          }

          $OLD_DATA->{ $field_name }=$v;
          $FIELDS->{ $field_name }=$k;
        }
      }
  }

  my $CHANGES_QUERY = "";
  my $CHANGES_LOG   = "";
  while (my ($k, $v) = each(%DATA)) {
    #print "$k / $v -> $FIELDS->{$k} && $DATA{$k} && $OLD_DATA->{$k} ne $DATA{$k}<br>\n";
    if ($FIELDS->{$k} && defined($DATA{$k}) && $OLD_DATA->{$k} ne $DATA{$k}) {
      if ($k eq 'PASSWORD' || $k eq 'NAS_MNG_PASSWORD') {
        if ($DATA{$k}) {
          $CHANGES_LOG   .= "$k *->*;";
          $CHANGES_QUERY .= "$FIELDS->{$k}=ENCODE('$DATA{$k}', '$CONF->{secretkey}'),";
        }
      }
      elsif ($k eq 'IP' || $k eq 'NETMASK') {
        if ($DATA{$k} !~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/) {
          $DATA{$k} = '0.0.0.0';
        }

        $CHANGES_LOG   .= "$k $OLD_DATA->{$k}->$DATA{$k};";
        $CHANGES_QUERY .= "$FIELDS->{$k}=INET_ATON('$DATA{$k}'),";
      }
      elsif ($k eq 'IPV6_PREFIX') {
        $CHANGES_LOG   .= "$k $OLD_DATA->{$k}->$DATA{$k};";
        $CHANGES_QUERY .= "$FIELDS->{$k}=INET6_ATON('$DATA{$k}'),";
      }
      elsif ($k eq 'CHANGED') {
        $CHANGES_QUERY .= "$FIELDS->{$k}=now(),";
      }
      else {
        if (!$OLD_DATA->{$k} && ($DATA{$k} eq '0' || $DATA{$k} eq '')) {
          next;
        }

        if ($k eq 'DISABLE') {
          if (defined($DATA{$k}) && $DATA{$k} == 0 || !defined($DATA{$k})) {
            if ($self->{DISABLE} != 0) {
              $self->{ENABLE}  = 1;
              $self->{DISABLE} = undef;
            }
          }
          else {
            $self->{DISABLE_ACTION} = 1;
          }
        }
        elsif ($k eq 'DOMAIN_ID' && $OLD_DATA->{$k} == 0 && !$DATA{$k}) {
        }
        elsif ($k eq 'STATUS') {
          $self->{CHG_STATUS} = $OLD_DATA->{$k} . '->' . $DATA{$k};
          $self->{'STATUS'} = $DATA{$k};
        }
        elsif ($k eq 'TP_ID') {
          $self->{CHG_TP} = $OLD_DATA->{$k} . '->' . $DATA{$k};
        }
        elsif ($k eq 'GID') {
          $self->{CHG_GID} = $OLD_DATA->{$k} . '->' . $DATA{$k};
        }
        elsif ($k eq 'CREDIT') {
          $self->{CHG_CREDIT} = $OLD_DATA->{$k} . '->' . $DATA{$k};
        }
        else {
          $CHANGES_LOG .= "$k $OLD_DATA->{$k}->$DATA{$k};";
        }
        $CHANGES_QUERY .= "$FIELDS->{$k}='" . ((defined($DATA{$k})) ? $DATA{$k} : '') . "',";
      }
    }
  }

  if ($CHANGES_QUERY eq '') {
    return $self->{result};
  }
  else {
    $self->{CHANGES_LOG} = $CHANGES_LOG;
  }

  chop($CHANGES_QUERY);

  my $extended = ($attr->{EXTENDED}) ? $attr->{EXTENDED} : '';

  $self->query2("UPDATE $TABLE SET $CHANGES_QUERY WHERE $FIELDS->{$CHANGE_PARAM}='$DATA{$CHANGE_PARAM}'$extended", 'do');
  $self->{AFFECTED} = sprintf("%d", (defined ($self->{AFFECTED}) ? $self->{AFFECTED} : 0));
  
  if ($self->{AFFECTED} == 0) {
    return $self; 
  }
  elsif ($self->{errno}) {
    return $self;
  }
  if ($attr->{EXT_CHANGE_INFO}) {
    $CHANGES_LOG = $attr->{EXT_CHANGE_INFO} . ' ' . $CHANGES_LOG;
  }
  else {
    $attr->{EXT_CHANGE_INFO} = '';
  }

  if (defined($DATA{UID}) && $DATA{UID} > 0 && defined($admin)) {
    if ($attr->{'ACTION_ID'}) {
      $admin->action_add($DATA{UID}, $attr->{EXT_CHANGE_INFO}, { TYPE => $attr->{'ACTION_ID'} });
      return $self->{result};
    }

    if ($self->{'DISABLE_ACTION'}) {
      $admin->action_add($DATA{UID}, "", { TYPE => 9, ACTION_COMMENTS => $DATA{ACTION_COMMENTS} });
    }

    if ($self->{'ENABLE'}) {
      $admin->action_add($DATA{UID}, "", { TYPE => 8 });
    }

    if ($CHANGES_LOG ne '' && ($CHANGES_LOG ne $attr->{EXT_CHANGE_INFO} . ' ')) {
      $admin->action_add($DATA{UID}, "$CHANGES_LOG", { TYPE => 2 });
    }

    if ($self->{'CHG_TP'}) {
      $admin->action_add($DATA{UID}, "$self->{'CHG_TP'}", { TYPE => 3 });
    }

    if ($self->{CHG_GID}) {
      $admin->action_add($DATA{UID}, "$self->{CHG_GID}", { TYPE => 26 });
    }

    if ($self->{CHG_STATUS}) {
      $admin->action_add($DATA{UID}, "$self->{'STATUS'}" . (($attr->{EXT_CHANGE_INFO}) ? ' ' . $attr->{EXT_CHANGE_INFO} : ''), { TYPE => ($self->{'STATUS'} == 3) ? 14 : 4 });
    }

    if ($self->{CHG_CREDIT}) {
      $admin->action_add($DATA{UID}, "$self->{'CHG_CREDIT'}", { TYPE => 5 });
    }
  }
  elsif (defined($admin)) {
    if ($self->{'DISABLE'}) {
      $admin->system_action_add("$CHANGES_LOG", { TYPE => 9 });
    }
    elsif ($self->{'ENABLE'}) {
      $admin->system_action_add("$CHANGES_LOG", { TYPE => 8 });
    }
    else {
      $admin->system_action_add("$CHANGES_LOG", { TYPE => 2 });
    }
  }

  return $self->{result};
}

#**********************************************************
#
#**********************************************************
sub attachment_add () {
  my $self = shift;
  my ($attr) = @_;

  $self->query2("INSERT INTO $attr->{TABLE}
        (filename, content_type, content_size, content, create_time) 
        VALUES ('$attr->{FILENAME}', '$attr->{CONTENT_TYPE}', '$attr->{FILESIZE}', ?, now())",
    'do', { Bind => [ $attr->{CONTENT} ] }
  );

  return $self;
}

#**********************************************************
#
#**********************************************************
sub search_expr_users () {
  my $self = shift;
  my ($attr) = @_;
  my @fields = ();

  if (! $attr->{SUPPLEMENT}) {
    $self->{SEARCH_FIELDS}         = '';
    $self->{SEARCH_FIELDS_COUNT}   = 0;
    $self->{EXT_TABLES}            = '';
    @{ $self->{SEARCH_FIELDS_ARR} } = ();
  }

  #ID:type:Field name
  my %users_fields_hash = (
    LOGIN         => 'STR:u.id',
    UID           => 'INT:u.uid',
    DEPOSIT       => 'INT:if(company.id IS NULL, b.deposit, cb.deposit) AS deposit',
    DOMAIN_ID     => 'INT:u.domain_id',
    COMPANY_ID    => 'INT:u.company_id',
    COMPANY_CREDIT=> 'INT:company.credit AS company_credit',
    LOGIN_STATUS  => 'INT:u.disable AS login_status',
    REGISTRATION  => 'DATE:u.registration',

    COMMENTS      => 'STR:pi.comments',
    FIO           => 'STR:pi.fio',
    PHONE         => 'STR:pi.phone',
    EMAIL         => 'STR:pi.email',

    PASPORT_DATE  => 'DATE:pi.pasport_date',
    PASPORT_NUM   => 'STR:pi.pasport_num', 
    PASPORT_GRANT => 'STR:pi.pasport_grant',
    CITY          => 'STR:pi.city', 
    ZIP           => 'STR:pi.zip',
    CONTRACT_ID   => 'STR:pi.contract_id',
    CONTRACT_SUFIX=> 'STR:pi.contract_sufix',
    CONTRACT_DATE => 'DATE:pi.contract_date',

    ACTIVATE      => 'DATE:u.activate',
    EXPIRE        => 'DATE:u.expire',
    
    CREDIT        => 'INT:u.credit',
    CREDIT_DATE   => 'DATE:u.credit_date', 
    REDUCTION     => 'INT:u.reduction',
    REDUCTION_DATE=> 'INT:u.reduction_date',
    COMMENTS      => 'STR:pi.comments',
    BILL_ID       => 'INT:if(company.id IS NULL,b.id,cb.id) AS bill_id',
    PASSWORD      => "STR:DECODE(u.password, '$CONF->{secretkey}') AS password",
    #ADDRESS_FLAT  => 'STR:pi.address_flat', 
  );

  if ($attr->{DEPOSIT} && $attr->{DEPOSIT} ne '_SHOW') {
    $users_fields_hash{DEPOSIT}='INT:b.deposit'
  }

  if ($attr->{CONTRACT_SUFIX}) {
    $attr->{CONTRACT_SUFIX} =~ s/\|//g;
  }

  my $info_field = $attr->{LOGIN} || 0;
  my %filled     = (); 

  foreach my $key ( @{ $attr->{EXT_FIELDS} }, keys %{ $attr } ) {
    if (defined($users_fields_hash{$key}) && defined($attr->{$key})) {
      if (in_array($key.':skip', $attr->{EXT_FIELDS}) || $filled{$key}) {
        next;
      }
      elsif ($attr->{SKIP_USERS_FIELDS} && in_array($key, $attr->{SKIP_USERS_FIELDS})) {
        next;
      }

      my ($type, $field) = split(/:/, $users_fields_hash{$key});
      if ($type eq 'STR' && ! $attr->{$key}) {
      	next; 
      }
#      elsif ($type eq 'STR' && $attr->{$key} eq '') {
#      	next;
#      }

      push @fields, @{ $self->search_expr($attr->{$key}, $type, "$field", { EXT_FIELD => in_array($key, $attr->{EXT_FIELDS}) }) };
      $filled{$key}=1;
    }
    elsif (! $info_field && $key =~ /^_/) {
      $info_field=1;
    }
  }

  #Info fields
  if ($info_field && defined $self->can('config_list') ) {
    my $list = $self->config_list({ PARAM => 'ifu*', SORT => 2 });
    if ($self->{TOTAL} > 0) {
      foreach my $line (@$list) {
        if ($line->[0] =~ /ifu(\S+)/) {
          my $field_name = $1;
          my ($position, $type, $name) = split(/:/, $line->[1]);

          if (defined($attr->{$field_name}) && $type == 4) {
            push @fields, 'pi.' . $field_name . "='$attr->{$field_name}'";
          }
          #Skip for bloab
          elsif ($type == 5) {
            next;
          }
          elsif ($attr->{$field_name}) {
            if ($type == 1) {
              push @fields, @{ $self->search_expr("$attr->{$field_name}", 'INT', "pi.$field_name", { EXT_FIELD => 1 }) };
            }
            elsif ($type == 2) {
              push @fields, @{ $self->search_expr("$attr->{$field_name}", 'INT', "pi.$field_name", { EXT_FIELD => $field_name . '_list.name AS '. $field_name }) };
              $self->{EXT_TABLES} .= "LEFT JOIN $field_name" . "_list ON (pi.$field_name = $field_name" . "_list.id)";
            }
            else {
              push @fields, @{ $self->search_expr("$attr->{$field_name}", 'STR', "pi.$field_name", { EXT_FIELD => 1 }) };
            }
          }
        }
      }
      $self->{EXTRA_FIELDS} = $list;
    }
  }

  if ($attr->{SKIP_GID}) {
    push @fields,  @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid', { EXT_FIELD => in_array('GID', $attr->{EXT_FIELDS}) }) };
  }
  elsif ($attr->{GIDS}) {
    if ($admin->{GIDS}) {
      my @result_gids = ();  
      my @admin_gids  = split(/, /, $admin->{GIDS});
      my @attr_gids   = split(/, /, $attr->{GIDS});

      foreach my $attr_gid ( @attr_gids ) {
        foreach my $admin_gid (@admin_gids)  {
          if ($admin_gid == $attr_gid) {
            push @result_gids, $attr_gid; 
            last;
          }
        }
      }

      $attr->{GIDS}=join(', ', @result_gids);
    }
    
    push @fields, "u.gid IN ($attr->{GIDS})";
  }
  elsif (defined($attr->{GID}) && $attr->{GID} ne '') {
    push @fields,  @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid', { EXT_FIELD => in_array('GID', $attr->{EXT_FIELDS}) }) };
  }
  elsif ($admin->{GIDS}) {
    push @fields, "u.gid IN ($admin->{GIDS})";
  }

  if ($attr->{GROUP_NAME}) {
    push @fields, @{ $self->search_expr("$attr->{GROUP_NAME}", 'STR', 'g.name', { EXT_FIELD => 'g.name AS group_name' }) };
    $self->{EXT_TABLES} .= " LEFT JOIN groups g ON (g.gid=u.gid)";
    if (defined($attr->{DISABLE_PAYSYS})) {
      push @fields, @{ $self->search_expr("$attr->{DISABLE_PAYSYS}", 'INT', 'g.disable_paysys', { EXT_FIELD => 1 }) };
    }
  }

  if (! $attr->{DOMAIN_ID} && $admin->{DOMAIN_ID}) {
    push @fields, @{ $self->search_expr("$admin->{DOMAIN_ID}", 'INT', 'u.domain_id') };
  }

  if ($attr->{NOT_FILLED}) {
    push @fields, "builds.id IS NULL";
    $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)";
  }
  elsif ($attr->{LOCATION_ID}) {
    push @fields, @{ $self->search_expr($attr->{LOCATION_ID}, 'INT', 'pi.location_id', { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build, pi.address_flat, builds.id AS build_id' }) };
    $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
   LEFT JOIN streets ON (streets.id=builds.street_id)";
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  else {
    if ($attr->{STREET_ID}) {
      push @fields, @{ $self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id', { EXT_FIELD => 'streets.name AS address_street, builds.number AS address_build' }) };
      $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
     LEFT JOIN streets ON (streets.id=builds.street_id)";
      $self->{SEARCH_FIELDS_COUNT} += 1;
    }
    elsif ($attr->{DISTRICT_ID}) {
      push @fields, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' }) };
      $self->{EXT_TABLES} .= " LEFT JOIN builds ON (builds.id=pi.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
    elsif ($CONF->{ADDRESS_REGISTER}) {
      if ($attr->{ADDRESS_STREET}) {
        push @fields, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'streets.name AS address_street', { EXT_FIELD => 1 }) };
        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
        LEFT JOIN streets ON (streets.id=builds.street_id)";
      }
      elsif ($attr->{ADDRESS_FULL}) {
        $attr->{BUILD_DELIMITER}=',' if (! $attr->{BUILD_DELIMITER});
         push @fields, @{ $self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(streets.name, ' ', builds.number, '$attr->{BUILD_DELIMITER}', pi.address_flat) AS address_full", { EXT_FIELD => 1 }) };

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
          LEFT JOIN streets ON (streets.id=builds.street_id)";
      }
      elsif ($attr->{SHOW_ADDRESS}) {
        push @{ $self->{SEARCH_FIELDS_ARR} }, 'streets.name AS address_street', 'builds.number AS address_build', 'pi.address_flat', 'streets.id AS street_id';

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
        LEFT JOIN streets ON (streets.id=builds.street_id)";
      }

      if ($attr->{ADDRESS_BUILD}) {
        push @fields, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'builds.number', { EXT_FIELD => 'builds.number AS address_build' }) };

        $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)" if ($self->{EXT_TABLES} !~ /builds/);
      }

    }
    else {
      if($attr->{SHOW_ADDRESS}) {
        push @{ $self->{SEARCH_FIELDS_ARR} }, 'pi.address_street', 'pi.address_build', 'pi.address_flat';
      }
      elsif ($attr->{ADDRESS_FULL}) {
         $attr->{BUILD_DELIMITER}=',' if (! $attr->{BUILD_DELIMITER});
         push @fields, @{ $self->search_expr("$attr->{ADDRESS_FULL}", "STR", "CONCAT(pi.address_street, ' ', pi.address_build, '$attr->{BUILD_DELIMITER}', pi.address_flat) AS address_full", { EXT_FIELD => 1 }) };
      }

      if ($attr->{ADDRESS_STREET}) {
        push @fields, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'pi.address_street', { EXT_FIELD => 1 }) };
      }

      if ($attr->{ADDRESS_BUILD}) {
        push @fields, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'pi.address_build', { EXT_FIELD => 1 }) };
      }

      if ($attr->{COUNTRY_ID}) {
        push @fields, @{ $self->search_expr($attr->{COUNTRY_ID}, 'STR', 'pi.country_id', { EXT_FIELD => 1 }) };
      }
    }
  }

  if ($attr->{ADDRESS_FLAT}) {
    push @fields, @{ $self->search_expr($attr->{ADDRESS_FLAT}, 'STR', 'pi.address_flat', { EXT_FIELD => 1 }) };
  }

  if ($attr->{ACTION_TYPE}) {
    push @fields, @{ $self->search_expr($attr->{ACTION_TYPE}, 'INT', 'aa.action_type AS action_type', { EXT_FIELD => 1 }) };
    $self->{EXT_TABLES} .= "LEFT JOIN admin_actions aa ON (u.uid=aa.uid)" if ($self->{EXT_TABLES} !~ /admin_actions/);
  }

  if ($attr->{ACTION_DATE}) {
    my $field_name = 'aa.datetime';
    if($attr->{ACTION_DATE}=~/\d{4}\-\d{2}\-\d{2}/) {
      $field_name = 'DATE_FORMAT(aa.datetime, \'%Y-%m-%d\')';
    }

    push @fields, @{ $self->search_expr($attr->{ACTION_DATE}, 'DATE', "$field_name AS action_datetime", { EXT_FIELD => 1 }) };
    $self->{EXT_TABLES} .= "LEFT JOIN admin_actions aa ON (u.uid=aa.uid)" if ($self->{EXT_TABLES} !~ /admin_actions/);
  }

  if ($attr->{DEPOSIT} || ($attr->{BILL_ID} && ! in_array('BILL_ID', $attr->{SKIP_USERS_FIELDS}))) {
    $self->{EXT_TABLES} .= " LEFT JOIN bills b ON (u.bill_id = b.id)
      LEFT JOIN companies company ON  (u.company_id=company.id) 
      LEFT JOIN bills cb ON (company.bill_id=cb.id) ";
  }

  if ( (!$admin->{permissions}->{0}->{8})
    || ($attr->{USER_STATUS} && !$attr->{DELETED})) {
    push @WHERE_RULES, @{ $self->search_expr(0, 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }
  elsif (defined($attr->{DELETED})) {
    push @WHERE_RULES, @{ $self->search_expr("$attr->{DELETED}", 'INT', 'u.deleted', { EXT_FIELD => 1 }) };
  }

  $self->{SEARCH_FIELDS}         = join(', ', @{ $self->{SEARCH_FIELDS_ARR} }).',' if (@{ $self->{SEARCH_FIELDS_ARR} });
  $self->{SEARCH_FIELDS_COUNT}   = $#{ $self->{SEARCH_FIELDS_ARR} } + 1;

  if ($attr->{SORT}) {
  	my $sort_position = ($attr->{SORT}-2 < 1) ? 1 : $attr->{SORT}-2;
    if ($self->{SEARCH_FIELDS_ARR}->[$sort_position]){
      if ( $self->{SEARCH_FIELDS_ARR}->[$sort_position] =~ m/build$|flat$/i) {
        if ($self->{SEARCH_FIELDS_ARR}->[$sort_position] =~ m/([a-z\._0-9\(\)]+)\s+/i) {
      	  $self->{SEARCH_FIELDS_ARR}->[$sort_position]=$1;
        }
    	  $SORT = $self->{SEARCH_FIELDS_ARR}->[$sort_position] ."*1";
      }
      elsif ($self->{SEARCH_FIELDS_ARR}->[$sort_position] =~ m/ [a-z0-9\.]{0,12}ip/i) {
      	$SORT = 'ip+0';
      }
    }
  }

  delete ($self->{COL_NAMES_ARR});
  return \@fields;
}

#**********************************************************
#
#**********************************************************
sub query_add {
  my $self = shift;
  my ($table, $values, $attr)=@_;
  
  my $db=$self->{db};

  my $q = $db->column_info(undef, undef, $table, '%');
  $q->execute();
  my @inserts_arr = ();
  
  while (defined(my $row = $q->fetchrow_hashref())) {
    my $column = uc($row->{COLUMN_NAME});
    if ($values->{$column}) {
      if ($column eq 'IP' || $column eq 'NETMASK') {
        push @inserts_arr, "$row->{COLUMN_NAME}=INET_ATON('$values->{$column}')";
      }
      elsif ($column eq 'IPV6_PREFIX') {
        push @inserts_arr, "$row->{COLUMN_NAME}=INET6_ATON('$values->{$column}')";
      }
      else {
        if ($values->{$column} =~ /[a-z]+\(\)$/) {
          push @inserts_arr, "$row->{COLUMN_NAME}=$values->{$column}";
        }
        else {
          push @inserts_arr, "$row->{COLUMN_NAME}='$values->{$column}'";
        }
      }
    }
  }
  
  my $sql = (($attr->{REPLACE}) ? 'REPLACE' : 'INSERT') . " INTO $table SET ". join(",\n ", @inserts_arr);
  return $self->query2($sql, 'do');
}

1
