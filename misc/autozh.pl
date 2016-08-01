#!/usr/bin/perl
=head1 NAME

  Auto zap/hangup console utility

=cut
#**********************************************************

use strict;

use vars qw( %conf
  $DATE
  $TIME
  $Log
  $db
);

use FindBin '$Bin';

my $debug   = 1;
my $VERSION = 0.20;

require $Bin . '/../libexec/config.pl';
unshift(@INC, $Bin . '/../', $Bin . '/../Abills', $Bin . "/../Abills/$conf{dbtype}");
require Abills::SQL;
Abills::SQL->import();
require Abills::Base;
Abills::Base->import();

my $begin_time = check_time();

require Admins;
Admins->import();

require Dv_Sessions;
Dv_Sessions->import();

require Nas;
Nas->import();

require $Bin . '/../Abills/nas.pl';

require Log;
Log->import('log_add');

my $ARGV = parse_arguments(\@ARGV);

if ($ARGV->{help}) {
  print << "[END]";

autozap.pl Version: $VERSION

  NAS_ID         - NAS ID for ZAP
  ACTION_EXPR=   - Extr for action (wildcard *)
  ACTION_COUNT=  - Count of some actions default 20
  LAST_ACTIONS_COUNT= - last history actions. default 250.
  NEGATIVE_DEPOSIT=1  - Hangup only with negtive deposit
  SLEEP=COUNT:TIME -  - Sleep after count of actions      -
  HANGUP=1       - Make Hangup
  LOGIN=...      - login for hangup
  COUNT=         - Hangup or zap records (Default: infinity)
  UID=...        - UID for hangup
  TP_ID=...      - TP_ID for hangup
  GID=...        - Group ID for hangup
  DEBUG=1..6     -
  help           - This help
[END]

  exit;
}

$debug = ($ARGV->{DEBUG}) ? $ARGV->{DEBUG} : $debug;

$db = Abills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

