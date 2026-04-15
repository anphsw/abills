=head1 NAME

 billd plugin

 DESCRIBE:  Iptv sync plugin

=cut

use strict;
use warnings;

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db,
);

use Iptv;
use Abills::Base qw(load_pmodule in_array _bp);
use Iptv::Services;
use Iptv::Init qw/init_iptv_service/;

my %Tv_services = ();
my $Iptv = Iptv->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin);
my $Iptv_services = Iptv::Services->new($db, $Admin, \%conf);

if ($argv->{SYNC_SERVICES}) {
  services_sync();
}
else {
  screen_sync();
}

#**********************************************************
=head2 services_sync() - Synchronize TV services

=cut
#**********************************************************
sub services_sync {

  if ($debug > 6) {
    $Iptv->{debug} = 1;
  }

  my $service_module = $argv->{MODULE} || '_SHOW';
  my $service_id = $argv->{SERVICE_ID} || '_SHOW';

  my $services = $Iptv->services_list({
    NAME       => '_SHOW',
    MODULE     => $service_module,
    ID         => $service_id,
    STATUS     => 0,
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  if (!$services || !@$services) {
    my $service_desc = $service_module || $service_id || '';
    $Log->log_print('LOG_INFO', 'SYSTEM', "No $service_desc services found", { PRINT => 1 });
    return;
  }

  foreach my $service (@{$services}) {
    process_service($service);
  }
}

#**********************************************************
=head2 process_service($service) - Process synchronization for a single TV service

  Arguments:
    $service - Hash reference with service data
       ID - Service ID (required)

  Returns:
    1 on success, undef on failure

  Example:
    process_service({ ID => 101 });

=cut
#**********************************************************
sub process_service {
  my ($service) = @_;

  if (!$service || !$service->{ID}) {
    $Log->log_print('LOG_ERR', 'SYSTEM', 'Invalid service data', { PRINT => 1 });
    return;
  }

  if (!$Tv_services{$service->{ID}}) {
    $Tv_services{$service->{ID}} = init_iptv_service($db, $Admin, \%conf, {
      SERVICE_ID => $service->{ID}
    });
  }

  my $Tv_service = $Tv_services{$service->{ID}};

  if ($debug > 6) {
    $Tv_service->{debug} = 1;
  }

  if (!$Tv_service) {
    $Log->log_print('LOG_ERR', 'SYSTEM', "Failed to initialize service $service->{ID}", { PRINT => 1 });
    return;
  }

  if (!$Tv_service->can('users_list') ||
    !$Tv_service->can('user_add') ||
    !$Tv_service->can('user_change')) {
    $Log->log_print('LOG_ERR', 'SYSTEM', "Service $service->{ID} missing required methods", { PRINT => 1 });
    return;
  }

  my $service_name = $Tv_service->{SERVICE_NAME} || $service->{ID};
  my $service_users = $Tv_service->users_list();
  if (!$service_users || ref $service_users ne 'HASH' || $Tv_service->{errno}) {
    $Log->log_print('LOG_ERR', 'SYSTEM', "Invalid service users list for service $service_name", { PRINT => 1 });
    return;
  }

  my $service_users_list = $service_users->{list} || $service_users;
  my $user_key = $service_users->{user_key} || 'login';
  my $service_status_key = $service_users->{status_key} || 'is_active';

  my $clear_service_error = sub {
    my ($login, $action, $details) = @_;
    if ($Tv_service->{errno}) {
      my $error = $Tv_service->{errstr} || 'Unknown error';
      $Log->log_print('LOG_ERR', $login, "Error $action in $service_name: $error", { PRINT => 1 });
      delete $Tv_service->{errno};
      delete $Tv_service->{errstr};
      return 0;
    }
    $Log->log_print('LOG_INFO', $login, $details, { PRINT => 1 }) if $details;
    return 1;
  };

  my $users = $Iptv->user_list({
    SERVICE_ID     => $service->{ID},
    SERVICE_STATUS => '_SHOW',
    LOGIN          => '_SHOW',
    UID            => '_SHOW',
    TP_FILTER_ID   => '_SHOW',
    COLS_NAME      => 1,
    PAGE_ROWS      => 65535
  });

  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    $Log->log_print('LOG_INFO', 'SYSTEM', "No billing users found for service $service_name($service->{ID})", { PRINT => 1 });
    return;
  }

  my $status_title = { 0 => 'Active', 1 => 'Disable' };
  my $dry_run = $debug >= 5;

  foreach my $user (@{$users}) {
    if (!$user->{login} || !$user->{uid} || !$user->{id}) {
      $Log->log_print('LOG_WARNING', 'SYSTEM', "Skipping user with incomplete data", { PRINT => 1 });
      next;
    }

    # Billing status: 0 = active, 1 = disabled
    my $billing_status = $user->{service_status} ? 1 : 0;
    my $service_user = $service_users_list->{$user->{$user_key}};

    if (!$service_user && !$billing_status) {
      if (!$dry_run) {
        $Iptv_services->_execute_service_user_add($Tv_service, $user->{uid}, $user->{id}, {});
      }

      $clear_service_error->($user->{login}, "adding user to", "User added to $service_name");
      next;
    }

    if (!$service_user) {
      next;
    }

    # Convert service status to billing format: is_active=1 -> status=0 (active)
    my $service_status = $service_user->{$service_status_key} ? 0 : 1;

    if ($service_status != $billing_status) {
      if (!$dry_run) {
        $Iptv_services->_execute_service_user_change(
          $Tv_service,
          $user->{uid},
          $user->{id},
          { STATUS => $user->{service_status} }
        );
      }

      if ($Tv_service->{errno}) {
        $clear_service_error->($user->{login}, "changing user");
      }
      else {
        my $state_before = $status_title->{$service_status};
        my $state_after = $status_title->{$billing_status};
        $Log->log_print('LOG_INFO', $user->{login}, "User status changed in $service_name $state_before => $state_after", { PRINT => 1 });
      }
    }

    next if $billing_status;

    my $service_tariff_id = $service_user->{tariff} ? $service_user->{tariff}{id} : undef;
    next if !$service_tariff_id || !$user->{tp_filter_id};
    next if $service_tariff_id eq $user->{tp_filter_id};

    if (!$dry_run) {
      $Iptv_services->_execute_service_user_add(
        $Tv_service,
        $user->{uid},
        $user->{id},
        { STATUS => 0 }
      );
    }

    if ($Tv_service->{errno}) {
      $clear_service_error->($user->{login}, "changing user's tariff plan");
    }
    else {
      $Log->log_print('LOG_INFO', $user->{login}, "User's tariff plan changed in $service_name $service_tariff_id => $user->{tp_filter_id}", { PRINT => 1 });
    }
  }

  return 1;
}

#**********************************************************
=head2 screen_sync($attr)

=cut
#**********************************************************
sub screen_sync {

  my $users = $Iptv->user_list({
    SERVICE_ID      => '_SHOW',
    IPTV_LOGIN      => '_SHOW',
    ID              => '_SHOW',
    UID             => '_SHOW',
    LOGIN           => '_SHOW',
    TV_SERVICE_NAME => '_SHOW',
    SUBSCRIBE_ID    => '_SHOW',
    COLS_NAME       => 1,
    COLS_UPPER      => 1,
    PAGE_ROWS       => 65000
  });

  foreach my $user (@{$users}) {
    if (!$Tv_services{$user->{SERVICE_ID}}) {

      $Tv_services{$user->{SERVICE_ID}} = init_iptv_service($db, $Admin, \%conf, {
        SERVICE_ID => $user->{SERVICE_ID}
      });
    }

    next if !$Tv_services{$user->{SERVICE_ID}};
    next if !$Tv_services{$user->{SERVICE_ID}}->can('screen_sync');

    my $service_screens = $Tv_services{$user->{service_id}}->screen_sync($user);
    my $user_screens = $Iptv->users_screens_list({
      TP_ID            => $user->{TP_ID},
      NUM              => '_SHOW',
      CID              => '_SHOW',
      SERIAL           => '_SHOW',
      USERS_SERVICE_ID => $user->{ID},
      COLS_NAME        => 1,
      COLS_UPPER       => 1,
      SHOW_ASSIGN      => 1
    });

    my %user_screens_hash = ();
    foreach my $screen (@{$user_screens}) {
      $user_screens_hash{$screen->{CID}} = { CID => $screen->{CID}, SERIAL => $screen->{SERIAL} };
    }
    _check_screens(\%user_screens_hash, $service_screens, $user);
  }
}

#**********************************************************
=head2 _check_screens($attr)

=cut
#**********************************************************
sub _check_screens {
  my ($user_screens, $service_screens, $attr) = @_;

  return 0 if ref $service_screens ne 'HASH' || ref $user_screens ne 'HASH';
  return 0 if !$attr->{ID} || !$attr->{TP_ID};

  $attr->{LOGIN} ||= '';
  my %screens_only_on_service = ();
  my %screens_only_on_billing = ();

  foreach my $user_screen (keys %{$user_screens}) {
    $screens_only_on_billing{$user_screen} = $user_screens->{$user_screen} if !$service_screens->{$user_screen};
  }

  foreach my $service_screen (keys %{$service_screens}) {
    $screens_only_on_service{$service_screen} = $service_screens->{$service_screen} if !$user_screens->{$service_screen};
  }

  my $next_screen = $Iptv->users_next_screen({ SERVICE_ID => $attr->{ID}, TP_ID => $attr->{TP_ID} });
  foreach my $screen (keys %screens_only_on_service) {
    if (!$next_screen->{num}) {
      _log('LOG_INFO', "Login: $attr->{LOGIN}. Screen: $screen. Can't create screen. Tariff plan does not have enough screens");
      next;
    }

    $Iptv->users_screens_add({ %{$screens_only_on_service{$screen}},
      SCREEN_ID  => $next_screen->{num},
      SERVICE_ID => $attr->{ID},
      UID        => $attr->{UID},
    });

    if (!$Iptv->{errno}) {
      _log('LOG_INFO', "Login: $attr->{LOGIN}. Screen created: $screen.");
      $next_screen = $Iptv->users_next_screen({ SERVICE_ID => $attr->{ID}, TP_ID => $attr->{TP_ID} });
    }
    else {
      _log('LOG_INFO', "Login: $attr->{LOGIN}. Error screen create: $screen.");
    }
  }

  foreach my $screen (keys %screens_only_on_billing) {
    _log('LOG_INFO', "Login: $attr->{LOGIN}. Service id: $attr->{ID}. Screen: $screen exist only in billing!");
  }
}

1;