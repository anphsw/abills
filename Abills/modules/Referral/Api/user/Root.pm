package Referral::Api::user::Root;

=head1 NAME

  User Referral

  Endpoints:
    /user/referral/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Referral;
use Referral::Users;

my Referral $Referral;
my Referral::Users $Referral_users;
my Control::Errors $Errors;

# Can be deleted after review Referral::Users object creation
our %lang;

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

  if ($self->{conf}->{API_CONF_LANGUAGE}) {
    my $lang_lng = $self->{conf}->{default_language} || 'english';
    eval {require "Abills/modules/Referral/lng_$lang_lng.pl"};
    require 'Abills/modules/Referral/lng_english.pl' if ($@);
  }
  else {
    require 'Abills/modules/Referral/lng_english.pl';
  }

  my %LANG = (%{$self->{lang}}, %lang);

  $Referral = Referral->new($self->{db}, $self->{admin}, $self->{conf});
  $Referral_users = Referral::Users->new($db, $admin, $conf, {
    html => $self->{html},
    lang => \%LANG,
  });
  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_referral($path_params, $query_params)

  Endpoint GET /user/referral/

=cut
#**********************************************************
sub get_user_referral {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Referral_users->referrals_user({ UID => $path_params->{uid} });
  return $result if (!$result->{referrals_total});

  foreach my $referral (@{$result->{referrals}}) {
    delete @{$referral}{qw/REFERRER BONUS_BILL BONUSES UID/};
  }

  return $result;
}

#**********************************************************
=head2 post_user_referral_bonus($path_params, $query_params)

  Endpoint POST /user/referral/bonus/

=cut
#**********************************************************
sub post_user_referral_bonus {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $result = $Referral_users->referral_bonus_add({ UID => $path_params->{uid} });
  return $result;
}

#**********************************************************
=head2 get_user_referral_bonus($path_params, $query_params)

  Endpoint GET /user/referral/bonus/

=cut
#**********************************************************
sub get_user_referral_bonus {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $bonuses = $Referral->get_bonus_history($path_params->{uid} || '--');
  return $bonuses if (!$Referral->{errno});

  return {
    errno  => 41023,
    errstr => 'Failed get bonus history. Try later',
  };
}


#**********************************************************
=head2 post_user_referral_friend($path_params, $query_params)

  Endpoint POST /user/referral/friend/

=cut
#**********************************************************
sub post_user_referral_friend {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  $query_params->{UID} = $path_params->{uid};
  $query_params->{add} = 1;

  my $result = $Referral_users->referral_user_manage($query_params);
  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 put_user_referral_friend_id($path_params, $query_params)

  Endpoint PUT /user/referral/friend/:id/

=cut
#**********************************************************
sub put_user_referral_friend_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $query_params->{UID} = $path_params->{uid};
  $query_params->{ID} = $path_params->{id};
  $query_params->{change} = 1;

  my $result = $Referral_users->referral_user_manage($query_params);
  delete @{$result}{qw/object fatal element/};
  return $result;
}

1;
