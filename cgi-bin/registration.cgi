#!/usr/bin/perl -w

=head2 NAME

  Main  registration engine

=cut

use strict;

BEGIN {
  our $libpath = '../';
  our $sql_type = 'mysql';
  unshift( @INC,
    $libpath . "Abills/$sql_type/",
    $libpath . 'lib/',
    $libpath . 'Abills/modules/',
    $libpath
  );

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}

use warnings;
use Abills::Defs;

do "../libexec/config.pl";
require Abills::Templates;
require Abills::Misc;

use Abills::Base;
use Users;

#use Paysys;
use Finance;
use Admins;
use Tariffs;
use Sharing;

our %OUTPUT;
our @REGISTRATION;
our $sid = '';
our %lang;
our %LANG;
our $base_dir;

our $html = Abills::HTML->new( { CONF => \%conf, NO_PRINT => 1, } );
our $db = Abills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );

if ( $conf{LANGS} ){
  $conf{LANGS} =~ s/\n//g;
  my (@lang_arr) = split( /;/, $conf{LANGS} );
  %LANG = ();
  foreach my $l ( @lang_arr ){
    my ($lang, $lang_name) = split( /:/, $l );
    $lang =~ s/^\s+//;
    $LANG{$lang} = $lang_name;
  }
}

my $CAPTCHA_DIR = $base_dir . 'cgi-bin/captcha/';
my %INFO_HASH = ();

our $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => '127.0.0.1' } );
#my $payments = Finance->payments($db, $admin, \%conf);
our $users = Users->new( $db, $admin, \%conf );

if ( !@REGISTRATION ){
  print "Content-Type: text/html\n\n";
  print "Can't find modules services for registration";
  exit;
}

$html->{language} = $FORM{language} if ($FORM{language});

do "../language/$html->{language}.pl";

$INFO_HASH{SEL_LANGUAGE} = $html->form_select(
  'language',
  {
    EX_PARAMS => 'onChange="selectLanguage()"',
    SELECTED  => $html->{language},
    SEL_HASH  => \%LANG,
    NO_ID     => 1
  }
);

if ( $FORM{FORGOT_PASSWD} ){
  password_recovery();
}
elsif ( $FORM{qindex} && $FORM{qindex} == 30 ){
  require "Abills/main/Address_mng.pm";
  form_address_sel();
}
elsif ( $#REGISTRATION > -1 ){
  my $m = $REGISTRATION[0];
  if ( $FORM{module} ){
    $m = $FORM{module};
  }
  else{
    if ( $#REGISTRATION > 0 && !$FORM{registration} ){
      foreach my $registration_module ( @REGISTRATION ){
        $html->{OUTPUT} .= $html->button( $registration_module, "module=$registration_module", { BUTTON => 1 } ) . ' ';
      }
    }
  }

  $INFO_HASH{CAPTCHA} = show_captcha();

  $INFO_HASH{RULES} = $html->tpl_show( templates( 'form_accept_rules' ), { }, { OUTPUT2RETURN => 1 } );
  $INFO_HASH{language} = $html->{language};

  if ( !$FORM{DOMAIN_ID} ){
    $FORM{DOMAIN_ID} = 0;
    $INFO_HASH{DOMAIN_ID} = 0;
  }

  load_module( $m, $html );

  $m = lc( $m );
  my $function = $m . '_registration';
  my $return = &{ \&{$function} }( \%INFO_HASH );

  # Send E-mail to admin after registration
  if ( $return && $return > 1 ){
    my $message = qq{
New Registrations
=========================================
Username: $FORM{LOGIN}
Fio:      $FORM{FIO}
DATE:     $DATE $TIME
IP:       $ENV{REMOTE_ADDR}
Module:   $m
E-Mail:   $FORM{EMAIL}
=========================================

};

    if ( $conf{REGISTRATION_EXTERNAL} ){
      if ( !_external( $conf{REGISTRATION_EXTERNAL}, { %FORM } ) ){
        #return 0;
      }
    }

    sendmail( "$conf{ADMIN_MAIL}", "$conf{ADMIN_MAIL}", "New registrations", "$message", "$conf{MAIL_CHARSET}", "" );
  }
}
else{

}

