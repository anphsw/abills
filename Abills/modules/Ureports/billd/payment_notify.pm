=head1 NAME

  billd plugin

=head2  DESCRIBE

  Payments notification plugins

=head2 EXAMPLE

  billd payment_notify DEBUG=1

=head2 PARAMS

  SUM=<>[0-9]    - Sum for notification
  NOTIFY_PERIOD  - Notify period in hours
  DEPOSIT=<>[0-9]- User deposit
  LIMIT          - Row limit

=cut
#**********************************************************

use strict;
use warnings FATAL => 'all';
use Nas;
use Abills::Base qw();
use Payments;
use Users;
use Ureports::Base;
require Abills::Templates;

our (
  $debug,
  %conf,
  $admin,
  $db,
  $OS,
  $argv,
  %LIST_PARAMS,
  %lang,
  $DATE,
  $TIME
);



payments_notify($argv);

#**********************************************************
=head2 payments_notify()

=cut
#**********************************************************
sub payments_notify {
  my ($attr) = @_;

  my ($Y, $M, $D) = split(/-/, $DATE, 3);
  my $html = Abills::HTML->new({ CONF => \%conf, LANG => \%lang });
  my $Ureports_base = Ureports::Base->new($db, $admin, \%conf, { HTML => $html, LANG => \%lang });
  my $REPORT_ID = $attr->{REPORT_ID} || 100;

  $LIST_PARAMS{COLS_NAME}=1;
  $LIST_PARAMS{DATETIME}='_SHOW';
  $LIST_PARAMS{SUM}='_SHOW';

  my $Payments = Payments->new($db, $admin, \%conf);
  if ($debug > 5) {
    $Payments->{debug}=1
  }

  if ($attr->{SUM}) {
    $LIST_PARAMS{SUM}=$attr->{SUM};
  }

  if ($attr->{DEPOSIT}) {
    $LIST_PARAMS{DEPOSIT}=$attr->{DEPOSIT};
  }

  if ($attr->{LIMIT}) {
    $LIST_PARAMS{PAGE_ROWS}=$attr->{LIMIT};
  }

  if ($attr->{NOTIFY_PERIOD}) {
    $attr->{NOTIFY_PERIOD}="";
  }

  my $payments_list = $Payments->list({ %LIST_PARAMS });

  my $cols = $Payments->{COL_NAMES_ARR};

  foreach my $pay ( @$payments_list ) {
    if ($debug) {
      foreach my $col (@$cols) {
        print "$col: " . ($pay->{$col} || q{}) . " ";
      }
      print "\n";
    }

    print "$REPORT_ID\n";
    my $ureports_template =  'ureports_report_' . $REPORT_ID;
    #Send reports section
    my $send_status = $Ureports_base->ureports_send_reports(
      'Mail,Push', # 9, 10
      '', #$user->{DESTINATION_ID},
      '',
      {
        #%{$user},
        #%PARAMS,
        SUBJECT         => '',
        REPORT_ID       => $REPORT_ID,
        UID             => $pay->{uid},
        #TP_ID           => $user->{TP_ID},
        #MESSAGE         => $PARAMS{MESSAGE},
        DATE            => "$DATE $TIME",
        METHOD          => 1,
        MESSAGE_TEPLATE => $ureports_template,
        DEBUG           => $debug,
        Y               => $Y,
        M               => $M,
        D               => $D
      }
    );

  }

  print "Send report";
  print "$REPORT_ID\n";

  return 1;
}

1;