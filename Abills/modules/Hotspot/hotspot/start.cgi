#!/usr/bin/perl

=head1 NAME

  ABillS Hotspot start page

  Error ID: 15xx

=cut

BEGIN {
  our $libpath = '../';
  our $sql_type = 'mysql';
  unshift( @INC,
    $libpath . "Abills/$sql_type/",
    $libpath . 'lib/',
    $libpath . 'Abills/modules/');

  eval { require Time::HiRes; };
  our $begin_time = 0;
  if ( !$@ ){
    Time::HiRes->import( qw(gettimeofday) );
    $begin_time = Time::HiRes::gettimeofday();
  }
}

our($base_dir, %LANG);
do "../libexec/config.pl";
#use strict;
use Abills::Defs;
use Abills::Base;
use Users;
use Nas;
use Admins;

require Abills::Templates;
require Abills::Misc;

$conf{base_dir} = $base_dir if (!$conf{base_dir});

our $html = Abills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
    METATAGS => templates( 'metatags' ),
    COLORS   => $conf{UI_COLORS}
  }
);

my $version = '0.21';

my $sql = Abills::SQL->connect( $conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd},
  { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef } );
our $db = ($conf{VERSION} && $conf{VERSION} < 0.70) ? $sql->{db} : $sql;

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

$html->{language} = $FORM{language} if (defined( $FORM{language} ) && $FORM{language} =~ /^[a-z_]+$/);
$html->{show_header} = 1;

do "../language/$html->{language}.pl";
$sid = $FORM{sid} || '';    # Session ID

my $PHONE_PREFIX = $conf{DEFAULT_PHONE_PREFIX} || '';
my $auth_cookie_time = $conf{AUTH_COOKIE_TIME} || 86400;

if ( $ENV{REQUEST_URI} ){
  my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
  $html->set_cookies( 'hotspot_userurl', "http://$ENV{SERVER_NAME}:$ENV{SERVER_PORT}/$ENV{REQUEST_URI}", "$cookies_time"
    , $html->{web_path} );
}

#cookie section ============================================
#Operation system ID
#$html->set_cookies( 'OP_SID', "$FORM{OP_SID}", "Fri, 1-Jan-2038 00:00:01",
#  $html->{web_path} ) if (defined( $FORM{OP_SID} ));

if ( $FORM{sid} ){
  $html->set_cookies( 'sid', "$FORM{sid}", "Fri, 1-Jan-2038 00:00:01", $html->{web_path} );
}

#===========================================================

our $admin = Admins->new( $db, \%conf );
$admin->info( $conf{SYSTEM_ADMIN_ID}, { IP => $ENV{REMOTE_ADDR} } );

#my $uid = 0;
my %OUTPUT = ();
my %INFO_HASH = ();

our $users = Users->new( $db, $admin, \%conf );
$user = $users;

if ( $FORM{DOMAIN_ID} ){
  $admin->info( $conf{SYSTEM_ADMIN_ID}, { DOMAIN_ID => $FORM{DOMAIN_ID} } );
  $html->{WEB_TITLE} = $admin->{DOMAIN_NAME};
}
else{
  if ( in_array( 'Multidoms', \@MODULES ) ){
    print $html->header( { CONTENT_LANGUAGE => $CONTENT_LANGUAGE } );
    print "Wrong domain id!!!";
    exit;
  }
}

my $nas = Nas->new( $db, \%conf );

my %PARAMS = ();
if ( $FORM{BUY_CARD} ){

}
elsif ( $FORM{NAS_ID} ){
  $PARAMS{NAS_ID} = $FORM{NAS_ID};
}
elsif ( $FORM{NAS_IP} ){
  $PARAMS{IP} = $FORM{NAS_IP};
}
else{
  $PARAMS{IP} = $ENV{REMOTE_ADDR};
}

$nas->info( { %PARAMS } );

if ( $nas->{TOTAL} > 0 ){
  $INFO_HASH{CITY} = $nas->{CITY};
  $INFO_HASH{ADDRESS_STREET} = $nas->{ADDRESS_STREET};
  $INFO_HASH{ADDRESS_BUILD} = $nas->{ADDRESS_BUILD};
  $INFO_HASH{ADDRESS_FLAT} = $nas->{ADDRESS_FLAT};
  $INFO_HASH{NAS_GID} = $nas->{GID};
  $FORM{NAS_GID} = $nas->{GID};
}