if ( !($FORM{header} && $FORM{header} == 2) ){
  $html->{METATAGS} = templates( 'metatags' );
  print $html->header();

  $OUTPUT{BODY} = $html->{OUTPUT};
  $OUTPUT{BODY} .= "<link href='/styles/default_adm/css/client.css' rel='stylesheet' />";

  print $html->tpl_show( templates( 'form_client_start' ), { %OUTPUT, TITLE_TEXT => $lang{REGISTRATION} } );
}
else{
  print "Content-Type: text/html\n\n";
  print $html->{OUTPUT};
}



#**********************************************************
=head2 password_recovery() - Password recovery

=cut
#**********************************************************
sub password_recovery{
  if ( $FORM{SEND} && check_captcha( $FORM{CCODE}, $FORM{C} ) ){
    password_recovery_process();
  }

  my %info = ();
  if ( in_array( 'Sms', \@MODULES ) ){
    $info{EXTRA_PARAMS} = $html->tpl_show( _include( 'sms_check_form', 'Sms' ), undef, { OUTPUT2RETURN => 1 } );
  }

  $info{CAPTCHA} = show_captcha();

  $html->tpl_show( templates( 'form_forgot_passwd' ), { %FORM, %info } );

  return 1
}

#**********************************************************
=head2 password_recovery_process()

=cut
#**********************************************************
sub password_recovery_process{

  # Possible pairs are
  #   login + mail
  #   login + phone
  #   uid + mail
  #   uid + phone
  unless (
    (
      ($FORM{LOGIN} && $FORM{LOGIN} ne '' && $FORM{LOGIN} ne '*' )
        ||
        ($FORM{UID} && $FORM{UID} ne '' && $FORM{UID} ne '*' )
    ) && (
      ($FORM{EMAIL} && $FORM{EMAIL} ne '' && $FORM{EMAIL} ne '*' )
        ||
        ($FORM{PHONE} && $FORM{PHONE} ne '' && $FORM{PHONE} ne '*' )
    )
  )
  {
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_DATA}" );
    return 0;
  }

  # Do not send empty parameters to list (we checked them below)
  my @args_can_be_empty = qw( PHONE UID LOGIN EMAIL );
  foreach my $arg ( @args_can_be_empty ){
    delete $FORM{$arg} if (defined $FORM{$arg} && $FORM{$arg} eq '' );
  };

  my $users_list = $users->list( {
      PHONE     => '_SHOW',
      EMAIL     => '_SHOW',
      %FORM,
      COLS_NAME => 1 }
  );

  if ( !defined $users_list || ref $users_list ne 'ARRAY' ){
    my $search_param = ($FORM{PHONE} && $FORM{PHONE} ne '') ? $lang{CELL_PHONE} : 'E-mail';
    $html->message( 'err', $lang{ERROR}, "$lang{USER} $lang{NOT_EXIST} $lang{OR} $search_param $lang{NOT_EXIST}" );
    return 0;
  };

  my $user = $users_list->[0];

  my $email = $user->{email};
  my $phone = $user->{phone};
  my $uid = $user->{uid};

  my $pi = $users->pi( { UID => $uid } );
  my $user_info = $users->info( $uid, { SHOW_PASSWORD => 1 } );

  my $message = $html->tpl_show( templates( 'msg_passwd_recovery' ), {
      MESSAGE => "$lang{LOGIN}:  $users->{LOGIN}\n" . "$lang{PASSWD}: $users->{PASSWORD}\n\n",
      %{$user_info},
      %{$pi}
    },
    { OUTPUT2RETURN => 1 }
  );

  if ( $email && $email ne '' ){
    sendmail( "$conf{ADMIN_MAIL}", "$email", "$PROGRAM Password Repair", "$message", "$conf{MAIL_CHARSET}", "" );
    $html->message( 'info', $lang{INFO}, "$lang{SENDED}" );
  }
  else{
    $html->message( 'info', $lang{INFO}, "E-Mail $lang{NOT_EXIST}" );
  }

  if ( $FORM{SEND_SMS} && in_array( 'Sms', \@MODULES ) ){
    load_module( 'Sms', $html );
    if (
      sms_send(
        {
          NUMBER    => $phone,
            MESSAGE => $message,
            UID     => $uid
        }
      )
    ){
      $html->message( 'info', "$lang{INFO}", "SMS $lang{SENDED}" );
    }
  }

  return 1;
}

