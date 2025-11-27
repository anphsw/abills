package Sqlcmd;

=head1 NAME

  SQL commander

=cut

use strict;
use parent qw(dbcore);

#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $MODULE = 'Sqlcmd';

  $admin->{MODULE} = $MODULE;
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 info($attr)

=cut
#**********************************************************
sub info {
  my ($self, $attr) = @_;

  my DBI $db = $self->{db}->{db};

  my $list;
  my $DATE = $attr->{DATE} || '0000-00-00';

  my $type = $attr->{TYPE} || '';
  my %table_ext_info = ();

  if ($type eq 'showtables') {
    if ($attr->{ACTION}) {
      if ($attr->{ACTION} eq 'ROTATE') {
        $DATE =~ s/\-/\_/xg;

        # CREATE TABLE LIKE work from version 4.1
        my $version = $self->db_version();
        if ($version < 4.1) {
          $self->{errno}  = 1;
          $self->{errstr} = "MYSQL: $version. Version Lower 4.1 not support RENAME Syntax";
          return $self;
        }

        my @tables_arr = split(/,\s/x, $attr->{TABLES});
        foreach my $table (@tables_arr) {
          print "CREATE TABLE IF NOT EXISTS " . $table . "_2 LIKE $table ;" . "RENAME TABLE $table TO $table" . "_$DATE, $table" . "_2 TO $table;";
          my $sth = $db->do("CREATE TABLE IF NOT EXISTS " . $table . "_2 LIKE $table ;");
          $sth = $db->do("RENAME TABLE $table TO $table" . "_$DATE, $table" . "_2 TO $table;");
        }
      }
      elsif($attr->{ACTION} eq 'OPTIMIZE') {
        my @tables_arr = split(/,\s+/x, $attr->{TABLES});
        foreach my $table (@tables_arr) {
          if ($table !~ /\d{4}\_\d{2}\_\d{2}$/xm) {
            my $sql = "OPTIMIZE TABLE $table;";
            print $sql;
            $db->do($sql);
          }
        }
      }
      elsif($attr->{ACTION} eq 'DEL_BACKUP') {
        my @tables_arr = split(/,\s/x, $attr->{TABLES});
        foreach my $table (@tables_arr) {
          if ($table =~ /\_\d{2,4}\_\d{2}$/xm) {
            my $sql = "DROP TABLE $table;";
            print $sql;
            $db->do($sql);
          }
        }
      }
      elsif($attr->{ACTION} eq 'SEARCH') {
        $self->table_full_search({ %$attr, TABLE_EXT_INFO => \%table_ext_info });
      }
    }

    my $like = '';
    if ($attr->{TABLES} && $attr->{search} ) {
      $attr->{TABLES} =~ s/\*/\%/xg;
      $like =  "LIKE '$attr->{TABLES}'";
    }

    my $dbname = $self->{conf}->{dbname};
    my $sth = $db->prepare("SHOW TABLE STATUS FROM $dbname $like");
    $sth->execute();
    my $pri_keys = $sth->{mysql_is_pri_key};
    my $names    = $sth->{NAME};

    push @$names, 'CHECK';

    $self->{FIELD_NAMES} = $names;

    my @rows = ();

    while (my @row_array = $sth->fetchrow()) {
      my $i         = 0;
      my %Rows_hash = ();

      foreach my $line (@row_array) {
        $Rows_hash{$names->[$i]} = $line;
        $i++;
      }

      # check syntax
      if ($attr->{'fields'} =~ /CHECK/xm) {
        my $q = $db->prepare("CHECK TABLE $row_array[0]");
        $q->execute();
        my @res = $q->fetchrow();
        $Rows_hash{$names->[$i]} = "$res[2] / $res[3]";
      }

      if($table_ext_info{$row_array[0]}) {
        $Rows_hash{ext_info}=$table_ext_info{$row_array[0]};
      }

      push @rows, \%Rows_hash;
    }

    $list = \@rows;

    #show indexes
    return $list;
  }
  elsif ($type eq 'showtriggers') {
    $self->query("SHOW TRIGGERS");
    return $self->{list};
  }

  return $self->{list};
}



#**********************************************************
=head2 table_full_search()

  Arguments:
    $attr
      TABLE_EXT_INFO
  Results:
    $self

