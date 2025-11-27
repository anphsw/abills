package Iptv::Services;

=head1 NAME

  Iptv users function

  ERROR ID: 108ХХХХ

=cut

use strict;
use warnings FATAL => 'all';

use POSIX qw(strftime);
use Abills::Base qw(in_array ip2int int2ip cmd);
use Control::Errors;
use Iptv;
use Users;
use Fees;
use Tariffs;
use Iptv::Init qw/init_iptv_service/;

my Control::Errors $Errors;
my Iptv $Iptv;
my Users $Users;
my Tariffs $Tariffs;
my Fees $Fees;

use constant {
  ACTION_REDIRECT => 'redirect',
  ACTION_MESSAGE  => 'message',
  ACTION_TEMPLATE => 'template',
  ACTION_MODAL    => 'modal',
};

my $BUTTON_CONFIG = {
  customer_add_device => {
    lang_key    => 'ADD_DEVICE_BY_UNIQ',
    fallback    => 'Add Device by Uniq',
    css_class   => 'btn-xs',
    modal       => 1
  },
  get_code            => {
    lang_key    => 'ACTIVATION_CODE',
    fallback    => 'Activation code',
    css_class   => 'btn-xs',
    modal       => 1
  },
  get_url             => {
    lang_key    => 'WATCH_NOW',
    fallback    => 'Watch now',
    css_class   => 'btn-xs',
    target      => '_blank'
  },
  send_message        => {
    lang_key    => 'SEND_MESSAGE',
    fallback    => 'Send message',
    css_class   => 'btn-xs',
    modal       => 1
  },
};

my $USER_PORTAL_BUTTON_CONFIG = {
  get_code     => {
    lang_key    => 'ACTIVATION_CODE',
    fallback    => 'Activation code',
    css_class   => 'btn-xs',
    modal       => 1
  },
  get_url      => {
    lang_key    => 'WATCH_NOW',
    fallback    => 'Watch now',
    css_class   => 'btn-xs',
    target      => '_blank'
  },
  service_info => {
    lang_key    => 'CHANNELS',
    fallback    => 'Channels',
    css_class   => 'btn-xs',
    modal       => 1
  }
};

#**********************************************************
=head2 new($db, $admin, $conf, $attr) - Constructor for the IPTV services handler

  Arguments:
    $db    => Database handle.
    $admin => Admin user object.
    $conf  => Configuration hashref.
    $attr  => Hashref of additional attributes:
      lang                 => Optional language hashref.
      ENABLE_FEES_MESSAGES => Optional flag to enable fee messages.
      MODULES              => Optional list of modules.
      SYSTEM_ADMIN         => Optional flag indicating system admin.
      USER_PORTAL          => Optional flag indicating user portal mode.

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db                   => $db,
    admin                => $admin,
    conf                 => $conf,
    lang                 => $attr->{lang} || {},
    ENABLE_FEES_MESSAGES => $attr->{ENABLE_FEES_MESSAGES}
  };

  $self->{MODULES} = $attr->{MODULES};
  if ($admin->{MODULES}) {
    $self->{MODULES} = [ keys %{ $admin->{MODULES} } ];
  }

  $self->{SYSTEM_ADMIN} = $attr->{SYSTEM_ADMIN};
  $self->{USER_PORTAL} = $attr->{USER_PORTAL};
  bless($self, $class);

  $Iptv = Iptv->new($self->{db}, $self->{admin}, $self->{conf});
  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});
  $Tariffs = Tariffs->new($self->{db}, $self->{conf}, $self->{admin});
  $Errors = Control::Errors->new($self->{db}, $self->{admin}, $self->{conf}, {
    lang   => $self->{lang},
    module => 'Iptv',
    parent => $self
  });
  $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

  if ($self->{ENABLE_FEES_MESSAGES}) {
    $Iptv->{FEES} ||= {};
  }

  delete $Iptv->{db}->{TRANSACTION};

  return $self;
}

#**********************************************************
=head2 user_info($attr) - Retrieve detailed IPTV user information

  Arguments:
    $attr - Extra attributes
      ID              - Service user identifier (required)
      ONLY_ACTION_BTN - If set, returns only action buttons without main info
      ...             - Other parameters that may be used by the IPTV service

  Returns:
    HASHREF
      success - 1 on success
      errno   - Error code (undef on success)
      data    - Hash containing:
        service_results - Data retrieved from the IPTV service
        buttons         - Set of service control buttons
        additional_info - Extra information from the service
      actions - Array of available user actions

  Example:

    my $info = $Iptv_services->user_info({ ID => 12345 });

=cut
#**********************************************************
sub user_info {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $uid = $user_service_info->{UID};
  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  $Users->info($uid, { SHOW_PASSWORD => 1 });
  $Users->pi({ UID => $uid });

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});

  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      return $Errors->throw_error(1080003);
    }
  }

  my $response  = {
    success => 1,
    errno   => undef,
    data    => {
      service_results => {},
      buttons         => {},
      additional_info => {}
    },
    actions => []
  };

  if ($tv_service) {
    $response->{data}{buttons} = $self->_build_service_buttons($tv_service);

    my $button_action = $self->_handle_button_actions($tv_service, $attr, $user_service_info);
    push @{$response->{actions}}, $button_action if $button_action;
  }

  if ($attr->{ONLY_ACTION_BTN}) {
    return $response;
  }

  if ($tv_service && $tv_service->can('additional_info')) {
    my $result = $tv_service->additional_info({
      %{$attr}, %{$user_service_info}, %{$Users}
    });

    if ($result) {
      $response->{data}{additional_info} = $self->_format_additional_tables($result);
    }
  }

  if (!$tv_service || !$tv_service->can('user_info')) {
    $response->{data}{service_results} = {};
    return $response;
  }

  $tv_service->user_info({ %{$attr}, %{$user_service_info}, %{$Users}, LOGIN => $Users->{LOGIN} });

  if ($tv_service->{errno}) {
    return {
      errno  => $tv_service->{errno},
      errstr => $tv_service->{errstr}
    }
  }

  my $results = {};
  if ($tv_service->{RESULT} && $tv_service->{RESULT}{results} &&
    ref $tv_service->{RESULT}{results} eq 'ARRAY') {

    $results = {
      data         => $tv_service->{RESULT}{results},
      service_name => $tv_service->{SERVICE_NAME} || 'Unknown Service',
      count        => scalar @{$tv_service->{RESULT}{results}}
    };
  }

  $response->{data}{service_results} = $results;

  return $response;
}

#**********************************************************
=head2 user_add($attr) - Add a new IPTV user with full validation and post-activation steps

  Arguments:
    $attr - Extra attributes
      UID          - Unique user identifier (required)
      TP_ID        - Tariff plan identifier (required)
      STATUS       - Initial service status (optional)
      SUBSCRIBE_ID - Subscription ID to update after adding the user (optional)
      USER_IMPORT  - If set and supported by the service, triggers user import (optional)
      ...          - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module data, including:
        INSERT_ID           - ID of the newly created user in the IPTV service
        FEES                - Monthly fee calculation results
        MANDATORY_CHANNELS  - Channels automatically added to the user
        FEES_MESSAGES       - Optional fee-related messages (if enabled)

  Example:

    my $result = $Iptv_services->user_add({
      UID    => 1001,
      TP_ID  => 2001
    });

    if (!$result->{errno}) {
      print "User added with ID: $result->{INSERT_ID}\n";
    }

=cut
#**********************************************************
sub user_add {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080005) if !$attr->{UID};
  return $Errors->throw_error(1080002) if !$attr->{TP_ID};

  my $uid = $attr->{UID};
  my $tp_id = $attr->{TP_ID};
  my $user_info = $Users->info($uid);

  my $service_info = $self->_get_service_info($tp_id);
  if (ref($service_info) eq 'HASH' && $service_info->{errno}) {
    return $service_info;
  }

  if ($self->{USER_PORTAL}) {
    my ($user_portal_subscribe_id_key) = split(/:/, $self->{conf}->{IPTV_SUBSCRIBE_ID} || q{});
    $user_portal_subscribe_id_key ||= 'EMAIL';

    if (!$attr->{$user_portal_subscribe_id_key}) {
      return $Errors->throw_error(1080004, { lang_vars => { FIELD => $user_portal_subscribe_id_key } });
    }

    if (!$service_info->{USER_PORTAL} || $service_info->{USER_PORTAL} < 2) {
      return $Errors->throw_error(1080003);
    }

    my $checking_result = $self->_check_user_tariff_activation($tp_id, $user_info);
    return $checking_result if $checking_result;
  }

  my $limit_error = $self->_check_subscription_limits($uid, $tp_id, $service_info);
  return $limit_error if $limit_error;

  my $transaction = $self->_start_transaction();

  $Iptv->user_add({
    %{$attr},
    TP_ID      => $tp_id,
    UID        => $uid,
    SERVICE_ID => $service_info->{SERVICE_ID}
  });

  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return $Iptv;
  }

  if ($attr->{STATUS} && $attr->{STATUS} > 0) {
    $transaction->{commit}->();
    return $Iptv;
  }

  my $insert_id = $Iptv->{INSERT_ID};

  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  $Iptv->user_info($insert_id);
  $Iptv->{FEES} = {};

  my $fees_result = ::service_get_month_fee($Iptv, {
    SERVICE_NAME               => $self->{lang}{TV} || 'Iptv',
    DO_NOT_USE_GLOBAL_USER_PLS => 1,
    MODULE                     => 'Iptv',
    QUITE                      => 1
  });

  $Iptv->{FEES} = $fees_result;
  if (ref($fees_result) eq 'HASH' && $fees_result->{errno}) {
    $transaction->{rollback}->();
    return $fees_result;
  }

  if ($tv_service) {
    my $service_result = $self->_execute_service_user_add($tv_service, $uid, $insert_id, $attr);
    if (ref($service_result) eq 'HASH' && $service_result->{errno}) {
      $transaction->{rollback}->();
      return $service_result;
    }
  }

  if ($attr->{SUBSCRIBE_ID}) {
    $Iptv->subscribe_change({
      ID     => $attr->{SUBSCRIBE_ID},
      STATUS => 0
    });

    if ($self->{conf}{IPTV_SUBSCRIBE_CMD}) {
      $Iptv->subscribe_info($attr->{SUBSCRIBE_ID});
      cmd($self->{conf}{IPTV_SUBSCRIBE_CMD}, {
        PARAMS => { %{$Iptv}, ACTION => 'SET' },
        ARGV   => 1,
        debug  => $self->{conf}{IPTV_CMD_DEBUG}
      });
    }
  }

  $Iptv->{MANDATORY_CHANNELS} = $self->_get_mandatory_channels($tp_id);

  if ($Iptv->{MANDATORY_CHANNELS}) {
    my $channel_result = $self->user_change_channels({ ID => $insert_id, IDS => [ keys(%{$Iptv->{MANDATORY_CHANNELS}}) ] });
    if (ref($channel_result) eq 'HASH' && $channel_result->{errno}) {
      $transaction->{rollback}->();
      return $channel_result;
    }
  }

  if ($attr->{USER_IMPORT} && $tv_service && $tv_service->can('user_import')) {
    $tv_service->user_import({ %{$Users}, %{$Iptv}, %{$attr}, ID => $insert_id });

    if ($tv_service->{errno}) {
      $transaction->{rollback}->();
      return {
        errno  => $tv_service->{errno},
        errstr => $tv_service->{errstr}
      };
    }
  }

  $transaction->{commit}->();

  if ($self->{ENABLE_FEES_MESSAGES}) {
    push @{ $Iptv->{FEES_MESSAGES} }, @{ $self->_prepare_fees_messages($Iptv->{FEES}, $Iptv->{TP_INFO}) || [] };
  }

  $Iptv->{INSERT_ID} = $insert_id;

  #Fixme Global symbol "%conf" Equipment/Defs.pm line 13
  # if ($self->{conf}{IPTV_CHANGE_ONU_CATV_PORT_STATUS} && in_array('Equipment', \@main::MODULES)) {
  #   use Equipment;
  #   our $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  #   use Equipment::Pon_mng;
  #   ::equipment_tv_port({
  #     UID          => $uid,
  #     CATV_PORT_ID => 1, #XXX should disable all ports or only first?
  #     ENABLE_PORT  => 1
  #   });
  # }

  return $Iptv;
}

