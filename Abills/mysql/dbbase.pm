package dbbase;

=head1 NAME

Abills::mysql::dbcore - DB manipulation functions

=cut

use strict;
use warnings;
use DBI;

our $VERSION = 1.00;
my $sql_errors = '/usr/abills/var/log/sql_errors';

#**********************************************************
=head2 connect($dbhost, $dbname, $dbuser, $dbpasswd, $attr) - Connect to DB

  Arguments:
    $dbhost,
    $dbname,
    $dbuser,
    $dbpasswd,
    $attr
      CHARSET  - Default utf8
      SQL_MODE - Default NO_ENGINE_SUBSTITUTION
      SCOPE    - Allow to create multiple cached pools ( to use with threads)
      DBPARAMS=""

=cut
#**********************************************************
sub connect {
  my $class = shift;
  my $self = { };
  my ($dbhost, $dbname, $dbuser, $dbpasswd, $attr) = @_;

  bless( $self, $class );
  #my %conn_attrs = (PrintError => 0, RaiseError => 1, AutoCommit => 1);
  # TaintIn => 1, TaintOut => 1,
  my DBI $db;
  my $db_params = q{};

  if ($attr && $attr->{DBPARAMS}) {
    $db_params .=";".$attr->{DBPARAMS};
  }

  my $sql_mode = ($attr->{SQL_MODE}) ? $attr->{SQL_MODE} : 'NO_ENGINE_SUBSTITUTION';

  my $mysql_init_command = "SET sql_mode='$sql_mode'";
  #For mysql 5 or higher
  if ($attr->{CHARSET}) {
    $mysql_init_command .= ", NAMES $attr->{CHARSET}";
    $self->{dbcharset}=$attr->{CHARSET};
  }
  if ( $db = DBI->connect_cached( "DBI:mysql:database=$dbname;host=$dbhost;mysql_client_found_rows=0".$db_params, "$dbuser", "$dbpasswd",
    {
      Taint                => 1,
      private_scope_key    => $attr->{SCOPE} || 0,
      mysql_auto_reconnect => 1,
      mysql_init_command   => $mysql_init_command
    } )
  ) {
    $self->{db} = $db;
  }
  else {
    print "Content-Type: text/html\n\nError: Unable connect to DB server '$dbhost:$dbname'\n";
    $self->{error} = $DBI::errstr;

    require Log;
    Log->import( 'log_print' );
    $self->{sql_errno} = 0 if (!$self->{sql_errno});
    $self->{sql_errstr} = '' if (!$self->{sql_errstr});

    Log::log_print( undef, 'LOG_ERR', '', "Connection Error: $DBI::errstr", {
      NAS      => 0,
      LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors'
    });
  }


  return $self;
}

#**********************************************************
=head2 disconnect()

=cut
#**********************************************************
sub disconnect{
  my $self = shift;

  $self->{db}->disconnect;

  return $self;
}

#**********************************************************
=head2 query($query, $type, $attr) - Query maker

  Arguments:
    $query   - SQL query
    $type    - Type of query
      undef - with fetch result like SELECT
      do    - do query without fetch (INSERT, UPDATE, DELETE)

    $attr   - Extra attributes
      COLS_NAME   - Return Array of HASH_ref. Column name as hash key
      COLS_UPPER  - Make hash key upper
      INFO        - Return fields as objects parameters $self->{LOGIN}
      LIST2HASH   - Return 2 field hash
            KEY,VAL
      MULTI_QUERY - Make multiquery (only for INSERT, UPDATE)
      Bind        - Array or bind values for placeholders  [ 10, 12, 33 ]
      DB_REF      - DB object. Using whem manage multi DB server
      test        - Run function without excute query. if using $self->{debug} show query.

    $self->{debug} - Show query
    $self->{db}    - DB object

  Returns:
    $self->{list}          - array of array
                           - array of hash (COLS_UPPER)

    $self->{INSERT_ID}     - Insert id for autoincrement fields
    $self->{TOTAL}         - Total rows in result (for query SELECT)
    $self->{AFFECTED}      - Total added or changed fields
    $self->{COL_NAMES_ARR} - Array_hash of column names

    Error flags:
      $self->{errno}      = 3;
      $self->{sql_errno}  = $db->err;
      $self->{sql_errstr} = $db->errstr;
      $self->{errstr}

  Examples:

    Delete query

      $self->query("DELETE FROM users WHERE uid= ?;", 'do', { Bind => [ 100 ] });

      Result:

        $self->{AFFECTED}  - Total deleted rows


    Show listing:

      $self->query("SELECT id AS login, uid FROM users LIMIT 10;", undef, { COLS_NAME => 1 });

      Result:

        $self->{TOTAL}  - Total rows
        $self->{list}   - ARRAY of hash_refs

    Make info atributes

       $self->query("SELECT id AS login, gid, credit FROM users WHERE uid = ? ;", undef, { INFO => 1, Bind => [ 100 ] });

      Result:

        $self->{LOGIN}
        $self->{GID}
        $self->{CREDIT}

    LIST2HASH listing

      $self->query("SELECT id AS login, gid, credit FROM users WHERE uid = ? ;", undef, { LIST2HASH => 'login,gid' });

      $self->{list_hash} - Hash ref

