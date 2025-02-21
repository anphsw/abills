package Api::Controllers::User::User_core::Password;

=head1 NAME

  User API Password

  Endpoints:
    /user/password/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;
use Control::Errors;

my Control::Errors $Errors;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_password_send($path_params, $query_params)

  Endpoint POST /user/password/send/

=cut
#**********************************************************
sub post_user_password_send {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 1000001,
    errstr => 'SERVICE_NOT_ENABLED',
  } if (!$self->{conf}->{USER_SEND_PASSWORD});

  ::load_module('Abills::Templates', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Abills/Templates.pm'}));

  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->pi({ UID => $path_params->{uid} });
  $Users->info($path_params->{uid}, { SHOW_PASSWORD => 1 });

  my $send_status = 0;
  my $type = '';

  if (in_array('Sms', \@main::MODULES) && ($Users->{PHONE} || $Users->{CELL_PHONE})) {
    $type = 'sms';
    my $sms_number = $Users->{CELL_PHONE} || $Users->{PHONE};
    my $message = $self->{html}->tpl_show(::_include('sms_password_recovery', 'Sms'), $Users, { OUTPUT2RETURN => 1 });

    $send_status = $Sender->send_message({
      TO_ADDRESS  => $sms_number,
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
      UID         => $Users->{UID},
    });
  }
  else {
    $type = 'email';
    my $message = $self->{html}->tpl_show(::templates('email_password_recovery'), $Users, { OUTPUT2RETURN => 1 });

    $send_status = $Sender->send_message({
      TO_ADDRESS   => $Users->{EMAIL},
      MESSAGE      => $message,
      SUBJECT      => $main::PROGRAM,
      SENDER_TYPE  => 'Mail',
      QUITE        => 1,
      UID          => $Users->{UID},
      CONTENT_TYPE => $self->{conf}->{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} ? $self->{conf}->{PASSWORD_RECOVERY_MAIL_CONTENT_TYPE} : '',
    });
  }

  return {
    result      => 'Successfully send password',
    send_status => $send_status,
    type        => $type
  };
}

#**********************************************************
=head2 post_user_password_recovery($path_params, $query_params)

  Endpoint POST /user/password/recovery/

=cut
#**********************************************************
sub post_user_password_recovery {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Control::Registration_mng;
  my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf}, { HTML => $self->{html}, LANG => $self->{lang} });

  return $Registration_mng->password_recovery($query_params);
}

#**********************************************************
=head2 post_user_reset_password($path_params, $query_params)

  Endpoint POST /user/reset/password/

=cut
#**********************************************************
sub post_user_reset_password {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10032,
    errstr => 'Service not available',
  } if (!$self->{conf}->{user_chg_passwd});

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  if ($self->{conf}->{group_chg_passwd}) {
    $Users->info($path_params->{uid});

    return {
      errno  => 10033,
      errstr => 'Service not available',
    } if ("$Users->{GID}" ne "$self->{conf}->{group_chg_passwd}");
  }

  return {
    errno  => 10036,
    errstr => 'No field password',
  } if (!$query_params->{PASSWORD});

  return {
    errno  => 10034,
    errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
  } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

  return {
    errno  => 10035,
    errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
  } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

  $Users->change($path_params->{uid}, {
    PASSWORD => $query_params->{PASSWORD},
    UID      => $path_params->{uid},
  });

  return {
    errno  => 10030,
    errstr => 'Failed to change user password',
  } if ($Users->{errno});

  return {
    result => 'Successfully changed password'
  };
}

#**********************************************************
=head2 post_user_reset_password($path_params, $query_params)

  Endpoint POST /user/reset/password/

=cut
#**********************************************************
sub post_user_password_reset {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Control::Registration_mng;
  my $Registration_mng = Control::Registration_mng->new($self->{db}, $self->{admin}, $self->{conf},
    { HTML => $self->{html}, LANG => $self->{lang} }
  );

  return $Registration_mng->password_reset($query_params);
}

1;