my $login_url = $conf{HOTSPOT_LOGIN_URL} || 'http://192.168.182.1:3990/prelogin?lang=' . $html->{language};

if ( $FORM{uamport} && $FORM{uamport} eq 'mikrotik' ){
  $login_url = 'http://192.168.182.1/login';
  #mikrotik_();
}
elsif ( $FORM{GUEST_ACCOUNT} ){
  get_hotspot_account();
}
elsif ( $FORM{PIN} ){
  check_card();
}
elsif ( $FORM{PAYMENT_SYSTEM} || $FORM{BUY_CARDS} ){
  $html->{OUTPUT} .= buy_cards();
}
else{
  print "Content-Type: text/html\n\n";

  if ( $conf{HOTSPOT_LOGIN_URL} ){
    $login_url = urldecode( $conf{HOTSPOT_LOGIN_URL} );
  }

  my $available_languages = join( ', ', %LANG );

  $INFO_HASH{PAGE_QS} = "language=$FORM{language}" if ($FORM{language});
  $INFO_HASH{SELL_POINTS} = $html->tpl_show( _include( 'multidoms_sell_points', 'Multidoms' ), \%OUTPUT,
    { OUTPUT2RETURN => 1 } );
  $INFO_HASH{CARDS_BUY} = buy_cards();

  $html->tpl_show(
    templates( 'form_client_hotspot_start' ),
    {
      DOMAIN_ID        => $admin->{DOMAIN_ID},
      DOMAIN_NAME      => $admin->{DOMAIN_NAME},
      CONTENT_LANGUAGE => $CONTENT_LANGUAGE,
      LOGIN_URL        => $login_url,
      LANGS_ARRAY      => $available_languages,
      LANG_CURRENT     => $html->{language},
      %INFO_HASH
    },
    { MAIN => 1 }
  );
  print $html->{OUTPUT};
  exit;
}

print $html->header( { CONTENT_LANGUAGE => $CONTENT_LANGUAGE } );
$OUTPUT{BODY} = $html->{OUTPUT};
print $html->tpl_show( templates( 'form_base' ), \%OUTPUT, { OUTPUT2RETURN => 1 } );

$html->test() if ($conf{debugmods} =~ /LOG_DEBUG/);

#**********************************************************
=head2 get_login_url($attr)


 http://10.5.50.1/login?fastlogin=true&login=test&password=123456

=cut
#**********************************************************
sub get_login_url{
  my ($attr) = @_;

  if ( $FORM{login_return_url} && $FORM{login_return_url} ne '' ){
    $login_url = urldecode( $FORM{login_return_url} );
  }
  elsif ( $FORM{GUEST_ACCOUNT} && $conf{HOTSPOT_GUEST_LOGIN_URL}){
    $login_url = $conf{HOTSPOT_GUEST_LOGIN_URL};
  }
  elsif ( $conf{HOTSPOT_LOGIN_URL}){
    $login_url = $conf{HOTSPOT_LOGIN_URL};
  };

  if ( $FORM{LOGIN} ){
    $login_url =~ s/%LOGIN%/$FORM{LOGIN}/g;
  };

  if ( $FORM{PASSWORD} ){
    $login_url =~ s/%PASSWORD%/$FORM{PASSWORD}/g;
  };

  if ( $attr->{NAS_IP} ){
    $login_url =~ s/%NAS_IP%/$attr->{NAS_IP}/g;
  };

  return $login_url;
}

#**********************************************************
=head2 get_hotspot_account()

