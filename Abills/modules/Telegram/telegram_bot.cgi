#!/usr/bin/perl

=head1 NAME

  ABillS Telegram User Bot
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
  %lang,
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
  do $libpath . "Abills/modules/Paysys/lng_$conf{TELEGRAM_LANG}.pl";

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

use Abills::Base qw/_bp in_array/;
use Abills::SQL;
use Admins;

use Telegram::db::Telegram;
use Telegram::API::Botapi;
use Telegram::API::APILayer;

use Telegram::Buttons;

use Abills::Misc;
use Control::Selects;
use Conf;

use Abills::Sender::Core;
use Abills::HTML;

require Control::Auth;

our $db = Abills::SQL->connect( @conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

our $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} || 3, {
  IP    => $ENV{REMOTE_ADDR},
  SHORT => 1
});

our $Conf = Conf->new($db, $admin, \%conf);

our $Bot_db = Telegram::db::Telegram->new($db, $admin, \%conf);

use Abills::Misc;
use Abills::Templates;

my $message = ();
my $fn_data = "";

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

my $Bot = Telegram::API::Botapi->new($conf{TELEGRAM_TOKEN}, $message->{chat}{id});

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

my $APILayer = Telegram::API::APILayer->new($db, $admin, \%conf, $Bot);

message_process();

#**********************************************************
=head2 message_process()

=cut
#**********************************************************
sub message_process {
  setup_lang($message);

  $APILayer->{for_admins} = 1;
  my ($admin_self) = $APILayer->fetch_api({ PATH => '/admins/self' });

  if (!$admin_self->{errno}) {
    if ($admin_self->{DISABLE} != 0) {
      $Bot->send_message({ text => $lang{YOU_FRIED} });
      return 1;
    }
    admin_fast_replace($admin_self);
    return 1;
  }

  $APILayer->{for_admins} = undef;

  my ($user_config) = $APILayer->fetch_api({ PATH => '/user/config' });

  if ($user_config->{errno}) {
    require Telegram::Tauth;
    my $Tauth = Telegram::Tauth->new($Bot, $APILayer);

    crm_add_dialogue_message($message);

    my $success = 0;
    my $try_to_auth = 0;

    if ($message->{contact} && $message->{contact}{user_id} eq $message->{chat}{id}) {
      $try_to_auth = 1;
      $success = $Tauth->subscribe_phone($message);
    }
    elsif ($message->{text} && $message->{text} =~ m/^\/start.+/) {
      $try_to_auth = 1;
      $success = $Tauth->subscribe($message);
    }

    if ($success) {
      my $is_admin = $success->{user} && $success->{user} eq 'false';
      # TODO: remove this after full migration to admin Telegram bot
      if ($is_admin) {
        ($admin_self) = $APILayer->fetch_api({ PATH => '/admins/self' });
        $Tauth->auth_admin_success($admin_self);
        return 1;
      }
      else {
        ($user_config) = $APILayer->fetch_api({ PATH => '/user/config' });
        $Tauth->auth_success();
      }
    }
    else {
      $Tauth->auth_fail() if ($try_to_auth);
      $Tauth->subscribe_info();
      return 1;
    }
  }

  my $text = $message->{text} ? encode_utf8($message->{text}) : "";

  my $info = $Bot_db->info($Bot->{chat_id});

  my $Buttons = Telegram::Buttons->new(\%conf, $Bot, $Bot_db, $APILayer, $user_config);

  my ($buttons_list, $err) = $Buttons->buttons_list();
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
    });

    main_menu(\%commands_list) if(!$ret);
    return 1;
  }
  elsif($fn_data) {
    my @fn_argv = split('&', $fn_data);

    $Buttons->telegram_button_fn({
      button => $fn_argv[0],
      fn     => $fn_argv[1],
      argv   => \@fn_argv,
      text   => $message->{text} || $message->{caption},
      photo  => $message->{photo}[0]{file_id},
    });
  }
  elsif ($commands_list{$text}) {
    $Buttons->telegram_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
    });
  }
  else {
    main_menu(\%commands_list);
  }
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
=head2 admin_fast_replace()

