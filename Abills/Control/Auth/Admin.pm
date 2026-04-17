package Control::Auth::Admin;

use strict;
use warnings FATAL => 'all';
use POSIX qw(strftime);
use Abills::Templates;
use Abills::Base qw(sendmail decode_base64 mk_unique_value in_array check_ip);

our(
  %lang,
  %err_strs,
  $PROGRAM,
);

my Admins $admin;
my Abills::HTML $html;
my $SELF_URL = q{};
my %COOKIES;
my $DATE  = strftime("%Y-%m-%d", localtime(time));

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    $attr
      USER

  Returns:
    object

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin_, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin_,
    conf    => $conf,
    lang    => $attr->{LANG} || {},
    html    => $attr->{HTML},
    libpath => $attr->{libpath} || ''
  };

  $admin = $admin_;
  $html = $self->{html};

  $SELF_URL = $Abills::HTML::SELF_URL;
  %COOKIES =  %Abills::HTML::COOKIES;

  bless($self, $class);

  return $self;
}


#**********************************************************
=head2 admin_auth($attr) - Primary auth form

  Arguments:
    $attr
      FORM

  Returns:
    TRUE or FALSE

=cut
#**********************************************************
sub auth_admin {
  my ($self, $attr)=@_;

  my $lang_loaded = 0;

  $self->load_lang($self->{html});
  Abills::Templates::template_init({
    LIB   => $self->{libpath},
    ADMIN => $self->{admin},
    HTML  => $self->{html},
    FORM  => $attr,
    LANG  => $self->{lang},
    CONF  => $self->{conf}
  });

  #Cookie auth
  if ($self->{conf}{AUTH_METHOD}) {
    if ($attr->{index} && $attr->{index} == 10) {
      $admin->online_del({ SID => $COOKIES{admin_sid} });
    }

    $lang_loaded = 1;
    my $res = $self->check_permissions($attr->{user}, $attr->{passwd}, $COOKIES{admin_sid}, $attr);
    if (! $res) {
      if ($attr->{REFERER} && $attr->{REFERER} =~ m/$SELF_URL/x && $attr->{REFERER} !~ m/index=10/x) {
        $html->set_cookies('admin_sid', $admin->{SID}, '', '');
        $COOKIES{admin_sid} = $admin->{SID};
        $admin->online({
          SID      => $admin->{SID},
          TIMEOUT  => $self->{conf}{web_session_timeout},
          EXT_INFO => $ENV{HTTP_USER_AGENT}
        });
        print "Location: $attr->{REFERER}\n\n";
      }
    }
    else {
      $self->auth_admin_fail({ %$attr, RES => $res });
    }
  }
  else {
    $self->auth_apache_basic($attr);
  }

  if (!$lang_loaded) {
    $self->load_lang($html);
  }

  return $admin->{AID} || 0;
}

#**********************************************************
=head3 auth_admin_fail($attr) - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:
    FALSE

=cut
#**********************************************************
sub auth_admin_fail {
  my ($self, $attr)=@_;

  my $cookie_sid = ($COOKIES{admin_sid} || '');
  my $admin_sid = ($admin->{SID} || '');
  my $res = $attr->{RES};

  if ($attr->{AJAX} || $attr->{json}){
    print "Content-Type:application/json\n\n";
    print qq{{"TYPE":"error","errstr":"Access Deny","sid":"$cookie_sid","aid":"$admin_sid","errno":"$res"}};
  }
  elsif($attr->{xml}){
    print "Content-Type:application/xml\n\n";
    print << "[END]";
    <?xml version="1.0" encoding="UTF-8"?>
        <error>
          <TYPE>error</TYPE>
          <errstr>Access Deny</errstr>
          <errno>$res</errno>
          <sid>$cookie_sid</sid>
          <aid>$admin_sid</aid>
        </error>
[END]
  }
  else {
    $html->{METATAGS} = Abills::Templates::templates('metatags');
    print %{ $admin->{SETTINGS} };
    print $html->header();
    my $err = '';

    if ( $admin->{errno} ) {
      if ( $admin->{errno} == 4 ) {
        $err = $lang{ERR_WRONG_PASSWD};
      }
      elsif ($attr->{user} && $attr->{passwd}) {
        $err = $admin->{errstr};
      }
    }
    delete $admin->{AID};
    $self->form_login({ %$attr, ERROR => $err });
    print "<!-- Access Deny. Auth cookie: $cookie_sid System: $admin_sid .$res -->";
  }

  return 0;
}


