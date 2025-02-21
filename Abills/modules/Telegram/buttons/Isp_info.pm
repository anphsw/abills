package Telegram::buttons::Isp_info;

use strict;
use warnings FATAL => 'all';

my %icons = (about => "\xF0\x9F\x8F\xA2");

#**********************************************************
=head2 new($conf, $bot, $bot_db, $APILayer, $user_config)

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $bot, $bot_db, $APILayer, $user_config) = @_;

  my $self = {
    conf        => $conf,
    bot         => $bot,
    bot_db      => $bot_db,
    api         => $APILayer,
    user_config => $user_config
  };

  bless($self, $class);

  return $self;
}

#**********************************************************
=head2 enable()

=cut
#**********************************************************
sub enable {
  my $self = shift;

  return 1;
}

#**********************************************************
=head2 btn_name()

=cut
#**********************************************************
sub btn_name {
  my $self = shift;

  return "$icons{about} $self->{bot}{lang}{ABOUT}";
}

#**********************************************************
=head2 click()

=cut
#**********************************************************
sub click {
  my $self = shift;

  my $org = $self->{user_config}{organization};

  my $message = "$icons{about} $self->{bot}{lang}{ABOUT}\n";

  $message .= "\n";
  $message .= "$self->{bot}{lang}{COMPANY_NAME}: $org->{ORGANIZATION_NAME}\n" if ($org->{ORGANIZATION_NAME});
  $message .= "$self->{bot}{lang}{ADDRESS}: $org->{ORGANIZATION_ADDRESS}\n" if ($org->{ORGANIZATION_ADDRESS});
  $message .= "$self->{bot}{lang}{PHONE}: $org->{ORGANIZATION_PHONE}\n" if ($org->{ORGANIZATION_PHONE});
  $message .= "$self->{bot}{lang}{EMAIL}: $org->{ORGANIZATION_MAIL}\n" if ($org->{ORGANIZATION_MAIL});
  $message .= "$self->{bot}{lang}{WEB_SITE}: $org->{ORGANIZATION_WEB_SITE}\n" if ($org->{ORGANIZATION_WEB_SITE});
  $message .= "Android $self->{bot}{lang}{MOBILE_APP}: $org->{ORGANIZATION_APP_LINK_GOOGLE_PLAY}\n" if ($org->{ORGANIZATION_APP_LINK_GOOGLE_PLAY});
  $message .= "iOS $self->{bot}{lang}{MOBILE_APP}: $org->{ORGANIZATION_APP_LINK_APP_STORE}\n" if ($org->{ORGANIZATION_APP_LINK_APP_STORE});

  $self->{bot}->send_message({
    text                     => $message,
    disable_web_page_preview => 'true'
  });

  return 1;
}

1;
