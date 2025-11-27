package Shedule;

=head1 NAME

  Shedule SQL backend

=cut

use strict;
use parent qw(dbcore);
use Abills::Base qw(in_array);

#**********************************************************
#
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  $admin->{MODULE} = 'Shedule';
  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 change($attr) - Change shedule rule

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub change {
  my ($self, $attr) = @_;

  if ($attr->{SHEDULE_ID} && !$attr->{ID}) {
    $attr->{ID} = $attr->{SHEDULE_ID};
  }

  $self->changes({
    CHANGE_PARAM    => 'ID',
    TABLE           => 'shedule',
    DATA            => $attr,
    EXT_CHANGE_INFO => "SHEDULE:$attr->{ID}, RESULT: $attr->{RESULT}"
  });

  $self->info({ ID => $attr->{SHEDULE_ID} });

  return $self;
}

#**********************************************************
=head2 info($attr) - Shedule info

  Arguments:
    $attr
      UID
      TYPE
      MODULE
      ID

  Results:
    Object

=cut
#**********************************************************
sub info {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();

  if ($attr->{UID}) {
    push @WHERE_RULES, "s.uid='$attr->{UID}'";
  }

  if ($attr->{TYPE}) {
    push @WHERE_RULES, "s.type='$attr->{TYPE}'";
  }

  if ($attr->{MODULE}) {
    push @WHERE_RULES, "s.module='$attr->{MODULE}'";
  }

  if ($attr->{ID}) {
    push @WHERE_RULES, "s.id='$attr->{ID}'";
  }

  if ($attr->{ACTION}) {
    push @WHERE_RULES, "s.action LIKE '$attr->{ACTION}'";
  }

  my $WHERE = ($#WHERE_RULES > -1) ? "WHERE " . join(' and ', @WHERE_RULES) : '';

  my $sql = <<"SQL";
  SELECT s.h,
     s.d,
     s.m,
     s.y,
     s.counts,
     s.action,
     s.date,
     s.comments,
     s.module,
     s.uid,
     s.id AS shedule_id,
     a.id As admin_name,
     s.admin_action
    FROM shedule s
    LEFT JOIN admins a ON (a.aid=s.aid)
    $WHERE;
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $self;
}

#**********************************************************
=head2 list() - Shedule list

=cut
#**********************************************************
sub list {
  my ($self, $attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;

  my @arr = (2, 3, 4);

  if (in_array($SORT, \@arr)) {
    $attr->{SHEDULE_DATE} = '_SHOW' if (!$attr->{SHEDULE_DATE});
    $attr->{SORT} = 16;
  }

  $self->{EXT_TABLES} = '';
  $attr->{SKIP_DEL_CHECK} = 1;

  my @search_params = (
    [ 'UID',      'INT', 's.uid'      ],
    [ 'AID',      'INT', 's.aid'      ],
    [ 'TYPE',     'STR', 's.type'     ],
    [ 'Y',        'STR', 's.y'        ],
    [ 'M',        'STR', 's.m'        ],
    [ 'D',        'STR', 's.d'        ],
    [ 'MODULE',   'STR', 's.module'   ],
    [ 'COMMENTS', 'STR', 's.comments' ],
    [ 'ACTION',   'STR', 's.action'   ],
    [ 'ADMIN_ACTION', 'STR', 's.admin_action' ],
    [ 'ID',       'INT', 's.id'       ],
    [ 'SHEDULE_DATE', 'DATE', "CONCAT(s.y,'-',s.m,'-',s.d)", "CONCAT(s.y,'-',s.m,'-',s.d)" ]
  );

  my $WHERE = $self->search_former($attr, \@search_params,
    { WHERE             => 1,
      USERS_FIELDS      => 1,
      USE_USER_PI       => 1,
      SKIP_USERS_FIELDS => [ 'FIO', 'UID' ]
    }
  );

  my $EXT_TABLE = $self->{EXT_TABLES} || '';
  my $GROUP_BY = q{};
  if ($attr->{TAGS}) {
    $GROUP_BY = 'GROUP BY s.id';
  }

  if ($attr->{SERVICE_ID}) {
    if ($WHERE) {
      $WHERE .= " AND s.action LIKE '$attr->{SERVICE_ID}:%'";
    }
    else {
      $WHERE .= " WHERE s.action LIKE '$attr->{SERVICE_ID}:%'";
    }
  }

  my $sql = <<"SQL";
SELECT s.h, s.d, s.m, s.y, s.counts,
       u.id AS login,
       s.type,
       s.action,
       s.module,
       a.id AS admin_name,
       s.date,
       s.comments,
       s.admin_action,
       a.aid,
       s.uid,
       $self->{SEARCH_FIELDS}
      s.id
FROM shedule s
  LEFT JOIN users u ON (u.uid=s.uid)
  LEFT JOIN admins a ON (a.aid=s.aid)
  $EXT_TABLE
  $WHERE
  $GROUP_BY
SQL


  $self->query_list($sql, $attr);

  my $list = $self->{list} || [];

  $sql = <<"SQL";
  SELECT COUNT(*) AS total FROM shedule s
    LEFT JOIN users u ON (u.uid=s.uid)
    LEFT JOIN admins a ON (a.aid=s.aid)
   $WHERE
SQL

  $self->query($sql, undef, { INFO => 1 });

  return $list || [];
}

#**********************************************************
=head2  add($attr) Add new shedule

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub add {
  my ($self, $attr) = @_;

  $attr->{D} = sprintf('%02d', $attr->{D}) if ($attr->{D} && $attr->{D} ne '*');
  $attr->{M} = sprintf('%02d', $attr->{M}) if ($attr->{M} && $attr->{M} ne '*');

  $self->query_add('shedule', {
    %{$attr},
    H      => $attr->{H} || '*',
    D      => $attr->{D} || '*',
    M      => $attr->{M} || '*',
    Y      => $attr->{Y} || '*',
    ACTION => (defined($attr->{ACTION})) ? $attr->{ACTION} : '',
    AID    => $self->{admin}->{AID},
    DATE   => 'NOW()',
  });

  if (!$self->{errno}) {
    $self->{admin}->{MODULE} = $attr->{MODULE};
    if ($attr->{UID}) {
      $self->{admin}->action_add($attr->{UID},
        "SHEDULE:$self->{INSERT_ID} $attr->{TYPE}:$attr->{ACTION}:$attr->{MODULE}:$attr->{COMMENTS}", { TYPE => 27 });
    }
    else {
      $self->{admin}->system_action_add(
        "SHEDULE:$self->{INSERT_ID} $attr->{TYPE}:$attr->{ACTION}:$attr->{MODULE}:$attr->{COMMENTS}", { TYPE => 27 });
    }
  }

  return $self;
}

#**********************************************************
=head2 add($self) - del shedule

  Arguments:
    $attr
      EXECUTE - Execute flag
      UID

  Result:
    Object

=cut
#**********************************************************
sub del {
  my ($self, $attr) = @_;

  my $result = $attr->{result} || 0;
  delete $attr->{result};

  if ($attr->{IDS}) {
    my $WHERE = '';
    if ($attr->{UID}) {
      $WHERE = " AND uid='$attr->{UID}'";
    }

    my $ids = $attr->{IDS};
    $ids =~ s/,\s?/;/xg;
    $self->list({ ID => $ids });

    if ($self->{TOTAL}) {
      my $sql = <<"SQL";
DELETE FROM shedule WHERE id IN ( $attr->{IDS} ) $WHERE;
SQL

      $self->query($sql, 'do');

      if ($self->{AFFECTED}) {
        $self->{admin}->{MODULE} = 'Shedule';
        if ($attr->{UID}) {
          $self->{admin}->action_add($attr->{UID}, "SHEDULE:$attr->{IDS} RESULT:$result" . $attr->{EXT_INFO},
            { TYPE => ($attr->{EXECUTE}) ? 29 : 28 });
        }
        else {
          $self->{admin}->system_action_add("SHEDULE:$attr->{IDS} UID:$self->{UID}", { TYPE => 10 });
        }
        return $self;
      }
    }
  }

  $self->info({ ID => $attr->{ID} });

  $self->{admin}->{MODULE} = $attr->{MODULE};
  if ($self->{TOTAL} > 0) {
    if ($attr->{UID} && $attr->{UID} != $self->{UID}) {
      $self->{errno} = 11;
      $self->{errstr} = 'WRONG_UID';
      return $self;
    }

    $self->query_del('shedule', $attr, {
      uid => $attr->{UID}
    });

    if ($self->{AFFECTED}) {
      if ($self->{UID}) {
        $self->{admin}->action_add($self->{UID}, "SHEDULE:$attr->{ID} $result" . $attr->{EXT_INFO},
          { TYPE => ($attr->{EXECUTE}) ? 29 : 28 });
      }
      else {
        $self->{admin}->system_action_add("SHEDULE:$attr->{ID} $result", { TYPE => ($attr->{EXECUTE}) ? 29 : 28 });
      }
    }
  }

  return $self;
}

1;
