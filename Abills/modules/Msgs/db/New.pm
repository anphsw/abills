package Msgs::db::New;
=head NAME

  Msgs Only new message

=cut

use strict;
use parent qw(dbcore);


#**********************************************************
# Init
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $MODULE = 'Msgs';
  $admin->{MODULE} = $MODULE;
  my $self = {
    db     => $db,
    admin  => $admin,
    conf   => $CONF,
    module => $MODULE
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head1 messages_new($attr) - Show new message

  Arguments:
    $attr
  Results:
    $self

=cut
#**********************************************************
sub messages_new {
  my ($self, $attr) = @_;

  my @WHERE_RULES = ();
  my $EXT_TABLE = '';
  my $fields = '';

  if (! $attr->{SHOW_CHAPTERS}) {
    push @WHERE_RULES, "m.external_chat_id = 0";
  }

  if ($attr->{USER_READ}) {
    push @WHERE_RULES, "m.user_read='$attr->{USER_READ}' AND admin_read>'0000-00-00 00:00:00' AND m.inner_msg='0'";
    $fields = q{COUNT(*) AS total, '', '', max(m.id), m.chapter, m.id, 1};
  }
  elsif ($attr->{ADMIN_UNREAD}) {
    $fields = q{COUNT(*) AS total, '', '', max(m.id), m.chapter, m.id, 1};
  }
  elsif ($attr->{ADMIN_READ}) {
    $fields = << "FIELDS";
SUM(if(admin_read='0000-00-00 00:00:00', 1, 0)) AS admin_unread_count,
     SUM(IF(plan_date=CURDATE(), 1, 0)) AS today_plan_count,
     SUM(IF(state = 0, 1, 0)) AS open_count,
    1,1,1,1
FIELDS
  }

  if ($attr->{UID}) {
    push @WHERE_RULES, "m.uid='$attr->{UID}'";

    if ($self->{admin}->{DOMAIN_ID}) {
      $self->{admin}->{DOMAIN_ID} =~ s/;/,/xg;
      push @WHERE_RULES, "u.domain_id IN ($self->{admin}->{DOMAIN_ID})";
    }
  }
  elsif ($self->{admin}->{DOMAIN_ID}) {
    $self->{admin}->{DOMAIN_ID} =~ s/;/,/xg;
    push @WHERE_RULES, "c.domain_id IN ($self->{admin}->{DOMAIN_ID})";
  }

  if ($attr->{CHAPTER}) {
    $attr->{CHAPTER} =~ s/,/;/xg;
    push @WHERE_RULES, @{$self->search_expr($attr->{CHAPTER}, 'INT', 'c.id')};
  }

  if (defined($attr->{STATE}) && $attr->{STATE} ne '') {
    push @WHERE_RULES, @{$self->search_expr($attr->{STATE}, 'INT', 'm.state')};
  }

  push @WHERE_RULES, "u.gid IN ($attr->{GID})" if ($attr->{GID});

  my $WHERE = ($#WHERE_RULES > -1) ? 'WHERE ' . join(' and ', @WHERE_RULES) : '';

  $EXT_TABLE = " LEFT JOIN users u ON (m.uid = u.uid)" if ($fields =~ /u\./xm || $WHERE =~ /u\./xm);

  if ($attr->{SHOW_CHAPTERS}) {
    my $sql = <<"SQL";
SELECT c.id,
c.name,
     COALESCE(SUM(m.admin_read = '0000-00-00 00:00:00'), 0) AS admin_unread_count,
     COALESCE(SUM(plan_date=CURDATE() AND resposible = $self->{admin}->{AID}), 0) AS today_plan_count,
     COUNT(*) AS open_count,
     COALESCE(SUM(resposible = $self->{admin}->{AID}), 0) AS resposible_count,
1, 1, 1
FROM msgs_chapters c
LEFT JOIN msgs_messages m ON (m.chapter= c.id AND m.state=0 AND m.external_chat_id = 0)
$EXT_TABLE
$WHERE
GROUP BY c.id;

SQL

    $self->query($sql, undef, $attr);
    return $self->{list} || [];
  }

  $EXT_TABLE .= "\nLEFT JOIN msgs_chapters c ON (m.chapter=c.id)" if ($fields =~ /c\./xm);

  my $sql = q{};
  if ($attr->{GID}) {
    $sql = <<"SQL";
    SELECT $fields
    FROM (msgs_messages m, users u)
    $EXT_TABLE
    $WHERE  AND u.uid=m.uid
    GROUP BY 7;
SQL
  }
  else {
    if ($attr->{CHAPTER}) {
      $EXT_TABLE .= " LEFT JOIN msgs_chapters c ON (m.chapter=c.id) ";
    }

    $sql = <<"SQL";
SELECT $fields
FROM msgs_messages m
$EXT_TABLE
$WHERE
GROUP BY 7;
SQL
  }

  $self->query($sql);
  if ($self->{TOTAL} && $self->{TOTAL} > 0) {
    ($self->{UNREAD}, $self->{TODAY}, $self->{OPENED}, $self->{LAST_ID}, $self->{CHAPTER}, $self->{MSG_ID}) = @{$self->{list}->[0]};
  }

  return $self;
}

#**********************************************************
=head2 permissions_list($aid)

  Arguments:
    $aid
  Results:
    $self

=cut
#**********************************************************
sub permissions_list {
  my ($self, $aid) = @_;

  if ($aid) {
    $self->query("SELECT section, actions FROM msgs_permits WHERE aid = ?;", undef, { Bind => [ $aid ], COLS_NAME => 1 });
  }
  else {
    $self->query("SELECT aid, section, actions FROM msgs_permits;", undef, { COLS_NAME => 1 });
  }

  my %msgs_permissions = ();
  foreach my $line (@{$self->{list}}) {
    if ($line->{aid}) {
      $msgs_permissions{$line->{aid}}{$line->{section}}{$line->{actions}} = 1;
      next;
    }

    $msgs_permissions{$line->{section}}{$line->{actions}} = 1;
  }

  if (!$self->{errno} && $aid) {
    my $sql = <<'SQL';
SELECT
       ma.deligation_level,
       IF(ma.chapter_id IS NULL, 0, ma.chapter_id) AS chapter_id
FROM admins a
       INNER join msgs_admins ma ON (a.aid=ma.aid)
WHERE a.aid = ?;
SQL

    $self->query($sql, undef, { Bind => [ $aid ], COLS_NAME => 1 });

    foreach my $msgs_admin (@{ $self->{list} }) {
      $msgs_permissions{deligation_level}{$msgs_admin->{chapter_id}}=$_->{deligation_level};
    }
  }

  return \%msgs_permissions;
}

1;