=cut
#**********************************************************
sub get_hotspot_account{

  use Tariffs;
  my $tariffs = Tariffs->new( $db, \%conf, $admin );

  load_module( 'Dv', $html );
  load_module( 'Cards', $html );

  $login_url = get_login_url();
  if ($FORM{PIN}) {
    my $login = $FORM{LOGIN} || q{};
    my $pin   = $FORM{PIN} || q{};
    cards_card_info({ INFO_ONLY => 1 });

    if($login eq $FORM{LOGIN} && $pin eq $FORM{PASSWORD}) {
      #print "Content-Type: text/html\n\n";
      $login_url = get_login_url();
      print "Location: $login_url\n\n";
      exit;
    }
    else {
      $html->message( 'info', "$lang{GUEST_ACCOUNT}", "Wrong pin\n$lang{USER}: '$COOKIES{hotspot_username}'" );
      $html->tpl_show( templates( 'form_client_hotspot_pin' ),
        { %FORM });
    }
  }
  elsif ( $COOKIES{hotspot_username} ){
    $html->message( 'info', "$lang{GUEST_ACCOUNT}", "$lang{USER}: '$COOKIES{hotspot_username}'" );
    if ( $conf{HOTSPOT_CHECK_PHONE} ){
      cards_card_info( {
        PIN         => "$COOKIES{hotspot_password}",
        FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
        HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
          { class => 'btn btn-default btn-xs' } ),
          INFO_ONLY => 1
        } );

      $html->tpl_show( templates( 'form_client_hotspot_pin' ),
        { %FORM });
    }
    else {
      cards_card_info( {
        PIN         => "$COOKIES{hotspot_password}",
        FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
          { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
        HEADER_TEXT =>
          $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
            { class => 'btn btn-default btn-xs' } )
        } );
    }
    return 0;
  }
  elsif ( $FORM{mac} ){
    use Dv;
    my $Dv = Dv->new( $db, $admin, \%conf );
    my $list = $Dv->list( {
        #DATE => $DATE,
        PASSWORD  => '_SHOW',
        CID       => $FORM{mac},
        COLS_NAME => 1,
      } );


    if ( $Dv->{TOTAL} == 1 ){
      cards_card_info( { PIN => "$list->[0]->{PASSOWRD}",
          FOOTER_TEXT        =>
          $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '', { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
          HEADER_TEXT        =>
          $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
            { class => 'btn btn-default btn-xs' } )
        } );

      return 0;
    }
  }
  else{
    #    my $a = `echo "$DATE $TIME Can't find MAC: $FORM{mac} // $COOKIES{hotspot_user_id}" >> /tmp/mac_test`;
  }

  my $list = $tariffs->list(
    {
      PAGE_ROWS    => 1,
      SORT         => 1,
      NAME         => '_SHOW',
      PAYMENT_TYPE => 2,
      COLS_NAME    => 1,
      NEW_MODEL_TP => 1,
    }
  );

  if ( $Dv->{TOTAL} ){
    $html->message( 'info', "$lang{ERROR}", "Guest mode disable for mac '$FORM{mac}'", { } );
    #    my $a = `echo "$DATE $TIME Guest mode disable: $FORM{mac} // $COOKIES{hotspot_user_id}" >> /tmp/mac_test`;
    return 0;
  }

  my $user_mac = $FORM{mac} || $COOKIES{hotspot_user_id} || '';
  #  my $a = `echo "REG GUEST: $DATE $TIME: $FORM{mac} COOKIES: $COOKIES{hotspot_user_id} user_mac: $user_mac" >> /tmp/mac_test`;

  if ( $tariffs->{TOTAL} < 1 ){
    $html->message( 'info', "$lang{INFO}", "$lang{GUEST_ACCOUNT} $lang{DISABLE}", { } );
    return 0;
  }

  #Check phone for guest connection
  if ( $conf{HOTSPOT_CHECK_PHONE} ){
    if($FORM{PIN}) {
      return 0;
    }
    if ( defined( $FORM{PHONE} ) && !$FORM{PHONE} ){
      $html->message( 'err', $lang{ERROR}, "$lang{ERR_WRONG_PHONE}", { ID => 1505 } );
    }

    if ( !$FORM{PHONE} ){
      $html->tpl_show( templates( 'form_client_hotspot_phone' ),
        { %FORM, PHONE_PREFIX => $PHONE_PREFIX },
      );

      return 0;
    }
  }


  foreach my $line ( @{$list} ){
    $FORM{'TP_NAME'} = $line->{name};
    $FORM{'4.TP_ID'} = $line->{id};
  }

  $FORM{create} = 1;
  $FORM{COUNT} = 1;
  $FORM{SERIAL} = 'G';
  my $return = cards_users_add( { NO_PRINT => 1 } );

  $FORM{add} = 1;
  if ( ref( $return ) eq 'ARRAY' ){
    foreach my $line ( @{$return} ){
      $FORM{'1.LOGIN'} = $line->{LOGIN};
      $FORM{'1.PASSWORD'} = $line->{PASSWORD};
      $FORM{'4.CID'} = $user_mac;
      $FORM{'1.CREATE_BILL'} = 1;
      if ( $FORM{PHONE} ){
        $FORM{'3.PHONE'} = $PHONE_PREFIX . $FORM{PHONE};
      }

      $line->{UID} = dv_wizard_user( { SHORT_REPORT => 1 } );

      if ( $line->{UID} < 1 ){
        $html->message( 'err', "$lang{ERROR}", "$lang{LOGIN}: '$line->{LOGIN}'", { ID => 1506 } );

        last if (!$line->{SKIP_ERRORS});
      }
      else{
        #Confim card creation
        if ( cards_users_gen_confim( { %{$line}, SUM => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 } ) == 0 ){
          return 0;
        }

        #Sendsms
        if ( $FORM{PHONE} && in_array( 'Sms', \@MODULES ) ){
          load_module( 'Sms', $html );
          my $message = $html->tpl_show( _include( 'dv_reg_complete_sms', 'Dv' ), { %FORM, %{$line} },
            { OUTPUT2RETURN => 1 } );

          my $phone = $PHONE_PREFIX . $FORM{PHONE};

          my $sms_result = sms_send( {
              NUMBER     => $phone,
              MESSAGE    => $message,
              UID        => $line->{UID},
              RIZE_ERROR => 1,
            } );

          if ( !$sms_result ){
            $users->change( $line->{UID},
              { UID             => $line->{UID},
                DISABLE         => 1,
                ACTION_COMMENTS => 'Unknown phone',
              } );

            $html->message( 'info', '',
              $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
                { BUTTON => 2 } ) );
            return 0;
          }
        }

        # 24 hours login
        my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
        $html->set_cookies( 'hotspot_username', "$line->{LOGIN}", "$cookies_time", $html->{web_path} );
        $html->set_cookies( 'hotspot_password', "$line->{PASSWORD}", "$cookies_time", $html->{web_path} );
        $html->set_cookies( 'hotspot_card_id', "$line->{PASSWORD}", "$cookies_time", $html->{web_path} );

        $login_url = get_login_url();

        #Send email
        if ( $FORM{EMAIL} ){
          my $message = $html->tpl_show( _include( 'dv_reg_complete_mail', 'Dv' ), { %FORM }, { OUTPUT2RETURN => 1 } );
          sendmail( "$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "$lang{REGISTRATION}", "$message", "$conf{MAIL_CHARSET}", '' );
        }

        if ( $conf{HOTSPOT_CHECK_PHONE} ){
          cards_card_info( {
            SERIAL      => "$line->{SERIAL}".sprintf( "%.11d", $line->{NUMBER} ),
            FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
              { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
            HEADER_TEXT => $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
              { class => 'btn btn-default btn-xs' } ),
            INFO_ONLY => 1
          } );

          $html->tpl_show( templates( 'form_client_hotspot_pin' ),
            { %FORM },
          );
        }
        else {
          cards_card_info( {
              SERIAL      => "$line->{SERIAL}".sprintf( "%.11d", $line->{NUMBER} ),
              FOOTER_TEXT => $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
                { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ),
              HEADER_TEXT =>$html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
                { class => 'btn btn-default btn-xs' } )
            } );
        }
        #$html->{OUTPUT} .= $html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}", { BUTTON => 1 }) . ' ' . $html->button($lang{LOGIN_IN_TO_HOTSPOT}, '', { GLOBAL_URL => "$login_url", BUTTON => 1 });
      }
    }

  }
}