=cut
#**********************************************************
sub table_full_search {
  my ($self, $attr) = @_;

  my $table_ext_info = $attr->{TABLE_EXT_INFO};
  my $db = $self->{db}->{db};

  my @tables_arr = split(/,\s+/x, $attr->{TABLES});
  foreach my $table (@tables_arr) {
    my $sth = $db->prepare("SHOW COLUMNS FROM $table;");
    $sth->execute();
    my @search_params = ();

    while (my @row_array = $sth->fetchrow()) {
      my $search_text = $row_array[0];
      if($row_array[1] =~ /varchar|text/xm) {
        $search_text .= " LIKE '%$attr->{VALUE}%' ";
      }
      else {
        if($row_array[1] =~ /int|doub|floa/xmi && $attr->{VALUE} !~ /^[0-9\,\.]+$/xm) {
          next;
        }
        elsif($row_array[1] =~ /date/xmi && $attr->{VALUE} !~ /^[0-9\-]+$/mx) {
          next;
        }
        else {
          $search_text .= "='$attr->{VALUE}'";
        }
      }

      push @search_params, $search_text;
    }

    if ($#search_params > -1) {
      my $sql = "SELECT COUNT(*) FROM $table WHERE ". join(' or ', @search_params);

      if($self->{debug}) {
        print $sql.'<br>';
      }

      $sth = $db->prepare($sql);
      $sth->execute();
      my @row_array =$sth->fetchrow();

      if($row_array[0]>0) {
        $table_ext_info->{$table}=$row_array[0];
      }
    }
  }

  return $self;
}

#**********************************************************
# maintenance()
#**********************************************************
sub maintenance {

}

#**********************************************************
=head2 list()

  Arguments:
    $attr
      QUERY

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  my DBI $db = $self->{db}->{db};

  my @QUERY_ARRAY = ();
  if ($attr->{QUERY} =~ /;\r?\n/mx) {
    @QUERY_ARRAY = split(/;\r?\n/x, $attr->{QUERY});
  }
  else {
    push @QUERY_ARRAY, $attr->{QUERY};
  }

  my @rows = ();

  foreach my $query (@QUERY_ARRAY) {
    next if (length($query) < 5);
    my $q;
    $query =~ s/^\s+//xg;

    if ($query =~ /^CREATE\s+|^UPDATE\s+|^INSERT\s+|^ALTER\s+|^DROP/xi) {
      $db->{mysql_client_found_rows} = 1;

      if (my $count = $db->do($query)) {
        $self->{AFFECTED} = sprintf("%d", (defined ($count) ? $count : 0));
      }
      else {
        $self->{errno}      = 3;
        $self->{sql_errno}  = $db->err;
        $self->{sql_errstr} = $db->errstr;
      }
    }
    else {
      print $query if ($self->{debug});
      $q = $db->prepare($query, { "mysql_use_result" => ($query !~ /!SELECT/gxi) ? 0 : 1 }) || print $db->errstr;

      if ($db->err) {
        $self->{errno}      = 3;
        $self->{sql_errno}  = $db->err;
        $self->{sql_errstr} = $db->errstr;
        $self->{errstr}     = $db->errstr;
        return $self->{errno};
      }

      $self->{AFFECTED} = $q->execute();

      if ($db->err) {
        $self->{errno}      = 3;
        $self->{sql_errno}  = $db->err;
        $self->{sql_errstr} = $db->errstr;
        $self->{errstr}     = "$query / " . $db->errstr;

        return $self;
      }

      $self->{MYSQL_FIELDS_NAMES}   = $q->{NAME};
      $self->{MYSQL_IS_PRIMARY_KEY} = $q->{mysql_is_pri_key};
      $self->{MYSQL_IS_NOT_NULL}    = $q->{mysql_is_not_null};
      $self->{MYSQL_LENGTH}         = $q->{mysql_length};
      $self->{MYSQL_MAX_LENGTH}     = $q->{mysql_max_length};
      $self->{MYSQL_IS_KEY}         = $q->{mysql_is_key};
      $self->{MYSQL_TYPE_NAME}      = $q->{mysql_type_name};

      $self->{TOTAL} = $q->rows;

      my $write_sql_regex = qr{
    ^
    (?:
          INSERT
        | UPDATE
        | CREATE
        | DELETE
        | ALTER
        | DROP
    )
    \s*
}xim;

      if ($query !~ $write_sql_regex) {
        if ($attr->{COLS_NAME}) {
          while (my $row = $q->fetchrow_hashref()) {
            push @rows, $row;
          }
        }
        else {
          while (my @row = $q->fetchrow()) {
            push @rows, \@row;
          }
        }
      }
    }
    return [] if ($self->{errno});

    push @{ $self->{EXECUTED_QUERY} }, $query;
  }

  $attr->{QUERY} =~ s/\'/\\\'/xg;
  $self->{admin}->system_action_add("SQLCMD:$attr->{QUERY}", { TYPE => 1 });

  my $list = \@rows;
  return $list || [];
}

#**********************************************************
=head2 sqlcmd_info()

