package Paysys::Api::user::Root;

=head1 NAME

  User Paysys

  Endpoints:
    /user/paysys/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(mk_unique_value);
use Control::Errors;
use Paysys;
use Paysys::Init;

my Paysys $Paysys;
my Control::Errors $Errors;

# Can not delete until present Paysys V3. Reason - Paysys_Base.pm
our %lang;
require 'Abills/modules/Paysys/lng_english.pl';

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

  $Paysys = Paysys->new($db, $admin, $conf);
  $Paysys->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user_paysys_systems($path_params, $query_params)

  Endpoint GET /user/paysys/systems/

=cut
#**********************************************************
sub get_user_paysys_systems {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my %LANG = (%{$self->{lang}}, %lang);

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  my $users_info = $Users->list({
    GID       => '_SHOW',
    UID       => $path_params->{uid},
    COLS_NAME => 1,
  });

  my $allowed_systems = $Paysys->groups_settings_list({
    GID       => $users_info->[0]->{gid},
    PAYSYS_ID => '_SHOW',
    COLS_NAME => 1,
    PAGE_ROWS => 50,
  });

  my $systems = $Paysys->paysys_connect_system_list({
    NAME         => '_SHOW',
    MODULE       => '_SHOW',
    ID           => '_SHOW',
    SUBSYSTEM_ID => '_SHOW',
    PAYSYS_ID    => '_SHOW',
    STATUS       => 1,
    COLS_NAME    => 1,
    SORT         => 'priority',
  });

  my @systems_list;
  foreach my $system (@{$systems}) {
    delete @{$system}{qw/status/};

    foreach my $allowed_system (@{$allowed_systems}) {
      next if ($system->{paysys_id} != $allowed_system->{paysys_id});
      if (!$self->{conf}->{PAYSYS_V4}) {
        # Attempt to reload Paysys/Paysys_Base.pm aborted. Error only in one client and it's very strange
        delete $INC{'Paysys/Paysys_Base.pm'};
      }
      my $Module = _configure_load_payment_module($system->{module}, 1, $self->{conf});
      next if (ref $Module eq 'HASH' || (!$Module->can('fast_pay_link') && !$Module->can('google_pay') && !$Module->can('apple_pay')));

      my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });
      my %settings = $Module->get_settings();
      $system->{request} = $settings{REQUEST} if (%settings && $settings{REQUEST});

      if ($settings{SUBSYSTEMS} && ref $settings{SUBSYSTEMS} eq 'HASH' &&  exists($settings{SUBSYSTEMS}{$system->{subsystem_id}})) {
        $system->{module} = ucfirst(lc($settings{SUBSYSTEMS}{$system->{subsystem_id}})) . '.pm';
      }

      if ($query_params->{REQUEST_METHOD} && $system->{request} && $system->{request}->{METHOD}) {
        next if ("$query_params->{REQUEST_METHOD}" ne $system->{request}->{METHOD});
      }

      if ($system->{module} && ($system->{module} eq 'GooglePay.pm' || $system->{module} eq 'ApplePay.pm')) {
        next if ($query_params->{REQUEST_METHOD});
        my $config = $Paysys_plugin->get_config($users_info->[0]->{gid});

        my $config_name = $system->{module} eq 'GooglePay.pm' ? 'google_config' : 'apple_config';
        $system->{$config_name} = $config;
      }
      push(@systems_list, $system);
    }
  }

  return \@systems_list || [];
}

#**********************************************************
=head2 get_user_paysys_transaction_status_string_id($path_params, $query_params)

  Endpoint GET /user/paysys/transaction/status/:string_id/

=cut
#**********************************************************
sub get_user_paysys_transaction_status_string_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $transaction_info = $Paysys->list({
    TRANSACTION_ID => $path_params->{id},
    UID            => $path_params->{uid},
    STATUS         => '_SHOW',
    COLS_NAME      => 1,
    SORT           => 1
  })->[0] || {};

  if (scalar keys %{$transaction_info}) {
    return $transaction_info;
  }
  else {
    return $Errors->throw_error(1170101);
  }
}

#**********************************************************
=head2 get_user_paysys_transaction_status_string_id($path_params, $query_params)

  Endpoint GET /user/paysys/transaction/status/:string_id/

=cut
#**********************************************************
sub post_user_paysys_pay {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $sum = $query_params->{SUM} || 0;
  my $operation_id = $query_params->{OPERATION_ID} || '';

  if (!defined $query_params->{SYSTEM_ID}) {
    return $Errors->throw_error(1170102, { lang_vars => { FIELD => 'systemId' } });
  }

  if (!$sum) {
    require Users;
    Users->import();
    my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

    my $user = $Users->info($path_params->{uid});
    $sum = ::recomended_pay($user) || 1;
  }

  if (!$operation_id) {
    $operation_id = mk_unique_value(9, { SYMBOLS => '0123456789' }),
  }
  else {
    $operation_id =~ s/[<>]//gm;
  }

  my $paysys = $Paysys->paysys_connect_system_list({
    SHOW_ALL_COLUMNS => 1,
    STATUS           => 1,
    COLS_NAME        => 1,
    ID               => $query_params->{SYSTEM_ID} || '--',
  });

  if (!scalar @{$paysys}) {
    return $Errors->throw_error(1170103);
  }

  my %pay_params = (
    UID          => $path_params->{uid},
    SUM          => $sum,
    OPERATION_ID => $operation_id,
    MODULE       => $paysys,
  );

  $pay_params{APAY} = $query_params->{APAY} if ($query_params->{APAY});
  $pay_params{GPAY} = $query_params->{GPAY} if ($query_params->{GPAY});

  return $self->paysys_pay(\%pay_params);
}