#**********************************************************
=head2 user_del($attr) - Delete an IPTV user with optional service-specific cleanup

  Arguments:
    $attr - Extra attributes
      ID         - IPTV user service ID (required unless UID and TP_ID are provided)
      UID        - Unique user identifier (used with TP_ID to find ID if not provided)
      TP_ID      - Tariff plan ID (used with UID to find ID if not provided)
      COMMENTS   - Deletion comments (optional)
      FORCE_DEL  - If set, forces deletion even if the service status would prevent it
      ...        - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after deletion

  Example:

    my $result = $Iptv_services->user_del({ ID => 12345, COMMENTS => 'User requested cancellation' });
    if (!$result->{errno}) {
      print "User deleted successfully\n";
    }

=cut
#**********************************************************
sub user_del {
  my ($self, $attr) = @_;

  if (!$attr->{ID}) {
    if ($attr->{UID} && $attr->{TP_ID}) {
      my $user_tp_info = $Iptv->user_list({
        UID        => $attr->{UID},
        TP_ID      => $attr->{TP_ID},
        SERVICE_ID => '_SHOW',
        COLS_NAME  => 1
      });

      if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0) {
        $attr->{ID} = $user_tp_info->[0]{id};
      }

      return $Errors->throw_error(1080008) if !$attr->{ID};
    }
    else {
      return $Errors->throw_error(1080008);
    }
  }

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $service_id = $user_service_info->{SERVICE_ID};
  my $uid = $user_service_info->{UID};
  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  my $transaction = $self->_start_transaction();

  $Iptv->user_del({ ID => $attr->{ID}, COMMENTS => $attr->{COMMENTS} });
  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return $Iptv;
  }
  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $service_id,
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  if ($tv_service && $tv_service->can('user_del')) {
    $Users->info($uid);
    $Users->pi({ UID => $uid });
    my $user_screens = $Iptv->users_screens_list({
      NUM              => '_SHOW',
      CID              => '_SHOW',
      SERIAL           => '_SHOW',
      USERS_SERVICE_ID => $attr->{ID},
      COLS_NAME        => 1,
      COLS_UPPER       => 1,
      SHOW_ASSIGN      => 1
    });

    $user_service_info->{STATUS} = 1 if $attr->{FORCE_DEL};
    $tv_service->user_del({ %$attr, %{$user_service_info}, %{$Users}, ID => $attr->{ID}, USER_SCREENS => $user_screens });

    if ($tv_service->{errno} || $tv_service->{error}) {
      $Iptv->{errno} = $tv_service->{errno};
      $Iptv->{errstr} = $tv_service->{errstr};
      $transaction->{rollback}->();
      return {
        errno  => $tv_service->{errno},
        errstr => $tv_service->{errstr}
      };
    }
  }

  ::_external('', { EXTERNAL_CMD => 'Iptv', %{($Users) ? $Users : {} }, %{$user_service_info}, ACTION => 'down', QUITE => 1 });

  $transaction->{commit}->();

  #Fixme Global symbol "%conf" Equipment/Defs.pm line 13
  # if ($self->{conf}{IPTV_CHANGE_ONU_CATV_PORT_STATUS} && in_array('Equipment', \@main::MODULES)) {
  #   use Equipment;
  #   our $Equipment = Equipment->new($self->{db}, $self->{admin}, $self->{conf});
  #   use Equipment::Pon_mng;
  #   ::equipment_tv_port({
  #     UID          => $uid,
  #     CATV_PORT_ID => 1, #XXX should disable all ports or only first?
  #     DISABLE_PORT => 1
  #   });
  # }

  return $Iptv;
}

#**********************************************************
=head2 user_change($attr) - Modify an existing IPTV user, including service-specific updates

  Arguments:
    $attr - Extra attributes
      ID         - IPTV user service ID (required)
      UID        - Unique user identifier (required)
      TP_ID      - New tariff plan ID (optional; triggers tariff change if different)
      STATUS     - New service status (optional)
      PASSWORD   - New password (optional; triggers password update if provided)
      ...        - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after modification

  Example:

    my $result = $Iptv_services->user_change({ ID => 12345, UID => 1001, STATUS => 1 });
    if (!$result->{errno}) {
      print "User updated successfully\n";
    }

=cut
#**********************************************************
sub user_change {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  return $Errors->throw_error(1080005) if !$attr->{UID};

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $uid = $user_service_info->{UID};
  if ($Iptv->{errno} || !$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  if (ref($service_info) eq 'HASH' && $service_info->{errno}) {
    return $service_info;
  }

  if ($self->{USER_PORTAL}) {
    if (!$service_info->{USER_PORTAL} || $service_info->{USER_PORTAL} < 2) {
      return $Errors->throw_error(1080003);
    }
  }

  if ($attr->{TP_ID} && $attr->{TP_ID} != $user_service_info->{TP_ID}) {
    return $self->user_chg_tp($attr);
  }

  my $user_info = $Users->info($attr->{UID});
  if ($Users->{errno}) {
    return {
      errno  => $Users->{errno},
      errstr => $Users->{errstr}
    };
  }

  if (!$Iptv->{UID} || $Iptv->{UID} ne $attr->{UID}) {
    return $Errors->throw_error(1080008);
  }

  my $transaction = $self->_start_transaction();
  $Iptv->user_change($attr);

  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return $Iptv;
  }

  if ($Iptv->{OLD_STATUS} && !$Iptv->{STATUS}) {
    my $result = $self->user_activate({ %{$attr}, SKIP_CHECK_USER_TARIFF_ACTIVATION => 1 });

    if (ref($result) eq 'HASH' && $result->{errno}) {
      $transaction->{rollback}->();
      return $result;
    }

    $transaction->{commit}->();
    return $Iptv;
  }

  ::_external('', { EXTERNAL_CMD => 'Iptv', %{$Iptv}, QUITE => 1 });

  if (($attr->{STATUS} && $Iptv->{OLD_STATUS}) || (defined($attr->{STATUS}) && $attr->{STATUS} == $Iptv->{OLD_STATUS})) {
    my @keys_to_check = qw(PASSWORD CHANGED_CONTACTS);
    my $should_continue = grep { $attr->{$_} } @keys_to_check;

    if (!$should_continue) {
      $transaction->{commit}->();
      return $Iptv;
    }
  }

  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  if ($tv_service) {
    my $service_result = $self->_execute_service_user_change($tv_service, $uid, $attr->{ID}, $attr);
    if (ref($service_result) eq 'HASH' && $service_result->{errno}) {
      $transaction->{rollback}->();
      return $service_result;
    }
  }

  # if ($tv_service && $tv_service->can('user_change')) {
  #   $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
  #   $Users->pi({ UID => $attr->{UID} });
  #   $Iptv->user_info($attr->{ID});
  #   $tv_service->user_change({
  #     %$Iptv,
  #     %$Users,
  #     %$attr,
  #     EMAIL         => $Users->{EMAIL} || $Iptv->{EMAIL},
  #     SERVICE_EMAIL => $Iptv->{EMAIL}
  #   });
  #
  #   if ($tv_service->{errno}) {
  #     $transaction->{rollback}->();
  #     $Iptv->{errno} = $tv_service->{errno};
  #     $Iptv->{errstr} = $tv_service->{errstr};
  #     return {
  #       errno  => $tv_service->{errno},
  #       errstr => $tv_service->{errstr}
  #     };
  #   }
  #
  #   if ($tv_service->{SUBSCRIBE_ID}) {
  #     $Iptv->user_change({
  #       ID           => $attr->{ID},
  #       SUBSCRIBE_ID => $tv_service->{SUBSCRIBE_ID}
  #     });
  #   }
  # }

  $transaction->{commit}->();

  return $Iptv;
}
#**********************************************************
=head2 user_negdeposit($attr) - Set IPTV user status to "negative deposit" and trigger service-specific handling

  Arguments:
    $attr - Extra attributes
      ID     - IPTV user service ID (required)
      UID    - Unique user identifier (required)
      ...    - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after status change

  Example:

    my $result = $Iptv_services->user_negdeposit({ ID => 12345, UID => 1001 });
    if (!$result->{errno}) {
      print "User marked as negative deposit successfully\n";
    }

=cut
#**********************************************************
sub user_negdeposit {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  return $Errors->throw_error(1080005) if !$attr->{UID};

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $uid = $user_service_info->{UID};
  if ($Iptv->{errno} || !$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  if (!$Iptv->{UID} || $Iptv->{UID} ne $attr->{UID}) {
    return $Errors->throw_error(1080008);
  }

  my $transaction = $self->_start_transaction();
  $Iptv->user_change({ ID => $attr->{ID}, STATUS => 5 });
  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return $Iptv;
  }

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  if ($tv_service && $tv_service->can('user_negdeposit')) {
    $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
    $Users->pi({ UID => $attr->{UID} });
    $Iptv->user_info($attr->{ID});
    $tv_service->user_negdeposit({
      %$Users,
      %$Iptv,
      %$attr,
      EMAIL         => $Users->{EMAIL} || $Iptv->{EMAIL},
      SERVICE_EMAIL => $Iptv->{EMAIL}
    });

    if ($tv_service->{errno}) {
      $Iptv->{errno} = $tv_service->{errno};
      $Iptv->{errstr} = $tv_service->{errstr};
      $transaction->{rollback}->();
      return {
        errno  => $tv_service->{errno},
        errstr => $tv_service->{errstr}
      };
    }
  }

  $transaction->{commit}->();
  return $Iptv;
}

#**********************************************************
=head2 user_activate($attr) - Activate an IPTV user and perform service-specific setup

  Arguments:
    $attr - Extra attributes
      ID                             - IPTV user service ID (required)
      UID                            - Unique user identifier (required)
      SKIP_CHECK_USER_TARIFF_ACTIVATION - Skip tariff activation check if set (optional)
      ...                            - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after activation, including:
        FEES          - Monthly fee calculation results
        FEES_MESSAGES - Optional fee-related messages (if enabled)

  Example:

    my $result = $Iptv_services->user_activate({ ID => 12345, UID => 1001 });
    if (!$result->{errno}) {
      print "User activated successfully\n";
    }

