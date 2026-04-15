#package Accident::Errors_gen;

use strict;
use warnings FATAL => 'all';
use Accident;
use Abills::Sender::Core;

=head1 NAME

  Accident error generation function

=cut
our(
  $db,
  $admin,
  %conf
);
my $Accident = Accident->new($db, $admin, \%conf);
my $Sender = Abills::Sender::Core->new($db, $admin, \%conf);

#**********************************************************
=head2 accident_equipment_error($attr)

  Attr:
    NAS_ID
    NAS_NAME
    PORT_ID - Error port
    STATUS: 0 - open, 1 - in process, 2 - closed, 3 - not response

=cut
#**********************************************************
sub accident_equipment_error {
  my ($attr) = @_;

  return if (!$attr->{NAS_ID});

  my $list_equipment_error = $Accident->accident_equipment_list({
    ID_EQUIPMENT => $attr->{NAS_ID},
    PORT_ID      => ($attr->{PORT_ID}) ? $attr->{PORT_ID} : '_SHOW',
    DATE         => '_SHOW',
    END_DATE     => '_SHOW',
    STATUS       => '0;3',
    AID          => '_SHOW',
    EXT_TABLE    => 1,
    COLS_NAME    => 1,
  });

  if ($Accident->{TOTAL} > 0){
    if ($attr->{STATUS} == 0 && $list_equipment_error->[0]->{status} == 3){
      $Accident->accident_equipment_chg({
        ID       => $list_equipment_error->[0]->{id},
        STATUS   => 0,
      });

      if ($conf{EQUIPMENT_TYPE_ACCIDENT}){
        my $admins_equipment = $Accident->admin_info({ ACCIDENT_TYPE => $conf{EQUIPMENT_TYPE_ACCIDENT} });
        return if (!$admins_equipment->{ADMINS});

        my @arr_admins = split(',', $admins_equipment->{ADMINS});

        foreach my $aid (@arr_admins) {
          $Sender->send_message({
            AID     => $aid,
            TITLE   => "ACCIDENT_EQUIPMENT: $attr->{NAS_NAME}",
            MESSAGE => "$attr->{NAS_NAME}, ID: $attr->{NAS_ID}",
            SOURCE  => 'Accident'
          });
        }
      }
    }
    elsif ($attr->{STATUS} == 2){
      $Accident->accident_equipment_chg({
        ID       => $list_equipment_error->[0]->{id},
        STATUS   => 2,
        END_DATE => "$DATE $TIME",
      });
    }

    return;
  }

  return if ($attr->{STATUS} && $attr->{STATUS} == 2);

  $Accident->accident_equipment_add({
    ID_EQUIPMENT => $attr->{NAS_ID},
    PORT_ID      => $attr->{PORT_ID} ? $attr->{PORT_ID} : '',
    DATE         => "$DATE $TIME",
    AID          => $admin->{AID},
    STATUS       => 3,
    TYPE         => $conf{EQUIPMENT_TYPE_ACCIDENT} || 0,
  });

  return;
}

1;