#**********************************************************
=head2 post_user_paysys_applepay_session($path_params, $query_params)

  Endpoint GET /user/paysys/applePay/session/

=cut
#**********************************************************
sub post_user_paysys_applepay_session {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $Module = _configure_load_payment_module('ApplePay.pm', 1, $self->{conf});
  return $Module if (ref $Module eq 'HASH');
  my %LANG = (%{$self->{lang}}, %lang);

  my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, { lang => \%LANG });

  return $Paysys_plugin->create_session({
    UID => $path_params->{uid},
  });
}

#**********************************************************
=head2 get_user_paysys_recurrent($path_params, $query_params)

  Endpoint GET /user/paysys/recurrent/

=cut
#**********************************************************
sub get_user_paysys_recurrent {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Paysys->user_info({
    UID => $path_params->{uid},
  });

  # sql error or not exists
  if ($Paysys->{errno}) {
    if ($Paysys->{errno} == 2) {
      return $Errors->throw_error(1170105);
    }
    else {
      return {
        errno  => $Paysys->{errno},
        errstr => $Paysys->{errstr}
      };
    }
  }

  # empty PAYSYS_ID, legacy cases. Such subscription will not work
  if (!$Paysys->{PAYSYS_ID}) {
    $Paysys->user_del({
      PAYSYS_ID => 0,
      UID       => $path_params->{uid},
    });

    return $Errors->throw_error(1170105);
  }

  return {
    paysys_id        => $Paysys->{PAYSYS_ID},
    recurrent_module => $Paysys->{RECURRENT_MODULE},
    order_id         => $Paysys->{ORDER_ID},
    date             => $Paysys->{EXTERNAL_LAST_DATE},
    sum              => $Paysys->{TOKEN} ? $Paysys->{SUM} : 0
  };
}

#**********************************************************
=head2 delete_user_paysys_recurrent($path_params, $query_params)

  Endpoint DELETE /user/paysys/recurrent/

=cut
#**********************************************************
sub delete_user_paysys_recurrent {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Paysys->user_info({
    UID => $path_params->{uid},
  });

  my $paysys_id = $Paysys->{PAYSYS_ID};

  # empty PAYSYS_ID, legacy cases. Such subscription will not work
  if (!$Paysys->{PAYSYS_ID}) {
    $Paysys->user_del({
      PAYSYS_ID => 0,
      UID       => $path_params->{uid},
    });

    return $Errors->throw_error(1170106);
  }

  my $payment_system_info = $Paysys->paysys_connect_system_info({
    PAYSYS_ID        => $paysys_id,
    SHOW_ALL_COLUMNS => 1,
    COLS_NAME        => 1
  });

  my $Pasysy_plugin = _configure_load_payment_module($payment_system_info->{module}, 1, $self->{conf});
  if (!$Pasysy_plugin->can('recurrent_cancel')) {
    return $Errors->throw_error(1170107);
  }

  my $paysys_object = $Pasysy_plugin->new($self->{db}, $self->{admin}, $self->{conf});
  my $result = $paysys_object->recurrent_cancel({ UID => $path_params->{uid} });

  if ($result->{errno}) {
    return $Errors->throw_error(1170108);
  }
  else {
    return {
      result  => 'SUCCESS_UNSUBSCRIBE',
      message => 'Successfully unsubscribed',
    };
  }
}

#**********************************************************
=head2 paysys_pay($attr) function for call fast_pay_link in Paysys modules

  Arguments:
    $attr
      UID           - uid of user
      SUM           - amount of sum payment
      OPERATION_ID  - ID of transaction
      MODULE        - Paysys module

  Result:
    fastpay url or Errno

=cut
#**********************************************************
sub paysys_pay {
  my $self = shift;
  my ($attr) = @_;
  my $Module = _configure_load_payment_module($attr->{MODULE}->[0]->{module}, 1, $self->{conf});

  return $Module if (ref $Module eq 'HASH');
  my %LANG = (%{$self->{lang}}, %lang);

  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Users->info($attr->{UID});
  $Users->pi({ UID => $attr->{UID} });
  my %params = (
    %$attr,
    USER => $Users,
  );

  my $Paysys_plugin = $Module->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang        => \%LANG,
    CUSTOM_NAME => $attr->{MODULE}->[0]->{name},
    CUSTOM_ID   => $attr->{MODULE}->[0]->{paysys_id}
  });

  if ($attr->{GPAY} && $Module->can('google_pay')) {
    return $Paysys_plugin->google_pay(\%params);
  }
  elsif ($attr->{APAY} && $Module->can('apple_pay')) {
    return $Paysys_plugin->apple_pay(\%params);
  }
  elsif ($Module->can('fast_pay_link')) {
    return $Paysys_plugin->fast_pay_link(\%params);
  }
  else {
    return $Errors->throw_error(1170104);
  }
}

1;
