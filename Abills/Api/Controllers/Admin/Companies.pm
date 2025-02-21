package Api::Controllers::Admin::Companies;

=head1 NAME

  ADMIN API Callback

  Endpoints:
    /companies/*

=cut

use strict;
use warnings FATAL => 'all';

use Control::Errors;
use Abills::Base qw(load_pmodule in_array);
use Abills::Fetcher qw(web_request);

use Companies;

my Control::Errors $Errors;
my Companies $Companies;

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
  $Companies = Companies->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}


#**********************************************************
=head2 get_companies($path_params, $query_params)

  Endpoint GET /companies/

=cut
#**********************************************************
sub get_companies {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{36};

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{COMPANY_NAME} = $query_params->{NAME} if ($query_params->{NAME});
  $query_params->{DISABLE} = $query_params->{STATUS} if ($query_params->{STATUS});

  my $companies = $Companies->list({
    EDRPOU         => '_SHOW',
    REPRESENTATIVE => '_SHOW',
    BANK_ACCOUNT   => '_SHOW',
    BANK_NAME      => '_SHOW',
    BILL_ID        => '_SHOW',
    TAX_NUMBER     => '_SHOW',
    CONTRACT_ID    => '_SHOW',
    CONTRACT_DATE  => '_SHOW',
    CREDIT         => '_SHOW',
    DEPOSIT        => '_SHOW',
    %$query_params,
    %PARAMS,
  });

  return {
    list  => $companies,
    total => $Companies->{TOTAL},
  };
}

#**********************************************************
=head2 get_companies_id($path_params, $query_params)

  Endpoint GET /companies/:id/

=cut
#**********************************************************
sub get_companies_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{36};

  $Companies->info($path_params->{id});
  delete @{$Companies}{qw/TOTAL list AFFECTED/};

  return $Companies;
}

#**********************************************************
=head2 post_companies($path_params, $query_params)

  Endpoint POST /companies/

=cut
#**********************************************************
sub post_companies {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{37};

  $query_params = $self->_companies_address($path_params, $query_params);
  $query_params->{CREATE_BILL} //= 1;

  $Companies->add({
    %$query_params
  });
  $Companies->info($Companies->{INSERT_ID}) if ($Companies->{INSERT_ID});
  delete @{$Companies}{qw/TOTAL list AFFECTED/};

  return $Companies;
}

#**********************************************************
=head2 put_companies_id($path_params, $query_params)

  Endpoint PUT /companies/:id/

=cut
#**********************************************************
sub put_companies_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{38};

  $query_params->{ID} = $path_params->{id};

  $query_params = $self->_companies_address($path_params, $query_params);

  $Companies->change({ %$query_params });
  delete @{$Companies}{qw/TOTAL list AFFECTED/};

  return $Companies;
}

#**********************************************************
=head2 delete_companies_id($path_params, $query_params)

  Endpoint DELETE /companies/:id/

=cut
#**********************************************************
sub delete_companies_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{39};

  $Companies->list({ COMPANY_ID => $path_params->{id}, USERS_COUNT => '_SHOW', COLS_NAME => 1, });

  if ($Companies->{TOTAL} > 0 || $Companies->{errno}) {
    return {
      errno  => 100050,
      errstr => 'NO_DELETE_COMPANY',
    };
  }

  $Companies->del($path_params->{id});

  return $Companies if ($Companies->{errno});

  if ($Companies->{AFFECTED} && $Companies->{AFFECTED} =~ /^[0-9]$/) {
    return {
      result => 'Successfully deleted',
      id     => $path_params->{id},
    };
  }
  else {
    return {
      errno  => 100051,
      errstr => "Failed delete company with id $path_params->{id} not exists",
    };
  }
}

#**********************************************************
=head2 _companies_address($path_params, $query_params) manage address

=cut
#**********************************************************
sub _companies_address {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  if ($query_params->{ADD_ADDRESS_BUILD}) {
    require Address;
    Address->import();
    my $Address = Address->new($self->{db}, $self->{admin}, $self->{conf});
    $Address->build_add({
      STREET_ID => $query_params->{STREET_ID},
      NUMBER    => $query_params->{ADD_ADDRESS_BUILD}
    });
    $query_params->{LOCATION_ID} = $Address->{LOCATION_ID};
  }

  if ($query_params->{LOCATION_ID}) {
    ::load_module('Control::Address_mng', { LOAD_PACKAGE => 1 }) if (!exists($INC{'Control::Address_mng'}));
    $query_params->{ADDRESS} = ::full_address_name($query_params->{LOCATION_ID}) . ($query_params->{ADDRESS_FLAT} ? ', ' . $query_params->{ADDRESS_FLAT} : '');
  }

  return $query_params;
}

#**********************************************************
=head2 get_companies_public_records_edrpou($path_params, $query_params)

  Endpoint GET /companies/public-records/:edrpou/

=cut
#**********************************************************
sub get_companies_public_records_edrpou {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{36};
  return {} if (!$self->{conf}->{COMPANY_API_DATA_EDRPOU});

  load_pmodule('XML::Simple');
  load_pmodule('Encode');

  my $edrpou = $path_params->{edrpou};
  my $endpoint =$self->{conf}->{COMPANY_API_DATA_EDRPOU};

  #probably need add other way adding properties to url... This case will support only one API
  my $result = web_request("$endpoint?egrpou=$edrpou", {
    CURL        => 1,
    HEADERS     => [ 'Content-Type: text/xml' ],
  });

  Encode::from_to($result, 'windows-1251', 'utf-8');
  $result = Encode::encode('UTF-8', $result);
  $result = Encode::decode('UTF-8', $result);
  $result =~ s/windows-1251/UTF-8/;

  my $xml = XML::Simple->new(ForceContent => 1);
  my $data = $xml->XMLin($result);

  return $data || {};
}

#**********************************************************
=head2 get_companies_admins($path_params, $query_params)

  Endpoint GET /companies/admins/

=cut
#**********************************************************
sub get_companies_admins {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{36};

  my %PARAMS = (
    COLS_NAME => 1,
    PAGE_ROWS => $query_params->{PAGE_ROWS} ? $query_params->{PAGE_ROWS} : 25,
    SORT      => $query_params->{SORT} ? $query_params->{SORT} : 1,
    PG        => $query_params->{PG} ? $query_params->{PG} : 0,
    DESC      => $query_params->{DESC},
  );

  my $admins = $Companies->admins_list({
    %PARAMS,
    COMPANY_ID => $query_params->{COMPANY_ID} || '',
    GET_ADMINS => $query_params->{GET_ADMINS} || '',
    UID        => $query_params->{UID} || '',
  });

  return {
    list  => $admins,
    total => $Companies->{TOTAL},
  };
}

#**********************************************************
=head2 put_companies_id_admins($path_params, $query_params)

  Endpoint PUT /companies/:id/admins/

=cut
#**********************************************************
sub put_companies_id_admins {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{0}{38};

  if (!$query_params->{IDS} && !$query_params->{UIDS}) {
    return {
      errno  => 100053,
      errstr => 'Not valid parameter ids',
    };
  }

  my $users = $Companies->admins_list({
    COMPANY_ID => $path_params->{id},
    COLS_NAME => 1,
  });

  if (!$Companies->{TOTAL}) {
    return {
      errno  => 100054,
      errstr => 'Company does not exist or no users in company',
    };
  }

  my $ids = '';
  my @ids;
  if ($query_params->{IDS}) {
    @ids = split(/,\s?/, $query_params->{IDS});
  }
  else {
    @ids = @{$query_params->{UIDS}}
  }

  foreach my $user (@{$users}) {
    next if (!$user->{uid} || !in_array($user->{uid}, \@ids));
    $ids .= "$user->{uid},";
  }

  $Companies->admins_change({
    IDS        => $ids,
    COMPANY_ID => $path_params->{id}
  });

  return {
    result => 'Successfully changed',
  };
}

#**********************************************************
=head2 get_companies_id_users($path_params, $query_params)

  Endpoint GET /companies/:id/users/

=cut
#**********************************************************
sub get_companies_id_users {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Companies->info($path_params->{id});
  delete @{$Companies}{qw/TOTAL list AFFECTED/};
  if ($Companies->{errno}) {
    return $Companies;
  }

  ::load_module('Control::Services', { LOAD_PACKAGE => 1 });

  require Users;
  Users->import();
  my $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  my $users_list = $Users->list({
    COMPANY_ID   => $path_params->{id},
    LOGIN        => '_SHOW',
    DEPOSIT      => '_SHOW',
    REDUCTION    => '_SHOW',
    FIO          => '_SHOW',
    GID          => '_SHOW',
    LOGIN_STATUS => '_SHOW',
    COLS_NAME    => 1,
    PAGE_ROWS    => 10000
  });

  my $services_count = 0;
  my $sum_total = 0;

  foreach my $user (@$users_list) {
    $user->{deposit} = sprintf("%.2f", $user->{deposit}),
      my $service_info = ::get_services({
        UID          => $user->{uid},
        REDUCTION    => $user->{reduction},
        PAYMENT_TYPE => 0
      });

    foreach my $service (@{$service_info->{list}}) {
      $sum_total += $service->{SUM} || 0;
      $services_count++;
    }
    $user->{services} = $service_info->{list};
  }

  return {
    list           => $users_list,
    total          => $Users->{TOTAL},
    sum            => $sum_total,
    services_count => $services_count,
    services_sum   => sprintf('%.2f', $sum_total),
  };
}

1;
