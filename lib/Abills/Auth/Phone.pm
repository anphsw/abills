package Abills::Auth::Phone;

=head1 NAME

  Auth module by mobile phone

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array);

use Users;
use Contacts;

my Contacts $Contacts;
my Users $Users;

#**********************************************************
=head2 check_access($attr)

=cut
#**********************************************************
sub check_access {
  my $self = shift;
  my ($attr) = @_;

  $Contacts = Contacts->new($self->{db}, $self->{admin}, $self->{conf});
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  if (!$attr->{PIN_CODE}) {
    return $self->send_pin($attr);
  }
  else {
    return $self->verify_pin($attr);
  }
}

#**********************************************************
=head2 verify_pin($attr)

=cut
#**********************************************************
sub verify_pin {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{AUTH_CODE}) {
    $self->{RETURN_RESULT}->{errno} = 100006;
    $self->{RETURN_RESULT}->{errstr} = 'ERR_NO_AUTH_CODE';
  }

  $Users->phone_pin_info($attr->{AUTH_CODE});

  if ($Users->{TOTAL} != 1) {
    $self->{RETURN_RESULT}->{errno} = 100007;
    $self->{RETURN_RESULT}->{errstr} = 'CODE_EXPIRED';
  }
  elsif ($Users->{ATTEMPTS} > 4) {
    $Users->phone_pin_del($attr->{AUTH_CODE});
    $self->{RETURN_RESULT}->{errno} = 100008;
    $self->{RETURN_RESULT}->{errstr} = 'USED_ALL_PIN_ATTEMPTS';
  }
  elsif ($Users->{PIN_CODE} ne $attr->{PIN_CODE}) {
    $Users->phone_pin_update_attempts($attr->{AUTH_CODE});
    $self->{RETURN_RESULT}->{errno} = 100009;
    $self->{RETURN_RESULT}->{errstr} = 'CODE_IS_INVALID';
  }
  else {
    my $contacts = $Contacts->contacts_list({
      VALUE    => "$Users->{PHONE},+$Users->{PHONE}",
      UID      => $attr->{UID} || '_SHOW',
      GROUP_BY => 'uc.uid'
    });

    if (!$Contacts->{TOTAL} || $Contacts < 0) {
      $self->{RETURN_RESULT}->{errno} = 100010;
      $self->{RETURN_RESULT}->{errstr} = 'USER_NOT_FOUND';
    }
    elsif ($Contacts->{TOTAL} == 1) {
      $Users->phone_pin_del($attr->{AUTH_CODE});
      $self->{USER_ID}      = $contacts->[0]->{uid};
      $self->{CHECK_FIELD}  = 'UID';
    }
    else {
      my $params = ();
      foreach my $contact (@{$contacts}) {
        $Users->info($contact->{uid});
        push @{$params->{users}}, { uid => $contact->{uid}, login => $Users->{LOGIN} };
      }

      $self->{RETURN_RESULT} = $params;
    }
  }

  return $self;
}

#**********************************************************
=head2 send_pin($attr)

=cut
#**********************************************************
sub send_pin {
  my $self = shift;
  my ($attr) = @_;

  if (!$attr->{PHONE}) {
    $self->{errno}  = 100001;
    $self->{errstr} = 'ERR_NO_PHONE';
    return $self;
  }

  my $search_field = "$attr->{PHONE}";

  if ($attr->{PHONE} =~ /^(380)(.+)/) {
    $search_field .= ",0$2";
    $search_field .= ",+$attr->{PHONE}";
  }
  elsif (length($attr->{PHONE}) == 10 && $attr->{PHONE} =~ /^0/) {
    $search_field .= ",38$attr->{PHONE},+38$attr->{PHONE}";
  }

  my $contacts = $Contacts->contacts_list({ VALUE => $search_field, UID => '_SHOW' });

  foreach my $contact (@{$contacts}) {
    $attr->{PHONE} = $contact->{value};
    $Users->info($contact->{uid});
    last if $Users->{UID};
  }

  if ($Contacts->{TOTAL} < 1 || !in_array('Sms', \@main::MODULES) || !$Users->{UID}) {
    $self->{RETURN_RESULT}->{errno} = 100002;
    $self->{RETURN_RESULT}->{errstr} = 'USER_NOT_FOUND';
    return $self;
  }

  if ($attr->{PIN_ALREADY_EXIST}) {
    $Users->phone_pin_info($Users->{UID});

    if ($Users->{TOTAL} != 1) {
      $self->{RETURN_RESULT}->{errno} = 100003;
      $self->{RETURN_RESULT}->{errstr} = 'CODE_EXPIRED';
      $self->{RETURN_RESULT}->{exists} = 'false';
    }
    else {
      $self->{RETURN_RESULT}->{exists} = 'true';
      $self->{RETURN_RESULT}->{auth_code} = $Users->{UID};
    }

    return $self;
  }

  my $sms_limit = $self->{conf}->{SMS_LIMIT} || 5;

  require Sms;
  Sms->import();
  my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});
  $Sms->list({
    UID      => $Users->{UID},
    INTERVAL => "$main::DATE/$main::DATE",
    NO_SKIP  => 1,
  });

  if ($Sms->{TOTAL} && $Sms->{TOTAL} >= $sms_limit) {
    $self->{RETURN_RESULT}->{errstr} = 'EXCEEDED_SMS_LIMIT';
    $self->{RETURN_RESULT}->{errno} = 100004;
    return $self;
  }

  my $pin_code = pin_generate();

  require Abills::Template;
  my $Templates = Abills::Template->new($self->{db}, $self->{admin}, $self->{conf}, {
    html    => $self->{html},
    lang    => $self->{lang},
    libpath => $self->{libpath}
  });
  my $message = $self->{html}->tpl_show($Templates->_include('sms_login_by_phone', 'Sms'), {
    LOGIN    => $Users->{LOGIN},
    PHONE    => $attr->{PHONE},
    PIN_CODE => $pin_code
  }, { OUTPUT2RETURN => 1, SKIP_DEBUG_MARKERS => 1 });

  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  my $sms_sent = $Sender->send_message({
    TO_ADDRESS  => $attr->{PHONE},
    MESSAGE     => $message,
    SENDER_TYPE => 'Sms',
    UID         => $Users->{UID},
  });

  if ($sms_sent) {
    $self->{RETURN_RESULT}->{sent} = 'true';
    $self->{RETURN_RESULT}->{auth_code} = $Users->{UID};

    $Users->phone_pin_add({ UID => $Users->{UID}, PIN_CODE => $pin_code, PHONE => $attr->{PHONE} });
  }
  else {
    $self->{RETURN_RESULT}->{sent} = 'false';
    $self->{RETURN_RESULT}->{errstr} = 'ERR_SEND_SMS';
    $self->{RETURN_RESULT}->{errno} = 100005;
  }

  return $self;
}

#**********************************************************
=head2 pin_generate()

=cut
#**********************************************************
sub pin_generate {
  my @alphanumeric = (0 .. 9);

  return join '', map $alphanumeric[rand @alphanumeric], 0 .. 4;
}

1;
