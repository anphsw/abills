package main;
use strict;

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

#**********************************************************
# Connect to DB
#**********************************************************
sub connect {
  my $class = shift;
  my $self  = {};
  my ($dbhost, $dbname, $dbuser, $dbpasswd, $attr) = @_;

  bless($self, $class);
  $self->{db} = DBI->connect_cached("DBI:mysql:database=$dbname;host=$dbhost", "$dbuser", "$dbpasswd") or print "Content-Type: text/html\n\nError: Unable connect to DB server '$dbhost:$dbname'\n";

  if (!$self->{db}) {
    my $a = `echo "/ $DBI::errstr/" >> /tmp/connect_error `;
  }

  #For mysql 5 or highter
  $self->{db}->do("set names " . $attr->{CHARSET}) if ($attr->{CHARSET});

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
sub query {
  my $self = shift;
  my ($db, $query, $type, $attr) = @_;

  $self->{errstr} = undef;
  $self->{errno}  = undef;
  $self->{TOTAL}  = 0;
  print "<p><code>\n$query\n</code></p>\n" if ($self->{debug});

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
          $self->{errno} = 3;
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
      log_print(undef, 'LOG_ERR', '', "\n$query\n --$self->{sql_errno}\n --$self->{sql_errstr}\n", { NAS => 0, LOG_FILE => "/tmp/sql_errors" });
    }
    return $self;
  }

  if ($self->{TOTAL} > 0) {
    my @rows;
    if ($attr->{COLS_NAME}) {
     	push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };        	
      while (my $row = $q->fetchrow_hashref()) {
      	if ($attr->{COLS_UPPER}) {
      		while(my($k,$v)=each %$row) {
      			$row->{uc($k)}=$v;
      		}
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
sub search_expr {
  my $self = shift;
  my ($value, $type, $field, $attr) = @_;

  if ($attr->{EXT_FIELD}) {
    $self->{SEARCH_FIELDS} .= ($attr->{EXT_FIELD} ne '1') ? "$attr->{EXT_FIELD}, " : "$field, ";
    $self->{SEARCH_FIELDS_COUNT}++;
  }

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

  my @result_arr = ();

  foreach my $v (@val_arr) {
    my $expr = '=';

    if ($type eq 'DATE') {
    	if ($v =~ /([=><!]{0,2})(\d{2})[\/\.\-](\d{2})[\/\.\-](\d{4})/) {
        $v = "$1$4-$3-$2";
      }
      elsif($v =~ /(\d{4}-\d{2}-\d{2})\/(\d{4}-\d{2}-\d{2})/) {
        my $from_date = $1;
        my $to_date   = $2;
        if ($field) {
          push @result_arr, "($field>=$from_date AND $field<=$to_date)" ;
        }
        next;
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
          if ($p[$i] eq '*') {
            $first_ip .= '0';
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
      return [ '(' . join(" $delimiter ", @result_arr) . ')' ];
    }
    return \@result_arr;
  }

  return $value;
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
          $OLD_DATA->{ uc($k) }=$v;
          $FIELDS->{ uc($k) }=$k;
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

  $self->query($db, "UPDATE $TABLE SET $CHANGES_QUERY WHERE $FIELDS->{$CHANGE_PARAM}='$DATA{$CHANGE_PARAM}'$extended", 'do');

  if ($self->{errno}) {
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

  $self->query($db, "INSERT INTO $attr->{TABLE}
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

  $self->{SEARCH_FIELDS}       = '';
  $self->{SEARCH_FIELDS_COUNT} = 0;
  $self->{EXT_TABLES}          = '';

  #ID:type:Field name
  my %users_fields_hash = (
    LOGIN        => 'STR:u.id',
    UID          => 'INT:u.uid',
    DEPOSIT      => 'INT:b.deposit',
    COMPANY_ID   => 'INT:u.company_id',
    REGISTRATION => 'DATE:u.registration',

    COMMENTS     => 'STR:pi.comments',
    FIO          => 'STR:pi.fio',
    PHONE        => 'STR:pi.phone',
    EMAIL        => 'STR:pi.email',


    PASPORT_DATE  => 'DATE:pi.pasport_date',
    PASPORT_NUM   => 'STR:pi.pasport_num', 
    PASPORT_GRANT => 'STR:pi.pasport_grant',
    CITY          => 'STR:pi.city', 
    ZIP           => 'STR:pi.zip',
    CONTRACT_ID   => 'STR:pi.contract_id',
    CONTRACT_SUFIX=> 'STR:pi.contract_sufix',
    CONTRACT_DATE => 'DATE:pi.contract_date',
    LOGIN_STATUS  => 'INT:u.disable',

    ACTIVATE      => 'DATE:u.activate',
    EXPIRE        => 'DATE:u.expire',
    
    DEPOSIT       => 'INT:b.deposit',
    CREDIT        => 'INT:u.credit',
    CREDIT_DATE   => 'DATE:u.credit_date', 
    REDUCTION     => 'INT:u.reduction',
    REDUCTION_DATE=> 'INT:u.reduction_date',
    COMMENTS      => 'STR:pi.comments',
    BILL_ID       => 'INT:if(company.id IS NULL,b.id,cb.id) AS bill_id',

    #ADDRESS_FLAT  => 'STR:pi.address_flat', 
  );



  if ($attr->{CONTRACT_SUFIX}) {
    $attr->{CONTRACT_SUFIX} =~ s/\|//g;
  }

  my %ext_fields = ();
  foreach my $id (@{ $attr->{EXT_FIELDS} }) {
    $ext_fields{$id}=1;
  }

  my $info_field = 0;
  foreach my $key (keys %{ $attr }) {
  	if ($users_fields_hash{$key}) {
  		next if ($ext_fields{$key.':skip'});
  		my ($type, $field) = split(/:/, $users_fields_hash{$key});
  		next if ($type eq 'STR' && ! $attr->{$key});
  		push @fields, @{ $self->search_expr($attr->{$key}, $type, "$field", { EXT_FIELD => $ext_fields{$key} }) };
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
              my $value = $self->search_expr("$attr->{$field_name}", 'INT');
              push @fields, "(pi." . $field_name . "$value)";
            }
            elsif ($type == 2) {
              push @fields, "(pi.$field_name='$attr->{$field_name}')";
              $self->{SEARCH_FIELDS} .= "$field_name" . '_list.name AS '. $field_name. '_list_name, ';
              $self->{SEARCH_FIELDS_COUNT}++;

              $self->{EXT_TABLES} .= "LEFT JOIN $field_name" . "_list ON (pi.$field_name = $field_name" . "_list.id)";
              next;
            }
            else {
              $attr->{$field_name} =~ s/\*/\%/ig;
              push @fields, "pi.$field_name LIKE '$attr->{$field_name}'";
            }
            $self->{SEARCH_FIELDS} .= "pi.$field_name, ";
            $self->{SEARCH_FIELDS_COUNT}++;
          }
        }
      }
      $self->{EXTRA_FIELDS} = $list;
    }
  }

  if ($attr->{GIDS}) {
    push @fields, "u.gid IN ($attr->{GIDS})";
  }
  elsif (defined($attr->{GID}) && $attr->{GID} ne '') {
    push @fields,  @{ $self->search_expr($attr->{GID}, 'INT', 'u.gid', { EXT_FIELD => $ext_fields{GID} }) };
  }

  if ($attr->{NOT_FILLED}) {
    push @fields, "builds.id IS NULL";
    $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)";
  }
  elsif ($attr->{LOCATION_ID}) {
    push @fields, @{ $self->search_expr($attr->{LOCATION_ID}, 'INT', 'pi.location_id', { EXT_FIELD => 'streets.name AS street_name, builds.number AS build_number, pi.address_flat, builds.id AS build_id' }) };
    $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
   LEFT JOIN streets ON (streets.id=builds.street_id)";
    $self->{SEARCH_FIELDS_COUNT} += 3;
  }
  else {
    if ($attr->{STREET_ID}) {
      push @fields, @{ $self->search_expr($attr->{STREET_ID}, 'INT', 'builds.street_id', { EXT_FIELD => 'streets.name AS street_name, builds.number AS build_number' }) };
      $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
     LEFT JOIN streets ON (streets.id=builds.street_id)";
      $self->{SEARCH_FIELDS_COUNT} += 1;
    }
    elsif ($attr->{DISTRICT_ID}) {
      push @fields, @{ $self->search_expr($attr->{DISTRICT_ID}, 'INT', 'streets.district_id', { EXT_FIELD => 'districts.name AS district_name' }) };
      $self->{EXT_TABLES} .= "LEFT JOIN builds ON (builds.id=pi.location_id)
      LEFT JOIN streets ON (streets.id=builds.street_id)
      LEFT JOIN districts ON (districts.id=streets.district_id) ";
    }
    elsif ($CONF->{ADDRESS_REGISTER}) {
      if ($attr->{ADDRESS_STREET}) {
        push @fields, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'streets.name AS street_name', { EXT_FIELD => 1 }) };
        $self->{EXT_TABLES} .= "INNER JOIN builds ON (builds.id=pi.location_id)
        INNER JOIN streets ON (streets.id=builds.street_id)";
      }
    }
    elsif ($attr->{ADDRESS_STREET}) {
      push @fields, @{ $self->search_expr($attr->{ADDRESS_STREET}, 'STR', 'pi.address_street', { EXT_FIELD => 1 }) };
    }

    if ($CONF->{ADDRESS_REGISTER}) {
      if ($attr->{ADDRESS_BUILD}) {
        push @fields, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'builds.number', { EXT_FIELD => 'builds.number' }) };
        $self->{EXT_TABLES} .= "INNER JOIN builds ON (builds.id=pi.location_id)" if ($self->{EXT_TABLES} !~ /builds/);
      }
    }
    elsif ($attr->{ADDRESS_BUILD}) {
      push @fields, @{ $self->search_expr($attr->{ADDRESS_BUILD}, 'STR', 'pi.address_build', { EXT_FIELD => 1 }) };
    }

    if ($attr->{COUNTRY_ID}) {
      push @fields, @{ $self->search_expr($attr->{COUNTRY_ID}, 'STR', 'pi.country_id', { EXT_FIELD => 1 }) };
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


  return \@fields;
}

#**********************************************************
#
#**********************************************************
sub query_add {
	my $self = shift;
	my ($db, $table, $values, $attr)=@_;
	
  my $q = $db->column_info(undef, undef, $table, '%');
  $q->execute();
  my @inserts_arr = ();
  
  while (defined(my $row = $q->fetchrow_hashref())) {
    my $column = uc($row->{COLUMN_NAME});
    if ($values->{$column}) {
    	push @inserts_arr, "$column='$values->{$column}'";
     }
  }
	
	my $sql = "INSERT INTO $table SET ". join(",\n ", @inserts_arr);

	return $self->query($db, $sql, 'do');
}

1
