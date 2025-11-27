package Tools;
=head1 NAME

  Tools for processing

=cut

use strict;
use warnings;
use parent 'dbcore';


#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 contacts_migrate($attr) - migrates contacts from old to new model

  Arguments:
    $attr

  Returns:
    boolean - success flag

=cut
#**********************************************************
sub contacts_migrate {
  my ($self, $attr) = @_;

  if ($attr->{IGNORE_DUPLICATE}){
    $self->query("ALTER TABLE users_contacts DROP KEY `_type_value`;");
    if ($self->{errno}) {
      if ($self->{errno} == 1091) {

      }
      else {
        return 0;
      }
    }
  };

  my %old_type_to_new = (
    EMAIL => 9,
    PHONE => 2
  );

  $self->query("SET FOREIGN_KEY_CHECKS=0;", 'do');

  my $sql = <<'SQL';
SELECT u.uid, up.phone, up.email
FROM users u
       LEFT JOIN users_pi up ON (u.uid=up.uid)
WHERE up.phone <> '' OR up.email <> ''
ORDER BY u.uid
SQL


  $self->query($sql, undef, { COLS_NAME => 1 });

  return 0 if ($self->{errno});
  return 1 if (!$self->{list} || scalar @{$self->{list}} <= 0);

  # Accumulating requests
  my @contacts_to_add = ();

  foreach my $user_pi (@{$self->{list}}) {
    if ($user_pi->{phone}) {
      my @phones = split(/,\s?/x, $user_pi->{phone});
      map {
        push @contacts_to_add, [ $user_pi->{uid}, $old_type_to_new{PHONE}, $_ ];
      } @phones;
    }
    if ($user_pi->{email}) {
      my @emails = split(/,\s?/x, $user_pi->{email});
      map {
        push @contacts_to_add, [ $user_pi->{uid}, $old_type_to_new{EMAIL}, $_ ];
      } @emails;
    }
  }

  # Start a transaction
  my DBI $db_ = $self->{db}->{db};
  $db_->{AutoCommit} = 0;

  # Add all contacts
  $self->query( "REPLACE INTO users_contacts (uid, type_id, value) VALUES (?, ?, ?);",
    undef,
    { MULTI_QUERY => \@contacts_to_add }
  );

  if ( $self->{errno} ) {
    # If error was occured, part of contacts could be inserted,
    # so next time we will get DUPLICATE, need to remove all inserted contacts
    $db_->rollback();
    return 0;
  }

  if ( $self->{errno} ) {
    $db_->rollback();
    return 0;
  }

  $db_->commit();
  $db_->{AutoCommit} = 1;

  # If insert was successful, can remove old info
  $self->query("UPDATE users_pi SET phone='', email='';", 'do');

  return 1;
}


1;