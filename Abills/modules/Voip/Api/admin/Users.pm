package Voip::Api::admin::Users;

=head1 NAME

  Voip Users

  Endpoints:
    /voip/users/
    /voip/:uid/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Voip;
use Voip::Services;

my Voip $Voip;
my Voip::Services $Voip_users;
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

  $Voip = Voip->new($db, $admin, $conf);
  $Voip_users = Voip::Services->new($db, $admin, $conf, {
    html        => $self->{html},
    lang        => $self->{lang},
    permissions => $admin->{permissions} || {}
  });

  $Voip->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_voip_users($path_params, $query_params)

  Endpoint GET /voip/users/

=cut
#**********************************************************
sub get_voip_users {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{COLS_NAME} = 1;
  $query_params->{PAGE_ROWS} = $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25;
  $query_params->{PG} = $query_params->{PG} ? $query_params->{PG} : 0;
  $query_params->{DESC} = $query_params->{DESC} ? $query_params->{DESC} : '';
  $query_params->{SORT} = $query_params->{SORT} ? $query_params->{SORT} : 1;

  if (($query_params->{EXTRA_NUMBERS_DAY_FEE} || $query_params->{EXTRA_NUMBERS_MONTH_FEE}) && !$query_params->{EXTRA_NUMBER}) {
    $query_params->{EXTRA_NUMBER} = '_SHOW'
  }

  $Voip->user_list($query_params);
}

#**********************************************************
=head2 post_voip_uid($path_params, $query_params)

  Endpoint POST /voip/:uid/

=cut
#**********************************************************
sub post_voip_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  delete $query_params->{UID};

  my $result = $Voip_users->voip_user_add({
    %$query_params,
    UID => $path_params->{uid},
  });

  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 put_voip_uid($path_params, $query_params)

  Endpoint PUT /voip/:uid/

=cut
#**********************************************************
sub put_voip_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  delete $query_params->{UID};

  my $result = $Voip_users->voip_user_chg({
    %$query_params,
    UID => $path_params->{uid},
  });

  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 get_voip_uid($path_params, $query_params)

  Endpoint GET /voip/:uid/

=cut
#**********************************************************
sub get_voip_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->user_info($path_params->{uid});

  require Shedule;
  Shedule->import();
  my $Schedule = Shedule->new($self->{db}, $self->{admin});

  $Schedule->info({
    UID    => $path_params->{uid},
    TYPE   => 'tp',
    MODULE => 'Voip'
  });

  if ($Schedule->{TOTAL} && $Schedule->{TOTAL} > 0) {
    $Voip->{SCHEDULE_TP_CHANGE} = {
      DATE     => "$Schedule->{Y}-$Schedule->{M}-$Schedule->{D}",
      ADDED    => $Schedule->{DATE},
      ADDED_BY => $Schedule->{ADMIN_NAME},
      TP_ID    => $Schedule->{ACTION},
      ID       => $Schedule->{SHEDULE_ID},
    };
  }

  return $Voip;
}

#**********************************************************
=head2 delete_voip_uid($path_params, $query_params)

  Endpoint DELETE /voip/:uid/

=cut
#**********************************************************
sub delete_voip_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  delete $query_params->{UID};

  my $result = $Voip_users->voip_user_del({
    %$query_params,
    UID => $path_params->{uid},
  });

  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 put_voip_uid_tariff($path_params, $query_params)

  Endpoint PUT /voip/:uid/tariff/

=cut
#**********************************************************
sub put_voip_uid_tariff {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  delete $query_params->{UID};

  my $result = $Voip_users->voip_user_chg_tp({
    %$query_params,
    UID => $path_params->{uid},
  });

  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 delete_voip_uid_tariff($path_params, $query_params)

  Endpoint DELETE /voip/:uid/tariff/

=cut
#**********************************************************
sub delete_voip_uid_tariff {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  delete $query_params->{UID};

  my $result = $Voip_users->voip_schedule_tp_del({
    %$query_params,
    UID => $path_params->{uid},
  });

  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 get_voip_uid_phone_aliases($path_params, $query_params)

  Endpoint GET /voip/:uid/phone/aliases/

=cut
#**********************************************************
sub get_voip_uid_phone_aliases {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->phone_aliases_list({
    NUMBER    => $query_params->{NUMBER} || '_SHOW',
    DISABLE   => $query_params->{DISABLE} || '_SHOW',
    CHANGED   => $query_params->{CHANGED} || '_SHOW',
    UID       => $path_params->{uid},
    COLS_NAME => 1,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    DESC      => $query_params->{DESC} ? $query_params->{DESC} : '',
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
  });
}

#**********************************************************
=head2 post_voip_uid_phone_aliases($path_params, $query_params)

  Endpoint POST /voip/:uid/phone/aliases/

=cut
#**********************************************************
sub post_voip_uid_phone_aliases {
  my $self = shift;
  my ($path_params, $query_params) = @_;
  delete $query_params->{UID};

  my $result = $Voip_users->voip_alias_add({
    %$query_params,
    UID => $path_params->{uid},
  });

  delete @{$result}{qw/object fatal element/};
  return $result;
}

#**********************************************************
=head2 delete_voip_uid_phone_aliases($path_params, $query_params)

  Endpoint DELETE /voip/:uid/phone/alias/:id/

=cut
#**********************************************************
sub delete_voip_uid_phone_aliases {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Voip->phone_aliases_del($path_params->{id}, { UID => $path_params->{uid} });

  if (!$Voip->{errno}) {
    if ($Voip->{AFFECTED} && $Voip->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return {
        errno  => 30004,
        errstr => "Phone alias with id $path_params->{id} and user with uid $path_params->{uid} not exist",
      };
    }
  }
  return $Voip;
}

1;
