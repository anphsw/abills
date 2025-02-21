package Api::Controllers::Admin::Admins;

=head1 NAME

  ADMIN API Admins

  Endpoints:
    /admins/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Admins;

my Control::Errors $Errors;
my Admins $Admins;

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

  $Errors = $self->{attr}->{Errors};
  $Admins = Admins->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 post_admins_login($path_params, $query_params)

  Endpoint POST /admins/login/

=cut
#**********************************************************
sub post_admins_login {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 1000002,
    errstr => 'ERR_AUTH_PASSWORD_LOGIN_DISABLED',
  } if !$self->{conf}->{API_ADMIN_AUTH_LOGIN} || !$self->{conf}->{AUTH_METHOD};

  return {
    errno  => 1000003,
    errstr => 'ERR_NO_LOGIN',
  } if !$query_params->{LOGIN};

  return {
    errno  => 1000004,
    errstr => 'ERR_NO_PASSWORD'
  } if !$query_params->{PASSWORD};

  %main::FORM = ();

  my $status = ::check_permissions($query_params->{LOGIN}, $query_params->{PASSWORD}, 'plug', {
    API       => 1,
    FULL_INFO => 1
  });

  if (!$status) {
    my %params = (
      sid => $self->{admin}->{SID} || '',
    );

    #TODO: delete it as soon as possible
    $params{api_key} = $self->{admin}->{API_KEY} if $self->{conf}->{API_ADMIN_AUTH_LOGIN_RETURN_API_KEY};

    return \%params;
  }
  else {
    return {
      errno  => 10,
      errstr => 'ACCESS_DENIED',
      status => $status
    };
  }
}

#**********************************************************
=head2 post_admins_aid_contacts($path_params, $query_params)

  Endpoint POST /admins/:aid/contacts/

=cut
#**********************************************************
sub post_admins_aid_contacts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  $Admins->admin_contacts_add({
    %$query_params,
    AID => $path_params->{aid},
  });
}

#**********************************************************
=head2 put_admin_aid_contacts($path_params, $query_params)

  Endpoint PUT /admins/:aid/contacts/

=cut
#**********************************************************
sub put_admin_aid_contacts {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  $Admins->admin_contacts_change({
    %$query_params,
    AID => $path_params->{aid}
  });
}

#**********************************************************
=head2 get_admins_aid($path_params, $query_params)

  Endpoint GET /admins/:aid/

=cut
#**********************************************************
sub get_admins_aid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  $Admins->info($path_params->{aid}, {
    %$query_params
  });
}

#**********************************************************
=head2 post_admins($path_params, $query_params)

  Endpoint POST /admins/

=cut
#**********************************************************
sub post_admins {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  return {
    errno  => 700,
    errstr => 'No field aLogin'
  } if !$query_params->{A_LOGIN};

  my $admin_regex = $self->{conf}->{ADMINNAMEREGEXP} || '^\S{1,}$';

  return {
    errno  => 701,
    errstr => 'Not valid login admin',
    regexp => "$admin_regex",
  } if $query_params->{A_LOGIN} !~ /$admin_regex/;

  $Admins->{MAIN_AID} = $self->{admin}->{AID};
  $Admins->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

  $Admins->add({
    A_LOGIN          => $query_params->{A_LOGIN},
    A_FIO            => $query_params->{A_FIO} || '',
    PASPORT_GRANT    => $query_params->{PASPORT_GRANT} || '',
    BIRTHDAY         => $query_params->{BIRTHDAY} || '0000-00-00',
    GID              => $query_params->{GID} || 0,
    RFID_NUMBER      => $query_params->{RFID_NUMBER} || '',
    MIN_SEARCH_CHARS => $query_params->{MIN_SEARCH_CHARS} || 0,
    EMAIL            => $query_params->{EMAIL} || '',
    CELL_PHONE       => $query_params->{CELL_PHONE} || '',
    PASPORT_DATE     => $query_params->{PASPORT_DATE} || '0000-00-00',
    GPS_IMEI         => $query_params->{GPS_IMEI} || '',
    ADDRESS          => $query_params->{ADDRESS} || '',
    DOMAIN_ID        => $query_params->{DOMAIN_ID} || 0,
    PASPORT_NUM      => $query_params->{PASPORT_NUM} || '',
    MAX_CREDIT       => $query_params->{MAX_CREDIT} || 0,
    INN              => $query_params->{INN} || '',
    TELEGRAM_ID      => $query_params->{TELEGRAM_ID} || '',
    PHONE            => $query_params->{PHONE} || '',
    COMMENTS         => $query_params->{COMMENTS} || '',
    DISABLE          => $query_params->{DISABLE} || '',
    MAX_ROWS         => $query_params->{MAX_ROWS} || 0,
    ANDROID_ID       => $query_params->{ANDROID_ID} || '',
    EXPIRE           => $query_params->{EXPIRE} || '0000-00-00 00:00:00',
    CREDIT_DAYS      => $query_params->{CREDIT_DAYS} || 0,
    API_KEY          => $query_params->{API_KEY} || '',
    SIP_NUMBER       => $query_params->{SIP_NUMBER} || '',
  });
}

