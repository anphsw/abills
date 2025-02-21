#!/usr/bin/perl

=head1 NAME

  ABillS Telegram Admin Bot
  abills.net.ua

=cut

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
  $ENV{REQUEST_METHOD} =~ tr/a-z/A-Z/ if ($ENV{REQUEST_METHOD});
  if (!$ENV{REQUEST_METHOD} || $ENV{REQUEST_METHOD} ne 'POST') {
    print "Content-Type: text/html\n\n";
    print "GO AWAY";
    exit 1;
  }

  our $libpath = '../../';
  require $libpath . 'libexec/config.pl';

  $conf{TELEGRAM_LANG} = $conf{default_language} if (!$conf{TELEGRAM_LANG});

  do $libpath . "language/$conf{TELEGRAM_LANG}.pl";
  do $libpath . "Abills/modules/Telegram/lng_$conf{TELEGRAM_LANG}.pl";
  do $libpath . "Abills/modules/Msgs/lng_$conf{TELEGRAM_LANG}.pl";
  do $libpath . "Abills/modules/Equipment/lng_$conf{TELEGRAM_LANG}.pl";

  my $sql_type = $conf{dbtype} || 'mysql';

  unshift(@INC,
    $libpath . 'Abills/modules/',
    $libpath . "Abills/$sql_type/",
    $libpath . '/lib/',
    $libpath . 'Abills/',
    $libpath
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use Abills::Base qw/_bp/;
use Abills::SQL;
use Admins;
use Users;
use Contacts;
use Conf;

use Telegram::db::Telegram;
use Telegram::API::Botapi;
use Telegram::API::APILayer;

use Telegram::Buttons;

use Abills::HTML;

require Control::Auth;

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/}, { CHARSET => $conf{dbcharset} });
our $admin = Admins->new($db, \%conf);
our $Conf = Conf->new($db, $admin, \%conf);

our $Bot_db = Telegram::db::Telegram->new($db, $admin, { %conf,
  TELEGRAM_BOT_NAME => $conf{TELEGRAM_ADMIN_BOT_NAME},
  TELEGRAM_TOKEN    => $conf{TELEGRAM_ADMIN_TOKEN},
}, { ADMIN => 1 });

my %SEARCH_KEYS = (
  '\/[E|e]quipment\s*([^\n\r]+)$' => 'Admin_equipment&search',
  '\/msgs\s*([^\n\r]+)$'          => 'Admin_msgs&search'
);

my $message = ();
my $fn_data = "";
my $debug   = 0;

print "Content-Type: text/html\n\n";
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

our $Bot = Telegram::API::Botapi->new($conf{TELEGRAM_ADMIN_TOKEN}, $message->{chat}{id});

our $html = Abills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
  language   => $conf{TELEGRAM_LANG}
});

$Bot->{lang} = \%lang;
$Bot->{html} = $html;

my $APILayer = Telegram::API::APILayer->new($db, $admin, \%conf, $Bot, { for_admins => 1 });

message_process();

#**********************************************************
=head2 message_process()

=cut
#**********************************************************
sub message_process {
  # TODO: add /admin/config
  my ($admin_self) = $APILayer->fetch_api({ PATH => '/admins/self' });

  if ($admin_self->{errno}) {
    require Telegram::Tauth;
    my $Tauth = Telegram::Tauth->new($Bot, $APILayer);

    my $success = 0;
    my $try_to_auth = 0;

    if ($message->{contact} && $message->{contact}{user_id} eq $message->{chat}{id}) {
      $try_to_auth = 1;
      $APILayer->{for_admins} = 0;
      $success = $Tauth->subscribe_phone($message);
      $APILayer->{for_admins} = 1;
    }
    elsif ($message->{text} && $message->{text} =~ m/^\/start.+/) {
      $try_to_auth = 1;
      $APILayer->{for_admins} = 0;
      $success = $Tauth->subscribe($message);
      $APILayer->{for_admins} = 1;
    }

    if ($success) {
      ($admin_self) = $APILayer->fetch_api({ PATH => '/admins/self' });
      $Tauth->auth_admin_success($admin_self);
    }
    else {
      $Tauth->auth_fail() if ($try_to_auth);
      $Tauth->subscribe_info();
      return 1;
    }
  }

  my $text = $message->{text} ? encode_utf8($message->{text}) : "";

  my $info = $Bot_db->info($Bot->{chat_id});

  _check_search_commands();

  my $Buttons = Telegram::Buttons->new(\%conf, $Bot, $Bot_db, $APILayer, $admin_self);
  my ($buttons_list, $err) = $Buttons->buttons_list({ for_admins => 1 });
  my %commands_list = reverse %$buttons_list;

  if ($err) {
    my $err_text = "<b>$lang{ERROR}</b>\n";
    if ($conf{TELEGRAM_DEBUG}) {
      $err_text .= "\n";
      $err_text .= $err;
    }
    $Bot->send_message({ text => $err_text });
    return 0;
  }

  if ($Bot_db->{TOTAL} > 0 && $info->{button} && $info->{fn}) {
    my $ret = $Buttons->telegram_button_fn({
      button    => $info->{button},
      fn        => $info->{fn},
      step_info => $info,
      message   => $message,
      update    => $hash
    });

    main_menu(\%commands_list) if(!$ret);
    return 1;
  } elsif ($fn_data) {
    my @fn_argv = split('&', $fn_data);

    $Buttons->telegram_button_fn({
      button     => $fn_argv[0],
      fn         => $fn_argv[1],
      argv       => \@fn_argv,
      text       => $message->{text} || $message->{caption},
      message_id => $message->{message_id},
      update     => $hash
    });
    return 1;
  }
  elsif ($commands_list{$text}) {
    $Buttons->telegram_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
      update => $hash,
    });
    return 1;
  }

  main_menu(\%commands_list);

  return 1;
}

#**********************************************************
=head2 main_menu()

=cut
#**********************************************************
sub main_menu {
  my ($commands_list) = @_;
  my @buttons = sort keys %$commands_list;

  my $BUTTONS_IN_ROW = 2;

  my $text = $lang{USE_BUTTON};
  my @keyboard = ();

  foreach my $i (0..$#buttons) {
    my $button = $buttons[$i];
    my $row_index = int($i / $BUTTONS_IN_ROW);
    $keyboard[$row_index] //= [];

    push (@{$keyboard[$row_index]}, { text => $button });
    $i++;
  }

  $Bot->send_message({
    text         => $text,
    reply_markup => {
      keyboard        => \@keyboard,
      resize_keyboard => 'true',
    },
  });

  return 1;
}
#**********************************************************
=head2 _check_search_commands()

=cut
#**********************************************************
sub _check_search_commands {
  foreach my $key (keys %SEARCH_KEYS) {
    if ($message->{text} =~ $key) {
      $fn_data = $SEARCH_KEYS{$key} . "&$1";
      return;
    }
  }
}

#**********************************************************
=head2 file_content_type()

=cut
#**********************************************************
sub file_content_type {
  my ($file_extension) = @_;

  my @IMAGES_FILE_EXTENSIONS = ('png', 'jpg', 'gif', 'jpeg', 'tiff');

  my $file_content_type = "application/octet-stream";

  if (in_array($file_extension, \@IMAGES_FILE_EXTENSIONS)) {
    $file_content_type = "image/$file_extension";
  }
  elsif ( $file_extension && $file_extension eq "zip" ) {
    $file_content_type = "application/x-zip-compressed";
  }

  return $file_content_type;
}

1;
