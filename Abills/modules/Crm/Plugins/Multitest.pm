package Crm::Plugins::Multitest;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Plugins::Multitest

=head2 SYNOPSIS

  This package is used to integrate with the Multitest system

=cut

use Crm::db::Crm;
use Address;

my $Crm;
my $Address;

use Abills::Base qw(in_array);

#**********************************************************
=head2 new($db,$admin,\%conf)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $Address //= Address->new(@{$self}{qw/db admin conf/});
  $Crm //= Crm->new(@{$self}{qw/db admin conf/});

  return $self;
}

#**********************************************************
=head2 lead_add($lead) - Manage Lead Request

  Arguments:
    $lead - Lead information hash reference
      mobile - Mobile number
      lastname - Last name (optional)
      name - First name
      email - Email address
      comment - Comments (optional)
      tariff - Tariff information (optional)

  Returns:
    None

  Example:
    $Multitest->lead_add({
      mobile   => '123456789',
      lastname => 'Doe',
      name     => 'John',
      email    => 'john.doe@example.com',
      comment  => 'Interested in special offer',
      tariff   => 'Gold Plan'
    });
=cut
#**********************************************************
sub lead_add {
  my $self = shift;
  my ($lead) = @_;

  return if !$lead->{mobile};

  $Crm->crm_lead_list({ PHONE => $lead->{mobile} });
  return if $Crm->{TOTAL} && $Crm->{TOTAL} > 0;

  $lead->{name} = join(' ', ($lead->{lastname}, $lead->{name})) if $lead->{lastname};

  if ($lead->{tariff}) {
    my $tariffs = $Crm->crm_competitors_tps_list({ NAME => $lead->{tariff}, COLS_NAME => 1 });
    if ($Crm->{TOTAL} && $Crm->{TOTAL} > 0) {
      $lead->{tp_id} = $tariffs->[0]{id};
    }
    else {
      $Crm->crm_competitors_tps_add({ NAME => $lead->{tariff} });
      $lead->{tp_id} = $Crm->{INSERT_ID} if $Crm->{INSERT_ID};
    }
  }
  $lead->{build_id} = _get_build_id($lead);

  $Crm->crm_lead_add({
    PHONE        => $lead->{mobile},
    FIO          => $lead->{name},
    EMAIL        => $lead->{email},
    COMMENTS     => $lead->{comment},
    ADDRESS_FLAT => $lead->{apartment},
    TP_ID        => $lead->{tp_id},
    BUILD_ID     => $lead->{build_id}
  });
}

#**********************************************************
=head2 _get_build_id($lead)

=cut
#**********************************************************
sub _get_build_id {
  my ($lead) = @_;

  return 0 if !$lead->{city} || !$lead->{street} || !$lead->{house};

  my $district = $Address->district_list({ NAME => $lead->{city}, COLS_NAME => 1 });
  my $district_id = 0;
  if ($Address->{TOTAL} && $Address->{TOTAL} > 0) {
    $district_id = $district->[0]{id};
  }
  else {
    $Address->district_add({ NAME => $lead->{city} });
    $district_id = $Address->{INSERT_ID};
  }
  return 0 if !$district_id;

  my $street = $Address->street_list({ STREET_NAME => $lead->{street}, DISTRICT_ID => $district_id, COLS_NAME => 1 });
  my $street_id = 0;
  if ($Address->{TOTAL} && $Address->{TOTAL} > 0) {
    $street_id = $street->[0]{street_id};
  }
  else {
    $Address->street_add({ NAME => $lead->{street}, DISTRICT_ID => $district_id });
    $street_id = $Address->{INSERT_ID};
  }
  return 0 if !$street_id;

  $Address->build_add({ ADD_ADDRESS_BUILD => $lead->{house}, STREET_ID => $street_id });
  return $Address->{LOCATION_ID} || 0;
}

1;