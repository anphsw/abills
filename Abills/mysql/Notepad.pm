package Notepad;

=head2 NAME

  Notepad

=cut

use strict;
use parent 'main';

my $debug = 0;

use constant {
  MONTH_DAY => 'MONTH_DAY',
  WEEK_DAY  => 'WEEK_DAY',
  MONTH     => 'MONTH',
  YEAR      => 'YEAR',
  HOUR      => 'HOUR',
  MINUTE    => 'MINUTE'
};

#**********************************************************
# Init Notepad module
#**********************************************************
sub new{
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = { };
  bless( $self, $class );

  $self->{db}    = $db;
  $self->{admin} = $admin;
  $self->{conf}  = $CONF;

  return $self;
}

#**********************************************************
=head2 notepad_list_notes() - Notepad list notes

=cut
#**********************************************************
sub notes_list{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'NOTE_STATUS', 'INT', 'n.status', ],
      [ 'STATUS', 'INT', 'n.status', ],
      [ 'AID', 'INT', 'n.aid', ],
      [ 'ID', 'INT', 'n.id', ],
      [ 'DATE', 'DATE', 'n.notified' ],
      [ 'MINUTE', 'INT', 'nr.minute', 1 ],
      [ 'HOUR', 'INT', 'nr.hour', 1 ],
      [ 'WEEK_DAY', 'INT', 'nr.week_day', 1 ],
      [ 'MONTH_DAY', 'STR', 'nr.month_day', 1 ],
      [ 'MONTH', 'INT', 'nr.month', 1 ],
      [ 'YEAR', 'INT', 'nr.year', 1 ],
    ],
    {
      WHERE => 1,
    }
  );

  $self->query2( "SELECT
                n.id,
                n.notified,
                n.create_date,
                n.status,
                n.subject,
                n.text,
                n.aid,
                adm.name,
                nr.id AS reminder_id,
                nr.minute,
                nr.hour,
                nr.week_day ,
                nr.month_day,
                nr.month,
                nr.year,
                nr.holidays
                FROM notepad AS n
                LEFT JOIN notepad_reminders nr ON ( n.id = nr.id )
              LEFT JOIN admins adm ON ( adm.aid = n.aid )
                $WHERE
                ORDER BY $SORT $DESC;",
    undef,
    $attr
  );

  return $self->{list};
}

#**********************************************************
=head2 notepad_note_info($attr) - Notepad note info

=cut
#**********************************************************
sub note_info{
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former( $attr, [
      [ 'NOTE_STATUS', 'INT', 'n.status', ],
      [ 'AID', 'INT', 'n.aid', ],
      [ 'ID', 'INT', 'n.id', ],
      [ 'DATE', 'DATE', 'n.notified' ]
    ],
    {
      WHERE => 1,
    }
  );

  $self->query2( "SELECT   n.id,
       DATE(n.notified) AS date,
       TIME(n.notified) AS notified,
       n.create_date,
       n.status,
       n.subject,
       n.text,
       n.aid,
       nr.*,
       adm.name
       FROM notepad AS n
       LEFT JOIN notepad_reminders nr ON ( n.id = nr.id )
       LEFT JOIN admins adm ON ( adm.aid = n.aid )
     $WHERE
     ORDER BY $SORT $DESC;",
    undef,
    { INFO => 1 }
  );

  return $self;
}

#**********************************************************
=head2 notepad_add_note($attr)  - Add note

=cut
#**********************************************************
sub note_add{
  my $self = shift;
  my ($attr) = @_;

  if ( $attr->{EXPLICIT_TIME} ){
    $self->query_add( 'notepad',
      {
        %{$attr},
        NOTIFIED    => $attr->{DATE} . ' ' . $attr->{NOTIFIED},
        AID         => $self->{admin}->{AID},
        CREATE_DATE => 'NOW()'
      }
    );
  }
  elsif ( $attr->{CUSTOM_TIME} ){
    $self->query_add( 'notepad',
      {
        %{$attr},
        NOTIFIED    => $attr->{DATE} . ' ' . $attr->{NOTIFIED},
        AID         => $self->{admin}->{AID},
        CREATE_DATE => 'NOW()'
      }
    );
    $self->query_add( 'notepad_reminders', { %{$attr}, ID => $self->{INSERT_ID} } );
  }

  return 1;
}

#**********************************************************
=head2 notepad_note_change($attr) - Change note

=cut
#**********************************************************
sub note_change{
  my $self = shift;
  my ($attr) = @_;

  $attr->{NOTIFIED} = $attr->{DATE} . ' ' . $attr->{NOTIFIED};
  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'notepad',
      DATA         => $attr,
    }
  );

  $self->changes2(
    {
      CHANGE_PARAM => 'ID',
      TABLE        => 'notepad_reminders',
      DATA         => $attr
    }
  );

  return $self;
}

#**********************************************************
=head2 notepad_del_note($attr) -  Del Note

=cut
#**********************************************************
sub note_del{
  my $self = shift;
  my ($attr) = @_;
  #  $self->{debug} = 1;
  $self->query_del( 'notepad', $attr );
  $self->query_del( 'notepad_reminders', $attr );

  return $self->{result};
}