=cut
#**********************************************************
sub user_activate {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  return $Errors->throw_error(1080005) if !$attr->{UID};

  $attr->{STATUS} = 0;
  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $uid = $user_service_info->{UID};
  if ($Iptv->{errno} || !$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  if (ref($service_info) eq 'HASH' && $service_info->{errno}) {
    return $service_info;
  }

  if ($self->{USER_PORTAL}) {
    if (!$service_info->{USER_PORTAL} || $service_info->{USER_PORTAL} < 2) {
      return $Errors->throw_error(1080003);
    }
  }

  my $user_info = $Users->info($attr->{UID});
  if ($Users->{errno}) {
    return {
      errno  => $Users->{errno},
      errstr => $Users->{errstr}
    };
  }

  if (!$Iptv->{UID} || $Iptv->{UID} ne $attr->{UID}) {
    return $Errors->throw_error(1080008);
  }

  if (!$attr->{SKIP_CHECK_USER_TARIFF_ACTIVATION}) {
    my $checking_result = $self->_check_user_tariff_activation($user_service_info->{TP_ID}, $user_info);
    return $checking_result if $checking_result;
  }

  my $transaction = $self->_start_transaction();

  $Iptv->user_change({
    ID     => $attr->{ID},
    STATUS => 0
  });

  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return $Iptv;
  }

  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  $Iptv->user_info($attr->{ID});
  $Iptv->{FEES} = {};

  delete $Iptv->{TP_INFO}{ACTIV_PRICE};
  my $fees_result = ::service_get_month_fee($Iptv, {
    SERVICE_NAME               => $self->{lang}{TV} || 'Iptv',
    DO_NOT_USE_GLOBAL_USER_PLS => 1,
    MODULE                     => 'Iptv',
    QUITE                      => 1
  });

  $Iptv->{FEES} = $fees_result;
  if (ref($fees_result) eq 'HASH' && $fees_result->{errno}) {
    $transaction->{rollback}->();
    return $fees_result;
  }

  my $service_result = $self->_execute_service_user_add($tv_service, $attr->{UID}, $attr->{ID}, $attr);
  if (ref($service_result) eq 'HASH' && $service_result->{errno}) {
    $transaction->{rollback}->();
    return $service_result;
  }
  $self->_activate_user_channels($attr, $user_service_info, $user_info);
  $attr->{BUNDLE_TYPE} = 'subs_renew';
  $self->_activate_user_screens($tv_service, $attr, $user_service_info, $user_info);

  $transaction->{commit}->();

  if ($self->{ENABLE_FEES_MESSAGES}) {
    push @{ $Iptv->{FEES_MESSAGES} }, @{ $self->_prepare_fees_messages($Iptv->{FEES}, $Iptv->{TP_INFO}) || [] };
  }

  return $Iptv;
}

#**********************************************************
=head2 user_chg_tp($attr) - Change the IPTV user's tariff plan with validation and service-specific updates

  Arguments:
    $attr - Extra attributes
      ID          - IPTV user service ID (required)
      UID         - Unique user identifier (required)
      TP_ID       - New tariff plan ID (required)
      GET_ABON    - Flag to get subscription fees (optional)
      RECALCULATE - Flag to recalculate fees (optional)
      ...         - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after tariff change, including:
        FEES          - Monthly fee calculation results (if applicable)
        FEES_MESSAGES - Optional fee-related messages (if enabled)

  Example:

    my $result = $Iptv_services->user_chg_tp({ ID => 12345, UID => 1001, TP_ID => 2002 });
    if (!$result->{errno}) {
      print "Tariff plan changed successfully\n";
    }

=cut
#**********************************************************
sub user_chg_tp {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  return $Errors->throw_error(1080005) if !$attr->{UID};

  if (!$self->{SYSTEM_ADMIN}) {
    if (!$self->{admin}->{permissions}{0}{4}) {
      return $Errors->throw_error(1080009);
    }
    if (!$self->{admin}->{permissions}{0}{10}) {
      return $Errors->throw_error(1080009);
    }
  }

  $Users->info($attr->{UID});
  if ($Users->{errno}) {
    return {
      errno  => $Users->{errno},
      errstr => $Users->{errstr}
    };
  }

  if (!$attr->{TP_ID}) {
    return $Errors->throw_error(1080002);
  }

  $Tariffs->info($attr->{TP_ID});
  if (!$Tariffs->{MODULE} || $Tariffs->{MODULE} ne 'Iptv') {
    return $Errors->throw_error(1080010);
  }

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  if ($Iptv->{errno} || !$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  if (!$Iptv->{UID} || $Iptv->{UID} ne $attr->{UID}) {
    return $Errors->throw_error(1080008);
  }

  if ($Iptv->{TP_ID} == $attr->{TP_ID}) {
    return $Errors->throw_error(1080011);
  }

  $user_service_info->{ABON_DATE} = $self->_service_get_abon_date({
    SERVICE   => $user_service_info,
    USER_INFO => $Users
  });

  my $scheduled_result = $self->_handle_scheduled_tariff_change($attr, $user_service_info);
  if ($scheduled_result) {
    return $scheduled_result;
  }

  my $transaction = $self->_start_transaction();
  $Iptv->user_change($attr);

  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return $Iptv;
  }

  if (!$user_service_info->{STATUS} && ($attr->{GET_ABON} || $attr->{RECALCULATE})) {
    delete $Iptv->{TP_INFO}{ACTIV_PRICE};

    if (!($attr->{GET_ABON} && $attr->{GET_ABON} eq '-1' && $attr->{RECALCULATE} && $attr->{RECALCULATE} eq '-1')) {
      my $fees_result = ::service_get_month_fee($Iptv, {
        SERVICE_NAME               => $self->{lang}{TV},
        RECALCULATE                => $attr->{RECALCULATE},
        DO_NOT_USE_GLOBAL_USER_PLS => 1,
        MODULE                     => 'Iptv',
        QUITE                      => 1
      });
      $Iptv->{FEES} = $fees_result;

      if ($self->{ENABLE_FEES_MESSAGES}) {
        push @{ $Iptv->{FEES_MESSAGES} }, @{ $self->_prepare_fees_messages($Iptv->{FEES}, $Iptv->{TP_INFO}) || [] };
      }
    }
  }

  $Iptv->user_info($attr->{ID});

  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });
    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  if ($tv_service && $tv_service->can('user_change')) {
    $Users->info($attr->{UID}, { SHOW_PASSWORD => 1 });
    $Users->pi({ UID => $attr->{UID} });

    $tv_service->user_change({
      %$Users,
      %$Iptv,
      %$attr,
      EMAIL         => $Users->{EMAIL} || $Iptv->{EMAIL},
      SERVICE_EMAIL => $Iptv->{EMAIL},
      CHANGE_TP     => 1
    });

    if ($tv_service->{errno} || $tv_service->{error}) {
      $Iptv->{errno} = $tv_service->{errno};
      $Iptv->{errstr} = $tv_service->{errstr};
      $transaction->{rollback}->();
      return {
        errno  => $tv_service->{errno},
        errstr => $tv_service->{errstr}
      };
    }

    if ($tv_service->{SUBSCRIBE_ID}) {
      $Iptv->user_change({
        ID           => $attr->{ID},
        SUBSCRIBE_ID => $tv_service->{SUBSCRIBE_ID}
      });
    }
  }

  $transaction->{commit}->();

  return $Iptv;
}

#**********************************************************
=head2 user_screen_add($attr) - Add a screen/device to an IPTV user service with fee processing and service-specific updates

  Arguments:
    $attr - Extra attributes
      ID          - IPTV user service ID (required)
      SCREEN_ID   - ID of the screen/device to add (required)
      CID         - Optional client ID
      SERIAL      - Optional device serial number
      COMMENT     - Optional comment
      BUNDLE_TYPE - Optional bundle type for screen/device
      ...         - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after adding the screen, including:
        FEES          - Fee calculation results for the added screen
        FEES_MESSAGES - Optional fee-related messages (if enabled)

  Example:

    my $result = $Iptv_services->user_screen_add({ ID => 12345, SCREEN_ID => 678 });
    if (!$result->{errno}) {
      print "Screen added successfully\n";
    }

=cut
#**********************************************************
sub user_screen_add {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  return $Errors->throw_error(1080004, { lang_vars => { FIELD => 'screen_id' } }) if !$attr->{SCREEN_ID};

  my $screen_info = $Iptv->users_screens_info($attr->{ID}, { SCREEN_ID => $attr->{SCREEN_ID} });
  $attr->{OLD_CID} = $Iptv->{CID} if ($Iptv->{CID} && $Iptv->{CID} ne $attr->{CID});
  $attr->{SCREEN_FILTER_ID} = $Iptv->{FILTER_ID};

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  my $service_id = $user_service_info->{SERVICE_ID};
  return $Errors->throw_error(1080008) if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1);
  return $Errors->throw_error(1080002) if (!$user_service_info->{TP_ID});

  my $user_info = $Users->info($user_service_info->{UID});
  return $Errors->throw_error(1080008) if (!$user_info);

  my $transaction = $self->_start_transaction();

  $Iptv->users_screens_add({
    SERVICE_ID => $attr->{ID},
    SCREEN_ID  => $attr->{SCREEN_ID},
    CID        => $attr->{CID},
    SERIAL     => $attr->{SERIAL} || '',
    COMMENT    => $attr->{COMMENT} || ''
  });
  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $Iptv->{errno},
      errstr => $Iptv->{errstr}
    };
  }

  my $fee_result = $self->_process_screen_fees({
    SCREEN_ID => $attr->{SCREEN_ID},
    TP_ID     => $user_service_info->{TP_ID}
  });
  if (ref($fee_result) eq 'HASH' && $fee_result->{errno}) {
    $transaction->{rollback}->();
    return $fee_result;
  }

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $service_id,
      LANG       => $self->{lang}
    });

    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  if (!$tv_service || !$tv_service->can('user_screens')) {
    $transaction->{commit}->();
    return $Iptv;
  }

  my %params = (%{$attr},
    BUNDLE_TYPE => $attr->{BUNDLE_TYPE} || ($attr->{CID} ? 'subs_free_device' : undef) || 'subs_no_device'
  );

  $params{SUBSCRIBE_ID} = $user_service_info->{SUBSCRIBE_ID} if $user_service_info->{SUBSCRIBE_ID};

  $Users->info($user_service_info->{UID}, { SHOW_PASSWORD => 1 });
  $params{LOGIN} = $Users->{LOGIN};
  $params{PASSWORD} = $Users->{PASSWORD};
  $params{DEPOSIT} = $Users->{DEPOSIT};

  $tv_service->user_screens(\%params);

  if ($tv_service->{errno}) {
    $Iptv->{errno} = $tv_service->{errno};
    $Iptv->{errstr} = $tv_service->{errstr};
    $transaction->{rollback}->();
    return {
      errno  => $tv_service->{errno},
      errstr => $tv_service->{errstr}
    };
  }

  $Iptv->users_screens_add({
    SERVICE_ID => $attr->{ID},
    SCREEN_ID  => $tv_service->{SCREEN_ID} || $attr->{SCREEN_ID},
    CID        => $tv_service->{CID},
    SERIAL     => $tv_service->{SERIAL} || '',
    COMMENT    => $tv_service->{COMMENT} || ''
  });

  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $Iptv->{errno},
      errstr => $Iptv->{errstr}
    };
  }

  if ($self->{ENABLE_FEES_MESSAGES}) {
    push @{ $Iptv->{FEES_MESSAGES} }, @{ $self->_prepare_fees_messages($Iptv->{FEES}, $Iptv->{TP_INFO}) || [] };
  }

  $transaction->{commit}->();
  return $Iptv;
}

#**********************************************************
=head2 user_screen_del($attr) - Remove a screen/device from an IPTV user service with service-specific updates

  Arguments:
    $attr - Extra attributes
      ID              - IPTV user service ID (required)
      SCREEN_ID       - ID of the screen/device to remove (required)
      CID             - Optional client ID
      SERIAL          - Optional device serial number
      TYPE            - Optional removal type (default: 'subs_break_contract')
      DEVICE_DEL_TYPE - Optional device removal type (default: 'device_break_contract')
      ...             - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after removing the screen/device, including error codes if any.

  Example:

    my $result = $Iptv_services->user_screen_del({ ID => 12345, SCREEN_ID => 678 });
    if (!$result->{errno}) {
      print "Screen removed successfully\n";
    }