#**********************************************************
=head2 check_card()

=cut
#**********************************************************
sub check_card{
  load_module( 'Cards', $html );

  if ( $FORM{PIN} ){
    our $line;
    cards_card_info( { PIN => $FORM{PIN} } );

    my $buttons = '';

    if ( $FORM{LOGIN} ){
      my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
      $html->set_cookies( 'hotspot_username', $FORM{LOGIN}, "$cookies_time", $html->{web_path} );
      $html->set_cookies( 'hotspot_password', $FORM{PASSWORD}, "$cookies_time", $html->{web_path} );
      $html->set_cookies( 'hotspot_card_id', $line->{PASSWORD}, "$cookies_time",
        $html->{web_path} ) if ($line->{PASSWORD});

      $login_url = get_login_url();

      $buttons = $html->button( $lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",
        { BUTTON => 1 } )
        . ' ' . $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
        { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } );
    }
    else{
      $buttons = $html->button( $lang{RETURN_TO_START_PAGE},
        "$SELF_URL/start.cgi?DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}", { BUTTON => 1 } );
    }

    $html->{OUTPUT} .= $buttons;

    return 0;
  }

  return 1;
}

#**********************************************************
=head2 mikrotik_($attr) Mikrotik

=cut
#**********************************************************
sub mikrotik_{
  #my ($attr) = @_;

  print << "[END]";
<form method="get" action="/hotspotlogin.cgi">
   <input name="chal" value="" type="HIDDEN">
   <input name="uamip" value="$FORM{uamip}" type="HIDDEN">
   <input name="uamport" value="mikrotik" type="HIDDEN">
   <input name="nasid" value="$FORM{nasid}" type="HIDDEN">
   <input name="mac" value="$FORM{mac}" type="HIDDEN">
   <input name="userurl" value="$FORM{userurl}" type="HIDDEN">
   <input name="login" value="login" type="HIDDEN">

   <input name="skin_id" id="skin_id" value="" type="hidden">
   <input name="uid" value="$FORM{mac_id}" type="hidden">
   <input name="pwd" value="password" type="hidden">
   <input name="submit" value="LOG IN TO HOTSPOT" class="formbutton" type="submit">
</form>
[END]

}

