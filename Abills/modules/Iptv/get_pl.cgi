#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

BEGIN {
  our $Bin;
  use FindBin '$Bin';
  if ($Bin =~ m/\/abills(\/)/) {
    our $libpath = substr($Bin, 0, $-[1]);
    unshift(@INC, "$libpath/lib");
  }
  else {
    die " Should be inside /usr/abills dir \n";
  }
}

our (
  %lang,
);

use Abills::Init qw/$db $admin %conf/;
use Abills::Defs;
use Abills::HTML;
use Abills::Base qw(_bp);
use Log qw(log_add log_print);
use Iptv;
require Abills::Misc;
require Iptv::User_portal;
require Iptv;

our $DATE = strftime("%Y-%m-%d", localtime(time));
our $TIME = strftime("%H:%M:%S", localtime(time));

our $html = Abills::HTML->new(
  {
    CONF     => \%conf,
    NO_PRINT => 0,
    PATH     => $conf{WEB_IMG_SCRIPT_PATH} || '../',
    CHARSET  => $conf{default_charset},
    LANG     => \%lang,
  }
);

if($html->{language} ne 'english') {
  do $libpath . "/language/english.pl";
}

if(-f $libpath . "/language/$html->{language}.pl") {
  do $libpath."/language/$html->{language}.pl";
}

my $Iptv = Iptv->new($db, $admin, \%conf);
my $Log = Log->new($db, \%conf);

if ($FORM{type}) {
  print "Content-type:text/html\n\n";
  if ($FORM{type} eq 'user') {
    check_user(\%FORM);
  }
  elsif ($FORM{type} eq 'tp') {
    show_user_tp(\%FORM);
  }
  exit;
}

if ($conf{IPTV_PASSWORDLESS_ACCESS} && $ENV{REMOTE_ADDR}) {

  my $iptv_online = $Iptv->online(
    {
      FRAMED_IP_ADDRESS => $ENV{REMOTE_ADDR},
      TP_ID             => '_SHOW',
      COLS_NAME         => 1,
      PAGE_ROWS         => 1,
    }
  );
  _error_show($Iptv);

  if (!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{tp_id}) {
    print "Content-type:text/html\n\n";
    print $html->element('h3', 'WARNING') . $html->element('p', 'This address ' . $ENV{REMOTE_ADDR} . ' is not connected to the TP');
    $Log->log_print('LOG_WARNING', '', 'Address ' . $ENV{REMOTE_ADDR} . ' not connected to the TP', { ACTION => 'AUTH' });
    exit;
  }
  else {
    $FORM{m3u_download} = 1;
    iptv_m3u($iptv_online->[0]->{tp_id});
  }
  exit;
}

#Folclor
if ($FORM{ip} || $FORM{phone} || $FORM{mbr_id}) {
  print "Content-type:text/html\n\n";
  check_user(\%FORM);
  exit;
}

if ($FORM{user_id} || $FORM{sum} || $FORM{cont_id} || $FORM{trf_id} || $FORM{message} || $FORM{start}) {
  print "Content-type:text/html\n\n";
  transfer_service(\%FORM);
  exit;
}

if (!$FORM{mac} && !$FORM{pin}) {
  print "Content-type:text/html\n\n";
  print $html->element('h3', 'WARNING') . $html->element('p', 'No mac or pin specified. No user found');
  exit;
}

if ($FORM{mac}) {
  $FORM{mac} =~ s/_SHOW//;
  $FORM{mac} =~ s/\*//;
}

if ($FORM{pin}) {
  $FORM{pin} =~ s/_SHOW//;
  $FORM{pin} =~ s/\*//;
}

my $iptv_list = $Iptv->user_list(
  {
    CID            => $FORM{mac},
    PIN            => $FORM{pin},
    SERVICE_STATUS => '_SHOW',
    LOGIN          => '_SHOW',
    TP_ID          => '_SHOW',
    DEPOSIT        => '_SHOW',
    CREDIT         => '_SHOW',
    COLS_NAME      => 1,
    PAGE_ROWS      => 1,
  }
);
_error_show($Iptv);

if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list)) {
  print "Content-type:text/html\n\n";
  if ($FORM{mac}) {
    print $html->element('h3', 'WARNING') . $html->element('p', 'Wrong CID:' . $FORM{mac} . '. No user found');
    $Log->log_print('LOG_WARNING', '', "Wrong CID: $FORM{mac}. No user found", { ACTION => 'AUTH' });
  }
  elsif ($FORM{pin}) {
    print $html->element('h3', 'WARNING') . $html->element('p', 'Wrong PIN:' . $FORM{pin} . '. No user found');
    $Log->log_print('LOG_WARNING', '', "Wrong PIN: $FORM{pin}. No user found", { ACTION => 'AUTH' });
  }
  exit 0;
}