=cut
#**********************************************************
sub sqlcmd_info {
  my $self = shift;

  my @row;
  my %stats = ();
  my %vars  = ();
  my %memory  = ();
  my DBI $db_ = $self->{db}->{db};

  # Determine MySQL version
  my $query = $db_->prepare("SHOW VARIABLES LIKE 'version';");
  $query->execute();
  @row = $query->fetchrow_array();

  my ($major, $minor, $patch) = ($row[1] =~ /(\d{1,2})\.(\d{1,2})\.(\d{1,2})/xm);

  if ($major == 5 && (($minor == 0 && $patch >= 2) || $minor > 0)) {
    $query = $db_->prepare("SHOW GLOBAL STATUS;");
  }
  else {
    $query = $db_->prepare("SHOW STATUS;");
  }

  # Get status values
  $query->execute();
  while (@row = $query->fetchrow_array()) {
    $stats{ $row[0] } = $row[1];
  }

  # Get server system variables
  $query = $db_->prepare("SHOW VARIABLES;");
  $query->execute();
  while (@row = $query->fetchrow_array()) {
    $vars{ $row[0] } = $row[1];
  }

  my $sql = <<'SQL';
select SUBSTRING_INDEX(
         SUBSTRING_INDEX(event_name, '/', 2),
         '/',
         -1
       )                                                                    AS event_type,
       CONCAT(ROUND(SUM(CURRENT_NUMBER_OF_BYTES_USED)/1024/1024, 2), ' Mb') as MB_CURRENTLY_USED
FROM performance_schema.memory_summary_global_by_event_name
GROUP BY event_type
SQL


  #Get server memory usage
  $query = $db_->prepare($sql);

  if ($query) {
    $query->execute();
    while (@row = $query->fetchrow_array()) {
      $memory{ $row[0] } = $row[1];
    }
  }

  return \%stats, \%vars, \%memory;
}

#**********************************************************
=head2 history_add($attr)

=cut
#**********************************************************
sub history_add {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
INSERT INTO sqlcmd_history (datetime, aid, sql_query, db_id, comments, status)
VALUES (NOW(), ?, ?, ?, ?, ?);
SQL


  $self->query($sql,
  'do',
  { Bind => [
      $self->{admin}->{AID},
      $attr->{QUERY},
      $attr->{DB_ID} || 0,
      $attr->{COMMENTS} || q{},
      $attr->{STATUS} || 0
    ]
  }
  );

  return $self;
}

#**********************************************************
=head2 history_del($attr)

=cut
#**********************************************************
sub history_del {
  my ($self, $attr) = @_;

  $self->query_del('sqlcmd_history', $attr);

  return $self;
}

#**********************************************************
# list_allow nass
#**********************************************************
sub history_list {
  my ($self, $attr) = @_;

  my $PG        = ($attr->{PG})        ? $attr->{PG}        : 0;
  my $PAGE_ROWS = ($attr->{PAGE_ROWS}) ? $attr->{PAGE_ROWS} : 25;

  my $WHERE = $self->search_former( $attr, [
    [ 'AID',     'INT',  'sh.aid'    ],
    [ 'STATUS',  'INT',  'sh.status' ],
  ],
    {
      WHERE => 1
    }
  );

  my $sql = <<"SQL";
SELECT datetime, comments, id, sql_query, status
FROM sqlcmd_history sh
  $WHERE
ORDER BY 1 DESC
  LIMIT $PG, $PAGE_ROWS;
SQL

  $self->query($sql, undef, { COLS_NAME => 1 });

  my $list = $self->{list} || [];

  $sql = <<'SQL';
SELECT COUNT(*) AS total
FROM sqlcmd_history
WHERE aid= ?;
SQL


  if ($self->{TOTAL} > 0) {
    $self->query($sql,  undef,
    { INFO => 1,
      Bind      => [ $self->{admin}->{AID}  ]
    }
    );
  }

  return $list;
}

#**********************************************************
# list_allow nass
#**********************************************************
sub history_query {
  my ($self, $attr) = @_;

  my $sql = <<'SQL';
SELECT datetime,
       sql_query,
       comments,
       id
FROM sqlcmd_history
WHERE aid= ?
  AND id= ?;
SQL


  $self->query($sql, undef,
    { INFO => 1,
      Bind => [
        $self->{admin}->{AID},
        $attr->{QUERY_ID}
      ] }
  );

  return $self;
}

#**********************************************************
=head2 columns()

  Returns:
    $array - [[$table, $column], ...]
=cut
#**********************************************************
sub columns {
  my $self = shift;

  my $sql = <<'SQL';
SELECT
  table_name,
  column_name
FROM
  information_schema.columns
WHERE
  table_schema=?
ORDER BY table_name, ordinal_position;
SQL


  $self->query($sql, undef,
      {
        Bind => [
          $self->{conf}->{dbname}
        ]
      }
  );

  return $self->{list} || [];
}

1;
