=head1 NAME

  Manage admin and user passwords

=cut

use strict;
use warnings FATAL => 'all';

our (
  $db,
  $admin,
  %conf,
  %lang,
  %FORM,
  $user,
);

our Abills::HTML $html;

#**********************************************************
=head2 form_passwd($attr)

  Arguments:
    $attr

=cut
#**********************************************************
sub form_passwd {
  my ($attr) = @_;

  my $password_form;
  my $ret  = 0;
  my $is_g2fa = 0;
  my $g2fa_message = '';
  $attr->{USER_INFO} = $user if ($user && %{$user});

  $password_form->{G2FA_HIDDEN} = 'hidden';

  if ($attr->{ADMIN}->{AID}) {
    $password_form->{HIDDDEN_INPUT} = $html->form_input('AID', $attr->{ADMIN}->{AID},{ TYPE => 'hidden', OUTPUT2RETURN => 1 });
    $index = $attr->{index} || 50;
    $is_g2fa = 1 if ($conf{AUTH_G2FA} && $attr->{ADMIN} && $attr->{ADMIN}->{G2FA});
  }
  elsif ($attr->{USER_INFO}->{UID}) {
    $password_form->{HIDDDEN_INPUT} = $html->form_input('UID', ($attr->{USER_INFO}->{UID} || $FORM{UID}), { TYPE  => 'hidden', OUTPUT2RETURN => 1 });
    $index = 15 if (!$attr->{REGISTRATION});
    $index = get_function_index('form_passwd') if ($attr->{USER_INFO}->{SID});

    if ($conf{AUTH_G2FA}) {
      $attr->{USER_INFO}->pi({ UID => $attr->{USER_INFO}->{UID} });
      $is_g2fa = 1 if ($attr->{USER_INFO}->{_G2FA});

      $g2fa_message = check_user_2FA({ USER_INFO => $attr->{USER_INFO} }) if $attr->{USER_INFO}->{SID};

      if ($attr->{USER_INFO}->{SID} && !$is_g2fa){
        require Abills::Auth::OATH;
        Abills::Auth::OATH->import();
        $password_form->{G2FA_HIDDEN} = '';

        my $secret = $FORM{g2fa_secret} || uc(mk_unique_value(32));
        $password_form->{G2FA_SECRET} = $secret;

        require Control::Qrcode;
        Control::Qrcode->import();
        my $QRCode = Control::Qrcode->new($db, $admin, \%conf, { html => $html });

        my $img_qr = $QRCode->_encode_url_to_img(Abills::Auth::OATH::encode_base32($secret), {
          AUTH_G2FA_NAME => $conf{WEB_TITLE} || 'Abills',
          AUTH_G2FA_MAIL => $attr->{USER_INFO}->{LOGIN},
          OUTPUT2RETURN  => 1,
        });

        $password_form->{G2FA_QR} = "<img src='data:image/jpg;base64," . encode_base64($img_qr) . "'>";
        $password_form->{G2FA_BUTTON} = $lang{ADD};
      }
    }
  }

  my $check_passwd = check_passwd({
    AID => $FORM{AID} || '',
    UID => $FORM{UID} || $attr->{USER_INFO}->{UID} || '',
  });

  if ($check_passwd && $check_passwd == 1){
    if ($attr->{USER_INFO}->{SID}){
      save_user_passwd({ NEW_PASSWORD => $FORM{newpassword}, USER_INFO => $attr->{USER_INFO} });
    }
    return 1;
  }

  $password_form->{PW_CHARS}   = $conf{PASSWD_SYMBOLS};
  $password_form->{PW_LENGTH}  = $conf{PASSWD_LENGTH};
  $password_form->{ACTION}     = 'change';
  $password_form->{LNG_ACTION} = $lang{CHANGE};
  $password_form->{CONFIG_PASSWORD} = $conf{CONFIG_PASSWORD} || q{};

  if ($conf{AUTH_G2FA} && $is_g2fa) {
    $password_form->{G2FA_BUTTON} = $lang{DELETE};
    $password_form->{G2FA_HIDDEN} = '' if ($attr->{USER_INFO}->{_G2FA});
    $password_form->{G2FA_REMOVE} = 1;
    $password_form->{G2FA_INPUT_HIDDEN} = 'hidden' if (!$attr->{USER_INFO}->{UID});
    $password_form->{G2FA_STYLE} = 'justify-content-center';
    $password_form->{G2FA_ACTION} = 'change';
    $password_form->{G2FA_SECRET} = $attr->{USER_INFO}->{_G2FA} if ($attr->{USER_INFO}->{_G2FA});
  }

  if(! $FORM{generated_pw} || ! $FORM{newpassword} || ! $FORM{confirm}) {
    $password_form->{newpassword}=mk_unique_value($password_form->{PW_LENGTH},
      {  SYMBOLS => $password_form->{PW_CHARS} });
    $password_form->{confirm}=$password_form->{newpassword};
  }

  if ($g2fa_message) {
    $password_form->{G2FA_MESSAGE} = $g2fa_message;
  }

  $html->tpl_show(templates('form_password'), $password_form);

  return $ret;
}