#**********************************************************
=head3 forgot_passwd($attr) - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:

=cut
#**********************************************************
sub forgot_passwd {
  my ($self, $attr)=@_;

  if ($attr->{email}) {
    require Digest::SHA;
    Digest::SHA->import('sha256_hex');
    $admin->list({ EMAIL => $attr->{email} });
    if ($admin->{TOTAL} > 0) {
      my $digest = Digest::SHA::sha256_hex("$attr->{email}$DATE 1234567890");
      my $message = "Go to the following link to change your password. \n $SELF_URL?index=10&recovery_passwd=$digest";
      sendmail($self->{conf}{ADMIN_MAIL}, $attr->{email}, "$PROGRAM Password Repair", $message, $self->{conf}{MAIL_CHARSET}, "");
      $html->message('info', 'E-mail sended.');
    }
    else {
      $html->message('error', 'ERR_WRONG_EMAIL');
    }
  }
  else {
    $html->tpl_show(templates('form_admin_forgot_passwd'), $attr);
  }

  return 1;
}

#**********************************************************
=head3 recovery_passwd($attr) - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:

=cut
#**********************************************************
sub recovery_passwd {
  my ($self, $attr)=@_;

  require Digest::SHA;
  Digest::SHA->import('sha256_hex');
  my $admins_list = $admin->list({
    EMAIL     => '_SHOW',
    COLS_NAME => 1
  });
  foreach (@$admins_list) {
    my $digest = Digest::SHA::sha256_hex("$_->{email}$DATE 1234567890");
    if ($digest eq $attr->{recovery_passwd}) {
      if ($attr->{newpassword}) {
        my $admin_form = Admins->new($self->{db}, $self->{conf});
        $admin_form->info($_->{aid});
        $admin_form->change({ PASSWORD => $attr->{newpassword}, AID => $_->{aid} });
        if (!$admin_form->{errno}) {
          $html->message('info', $self->{lang}{CHANGED}, $self->{lang}{CHANGED});
        }
      }
      else {
        my $password_form;
        $password_form->{PW_CHARS}      = $self->{conf}{PASSWD_SYMBOLS};
        $password_form->{PW_LENGTH}     = $self->{conf}{PASSWD_LENGTH};
        $password_form->{ACTION}        = 'change';
        $password_form->{LNG_ACTION}    = $self->{lang}{CHANGE};
        $password_form->{HIDDDEN_INPUT} = $html->form_input('recovery_passwd', $digest, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
        $html->tpl_show(templates('form_password'), $password_form);
      }
      last;
    }
  }

  return 1;
}

#**********************************************************
=head3 form_login($attr) - Admin http login page

  Arguments:
    $attr
      ERROR
      G2FA

  Returns:

=cut
#**********************************************************
sub form_login {
  my ($self, $attr) = @_;

  if ($attr->{forgot_passwd} && $self->{conf}{ADMIN_PASSWORD_RECOVERY}) {
    return $self->forgot_passwd($attr);
  }
  elsif ($attr->{recovery_passwd}) {
    return $self->recovery_passwd($attr);
  }

  my %first_page = ();

  # if ($conf{tech_works}) {
  #   $html->message( 'info', $lang{INFO}, $conf{tech_works} );
  #   return 0;
  # }

  my %LANG = ('english' => 'English');
  if ($self->{conf}{LANGS}) {
    $self->{conf}{LANGS} =~ s/\n//xg;
    my (@lang_arr) = split(';', $self->{conf}{LANGS});
    foreach my $l (@lang_arr) {
      my ($lang, $lang_name) = split(':', $l);
      $lang =~ s/^\s+//x;
      $LANG{$lang} = $lang_name;
    }
  }

  my %QT_LANG = (
    byelorussian => 22,
    bulgarian    => 20,
    english      => 31,
    french       => 37,
    polish       => 90,
    russian      => 96,
    ukrainian    => 129,
  );

  $first_page{SEL_LANGUAGE} = $html->form_select('language', {
    SELECTED   => $html->{language},
    SEL_HASH   => \%LANG,
    NO_ID      => 1,
    EXT_PARAMS => { qt_locale => \%QT_LANG }
  });

  $first_page{TITLE} = $lang{AUTH};

  if (! $attr->{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER}  =~ m/$SELF_URL/x) {
    $attr->{REFERER} = $ENV{HTTP_REFERER};
  }

  if($attr->{ERROR}) {
    $first_page{ERROR_MSG} = $html->message( 'danger text-center', $lang{ERROR}, $attr->{ERROR}, {
      OUTPUT2RETURN => 1
    } );
  }

  if ($self->{conf}{TECH_WORKS}) {
    $first_page{TECH_WORKS_BLOCK_VISIBLE} = 1;
    $first_page{TECH_WORKS_MESSAGE} = $self->{conf}{TECH_WORKS};
  }

  if ($self->{conf}{ADMIN_PASSWORD_RECOVERY}) {
    $first_page{PSWD_BTN} = $html->button("$lang{FORGOT_PASSWORD}?", "index=10&forgot_passwd=1");
  }

  $first_page{G2FA_hidden} = 'hidden';
  if($attr->{G2FA}){
    $first_page{G2FA_hidden} = '';
    $first_page{password} = $attr->{password};
  }

  if ($attr->{DOMAIN_ID} && $attr->{DOMAIN_ID} =~ m/^(\d+)$/x) {
    $first_page{DOMAIN_ID}=$attr->{DOMAIN_ID};
  }
  if ($attr->{REFERER} && $attr->{REFERER} =~ m/$SELF_URL/x) {
    $attr->{REFERER} =~ s/>/&gt;/xg;
    $attr->{REFERER} =~ s/</&lt;/xg;
    $first_page{REFERER} = $attr->{REFERER};
  }

  $html->tpl_show(templates('form_login'), \%first_page, $attr);

  return 1;
}

#**********************************************************
=head2 check_permissions($login, $password, $session_sid, $attr) - Checkadmin permission

  Arguments:
    $login
    $password
    $session_sid
    $attr
      API_KEY | key
      FULL_INFO
      API
      ADMIN_INFO  - Admin Obj
      g2fa

  Returns:

    0 - Access
    1 - Deny
    2 - Disable
    3 - Deny IP
    4 - Wrong passwd or bruteforce
    5 - Wrong LDAP Auth
    6 - Deny IP/Time
    7 - Bruteforce

=cut
#**********************************************************
sub check_permissions {
  my ($self, $login, $password, $session_sid, $attr) = @_;

  if($self->{admin}) {
    $admin = $self->{admin};
  }

  $login    = '' if (!defined($login));
  $password = '' if (!defined($password));
  my $REMOTE_ADDR = $ENV{REMOTE_ADDR} || '0.0.0.0';

  if ($self->{conf}{AUTH_X_FORWARDED} && $self->{conf}{AUTH_X_DOMAIN} && in_array($ENV{HTTP_HOST}, [ split(',\s?', $self->{conf}{AUTH_X_DOMAIN}) ])) {
    $REMOTE_ADDR = $ENV{$self->{conf}{AUTH_X_FORWARDED}} || q{}; #if ($ENV{$self->{conf}{AUTH_X_FORWARDED}});
  }

  if ($self->{conf}{ADMINS_ALLOW_IP}) {
    $self->{conf}{ADMINS_ALLOW_IP} =~ s/\s//xg;
    my @allow_ips_arr = split(',', $self->{conf}{ADMINS_ALLOW_IP});
    my %allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $REMOTE_ADDR }) {
      if($self->{conf}{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->system_action_add("$login:$password DENY IP: $REMOTE_ADDR", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  my %PARAMS = (
    IP    => ($REMOTE_ADDR eq '::1') ? '0.0.0.1' : $REMOTE_ADDR,
    SHORT => $attr->{FULL_INFO} ? 0 : 1
  );

  # if($PARAMS{IP} eq '::1') {
  #   $PARAMS{IP} = '0.0.0.1';
  # }
  #Rudements
  #$login    =~ s/"/\\"/xg;
  #$login    =~ s/'/\\'/xg;
  #$password =~ s/"/\\"/xg;
  #$password =~ s/'/\\'/xg;

  if ($session_sid && ! $login && (! $attr->{API_KEY} && ! $attr->{key})) {
    $admin->online_info({ SID => $session_sid });
    if ($admin->{TOTAL} > 0
      && ((! $self->{conf}{ADMIN_MULTI_IP_ACCESS} && $REMOTE_ADDR eq $admin->{IP})
      || ($self->{conf}{ADMIN_MULTI_IP_ACCESS} && $ENV{HTTP_USER_AGENT} eq $admin->{EXT_INFO}))
    ) {
      $admin->{SID} = $session_sid;
    }
    else {
      $admin->online_del({ SID => $session_sid });
    }
  }
  else {
    if (! $session_sid) {
      $self->{html}->get_cookies();
      $admin->{SID} = $COOKIES{admin_sid};
    }
    else {
      $admin->{SID} = mk_unique_value(14);
    }

    if($attr->{API_KEY}
      || ($self->{conf}{US_API} && $attr->{key})) {
      $PARAMS{API_KEY}   = $attr->{API_KEY} || $attr->{key} || q{123};

      $admin->admin_bruteforce_list({
        REMOTE_ADDR => $REMOTE_ADDR,
        CHECK       => 1,
        %PARAMS
      });

      if ($admin->{TOTAL} && $admin->{TOTAL} > 5) {
        return 4;
      }
    }
    #LDAP auth
    elsif($self->{conf}{LDAP_IP}) {
      require Abills::Auth::Core;
      Abills::Auth::Core->import();
      my $Auth = Abills::Auth::Core->new({
        CONF      => $self->{conf},
        AUTH_TYPE => 'Ldap'
      });

      my $result = $Auth->check_access({
        LOGIN    => $login,
        PASSWORD => $password
      });

      if ($result) {
        $PARAMS{LOGIN}   = $login;
        $PARAMS{EXTERNAL_AUTH} = 'ldap';
      }
      else {
        $admin->{errno} = 5;
        $admin->{errstr}= $Auth->{errstr};

        if (! $self->{conf}{AUTH_CASCADE}) {
          return 2;
        }
        $PARAMS{LOGIN}   = $login;
        $PARAMS{PASSWORD}= $password;
      }
    }
    else {
      $PARAMS{LOGIN}   = $login;
      $PARAMS{PASSWORD}= $password;
    }
  }

  $admin->info($admin->{AID}, \%PARAMS);

  if ($login && $password) {
    if ($self->{conf}{ADMIN_BRUTE_PERIOD} && $self->{conf}{ADMIN_BRUTE_LIMIT}) {
      # Check brutefarce
      if(! $admin->{errno}) {
        $admin->system_action_list({
          AID        => $admin->{AID},
          TYPE       => 11,
          PERIOD     => "<" . $self->{conf}{ADMIN_BRUTE_PERIOD},
          TOTAL_ONLY => 1
        });

        if ($admin->{TOTAL} && $admin->{TOTAL} > $self->{conf}{ADMIN_BRUTE_LIMIT}) {
          $admin->{errno}  = 4;
          $admin->{errstr} = 'BRUTEFORCE';
          return 4;
        }
      }
    }

    if (!$attr->{g2fa}) {
      if ($admin->{G2FA}) {
        $attr->{user} = $login;
        $attr->{password} = $password;
        $attr->{G2FA} = 1;
        return 7;
      }
    }
    else {
      require Abills::Auth::Core;
      Abills::Auth::Core->import();
      my $Auth = Abills::Auth::Core->new({
        CONF      => $self->{conf},
        AUTH_TYPE => 'OATH',
        FORM      => $attr
      });

      if (!$Auth->check_access({ SECRET => $admin->{G2FA}, PIN => $attr->{g2fa} })) {
        $admin->{errno}  = 5;
        $admin->{errstr} = 'ERROR_WRONG_PIN';
        $attr->{G2FA} = 1;
        return 2;
      }
    }
  }

  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      if($self->{conf}{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->{MODULE}=q{};
      $admin->system_action_add("$login:$password", { TYPE => 11 });
      $admin->{errno} = 4;
    }
    elsif ($admin->{errno} == 2) {
      #TODO add also for admin panel auth with login ad pass
      if ($PARAMS{API_KEY}) {
        $admin->admin_bruteforce_add({
          #TODO think in which format store api key it, directly not hidden not the best choice
          API_KEY     => 'plug',
          REMOTE_ADDR => $REMOTE_ADDR
        });
      }

      return 2;
    }

    return 1;
  }
  elsif ($admin->{DISABLE} == 1) {
    $admin->system_action_add("Disabled admin $login tried to login", { TYPE => 11 });
    $admin->{errno}  = 2;
    $admin->{errstr} = 'DISABLED';
    return 2;
  }
  elsif ($admin->{DISABLE} == 2) {
    $admin->system_action_add("Fired admin $login tried to login", { TYPE => 11 });
    $admin->{errno}  = 2;
    $admin->{errstr} = 'FIRED';
    return 2;
  }
  elsif ($admin->{EXPIRE} && $admin->{EXPIRE} ne '0000-00-00 00:00:00' && $admin->{EXPIRE} lt $DATE ) {
    $admin->system_action_add("Expired admin $login tried to login", { TYPE => 11 });
    $admin->{errno}  = 2;
    $admin->{errstr} = 'EXPIRED';
    return 2;
  }

  if ($admin->{WEB_OPTIONS}) {
    my @WO_ARR = split(';', $admin->{WEB_OPTIONS});
    foreach my $line (@WO_ARR) {
      my ($k, $v) = split('=', $line, 2);
      next if(! $k);
      $admin->{SETTINGS}{$k} = $v;

      if ($html)  {
        if($k eq 'language' && $attr->{language}) {
          $v = $attr->{language};
        }
        $html->{$k}=$v;
      }
    }
  }

  if ($admin->{ADMIN_ACCESS}) {
    my $ret = $self->admin_access();
    if($ret) {
      return $ret;
    }
  }

  my $permissions = $admin->get_permissions();

  if($permissions->{0} && $permissions->{0}{17}) {
    $html->{EXPORT_LIST}=1;
  }
  if ($permissions->{4} && $permissions->{4}{7}) {
    $html->{CHANGE_TPLS}=1;
  }

  if ($attr->{API}) {
    $admin->online({
      SID     => $admin->{SID},
      EXT_INFO=> $ENV{HTTP_USER_AGENT} || q{},
      TIMEOUT => $self->{conf}{web_session_timeout}
    });
  }

  if ($password && $login) {
    my $params = $ENV{HTTP_USER_AGENT} || q{};
    $params .= ($admin->{GT}) ? ' '.$admin->{GT} : q{};
    $admin->full_log_add( {
      FUNCTION_INDEX => 0,
      AID            => $admin->{AID},
      FUNCTION_NAME  => 'ADMIN_AUTH',
      DATETIME       => 'NOW()',
      IP             => $REMOTE_ADDR,
      SID            => $admin->{SID},
      PARAMS         => $params
    });
  }

  if (!$admin->{SID}) {
    $admin->{SID} = mk_unique_value(14);
  }

  return 0;
}

#**********************************************************
=head2 admin_access() - Check admin time access

  Arguments:
    $attr
  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub admin_access {
  my ($self) = @_;

  my $REMOTE_ADDR = $self->{admin}->{SESSION_IP};
  my $access_list = $admin->access_list({
    AID       => $self->{admin}->{AID},
    DISABLE   => 0,
    COLS_NAME => 1
  });

  my $deny = ($admin->{TOTAL}) ? 1 : 0;
  my $TIME    = strftime("%H:%M:%S", localtime(time));
  foreach my $access (@$access_list) {
    my $time       = $TIME;
    $time          =~ s/://xg;
    $access->{begin} =~ s/://xg;
    $access->{end}   =~ s/://xg;
    my $wday = (localtime(time))[6];

    if ((! $access->{day} || $wday+1 == $access->{day})
      && $time > $access->{begin} && $time < $access->{end}) {
      if ($access->{bit_mask} && check_ip($REMOTE_ADDR, "$access->{ip}/$access->{bit_mask}")) {
        $deny = 0;
        last;
      }
      elsif ($access->{ip} eq '0.0.0.0' || !$access->{bit_mask} && check_ip($REMOTE_ADDR, $access->{ip})) {
        $deny = 0;
        last;
      }
    }
  }

  if ($deny) {
    $self->{admin}->{MODULE}='';
    $self->{admin}->system_action_add("DENY IP: $REMOTE_ADDR", { TYPE => 50 });
    return 6;
  }

  return 0;
}

#**********************************************************
=head2 load_lang($html_) - Small lang loader

  Arguments:
    $attr
  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub load_lang {
  my ($self, $html_)=@_;

  my $fallback_locale = 'english';
  my $is_fallback = 0;

  if (!$html_ || !$html_->{language}) {
    $html_->{language} = $fallback_locale;
    $is_fallback = 1;
  }

  $is_fallback = 1 if (!$is_fallback && $html->{language} eq $fallback_locale);
  do "language/$fallback_locale.pl";

  if (!$is_fallback) {
    if ($html_->{language} =~ /^([\s+&:#-\@\w.]+)$/xm) {
      $html_->{language} = $1; #data is now untainted
    }
    else {
      print "Content-Type:text/html\n\n";
      print "bad data\n";
    }

    eval{ do "language/$html_->{language}.pl" };
    if ($@) {
      print "Content-Type: text/plain\n\n";
      print "Can't load language\n";
      print $@;
      print ">> language/$html_->{language}.pl << ";
      exit;
    }
  }

  $self->{lang} = \%lang;

  return  1;
}

#**********************************************************
=head2 auth_apache_basic($attr)

  Arguments:
    $attr
      ADMIN_INFO

  Results:


apache.conf - IF Mod rewrite enabled Basic Auth

      <IfModule mod_rewrite.c>
          RewriteEngine on
          RewriteCond %{HTTP:Authorization} ^(.*)
          RewriteRule ^(.*) - [E=HTTP_CGI_AUTHORIZATION:%1]
          Options Indexes ExecCGI SymLinksIfOwnerMatch
      </IfModule>
      Options Indexes ExecCGI FollowSymLinks

=cut
#**********************************************************
sub auth_apache_basic {
  my($self, $attr)=@_;

  if (! defined($ENV{HTTP_CGI_AUTHORIZATION})) {
    print "'mod_rewrite' not install";
    return 0;
  }

  $ENV{HTTP_CGI_AUTHORIZATION} =~ s/basic\s+//ix;
  my ($REMOTE_USER, $REMOTE_PASSWD) = split(':', decode_base64($ENV{HTTP_CGI_AUTHORIZATION}));

  if ($REMOTE_USER) {
    $REMOTE_USER = substr($REMOTE_USER, 0, 20);
    $REMOTE_USER =~ s/\\//xg;
  }
  else {
    $REMOTE_USER = q{};
  }
  if ($REMOTE_PASSWD) {
    $REMOTE_PASSWD = substr($REMOTE_PASSWD, 0, 20);
    $REMOTE_PASSWD =~ s/\\//xg;
  }

  my $res = $self->check_permissions($REMOTE_USER, $REMOTE_PASSWD, undef, $attr);
  if ($res == 1) {
    print "WWW-Authenticate: Basic realm=\"$self->{conf}{WEB_TITLE} Billing System\"\n";
    print "Status: 401 Unauthorized\n";
  }
  elsif ($res == 2) {
    print "WWW-Authenticate: Basic realm=\"Billing system / '$REMOTE_USER' Account Disabled\"\n";
    print "Status: 401 Unauthorized\n";
  }

  if ($admin->{errno}) {
    #load_lang();
    $html->{METATAGS} = templates('metatags');
    print $html->header();

    my $message = $lang{ERR_ACCESS_DENY};

    if ($admin->{errno} == 2) {
      $message = "$lang{ACCOUNT_DISABLE} $lang{OR} $admin->{errstr}";
    }
    elsif ($admin->{errno} == 3) {
      $message = $lang{ERR_UNALLOW_IP};
    }
    elsif ($admin->{errno} == 4) {
      $message = $lang{ERR_WRONG_PASSWD} || 'ERR_WRONG_PASSWD';
    }
    else {
      $message = $err_strs{ $admin->{errno} };
    }

    print $html->element('div',
      $html->message('err', $lang{ERROR}, $message, { OUTPUT2RETURN => 1 }),
      { class => 'p-5' }
    );
    exit;
  }

  return 1;
}

1;