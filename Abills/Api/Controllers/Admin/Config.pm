package Api::Controllers::Admin::Config;

=head1 NAME

  ADMIN API Config

  Endpoints:
    /config/

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
    db    => $db,
    admin => $admin,
    conf  => $conf,
    attr  => $attr,
    html  => $attr->{html},
    lang  => $attr->{lang}
  };

  bless($self, $class);

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_config($path_params, $query_params)

  Endpoint GET /config/

=cut
#**********************************************************
sub get_config {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %config = ();
  $config{social_auth}{facebook} = 1 if ($self->{conf}->{AUTH_FACEBOOK_ID});
  $config{social_auth}{google} = 1 if ($self->{conf}->{AUTH_GOOGLE_ID});
  $config{social_auth}{apple} = 1 if ($self->{conf}->{AUTH_APPLE_ID});
  if ($self->{conf}->{PASSWORD_RECOVERY}) {
    my @fields = split(',\s?', ($self->{conf}->{PASSWORD_RECOVERY_REQUIRED_PARAMS} || 'LOGIN,EMAIL'));

    $config{password_recovery} = {
      fields       => \@fields,
      can_send_sms => in_array('Sms', \@main::MODULES) ? 1 : 0,
    };
  }
  if ($self->{conf}->{NEW_REGISTRATION_FORM}) {
    $config{registration}{facebook} = 1 if ($self->{conf}->{FACEBOOK_REGISTRATION});
    $config{registration}{google} = 1 if ($self->{conf}->{GOOGLE_REGISTRATION});
    $config{registration}{apple} = 1 if ($self->{conf}->{APPLE_REGISTRATION});
  }
  else {
    $config{registration}{internet} = 1 if (in_array('Internet', \@main::MODULES) && in_array('Internet', \@main::REGISTRATION));
  }
  $config{login}{regx} = $self->{conf}->{USERNAMEREGEXP} if ($self->{conf}->{USERNAMEREGEXP});
  $config{login}{max_length} = $self->{conf}->{MAX_USERNAME_LENGTH} if ($self->{conf}->{MAX_USERNAME_LENGTH});
  $config{password}{symbols} = $self->{conf}->{PASSWD_SYMBOLS} if ($self->{conf}->{PASSWD_SYMBOLS});
  $config{password}{length} = $self->{conf}->{PASSWD_LENGTH} if ($self->{conf}->{PASSWD_LENGTH});
  $config{portal_news} = 1 if ($self->{conf}->{PORTAL_START_PAGE});

  $config{auth}{phone} = 1 if ($self->{conf}->{AUTH_BY_PHONE});
  $config{phone}{pattern} = $self->{conf}->{PHONE_NUMBER_PATTERN} if ($self->{conf}->{PHONE_NUMBER_PATTERN});

  my %org_params = map { $_ => $self->{conf}{$_} } grep /^ORGANIZATION_/, keys %{$self->{conf}};
  while (my ($param, $value) = each %org_params) {
    next if (!$param || !$value);
    $config{organization}{$param} = $value;
  }

  # TODO: deprecate in 1.40, remove in 1.50
  $config{organization}{ORGANIZATION_APP_LINK_GOOGLE_PLAY} ||=
    $self->{conf}{APP_LINK_GOOGLE_PLAY} if ($self->{conf}{APP_LINK_GOOGLE_PLAY});
  $config{organization}{ORGANIZATION_APP_LINK_APP_STORE} ||=
    $self->{conf}{APP_LINK_APP_STORE} if ($self->{conf}{APP_LINK_APP_STORE});

  return \%config;
}

1;
