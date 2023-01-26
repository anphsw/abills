package Paysys::Paysys_Base2;
=head1 Paysys_Base2

  Paysys_Base - module for payments

=head1 SYNOPSIS

  paysys_load('Paysys_Base');

=cut

use strict;
use warnings FATAL => 'all';

no if $] >= 5.017011, warnings => 'experimental::smartmatch';

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    lang  => $attr->{lang},
    html  => $attr->{html},
    conf  => $conf,
    DEBUG => $conf->{PAYSYS_DEBUG} || 0,
  };


  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 conf_gid_split($attr) - Find payment system parameters for some user group (GID)

  Arguments:
    $attr
      GID           - group identifier;
      NAME: string  - custom name of Payment system
      PARAMS        - Array of parameters
      SERVICE       - Service ID
      SERVICE2GID   - Service to gid
                        delimiter :
                        separator ;
      GET_MAIN_GID-

  Returns:
    TRUE or FALSE

  Examples:

    conf_gid_split({ GID    => 1,
                     PARAMS => [
                         'PAYSYS_UKRPAYS_SERVICE_ID',
                      ],
                 })
    convers

     $conf{PAYSYS_UKRPAYS_SERVICE_ID} => $conf{PAYSYS_UKRPAYS_SERVICE_ID_1};

=cut
#**********************************************************
sub conf_gid_split {
  my $self = shift;
  my ($attr) = @_;

  my $gid = $attr->{GID};

  if (!$gid) {
    return $self->{conf};
  }

  if ($attr->{SERVICE} && $attr->{SERVICE2GID}) {
    my @services_arr = split(/;/, $attr->{SERVICE2GID});
    foreach my $line (@services_arr) {
      my ($service, $gid_id) = split(/:/, $line);
      if ($attr->{SERVICE} == $service) {
        $gid = $gid_id;
        last;
      }
    }
  }

  if ($attr->{PARAMS}) {
    my $params = $attr->{PARAMS};
    foreach my $key (@$params) {
      $key =~ s/_NAME_/_$attr->{NAME}\_/ if ($attr->{NAME} && $key =~ /_NAME_/);
      if ($self->{conf}->{$key . '_' . $gid} || $self->{conf}->{$key . '_' . $gid} ~~ 0) {
        $self->{conf}->{$key} = $self->{conf}->{$key . '_' . $gid};
        if ($attr->{GET_MAIN_GID}) {
          $attr->{MAIN_GID} = $gid;
        }
      }
    }
  }

  return $self->{conf};
}

1;