#**********************************************************
=head2 show_captcha()

=cut
#**********************************************************
sub show_captcha{
  #  my ($attr) = @_;

  $conf{REGISTRATION_CAPTCHA} = 1 if (!defined( $conf{REGISTRATION_CAPTCHA} ));

  if ( $conf{REGISTRATION_CAPTCHA} ){
    load_pmodule( 'Authen::Captcha', { HEADER => 1 } );

    my $Captcha = Authen::Captcha->new(
      data_folder   => $CAPTCHA_DIR,
      output_folder => $CAPTCHA_DIR,
    );

    $INFO_HASH{CAPTCHA_OBJ} = $Captcha;

    if ( !-d $CAPTCHA_DIR ){
      if ( !mkdir( $CAPTCHA_DIR ) ){
        $html->message( 'err', $lang{ERROR}, "$lang{ERR_CANT_CREATE_FILE} '$CAPTCHA_DIR' $lang{ERROR}: $!\n" );
        $html->message( 'info', $lang{INFO}, "$lang{NOT_EXIST} '$CAPTCHA_DIR'" );
      }
    }
    else{

      my $number_of_characters = 5;
      my $md5sum = eval { return $Captcha->generate_code( $number_of_characters ) };

      if ( !$md5sum ){
        print "Content-Type: text/html\n\n";
        print "Can't make captcha\n";
        print $@;
        exit;
      }

      $INFO_HASH{CAPTCHA} = $html->tpl_show( templates( 'form_captcha' ), { MD5SUM => $md5sum },
        { OUTPUT2RETURN => 1 } );

    }
  }

  return $INFO_HASH{CAPTCHA};
}

#**********************************************************
=head2 check_captcha($user_input, $md5hash)

  Arguments:
   $user_input
   $md5hash

  Returns:
    boolean

=cut
#**********************************************************
sub check_captcha{
  my ($user_input, $md5hash) = @_;

  $conf{REGISTRATION_CAPTCHA} = 1 if (!defined( $conf{REGISTRATION_CAPTCHA} ));

  if ( $conf{REGISTRATION_CAPTCHA} ){
    load_pmodule( 'Authen::Captcha', { HEADER => 1 } );

    my $Captcha = Authen::Captcha->new(
      data_folder   => $CAPTCHA_DIR,
      output_folder => $CAPTCHA_DIR,
    );

    $Captcha->debug( 2 );
    my $result = $Captcha->check_code( $user_input, $md5hash );

    if ( $result == 0 ){
      $html->message( 'err', "Captcha: $lang{ERROR}" );
      #file error
    }
    elsif ( $result == -1 ){
      $html->message( 'err', "Captcha: has been expired" );
      #code expired
    }
    elsif ( $result == -2 ){
      $html->message( 'err', "Captcha: invalid (-2)" );
      #code invalid
    }
    elsif ( $result == -3 ){
      #code does not match crypt
      $html->message( 'err', "Captcha: invalid (-3)" );
    }

    return $result == 1;
  }
  else{
    return 1;
  }
}

1
