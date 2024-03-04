package Sms::Misc;

use strict;
use warnings FATAL => 'all';

=head1 NAME

  Sms::Misc

=cut

=head2 SYNOPSIS

  Sms miscellaneous functions

=cut

use Sms;
use Sms::Init;

#*******************************************************************
=head2 new() - init

=cut
#*******************************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $CONF) = @_;

  my $self = {};
  bless($self, $class);

  $self->{db} = $db;
  $self->{admin} = $admin;
  $self->{conf} = $CONF;

  return $self;
}

#**********************************************************
=head2 sms_status() - Request for sms status

=cut
#**********************************************************
sub sms_status {
  my ($self, $attr) = @_;

  my $debug = $attr->{DEBUG} || 0;

  do 'Abills/Misc.pm';
  print "Sms status\n" if ($debug > 1);
  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

  my $Sms_service = init_sms_service($self->{db}, $self->{admin}, $self->{conf});
  if ($Sms_service->{errno}) {
    return 0;
  }

  if ($Sms_service->can('get_status')) {
    my $list = $Sms->list({
      DATETIME   => '_SHOW',
      SMS_STATUS => 0,
      COLS_NAME  => 1,
      PAGE_ROWS  => 100000
    });

    foreach my $line ( @$list ) {

      if($debug > 1) {
        print "ID: $line->{id} DATE: $line->{datetime}\n";
      }

      $Sms_service->get_status({
        REF_ID => $line->{datetime},
        EXT_ID => ($line->{ext_id} ? $line->{ext_id} : $line->{id}),
        DEBUG  => $debug || 0,
      });

      if($debug > 1) {
        print "  STATUS: ". (defined($Sms_service->{status}) ? $Sms_service->{status} : 0) ."\n";
      }

      if (!$Sms_service->{errno}) {
        if ($Sms_service->{status} || $Sms_service->{list}->[0]{status}) {
          $Sms->change({
            ID     => $line->{id},
            STATUS => ($Sms_service->{status}) ? $Sms_service->{status} : $Sms_service->{list}->[0]{status}
          });
        }
      }
    }
  }

  return 1;
}

1;