#**********************************************************
=head2 put_admins_aid($path_params, $query_params)

  Endpoint PUT /admins/:aid/

=cut
#**********************************************************
sub put_admins_aid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  if ($query_params->{A_LOGIN}) {
    my $admin_regex = $self->{conf}->{ADMINNAMEREGEXP} || '^\S{1,}$';

    return {
      errno  => 701,
      errstr => 'Not valid login admin',
      regexp => "$admin_regex",
    } if $query_params->{A_LOGIN} !~ /$admin_regex/;
  }

  $Admins->{AID} = $path_params->{aid};
  $Admins->{MAIN_AID} = $self->{admin}->{AID};
  $Admins->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

  $Admins->change({
    AID => $path_params->{aid},
    %$query_params
  });
}

#**********************************************************
=head2 post_admins_aid_permissions($path_params, $query_params)

  Endpoint POST /admins/:aid/permissions/

=cut
#**********************************************************
sub post_admins_aid_permissions {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  $Admins->{AID} = $path_params->{aid};
  $Admins->{MAIN_AID} = $self->{admin}->{AID};
  $Admins->{MAIN_SESSION_IP} = $ENV{REMOTE_ADDR};

  $Admins->set_permissions($query_params);

  if ($Admins->{errno}) {
    return $Admins;
  }
  else {
    return {
      result => 'Permissions successfully set',
      aid    => $path_params->{aid}
    };
  }
}

#**********************************************************
=head2 get_admins_settings($path_params, $query_params)

  Endpoint GET /admins/settings/

=cut
#**********************************************************
sub get_admins_settings {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Admins->{AID} = $self->{admin}{AID};
  $Admins->settings_info($query_params->{OBJECT_ID} || '--');
}

#**********************************************************
=head2 post_admins_settings($path_params, $query_params)

  Endpoint POST /admins/settings/

=cut
#**********************************************************
sub post_admins_settings {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Admins->{AID} = $self->{admin}{AID};
  $Admins->settings_add({
    %$query_params,
    AID => $self->{admin}{AID},
  });
}

#**********************************************************
=head2 get_admins_all($path_params, $query_params)

  Endpoint GET /admins/all/

=cut
#**********************************************************
sub get_admins_all {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{4}{4};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} || 25;
  $query_params->{SORT} = $query_params->{SORT} || 1;
  $query_params->{DESC} = $query_params->{DESC} || '';
  $query_params->{PG} = $query_params->{PG} || 0;

  my $admins = $Admins->list({
    %{$query_params},
    COLS_NAME => 1,
  });

  return $admins;
}

#**********************************************************
=head2 get_admins_self($path_params, $query_params)

  Endpoint GET /admins/self/

=cut
#**********************************************************
sub get_admins_self {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return $Admins->info($self->{admin}->{AID} || 9999);
}

1;
