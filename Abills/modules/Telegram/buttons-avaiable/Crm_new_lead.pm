package Crm_new_lead;

use strict;
use warnings FATAL => 'all';

my $Crm;

#**********************************************************
=head2 new($Botapi)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf, $bot) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    bot   => $bot,
  };

  bless($self, $class);

  use Crm::db::Crm;
  $Crm = Crm->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return $self->{bot}{lang}{THE_SUBSCRIBER_WITH_THIS_PHONE_IS_NOT_REGISTERED};
}

#**********************************************************
=head2 add_request($attr)

=cut
#**********************************************************
sub add_request {
  my $self = shift;
  my ($attr) = @_;

  my $phone = $attr->{argv}[2] || '';
  if (!$phone) {
    $self->{bot}->send_message({
      text       => $self->{bot}{lang}{AN_ERROR_OCCURRED_WHILE_APPLYING},
      parse_mode => 'HTML'
    });
    return 1;
  }

  $Crm->crm_lead_list({
    PHONE_SEARCH   => $phone,
    SKIP_DEL_CHECK => 1,
    COLS_NAME      => 1
  });

  if ($Crm->{TOTAL} && $Crm->{TOTAL} > 0) {
    $self->{bot}->send_message({
      text       => $self->{bot}{lang}{REQUEST_BY_THIS_NUMBER_HAS_ALREADY_BEEN_SENT},
      parse_mode => 'HTML'
    });
    return 1;
  }

  my $fio = $attr->{user} ? ($attr->{user}{last_name} || '') . ' ' . ($attr->{user}{first_name} || '') : '';

  $Crm->crm_lead_add({
    PHONE    => $phone,
    FIO      => $fio,
    COMMENTS => 'Telegram: ' . ($attr->{user} && $attr->{user}{id} ? $attr->{user}{id} : '')
  });

  my $text = $Crm->{errno} ? $self->{bot}{lang}{AN_ERROR_OCCURRED_WHILE_APPLYING} : $self->{bot}{lang}{APPLICATION_SENT};

  $self->{bot}->send_message({
    text       => $text,
    parse_mode => 'HTML'
  });
}

1;