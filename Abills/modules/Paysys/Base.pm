package Paysys::Base;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(cmd sendmail);

my Abills::HTML $html;

my ($admin, $CONF, $db);
my Paysys $Paysys;

#**********************************************************
=head2 new($db, $admin, $CONF, $attr)

  Arguments:
    $db
    $admin
    $CONF
    $attr
      HTML
      LANG

=cut
#**********************************************************
sub new {
  my $class = shift;
  $db = shift;
  $admin = shift;
  $CONF = shift;
  my $attr = shift;

  my $self = {};

  require Paysys;
  Paysys->import();
  $Paysys = Paysys->new($db, $admin, $CONF);

  $html = $attr->{HTML} if $attr->{HTML};

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 paysys_payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub paysys_payments_maked {
  my $self = shift;
  my ($attr) = @_;

  $attr->{UID} //= $attr->{USER_INFO}->{UID} if ($attr->{USER_INFO});

  return 0 if (!$attr->{UID} || !$attr->{PAYSYS_PAYMENT});

  my Users $Users;
  if ($attr->{USER_INFO}) {
    $Users = $attr->{USER_INFO};
  }
  else {
    require Users;
    Users->import();
    $Users = Users->new($db, $admin, $CONF);
    $Users->info($attr->{UID});
  }

  #Send mail
  if ($CONF->{PAYSYS_EMAIL_NOTICE} || $CONF->{PAYSYS_EXTERN_SYNC}) {
    my $payment_system = $attr->{PAYSYS_PAYMENT}->{PAYMENT_SYSTEM} // '';
    my $ext_id = $attr->{PAYSYS_PAYMENT}->{EXT_ID} // '';
    ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Abills/Templates.pm'}));

    # define properties
    $Users->pi({ UID => $attr->{UID} });

    my $message = $main::html->tpl_show(main::_include('paysys_mail_admin_notification', 'Paysys'), {
      %{$attr->{PAYSYS_PAYMENT} || {}},
      %$Users,
      %$attr,
      PAYMENT_SYSTEM => $payment_system,
      DATE           => $main::DATE,
      TIME           => $main::TIME,
      SUM            => $attr->{SUM} || 0,
      REQUEST        => $ext_id,
    }, { OUTPUT2RETURN => 1 });

    sendmail($CONF->{ADMIN_MAIL}, $CONF->{ADMIN_MAIL}, "$payment_system ADD", "$message", $CONF->{MAIL_CHARSET}, '2 (High)');
  }

  require Conf;
  Conf->import();
  my $Config = Conf->new($db, $admin, $CONF);

  $Config->config_info({ PARAM => 'PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND' });

  return 0 if ($Config->{errno} || !$Config->{TOTAL});

  my $my_command = $Config->{VALUE};

  cmd($my_command, {
    PARAMS => { UID => $attr->{UID} }, ARGV => 1
  });

  return $self;
}

#**********************************************************
=head2 payment_del($attr) - Cross module payment deleted

  Arguments:
    $attr
      PAYMENT_ID
      UID

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub paysys_payment_del {
  my $self = shift;
  my ($attr) = @_;

  return 0 if (!$attr->{ID});
  return 0 if (!$attr->{PAYMENT_INFO} || !$attr->{PAYMENT_INFO}->{EXT_ID});

  my $transaction = $Paysys->list({
    TRANSACTION_ID => $attr->{PAYMENT_INFO}->{EXT_ID},
    UID            => $attr->{PAYMENT_INFO}->{UID},
    COLS_NAME      => 1,
    SKIP_DEL_CHECK => 1,
    SKIP_DOMAIN    => 1
  });

  return 0 if ($Paysys->{errno} || !scalar @{$transaction});

  $Paysys->del($transaction->[0]->{id} || '--');

  return $self;
}

1;
