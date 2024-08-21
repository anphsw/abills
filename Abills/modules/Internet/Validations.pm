package Internet::Validations;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use Abills::Base qw(in_array);

our @EXPORT = qw(
  POST_INTERNET_HANGUP
  POST_INTERNET_TARIFF
  PUT_INTERNET_TARIFF
  POST_INTERNET_MAC_DISCOVERY
  POST_INTERNET_USER
  PUT_INTERNET_USER
);

our @EXPORT_OK = qw(
  POST_INTERNET_HANGUP
  POST_INTERNET_TARIFF
  PUT_INTERNET_TARIFF
  POST_INTERNET_MAC_DISCOVERY
  POST_INTERNET_USER
  PUT_INTERNET_USER
);

use constant {
  INTERNET_TARIFF => {
    PERIOD_ALIGNMENT        => {
      type => 'unsigned_integer'
    },
    ABON_DISTRIBUTION       => {
      type => 'unsigned_integer'
    },
    FIXED_FEES_DAY          => {
      type => 'unsigned_integer'
    },
    POSTPAID_MONTH_FEE      => {
      type => 'unsigned_integer'
    },
    ACTIVE_DAY_FEE          => {
      type => 'unsigned_integer'
    },
    POSTPAID_DAY_FEE        => {
      type => 'unsigned_integer'
    },
    STATUS                  => {
      type => 'unsigned_integer'
    },
    REDUCTION_FEE           => {
      type => 'unsigned_integer'
    },
    TOTAL_TIME_LIMIT        => {
      type => 'unsigned_integer'
    },
    NEG_DEPOSIT_FILTER_ID   => {},
    AGE                     => {
      type => 'unsigned_integer'
    },
    MONTH_FEE               => {
      type => 'unsigned_number'
    },
    CREDIT_TRESSHOLD        => {
      type => 'unsigned_number'
    },
    NEXT_TP_ID              => {
      type     => 'custom',
      function => \&check_tp,
    },
    SMALL_DEPOSIT_ACTION    => {
      type     => 'custom',
      function => \&check_tp,
    },
    DESCRIBE_AID            => {},
    PAYMENT_TYPE            => {
      type     => 'custom',
      function => \&check_payment_types
    },
    TRAFFIC_TRANSFER_PERIOD => {
      type => 'unsigned_integer'
    },
    DAY_FEE                 => {
      type => 'unsigned_number'
    },
    UPLIMIT                 => {
      type => 'unsigned_number'
    },
    ACTIVATE_PRICE          => {
      type => 'unsigned_number'
    },
    USER_CREDIT_LIMIT       => {
      type => 'unsigned_number'
    },
    PRIORITY                => {
      type => 'unsigned_integer'
    },
    TP_GID                  => {
      type     => 'custom',
      function => \&check_tp_gid
    },
    IPPOOL                  => {
      type     => 'custom',
      function => \&check_ip_pool
    },
    OCTETS_DIRECTION        => {
      type     => 'custom',
      function => \&check_octets
    },
    MIN_SESSION_COST        => {
      type => 'unsigned_number'
    },
    COMMENTS                => {},
    DAY_TIME_LIMIT          => {
      type => 'unsigned_integer'
    },
    WEEK_TRAF_LIMIT         => {
      type => 'unsigned_integer'
    },
    CHANGE_PRICE            => {
      type => 'unsigned_number'
    },
    TOTAL_TRAF_LIMIT        => {
      type => 'unsigned_integer'
    },
    MAX_SESSION_DURATION    => {
      type => 'unsigned_integer'
    },
    MONTH_TRAF_LIMIT        => {
      type => 'unsigned_integer'
    },
    CREDIT                  => {
      type => 'unsigned_number'
    },
    DAY_TRAF_LIMIT          => {
      type => 'unsigned_integer'
    },
    RAD_PAIRS               => {},
    LOGINS                  => {
      type => 'unsigned_integer'
    },
    FILTER_ID               => {},
    WEEK_TIME_LIMIT         => {
      type => 'unsigned_integer'
    },
    FINE                    => {
      type => 'unsigned_number'
    },
    NEG_DEPOSIT_IPPOOL      => {
      type     => 'custom',
      function => \&check_ip_pool,
    },
    MIN_USE                 => {
      type => 'unsigned_number'
    },
    MONTH_TIME_LIMIT        => {
      type => 'unsigned_integer'
    },
    CREATE_FEES_TYPE        => {
      type => 'unsigned_integer'
    },
    DOMAIN_ID               => {
      type => 'unsigned_integer'
    },
  },
  INTERNET_USER   => {
    STATUS           => {
      required => 1,
      type     => 'unsigned_integer',
    },
    CID              => {
      type => 'string',
    },
    IP               => {
      type => 'string',
    },
    PERSONAL_TP      => {
      type => 'unsigned_integer',
    },
    SERVICE_EXPIRE   => {
      type    => 'date',
      default => '0000-00-00'
    },
    SERVICE_ACTIVATE => {
      type    => 'date',
      default => '0000-00-00'
    },
    PORT             => {
      type => 'string',
    },
    COMMENTS         => {
      type => 'string',
    },
    CPE_MAC          => {
      type => 'string',
    },
    STATIC_IP_POOL   => {
      type => 'unsigned_integer',
    },
    SERVER_VLAN      => {
      type => 'unsigned_integer',
    },
    VLAN             => {
      type => 'unsigned_integer',
    },
    IPV6_MASK        => {
      type    => 'unsigned_integer',
      default => '32'
    },
    IPV6             => {
      type => 'string',
    },
    IPV6_PREFIX      => {
      type => 'unsigned_integer',
    },
    IPV6_PREFIX_MASK => {
      type    => 'unsigned_integer',
      default => '32'
    },
    STATIC_IPV6_POOL => {
      type    => 'unsigned_integer',
      default => '0'
    },
    # do we really need this param?
    STATUS_DAYS      => {
      type => 'string',
    },
  }
};

