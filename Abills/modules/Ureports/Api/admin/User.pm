package Ureports::Api::admin::User;

=head1 NAME

  Ureports User

  Endpoints:
    /ureports/user/

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Abills::Sender::Core;

use Ureports;

my Ureports $Ureports;
my Control::Errors $Errors;

my %send_methods = %Abills::Sender::Core::PLUGIN_NAME_FOR_TYPE_ID;

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

  $Ureports = Ureports->new($db, $admin, $conf);
  $Ureports->{debug} = $self->{debug};

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_ureports_user_list($path_params, $query_params)

  Endpoint GET /ureports/user/list/

=cut
#**********************************************************
sub get_ureports_user_list {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $users = $Ureports->user_list({
    %$query_params,
    DESTINATION => '_SHOW',
    TYPE        => '_SHOW',
    COLS_NAME   => 1,
  });

  if ($users && scalar @{$users}) {
    foreach my $user (@{$users}) {
      my @types = split(',', ($user->{type} || ''));
      my @destination = split(',', ($user->{destination} || ''));
      delete $user->{type};
      $user->{destinations} = [];
      delete @{$user}{qw/destination type/};
      if (scalar @types) {
        for (my $i = 0; $i <= $#types; $i++) {
          push @{$user->{destinations}}, {
            type        => $types[$i],
            name        => $send_methods{$types[$i]},
            destination => $destination[$i],
          };
        }
      }
    }
  }

  return $users;
}

#**********************************************************
=head2 get_ureports_user_uid($path_params, $query_params)

  Endpoint GET /ureports/user/:uid/

=cut
#**********************************************************
sub get_ureports_user_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  my $user = $Ureports->user_list({
    UID            => $path_params->{uid},
    TP_ID          => '_SHOW',
    TP_NAME        => '_SHOW',
    DESTINATION    => '_SHOW',
    DESTINATION_ID => '_SHOW',
    TYPE           => '_SHOW',
    STATUS         => '_SHOW',
    REPORTS_COUNT  => '_SHOW',
    COLS_NAME      => 1,
  });

  if ($user && scalar @{$user}) {
    $user = $user->[0];
    my @types = split(',', ($user->{type} || ''));
    my @destination = split(',', ($user->{destination} || ''));
    $user->{destinations} = [];
    delete @{$user}{qw/destination type/};
    if (scalar @types) {
      for (my $i = 0; $i <= $#types; $i++) {
        push @{$user->{destinations}}, {
          type        => $types[$i],
          name        => $send_methods{$types[$i]},
          destination => $destination[$i],
        };
      }
    }
  }

  return $user;
}

#**********************************************************
=head2 post_ureports_user_uid($path_params, $query_params)

  Endpoint POST /ureports/user/:uid/

=cut
#**********************************************************
sub post_ureports_user_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  return $Errors->throw_error(1210001) if !$query_params->{TP_ID};

  return $Errors->throw_error(1210002) if !defined $query_params->{DESTINATIONS};

  return $Errors->throw_error(1210003) if ref $query_params->{DESTINATIONS} ne 'ARRAY';

  my $list = $Ureports->user_list({
    UID       => $path_params->{uid},
    COLS_NAME => 1,
  });

  return $Errors->throw_error(1210004) if ($list && scalar @{$list});

  my %destinations = (
    TYPE => '',
  );

  foreach my $destination (@{$query_params->{DESTINATIONS}}) {
    next if (ref $destination ne 'HASH');
    next if (!$destination->{ID});
    $destinations{TYPE} .= "$destination->{ID},";
    $destinations{'DESTINATION_' . $destination->{ID}} = $destination->{VALUE} || 0;
  }

  $Ureports->user_add({
    %{$query_params || {}},
    %destinations,
    UID => $path_params->{uid},
  });

  $Ureports->user_info($path_params->{uid});

  my %destinations_ = $Ureports->{DESTINATIONS} ? split /[|,]/, $Ureports->{DESTINATIONS} : ();
  my $destinations;

  foreach my $dest (keys %destinations_) {
    push @{$destinations}, {
      id    => $dest,
      value => $destinations_{$dest},
    };
  }

  $Ureports->{DESTINATIONS} = $destinations;
  delete @{$Ureports}{qw/list AFFECTED TOTAL TP_INFO TYPES/};
  return $Ureports;
}

#**********************************************************
=head2 put_ureports_user_uid($path_params, $query_params)

  Endpoint PUT /ureports/user/list/

=cut
#**********************************************************
sub put_ureports_user_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  return $Errors->throw_error(1210005) if $query_params->{DESTINATIONS} && ref $query_params->{DESTINATIONS} ne 'ARRAY';

  my %destinations = ();

  if ($query_params->{DESTINATIONS}) {
    $destinations{TYPE} = '';

    foreach my $destination (@{$query_params->{DESTINATIONS}}) {
      next if (ref $destination ne 'HASH');
      next if (!$destination->{ID});
      $destinations{TYPE} .= "$destination->{ID},";
      $destinations{'DESTINATION_' . $destination->{ID}} = $destination->{VALUE} || 0;
    }
  }
  else {
    $query_params->{SKIP_ADD_SEND_TYPES} = 1;
  }

  $Ureports->user_change({
    %{$query_params || {}},
    %destinations,
    UID => $path_params->{uid},
  });

  $Ureports->user_info($path_params->{uid});

  my %destinations_ = $Ureports->{DESTINATIONS} ? split /[|,]/, $Ureports->{DESTINATIONS} : ();
  my $destinations;

  foreach my $dest (keys %destinations_) {
    push @{$destinations}, {
      id    => $dest,
      value => $destinations_{$dest},
    };
  }

  $Ureports->{DESTINATIONS} = $destinations;
  delete @{$Ureports}{qw/list AFFECTED TOTAL TYPES/};
  return $Ureports;
}

