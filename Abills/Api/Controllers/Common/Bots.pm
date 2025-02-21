package Api::Controllers::Common::Bots;
=head NAME

  Portal articles manage

  Endpoints:
    /user/bots/*
    or
    /bots/*

=cut
use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Contacts;

my Contacts $Contacts;
my Control::Errors $Errors;

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

  $Contacts = Contacts->new($db, $admin, $conf);

  $Errors = $self->{attr}->{Errors};

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

  my $admin = $self->{admin};

  my $check_list = $Contacts->contacts_list({
    TYPE  => $path_params->{bot},
    VALUE => $path_params->{user_id},
    UID   => '_SHOW',
  });

  my $check_list_admin = $admin->admins_contacts_list({
    TYPE           => $path_params->{bot},
    VALUE          => $path_params->{user_id},
    SKIP_AID_CHECK => 1
  });

  if ($Contacts->{TOTAL} && scalar(@{$check_list}) > 0) {
    return {
      result => 'Already subscribed',
      code   => 1,
      user   => 'true'
    };
  }
  elsif (scalar(@{$check_list_admin}) > 0) {
    return {
      result => 'Already subscribed',
      code   => 1,
      user   => 'false'
    };
  }

  my $list = $Contacts->contacts_list({
    VALUE => $query_params->{PHONE},
    UID   => '_SHOW',
  });

  my $alist = $admin->admins_contacts_list({
    VALUE          => $query_params->{PHONE},
    AID            => '_SHOW',
    SKIP_AID_CHECK => 1
  });

  if ($Contacts->{TOTAL} && $list->[0]->{uid}) {
    $Contacts->contacts_add({
      UID      => $list->[0]->{uid},
      TYPE_ID  => $path_params->{bot},
      VALUE    => $path_params->{user_id},
      PRIORITY => 0,
    });

    return {
      result => 'Successfully added',
      code   => 2,
      user   => 'true'
    };
  }
  elsif (scalar @{$alist}) {
    $admin->admin_contacts_add({
      AID      => $alist->[0]->{aid},
      TYPE_ID  => $path_params->{bot},
      VALUE    => $path_params->{user_id},
      PRIORITY => 0,
    });

    return {
      result => 'Successfully added',
      code   => 2,
      user   => 'false'
    };
  }
  else {
    return $Errors->throw_error(1770009);
  }
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

  my ($type, $sid) = $query_params->{TOKEN} =~ m/^([uae])_([a-zA-Z0-9]+)/;

  if (!$type || !$sid) {
    return $Errors->throw_error(1770005);
  }

  if ("$type" eq 'u') {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
    $Users->web_session_info({ SID => $sid });

    if (!$Users->{UID}) {
      return $Errors->throw_error(1770006);
    }

    my $list = $Contacts->contacts_list({
      TYPE  => $path_params->{bot},
      VALUE => $path_params->{user_id},
      UID   => '_SHOW',
    });

    if (!$Contacts->{TOTAL} || scalar(@{$list}) == 0) {
      $Contacts->contacts_add({
        UID      => $Users->{UID},
        TYPE_ID  => $path_params->{bot},
        VALUE    => $path_params->{user_id},
        PRIORITY => 0,
      });

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
  elsif ("$type" eq 'e' || "$type" eq 'a') {
    my $bot_id = $path_params->{user_id};
    my $admin = $self->{admin};
    $admin->online_info({ SID => $sid });

    my $aid = $admin->{AID};

    if (!$aid) {
      return $Errors->throw_error(1770008);
    }

    my $list = $admin->admins_contacts_list({
      TYPE           => 6,
      VALUE          => $bot_id,
      SKIP_AID_CHECK => 1
    });

    if (!$admin->{TOTAL} || scalar(@{$list}) == 0) {
      $admin->admin_contacts_add({
        AID      => $aid,
        TYPE_ID  => $path_params->{bot},
        VALUE    => $bot_id,
        PRIORITY => 0,
      });

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