use constant {
  POST_INTERNET_HANGUP        => {
    NAS_ID          => {
      required => 1,
      type     => 'unsigned_integer'
    },
    NAS_PORT_ID     => {
      required => 1,
      type     => 'unsigned_integer'
    },
    USER_NAME       => {
      required => 1
    },
    ACCT_SESSION_ID => {
      required => 1
    },
  },
  POST_INTERNET_TARIFF        => {
    NAME        => {
      required => 1
    },
    ID          => {
      required => 1,
      type     => 'unsigned_integer'
    },
    FEES_METHOD => {
      type    => 'unsigned_integer',
      default => 1,
    },
    %{+INTERNET_TARIFF},
  },
  PUT_INTERNET_TARIFF         => {
    NAME        => {},
    ID          => {
      type => 'unsigned_integer'
    },
    FEES_METHOD => {
      type => 'unsigned_integer',
    },
    %{+INTERNET_TARIFF},
  },
  POST_INTERNET_MAC_DISCOVERY => {
    ID  => {
      required => 1,
      type     => 'unsigned_integer'
    },
    CID => {
      required => 1,
      type     => 'custom',
      function => \&check_mac,
    },
  },
  POST_INTERNET_USER          => {
    %{+INTERNET_USER},
    TP_ID => {
      required => 1,
      type     => 'custom',
      function => \&check_tp,
    },
  },
  PUT_INTERNET_USER           => {
    %{+INTERNET_USER},
    ID => {
      required => 1,
      type     => 'unsigned_integer',
    },
  },
};

#**********************************************************
=head2 check_ip_pool($validator, $value)

