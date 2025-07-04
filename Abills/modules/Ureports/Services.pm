package Ureports::Services;

use strict;
use warnings FATAL => 'all';

my Abills::HTML $html;

use Ureports;
my Ureports $Ureports;
my $Tariffs;
my $Contacts;
my $Users;
my $Fees;

use Abills::Base qw/in_array/;

#**********************************************************
=head2 new($html, $lang)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    lang  => $attr->{lang} || {}
  };

  $Ureports = Ureports->new($db, $admin, $conf);

  use Tariffs;
  $Tariffs = Tariffs->new($db, $conf, $admin);

  require Contacts;
  Contacts->import();
  $Contacts = Contacts->new($db, $admin, $conf);

  require Users;
  Users->import();
  $Users = Users->new($db, $admin, $conf);

  require Finance;
  Finance->import();
  $Fees = Finance->fees($db, $admin, $conf);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 ureport_add_multiple_users($attr) - Add multiple users to a tariff plan with specified types

  Arguments:
    $attr   - Hash reference containing the following keys:
       TP_ID   - Tariff plan ID (required)
       UIDS    - Array reference of user IDs (required)
       TYPE    - Type(s) of user destinations (required, scalar or array reference)
       STATUS  - Status to set for successful users (optional)
       R_IDS   - Array reference of report IDs for updating user reports (optional)

  Returns:
    $self    - Updated object with the following keys:
       FAILED_USERS     - Comma-separated list of failed user IDs
       SUCCESSFUL_USERS - Comma-separated list of successful user IDs
       TOTAL            - Count of successfully added users

=cut
#**********************************************************
sub ureport_add_multiple_users {
  my $self = shift;
  my ($attr) = @_;

  return $self if !$attr->{TP_ID};
  return $self if !$attr->{UIDS} || ref $attr->{UIDS} ne 'ARRAY';
  return $self if !$attr->{TYPE};

  my @types = ref $attr->{TYPE} ne 'ARRAY' ? ($attr->{TYPE}) : @{$attr->{TYPE}};
  my %types_default_value = ( 10 => 1 );
  my %types_extra_value = ( 1 => 2, 14 => 1 );
  my $types_str = join(',', @types);
  my @uids = @{$attr->{UIDS}};

  $self->{TP_INFO} = $Tariffs->info($attr->{TP_ID});
  return $self if !$Tariffs->{TOTAL} || $Tariffs->{TOTAL} < 1;

  my %contacts_hash = ();
  my $contacts_list = $Contacts->contacts_list({
    UID       => join(';', @uids),
    VALUE     => '!',
    TYPE      => '_SHOW',
    COLS_NAME => 1
  });

  my @successful_users = ();
  my @failed_users = ();

  foreach my $line (@$contacts_list) {
    $contacts_hash{$line->{uid}}{$line->{type_id}} = $line->{value};
  }

  foreach my $uid (@uids) {
    my $user_contacts = $contacts_hash{$uid};
    if (!$user_contacts && !in_array(10, \@types)) {
      push @failed_users, $uid;
      next;
    }

    $Ureports->user_info($uid);
    if ($Ureports->{TOTAL} && $Ureports->{TOTAL} > 0) {
      push @failed_users, $uid;
      next;
    }

    my %user_destinations = ();
    foreach my $type (@types) {
      next if (!$user_contacts->{$type} && !$types_extra_value{$type}) && !$types_default_value{$type};
      my $destination = $user_contacts->{$type} ||
        ($types_extra_value{$type} ? $user_contacts->{$types_extra_value{$type}} : '') ||
        $types_default_value{$type};
      next if !$destination;

      $user_destinations{'DESTINATION_' . $type} = $destination;
    }

    if (scalar(keys(%user_destinations)) < 1) {
      push @failed_users, $uid;
      next;
    }

    if ($Tariffs->{ACTIVATE_PRICE} > 0) {
      my $user_info = $Users->info($uid);
      if (($user_info->{DEPOSIT} + $user_info->{CREDIT} < $Tariffs->{ACTIVATE_PRICE}) && $Tariffs->{PAYMENT_TYPE} == 0) {
        push @failed_users, $uid;
        next;
      }

      $Fees->take($user_info, $Tariffs->{ACTIVATE_PRICE}, { DESCRIBE => "Ureports: ACTIVE Tariff plan" });
      if ($Fees->{errno}) {
        push @failed_users, $uid;
        next;
      }
    }

    $Ureports->user_send_types_add({
      TYPE => $types_str,
      UID  => $uid,
      %user_destinations
    });
    if ($Ureports->{errno}) {
      push @failed_users, $uid;
      next;
    }
    else {
      $self->{admin}->action_add($uid, "TP_ID: $attr->{TP_ID}", { TYPE => 1 });
      push @successful_users, $uid;
    }
  }

  $self->{FAILED_USERS} = join(', ', @failed_users);
  $self->{SUCCESSFUL_USERS} = join(', ', @successful_users);
  $self->{TOTAL} = scalar(@successful_users);

  return $self if !$self->{SUCCESSFUL_USERS};

  $Ureports->user_multi_add({
    UID    => \@successful_users,
    TP_ID  => $attr->{TP_ID},
    STATUS => $attr->{STATUS}
  });

  if ($attr->{R_IDS}) {
    $Ureports->tp_user_reports_multi_change({ %{$attr},
      UIDS  => $self->{SUCCESSFUL_USERS},
      IDS   => $attr->{R_IDS},
      TP_ID => $attr->{TP_ID}
    });
  }

  return $self;
}

1;