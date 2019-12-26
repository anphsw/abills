#!/usr/bin/perl

use strict;
use warnings;
use JSON;
use Encode qw/encode_utf8 decode_utf8/;

our (
  %conf,
  $DATE,
  $TIME,
  $base_dir,
  %lang
);

BEGIN {
  use FindBin '$Bin';
  require $Bin . '/../../libexec/config.pl';
  do $Bin . '/../../language/english.pl';
  unshift(@INC,
    $Bin . '/../../',
    $Bin . '/../../lib/',
    $Bin . '/../../Abills',
    $Bin . '/../../Abills/mysql',
    $Bin . '/../../Abills/modules',
    $Bin . '/../../Abills/modules/Telegram',
  );

}

use Abills::Base qw/_bp/;
use Abills::SQL;
use Admins;
use Users;
use Contacts;
use API::Botapi;
use db::Telegram;
use Buttons;
use Tauth;

our $db = Abills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });
our $admin    = Admins->new($db, \%conf);
our $Bot_db   = Telegram->new($db, $admin, \%conf);
our $Users    = Users->new($db, $admin, \%conf);
our $Contacts = Contacts->new($db, $admin, \%conf);

my $message = ();
my $fn_data = "";
my $debug   = 0;
our $Bot = ();

print "Content-type:text/html\n\n";
$ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/ if ($ENV{'REQUEST_METHOD'});
if (!$ENV{'REQUEST_METHOD'}) {
  $message->{text} = join(' ', @ARGV);
  $message->{chat}{id} = 403536999;
  $debug = 1;
  $Bot = Botapi->new($conf{TELEGRAM_TOKEN}, 403536999, 'curl');
}
elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
  my $buffer = '';
  read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
  `echo '$buffer' >> /tmp/telegram.log`;
  my $hash = decode_json($buffer);
  exit 0 unless ($hash && ref($hash) eq 'HASH' && ($hash->{message} || $hash->{callback_query}));
  if ($hash->{callback_query}) {
    $message = $hash->{callback_query}->{message};
    $fn_data = $hash->{callback_query}->{data};
  }
  else {
    $message = $hash->{message};
  }
  $Bot = Botapi->new($conf{TELEGRAM_TOKEN}, $message->{chat}{id}, ($conf{FILE_CURL} || 'curl'));
}
else {
  my ($command) = $ENV{'QUERY_STRING'} =~ m/command=([^&]*)/;
  $command //= '';
  $command =~ tr/+/ /;
  $command =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  $message->{text} = decode_utf8($command);
  $message->{chat}{id} = 'test_id';
  ($fn_data) = $ENV{'QUERY_STRING'} =~ m/fn_data=([^&]*)/;
  $fn_data =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
  $fn_data =~ decode_utf8($fn_data);
  require API::Webtest;
  $Bot = Webtest->new();
}

my %buttons_list = %{buttons_list({bot => $Bot, bot_db => $Bot_db})};
my %commands_list = reverse %buttons_list;

message_process();
exit 1;

#**********************************************************
=head2 message_process()
  
=cut
#**********************************************************
sub message_process {
  my $aid = get_aid($message->{chat}{id});
  if ($aid) {
    admin_menu();
    return 1;
  }

  my $uid = get_uid($message->{chat}{id}); 
  if (!$uid) {
    if ($message->{text} =~ m/^\/start/) {
      subscribe($message);
      main_menu();     
    }
    elsif ($message->{contact}) {
      if ($message->{contact}{user_id} eq $message->{chat}{id}) {
        subscribe_phone($message);
        main_menu();
      }
    }
    else {
      subscribe_info();
    }
    return 1;
  }

  $Bot->{uid} = $uid;
  my $text = $message->{text} ? encode_utf8($message->{text}) : "";

  my $info = $Bot_db->info($uid);

  if ($Bot_db->{TOTAL} > 0 && $info->{button} && $info->{fn}) {
    #Игнорирование нажатия старых инлайн-кнопок.
    return 1 if ($fn_data);
    
    my $ret = telegram_button_fn({
      button    => $info->{button},
      fn        => $info->{fn},
      step_info => $info,
      uid       => $uid,
      bot       => $Bot,
      bot_db    => $Bot_db,
      message   => $message,
    });

    main_menu() if(!$ret);
    return 1;
  }
  elsif ($fn_data) {
    $fn_data =~ s/MSGS:REPLY:/Msgs_reply&reply&/;
    my @fn_argv = split('&', $fn_data);
    telegram_button_fn({
      button => $fn_argv[0],
      fn     => $fn_argv[1],
      argv   => \@fn_argv,
      uid    => $uid,
      bot    => $Bot,
      bot_db => $Bot_db,
    });
  }
  elsif ($commands_list{$text}) {
    telegram_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
      bot    => $Bot,
      bot_db => $Bot_db,
    });
  }
  elsif ($buttons_list{Send_message} && length($message->{text}) >= 20) {
    telegram_button_fn({
      button => 'Send_message',
      fn     => 'simple_msgs',
      text   => $message->{text},
      uid    => $uid,
      bot    => $Bot,
      bot_db => $Bot_db,
    });
  }
  else {
    main_menu();
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
  my $text = "Пожалуйста используйте кнопки.";
    
  foreach my $button (sort keys %commands_list) {
    push (@{$line[$i%4]}, {text => $button});
    $i++;
  }

  my $keyboard = [$line[0] || [], $line[1] || [], $line[2] || [], $line[3] || []];

  $Bot->send_message({
    text         => $text,
    reply_markup => { 
      keyboard        => $keyboard,
      resize_keyboard => "true",
    },
  });

  return 1;
}

#**********************************************************
=head2 admin_menu()  

=cut
#**********************************************************
sub admin_menu {

  $Bot->send_message({
    text => 'Hello admin',
  });

  return 1;
}

1;