=cut
#**********************************************************
sub user_screen_del {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  return $Errors->throw_error(1080004, { lang_vars => { FIELD => 'screen_id' } }) if !$attr->{SCREEN_ID};

  my $screen_info = $Iptv->users_screens_info($attr->{ID}, { SCREEN_ID => $attr->{SCREEN_ID} });
  my $user_service_info = $Iptv->user_info($attr->{ID});
  return $Errors->throw_error(1080008) if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1);
  return $Errors->throw_error(1080002) if (!$user_service_info->{TP_ID});

  my $user_info = $Users->info($user_service_info->{UID});
  return $Errors->throw_error(1080008) if (!$user_info);

  my $transaction = $self->_start_transaction();

  $Iptv->users_screens_del({ SERVICE_ID => $attr->{ID}, SCREEN_ID => $attr->{SCREEN_ID}, UID => $user_service_info->{UID} });
  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $Iptv->{errno},
      errstr => $Iptv->{errstr}
    };
  }

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });

    if (!$tv_service) {
      $transaction->{rollback}->();
      return $Errors->throw_error(1080003);
    }
  }

  if (!$tv_service || !$tv_service->can('user_screens')) {
    $transaction->{commit}->();
    return $Iptv;
  }

  my %params = (
    MAC             => $screen_info->{CID} || $attr->{CID},
    %{$attr},
    CID             => $screen_info->{CID} || $attr->{CID},
    ID              => $attr->{ID},
    SERIAL          => $screen_info->{SERIAL} || $attr->{SERIAL},
    TP_FILTER_ID    => $user_service_info->{FILTER_ID},
    SUB_ID          => $user_service_info->{FILTER_ID},
    del             => 1,
    TYPE            => $attr->{TYPE} || 'subs_break_contract',
    DEVICE_DEL_TYPE => $attr->{DEVICE_DEL_TYPE} || 'device_break_contract'
  );

  $params{SUBSCRIBE_ID} = $user_service_info->{SUBSCRIBE_ID} if $user_service_info->{SUBSCRIBE_ID};

  $Users->info($user_service_info->{UID}, { SHOW_PASSWORD => 1 });
  $params{LOGIN} = $Users->{LOGIN};
  $params{PASSWORD} = $Users->{PASSWORD};
  $params{DEPOSIT} = $Users->{DEPOSIT};

  $tv_service->user_screens(\%params);

  if ($tv_service->{errno}) {
    $Iptv->{errno} = $tv_service->{errno};
    $Iptv->{errstr} = $tv_service->{errstr};
    $transaction->{rollback}->();
    return {
      errno  => $tv_service->{errno},
      errstr => $tv_service->{errstr}
    };
  }

  $transaction->{commit}->();
  return $Iptv;
}

#**********************************************************
=head2 user_change_channels($attr) - Change the channels assigned to an IPTV user service

  Arguments:
    $attr - Extra attributes
      ID    - IPTV user service ID (required)
      IDS   - Optional list/array of channel IDs to assign
      ...   - Other IPTV-specific attributes

  Returns:
    HASHREF
      Contains IPTV module result data after changing channels, including error codes if any.

  Example:

    my $result = $Iptv_services->user_change_channels({ ID => 12345, IDS => [1,2,3,4] });
    if (!$result->{errno}) {
      print "Channels updated successfully\n";
    }

=cut
#**********************************************************
sub user_change_channels {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};
  my $user_service_info = $Iptv->user_info($attr->{ID});
  return $Errors->throw_error(1080008) if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1);
  return $Errors->throw_error(1080002) if (!$user_service_info->{TP_ID});

  my $user_info = $Users->info($user_service_info->{UID}, { SHOW_PASSWORD => 1 });
  return $Errors->throw_error(1080008) if (!$user_info);

  my $transaction = $self->_start_transaction();

  my $channels_to_add  = $self->_process_channels($attr, $user_service_info, $user_info);
  if (ref($channels_to_add) eq 'HASH' && $channels_to_add->{errno}) {
    $transaction->{rollback}->();
    return $channels_to_add;
  }

  if (scalar(@$channels_to_add) < 1) {
    return {};
  }

  $Iptv->user_channels({
    ID    => $attr->{ID},
    TP_ID => $user_service_info->{TP_ID},
    IDS   => join(',', @$channels_to_add)
  });

  if ($Iptv->{errno}) {
    $transaction->{rollback}->();
    return {
      errno  => $Iptv->{errno},
      errstr => $Iptv->{errstr}
    };
  }

  my $service_result = $self->_execute_service_channel_changes($user_service_info, $user_info, $channels_to_add, $attr);
  if (ref($service_result) eq 'HASH' && $service_result->{errno}) {
    $transaction->{rollback}->();
    return $service_result;
  }

  $transaction->{commit}->();
  return $Iptv;
}

#**********************************************************
=head2 user_service_extra_fields($attr) - Get extra IPTV fields for a user service

  Arguments:
    $attr - Extra attributes
      ID - IPTV user service ID (required)

  Returns:
    HASHREF
      Contains extra fields from the IPTV portal for the given user service.
      Returns an empty hashref if no extra fields are available.

  Example:

    my $extra_fields = $Iptv_services->user_service_extra_fields({ ID => 12345 });
    print Dumper($extra_fields);

=cut
#**********************************************************
sub user_service_extra_fields {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};

  $Iptv->user_info($attr->{ID});
  my $user_service_info = { %$Iptv };
  if ($Iptv->{errno} || !$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  my $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
    SERVICE_ID => $user_service_info->{SERVICE_ID},
    LANG       => $self->{lang}
  });
  if (!$tv_service || !$tv_service->can('get_iptv_portal_extra_fields')) {
    return {};
  }

  return $tv_service->get_iptv_portal_extra_fields($user_service_info);
}

#**********************************************************
=head2 service_info($attr) - Get information about an IPTV service

  Arguments:
    $attr - Attributes hashref
      TP_ID                  - Tariff plan ID (required)
      CHECK_METHOD_AVAILABLE - Optional flag to check if the service_info method exists

  Returns:
    HASHREF
      Returns detailed service information from the IPTV service.
      Returns 1/0 if CHECK_METHOD_AVAILABLE is set.
      Returns an empty string if the service_info method is not implemented.

  Example:
    my $service_info = $Iptv_services->service_info({ ID => 123 });

=cut
#**********************************************************
sub service_info {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080002) if !$attr->{TP_ID};

  my $service_info = $self->_get_service_info($attr->{TP_ID});
  if (ref($service_info) eq 'HASH' && $service_info->{errno}) {
    return $service_info;
  }

  my $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
    SERVICE_ID => $service_info->{SERVICE_ID},
    LANG       => $self->{lang}
  });
  if (!$tv_service || !$tv_service->can('service_info')) {
    return '';
  }

  if ($attr->{CHECK_METHOD_AVAILABLE}) {
    return $tv_service->can('service_info') ? 1 : 0;
  }

  return $tv_service->service_info($Tariffs);
}

#**********************************************************
=head2 service_m3u_playlist($attr) - Get the M3U playlist for a user service

  Arguments:
    $attr - Attributes hashref
      ID                     - User service ID (required)
      CHECK_METHOD_AVAILABLE - Optional flag to check if get_playlist_m3u method exists

  Returns:
    STRING / HASHREF
      Returns the M3U playlist as a string from the IPTV service.
      Returns 1/0 if CHECK_METHOD_AVAILABLE is set.
      Returns an empty string if the get_playlist_m3u method is not implemented.

  Example:
    my $playlist = $Iptv_services->service_m3u_playlist({ ID => 123 });

=cut
#**********************************************************
sub service_m3u_playlist {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};

  my $user_service_info = $Iptv->user_info($attr->{ID});
  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  my $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
    SERVICE_ID => $user_service_info->{SERVICE_ID},
    LANG       => $self->{lang}
  });
  if (!$tv_service || !$tv_service->can('get_playlist_m3u')) {
    return '';
  }

  if ($attr->{CHECK_METHOD_AVAILABLE}) {
    return $tv_service->can('get_playlist_m3u') ? 1 : 0;
  }

  return $tv_service->get_playlist_m3u($user_service_info);
}

#**********************************************************
=head2 service_hangup($attr) - Hang up a user service (IPTV)

  Arguments:
    $attr - Attributes hashref
      ID - User service ID (required)

  Returns:
    HASHREF
      Returns the result of the hangup operation from the IPTV service.
      Returns empty hashref if the hangup method is not implemented.

  Example:
    my $result = $Iptv_services->service_hangup({ ID => 123 });

=cut
#**********************************************************
sub service_hangup {
  my ($self, $attr) = @_;

  return $Errors->throw_error(1080008) if !$attr->{ID};

  my $user_service_info = $Iptv->user_info($attr->{ID});
  if ($Iptv->{errno} || !$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080008);
  }

  my $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
    SERVICE_ID => $user_service_info->{SERVICE_ID},
    LANG       => $self->{lang}
  });
  if (!$tv_service || !$tv_service->can('hangup')) {
    return {};
  }

  return $tv_service->hangup({ %{$attr}, %{$user_service_info} });
}

#**********************************************************
=head2 _start_transaction() - Initialize transaction manager

  Arguments:
    None

  Returns:
    HASHREF
      {
        rollback => sub { ... }, # Rollback transaction if needed
        commit   => sub { ... }  # Commit transaction if needed
      }

  Example:
    my $transaction = $self->_start_transaction();
    $transaction->{commit}->();

=cut
#**********************************************************
sub _start_transaction {
  my ($self) = @_;

  my $db = $Iptv->{db}{db};
  my $manage_transaction = !$Iptv->{db}->{TRANSACTION};

  if ($manage_transaction) {
    $db->{AutoCommit} = 0;
    $Iptv->{db}->{TRANSACTION} = 1;
  }

  return {
    rollback => sub {
      return if !$manage_transaction;

      delete $Iptv->{db}->{TRANSACTION};
      $db->rollback();
      $db->{AutoCommit} = 1;
    },
    commit => sub {
      return if !$manage_transaction;

      delete $Iptv->{db}->{TRANSACTION};
      $db->commit();
      $db->{AutoCommit} = 1;
    }
  };
}

#**********************************************************
=head2 _execute_service_user_add($tv_service, $uid, $user_service_id, $attr) - Add user to IPTV service

  Arguments:
    $tv_service        - Initialized IPTV service object
    $uid               - User ID in the system
    $user_service_id   - ID of the IPTV user service
    $attr              - Hashref with additional attributes

  Returns:
    undef              - On success
    HASHREF            - { errno, errstr } on failure

  Example:
    my $error = $self->_execute_service_user_add($tv_service, 42, 1001, { EMAIL => 'test@example.com' });

