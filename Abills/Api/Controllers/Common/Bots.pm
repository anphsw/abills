package Api::Controllers::Common::Bots;
=head NAME

  Bots manage

  Endpoints:
    /user/bots/*
    or
    /bots/*

=cut
use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Control::Contacts;

my $Errors;
my $Contacts_user;
my $Contacts_admin;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Contacts_user = Control::Contacts->new($db, $admin, $conf, { role => 'user' });
  $Contacts_admin = Control::Contacts->new($db, $admin, $conf, { role => 'admin' });

  $Errors = $self->{attr}->{Errors};

  $self->{bot_type} = {
    5 => 'Viber',
    6 => 'Telegram'
  };

  return $self;
}

#**********************************************************
=head2 post_bots_subscribe_phone($path_params, $query_params)

  Endpoint POST /bots/subscribe/phone/

=cut
#**********************************************************
sub post_bots_subscribe_phone {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$query_params->{PHONE}) {
    return $Errors->throw_error(1770010, { lang_vars => { FIELD => 'phone' } });
  }

  $query_params->{PHONE} =~ s/\D//g;

  if ($self->{conf}->{TELEGRAM_NUMBER_EXPR}) {
    my ($left, $right) = split '/', $self->{conf}->{TELEGRAM_NUMBER_EXPR};

    $query_params->{PHONE} =~ s/$left/$right/ge;
  }

  my $user_contacts = $Contacts_user->contacts_list({
    TYPE  => $path_params->{bot},
    VALUE => $path_params->{user_id},
    UID   => '_SHOW'
  });
  if ($user_contacts->{total} && $user_contacts->{total} > 0) {
    return {
      result => 'Already subscribed',
      code   => 1,
      user   => 'true'
    };
  }

  my $admin_contacts = $Contacts_admin->contacts_list({
    TYPE           => $path_params->{bot},
    VALUE          => $path_params->{user_id},
    SKIP_AID_CHECK => '_SHOW'
  });
  if ($admin_contacts->{total} && $admin_contacts->{total} > 0) {
    return {
      result => 'Already subscribed',
      code   => 1,
      user   => 'false'
    };
  }

  my $user_contacts_by_phone = $Contacts_user->contacts_list({
    VALUE  => $query_params->{PHONE},
    UID   => '_SHOW'
  });
  if ($user_contacts_by_phone->{total} && $user_contacts_by_phone->{total} > 0) {
    my $result = $Contacts_user->add_contact($user_contacts_by_phone->{list}->[0]->{uid}, {
      TYPE_ID  => $path_params->{bot},
      VALUE    => $path_params->{user_id},
      PRIORITY => 0,
    });

    if ($result->{errno}) {
      return $result;
    }

    return {
      result => 'Successfully added',
      code   => 2,
      user   => 'true'
    };
  }

  my $admin_contacts_by_phone = $Contacts_admin->contacts_list({
    VALUE          => $query_params->{PHONE},
    AID            => '_SHOW',
    SKIP_AID_CHECK => 1
  });
  if ($admin_contacts_by_phone->{total} && $admin_contacts_by_phone->{total} > 0) {
    my $result = $Contacts_admin->add_contact($admin_contacts_by_phone->{list}->[0]->{aid}, {
      TYPE_ID  => $path_params->{bot},
      VALUE    => $path_params->{user_id},
      PRIORITY => 0,
    });

    if ($result->{errno}) {
      return $result;
    }

    return {
      result => 'Successfully added',
      code   => 2,
      user   => 'false'
    };
  }

  return $Errors->throw_error(1770009);
}

#**********************************************************
=head2 post_bots_subscribe($path_params, $query_params)

  Endpoint POST /bots/subscribe/

=cut
#**********************************************************
sub post_bots_subscribe {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if (!$query_params->{TOKEN}) {
    return $Errors->throw_error(1770004, { lang_vars => { FIELD => 'token' } });
  }

  my ($type, $sid) = $query_params->{TOKEN} =~ m/^([uae])_([a-zA-Z0-9]+)/x;

  if (!$type || !$sid) {
    return $Errors->throw_error(1770005);
  }

  if ($type eq 'u') {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->web_session_info({ SID => $sid });

    if (!$Users->{UID}) {
      return $Errors->throw_error(1770006);
    }

    my $user_contacts = $Contacts_user->contacts_list({
      TYPE  => $path_params->{bot},
      VALUE => $path_params->{user_id},
      UID   => '_SHOW',
    });

    if (defined $user_contacts->{total} && $user_contacts->{total} == 0) {
      my $result = $Contacts_user->add_contact($Users->{UID}, {
        TYPE_ID  => $path_params->{bot},
        VALUE    => $path_params->{user_id},
        PRIORITY => 0,
      });
      if ($result->{errno}) {
        return $result;
      }

      $self->{admin}{MODULE} = $self->{bot_type}{$path_params->{bot}};
      $self->{admin}->action_add($Users->{UID}, "ID: $path_params->{user_id}", { TYPE => 62 });

      return {
        result => 'Successfully added',
        code   => 2,
        user   => 'true',
      };
    }
    else {
      return {
        result => 'Already subscribed',
        code   => 1,
        user   => 'true',
      };
    }
  }
  elsif ($type eq 'e' || $type eq 'a') {
    my $bot_id = $path_params->{user_id};
    my $admin = $self->{admin};
    $admin->online_info({ SID => $sid });

    my $aid = $admin->{AID};

    if (!$aid) {
      return $Errors->throw_error(1770008);
    }

    my $admin_contacts = $Contacts_admin->contacts_list({
      TYPE           => 6,
      VALUE          => $bot_id,
      SKIP_AID_CHECK => 1
    });

    if (defined $admin_contacts->{total} && $admin_contacts->{total} == 0) {
      my $result = $Contacts_admin->add_contact($aid, {
        TYPE_ID  => $path_params->{bot},
        VALUE    => $bot_id,
        PRIORITY => 0
      });
      if ($result->{errno}) {
        return $result;
      }

      $admin->{MODULE} = $self->{bot_type}{6};
      $admin->action_add(undef, "ID: $bot_id", { TYPE => 62 });

      return {
        result => 'Successfully added',
        code   => 2,
        user   => 'false'
      };
    }
    else {
      return {
        result => 'Already subscribed',
        code   => 1,
        user   => 'false'
      };
    }
  }
  else {
    return $Errors->throw_error(1770007);
  }
}

#**********************************************************
=head2 _bots_subscribe_link() return subscribe link for bots

  BOT
  SID

=cut
#**********************************************************
sub _bots_subscribe_link {
  my $self = shift;
  my ($attr) = @_;

  my $bot_link = q{};

  if (uc "$attr->{BOT}" eq 'VIBER') {
    if (!$self->{conf}->{VIBER_BOT_NAME}) {
      return $Errors->throw_error(1770001);
    }

    $bot_link = "viber://pa?chatURI=$self->{conf}->{VIBER_BOT_NAME}&context=$attr->{SID}&text=/start";
  }
  elsif (uc "$attr->{BOT}" eq 'TELEGRAM') {
    if (!$self->{conf}->{TELEGRAM_BOT_NAME}) {
      return $Errors->throw_error(1770002);
    }

    $bot_link = "https://t.me/$self->{conf}->{TELEGRAM_BOT_NAME}?start=$attr->{SID}";
  }
  else {
    return $Errors->throw_error(1770003)
  }

  return {
    bot_link => $bot_link
  };
}

#**********************************************************
=head2 bots_subscribe_link() return subscribe qrcode image for bots

=cut
#**********************************************************
sub _bots_subscribe_qrcode {
  my $self = shift;
  my ($attr) = @_;

  my $bot_link = $self->_bots_subscribe_link($attr);

  return $bot_link if ($bot_link->{errno});

  require Control::Qrcode;
  Control::Qrcode->import();

  my $QRCode = Control::Qrcode->new($self->{db}, $self->{admin}, $self->{conf}, { html => $self->{html} });
  my $qr_code_image = $QRCode->qr_make_image_from_string($bot_link->{bot_link});

  return $qr_code_image;
}

1;