my $service = $iptv_list->[0];
if (!$service->{login} || !$service->{tp_id}) {
  print "Content-type:text/html\n\n";
  print $html->element('h3', 'WARNING') . $html->element('p',
    'TP_ID:' . $service->{tp_id} . '. No activated service');
  $Log->log_print('LOG_WARNING', $service->{login},
    "TP_ID: $service->{tp_id}. No activated service", { ACTION => 'AUTH' });
}

# service_status 1 means it is disabled
if ($service->{service_status}) {
  $Log->log_print('LOG_WARNING', $service->{login},
    "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
}
if (($service->{deposit} + $service->{credit}) <= 0) {
  $Log->log_print('LOG_WARNING', $service->{login},
    "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
}
else {
  $FORM{m3u_download} = 1;
  iptv_m3u($service->{tp_id});
}

#**********************************************************
=head2 check_user($attr) - search uid by ip or uid

  Arguments:
    $attr{ip}  - user ip
    $attr{uid} - user ip

  Returns:
   UID

  Example:

    check_user(/%FORM);

=cut
#**********************************************************
sub check_user {
  my ($params) = @_;

  my %result = ();

  if ($params->{uid} || $params->{mbr_id}) {
    my $iptv_list = $Iptv->user_list(
      {
        UID            => $params->{uid} || '_SHOW',
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        SUBSCRIBE_ID   => $params->{mbr_id} || '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    _error_show($Iptv);

    if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list) || !$iptv_list->[0]->{uid}) {
      $result{status} = '-1';
      $result{err} = '-1';
      $result{errmsg} = "User is not found";
      #      $Log->log_print('LOG_WARNING', '', 'No user found', { ACTION => 'AUTH' });
      print _json_former(\%result);
      exit;
    }

    my $service = $iptv_list->[0];
    # service_status 1 means it is disabled
    if ($service->{service_status}) {
      $result{ERROR} .= "SERVICE_STATUS: $service->{service_status}. No activated service. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
    }
    if (($service->{deposit} + $service->{credit}) <= 0) {
      $result{ERROR} .= "DEPOSIT: $service->{deposit}. Too small deposit. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
    }

    $result{user_id} = $service->{uid};
  }
  elsif ($params->{ip}) {

    my $iptv_online = $Iptv->online(
      {
        FRAMED_IP_ADDRESS => $params->{ip},
        UID               => '_SHOW',
        COLS_NAME         => 1,
        PAGE_ROWS         => 1,
      }
    );

    if (!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{uid}) {
      $result{ERROR} .= 'Address ' . $params->{ip} . ' is not connected to any uid';
      $Log->log_print('LOG_WARNING', '', 'Address ' . $params->{ip} . ' not connected to any uid', { ACTION => 'AUTH' });
    }
    else {
      $result{UID} = $iptv_online->[0]->{uid};
    }
  }

  print _json_former(\%result);
}

#**********************************************************
=head2 show_user_tp($attr) - search tp by ip or uid

  Arguments:
    $attr{ip}  - user ip
    $attr{uid} - user ip

  Returns:
   UID

  Example:

    show_user_tp(/%FORM);

=cut
#**********************************************************
sub show_user_tp {
  my ($params) = @_;

  my %result = ();

  if ($params->{uid} || $params->{user_id}) {
    $iptv_list = $Iptv->user_list(
      {
        UID            => $params->{user_id} || $params->{uid},
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    _error_show($Iptv);

    if (!$iptv_list || ref $iptv_list ne 'ARRAY' && !scalar(@$iptv_list) || !$iptv_list->[0]->{tp_id}) {
      $result{ERROR} .= 'Wrong UID. No user found. ';
      $Log->log_print('LOG_WARNING', '', 'No user found', { ACTION => 'AUTH' });
      print _json_former(\%result);
      exit;
    }

    $service = $iptv_list->[0];
    # service_status 1 means it is disabled
    if ($service->{service_status}) {
      $result{ERROR} .= "SERVICE_STATUS: $service->{service_status}. No activated service. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "SERVICE_STATUS: $service->{service_status}. No activated service. ", { ACTION => 'AUTH' });
    }
    if (($service->{deposit} + $service->{credit}) <= 0) {
      print "OKK";
      $result{ERROR} .= "DEPOSIT: $service->{deposit}. Too small deposit. ";
      $Log->log_print('LOG_WARNING', $service->{login},
        "DEPOSIT: $service->{deposit}. Too small deposit. ", { ACTION => 'AUTH' });
    }
    else {
      print "12222";
    }
  }
  #  elsif($params->{ip}){
  #
  #    my $iptv_online = $Iptv->online(
  #      {
  #        FRAMED_IP_ADDRESS => $params->{ip},
  #        UID               => '_SHOW',
  #        COLS_NAME         => 1,
  #        PAGE_ROWS         => 1,
  #      }
  #    );
  #
  #    if(!$iptv_online || ref $iptv_online ne 'ARRAY' && !scalar(@$iptv_online) || !$iptv_online->[0]->{tp_id}){
  #      $result{ERROR} .= 'Address ' . $params->{ip} . ' is not connected to any tp';
  #      $Log->log_print('LOG_WARNING', '', 'Address ' . $params->{ip} . ' is not connected to any tp', { ACTION => 'AUTH' });
  #    }
  #    else{
  #      $result{TP_ID} = $iptv_online->[0]->{tp_id};
  #    }
  #  }

  print _json_former(\%result);
}

#**********************************************************
=head2 _json_former($request) - hash2json

=cut
#**********************************************************
sub _json_former {
  my ($request) = @_;
  my @text_arr = ();

  if (ref $request eq 'ARRAY') {
    foreach my $key (@{$request}) {
      push @text_arr, _json_former($key);
    }
    return '[' . join(', ', @text_arr) . "]";
  }
  elsif (ref $request eq 'HASH') {
    foreach my $key (keys %{$request}) {
      my $val = _json_former($request->{$key});
      push @text_arr, qq{\"$key\":$val};
    }
    return '{' . join(', ', @text_arr) . "}";
  }
  else {
    $request //= '';
    if ($request =~ '^[0-9]$') {
      return qq{$request};
    }
    else {
      return qq{\"$request\"};
    }
  }
}

#**********************************************************
=head2 transfer_service($attr)

  Arguments:
    $attr{user_id}  - user ip
    $attr{sum} - user ip
    $attr{cont_id}
    $attr{trf_id}
    $attr{message}
    $attr{start}

  Returns:
   UID

  Example:

    transfer_service(/%FORM);

=cut
#**********************************************************
sub transfer_service {
  my ($params) = @_;

  my %result = ();
  my $tarrifs = ();

  if ($params->{user_id}) {
    $iptv_list = $Iptv->user_info($params->{user_id});
    _error_show($Iptv);

    if (!$iptv_list) {
      $result{status} = '-1';
      print _json_former(\%result);
      exit;
    }

    my $iptv_user = $Iptv->user_list(
      {
        ID             => $iptv_list->{ID},
        LOGIN          => '_SHOW',
        SERVICE_STATUS => '_SHOW',
        DEPOSIT        => '_SHOW',
        CREDIT         => '_SHOW',
        TP_ID          => '_SHOW',
        COLS_NAME      => 1,
        PAGE_ROWS      => 1,
      }
    );
    $service = $iptv_user->[0];

    if (($service->{deposit} + $service->{credit}) <= 0) {
      $result{status} = '-2';
      print _json_former(\%result);
      exit;
    }
    else {
      require Tariffs;
      Tariffs->import();
      my $Tariffs = Tariffs->new($db, \%conf, $admin);

      $tarrifs = $Tariffs->list({
        NAME        => "_SHOW",
        ACTIV_PRICE => "_SHOW",
        MODULE      => 'Iptv',
        SERVICE_ID  => $iptv_list->{SERVICE_ID},
        FILTER_ID   => $params->{trf_id},
        COLS_NAME   => 1
      });

      $Iptv->{TP_INFO}->{PERIOD_ALIGNMENT} = $Iptv->{PERIOD_ALIGNMENT} || 0;
      $Iptv->{TP_INFO}->{MONTH_FEE} = $Iptv->{MONTH_FEE};
      $Iptv->{TP_INFO}->{DAY_FEE} = $Iptv->{DAY_FEE};
      $Iptv->{TP_INFO}->{TP_ID} = $Iptv->{TP_ID};
      $Iptv->{TP_INFO}->{ABON_DISTRIBUTION} = $Iptv->{ABON_DISTRIBUTION};
      $Iptv->{TP_INFO}->{ACTIV_PRICE} = $tarrifs->[0]{activate_price};

      my $temp = service_get_month_fee($Iptv, {
        SERVICE_NAME => $iptv_list->{SERVICE_MODULE},
        QUITE        => 1,
      });
    }
  }

  $result{id} = $Iptv->{FEES_ID}[0] || 0;
  $result{status} = '1';
  print _json_former(\%result);

  return 1;
}


1;

