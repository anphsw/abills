package Telegram::db::Telegram;

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
  my ($db, $admin, $conf, $attr) = @_;

  $admin->{MODULE} = $MODULE;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    table => $attr->{ADMIN} ? 'telegram_state_admin' : 'telegram_state_user'
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 info($user_id)

=cut
#**********************************************************
sub info {
  my $self = shift;
  my ($user_id) = @_;

  $self->query("SELECT * FROM `$self->{table}` WHERE user_id = ?;",
    undef,
    { Bind => [ $user_id ], COLS_NAME => 1, COLS_UPPER => 1}
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
    [ 'USER_ID',    'INT', 'tt.user_id',    1 ],
    [ 'FN',         'STR', 'tt.fn',         1 ],
    [ 'BUTTON',     'STR', 'tt.button',     1 ],
    [ 'ARGS',       'STR', 'tt.args',       1 ],
    [ 'PING_COUNT', 'INT', 'tt.ping_count', 1 ],
    [ 'MINUTES_SINCE_LAST_CONTACT', 'INT', 'TIMESTAMPDIFF(MINUTE, tt.created, NOW())', 'TIMESTAMPDIFF(MINUTE, tt.created, NOW()) AS minutes_since_last_contact' ]
  ], { WHERE => 1 });

  $self->query("SELECT $self->{SEARCH_FIELDS} tt.id
     FROM `$self->{table}` tt
   $WHERE
   ORDER BY $SORT $DESC;", undef, $attr);

  return $self->{list} || [];
}

#**********************************************************
=head2 add($attr)

=cut
#**********************************************************
sub add {
  my $self = shift;
  my ($attr) = @_;

  $self->query_add($self->{table}, $attr);

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
    TABLE        => $self->{table},
    DATA         => $attr,
  });

  return $self;
}

#**********************************************************
=head2 del($user_id)

=cut
#**********************************************************
sub del {
  my $self = shift;
  my ($user_id) = @_;

  $self->query_del($self->{table}, {}, { USER_ID => $user_id });

  return $self;
}

#**********************************************************
=head2 truncate()

=cut
#**********************************************************
sub truncate {
  my $self = shift;

  $self->query_del($self->{table}, {}, {}, {CLEAR_TABLE => 1});

  return 1;
}

1