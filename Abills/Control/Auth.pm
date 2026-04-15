=head1 NAME


=cut

use strict;
use warnings FATAL => 'all';
use Abills::Base qw(sendmail decode_base64 mk_unique_value in_array check_ip);

require Abills::Misc;

our(
  $db,
  %conf,
  %lang,
  %err_strs,
  %LANG,
  %permissions,
  %FORM,
  $index,
  %COOKIES,
  $SELF_URL,
  $DATE,
  $TIME,
  #$user,
  $sid,
  $PAGE_ROWS,
  $PROGRAM,
  %LIST_PARAMS,
  $libpath
);

our Admins $admin;
our Abills::HTML $html;

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
  my ($attr)=@_;
  my $lang_loaded = 0;

  load_lang($html);
  template_init({
    LIB   => $libpath,
    ADMIN => $admin,
    HTML  => $html,
    FORM  => \%FORM,
    LANG  => \%lang,
    CONF  => \%conf
  });

  #Cookie auth
  if ($conf{AUTH_METHOD}) {
    if ($index == 10) {
      $admin->online_del({ SID => $COOKIES{admin_sid} });
    }

    $lang_loaded = 1;
    my $res = check_permissions($attr->{user}, $attr->{passwd}, $COOKIES{admin_sid}, \%FORM);

    if (! $res) {
      if ($attr->{REFERER} && $attr->{REFERER} =~ m/$SELF_URL/x && $attr->{REFERER} !~ m/index=10/x) {
        $html->set_cookies('admin_sid', $admin->{SID}, '', '');
        $COOKIES{admin_sid} = $admin->{SID};
        $admin->online({
          SID      => $admin->{SID},
          TIMEOUT  => $conf{web_session_timeout},
          EXT_INFO => $ENV{HTTP_USER_AGENT}
        });
        print "Location: $attr->{REFERER}\n\n";
      }
    }
    else {
      auth_admin_fail({ %$attr, RES => $res });
    }
  }
  else {
    auth_apache_basic($attr);
  }

  if (!$lang_loaded) {
    load_lang($html);
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
  my ($attr)=@_;

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
    $html->{METATAGS} = templates('metatags');
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

    form_login({ ERROR => $err });
    print "<!-- Access Deny. Auth cookie: $cookie_sid System: $admin_sid .$res -->";
  }

   return 0;
}

#**********************************************************
=head3 form_login() - Admin http login page

  Arguments:
    $attr
      ERROR

  Returns:

