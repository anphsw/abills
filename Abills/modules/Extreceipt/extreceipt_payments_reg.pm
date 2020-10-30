=head1 NAME

  Extreceipt billd plugin

=head1 ARGUMENTS

  PAYMENT_ID
  START    - Start payments ID
  CHECK
  FROM_DATE
  RESEND
  CANCEL
  PAGE_ROWS - List size of send documents
  SLEEP - Sleep in second after each send
  API_NAME - Use only one API

=cut

use strict;
use warnings FATAL => 'all';

our (
  %conf,
  $Admin,
  $db,
  $argv,
  $DATE,
  $TIME,
);

use Abills::Base qw(show_hash);
use Conf;
use Extreceipt::db::Extreceipt;

my $debug = 0;

my $Config = Conf->new($db, $Admin, \%conf);
my $Receipt = Extreceipt->new($db, $Admin, \%conf);

if ($argv->{DEBUG}) {
  $debug = $argv->{DEBUG};
  $Receipt->{debug}=1 if($debug > 4);
}

my $api_list = $Receipt->api_list();
my $Receipt_api = ();
foreach my $line (@$api_list) {
  my $api_name = $line->{api_name};

  if ($argv->{API_NAME} && $argv->{API_NAME} ne $api_name) {
    next;
  }

  if ($debug > 3) {
    print "API: $api_name\n";
  }

  if (eval {
    require "Extreceipt/API/$api_name.pm";
    1;
  }) {
    $Receipt_api->{$line->{api_id}} = $api_name->new(\%conf, $line);
    $Receipt_api->{$line->{api_id}}->{debug} = 1 if ($debug);
    if (!$Receipt_api->{$line->{api_id}}->init()) {
      $Receipt_api->{$line->{api_id}} = ();
    }
  }
  else {
    print $@;
    $Receipt_api->{$line->{api_id}} = ();
  }
}

my %params = ( PAGE_ROWS => 9999 );

if($argv->{PAYMENT_ID}) {
  $params{PAYMENT_ID}=$argv->{PAYMENT_ID};
}
elsif($argv->{FROM_DATE}) {
  $params{FROM_DATE}=$argv->{FROM_DATE}
}

if ($argv->{PAGE_ROWS}) {
  $params{PAGE_ROWS} = $argv->{PAGE_ROWS};
}

if ($argv->{CANCEL}) {
  cancel_payments($argv->{CANCEL});
}
elsif ($argv->{CHECK}) {
  check_receipts();
}
elsif ($argv->{RESEND}) {
  resend_errors();
}
else {
  check_receipts();
  check_payments();
  send_payments();
  resend_errors();
}

#exit 1;

#**********************************************************
=head2 check_payments()
  Checks whether new payments appear in the payments table.
??If there are new payments, they are entered into the Receipts_main table with the status 0.
=cut
#**********************************************************
sub check_payments {

  my $start_id = $argv->{START} || $conf{EXTRECEIPT_LAST_ID} || 1;
  $Receipt->get_new_payments($start_id);

  if ($Receipt->{error}) {
    print "ERROR: $Receipt->{error} $Receipt->{errstr}\n";
    return 0;
  }

  $Config->config_add({
    PARAM   => "EXTRECEIPT_LAST_ID",
    VALUE   => $Receipt->{LAST_ID},
    REPLACE => 1
  });

  return 1;
}

#**********************************************************
=head2 send_payments() - Sends all payments with status 0, status changes to 1.

=cut
#**********************************************************
sub send_payments {
  my $list = $Receipt->list({
    STATUS    => 0,
    %params
  });

  foreach my $line (@$list) {
    next if (!$Receipt_api->{$line->{api_id}});
    $line->{phone} =~ s/[^0-9\+]//g;
    if (!$line->{mail} && !$line->{phone}) {
      $line->{mail} = $line->{uid} . '@myisp.ru';
    }
    my $command_id = $Receipt_api->{$line->{api_id}}->payment_register($line);

    if ($command_id) {
      $Receipt->change({
        PAYMENTS_ID => $line->{payments_id},
        COMMAND_ID  => $command_id,
        STATUS      => 1
      });
    }

    if ($argv->{SLEEP}) {
      sleep int($argv->{SLEEP});
    }
  }
  return 1;
}

