=head1 NAME

24TV Sync Plugin

=head1 DESCRIPTION

Synchronizes users between billing system and 24TV service

=cut

use strict;
use warnings;

use Iptv;
use Abills::Base qw(load_pmodule in_array _bp);
use Iptv::Init qw(init_iptv_service);
use Iptv::Services;

our (
  $argv,
  $debug,
  %conf,
  $Admin,
  $db
);

my $SERVICE_MODULE = '24tv';

my $Iptv = Iptv->new($db, $Admin, \%conf);
my $Log = Log->new($db, $Admin);
my $Iptv_services = Iptv::Services->new($db, $Admin, \%conf);

my %tv_services_cache = ();

tv24_sync($argv);

#**********************************************************
=head2 tv24_sync() - Synchronize 24TV services

  Arguments:
    None

  Returns:
    Nothing. Logs and exits if no services found.

  Example:
    tv24_sync();

=cut
#**********************************************************
sub tv24_sync {
  my ($attr) = @_;

  if($debug > 6) {
    $Iptv->{debug}=1;
  }

  my $services = $Iptv->services_list({
    NAME       => '_SHOW',
    MODULE     => $SERVICE_MODULE,
    ID         => $attr->{SERVICE_ID} || '_SHOW',
    COLS_NAME  => 1,
    COLS_UPPER => 1
  });

  if (!$services || !@$services) {
    $Log->log_print('LOG_INFO', 'SYSTEM', 'No 24TV services found', { PRINT => 1 });
    return;
  }

  foreach my $service (@{$services}) {
    process_service($service);
  }

  return 1;
}

#**********************************************************
=head2 process_service($service) - Process synchronization for a single 24TV service

  Arguments:
    $service - Hash reference with service data
       ID - Service ID (required)

  Returns:
    Nothing. Logs errors and actions during processing.

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

  if (!$tv_services_cache{$service->{ID}}) {
    $tv_services_cache{$service->{ID}} = init_iptv_service($db, $Admin, \%conf, {
      SERVICE_ID => $service->{ID}
    });
  }

  my $Tv_service = $tv_services_cache{$service->{ID}};

  if($debug > 6) {
    $Tv_service->{debug}=1;
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

  my $service_users_list = $Tv_service->users_list();
  if (!$service_users_list || ref $service_users_list ne 'HASH' || $Tv_service->{errno}) {
    $Log->log_print('LOG_ERR', 'SYSTEM', "Invalid service users list for service $service->{ID}", { PRINT => 1 });
    return;
  }

  my $users = $Iptv->user_list({
    SERVICE_ID     => $service->{ID},
    SERVICE_STATUS => '_SHOW',
    LOGIN          => '_SHOW',
    UID            => '_SHOW',
    PHONE          => '_SHOW',
    COLS_NAME      => 1,
    PAGE_ROWS      => 65535
  });

  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    $Log->log_print('LOG_ERR', 'SYSTEM', "No billing users found for service $service->{ID}", { PRINT => 1 });
    return;
  }

  foreach my $user (@{$users}) {
    if (!$user->{login}) {
      next;
    }

    my $phone = (split(';', $user->{phone}))[0];
    next if (!$phone);

    my $billing_status = $user->{service_status} || 0;

    if (!$service_users_list->{$phone} && !$billing_status) {
      if ($debug < 5) {
        $Iptv_services->_execute_service_user_add($Tv_service, $user->{uid}, $user->{id}, {});
      }

      if ($Tv_service->{errno}) {
        my $error = $Tv_service->{errstr} || 'Unknown error';
        $Log->log_print('LOG_ERR', $user->{login}, "Error adding user to 24TV: $error", { PRINT => 1 });
        delete $Tv_service->{errno};
        delete $Tv_service->{errstr};
      }
      else {
        $Log->log_print('LOG_INFO', $user->{login}, 'User added to 24TV', { PRINT => 1 });
      }
      next;
    }

    if (!$service_users_list->{$phone}) {
      next;
    }

    my $service_status = $service_users_list->{$phone}{is_active} ? 0 : 1;
    if ($service_status == $billing_status) {
      next;
    }

    if($debug < 5) {
      $Iptv_services->_execute_service_user_change(
        $Tv_service,
        $user->{uid},
        $user->{id},
        { STATUS => $billing_status }
      );
    }

    if ($Tv_service->{errno}) {
      my $error = $Tv_service->{errstr} || 'Unknown error';
      $Log->log_print('LOG_ERR', $user->{login}, "Error changing user in 24TV: $error", { PRINT => 1 });
      delete $Tv_service->{errno};
      delete $Tv_service->{errstr};
    }
    else {
      $Log->log_print('LOG_INFO', $user->{login}, "User status changed in 24TV $billing_status => $service_status ", { PRINT => 1 });
    }
  }

  return 1;
}

1;