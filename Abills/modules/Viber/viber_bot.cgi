#!/usr/bin/perl

=head1 NAME

  ABillS Viber User Bot
  abills.net.ua

=cut

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
  %FORM,
  @MODULES
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

  $conf{VIBER_LANG} = $conf{default_language} if (!$conf{VIBER_LANG});

  require $libpath . "language/$conf{VIBER_LANG}.pl";
  require $libpath . "Abills/modules/Msgs/lng_$conf{VIBER_LANG}.pl";
  require $libpath . "Abills/modules/Viber/lng_$conf{VIBER_LANG}.pl";

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

use Abills::SQL;
use Admins;

use Viber::db::Viber;
use Viber::API::Botapi;
use Viber::API::APILayer;

use Viber::Buttons;

require Abills::Misc;
use Abills::Templates;
use Abills::Base qw/in_array/;
use Abills::HTML;

require Control::Auth;

our $db = Abills::SQL->connect(@conf{qw/dbtype dbhost dbname dbuser dbpasswd/},
  { CHARSET => $conf{dbcharset} });

our $admin = Admins->new($db, \%conf);
$admin->info($conf{USERS_WEB_ADMIN_ID} || 3, {
  IP        => $ENV{REMOTE_ADDR},
  SHORT     => 1
});

our $Conf = Conf->new($db, $admin, \%conf);

our $Bot_db = Viber::db::Viber->new($db, $admin, \%conf);

my $hash = ();

print "Content-Type: text/html\n\n";
my $buffer = '';
read(STDIN, $buffer, $ENV{CONTENT_LENGTH});

$hash = decode_json($buffer);

return 0 unless ($hash && ref($hash) eq 'HASH' && $hash->{event});

my $id = $hash->{user}{id} || $hash->{sender}{id} || '';

my $Bot = Viber::API::Botapi->new($conf{VIBER_TOKEN}, $id, { NAME => $conf{VIBER_BOT_SENDER_NAME} });

our $html = Abills::HTML->new({
  IMG_PATH   => 'img/',
  NO_PRINT   => 1,
  CONF       => \%conf,
  CHARSET    => $conf{default_charset},
  HTML_STYLE => $conf{UP_HTML_STYLE},
  language   => $conf{VIBER_LANG}
});

$Bot->{lang} = \%lang;
$Bot->{html} = $html;

my $APILayer = Viber::API::APILayer->new($db, $admin, \%conf, $Bot);

message_process();

#**********************************************************
=head2 message_process()

=cut
#**********************************************************
sub message_process {
  my ($user_config) = $APILayer->fetch_api({ PATH => '/user/config' });

  if ($user_config->{errno}) {
    require Viber::Vauth;
    my $Vauth = Viber::Vauth->new($Bot, $APILayer);

    if ($hash->{event} && $hash->{event} =~ m/^message/) {
      crm_add_dialogue_message($hash);
    }

    my $success = 0;
    my $try_to_auth = 0;

    if ($hash->{message} && $hash->{message}{contact} && $hash->{message}{contact}{phone_number}) {
      $try_to_auth = 1;
      $success = $Vauth->subscribe_phone($hash);
    }
    elsif ($hash->{event} && $hash->{event} =~ m/^conversation_started/) {
      $try_to_auth = 1;
      $success = $Vauth->subscribe($hash);
    }

    if ($success) {
      ($user_config) = $APILayer->fetch_api({ PATH => '/user/config' });
      $Vauth->auth_success();
    }
    else {
      $Vauth->auth_fail() if ($try_to_auth);
      $Vauth->subscribe_info();

      return 1;
    }
  }

  my $text = $hash->{message}{text} ? encode_utf8($hash->{message}{text}) : '';

  my $info = $Bot_db->info($Bot->{receiver});

  my $Buttons = Viber::Buttons->new(\%conf, $Bot, $Bot_db, $APILayer, $user_config);

  my ($buttons_list, $err) = $Buttons->buttons_list();
  my %commands_list = reverse %$buttons_list;

  if ($err) {
    my $err_text = "*$lang{ERROR}*\n";
    if ($conf{VIBER_DEBUG}) {
      $err_text .= "\n";
      $err_text .= $err;
    }
    $Bot->send_message({ text => $err_text });
    return 0;
  }

  if ($commands_list{$text}) {
    my $ret = $Buttons->viber_button_fn({
      button => $commands_list{$text},
      fn     => 'click',
    });
    main_menu(\%commands_list) if (!$ret);
  }
  else {
    if ($hash->{event} && $hash->{event} =~ m/^message/) {
      if ($text =~ /fn:([A-z 0-9 _-]*)&(.*)/) {
        my @args = split /&/, $2;
        my $fn = shift @args;
        my $ret = $Buttons->viber_button_fn({
          button    => $1,
          fn        => $fn,
          argv      => \@args,
          step_info => $info,
        });

        main_menu(\%commands_list) if (!$ret);
      }
      elsif ($Bot_db->{TOTAL} > 0 && $info->{fn}
        && $info->{fn} =~ /fn:([A-z 0-9 _-]*)&(.*)/) {

        my @args = split /&/, $2;
        my $fn = shift @args;

        my $ret = $Buttons->viber_button_fn({
          button    => $1,
          fn        => $fn,
          text      => $text,
          argv      => \@args,
          message   => $hash->{message},
          step_info => $info,
        });

        main_menu(\%commands_list) if (!$ret);
      }
      else {
        main_menu(\%commands_list);
      }
    }
    elsif ($hash->{event} =~ m/^conversation_started/) {
      main_menu(\%commands_list);
    }
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

  my $text = $lang{USE_BUTTON};
  my @keyboard = ();

  for my $button (@buttons) {
    push @keyboard, {
      Columns    => 3,
      Rows       => 1,
      ActionType => 'reply',
      ActionBody => $button,
      Text       => $button,
      TextSize   => 'regular'
    };
  }

  $Bot->send_message({
    text     => $text,
    keyboard => {
      Type          => 'keyboard',
      DefaultHeight => 'false',
      Buttons       => \@keyboard,
    },
  });

  return 1;
}

#**********************************************************
=head2 crm_add_dialogue_message($message)

=cut
#**********************************************************
sub crm_add_dialogue_message {
  my $message = shift;

  return if !in_array('Crm', \@MODULES);

  my $params = {
    MESSAGE => $message->{message}{text}
  };

  if ($message->{message}{media}) {
    my $file_id = $message->{message}{media}.'|'.$message->{message}{file_name}.'|'.$message->{message}{size};
    my ($file, $file_size, $file_content) = $Bot->get_file($file_id);
    my ($file_extension) = $file =~ /\.([^.]+)$/;

    $params->{ATTACHMENTS} = [{
      FILE_NAME    => $message->{message}{file_name},
      CONTENT_TYPE => file_content_type($file_extension),
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