=cut
#**********************************************************
sub _execute_service_user_add {
  my ($self, $tv_service, $uid, $user_service_id, $attr) = @_;

  if (!$tv_service || !$tv_service->can('user_add')) {
    return undef;
  }

  $Users->info($uid, { SHOW_PASSWORD => 1 });
  $Users->pi({ UID => $uid });
  $Iptv->user_info($user_service_id);

  $tv_service->user_add({
    %{$Iptv},
    %{$Users},
    %{$attr},
    PASSWORD      => $Users->{PASSWORD},
    ID            => $Iptv->{ID},
    EMAIL         => $attr->{EMAIL} || $Iptv->{EMAIL} || $Users->{EMAIL},
    PHONE         => $Users->{PHONE} || $attr->{PHONE},
    SERVICE_EMAIL => $Iptv->{EMAIL}
  });

  if ($tv_service->{errno}) {
    delete $Iptv->{ID};
    $Iptv->{errno} = $tv_service->{errno};
    $Iptv->{errstr} = $tv_service->{errstr};
    return {
      errno  => $tv_service->{errno},
      errstr => $tv_service->{errstr}
    };
  }

  if ($tv_service->{SUBSCRIBE_ID}) {
    $Iptv->user_change({
      ID           => $user_service_id,
      SUBSCRIBE_ID => $tv_service->{SUBSCRIBE_ID}
    });
  }

  return undef;
}

#**********************************************************
=head2 _execute_service_user_change($tv_service, $uid, $user_service_id, $attr) - Change user IPTV service

  Arguments:
    $tv_service        - Initialized IPTV service object
    $uid               - User ID in the system
    $user_service_id   - ID of the IPTV user service
    $attr              - Hashref with additional attributes

  Returns:
    undef              - On success
    HASHREF            - { errno, errstr } on failure

  Example:
    my $error = $self->_execute_service_user_change($tv_service, 42, 1001, { EMAIL => 'test@example.com' });

=cut
#**********************************************************
sub _execute_service_user_change {
  my ($self, $tv_service, $uid, $user_service_id, $attr) = @_;

  if (!$tv_service || !$tv_service->can('user_change')) {
    return undef;
  }

  $Users->info($uid, { SHOW_PASSWORD => 1 });
  $Users->pi({ UID => $uid });
  $Iptv->user_info($user_service_id);

  $tv_service->user_change({
    %{$Iptv},
    %{$attr},
    %{$Users},
    ID            => $Iptv->{ID},
    EMAIL         => $attr->{EMAIL} || $Iptv->{EMAIL} || $Users->{EMAIL},
    SERVICE_EMAIL => $Iptv->{EMAIL}
  });

  if ($tv_service->{errno}) {
    delete $Iptv->{ID};
    $Iptv->{errno} = $tv_service->{errno};
    $Iptv->{errstr} = $tv_service->{errstr};
    return {
      errno  => $tv_service->{errno},
      errstr => $tv_service->{errstr}
    };
  }

  if ($tv_service->{SUBSCRIBE_ID}) {
    $Iptv->user_change({
      ID           => $user_service_id,
      SUBSCRIBE_ID => $tv_service->{SUBSCRIBE_ID}
    });
  }

  return undef;
}

#**********************************************************
=head2 _execute_service_channel_changes($user_service_info, $user_info, $channels_to_add, $attr) - Apply channel changes to IPTV service

  Arguments:
    $user_service_info - Hashref with user service information
    $user_info         - Hashref with user account information
    $channels_to_add   - Arrayref of channel IDs to add
    $attr              - Hashref with additional attributes

  Returns:
    undef              - On success
    HASHREF            - { errno, errstr } on failure

  Example:
    $self->_execute_service_channel_changes(
      $user_service_info,
      $user_info,
      [101, 102, 103],
      { ID => 555 }
    );

=cut
#**********************************************************
sub _execute_service_channel_changes {
  my ($self, $user_service_info, $user_info, $channels_to_add, $attr) = @_;

  my $service_info = $self->_get_service_info($user_service_info->{TP_ID});
  my $tv_service;
  if ($service_info && $service_info->{MODULE}) {
    $tv_service = init_iptv_service($self->{db}, $self->{admin}, $self->{conf}, {
      SERVICE_ID => $user_service_info->{SERVICE_ID},
      LANG       => $self->{lang}
    });

    if (!$tv_service) {
      return $Errors->throw_error(1080003);
    }
  }

  if ($tv_service && $tv_service->can('channels_change')) {
    my $filter_ids = [];
    my $channel_ti_list = $Iptv->channel_ti_list({
      ID        => join(';', @$channels_to_add) || '-',
      FILTER_ID => '_SHOW',
      COLS_NAME => 1
    });

    foreach my $line (@$channel_ti_list) {
      if ($line->{filter_id}) {
        push @{$filter_ids}, $line->{filter_id};
      }
    }

    $tv_service->channels_change({
      %{$attr},
      %{$user_service_info},
      %{$user_info},
      FILTER_ID => join(',', @$filter_ids),
      ID        => $attr->{ID},
    });

    if ($tv_service->{errno}) {
      $Iptv->{errno} = $tv_service->{errno};
      $Iptv->{errstr} = $tv_service->{errstr};
      return {
        errno  => $tv_service->{errno},
        errstr => $tv_service->{errstr}
      };
    }
  }

  return undef;
}

#**********************************************************
=head2 _get_service_info($tp_id) - Retrieve service information by tariff plan ID

  Arguments:
    $tp_id     - Tariff plan ID

  Returns:
    HASHREF    - Service information on success
    HASHREF    - { errno, errstr } on failure

  Example:
    my $service_info = $self->_get_service_info(42);

=cut
#**********************************************************
sub _get_service_info {
  my ($self, $tp_id) = @_;

  my $tp_info = $Tariffs->info(undef, { TP_ID => $tp_id });

  my $service_id = 0;
  if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) {
    $service_id = $tp_info->{SERVICE_ID};
    $Iptv->{TP_INFO} = $tp_info;
  }

  return {} if !$service_id;

  my $service_info = $Iptv->services_info($service_id);
  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080003);
  }

  if ($service_info->{STATUS} && $service_info->{STATUS} > 0) {
    return $Errors->throw_error(1080003);
  }

  $service_info->{SERVICE_ID} = $service_id;
  return $service_info;
}

#**********************************************************
=head2 _get_mandatory_channels($tp_id) - Retrieve the list of mandatory channels for a tariff plan

  Arguments:
    $tp_id     - Tariff plan ID

  Returns:
    HASHREF    - {
                    channel_id => {
                      NUM         => <channel number>,
                      NAME        => <channel name>,
                      FILTER_ID   => <filter ID>,
                      MONTH_PRICE => <monthly price>,
                      DAY_PRICE   => <daily price>
                    },
                    ...
                  }
    undef      - If no mandatory channels found

  Example:
    my $mandatory_channels = $self->_get_mandatory_channels(42);


=cut
#**********************************************************
sub _get_mandatory_channels {
  my ($self, $tp_id) = @_;

  my %tp_channels_list = ();
  $Tariffs->ti_list({ TP_ID => $tp_id, COLS_NAME => 1 });

  return undef if (!$Tariffs->{TOTAL} || $Tariffs->{TOTAL} < 1);

  my $channels_list = $Iptv->channel_ti_list({
    INTERVAL_ID => $Tariffs->{list}->[0]->{id},
    MANDATORY   => 1,
    FILTER_ID   => '_SHOW',
    COLS_NAME   => 1
  });

  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return undef;
  }

  foreach my $line (@{$channels_list}) {
    my $channel_id = $line->{channel_id};
    $tp_channels_list{$channel_id} = {
      NUM         => $line->{channel_num},
      NAME        => $line->{name},
      FILTER_ID   => $line->{filter_id},
      MONTH_PRICE => $line->{month_price},
      DAY_PRICE   => $line->{day_price},
    };
  }

  return \%tp_channels_list;
}

#**********************************************************
=head2 _get_affordable_channels($channel_ids, $interval_id, $user_info) - Determine which channels the user can afford

  Arguments:
    $channel_ids  - Arrayref of channel IDs to check
    $interval_id  - User's current tariff interval ID
    $user_info    - Hashref with user details (DEPOSIT, CREDIT, REDUCTION, etc.)

  Returns:
    ARRAYREF  - List of affordable channel IDs
    HASHREF   - { errno, errstr } on failure

  Example:
    my $affordable = $self->_get_affordable_channels([1,2,3], 10, $user_info);

=cut
#**********************************************************
sub _get_affordable_channels {
  my ($self, $channel_ids, $interval_id, $user_info) = @_;

  my $channel_list = $Iptv->channel_ti_list({
    DISABLE          => 0,
    COLS_NAME        => 1,
    USER_INTERVAL_ID => $interval_id,
    IDS              => join('; ', @$channel_ids)
  });

  if (!$channel_list || ref($channel_list) ne 'ARRAY') {
    return $Errors->throw_error(1080014);
  }

  my $user_deposit = $user_info->{CREDIT} + ($user_info->{DEPOSIT} || 0);
  my @affordable_channels = ();

  foreach my $channel (@$channel_list) {
    my $price = $channel->{month_price} || $channel->{day_price} || 0;

    if ($user_info->{REDUCTION} && $user_info->{REDUCTION} > 0 && $channel->{REDUCTION_FEE}) {
      $price *= (100 - $user_info->{REDUCTION}) / 100;
    }

    if ($user_deposit >= $price || $Iptv->{PAYMENT_TYPE} || $Iptv->{POSTPAID_MONTHLY_FEE}) {
      $user_deposit -= $price;
      push @affordable_channels, $channel->{channel_id};
    }
  }

  return \@affordable_channels;
}

#**********************************************************
=head2 _process_channels($attr, $user_service_info, $user_info) - Determine which channels should be added for the user

  Arguments:
    $attr               - Hashref with attributes
      IDS               - Arrayref or comma-separated list of channel IDs requested by the user
    $user_service_info  - Hashref with user service details (TP_ID, ID, etc.)
    $user_info          - Hashref with user details (deposit, credit, reduction, etc.)

  Returns:
    ARRAYREF  - List of channel IDs to be added
    HASHREF   - { errno, errstr } on failure

  Example:
    my $channels_to_add = $self->_process_channels(
      { IDS => [101, 102, 103] },
      $user_service_info,
      $user_info
    );

=cut
#**********************************************************
sub _process_channels {
  my ($self, $attr, $user_service_info, $user_info) = @_;

  my $activated_user_channels = {};
  my $activated_user_channels_list = $Iptv->user_channels_list({
    TP_ID     => $user_service_info->{TP_ID},
    ID        => $user_service_info->{ID},
    PAGE_ROWS => 10000,
    COLS_NAME => 1
  });
  foreach my $activated_channel (@{$activated_user_channels_list}) {
    $activated_user_channels->{ $activated_channel->{channel_id} } = $activated_channel->{changed};
  }

  if (!$attr->{IDS} || ref $attr->{IDS} ne 'ARRAY') {
    $attr->{IDS} = split(/,\s?/, $attr->{IDS} || '');
  }

  my %available_channels = map { $_ => 1 } @{$attr->{IDS}};
  my @channels_to_add = ();

  foreach my $channel_id (keys %$activated_user_channels) {
    if (delete $available_channels{$channel_id}) {
      push @channels_to_add, $channel_id;
    }
  }

  my $intervals = $Tariffs->ti_list({ TP_ID => $user_service_info->{TP_ID}, COLS_NAME => 1 });
  if (!$Tariffs->{TOTAL} || $Tariffs->{TOTAL} < 1) {
    return [];
  }

  my @remaining_ids = keys %available_channels;
  if (@remaining_ids) {
    my $affordable_channels = $self->_get_affordable_channels(\@remaining_ids, $intervals->[0]{id}, $user_info);
    if (ref($affordable_channels) eq 'HASH' && $affordable_channels->{errno}) {
      return $affordable_channels;
    }

    $self->_process_channel_fees($affordable_channels, $intervals->[0]{id}, $user_service_info, $user_info);

    push @channels_to_add, @$affordable_channels;
  }

  return \@channels_to_add;
}