#**********************************************************
=head2 notepad_new($attr)
=cut
#**********************************************************
sub notepad_new{
  my $self = shift;
  my ($attr) = @_;

  $self->query2( "SELECT sum(if(DATE_FORMAT(notified, '%Y-%m-%d') = curdate(), 1, 0)) AS today,
    sum(if(status = 0, 1, 0)) AS active
    FROM notepad n
    WHERE n.aid= ?;",
    undef,
    { Bind => [ $attr->{AID} ],
      INFO => 1 }
  );

  $self->{TODAY} = 0 if (!$self->{TODAY});
  $self->{ACTIVE} = 0 if (!$self->{ACTIVE});

  return $self->{TODAY}, $self->{ACTIVE};
}

#**********************************************************
=head2 active_periodic_reminders_list($attr) - returns list of periodic reminders

  Arguments:
    $attr - hash_ref

  Returns:
    list

=cut
#**********************************************************
sub active_periodic_reminders_list{
  my $self = shift;
  my ($attr) = @_;

  my $list = $self->notes_list( { COLS_UPPER => 1, COLS_NAME => 1, STATUS => 0 } );

  my @active_list = ();
  foreach my $reminder ( @{$list} ){
    if (
      $self->_now_is( {
          'MONTH_DAY' => $reminder->{'MONTH_DAY'},
          'WEEK_DAY'  => $reminder->{'WEEK_DAY'},
          'MONTH'     => $reminder->{'MONTH'},
          'YEAR'      => $reminder->{'YEAR'},
          'HOLIDAY'   => $reminder->{'HOLIDAYS'},
          'HOUR'      => $reminder->{'HOUR'},
          'MINUTE'    => $reminder->{'MINUTE'},
          DEBUG       => $attr->{DEBUG} || $debug
        } )
    ){
      push ( @active_list, $reminder );
    }
  }

  return \@active_list;
}

#**********************************************************
=head2 _date_is($time, $attr) - checks given epoch timestamp

  checks given epoch timestamp

  Arguments:
    $time - epoch time to check
    $attr - hash_ref with params to check. params are checked one by one
      MONTH_DAY
      WEEK_DAY
      MONTH
      YEAR
      HOUR
      MINUTE
      WORKDAY - boolean
      HOLIDAY - boolean

  Returns:
    true or false

  Examples:
    my $is_holiday             = notepad_date_is( time, { HOLIDAY => 1 } );
    my $is_workday             = notepad_date_is( time, { WORKDAY => 1 } );
    my $is_weekday             = notepad_date_is( time, { WEEK_DAY => 3 } );
    my $is_not_weekday         = notepad_date_is( time, { WEEK_DAY => 1 } );
    my $is_second_month_day    = notepad_date_is( time, { MONTH_DAY => 2 } );
    my $is_second_day_of_march = notepad_date_is( time, { MONTH_DAY => 2, MONTH => 3 } );
    my $is_third_day_of_march  = notepad_date_is( time, { MONTH_DAY => 3, MONTH => 3 } );
    my $is_2016_year           = notepad_date_is( time, { YEAR => '2016' } );
    my $is_2017_year           = notepad_date_is( time, { YEAR => '2017' } );
    my $is_11_hour             = notepad_date_is( time, { HOUR => 11 } );

=cut
#**********************************************************
sub _date_is {
  shift;
  my ($time, $attr) = @_;

  my (undef, $min, $hour, $mday, $mon, $year, $wday) = localtime( $time );

  $wday = ($wday == 0) ? 7 : $wday;
  $mon = $mon + 1;

  my $is = 2;
  while (my ($date_type, $date_value) = each %{$attr}) {
    if ( $date_value == 0 ){ next }
    if ( $attr->{DEBUG} ){ print "<hr> current key:value $date_type = $date_value"}
    if ( $date_type eq MONTH_DAY ){
      if ( $date_value =~ /\,/ ){
        my $result = 0;
        my @days_list = split ( /,\s?/, $date_value );
        foreach my $day ( @days_list ){
          print "Checking ($day == $mday) \n" if ($attr->{DEBUG});
          $result = ($day == $mday);
          print "result $result \n" if ($attr->{DEBUG});
          if ( $result == 1 ){ last };
        }
        $is = $result;
        print "result $result, $is \n" if ($attr->{DEBUG});
      }
      else{
        $is = ($date_value == $mday);
      }
    }
    elsif ( $date_type eq WEEK_DAY ){
      $is = ($date_value == $wday)
    }
    elsif ( $date_type eq MONTH ){
      $is = ($date_value == $mon)
    }
    elsif ( $date_type eq YEAR ){
      $is = ($date_value == $year + 1900)
    }
    elsif ( $date_type eq HOUR ){
      $is = ($date_value <= $hour)
    }
    elsif ( $date_type eq MINUTE ){
      $is = ($date_value <= $min || $date_value == $min)
    }

    if ( $is == 0 ){
      if ( $attr->{DEBUG} ){
        print "<hr>Exit on $date_type: $date_value <br/>";
      }
      return 0
    };
  }
  if ( $is == 2 ){ return  };

  if ( $is == 1 && $attr->{HOLIDAY} != 1 ){
    $is = $wday <= 5;
  }

  return $is;
}

#**********************************************************
=head2 notepad_now_is($attr)

  translates now to notepad_date_is(). See notepad_date_is() for comments

  Arguments:
    $attr - hash_ref

  Returns:
    true or false

=cut
#**********************************************************
sub _now_is{
  my $self = shift;
  return $self->_date_is( time, @_ );
}



1
