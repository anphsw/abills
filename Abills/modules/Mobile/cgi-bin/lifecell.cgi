#!/usr/bin/perl

=head1 NAME

  Mobile Lifecell callback cgi

=cut

use strict;
use warnings;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  @MODULES,
  %FORM,
  %COOKIES
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../libexec/config.pl';
  unshift(@INC,
    $Bin . '/../',
    $Bin . '/../lib/',
    $Bin . '/../Abills',
    $Bin . '/../Abills/mysql',
    $Bin . '/../Abills/modules',
  );

  foreach my $module (@MODULES) {
    unshift(@INC, $Bin . "/../Abills/modules/$module/config");
  }
}

use Abills::Defs;
use Abills::JSON;
use Admins;
use Abills::Base qw(json_former _bp check_ip);
use Mobile;
use Users;
use Tariffs;
use Fees;
require Abills::Misc;

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin = Admins->new($db, \%conf);
my $Mobile = Mobile->new($db, $admin, \%conf);
my $Tariffs = Tariffs->new($db, \%conf, $admin);
my $Fees = Fees->new($db, $admin, \%conf);

use Docs::Init qw(init_esign_service);
use JSON qw(decode_json);
our $html = Abills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
});

_start();

#**********************************************************
=head2 _start()

=cut
#**********************************************************
sub _start {

  my %res = (success => 'true');
  my $response_status = 200;

  my $res = json_former(\%res, { BOOL_VALUES => 1 });

  my $params = $FORM{__BUFFER} ? decode_json($FORM{__BUFFER}) : ();
  if (!$params) {
    print Abills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  my $user_info = $Mobile->user_list({
    TRANSACTION_ID  => $params->{transactionId},
    PHONE           => '_SHOW',
    UID             => '_SHOW',
    DISABLE         => '_SHOW',
    TP_DISABLE      => '_SHOW',
    TP_ID           => '_SHOW',
    EXTERNAL_METHOD => '!',
    COLS_NAME       => 1
  });

  if (!$Mobile->{TOTAL} || $Mobile->{TOTAL} < 1) {
    print Abills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  $user_info = $user_info->[0];

  $Mobile->log_change({
    TRANSACTION_ID           => $params->{transactionId},
    CALLBACK                 => json_former($params),
    CALLBACK_DATE            => "$DATE $TIME",
    CHANGE_BY_TRANSACTION_ID => 1
  });

  if ($user_info->{external_method} eq 'partnerP2CConfirm' || $user_info->{external_method} eq 'partnerActivationStandart') {
    if (defined $params->{resultCode} && (!$params->{resultCode} || $params->{resultCode} eq '000000')) {
      $Mobile->user_change({ DISABLE => 0, ID => $user_info->{id}, TRANSACTION_ID => '', EXTERNAL_METHOD => '', ACTIVATE => $DATE });
    }
    else {
      $Mobile->user_change({ ID => $user_info->{id}, TRANSACTION_ID => '', EXTERNAL_METHOD => '' });
    }
    print Abills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  if ($user_info->{external_method} eq 'partnerChangeC2P') {
    if (defined $params->{resultCode} && (!$params->{resultCode} || $params->{resultCode} eq '000000')) {
      $Mobile->user_change({
        DISABLE         => 1,
        TP_STATUS       => 1,
        TP_ID           => 0,
        ID              => $user_info->{id},
        TRANSACTION_ID  => '',
        EXTERNAL_METHOD => '',
        ACTIVATE        => '0000-00-00',
        TP_ACTIVATE     => '0000-00-00',
      });
    }
    else {
      $Mobile->user_change({ ID => $user_info->{id}, TRANSACTION_ID => '', EXTERNAL_METHOD => '' });
    }
    print Abills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  if ($user_info->{external_method} eq 'partnerOrderOffer') {
    if (defined $params->{resultCode} && (!$params->{resultCode} || $params->{resultCode} eq '000000')) {
      $Mobile->user_change({ ID => $user_info->{id}, TRANSACTION_ID => '', TP_STATUS => 0, TP_ACTIVATE => $DATE, EXTERNAL_METHOD => '' });
    }
    else {
      my $fees_info = $Fees->list({ INNER_DESCRIBE => $params->{transactionId}, UID => $user_info->{uid}, COLS_NAME => 1 });

      if ($Fees->{TOTAL} && $Fees->{TOTAL} > 0) {
        $Fees->del({ UID => $user_info->{uid} }, $fees_info->[0]{id});
      }
      $Mobile->user_change({ ID => $user_info->{id}, TRANSACTION_ID => '', EXTERNAL_METHOD => '', TP_STATUS => 1 });
    }
    print Abills::JSON::header(undef, { STATUS => $response_status });
    print $res;
    return;
  }

  print Abills::JSON::header(undef, { STATUS => $response_status });
  print $res;
}

1;