#**********************************************************
=head2 _process_channel_fees($affordable_channels, $interval_id, $user_service_info, $user_info) - Calculate fees for selected channels

  Arguments:
    $affordable_channels  - Arrayref of channel IDs that user can afford
    $interval_id          - User tariff interval ID
    $user_service_info    - Hashref with user service details (TP_ID, PERIOD_ALIGNMENT, ABON_DISTRIBUTION, REDUCTION_FEE)
    $user_info            - Hashref with user details (CREDIT, DEPOSIT, etc.)

  Returns:
    HASHREF - {} on success, throws error on failure (e.g., { errno, errstr })

  Example:
    my $result = $self->_process_channel_fees(
      [101, 102, 103],
      $interval_id,
      $user_service_info,
      $user_info
    );

=cut
#**********************************************************
sub _process_channel_fees {
  my ($self, $affordable_channels, $interval_id, $user_service_info, $user_info) = @_;

  my $channel_list = $Iptv->channel_ti_list({
    DISABLE          => 0,
    USER_INTERVAL_ID => $interval_id,
    IDS              => join('; ', @$affordable_channels),
    COLS_NAME        => 1
  });

  if (!$channel_list || ref($channel_list) ne 'ARRAY') {
    return $Errors->throw_error(1080012);
  }
  $Iptv->{FEES}{CHANNELS} //= {};

  foreach my $channel (@$channel_list) {
    $Iptv->{TP_INFO} = {
      PERIOD_ALIGNMENT    => $user_service_info->{PERIOD_ALIGNMENT} || 0,
      MONTH_FEE           => $channel->{month_price},
      DAY_FEE             => $channel->{day_price},
      NAME                => $channel->{name} || '',
      TP_ID               => $user_service_info->{TP_ID},
      ABON_DISTRIBUTION   => $user_service_info->{ABON_DISTRIBUTION},
      REDUCTION_FEE       => $user_service_info->{REDUCTION_FEE},
      INTERVAL_CHANNEL_ID => $channel->{interval_channel_id},
    };
    if ($Iptv->{TP_INFO}->{MONTH_FEE} && $Iptv->{TP_INFO}->{MONTH_FEE} > 0) {
      my $fees_result = ::service_get_month_fee($Iptv, {
        EXT_DESCRIBE               => " $self->{lang}{CHANNEL}: $Iptv->{TP_INFO}->{INTERVAL_CHANNEL_ID}",
        SERVICE_NAME               => $self->{lang}{TV},
        DO_NOT_USE_GLOBAL_USER_PLS => 1,
        MODULE                     => 'Iptv',
        QUITE                      => 1
      });

      if ($self->{ENABLE_FEES_MESSAGES}) {
        $Iptv->{FEES}{CHANNELS}{$channel->{channel_id}} = $fees_result;
      }
    }
    elsif ($Iptv->{TP_INFO}->{DAY_FEE} && $Iptv->{TP_INFO}->{DAY_FEE} > 0) {
      my %PARAMS = (
        DESCRIBE => "$self->{lang}{TV}: $self->{lang}{DAY_FEE}",
        METHOD   => 1
      );
      $Fees->take($user_info, $Iptv->{TP_INFO}->{DAY_FEE}, { %PARAMS });

      if ($self->{ENABLE_FEES_MESSAGES}) {
        $Iptv->{FEES}{CHANNELS}{$channel->{channel_id}} = {
          DAY_FEE  => $Iptv->{TP_INFO}->{DAY_FEE},
          FEES_DSC => {
            FEES_PERIOD_DAY => $self->{lang}{DAY_FEE_SHORT},
            ID              => $user_service_info->{ID},
            MODULE          => 'Iptv',
            SERVICE_NAME    => $self->{lang}{TV},
            TP_ID           => $user_service_info->{TP_ID},
            TP_NAME         => $channel->{name}
          }
        };
      }
    }
  }

  return {};
}

#**********************************************************
=head2 _process_screen_fees($attr, $user_service_info) - Calculate monthly fees for user screens

  Arguments:
    $attr               - Hashref with parameters (e.g., TP_ID, additional filters)
    $user_service_info  - Hashref with user service details (TP_ID, PERIOD_ALIGNMENT, ABON_DISTRIBUTION, REDUCTION_FEE)

  Returns:
    HASHREF - {} on success, throws error on failure (e.g., { errno, errstr })

  Example:
    my $result = $self->_process_screen_fees(
      { TP_ID => 101 },
      $user_service_info
    );

=cut
#**********************************************************
sub _process_screen_fees {
  my ($self, $attr, $user_service_info) = @_;

  my $user_screens = $Iptv->users_screens_list({
    LOGIN            => '_SHOW',
    LOGIN_STATUS     => 0,
    SERVICE_TP_ID    => $attr->{TP_ID},
    # MONTH_FEE        => '>0',
    NUM              => '_SHOW',
    NAME             => '_SHOW',
    FILTER_ID        => '_SHOW',
    REDUCTION        => '_SHOW',
    TP_REDUCTION_FEE => '_SHOW',
    COLS_NAME        => 1,
    %{$attr},
    SORT             => 's.num'
  });

  if (!$user_screens || ref($user_screens) ne 'ARRAY') {
    return $Errors->throw_error(1080013);
  }
  $Iptv->{FEES}{SCREENS} //= {};

  foreach my $screen (@{$user_screens}) {
    $Iptv->{TP_INFO} = {
      PERIOD_ALIGNMENT    => $user_service_info->{PERIOD_ALIGNMENT} || 0,
      MONTH_FEE           => $screen->{month_fee},
      NAME                => $screen->{name} || '',
      TP_ID               => $user_service_info->{TP_ID},
      ABON_DISTRIBUTION   => $user_service_info->{ABON_DISTRIBUTION},
      REDUCTION_FEE       => $user_service_info->{REDUCTION_FEE}
    };
    next if (!$Iptv->{TP_INFO}->{MONTH_FEE} || $Iptv->{TP_INFO}->{MONTH_FEE} <= 0);

    my $fees_result = ::service_get_month_fee($Iptv, {
      EXT_DESCRIBE               => " $self->{lang}{SCREEN}: $screen->{screen_id}",
      SERVICE_NAME               => $self->{lang}{TV},
      DO_NOT_USE_GLOBAL_USER_PLS => 1,
      MODULE                     => 'Iptv',
      QUITE                      => 1
    });

    if ($self->{ENABLE_FEES_MESSAGES}) {
      $Iptv->{FEES}{SCREENS}{$screen->{screen_id}} = $fees_result;
    }
  }

  return {};
}

#**********************************************************
=head2 _service_get_abon_date($attr) - Calculate subscription start date for a service

  Arguments:
    $attr - Hashref containing:
      SERVICE    => Hashref with service info (MONTH_ABON, STATUS, ACTIVATE, POSTPAID_ABON, PAYMENT_TYPE)
      USER_INFO  => Hashref with user info (DEPOSIT, CREDIT, DISABLE)

  Returns:
    STRING - Subscription start date in format 'YYYY-MM-DD', or empty string if conditions not met.

  Example:
    my $abon_date = $self->_service_get_abon_date({
      SERVICE   => $service_info,
      USER_INFO => $user_info
    });


=cut
#**********************************************************
sub _service_get_abon_date {
  my $self = shift;
  my ($attr) = @_;

  my $Service = $attr->{SERVICE};
  my $user_info = $attr->{USER_INFO};

  my $abon_date = '';

  if (
    ($Service->{MONTH_ABON} && $Service->{MONTH_ABON} > 0)
      && !$Service->{STATUS}
      && !$user_info->{DISABLE}
      && (($user_info->{DEPOSIT} ? $user_info->{DEPOSIT} : 0) + ($user_info->{CREDIT} ? $user_info->{CREDIT} : 0) > 0
      || $Service->{POSTPAID_ABON}
      || ($Service->{PAYMENT_TYPE} && $Service->{PAYMENT_TYPE} == 1))
  ) {
    if ($Service->{ACTIVATE} ne '0000-00-00') {
      my ($Y, $M, $D) = split('-', $Service->{ACTIVATE}, 3);
      $M--;
      $abon_date = POSIX::strftime("%Y-%m-%d", localtime((POSIX::mktime(0, 0, 0, $D, $M, ($Y - 1900), 0, 0, 0) + 31 * 86400 +
        (($self->{conf}->{START_PERIOD_DAY}) ? $self->{conf}->{START_PERIOD_DAY} * 86400 : 0))));
    }
    else {
      my ($Y, $M, $D) = split('-', $main::DATE, 3);
      $M++;
      if ($M == 13) {
        $M = 1;
        $Y++;
      }

      if ($self->{conf}->{START_PERIOD_DAY}) {
        $D = $self->{conf}->{START_PERIOD_DAY};
      }
      else {
        $D = '01';
      }
      $abon_date = sprintf("%d-%02d-%02d", $Y, $M, $D);
    }
  }

  return $abon_date;
}

#**********************************************************
=head2 _activate_user_channels($attr, $user_service_info, $user_info) - Activate user channels

  Arguments:
    $attr               => Hashref with additional parameters (e.g., BUNDLE_TYPE)
    $user_service_info  => Hashref with user service info (ID, TP_ID, etc.)
    $user_info          => Hashref with user account info (CREDIT, DEPOSIT, REDUCTION, etc.)

  Returns:
    undef or hashref with error (errno, errstr) on failure.

  Example:
    my $result = $self->_activate_user_channels($attr, $user_service_info, $user_info);

=cut
#**********************************************************
sub _activate_user_channels {
  my ($self, $attr, $user_service_info, $user_info) = @_;

  my $intervals = $Tariffs->ti_list({ TP_ID => $user_service_info->{TP_ID}, COLS_NAME => 1 });
  if (!$Tariffs->{TOTAL} || $Tariffs->{TOTAL} < 1) {
    return $Errors->throw_error(1080012);
  }

  my $activated_user_channels = {};
  my $activated_user_channels_list = $Iptv->user_channels_list({
    TP_ID     => $user_service_info->{TP_ID},
    ID        => $user_service_info->{ID},
    PAGE_ROWS => 10000,
    COLS_NAME => 1
  });
  foreach my $activated_channel (@{$activated_user_channels_list}) {
    $activated_user_channels->{ $activated_channel->{channel_id} } = $activated_channel->{changed};
  }

  my $mandatory_channels = $self->_get_mandatory_channels($user_service_info->{TP_ID});

  my $channels = [ keys(%{$activated_user_channels}), keys(%{$mandatory_channels}) ];

  my $affordable_channels = $self->_get_affordable_channels($channels, $intervals->[0]{id}, $user_info);
  if (ref($affordable_channels) eq 'HASH' && $affordable_channels->{errno}) {
    return $affordable_channels;
  }

  my $fee_result = $self->_process_channel_fees($affordable_channels, $intervals->[0]{id}, $user_service_info, $user_info);
  if (ref($fee_result) eq 'HASH' && $fee_result->{errno}) {
    return $fee_result;
  }

  $attr->{BUNDLE_TYPE} = 'subs_renew';
  my $service_result = $self->_execute_service_channel_changes($user_service_info, $user_info, $affordable_channels, $attr);
  if (ref($service_result) eq 'HASH' && $service_result->{errno}) {
    return $service_result;
  }

  return $service_result;
}

