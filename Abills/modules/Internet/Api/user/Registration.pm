package Internet::Api::user::Registration;

=head1 NAME

  User Internet Regisration

  DEPRECATED

  Endpoints:
    /user/internet/registration/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array mk_unique_value/;
use Control::Errors;
use Internet;

my Internet $Internet;
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

  $Internet = Internet->new($self->{db}, $self->{admin}, $self->{conf});
  $Internet->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 post_user_internet_registration($path_params, $query_params)

  Endpoint GET /user/internet/registration/

=cut
#**********************************************************
sub post_user_internet_registration {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10091,
    errstr => 'Service not available',
  } if ($self->{conf}->{NEW_REGISTRATION_FORM});

  return {
    errno  => 10011,
    errstr => 'Service not available',
  } if (!in_array('Internet', \@main::MODULES) || !in_array('Internet', \@main::REGISTRATION));

  return {
    errno  => 10040,
    errstr => 'Service not available',
  } if ($self->{conf}->{REGISTRATION_PORTAL_SKIP});

  return {
    errno  => 10012,
    errstr => 'Invalid login',
  } if (!$query_params->{LOGIN});

  return {
    errno  => 10013,
    errstr => 'Invalid email',
  } if (!$query_params->{EMAIL} || $query_params->{EMAIL} !~ /(([^<>()[\]\\.,;:\s\@\"]+(\.[^<>()[\]\\.,;:\s\@\"]+)*)|(\".+\"))\@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))/);

  return {
    errno  => 10014,
    errstr => 'Invalid phone',
  } if (!$query_params->{PHONE} || ($self->{conf}->{PHONE_FORMAT} && $query_params->{PHONE} !~ m/$self->{conf}->{PHONE_FORMAT}/));

  my $password = q{};

  if ($self->{conf}->{REGISTRATION_PASSWORD}) {
    return {
      errno  => 10037,
      errstr => 'No field password',
    } if (!$query_params->{PASSWORD});

    return {
      errno  => 10038,
      errstr => "Length of password not valid minimum $self->{conf}->{PASSWD_LENGTH}",
    } if ($self->{conf}->{PASSWD_LENGTH} && $self->{conf}->{PASSWD_LENGTH} > length($query_params->{PASSWORD}));

    return {
      errno  => 10039,
      errstr => "Password not valid, allowed symbols $self->{conf}->{PASSWD_SYMBOLS}",
    } if ($self->{conf}->{PASSWD_SYMBOLS} && $query_params->{PASSWORD} !~ /[$self->{conf}->{PASSWD_SYMBOLS}]/);

    $password = $query_params->{PASSWORD};
  }

  #TODO: add a street GET PATH and validate it if enabled $conf{INTERNET_REGISTRATION_ADDRESS}
  #TODO: add referral

  if (!$password) {
    $password = mk_unique_value($self->{conf}->{PASSWD_LENGTH}, { SYMBOLS => $self->{conf}->{PASSWD_SYMBOLS} });
  }

  my $cid = q{};

  if ($self->{conf}->{INTERNET_REGISTRATION_IP}) {
    return {
      errno  => 10015,
      errstr => 'Invalid ip',
    } if (!$query_params->{USER_IP} || $query_params->{USER_IP} eq '0.0.0.0');

    require Internet::Sessions;
    Internet::Sessions->import();

    my $Sessions = Internet::Sessions->new($self->{db}, $self->{admin}, $self->{conf});
    $Sessions->online({
      CLIENT_IP => $query_params->{USER_IP},
      CID       => '_SHOW',
      GUEST     => 1,
      COLS_NAME => 1
    });

    if ($Sessions->{TOTAL}) {
      $cid = $Sessions->{list}->[0]->{cid};
    }

    return {
      errno  => 10016,
      errstr => 'IP address and MAC was not found',
    } if (!$cid);
  }

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Users->add({
    LOGIN       => $query_params->{LOGIN},
    CREATE_BILL => 1,
    PASSWORD    => $password,
    GID         => $self->{conf}->{REGISTRATION_GID},
    PREFIX      => $self->{conf}->{REGISTRATION_PREFIX},
  });

  if ($Users->{errno}) {
    return {
      errno  => 10023,
      errstr => 'Invalid login of user',
    } if ($Users->{errno} eq 10);

    return {
      errno  => 10024,
      errstr => 'User already exist',
    } if ($Users->{errno} eq 7);

    return {
      errno  => 10018,
      errstr => 'Error occurred during creation of user',
    };
  }

  my $uid = $Users->{UID};
  $Users->info($uid);

  $Users->pi_add({
    UID   => $uid,
    FIO   => $query_params->{FIO},
    EMAIL => $query_params->{EMAIL},
    PHONE => $query_params->{PHONE}
  });

  if ($Users->{errno}) {
    $Users->del({
      UID => $uid,
    });

    return {
      errno  => 10019,
      errstr => 'Error occurred during add pi info of user',
    };
  }

  if ($query_params->{TP_ID}) {
    require Tariffs;
    Tariffs->import();
    my $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});

    my $tp_list = $Tariffs->list({
      MODULE       => 'Internet',
      TP_ID        => $query_params->{TP_ID},
      TP_GID       => '_SHOW',
      NEW_MODEL_TP => 1,
      COLS_NAME    => 1,
      STATUS       => '0',
    });

    if ($tp_list && scalar @{$tp_list} < 1) {
      $Users->del({
        UID => $uid,
      });

      return {
        errno  => 10020,
        errstr => 'No tariff plan with this tpId',
      };
    }
    elsif ($self->{conf}->{INTERNET_REGISTRATION_TP_GIDS} && !in_array($tp_list->{tp_gid}, $self->{conf}->{INTERNET_REGISTRATION_TP_GIDS})) {
      $Users->del({
        UID => $uid,
      });

      return {
        errno  => 10021,
        errstr => 'Not available tariff plan',
      };
    }
  }

  $Internet->user_add({
    UID    => $uid,
    TP_ID  => $query_params->{TP_ID} || $self->{conf}->{REGISTRATION_DEFAULT_TP} || 0,
    STATUS => 2,
    CID    => $cid
  });

  if ($query_params->{REGISTRATION_TAG} && $self->{conf}->{AUTH_ROUTE_TAG} && in_array('Tags', \@main::MODULES)) {
    require Tags;
    Tags->import();

    my $Tags = Tags->new($self->{db}, $self->{conf}, $self->{admin});
    $Tags->tags_user_change({
      IDS => $self->{conf}->{AUTH_ROUTE_TAG},
      UID => $uid,
    });
  }

  if ($Internet->{errno}) {
    $Users->del({
      UID => $uid,
    });

    return {
      errno  => 10022,
      errstr => 'Failed create Internet service',
    };
  }

  my $prot = (defined($ENV{HTTPS}) && $ENV{HTTPS} =~ /on/i) ? 'https' : 'http';
  my $addr = (defined($ENV{HTTP_HOST})) ? "$prot://$ENV{HTTP_HOST}/index.cgi" : '';

  ::load_module("Abills::Templates", { LOAD_PACKAGE => 1 });
  my $message = $self->{html}->tpl_show(::_include('internet_reg_complete_sms', 'Internet'), {
    %$Internet, %$query_params,
    PASSWORD => "$password",
    BILL_URL => $addr
  }, { OUTPUT2RETURN => 1 });

  require Abills::Sender::Core;
  Abills::Sender::Core->import();
  my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

  if (in_array('Sms', \@main::MODULES) && $self->{conf}->{INTERNET_REGISTRATION_SEND_SMS}) {
    $Sender->send_message({
      TO_ADDRESS  => $query_params->{PHONE},
      MESSAGE     => $message,
      SENDER_TYPE => 'Sms',
      UID         => $uid
    });
  }
  else {
    $Sender->send_message({
      TO_ADDRESS   => $query_params->{EMAIL},
      MESSAGE      => $message,
      SUBJECT      => $self->{lang}->{REGISTRATION},
      SENDER_TYPE  => 'Mail',
      QUITE        => 1,
      CONTENT_TYPE => $self->{conf}->{REGISTRATION_MAIL_CONTENT_TYPE} ? $self->{conf}->{REGISTRATION_MAIL_CONTENT_TYPE} : '',
    });
  }

  my %result = (
    result => "Successfully created user with uid: $uid",
  );

  $result{redirect_url} = $self->{conf}->{REGISTRATION_REDIRECT} if ($self->{conf}->{REGISTRATION_REDIRECT});
  $result{password} = $password if ($self->{conf}->{REGISTRATION_SHOW_PASSWD});

  return \%result;
}

1;