#**********************************************************
=head2 check_passwd()

  Attr:
    AID
    UID

=cut
#**********************************************************
sub check_passwd {
  my ($attr) = @_;

  if (!$FORM{newpassword}) {
    return 0;
  }

  if (length($FORM{newpassword}) < $conf{PASSWD_LENGTH}) {
    $lang{ERR_SHORT_PASSWD} =~ s/6/$conf{PASSWD_LENGTH}/;
    $html->message( 'err', $lang{ERROR}, "$lang{ERR_SHORT_PASSWD} $conf{PASSWD_LENGTH}");
    return 0;
  }

  if ($conf{CONFIG_PASSWORD}
    && ( $attr->{AID} || ( $conf{PASSWD_POLICY_USERS} && $attr->{UID}) )
    && !Conf::check_password($FORM{newpassword}, $conf{CONFIG_PASSWORD})
  ){
    load_module('Config', $html);
    my $explain_string = config_get_password_constraints($conf{CONFIG_PASSWORD});

    $html->message( 'err', $lang{ERROR}, "$lang{ERR_PASSWORD_INSECURE} $explain_string");
    return 0;
  }

  if ($attr->{AID}) {
    $admin->password_blacklist_match({ PASSWORD => $FORM{newpassword}, AID => $attr->{AID}, COLS_NAME => 1 });
    if ($admin->{TOTAL_MATCH} && $admin->{TOTAL_MATCH} > 0) {
      $html->message('err', $lang{ERROR}, $lang{ERR_PASSWORD_NOT_ALLOWED});
      return 0;
    }
  }

  if ($FORM{newpassword} eq $FORM{confirm}) {
    $FORM{PASSWORD} = $FORM{newpassword};
    return 1;
  }
  else {
    $html->message( 'err', $lang{ERROR}, $lang{ERR_WRONG_CONFIRM} );
    return 0;
  }
  
  return 0;
}

#**********************************************************
=head2 save_user_passwd($attr) - save user password on user portal

    Attr:
     NEW_PASSWORD
     USER_INFO

=cut
#**********************************************************
sub save_user_passwd {
  my ($attr) = @_;
  my $user_ = $attr->{USER_INFO};

  my %INFO = (
    PASSWORD => $attr->{NEW_PASSWORD},
    UID      => $user_->{UID},
    DISABLE  => $user_->{DISABLE}
  );

  $user->change($user_->{UID}, \%INFO);

  if (!_error_show($user_)) {
    $html->message('info', $lang{INFO}, $lang{CHANGED});
    # strange fix for IPTV module when changing the password
    cross_modules('payments_maked', { USER_INFO => $user_ });
  }

  return 0;
}

#**********************************************************
=head2 check_user_2FA ($attr) - user verification two-factor authentication

    Attr:
      USER_INFO

=cut
#**********************************************************
sub check_user_2FA {
  my ($attr) = @_;
  my $user_ = $attr->{USER_INFO};

  $user_->pi({ UID => $user_->{UID} });

  my $g2fa_message = "";

  if ($FORM{g2fa}) {
    require Abills::Auth::Core;
    Abills::Auth::Core->import();
    my $Auth = Abills::Auth::Core->new({ CONF => \%conf, AUTH_TYPE => 'OATH' });

    if ($Auth->check_access({ PIN => $FORM{g2fa}, SECRET => $FORM{g2fa_secret} })) {
      if ($FORM{g2fa_remove}) {
        $user_->pi_change({ UID => $user_->{UID}, _G2FA => '' });
      }
      else {
        $user_->pi_change({ UID => $user_->{UID}, _G2FA => $FORM{g2fa_secret} });
      }
      $g2fa_message = $html->message('info', $lang{SUCCESS}, '', { OUTPUT2RETURN => 1 });
    }
    else {
      $g2fa_message = $html->message('err', $lang{ERROR}, $lang{G2FA_WRONG_CODE}, { OUTPUT2RETURN => 1 });
    }
  }

  return $g2fa_message;
}

1;