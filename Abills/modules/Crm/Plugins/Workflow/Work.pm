package Crm::Plugins::Workflow::Work;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Crm::Plugins::Workflow::Work

=head2 SYNOPSIS

  Plugin for test

=cut

my $Crm;
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

  use Crm::db::Crm;
  $Crm //= Crm->new(@{$self}{qw/db admin conf/});

  return $self;
}

#**********************************************************
=head2 execute($lead_id)

=cut
#**********************************************************
sub execute {
  my $self = shift;
  my $lead_id = shift;
  
  my $lead = $Crm->crm_lead_info({ ID => $lead_id });
  my $step_id_hash = $Crm->crm_step_number_leads();

  $Crm->progressbar_comment_add({
    LEAD_ID => $lead_id,
    STEP_ID => $step_id_hash->{$lead->{CURRENT_STEP}} || 1,
    MESSAGE => 'Message created from the test plugin',
    DATE    => "$main::DATE $main::TIME"
  });
}

1;