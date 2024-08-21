package Ureports::Plugins::Paysys_invoices;

use Paysys::Init qw(_configure_load_payment_module);

use strict;
use warnings FATAL => 'all';

my %SYS_CONF = (
  REPORT_ID       => 52,
  REPORT_NAME     => 'Paysys invoice',
  REPORT_FUNCTION => 'send_invoice',
  #TODO: use in future COMMENTS        => 'Paysys send invoice',
  COMMENTS        => 'Privat invoice',
  LOCAL_SEND      => 1,
  TEMPLATE        => 'none'
  #TODO: add sub reports field
);

#**********************************************************
=head2 new()

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF
  };

  bless($self, $class);

  $self->{SYS_CONF} = \%SYS_CONF;

  return $self;
}

#**********************************************************
=head2 send_invoice()

=cut
#**********************************************************
sub send_invoice {
  my $self = shift;
  my ($user, $attr) = @_;

  if (!$user->{EXPIRE_DAYS} || $user->{EXPIRE_DAYS} > $user->{VALUE}) {
    if ($self->{debug}) {
      print "Skip sending invoice expire the time has not yet come no EXPIRE_DAYS or EXPIRE_DAYS > VALUE\n";
    }
    return 0;
  }

  ::load_module('Paysys', { LANG_ONLY => 1 });
  ::load_module('Paysys::Paysys_Base', { LOAD_PACKAGE => 1 }) if (!exists($INC{"Paysys/Paysys_Base.pm"}));
  require Paysys;
  Paysys->import();
  my $Paysys = Paysys->new($self->{db}, $self->{admin}, $self->{conf});

  #TODO add support of SUB_REPORT_ID and load such payment plugin via paysys_id
  my $systems_list = $Paysys->paysys_connect_system_list({
    STATUS    => 1,
    ID        => '_SHOW',
    NAME      => '_SHOW',
    MODULE    => 'Privat_terminal.pm',
    COLS_NAME => 1,
    PAGE_ROWS => 50
  });

  my $Pay_plugin = '';
  foreach my $system (@{$systems_list}) {
    my $Paysys_plugin = _configure_load_payment_module($system->{module}, 0, $self->{conf});
    next if (!$Paysys_plugin->can('ureports_send'));

    $Pay_plugin = $Paysys_plugin->new($self->{db}, $self->{admin}, $self->{conf});
    last;
  }

  return 0 if (!$Pay_plugin);

  my $result = $Pay_plugin->ureports_send($user, $attr);

  require Ureports;
  Ureports->import();
  my $Ureports = Ureports->new($self->{db}, $self->{admin}, $self->{conf});

  my $body = $result->{id} ? "UID $user->{UID}, Invoice $result->{id}, sum $result->{sum}"
    : $result->{warning} ? "UID $user->{UID} $result->{warning}"
    : "UID $user->{UID} " . ($result->{errno} || '') . ' : ' . ($result->{errstr} || '');

  if ($self->{debug}) {
    print "$body\n";
  }

  $Ureports->log_add({
    DESTINATION => 'Privat invoice',
    BODY        => $body,
    UID         => $user->{UID},
    TP_ID       => $user->{TP_ID} || 0,
    REPORT_ID   => $user->{REPORT_ID} || 0,
    STATUS      => $result->{id} ? 1 : 0
  });

  return 1;
}

1;