#**********************************************************
=head2 buy_cards($attr) - Buy cards

  Arguments:
    $attr

  Returns:

=cut
#**********************************************************
sub buy_cards{
  #my ($attr) = @_;

  use Tariffs;
  my $Tariffs = Tariffs->new( $db, \%conf, $admin );
  $LIST_PARAMS{UID} = $FORM{UID};

  load_module( 'Paysys' );
  if ( $FORM{BUY_CARDS} || $FORM{PAYMENT_SYSTEM} ){
    if ( $FORM{PAYMENT_SYSTEM} && $conf{HOTSPOT_CHECK_PHONE} && !$FORM{PHONE} ){
      $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_PHONE}, { ID => 1504 } );
      $FORM{PAYMENT_SYSTEM_SELECTED} = $FORM{PAYMENT_SYSTEM};
      $FORM{PAYMENT_SYSTEM} = undef;
    }

    if ( $FORM{PAYMENT_SYSTEM} ){
      my $ret = paysys_payment( { OUTPUT2RETURN => 1,
                                  QUITE         => 1,
                                  #RETURN_URL    => $ENV{PROT}.'://'. $ENV{SERVER_NAME}.':'. $ENV{SERVER_PORT} . '/start.cgi'
                                 } );

      $Tariffs->info( $FORM{TP_ID} );

      $FORM{'5.SUM'} = $Tariffs->{ACTIV_PRICE} || $FORM{PAYSYS_SUM};
      $FORM{'5.DESCRIBE'} = "$FORM{SYSTEM_SHORT_NAME} # $FORM{OPERATION_ID}";
      $FORM{'5.EXT_ID'} = "$FORM{SYSTEM_SHORT_NAME}:$FORM{OPERATION_ID}";
      $FORM{'5.METHOD'} = 2;
      $FORM{'3.EMAIL'} = $FORM{EMAIL};

      if ( $FORM{TRUE} ){
        if ( $ret ){
          load_module( 'Dv', $html );
          load_module( 'Cards', $html );
          $FORM{'4.TP_ID'} = $Tariffs->{ID};

          $FORM{create} = 1;
          $FORM{COUNT} = 1;
          $FORM{SERIAL} = "$FORM{TP_ID}";
          my $return = cards_users_add( { NO_PRINT => 1 } );
          $FORM{add} = 1;

          if ( ref( $return ) eq 'ARRAY' ){
            foreach my $line ( @{$return} ){
              #password gen by Cards
              $FORM{'1.LOGIN'} = $FORM{OPERATION_ID};
              $FORM{'1.PASSWORD'} = $FORM{OPERATION_ID};
              $FORM{'1.CREATE_BILL'} = 1;
              $line->{UID} = dv_wizard_user( { SHORT_REPORT => 1,
                  SHOW_USER                                 => 1
                } );
              if ( $line->{UID} < 1 ){
                $html->message( 'err', "$lang{ERROR}", "$lang{LOGIN}: '$FORM{OPERATION_ID}'", { ID => 1507 } );
                last if (!$line->{SKIP_ERRORS});
              }
              else{
                #Confim card creation
                if ( cards_users_gen_confim( { %{$line},
                    LOGIN    => $FORM{'1.LOGIN'},
                    PASSWORD => $FORM{'1.PASSWORD'},
                    PIN      => $FORM{'1.PASSWORD'},
                    SUM      => ($FORM{'5.SUM'}) ? $FORM{'5.SUM'} : 0 } ) == 0 ){
                  return 0;
                }

                # 24 hours login
                my $cookies_time = gmtime( time() + $auth_cookie_time ) . " GMT";
                $html->set_cookies( 'hotspot_username', "$line->{LOGIN}", "$cookies_time", $html->{web_path} );
                $html->set_cookies( 'hotspot_password', "$line->{PASSWORD}", "$cookies_time", $html->{web_path} );
                $html->set_cookies( 'hotspot_card_id', "$line->{PASSWORD}", "$cookies_time", $html->{web_path} );

                #Attach UID to payment
                if ( $FORM{PAYSYS_ID} ){
                  if ( form_purchase_module( {
                      HEADER   => $user->{UID},
                        MODULE => 'Paysys',
                    } ) ){
                    exit;
                  }

                  my $Paysys = Paysys->new( $db, $admin, \%conf );
                  $Paysys->change( { ID => $FORM{PAYSYS_ID},
                      UID               => $line->{UID},
                      STATUS            => ($FORM{TRUE}) ? 2 : undef
                    } );
                }

                $FORM{LOGIN} = $FORM{'1.LOGIN'};
                $FORM{PASSWORD} = $FORM{'1.PASSWORD'};

                #Sendsms
                if ( $FORM{PHONE} && in_array( 'Sms', \@MODULES ) ){
                  load_module( 'Sms', $html );

                  my $message = $html->tpl_show( _include( 'dv_reg_complete_sms', 'Dv' ), { %{$Cards}, %FORM },
                    { OUTPUT2RETURN => 1 } );

                  sms_send( {
                      NUMBER    => $FORM{PHONE},
                        MESSAGE => $message,
                        UID     => $line->{UID},
                    } );
                }

                #Send email
                if ( $FORM{EMAIL} ){
                  my $message = $html->tpl_show( _include( 'dv_reg_complete_mail', 'Dv' ), { %FORM },
                    { OUTPUT2RETURN => 1 } );
                  sendmail( "$conf{ADMIN_MAIL}", "$FORM{EMAIL}", "$lang{REGISTRATION}", "$message", "$conf{MAIL_CHARSET}",
                    '' );
                }
                cards_card_info( { #SERIAL => "$line->{SERIAL}" . sprintf("%.11d", $line->{NUMBER}),
                    ID => $FORM{CARD_ID} } );

                $login_url = get_login_url();
                `echo "$DATE $TIME Login to hotspot MAC: $FORM{mac} / $COOKIES{hotspot_user_id} Card: $FORM{CARD_ID} Login: $user->{LOGIN}  UID: $line->{UID} ($login_url)" >> /tmp/mac_test`;
                $html->{OUTPUT} .= '<center>' . $html->button( $lang{LOGIN_IN_TO_HOTSPOT}, '',
                  { GLOBAL_URL => "$login_url", class => 'btn btn-success btn-lg' } ) . '</center>';
                #$html->button($lang{RETURN_TO_START_PAGE}, "DOMAIN_ID=$FORM{DOMAIN_ID}&NAS_ID=$FORM{NAS_ID}",  { BUTTON => 1}).' '.
                return '';
              }
            }

          }

          return $ret;
        }
      }
      elsif ( $FORM{FALSE} ){
        $html->message( 'err', $lang{ERROR}, $html->button( $lang{ERR_TRY_AGAIN}, "$SELF_URL", { BUTTON => 1 } ), { ID => 1509 } );
      }

      return ($ret) ? $ret : '';
    }
    else{
      $Tariffs->info( $FORM{TP_ID} );
      my $unique = mk_unique_value( 8, { SYMBOLS => '0123456789' } );
      return $html->tpl_show(
        templates( 'form_buy_cards_paysys' ),
        {
          %INFO_HASH,
          SUM               => $Tariffs->{ACTIV_PRICE},
          DESCRIBE          => '',
          OPERATION_ID      => $unique,
          UID               => "$unique:$admin->{DOMAIN_ID}",
          TP_ID             => $FORM{TP_ID},
          DOMAIN_ID         => $admin->{DOMAIN_ID} || $FORM{DOMAIN_ID},
          PAYSYS_SYSTEM_SEL => paysys_system_sel( { PAYMENT_SYSTEM => $FORM{PAYMENT_SYSTEM_SELECTED} } )
        },
        { OUTPUT2RETURN => 1 }
      );
    }
  }

  if ( $conf{DV_REGISTRATION_TP_GIDS} ){
    $LIST_PARAMS{TP_GID} = $conf{DV_REGISTRATION_TP_GIDS};
  }
  #else {
  #  $LIST_PARAMS{TP_GID} = '>0';
  #}

  $LIST_PARAMS{DOMAIN_ID} = $admin->{DOMAIN_ID};

  my $list = $Tariffs->list(
    {
      PAYMENT_TYPE     => '<2',
      TOTAL_TIME_LIMIT => '_SHOW',
      TOTAL_TRAF_LIMIT => '_SHOW',
      ACTIV_PRICE      => '_SHOW',
      AGE              => '_SHOW',
      NAME             => '_SHOW',
      %LIST_PARAMS,
      TP_ID            => $conf{HOTSPOT_TPS},
      MODULE           => 'Dv',
      COLS_NAME        => 1,
    }
  );

  #�������� ������������, ������, �� ���� ���������, ����� 䳿, �-��� ����� ����/�����
  foreach my $line ( @{$list} ){
    my $ti_list = $Tariffs->ti_list( { TP_ID => $line->{tp_id} } );
    if ( $Tariffs->{TOTAL} > 0 ){
      $Tariffs->ti_info( $ti_list->[0]->[0] );
      if ( $Tariffs->{TOTAL} > 0 ){
        $Tariffs->tt_info( { TI_ID => $ti_list->[0]->[0], TT_ID => 0 } );
      }
    }

    $INFO_HASH{CARDS_TYPE} .= $html->tpl_show(
      templates( 'form_buy_cards_card' ),
      {
        TP_NAME         => $line->{name},
        ID              => $line->{id},
        TP_ID           => $line->{tp_id},
        AGE             => $line->{age} || $lang{UNLIM},
        DOMAIN_ID       => $admin->{DOMAIN_ID},
        SPEED_IN        => $Tariffs->{IN_SPEED} || $lang{UNLIM},
        SPEED_OUT       => $Tariffs->{OUT_SPEED} || $lang{UNLIM},
        PREPAID_MINS    => ($line->{total_time_limit}) ? $line->{total_time_limit} / 60 : $lang{UNLIM},
        PREPAID_TRAFFIC => $line->{total_traf_limit} || $lang{UNLIM},
        PRICE           => $line->{activate_price} || 0.00,
      },
      { OUTPUT2RETURN => 1 }
    );
  }

  return $html->tpl_show( templates( 'form_buy_cards' ), { %INFO_HASH }, { OUTPUT2RETURN => 1 } );
}

1
