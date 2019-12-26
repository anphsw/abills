=head1 NAME

  Telegram auth
=cut

use strict;
use warnings FATAL => 'all';

our (
  $Contacts,
  $Users,
  $admin,
  $Bot
);

#**********************************************************
=head2 get_uid($chat_id)
  
=cut
#**********************************************************
sub get_uid {
  my ($chat_id) = @_;
  my $list = $Contacts->contacts_list({
    TYPE  => 6,
    VALUE => $chat_id,
    UID   => '_SHOW',
  });

  return 0 if ($Contacts->{TOTAL} < 1);

  return $list->[0]->{uid};
}

#**********************************************************
=head2 get_aid($chat_id)

=cut
#**********************************************************
sub get_aid {
  my ($chat_id) = @_;

  my $list = $admin->admins_contacts_list({
    TYPE  => 6,
    VALUE => $chat_id,
    AID   => '_SHOW',
  });

  return 0 if ($admin->{TOTAL} < 1);

  return $list->[0]->{aid};
}

#**********************************************************
=head2 subscribe($message)
  
=cut
#**********************************************************
sub subscribe {
  my ($message) = @_;
  my ($type, $sid) = $message->{text} =~ m/^\/start ([ua])_([a-zA-Z0-9]+)/;

  if ($type && $sid && $type eq 'u') {
    my $uid = $Users->web_session_find($sid);
    if ($uid) {
      my $list = $Contacts->contacts_list({
        TYPE  => 6,
        VALUE => $message->{chat}{id},
      });
      
      if ( !$Contacts->{TOTAL} || scalar (@{$list}) == 0 ) {
        $Contacts->contacts_add({
          UID      => $uid,
          TYPE_ID  => 6,
          VALUE    => $message->{chat}{id},
          PRIORITY => 0,
        });
      }
    }
  }
  elsif ($type && $sid && $type eq 'a') {
    $admin->online_info({SID => $sid});
    my $aid = $admin->{AID};
    if ( $aid ) {
      my $list = $admin->admins_contacts_list({
        TYPE  => 6,
        VALUE => $message->{chat}{id},
      });
      
      if ( !$admin->{TOTAL} || scalar (@{$list}) == 0 ) {
        $admin->admin_contacts_add({
          AID      => $aid,
          TYPE_ID  => 6,
          VALUE    => $message->{chat}{id},
          PRIORITY => 0,
        });
        $Bot->send_message({
          text         => "Welcome admin.",
          reply_markup => { 
            remove_keyboard => "true"
          },
        });
      }
    }
    exit 0;
  }
  else {
    subscribe_info();
    exit 0;
  }

  return 1;
}

#**********************************************************
=head2 subscribe_phone($message)
  
=cut
#**********************************************************
sub subscribe_phone {
  my ($message) = @_;

  # Веб клиент и андроид передают телефон без плюса, виндовс приложение - с плюсом.
  my $phone = $message->{contact}{phone_number};
  $phone =~ s/\D//g;
  my $list = $Contacts->contacts_list({
    VALUE => $phone,
    UID   => '_SHOW',
  });

  my $alist = $admin->admins_contacts_list({
    VALUE => $phone,
    AID   => '_SHOW',
  });

  if ($Contacts->{TOTAL} && $list->[0]->{uid}) {
    $Contacts->contacts_add({
      UID      => $list->[0]->{uid},
      TYPE_ID  => 6,
      VALUE    => $message->{chat}{id},
      PRIORITY => 0,
    });
  }
  elsif ($admin->{TOTAL} && $alist->[0]->{aid}) {
    $admin->admin_contacts_add({
      AID      => $alist->[0]->{aid},
      TYPE_ID  => 6,
      VALUE    => $message->{chat}{id},
      PRIORITY => 0,
    });
    $Bot->send_message({
      text         => "Welcome admin.",
      reply_markup => { 
        remove_keyboard => "true"
      },
    });
    exit 0;
  }
  else {
    $Bot->send_message({
      text => "Абонент с таким телефоном не зарегистрирован.",
    });
    subscribe_info();
    exit 0;
  }
  
  return 1;
}
#**********************************************************
=head2 subscribe_info()
  print HOWTO subscribe text
  
=cut
#**********************************************************
sub subscribe_info {
   my @keyboard = ();
  my $button = {
    text => "Подтвердить телефон",
    request_contact => "true",
  };
  push (@keyboard, [$button]);

  $Bot->send_message({
    text         => "Для подключения телеграм-бота нажмите <b>Подтвердить телефон</b> или используйте кнопку <b>Подписаться</b> в кабинете пользователя.",
    reply_markup => { 
      keyboard        => \@keyboard,
      resize_keyboard => "true",
    },
    parse_mode   => 'HTML'
  });

  return 1;
}

1;