my $admin = Admins->new($db, \%conf);
$admin->info($conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' });

my $nas = Nas->new($db, \%conf);
$Log = Log->new($db, \%conf);
$Log->{PRINT} = 1;

my $Dv_sessions = Dv_Sessions->new($db, $admin, \%conf);
my %LIST_PARAMS = ();

if ($ARGV->{LOGIN}) {
  $LIST_PARAMS{USER_NAME} = $ARGV->{LOGIN};
}
elsif ($ARGV->{UID}) {
  $LIST_PARAMS{UID} = $ARGV->{UID};
}

if ($ARGV->{DURATION}) {
  $LIST_PARAMS{DURATION_SEC} = $ARGV->{DURATION};
}

if ($ARGV->{TP_ID}) {
  $LIST_PARAMS{TP_ID} = $ARGV->{TP_ID};
}

if ($ARGV->{GID}) {
  $LIST_PARAMS{GID} = $ARGV->{GID};
}

if ($ARGV->{COUNT}) {
  $LIST_PARAMS{PAGE_ROWS} = $ARGV->{COUNT};
  $LIST_PARAMS{LIMIT}     = $LIST_PARAMS{PAGE_ROWS};
}

$LIST_PARAMS{NAS_ID} = $ARGV->{NAS_ID} if ($ARGV->{NAS_ID});
my %ACCT_INFO = ();
my $count     = 0;

if ($debug > 1) {
  print "DATE: $DATE $TIME\n";
}

if ($ARGV->{HANGUP}) {
  if ($debug > 6) {
    $Dv_sessions->{debug} = 1;
  }

  $Dv_sessions->online(
    {
      USER_NAME       => '_SHOW',
      ACCT_SESSION_ID => '_SHOW',
      NAS_PORT_ID     => '_SHOW',
      NAS_IP          => '_SHOW',
      CLIENT_IP       => '_SHOW',
      CONNECT_INFO    => '_SHOW',
      CID             => '_SHOW',
      USER_NAME       => '_SHOW',
      UID             => '_SHOW',
      DEPOSIT         => '_SHOW',
      CREDIT          => '_SHOW',
      TP_CREDIT       => '_SHOW',
      %LIST_PARAMS
    }
  );

  my $online_list = $Dv_sessions->{nas_sorted};
  my $nas_list    = $nas->list({ COLS_NAME => 1 });
  my @results     = ();

  foreach my $nas_row (@$nas_list) {
    next if (!defined($online_list->{ $nas_row->{nas_id} }));
    $nas->info({ NAS_ID => $nas_row->{nas_id} });

    foreach my $line (@{ $online_list->{ $nas_row->{nas_id} } }) {

      $ACCT_INFO{ACCT_SESSION_ID}    = $line->{acct_session_id};
      $ACCT_INFO{NAS_PORT}           = $line->{nas_port_id};
      $ACCT_INFO{NAS_IP_ADDRESS}     = $nas_row->{nas_ip};
      $ACCT_INFO{FRAMED_IP_ADDRESS}  = $line->{client_ip};
      $ACCT_INFO{CONNECT_INFO}       = $line->{connection_info};
      $ACCT_INFO{CALLING_STATION_ID} = $line->{cid};
      $ACCT_INFO{USER_NAME}          = $line->{user_name};
      $ACCT_INFO{UID}                = $line->{uid};
      $ACCT_INFO{DEPOSIT}            = $line->{deposit};
      $ACCT_INFO{CREDIT}             = ($line->{credit} > 0) ? $line->{credit} : $line->{tp_credit};

      if (defined($ARGV->{NEGATIVE_DEPOSIT}) && $ACCT_INFO{DEPOSIT} + $ACCT_INFO{CREDIT} > 0) {
        print "1:INFO=Hangupped '$ACCT_INFO{USER_NAME}'" if ($ARGV->{LOGIN});
        next;
      }

      if ($debug > 1) {
        print "[$ACCT_INFO{UID}] $ACCT_INFO{USER_NAME} $ACCT_INFO{FRAMED_IP_ADDRESS} $ACCT_INFO{NAS_PORT} $ACCT_INFO{NAS_IP_ADDRESS} $ACCT_INFO{ACCT_SESSION_ID} $ACCT_INFO{CALLING_STATION_ID}\n";
      }

      if ($debug < 5) {
        my $ret = hangup(
          $nas,
          "$ACCT_INFO{NAS_PORT}",
          "$ACCT_INFO{USER_NAME}",
          {
            ACCT_SESSION_ID   => "$ACCT_INFO{ACCT_SESSION_ID}",
            FRAMED_IP_ADDRESS => "$ACCT_INFO{FRAMED_IP_ADDRESS}",
            UID               => $ACCT_INFO{UID},
            DEBUG             => ($debug > 1) ? $debug : 0
          }
        );

        #          if ($ret == 0) {
        if ($ARGV->{CREDIT}) {
          print "1:INFO=Hangupped '$ACCT_INFO{USER_NAME}'";
        }

        #           }
      }
      $count++;

      if ($ARGV->{SLEEP}) {
        my($action_count, $sleep_time) = split(/:/, $ARGV->{SLEEP});

        if ($count % $action_count == 0) {
          if ($debug > 1) {
            print "Sleep: $sleep_time ($count)\n";
          }
          sleep $sleep_time;
        }
      }

    }
  }
  if ($LIST_PARAMS{USER_NAME} && $Dv_sessions->{TOTAL} == 0) {
    print "1:INFO=Not online '$LIST_PARAMS{USER_NAME}'";
  }
}
elsif ($ARGV->{ACTION_EXPR}) {
  $ARGV->{LAST_ACTIONS_COUNT} = 250 if (!$ARGV->{LAST_ACTIONS_COUNT});
  $ARGV->{ACTION_COUNT}       = 20  if (!$ARGV->{ACTION_COUNT});

  if (!$LIST_PARAMS{NAS_ID}) {
    print "Error: Select NAS server\n";
    exit;
  }

  my $list = $Log->log_list(
    {
      MESSAGE   => "$ARGV->{ACTION_EXPR}",
      PAGE_ROWS => $ARGV->{LAST_ACTIONS_COUNT},
      %LIST_PARAMS
    }
  );
  if ($debug > 0) {
    foreach my $line (@$list) {
      print "$line->[4]\n";
    }
  }

  print "$nas->{OUTPUT_ROWS}\n" if ($debug > 0);
  if ($nas->{OUTPUT_ROWS} > $ARGV->{ACTION_COUNT}) {
    print "Zap sessins on: $LIST_PARAMS{NAS_ID}\n";
    goto ZAP_LABEL;
  }
}
else {
  ZAP_LABEL:
  $Dv_sessions->zap(0, 0, 0, {%LIST_PARAMS});
}


if ($debug > 0) {
  print "Total: $count\n";

  if ($begin_time > 0 && $debug > 1) {
    Time::HiRes->import(qw(gettimeofday));
    my $end_time = gettimeofday();
    my $gen_time = $end_time - $begin_time;
    printf(" GT: %2.5f\n", $gen_time);
  }
}

1