=cut
#**********************************************************
sub admin_fast_replace {
  my ($admin_self) = @_;

  my @msgs_text = [];
  if($message->{text} || $message->{caption}) {
    $message->{text} = $message->{caption} if ($message->{caption});
    @msgs_text = $message->{text} =~ /(MSGS_ID=[0-9]+)(\s|\n)*(.*)/gs;
  }

  unless (($msgs_text[0]) || ($message->{photo} || $message->{document})) {
    $Bot->send_message({ text => $lang{SEND_ERROR} });

    return 1;
  }

  my $props = {};

  my $message_id = 0;

  $Bot_db = Telegram::db::Telegram->new($db, $admin, \%conf, { ADMIN => 1 });

  if (!ref $msgs_text[0]) {
    $message_id = $msgs_text[0];
    $message_id =~ s/MSGS_ID=//g;

    $props->{REPLY_TEXT} = $msgs_text[2] || '';

    $Bot_db->del($Bot->{chat_id});

    $Bot_db->add({
      USER_ID => $Bot->{chat_id},
      ARGS    => '{"message":{"id":"' . $message_id . '"}}',
    });
  }

  my $info = $Bot_db->info($Bot->{chat_id});

  if ($Bot_db->{TOTAL} > 0 && (defined $message->{caption} || !$#msgs_text)) {
    my $msg_hash = decode_json($info->{args});

    $Bot->send_message({ text => $lang{SEND_ERROR}, }) if !$msg_hash->{message}{id};

    $message_id = $msg_hash->{message}->{id};

    my $file_id;

    if ($message->{photo}) {
      my $photo = pop @{$message->{photo}};
      $file_id = $photo->{file_id};
    }
    else {
      $file_id = $message->{document}->{file_id};
    }

    my ($file_path, $file_size, $file_content) = $Bot->get_file($file_id);
    my ($file_name, $file_extension) = $file_path =~ m/.*\/(.*)\.(.*)/;

    $Bot->send_message({
      text         => "$lang{SEND_ERROR}",
    }) unless ($file_content && $file_size && $file_name && $file_extension);

    my $file_content_type = main::file_content_type($file_extension);

    $props->{FILE1} = {
      FILENAME     => "$file_name.$file_extension",
      CONTENT_TYPE => $file_content_type,
      SIZE         => $file_size,
      CONTENTS     => $file_content,
    };
  }

  my ($res) = $APILayer->fetch_api({
    METHOD => 'POST',
    PATH   => "/msgs/$message_id/reply",
    PARAMS => $props
  });

  if ($res->{errno}) {
    $Bot->send_message({ text => "$lang{SEND_ERROR}" });
  }
  else {
    $Bot->send_message({ text => "$lang{SEND_SUCCESS}" });
  }

  return 1;
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

#**********************************************************
=head2 crm_add_dialogue_message($message)

=cut
#**********************************************************
sub crm_add_dialogue_message {
  my ($message) = @_;

  return if !in_array('Crm', \@MODULES);

  my $params = {
    MESSAGE => $message->{text} || $message->{caption}
  };

  my $file_id;
  my $mime_type;

  if ($message->{photo}) {
    my $photo = pop @{$message->{photo}};
    $file_id = $photo->{file_id};
    $mime_type = 'image/jpeg';
  }
  elsif ($message->{document}) {
    $file_id = $message->{document}{file_id};
    $mime_type = $message->{document}{mime_type};
  }

  if ($file_id) {
    my ($file_path, $file_size, $file_content) = $Bot->get_file($file_id);
    return 0 if !$file_path || !$file_size;

    $params->{ATTACHMENTS} = [{
      FILE_NAME    => $file_path,
      CONTENT_TYPE => $mime_type,
      SIZE         => $file_size,
      CONTENTS     => $file_content
    }];
  }

  my ($res) = $APILayer->fetch_api({
    METHOD => 'POST',
    PATH   => '/crm/leads/dialogue/message',
    PARAMS => $params,
  });

  if ($res->{errno}) {
    return 0;
  }

  exit 1;
}

#**********************************************************
=head2 setup_lang($m)

=cut
#**********************************************************
sub setup_lang {
  my ($m) = @_;

  my %ISO_LANGUAGE_CODE = (
    english     => 'en',
    russian     => 'ru',
    ukrainian   => 'uk',
    bulgarian   => 'bg',
    french      => 'fr',
    armenian    => 'hy',
    azeri       => 'az',
    belarussian => 'be',
    spanish     => 'es',
    uzbek       => 'uz',
    polish      => 'pl',
    kazakh      => 'kk',
  );

  # language_code is optional.
  my $from = $m->{from} || {};
  my $lang_code = $from->{language_code};

  my %key_to_language = reverse %ISO_LANGUAGE_CODE;
  my $language = $key_to_language{$lang_code};

  if ($language) {
    eval {
      do $libpath . "language/$language.pl";
      do $libpath . "Abills/modules/Telegram/lng_$language.pl";
      do $libpath . "Abills/modules/Msgs/lng_$language.pl";
      do $libpath . "Abills/modules/Paysys/lng_$language.pl";
    }
  };
}

1;
