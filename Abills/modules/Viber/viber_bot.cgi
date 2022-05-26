#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';

use JSON qw/decode_json/;
use Encode qw/encode_utf8/;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang,
  %FORM
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../../libexec/config.pl';

  $conf{VIBER_LANG} = 'russian' unless($conf{VIBER_LANG});

  do $Bin . "/../../language/$conf{VIBER_LANG}.pl";
  do $Bin . "/../../Abills/modules/Viber/lng_$conf{VIBER_LANG}.pl";

  unshift(@INC,
    $Bin . '/../../',
    $Bin . '/../../lib/',
    $Bin . '/../../Abills',
    $Bin . '/../../Abills/mysql',
    $Bin . '/../../Abills/modules',
    $Bin . '/../../Abills/modules/Viber',
  );
}

use Abills::SQL;
use Admins;
use Users;
use Contacts;
use Vauth;
use Buttons;
use API::Botapi;
use db::Viber;
require Abills::Misc;

our $db = Abills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin    = Admins->new($db, \%conf);
our $Users    = Users->new($db, $admin, \%conf);
our $Contacts = Contacts->new($db, $admin, \%conf);
our $Bot_db   = Viber->new($db, $admin, \%conf);

my $hash = ();
our $Bot = ();

print "Content-type:text/html\n\n";

$ENV{REQUEST_METHOD} =~ tr/a-z/A-Z/ if ($ENV{REQUEST_METHOD});
if ($ENV{REQUEST_METHOD} && $ENV{REQUEST_METHOD} eq 'POST') {
  my $buffer = '';
  read(STDIN, $buffer, $ENV{CONTENT_LENGTH});

  $hash = decode_json($buffer);

  return 0 unless ($hash && ref($hash) eq 'HASH' && $hash->{event});

  my $id = $hash->{user}{id} || $hash->{sender}{id} || '';

  my $bot_addr = "https://" . ($ENV{SERVER_NAME} || $ENV{SERVER_ADDR}) . ":$ENV{SERVER_PORT}";
  $Bot = Botapi->new($conf{VIBER_TOKEN}, $id, $bot_addr);
}

$Bot->{lang} = \%lang;
my %buttons_list = %{buttons_list({bot => $Bot})};
my %commands_list = reverse %buttons_list;

message_process();

return 1;

#**********************************************************
=head2 message_process()

=cut
#**********************************************************
sub message_process {
  my $uid = get_uid($hash->{user}{id} || $hash->{sender}{id});
  my $aid = get_aid($hash->{user}{id} || $hash->{sender}{id});
  if (!$uid && !$aid) {
    if ($hash->{event} && $hash->{event} =~ m/^conversation_started/) {
      subscribe($hash);
    }
    return 1;
  }

  $Bot->{uid} = $uid;
  my $text    = $hash->{message}{text} ? encode_utf8($hash->{message}{text}) : '';

  my $info = $Bot_db->info($uid);

  if ($commands_list{$text}) {
    my $ret = viber_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
      bot    => $Bot,
    });
    main_menu({ NO_MSG => 1 }) if ($ret ne 'NO_MENU');
  } else {
    if ($hash->{event} && $hash->{event} =~ m/^message/) {
      if ($text =~ /fn:([A-z 0-9 _-]*)&(.*)/) {
        my @args = split /&/, $2;
        my $fn = shift @args;
        my $ret = viber_button_fn({
          button    => $1,
          fn        => $fn,
          argv      => \@args,
          bot       => $Bot,
          step_info => $info,
        });

        if ($ret ne 'MAIN_MENU') {
          main_menu({ NO_MSG => 1 });
          return 1;
        }

        viber_button_fn({
          button => $1,
          fn     => 'click',
          NO_MSG => 1,
          bot    => $Bot,
        }) if ($ret ne 'NO_MENU');
      }
      elsif ($Bot_db->{TOTAL} > 0 && $info->{fn}
        && $info->{fn} =~ /fn:([A-z 0-9 _-]*)&(.*)/) {

        my @args = split /&/, $2;
        viber_button_fn({
          button    => $1,
          fn        => $2,
          bot       => $Bot,
          text      => $text,
          argv      => \@args,
          message   => $hash->{message},
          bot_db    => $Bot_db,
          step_info => $info,
        });
      }
      elsif ($text eq 'MENU') {
        main_menu({ NO_MSG => 1 });
      }
      else {
        main_menu();
      }
    }
  }

  return 1;
}

#**********************************************************
=head2 main_menu()

=cut
#**********************************************************
sub main_menu {
  my ($attr) = @_;
  my @line = ();
  my $i = 0;
  my $text = $lang{USE_BUTTON};

  foreach my $button (sort keys %commands_list) {
    push (@{$line[$i%4]}, $button);
    $i++;
  }

  my @keyboard = ();

  for my $buttons (@line){
    for my $button (@$buttons) {
      push @keyboard, { ActionType => 'reply', ActionBody => $button, 'Text' => $button, TextSize => 'regular', };
    }
  }

  my $message = {
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'false',
      Buttons       => \@keyboard,
    },
  };

  $message->{text} = $text if(!$attr->{NO_MSG});
  $message->{type} = 'text' if(!$attr->{NO_MSG});

  $Bot->send_message($message);

  return 1;
}
