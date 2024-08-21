package Telegram;

=head1 NAME

 Telegram_bot sql functions

=cut

use strict;
use parent 'dbcore';
my $MODULE = 'Telegram';

#**********************************************************
=head2 new($db, $admin, \%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 info($uid)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($uid) = @_;

  $self->query("SELECT * FROM telegram_tmp WHERE uid = ?;",
    undef,
    { Bind => [ $uid ], COLS_NAME => 1, COLS_UPPER => 1}
  );
  return [ ] if ($self->{errno});

  return $self->{list}->[0];
}

#**********************************************************
=head2 list($attr)

=cut
#**********************************************************
sub list {
  my $self = shift;
  my ($attr) = @_;

  my $SORT = ($attr->{SORT}) ? $attr->{SORT} : 1;
  my $DESC = ($attr->{DESC}) ? $attr->{DESC} : '';

  my $WHERE = $self->search_former($attr, [
    [ 'ID',         'INT', 'tt.id',         1 ],
    [ 'UID',        'INT', 'tt.uid',        1 ],
    [ 'AID',        'INT', 'tt.aid',        1 ],
    [ 'FN',         'STR', 'tt.fn',         1 ],
    [ 'BUTTON',     'STR', 'tt.button',     1 ],
    [ 'ARGS',       'STR', 'tt.args',       1 ],
    [ 'PING_COUNT', 'INT', 'tt.ping_count', 1 ],
    [ 'MINUTES_SINCE_LAST_CONTACT', 'INT', 'TIMESTAMPDIFF(MINUTE, tt.created, NOW())', 'TIMESTAMPDIFF(MINUTE, tt.created, NOW()) AS minutes_since_last_contact' ]
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} tt.id
     FROM telegram_tmp tt
   $WHERE
   ORDER BY $SORT $DESC;", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 info_admin($aid)

=cut
#**********************************************************
sub info_admin {
  my $self = shift;
  my ($aid) = @_;

  $self->query("SELECT * FROM telegram_tmp WHERE aid = ?;",
    undef,
    { Bind => [ $aid ], COLS_NAME => 1, COLS_UPPER => 1}
  );
  return [ ] if ($self->{errno});

  return $self->{list}->[0];
}

#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add('telegram_tmp', $attr);

  return $self;
}

#**********************************************************
=head2 change($attr)

=cut
#**********************************************************
sub change {
  my $self = shift;
  my ($attr) = @_;
  
  $self->changes({
    CHANGE_PARAM => 'ID',
    TABLE        => 'telegram_tmp',
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 del($uid)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($uid) = @_;

  $self->query_del("telegram_tmp", {}, { UID => $uid });

  return $self;
}

#**********************************************************
=head2 del_admin($aid)

=cut
#**********************************************************
sub del_admin {
  my $self = shift;
  my ($aid) = @_;

  $self->query_del("telegram_tmp", {}, { AID => $aid });

  return $self;
}

#**********************************************************
=head2 truncate()

=cut
#**********************************************************
sub truncate {
  my $self = shift;

  $self->query_del("telegram_tmp", {}, {}, {CLEAR_TABLE => 1});

  return 1;
}

1