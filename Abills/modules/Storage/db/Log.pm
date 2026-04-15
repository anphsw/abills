package Storage::db::Log;

=head1 NAME

  Storage Log DB functions

=head1 VERSION

  VERSION: 0.01
  REVISION: 20251125
  UPDATE: 20251125

=cut

use strict;
use parent 'dbcore';

use Abills::Base qw/json_former/;

#**********************************************************
=head2 new($class, $db, $admin, $CONF)

  Arguments:
    $class - Class name (automatically passed)
    $db    - Database handler
    $admin - Admin object containing current admin session/user data
    $CONF  - Configuration hash or object

  Example:

    my $obj = Log->new($db, $admin, \%CONF);

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
=head2 storage_log_add_hybrid($self, $attr)

  Arguments:
    $self - Object instance
    $attr - HashRef with the following keys:
        STORAGE_MAIN_ID
        STORAGE_ID
        ACTION
        COUNT
        COMMENTS
        UID
        NAS_ID
        STORAGE_INSTALLATION_ID
        ARTICLE_ID
        STORAGE_INCOMING_ID
        SERIAL_NUMBER
        EXTRA_DATA
        OPERATION_DATA

  Returns:
    $self

  Example:

    $storage->storage_log_add_hybrid({
      STORAGE_MAIN_ID => 12,
      STORAGE_ID      => 3,
      ACTION          => 'MOVE',
      COUNT           => 1,
      COMMENTS        => 'Item moved',
      EXTRA_DATA      => { note => 'OK' },
      OPERATION_DATA  => { PRICE => '10 -> 12' }
    });

=cut
#**********************************************************
sub storage_log_add_hybrid {
  my ($self, $attr) = @_;

  my %denormalized = (
    ARTICLE_ID          => $attr->{ARTICLE_ID} || '',
    STORAGE_INCOMING_ID => $attr->{STORAGE_INCOMING_ID} || '',
    SERIAL_NUMBER       => $attr->{SERIAL_NUMBER} || '',
  );

  my $extra_json = json_former($attr->{EXTRA_DATA} || {});
  my $operation_json = json_former($attr->{OPERATION_DATA} || {});

  $self->query_add('storage_log', {
    STORAGE_MAIN_ID         => $attr->{STORAGE_MAIN_ID},
    STORAGE_ID              => $attr->{STORAGE_ID},
    ACTION                  => $attr->{ACTION},
    COUNT                   => $attr->{COUNT},
    COMMENTS                => $attr->{COMMENTS},
    UID                     => $attr->{UID},
    NAS_ID                  => $attr->{NAS_ID},
    STORAGE_INSTALLATION_ID => $attr->{STORAGE_INSTALLATION_ID},

    %denormalized,
    EXTRA_DATA              => $extra_json,
    OPERATION_DATA          => $operation_json,

    DATE                    => 'NOW()',
    IP                      => $self->{admin}->{SESSION_IP},
    AID                     => $self->{admin}->{AID}
  });

  return $self;
}

1;