=cut
#**********************************************************
sub check_ip_pool {
  my ($validator, $value) = @_;
  return {
    errstr => 'Value is not valid',
    type   => 'unsigned_integer',
  } if ($value !~ /^[1-9]\d*$/);

  require Nas;
  Nas->import();
  my $Nas = Nas->new($validator->{db}, $validator->{conf}, $validator->{admin});
  $Nas->nas_ip_pools_list({ STATIC => 0, ID => $value || '--', COLS_NAME => 1 });

  if ($Nas->{TOTAL} && $Nas->{TOTAL} > 0) {
    return {
      result => 1,
    };
  }
  else {
    return {
      result => 0,
      errstr => "No IP pool with id $value",
      type   => 'unsigned_integer',
    };
  }
}

#**********************************************************
=head2 check_tp($validator, $value)

=cut
#**********************************************************
sub check_tp {
  my ($validator, $value) = @_;
  return {
    errstr => 'Value is not valid',
    type   => 'unsigned_integer',
  } if ($value !~ /^[1-9]\d*$/);

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($validator->{db}, $validator->{conf}, $validator->{admin});

  $Tariffs->list({
    NEW_MODEL_TP => 1,
    MODULE       => 'INTERNET',
    COLS_NAME    => 1,
    STATUS       => '0',
    TP_ID        => $value || '--',
  });

  if ($Tariffs->{TOTAL} && $Tariffs->{TOTAL} > 0) {
    return {
      result => 1,
    };
  }
  else {
    return {
      result => 0,
      errstr => "No tariff plan with tpId $value",
      type   => 'unsigned_integer',
    };
  }
}

#**********************************************************
=head2 check_octets($validator, $value)

=cut
#**********************************************************
sub check_octets {
  my ($validator, $value) = @_;

  my @allowed_octets = (0, 1, 2);

  if (in_array($value, \@allowed_octets)) {
    return {
      result => 1
    };
  }
  else {
    return {
      result         => 0,
      errstr         => 'Allowed values 1, 2, 3',
      type           => 'unsigned_integer',
      allowed_values => [
        {
          value       => 0,
          description => 'Received + send',
        },
        {
          value       => 1,
          description => 'Received',
        },
        {
          value       => 2,
          description => 'Send',
        },
      ]
    };
  }
}

#**********************************************************
=head2 check_tp_gid($validator, $value)

=cut
#**********************************************************
sub check_tp_gid {
  my ($validator, $value) = @_;

  return {
    errstr => 'Value is not valid',
    type   => 'unsigned_integer',
  } if ($value !~ /^[1-9]\d*$/);

  require Tariffs;
  Tariffs->import();
  my $Tariffs = Tariffs->new($validator->{db}, $validator->{conf}, $validator->{admin});
  my $tp_groups_list = $Tariffs->tp_group_list({ COLS_NAME => 1 });

  foreach my $group (@$tp_groups_list) {
    return { result => 1 } if ($group->{id} eq $value);
  }

  return {
    result => 0,
    errstr => "No tariff group with tpId $value",
    type   => 'unsigned_integer',
  };
}

#**********************************************************
=head2 check_payment_types($validator, $value)

=cut
#**********************************************************
sub check_payment_types {
  my ($validator, $value) = @_;

  my @allowed_types = (0, 1, 2);

  if (in_array($value, \@allowed_types)) {
    return {
      result => 1
    };
  }
  else {
    return {
      result         => 0,
      errstr         => 'Allowed values 1, 2, 3',
      type           => 'unsigned_integer',
      allowed_values => [
        {
          value       => 0,
          description => 'Prepaid',
        },
        {
          value       => 1,
          description => 'Postpaid',
        },
        {
          value       => 2,
          description => 'Guest',
        },
      ]
    };
  }
}

#**********************************************************
=head2 check_mac($validator, $value)

=cut
#**********************************************************
sub check_mac {
  my ($validator, $value) = @_;

  require Abills::Filters;
  Abills::Filters->import(qw($MAC));

  if ($value =~ /^$Abills::Filters::MAC$/) {
    return {
      result => 1
    };
  }
  else {
    return {
      errstr => 'Value is not valid',
      type   => 'mac',
      regex  => "^$Abills::Filters::MAC\$"
    };
  }
}

1;