#**********************************************************
=head2 _activate_user_screens($tv_service, $attr, $user_service_info, $user_info) - Activate user screens

  Arguments:
    $tv_service         => Tv service object
    $attr               => Hashref with additional parameters (e.g., BUNDLE_TYPE, CID)
    $user_service_info  => Hashref with user service info (ID, TP_ID, SERVICE_ID, SUBSCRIBE_ID, etc.)
    $user_info          => Hashref with user account info (LOGIN, PASSWORD, DEPOSIT, etc.)

  Returns:
    undef or hashref with error (errno, errstr) on failure for individual screens.

  Example:
    $self->_activate_user_screens($attr, $tv_service, $user_service_info, $user_info);

=cut
#**********************************************************
sub _activate_user_screens {
  my ($self, $tv_service, $attr, $user_service_info, $user_info) = @_;

  my $user_screens = $Iptv->users_screens_list({
    LOGIN            => '_SHOW',
    LOGIN_STATUS     => 0,
    SERVICE_TP_ID    => $user_service_info->{TP_ID},
    MONTH_FEE        => '_SHOW',
    NUM              => '_SHOW',
    NAME             => '_SHOW',
    FILTER_ID        => '_SHOW',
    REDUCTION        => '_SHOW',
    TP_REDUCTION_FEE => '_SHOW',
    SCREEN_ID        => '_SHOW',
    COLS_NAME        => 1,
    COLS_UPPER       => 1,
    SORT             => 's.num'
  });

  if (!$Iptv->{TOTAL} || $Iptv->{TOTAL} < 1) {
    return $Errors->throw_error(1080013);
  }

  foreach my $screen (@{$user_screens}) {
    my $fee_result = $self->_process_screen_fees({
      TP_ID     => $user_service_info->{TP_ID},
      SCREEN_ID => $screen->{screen_id},
    }, $user_service_info);

    if (ref($fee_result) eq 'HASH' && $fee_result->{errno}) {
      next;
    }

    if (!$tv_service) {
      next;
    }

    if (!$tv_service->can('user_screens')) {
      next;
    }

    my %params = (%{$attr}, %{$screen},
      BUNDLE_TYPE => $attr->{BUNDLE_TYPE} || ($attr->{CID} ? 'subs_free_device' : undef) || 'subs_no_device'
    );

    $params{SUBSCRIBE_ID} = $user_service_info->{SUBSCRIBE_ID} if $user_service_info->{SUBSCRIBE_ID};
    $params{LOGIN} = $user_info->{LOGIN};
    $params{PASSWORD} = $user_info->{PASSWORD};
    $params{DEPOSIT} = $user_info->{DEPOSIT};

    $tv_service->user_screens(\%params);
  }
}

#**********************************************************
=head2 _handle_scheduled_tariff_change($attr, $user_service_info) - Schedule a future tariff change

  Arguments:
    $attr               => Hashref with parameters:
                            ID        => user service ID
                            TP_ID     => new tariff plan ID
                            UID       => user UID
                            PERIOD    => 1 for next abon date, >1 for specific date
                            DATE      => optional, in YYYY-MM-DD format for custom period
                            GET_ABON  => optional flag
                            RECALCULATE => optional flag
    $user_service_info  => Hashref with current user service information (ABON_DATE, TP_ID, TP_NAME, etc.)

  Returns:
    Shedule object on success
    Throws error via $Errors->throw_error on invalid input or scheduling failure

  Example:
    my $Shedule = $self->_handle_scheduled_tariff_change(
      { ID => 123, TP_ID => 45, UID => 678, PERIOD => 2, DATE => '2025-09-01' },
      $user_service_info
    );

=cut
#**********************************************************
sub _handle_scheduled_tariff_change {
  my ($self, $attr, $user_service_info) = @_;

  my $period = $attr->{PERIOD} || $attr->{period} || 0;

  if ($period <= 0) {
    return undef;
  }

  my ($year, $month, $day) = split('-', $main::DATE, 3);

  if ($period == 1) {
    ($year, $month, $day) = split('-', $user_service_info->{ABON_DATE}, 3);
  } else {
    if (!$attr->{DATE}) {
      return $Errors->throw_error(1080004, { lang_vars => { FIELD => 'date' } });
    }

    ($year, $month, $day) = split('-', $attr->{DATE}, 3);

    if (!$year || !$month || !$day) {
      return $Errors->throw_error(1080004, { lang_vars => { FIELD => 'date' } });
    }
  }

  my $selected_date_time = POSIX::mktime(0, 0, 0, $day, ($month - 1), ($year - 1900));

  if ($selected_date_time <= time()) {
    return $Errors->throw_error(580008);
  }

  require Shedule;
  Shedule->import();
  my $Shedule = Shedule->new($self->{db}, $self->{admin});

  my $comment = "$self->{lang}{FROM}: $user_service_info->{TP_ID}";
  if ($user_service_info->{TP_NAME}) {
    $comment .= ": $user_service_info->{TP_NAME}";
  }
  if (!$attr->{GET_ABON}) {
    $comment .= "\nGET_ABON=-1";
  }
  if (!$attr->{RECALCULATE}) {
    $comment .= "\nRECALCULATE=-1";
  }

  $Shedule->add({
    UID          => $attr->{UID},
    TYPE         => 'tp',
    ACTION       => "$attr->{ID}:$attr->{TP_ID}",
    D            => $day,
    M            => $month,
    Y            => $year,
    COMMENTS     => $comment,
    ADMIN_ACTION => 1,
    MODULE       => 'Iptv'
  });

  if ($Shedule->{errno}) {
    return {
      errno  => $Shedule->{errno},
      errstr => $Shedule->{errstr}
    }
  }

  return $Shedule;
}

#**********************************************************
=head2 _handle_button_actions($tv_service, $attr, $user_service_info) - Handle user button actions

  Arguments:
    $tv_service         => IPTV service object
    $attr               => Hashref with user input and button flags
    $user_service_info  => Hashref with user service information
    $self->{USER_PORTAL} => Optional flag to switch button config

  Returns:
    Hashref describing the action:
      { type => ACTION_REDIRECT, url => $url }
      { type => ACTION_TEMPLATE, template => $template }
      { type => ACTION_MESSAGE, message => $msg, level => 'info' }
    undef if no button action was applicable

  Example:
    my $action = $self->_handle_button_actions($tv_service, { get_code => 1 }, $user_service_info);

    if ($action->{type} eq ACTION_REDIRECT) {
        print "Redirect user to: $action->{url}\n";
    } elsif ($action->{type} eq ACTION_MESSAGE) {
        print "Show message: $action->{message}\n";
    }

=cut
#**********************************************************
sub _handle_button_actions {
  my ($self, $tv_service, $attr, $user_service_info) = @_;

  my $buttons_hash = $self->{USER_PORTAL} ? $USER_PORTAL_BUTTON_CONFIG : $BUTTON_CONFIG;

  foreach my $button_name (keys %{$buttons_hash}) {
    if (!$attr->{$button_name} || !$tv_service || !$tv_service->can($button_name)) {
      next;
    }

    my $result = $tv_service->$button_name({
      %{$attr}, %{$user_service_info}, %{$Users}
    });

    if (ref $result eq 'HASH' && $result->{result}) {
      my $data = $result->{result};

      return { type => ACTION_REDIRECT, url => $data->{web_url} } if $data->{web_url};
      return { type => ACTION_TEMPLATE, template => $data->{template} } if $data->{template};
      return { type => ACTION_MESSAGE, message => $data->{message}, level => 'info' } if $data->{message};
    }

    return { type => ACTION_MESSAGE, message => $result, level => 'info' } if $result;

    return;
  }

  return;
}

#**********************************************************
=head2 _prepare_fees_messages($fees, $tp_info) - Format fees into readable messages

  Arguments:
    $fees   => Hashref containing fee information (ACTIVATE, MONTH_FEE, CHANNELS, SCREENS)
    $tp_info => Hashref with tariff plan info (TP_ID, NAME)

  Returns:
    Arrayref of formatted fee messages as strings.
    Returns [] if $fees is not provided or is not a hashref.

  Example:
    my $messages = $self->_prepare_fees_messages($Iptv->{FEES}, $Iptv->{TP_INFO});

=cut
#**********************************************************
sub _prepare_fees_messages {
  my ($self, $fees, $tp_info) = @_;

  return [] if !$fees || ref $fees ne 'HASH';

  my $messages = [];

  $self->{lang}{TV} //= 'Television';
  $self->{lang}{SUM} //= 'Sum';

  if ($fees->{ACTIVATE} && $fees->{ACTIVATE} > 0) {
    my $activation_msg = $self->_format_fee_message({
      SERVICE_NAME => $self->{lang}{TV},
      TP_ID        => $tp_info->{TP_ID},
      TP_NAME      => $tp_info->{NAME},
      EXTRA        => $self->{lang}{ACTIVATE_TARIF_PLAN}
    });

    push @{$messages}, $activation_msg . "\n$self->{lang}{SUM}: " . sprintf("%.2f", $fees->{ACTIVATE});
  }

  if ($fees->{MONTH_FEE} && $fees->{MONTH_FEE} > 0) {
    my $fee_description = $fees->{FEES_DSC};

    if (!$fee_description || ref $fee_description ne 'HASH') {
      $fee_description = {
        SERVICE_NAME      => $self->{lang}{TV},
        TP_ID             => $tp_info->{TP_ID},
        TP_NAME           => $tp_info->{NAME},
        FEES_PERIOD_MONTH => $self->{lang}{MONTH_FEE_SHORT}
      };
    }

    my $monthly_msg = $self->_format_fee_message($fee_description);
    push @{$messages}, $monthly_msg . "\n$self->{lang}{SUM}: " . sprintf("%.2f", $fees->{MONTH_FEE});
  }

  if ($fees->{CHANNELS} && ref $fees->{CHANNELS} eq 'HASH') {
    foreach my $channel_id (keys %{$fees->{CHANNELS}}) {
      next if (ref $fees->{CHANNELS}{$channel_id} ne 'HASH');

      my $fee_description = $fees->{CHANNELS}{$channel_id}{FEES_DSC};
      next if !$fee_description;

      my $fee_msg = $self->_format_fee_message($fee_description);
      my $price = $fees->{CHANNELS}{$channel_id}{MONTH_FEE} || $fees->{CHANNELS}{$channel_id}{DAY_FEE};
      if (!$price || $price < 0) {
        next;
      }
      push @{$messages}, $fee_msg . "\n$self->{lang}{CHANNEL}: $channel_id" .
        "\n$self->{lang}{SUM}: " . sprintf("%.2f", $price);
    }
  }

  if ($fees->{SCREENS} && ref $fees->{SCREENS} eq 'HASH') {
    foreach my $screen_id (keys %{$fees->{SCREENS}}) {
      next if (ref $fees->{SCREENS}{$screen_id} ne 'HASH');

      my $fee_description = $fees->{SCREENS}{$screen_id}{FEES_DSC};
      next if !$fee_description;

      my $fee_msg = $self->_format_fee_message($fee_description);
      my $price = $fees->{SCREENS}{$screen_id}{MONTH_FEE} || $fees->{SCREENS}{$screen_id}{DAY_FEE};
      if (!$price || $price < 0) {
        next;
      }
      push @{$messages}, $fee_msg . "\n$self->{lang}{SCREEN}: $screen_id" .
        "\n$self->{lang}{SUM}: " . sprintf("%.2f", $price);
    }
  }


  return $messages;
}

