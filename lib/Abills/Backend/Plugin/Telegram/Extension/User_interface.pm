#!/usr/bin/perl

package Abills::Backend::Plugin::Telegram::Extension::User_interface;
use strict;
use warnings FATAL => 'all';

=head2 NAME

  Abills::Backend::Plugin::Telegram::Extension::Example
  
=head2 SYNOPSIS

  UI for ABillS Telegram bot.
   
=cut
BEGIN {
  unshift(@INC, '/usr/abills/lib/');
}
our ($db, $admin, %conf, $base_dir, $Pub);

use Abills::Backend::Log;
use Abills::Backend::Defs;
use Abills::Backend::Plugin::Telegram;
use Abills::Backend::Plugin::Telegram::Extension;
use parent 'Abills::Backend::Plugin::Telegram::Extension';
use POSIX qw/strftime/;

use Abills::Backend::Plugin::Telegram::Operation;

use Internet;
use Users;
my $Internet = Internet->new($db, $admin, \%conf);
my $Users = Users->new($db, $admin, \%conf);

my $EXTENSION = 'User_interface';

my Abills::Backend::Log $Log =
  Abills::Backend::Plugin::Telegram::Extension::build_log_for(
    $EXTENSION,
    '/usr/abills/var/log/telegram_example.log'
  );

#**********************************************************
=head2 add_extensions()

=cut
#**********************************************************
sub add_extensions {
  my Abills::Backend::Plugin::Telegram $Telegram_Bot = shift;
  
  $Telegram_Bot->add_callback('/info', sub {
    
    my ($first_message, $chat_id, $client_type, $client_id) = @_;

    if ($client_type eq 'AID') {
      $Telegram_Bot->send_text("Sorry, only for users.", $chat_id);
      return 1;
    };

    my $list = $Users->list({
      UID       => $client_id,
      LOGIN     => '_SHOW',
      DEPOSIT   => '_SHOW',
      CREDIT    => '_SHOW',
      FIO       => '_SHOW',
      DISABLE   => '_SHOW',
      COLS_NAME => 1,
    });

    $Internet->info($client_id);
    $Users->info($client_id);
    
    my $message = "_{USER}_: " . ($list->[0]->{fio} || $list->[0]->{login} ) . "\n";
    if ($list->[0]->{deposit} < 0) {
      $message .= "_{NEGATIVE_DEPOSIT}_.\n";
    }
    $message .= "_{DEPOSIT}_: " . ($list->[0]->{deposit} || '' ) . "\n\n";
    
    $message .= "_{TARIF_PLAN}_: " . $Internet->{TP_NAME} . "\n";
    $message .= next_payments($client_id) . "\n" if($list->[0]->{deposit} >= 0);
    
    $message .= "\n_{HELP}_ /help\n";

    $Telegram_Bot->send_text($message, $chat_id);
  });
  
  $Telegram_Bot->add_callback('/help', sub {
    my ($first_message, $chat_id, $client_type, $client_id) = @_;

    my $message = "_{MENU}_:\n\n";
    $message .= "/help   - _{HELP}_\n\n";
    $message .= "/info   - _{INFO}_\n\n";
    $message .= "/credit - _{CREDIT}_\n\n";
    $message .= "/chg_tp - _{CHANGE_}_ _{TARIF_PLAN}_\n\n";

    $Telegram_Bot->send_text($message, $chat_id);
  });


  #cccccccccccccccccccccccccc#
  
  # $Pub->on('user_authenticated', sub {
  #   my ($chat_id) = @_;
  #   $Telegram_Bot->send_text("Welcome to your personal menu.", $chat_id, {
  #     reply_markup => {
  #       keyboard => [
  #         [{ text => 'Информация' }, { text => 'Сменить тариф' }],
  #         [{ text => 'Кредит' }, { text => 'Отключение услуги' }],
  #       ],
  #       resize_keyboard => \1
  #     }
  #   });
  # });
  
  return 1;
}


sub next_payments {
  my ($uid) = @_;
  my $DATE = strftime "%Y-%m-%d", localtime(time);
  my ($year, $month, $day) = split(/-/, $DATE, 3);

  if($Internet->{PERSONAL_TP} && $Internet->{PERSONAL_TP} > 0) {
    $Internet->{MONTH_ABON} = $Internet->{PERSONAL_TP};
  }
  
  my $reduction_division = ($Users->{REDUCTION} >= 100) ? 0 : ((100 - $Users->{REDUCTION}) / 100);
  return "\n" unless ($reduction_division * );

  return "\n" if (!$Internet->{MONTH_ABON} && !$Internet->{DAY_ABON});

  if ($Internet->{ABON_DISTRIBUTION} && $Internet->{MONTH_ABON} > 0) {
    $Internet->{DAY_ABON} ||= 0;
    $Internet->{DAY_ABON} += $Internet->{MONTH_ABON} / 30;
  }

  if ($Internet->{DAY_ABON} && $Internet->{DAY_ABON} > 0) {
    my $days = int(($Users->{DEPOSIT} + $Users->{CREDIT} > 0) ?  ($Users->{DEPOSIT} + $Users->{CREDIT}) / ($Internet->{DAY_ABON} * $reduction_division) : 0);
    my $str = "Услуга завершится через $days дней.";
    return "$str\n";
  }

  my $payment_date = '';
  my $activate_day = (split(/-/, $Users->{ACTIVATE}, 3))[2];
  $activate_day = 0 if ($activate_day eq '00');
  my $payment_day = $activate_day || $conf{START_PERIOD_DAY} || 1;
  if ($payment_day <= $day) {
    $year++ if ($month == 12);
    $month = $month % 12;
    $month++;
  }
  $payment_date = sprintf("%02d.%02d.%04d", $payment_day, $month, $year);

  my $message = "_{NEXT_FEES}_ $payment_date\n";
  $message .= "_{SUM}_: " . int($Internet->{MONTH_ABON} * $reduction_division) if ($Internet->{MONTH_ABON});
  return $message;
}


1;