=cut
#**********************************************************
sub query{
  my $self = shift;
  my ($query, $type, $attr) = @_;

  my DBI $db = $self->{db};

  if ( $self->{db}->{db} ){
    $db = $self->{db}->{db};

    $self->{db}->{queries_count}++;

    if ( $self->{db}->{db_debug} ){
      if ( $self->{db}->{db_debug} > 4 ){
        $db->trace( 1, '/tmp/sql_trace' );
      }
      elsif ( $self->{db}->{db_debug} > 3 ){
        $db->trace( 'SQL', '/tmp/sql_trace' );
      }
      elsif ( $self->{db}->{db_debug} > 2 ){
        require Log;
        Log->import( 'log_print' );
        my $arguments = '';
        if($attr->{Bind}) {
          $arguments .= join(', ', @{ $attr->{Bind} });
        }
        Log::log_print( undef, 'LOG_ERR', '', "\n-----". ($self->{queries_count} || q{}) ."------\n$query\n------\n$arguments\n",
          { NAS => 0, LOG_FILE => "/tmp/sql_debug" } );
      }
      #sequence
      elsif ( $self->{db}->{db_debug} > 1 ){
        # Usually, library is loaded by default, but since
        # this is a critical script, we will check it just in case.
        # Fact, that is only done during debugging is also not scary for performance.
        unless ($Time::HiRes::VERSION) {
          require Time::HiRes;
          Time::HiRes->import();
        }

        my $caller = qq{\n\n};
        my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
        my $i = 1;
        my @r = ();
        while (@r = caller($i)) {
          ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
          $caller .= "  $filename:$line $subroutine\n";
          $i++;
        }

        push @{ $self->{db}->{queries_list} }, [$query. $caller, 0, $caller];
      }
      else{
        #Queries typisation
        $self->{db}->{queries_list}->{$query}++;
      }
    }
  }

  if ( $attr->{DB_REF} ){
    $db = $attr->{DB_REF};
  }

  #Query
  delete( $self->{errstr} );
  delete( $self->{errno} );
  $self->{TOTAL} = 0;

  if ( $self->{debug} ){
    print "<pre><code>\n$query\n</code></pre>\n" if ($self->{debug});
    if ( $self->{debug} ne 1 ){
      $db->trace( 1, $self->{debug} );
    }
  }

  if ( !$db || ref $db eq 'HASH' ){
    require Log;
    Log->import( 'log_print' );
    $self->{sql_errno} = 0 if (!$self->{sql_errno});
    $self->{sql_errstr} = '' if (!$self->{sql_errstr});
    my $caller = join(', ', caller());
    Log::log_print( undef, 'LOG_ERR', '',
      "Query:\n$query\n Error:$self->{sql_errno}\n Error str:$self->{sql_errstr}\nundefined \$db\n$caller",
      { NAS => 0, LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors' } );
    return $self;
  }

  if ( defined( $attr->{test} ) ){
    return $self;
  }

  $self->{AFFECTED} = 0;
  my DBI $q;
  my $start_query_time = 0;
  if ($self->{db}->{db_debug} && $self->{db}->{db_debug} == 2) {
    $start_query_time = [ Time::HiRes::gettimeofday() ]
  }

  if ( $type && $type eq 'do' ){
    $self->{AFFECTED} = $db->do( $query, undef, @{ $attr->{Bind} } );
    if ( $db->{'mysql_insertid'} ){
      $self->{INSERT_ID} = $db->{'mysql_insertid'};
    }
  }
  else{
    $q = $db->prepare( $query );

    if ( $attr->{MULTI_QUERY} ){
      foreach my $line ( @{ $attr->{MULTI_QUERY} } ){
        $q->execute( @{$line} );
        if ( $db->err ){
          $self->{errno} = 3;
          $self->{sql_errno} = $db->err;
          $self->{sql_errstr} = $db->errstr;
          $self->{errstr} = $db->errstr;
          return $self->{errno};
        }
      }

      if ($self->{db}->{db_debug} && $self->{db}->{db_debug} == 2) {
        my $elapsed = Time::HiRes::tv_interval($start_query_time);
        ${ $self->{db}->{queries_list} }[-1]->[1] = $elapsed;
      };

      $self->{TOTAL} = $#{ $attr->{MULTI_QUERY}  } + 1;
      return $self;
    }
    else{
      $q->execute( @{ $attr->{Bind} } );
      $self->{TOTAL} = $q->rows;
    }
  }

  if ($self->{db}->{db_debug} && $self->{db}->{db_debug} == 2) {
    my $elapsed = Time::HiRes::tv_interval($start_query_time);
    ${ $self->{db}->{queries_list} }[-1]->[1] = $elapsed;
  }

  if ( $db->err ){
    if ( $db->err == 1062 ){
      $self->{errno} = 7;
      $self->{errstr} = 'ERROR_DUPLICATE';
    }
    else{
      $self->{sql_errno} = $db->err;
      $self->{sql_errstr} = $db->errstr;
      $self->{errno} = 3;
      $self->{errstr} = 'SQL_ERROR';
      $self->{sql_query} = $query;
      my $caller = q{}; #join(', ', caller());
      my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash);
      my $i = 1;
      my @r = ();
      while (@r = caller($i)) {
        ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask, $hinthash) = @r;
        $caller .= "$filename:$line $subroutine\n";
        $i++;
      }
      use Log qw(log_print);
      # require Log;
      # Log->import( 'log_print' );
      Log::log_print( undef, 'LOG_ERR', '',
        "index:". ($attr->{index} || q{}) ."\n"
          . ($query || q{}) ."\n --$self->{sql_errno}\n --$self->{sql_errstr}\n --AutoCommit: $db->{AutoCommit}\n$caller\n"
        , { NAS => 0, LOG_FILE => ( -w $sql_errors) ? $sql_errors : '/tmp/sql_errors' } );
    }
    return $self;
  }

  if ( $self->{TOTAL} > 0 ){
    my @rows = ();

    if ( $attr->{COLS_NAME} ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} || []};

      while (my $row = $q->fetchrow_hashref()) {
        if ( $attr->{COLS_UPPER} ){
          my $row2;
          while(my ($k, $v) = each %{$row}) {
            $row2->{uc( $k )} = $v;
          }
          $row = { %{$row2}, %{$row} };
        }
        push @rows, $row;
      }
    }
    elsif ( $attr->{INFO} ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };
      while (my $row = $q->fetchrow_hashref()) {
        while(my ($k, $v) = each %{$row} ) {
          $self->{ uc( $k ) } = $v;
        }
      }
    }
    elsif ( $attr->{LIST2HASH} ){
      my ($key, @val) = split( /,\s?/, $attr->{LIST2HASH} );
      my %list_hash = ();

      while (my $row = $q->fetchrow_hashref()) {
        my @vals = ();
        foreach my $v (@val) {
          push @vals, $row->{$v};
        }

        $list_hash{$row->{$key}} = join(', ', @vals);
      }

      $self->{list_hash} = \%list_hash;
    }
    else{
      while (my @row = $q->fetchrow()) {
        push @rows, \@row;
      }
    }
    $self->{list} = \@rows;
  }
  else{
    if ( $q && $q->{NAME} && ref $q->{NAME} eq 'ARRAY' ){
      push @{ $self->{COL_NAMES_ARR} }, @{ $q->{NAME} };
    }

    delete $self->{list};
    if ( $attr->{INFO} ){
      $self->{errno} = 2;
      $self->{errstr} = 'ERROR_NOT_EXIST';
    }
  }

  if ( $attr->{CLEAR_NAMES} ){
    delete $self->{COL_NAMES_ARR};
  }

  #end
  return $self;
}

1