#**********************************************************
=head2 _format_fee_message($attr) - Generate formatted fee message

  Arguments:
    $attr => Hashref with keys:
      SERVICE_NAME => Name of the service (default 'Television')
      TP_ID        => Tariff plan ID
      TP_NAME      => Tariff plan name
      ID           => Optional user/service ID
      EXTRA        => Extra description
      PERIOD       => Optional period info
      FEES_PERIOD_MONTH => Monthly fee label
      FEES_PERIOD_DAY   => Daily fee label

  Returns:
    Formatted string with placeholders replaced by values from $attr.

  Example:
    my $msg = $self->_format_fee_message({
        SERVICE_NAME      => 'TV',
        TP_ID             => 123,
        TP_NAME           => 'Premium Pack',
        ID                => 456,
        EXTRA             => 'Activation',
        FEES_PERIOD_MONTH => 'Month',
        FEES_PERIOD_DAY   => 'Day',
    });

=cut
#**********************************************************
sub _format_fee_message {
  my ($self, $attr) = @_;

  $attr->{SERVICE_NAME} //= 'Television';

  my $text = '%SERVICE_NAME%: %FEES_PERIOD_MONTH%%FEES_PERIOD_DAY% %TP_NAME% (%TP_ID%)%ID% %EXTRA%%PERIOD%';

  while ($text =~ /\%(\w+)\%/xg) {
    my $var = $1;
    $attr->{$var} //= '';
    $text =~ s/\%$var\%/$attr->{$var}/xg;
  }

  return $text;
}

#**********************************************************
=head2 _format_additional_tables($info) - Format additional info tables

  Arguments:
    $info => Hashref containing:
      info_tables => Arrayref of tables, each with keys:
        table      => Table identifier or name
        titles     => Optional hashref of column titles
        data_hash  => Arrayref of row data (mandatory)
        buttons    => Optional button definitions

  Returns:
    Hashref with key 'tables' containing an arrayref of formatted tables.
    Each table includes:
      table   => Table identifier
      titles  => Column titles (or empty hashref)
      data    => Row data
      buttons => Formatted buttons (from _format_table_buttons)

  Example:
    my $info = {
        info_tables => [
            {
                table     => 'users',
                titles    => { id => 'ID', name => 'Name' },
                data_hash => [ { id => 1, name => 'Alice' }, { id => 2, name => 'Bob' } ],
                buttons   => [ { name => 'edit' }, { name => 'delete' } ]
            }
        ]
    };

    my $formatted = $self->_format_additional_tables($info);
    # $formatted will be:
    # {
    #   tables => [
    #     {
    #       table   => 'users',
    #       titles  => { id => 'ID', name => 'Name' },
    #       data    => [ { id => 1, name => 'Alice' }, { id => 2, name => 'Bob' } ],
    #       buttons => [ ...formatted buttons... ]
    #     }
    #   ]
    # }

=cut
#**********************************************************
sub _format_additional_tables {
  my ($self, $info) = @_;

  if (!$info->{info_tables} || ref $info->{info_tables} ne 'ARRAY') {
    return {};
  }

  my @formatted_tables;

  foreach my $table (@{$info->{info_tables}}) {
    if ($table->{data_hash} && ref $table->{data_hash} eq 'ARRAY' && $table->{table}) {
      my $formatted_table = {
        table   => $table->{table},
        titles  => $table->{titles} || {},
        data    => $table->{data_hash},
        buttons => $self->_format_table_buttons($table->{buttons})
      };

      push @formatted_tables, $formatted_table;
    }
  }

  return { tables => \@formatted_tables };
}

#**********************************************************
=head2 _format_table_buttons($buttons) - Format table buttons

  Arguments:
    $buttons => Arrayref of button rows, where each row is an arrayref of buttons.
      Each button is a hashref with keys like:
        title  => Button label
        url    => Optional URL for action
        ...    => Any additional params

  Returns:
    Arrayref of formatted button rows. Each button is converted into a hashref with:
      title  => Button label
      url    => Button URL
      params => Original button hashref

=cut
#**********************************************************
sub _format_table_buttons {
  my ($self, $buttons) = @_;

  if (!$buttons || ref $buttons ne 'ARRAY') {
    return [];
  }

  my @formatted_buttons;

  for my $row_idx (0 .. $#{$buttons}) {
    my $row_buttons = $buttons->[$row_idx];
    if (ref $row_buttons ne 'ARRAY') {
      next;
    }

    my @row_formatted_buttons;
    for my $btn_idx (0 .. $#{$row_buttons}) {
      my $button = $row_buttons->[$btn_idx];
      if (ref $button ne 'HASH') {
        last;
      }

      push @row_formatted_buttons, {
        title  => $button->{title},
        url    => $button->{url},
        params => $button
      };
    }
    $formatted_buttons[$row_idx] = \@row_formatted_buttons;
  }

  return \@formatted_buttons;
}

#**********************************************************
=head2 _check_user_tariff_activation($tp_id, $user_info) - Check if user can activate tariff

  Arguments:
    $tp_id     => Tariff plan ID
    $user_info => Hashref with user information, including keys:
                   UID, CREDIT, DEPOSIT, REDUCTION, PAYMENT_TYPE, etc.

  Returns:
    undef - if activation is possible
    Throws error (1080010) via $Errors->throw_error if funds are insufficient.

  Example:
    $self->_check_user_tariff_activation(12345, {
      UID       => 67890,
      CREDIT    => 50.00,
      DEPOSIT   => 10.00,
      REDUCTION => 20,
      PAYMENT_TYPE => 0
    });

=cut
#**********************************************************
sub _check_user_tariff_activation {
  my ($self, $tp_id, $user_info) = @_;

  my $tariff_info = $Tariffs->info($tp_id);

  my $available_credit = $user_info->{CREDIT} // 0;
  if ($available_credit <= 0) {
    $available_credit = $tariff_info->{CREDIT} // 0;
  }
  $user_info->{CREDIT} = $available_credit;
  $user_info->{REDUCTION} = $tariff_info->{REDUCTION_FEE} ? $user_info->{REDUCTION} : 0;

  my $tariff_total_fee = ($tariff_info->{DAY_FEE} // 0) + ($tariff_info->{MONTH_FEE} // 0);

  if ($tariff_info->{REDUCTION_FEE} && $user_info->{REDUCTION}) {
    if ($user_info->{REDUCTION} < 100) {
      $tariff_total_fee = $tariff_total_fee * ((100 - $user_info->{REDUCTION}) / 100);
    }
    else {
      $tariff_total_fee = 0;
    }
  }

  my $total_available_funds = ($user_info->{DEPOSIT} // 0) + $available_credit;
  my $payment_required = !$tariff_info->{PAYMENT_TYPE} && !$tariff_info->{ABON_DISTRIBUTION};

  my %users_services_channels = ();
  my %users_services_screens = ();

  require Iptv::Base;
  my $Iptv_base = Iptv::Base->new($self->{db}, $self->{admin}, $self->{conf}, { LANG => $self->{lang} });

  $Iptv_base->iptv_channels_fees({
    UID              => $user_info->{UID},
    TP_ID            => $tariff_info->{TP_ID},
    TP               => $tariff_info,
    SKIP_MONTH_PRICE => 1,
    USERS_SERVICES   => \%users_services_channels,
  });

  $Iptv_base->iptv_screen_fees({
    UID            => $user_info->{UID},
    TP_ID          => $tariff_info->{TP_ID},
    TP             => $tariff_info,
    USERS_SERVICES => \%users_services_screens,
  });

  $Tariffs->ti_list({ TP_ID => $tp_id, COLS_NAME => 1 });

  if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) {
    my $mandatory_channels_list = $Iptv->channel_ti_list({
      INTERVAL_ID => $Tariffs->{list}->[0]->{id},
      MANDATORY   => 1,
      FILTER_ID   => '_SHOW',
      COLS_NAME   => 1,
      COLS_UPPER  => 1
    });

    my $days_in_month = Abills::Base::days_in_month();
    foreach my $channel (@{$mandatory_channels_list}) {
      my $sum = $channel->{MONTH_PRICE};

      $sum = ($user_info->{REDUCTION} && $user_info->{REDUCTION} > 0) ? $sum * (100 - $user_info->{REDUCTION}) / 100 : $sum;
      $sum = sprintf("%.6f", $sum / $days_in_month) if ($tariff_info->{ABON_DISTRIBUTION});

      push @{$users_services_channels{ $user_info->{UID} }}, {
        SUM       => $sum,
        ID        => $channel->{CHANNEL_ID},
      };
    }
  }

  foreach my $screen (@{$users_services_screens{$user_info->{UID}}}) {
    next if !$screen->{SUM};
    $tariff_total_fee += $screen->{SUM};
  }

  foreach my $channel (@{$users_services_channels{$user_info->{UID}}}) {
    next if !$channel->{SUM};
    $tariff_total_fee += $channel->{SUM};
  }

  if ($tariff_total_fee > $total_available_funds && $payment_required) {
    return $Errors->throw_error(1080014);
  }

  return;
}

#**********************************************************
=head2 _check_subscription_limits($uid, $tp_id, $service_info) - Verify user's subscription limits

  Arguments:
    $uid          => User ID
    $tp_id        => Tariff plan ID
    $service_info => Hashref with service information, including keys:
      SERVICE_ID, SUBSCRIBE_COUNT, etc.

  Returns:
    undef - if subscription is allowed
    Throws error (1080006) if maximum subscriptions reached.
    Throws error (1080007) if unique tariff plan constraint violated.

  Example:
    $self->_check_subscription_limits(67890, 12345, {
      SERVICE_ID     => 101,
      SUBSCRIBE_COUNT => 3
    });

=cut
#**********************************************************
sub _check_subscription_limits {
  my ($self, $uid, $tp_id, $service_info) = @_;

  if ($service_info->{SUBSCRIBE_COUNT}) {
    $Iptv->user_list({
      SERVICE_ID => $service_info->{SERVICE_ID},
      UID        => $uid,
      COLS_NAME  => 1,
      PAGE_ROWS  => 99999,
    });

    if ($Iptv->{TOTAL} && $Iptv->{TOTAL} >= $service_info->{SUBSCRIBE_COUNT}) {
      return $Errors->throw_error(1080006);
    }
  }

  if ($self->{conf}{IPTV_USER_UNIQUE_TP}) {
    $Iptv->user_list({
      UID       => $uid,
      TP_ID     => $tp_id,
      COLS_NAME => 1
    });

    if ($Iptv->{TOTAL} && $Iptv->{TOTAL} > 0) {
      return $Errors->throw_error(1080007);
    }
  }

  return undef;
}

#**********************************************************
=head2 _build_service_buttons($tv_service) - Build service action buttons

  Arguments:
    $tv_service => Service object to check available actions.

  Returns:
    Hashref where keys are button names and values are button attributes.

  Example:
    my $buttons = $self->_build_service_buttons($tv_service);
    # $buttons->{activate} might contain:
    # {
    #   title         => 'Activate',
    #   class         => 'btn-primary',
    #   LOAD_TO_MODAL => 1,
    #   target        => '_self',
    #   BUTTON        => 1
    # }

=cut
#**********************************************************
sub _build_service_buttons {
  my ($self, $tv_service) = @_;

  my $buttons = {};
  my $buttons_hash = $self->{USER_PORTAL} ? $USER_PORTAL_BUTTON_CONFIG : $BUTTON_CONFIG;

  foreach my $button_name (keys %{$buttons_hash}) {
    next if !$tv_service->can($button_name);

    my $button = $buttons_hash->{$button_name};

    $buttons->{$button_name} = {
      title         => $self->{lang}{$button->{lang_key}} || $button->{fallback},
      class         => $button->{css_class},
      LOAD_TO_MODAL => $button->{modal} || 0,
      target        => $button->{target},
      BUTTON        => 1
    };
  }

  return $buttons;
}

1;