=cut
#**********************************************************
sub form_login {
  my ($attr) = @_;

  if ($FORM{forgot_passwd} && $conf{ADMIN_PASSWORD_RECOVERY}) {
    if ($FORM{email}) {
      require Digest::SHA;
      Digest::SHA->import('sha256_hex');
      $admin->list({ EMAIL => $FORM{email} });
      if ($admin->{TOTAL} > 0) {
        my $digest = Digest::SHA::sha256_hex("$FORM{email}$DATE 1234567890");
        my $message = "Go to the following link to change your password. \n $SELF_URL?index=10&recovery_passwd=$digest";
        sendmail("$conf{ADMIN_MAIL}", "$FORM{email}", "$PROGRAM Password Repair", "$message", "$conf{MAIL_CHARSET}", "");
        $html->message('info', 'E-mail sended.');
      }
      else {
        $html->message('error', 'Wrong e-mail.');
      }
      exit;
    }
    else {
      $html->tpl_show(templates('form_admin_forgot_passwd'), \%FORM);
      exit;
    }
  }
  elsif ($FORM{recovery_passwd}) {
    require Digest::SHA;
    Digest::SHA->import('sha256_hex');
    my $admins_list = $admin->list({
      EMAIL     => '_SHOW',
      COLS_NAME => 1
    });
    foreach (@$admins_list) {
      my $digest = Digest::SHA::sha256_hex("$_->{email}$DATE 1234567890");
      if ($digest eq $FORM{recovery_passwd}) {
        if ($FORM{newpassword}) {
          my $admin_form = Admins->new($db, \%conf);
          $admin_form->info($_->{aid});
          $admin_form->change({ PASSWORD => $FORM{newpassword}, AID => $_->{aid} });
          if (!$admin_form->{errno}) {
            $html->message('info', $lang{CHANGED}, "$lang{CHANGED} ");
          }
        }
        else {
          my $password_form;
          $password_form->{PW_CHARS}      = $conf{PASSWD_SYMBOLS};
          $password_form->{PW_LENGTH}     = $conf{PASSWD_LENGTH};
          $password_form->{ACTION}        = 'change';
          $password_form->{LNG_ACTION}    = "$lang{CHANGE}";
          $password_form->{HIDDDEN_INPUT} = $html->form_input('recovery_passwd', $digest, { TYPE => 'hidden', OUTPUT2RETURN => 1 });
          $html->tpl_show(templates('form_password'), $password_form);
        }
        last;
      }
    }
    exit;
  }

  my %first_page = ();

  # if ($conf{tech_works}) {
  #   $html->message( 'info', $lang{INFO}, $conf{tech_works} );
  #   return 0;
  # }

  #Make active lang list
  if ($conf{LANGS}) {
    $conf{LANGS} =~ s/\n//xg;
    my (@lang_arr) = split(';', $conf{LANGS});
    %LANG = ();
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

  if (! $FORM{REFERER} && $ENV{HTTP_REFERER} && $ENV{HTTP_REFERER}  =~ m/$SELF_URL/x) {
    $FORM{REFERER} = $ENV{HTTP_REFERER};
  }

  if($attr->{ERROR}) {
    $first_page{ERROR_MSG} = $html->message( 'danger text-center', $lang{ERROR}, $attr->{ERROR}, {
        OUTPUT2RETURN => 1
      } );
  }

  if ($conf{TECH_WORKS}) {
    $first_page{TECH_WORKS_BLOCK_VISIBLE} = 1;
    $first_page{TECH_WORKS_MESSAGE} = $conf{TECH_WORKS};
  }

  if ($conf{ADMIN_PASSWORD_RECOVERY}) {
    $first_page{PSWD_BTN} = $html->button("$lang{FORGOT_PASSWORD}?", "index=10&forgot_passwd=1");
  }

  $first_page{G2FA_hidden} = 'hidden';
  if($FORM{G2FA}){
    $first_page{G2FA_hidden} = '';
    $first_page{password} = $FORM{password};
  }

  if ($FORM{DOMAIN_ID} && $FORM{DOMAIN_ID} =~ m/^(\d+)$/x) {
    $first_page{DOMAIN_ID}=$FORM{DOMAIN_ID};
  }
  if ($FORM{REFERER} && $FORM{REFERER} =~ m/$SELF_URL/x) {
    $FORM{REFERER} =~ s/>/&gt;/xg;
    $FORM{REFERER} =~ s/</&lt;/xg;
    $first_page{REFERER} = $FORM{REFERER};
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
  my ($login, $password, $session_sid, $attr) = @_;

  if($attr->{ADMIN_INFO}) {
    $admin = $attr->{ADMIN_INFO};
  }

  $login    = '' if (!defined($login));
  $password = '' if (!defined($password));
  my $REMOTE_ADDR = $ENV{REMOTE_ADDR} || '0.0.0.0';

  if ($conf{AUTH_X_FORWARDED} && $conf{AUTH_X_DOMAIN} && in_array($ENV{HTTP_HOST}, [ split(',\s?', $conf{AUTH_X_DOMAIN}) ])) {
    $REMOTE_ADDR = $ENV{$conf{AUTH_X_FORWARDED}} if ($ENV{$conf{AUTH_X_FORWARDED}});
  }

  if ($conf{ADMINS_ALLOW_IP}) {
    $conf{ADMINS_ALLOW_IP} =~ s/\s//xg;
    my @allow_ips_arr = split(',', $conf{ADMINS_ALLOW_IP});
    my %allow_ips_hash = ();
    foreach my $ip (@allow_ips_arr) {
      $allow_ips_hash{$ip} = 1;
    }
    if (!$allow_ips_hash{ $REMOTE_ADDR }) {
      if($conf{HIDE_WRONG_PASSWORD}) {
        $password = '****';
      }
      $admin->system_action_add("$login:$password DENY IP: $REMOTE_ADDR", { TYPE => 11 });
      $admin->{errno} = 3;
      return 3;
    }
  }

  my %PARAMS = (
    IP    => $REMOTE_ADDR || '0.0.0.0',
    SHORT => $attr->{FULL_INFO} ? 0 : 1
  );

  if($PARAMS{IP} eq '::1') {
    $PARAMS{IP} = '0.0.0.1';
  }

  $login    =~ s/"/\\"/xg;
  $login    =~ s/'/\\'/xg;
  $password =~ s/"/\\"/xg;
  $password =~ s/'/\\'/xg;

  if ($session_sid && ! $login && (! $attr->{API_KEY} && ! $attr->{key})) {
    $admin->online_info({ SID => $session_sid });
    if ($admin->{TOTAL} > 0
      && ((! $conf{ADMIN_MULTI_IP_ACCESS} && $REMOTE_ADDR eq $admin->{IP})
         || ($conf{ADMIN_MULTI_IP_ACCESS} && $ENV{HTTP_USER_AGENT} eq $admin->{EXT_INFO}))
    ) {
      $admin->{SID} = $session_sid;
    }
    else {
      $admin->online_del({ SID => $session_sid });
    }
  }
  else {
    if (! $session_sid) {
      Abills::HTML::get_cookies();
      $admin->{SID} = $COOKIES{admin_sid};
    }
    else {
      $admin->{SID} = mk_unique_value(14);
    }

    if($attr->{API_KEY}
      || ($conf{US_API} && $attr->{key})) {
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
    elsif($conf{LDAP_IP}) {
      require Abills::Auth::Core;
      Abills::Auth::Core->import();
      my $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
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

        if (! $conf{AUTH_CASCADE}) {
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
    if ($conf{ADMIN_BRUTE_PERIOD} && $conf{ADMIN_BRUTE_LIMIT}) {
      # Check brutefarce
      if(! $admin->{errno}) {
        $admin->system_action_list({
          AID        => $admin->{AID},
          TYPE       => 11,
          PERIOD     => "<" . $conf{ADMIN_BRUTE_PERIOD},
          TOTAL_ONLY => 1
        });

        if ($admin->{TOTAL} && $admin->{TOTAL} > $conf{ADMIN_BRUTE_LIMIT}) {
          $admin->{errno}  = 4;
          $admin->{errstr} = 'BRUTEFORCE';
          return 4;
        }
      }
    }

    if (!$FORM{g2fa}) {
      if ($admin->{G2FA}) {
        $FORM{user} = $login;
        $FORM{password} = $password;
        $FORM{G2FA} = 1;
        return 7;
      }
    }
    else {
      require Abills::Auth::Core;
      Abills::Auth::Core->import();
      my $Auth = Abills::Auth::Core->new({
        CONF      => \%conf,
        AUTH_TYPE => 'OATH',
        FORM      => \%FORM
      });

      if (!$Auth->check_access({ SECRET => $admin->{G2FA}, PIN => $FORM{g2fa} })) {
        $admin->{errno}  = 5;
        $admin->{errstr} = 'ERROR_WRONG_PIN';
        $FORM{G2FA} = 1;
        return 2;
      }
    }
  }

  if ($admin->{errno}) {
    if ($admin->{errno} == 4) {
      if($conf{HIDE_WRONG_PASSWORD}) {
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

    if($admin->{SETTINGS}{PAGE_ROWS} ) {
      $PAGE_ROWS = $FORM{PAGE_ROWS} || $admin->{SETTINGS}{PAGE_ROWS};
      $LIST_PARAMS{PAGE_ROWS}=$PAGE_ROWS;
    }
  }

  if ($admin->{ADMIN_ACCESS}) {
    my $access_list = $admin->access_list({
      AID       => $admin->{AID},
      DISABLE   => 0,
      COLS_NAME => 1
    });

    my $deny = ($admin->{TOTAL}) ? 1 : 0;
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
      $admin->{MODULE}='';
      $admin->system_action_add("DENY IP: $REMOTE_ADDR", { TYPE => 50 });
      return 6;
    }
  }

  %permissions = %{ $admin->get_permissions() };

  if(defined($permissions{0}) && $permissions{0}{17}) {
    $html->{EXPORT_LIST}=1;
  }
  if (defined($permissions{4}) && $permissions{4}{7}) {
    $html->{CHANGE_TPLS}=1;
  }

  if ($attr->{API}) {
    $admin->online({
      SID     => $admin->{SID},
      EXT_INFO=> $ENV{HTTP_USER_AGENT} || q{},
      TIMEOUT => $conf{web_session_timeout}
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
=head2 load_lang($html_) - Small lang loader

  Arguments:
    $attr
  Results:
    TRUE or FALSE

=cut
#**********************************************************
sub load_lang {
  my ($html_)=@_;
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
  my($attr)=@_;

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

  my $res = check_permissions($REMOTE_USER, $REMOTE_PASSWD, undef, $attr);
  if ($res == 1) {
    print "WWW-Authenticate: Basic realm=\"$conf{WEB_TITLE} Billing System\"\n";
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