#**********************************************************
=head2 delete_ureports_user_uid($path_params, $query_params)

  Endpoint DELETE /ureports/user/:uid/

=cut
#**********************************************************
sub delete_ureports_user_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  $Ureports->{UID} = $path_params->{uid};
  $Ureports->user_del({ UID => $path_params->{uid} });

  if (!$Ureports->{errno}) {
    if ($Ureports->{AFFECTED} && $Ureports->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return $Errors->throw_error(1210006);
    }
  }

  return $Ureports;
}

#**********************************************************
=head2 get_ureports_user_uid_reports($path_params, $query_params)

  Endpoint GET /ureports/user/:uid/reports/

=cut
#**********************************************************
sub get_ureports_user_uid_reports {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  my $active_reports = $Ureports->tp_user_reports_list({
    UID       => $path_params->{uid},
    REPORT_ID => '_SHOW',
    COLS_NAME => 1
  });

  if ($active_reports && !scalar @{$active_reports}) {
    return $Errors->throw_error(1210007);
  }

  my %report_names = (
    '1'  => 'Deposit below',
    '2'  => 'Deposit + Credit Below',
    '3'  => 'Prepaid Traffic Below',
    '4'  => 'Day: Traffic more then',
    '5'  => 'Month: Deposit + Credit + Traffic',
    '6'  => 'Day: Deposit + Credit + Traffic',
    '7'  => 'Credit Expired',
    '8'  => 'Login Disable ',
    '9'  => 'Internet: Days To Expire',
    '10' => 'Too small deposit for next month',
    '11' => 'Too small deposit for next month v2',
    '12' => 'Payments information',
    '13' => 'All Service expired through XX days',
    '14' => 'Send deposit before user payment',
    '15' => 'Internet Service disabled',
    '16' => 'Next period tariff plan',
    '17' => 'Happy Birthday',
  );

  my %user_reports = (
    active_reports    => [],
    available_reports => [],
  );

  foreach my $report (@{$active_reports}) {
    $report->{report_name} = $report_names{$report->{report_id}} || '';

    $report->{uid} ? push @{$user_reports{active_reports}}, $report
      : push @{$user_reports{available_reports}}, $report;
  }

  return \%user_reports;
}

#**********************************************************
=head2 post_ureports_user_uid_reports($path_params, $query_params)

  Endpoint POST /ureports/user/:uid/reports/

=cut
#**********************************************************
sub post_ureports_user_uid_reports {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  return $Errors->throw_error(1210008) if !$query_params->{REPORTS};

  return $Errors->throw_error(1210009) if ref $query_params->{REPORTS} ne 'ARRAY';

  my $active_reports = $Ureports->tp_user_reports_list({
    UID       => $path_params->{uid},
    REPORT_ID => '_SHOW',
    TP_ID     => '_SHOW',
    COLS_NAME => 1
  });

  return $Errors->throw_error(1210010) if ($active_reports && !scalar @{$active_reports});

  #TODO: maybe Do not delete existing reports and add logic to operate old reports?

  my %report_params = (
    IDS => '',
  );

  foreach my $report (@{$query_params->{REPORTS}}) {
    next if (ref $report ne 'HASH');
    next if (!$report->{ID});
    $report_params{IDS} .= "$report->{ID},";
    $report_params{'VALUE_' . $report->{ID}} = $report->{VALUE} || 0;
  }

  $Ureports->tp_user_reports_change({
    %report_params,
    UID   => $path_params->{uid},
    TP_ID => $active_reports->[0]->{tp_id},
  });

  if (!$Ureports->{errno}) {
    if ($Ureports->{TOTAL} && $Ureports->{TOTAL} =~ /^[0-9]$/) {
      return {
        result => 'Successfully added reports',
      };
    }
    else {
      return $Errors->throw_error(1210011);
    }
  }

  return $Ureports;
}

#**********************************************************
=head2 delete_ureports_user_uid_reports($path_params, $query_params)

  Endpoint DELETE /ureports/user/:uid/reports/

=cut
#**********************************************************
sub delete_ureports_user_uid_reports {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  $Ureports->tp_user_reports_del({
    UID => $path_params->{uid} || '--'
  });

  if (!$Ureports->{errno}) {
    if ($Ureports->{AFFECTED} && $Ureports->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return $Errors->throw_error(1210012, { lang_vars => { UID => $path_params->{uid} } });
    }
  }

  return $Ureports;
}

#**********************************************************
=head2 delete_ureports_user_uid_reports_id($path_params, $query_params)

  Endpoint DELETE /ureports/user/:uid/reports/:id/

=cut
#**********************************************************
sub delete_ureports_user_uid_reports_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{4};

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{10};

  $Ureports->tp_user_reports_del({
    UID       => $path_params->{uid} || '--',
    REPORT_ID => $path_params->{id} || '--'
  });

  if (!$Ureports->{errno}) {
    if ($Ureports->{AFFECTED} && $Ureports->{AFFECTED} =~ /^[0-9]$/) {
      return {
        result => 'Successfully deleted',
      };
    }
    else {
      return $Errors->throw_error(1210013, { lang_vars => { UID => $path_params->{uid}, ID => $path_params->{id} } });
    }
  }

  return $Ureports;
}

1;
