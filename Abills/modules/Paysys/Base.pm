package Paysys::Base;

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(cmd);

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

  my $self = {};

  require Paysys;
  Paysys->import();
  $Paysys = Paysys->new($db, $admin, $CONF);

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 payments_maked($attr) - Cross module payment maked

  Arguments:
    $attr
      USER_INFO
      SUM

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub payments_maked {
  my $self = shift;
  my ($attr) = @_;

  return 0 if (!$attr->{UID});

  require Conf;
  my $Config = Conf->new($db, $admin, $CONF);

  $Config->config_info({ PARAM => 'PAYSYS_EXTERNAL_PAYMENT_MADE_COMMAND' });

  return 0 if ($Config->{errno} || !$Config->{TOTAL});

  my $my_command = $Config->{VALUE};

  cmd($my_command, {
    PARAMS => { UID => $attr->{UID} }, ARGV => 1
  });

  return $self;
}

1;