#**********************************************************
=head2 cancel_payments($id) -  Cancel payment, set status 3

=cut
#**********************************************************
sub cancel_payments {
  my ($id) = @_;
  my $info = $Receipt->info($id);
  return 1 if (!$Receipt_api->{$info->[0]{api_id}});
  my $command_id = $Receipt_api->{$info->[0]{api_id}}->payment_cancel($info->[0]);
  if ($command_id) {
    $Receipt->change({ PAYMENTS_ID => $id, CANCEL_ID => $command_id, STATUS => 3 });
  }
  return 1;
}

#**********************************************************
=head2 check_receipts()
  Checks the status of previously sent payments with status 1.
??If a check is made for them, it changes the status to 2, and fills with the ID check.
=cut
#**********************************************************
sub check_receipts {

  my $list;

  if ($argv->{CHECK}) {
    $list = $Receipt->info($argv->{CHECK});
  }
  else {
    $list = $Receipt->list({
      %params,
      STATUS    => 1
    });
  }

  foreach my $line (@$list) {
    if ($debug > 7) {
      print show_hash($line);
      print "\n";
      next;
    }

    next if (!$Receipt_api->{$line->{api_id}});
    my $Receipt_info = $Receipt_api->{$line->{api_id}};
    # next if ($line->{api_name} eq 'Atol');
    my ($fdn, $fda, $date, $payments_id, $error) = $Receipt_info->get_info($line);
    $payments_id ||= $line->{payments_id};

    print "GET_INFO: $payments_id (FDN: $fdn FDA: $fda, DATE: ". ($date || q{n/d}) ." PAYMENT_ID: $payments_id ERROR: $error)\n" if($debug > 1);
    if ($error) {
      if($Receipt_info->{error} && $Receipt_info->{error} == 1) {
        print "ERROR: $Receipt_info->{error} PAYMENT_ID: $payments_id ";
        if($Receipt_info->{errstr}) {
          print $Receipt_info->{errstr};
        }
        print "\n";
        next;
      }

      if ($payments_id =~ m/\-e/) {
        $payments_id =~ s/\-e//;
        $Receipt->change({
          PAYMENTS_ID => $payments_id,
          STATUS      => 5,
        });
      }
      else {
        $Receipt->change({
          PAYMENTS_ID => $payments_id,
          STATUS      => 4,
        });
      }
      next;
    }

    $payments_id =~ s/\-e//;
    $date =~ s/T/ /;
    $date =~ s/\+.*//;
    if ($fda) {
      $Receipt->change({
        PAYMENTS_ID  => $payments_id,
        FDN          => $fdn,
        FDA          => $fda,
        RECEIPT_DATE => $date,
        STATUS       => 2,
      });
    }
  }

  return 1;
}

#**********************************************************
=head2 resend_errors() - Resend payments with status 4, status changes to 1.


=cut
#**********************************************************
sub resend_errors {

  my $list = $Receipt->list({ STATUS => 4, %params });

  foreach my $line (@$list) {
    next if (!$Receipt_api->{$line->{api_id}});
    if (!$line->{mail} && !$line->{phone}) {
      $line->{mail} = $line->{uid} . '@myisp.ru';
    }
    $line->{payments_id} .= "-e";
    my $command_id = $Receipt_api->{$line->{api_id}}->payment_register($line);
    if ($command_id) {
      $Receipt->change({ PAYMENTS_ID => $line->{payments_id}, COMMAND_ID => $command_id, STATUS => 1 });
    }
  }

  return 1;
}

1;