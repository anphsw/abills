package Api::Controllers::Admin::Fees;

=head1 NAME

  ADMIN API Fees

  Endpoints:
    /fees/*

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array/;
use Control::Errors;
use Fees;

my Control::Errors $Errors;
my Fees $Fees;

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
  $Fees = Fees->new($self->{db}, $self->{admin}, $self->{conf});

  return $self;
}

#**********************************************************
=head2 get_fees($path_params, $query_params)

  Endpoint GET /fees/

=cut
#**********************************************************
sub get_fees {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{2}{0} && !$self->{admin}->{permissions}{2}{3});

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $query_params->{INVOICE_ID} = $query_params->{INVOICE_ID} || '_SHOW' if ($query_params->{INVOICE_NUM});
  $query_params->{DESC} = $query_params->{DESC} || 'DESC';
  $query_params->{SUM} = $query_params->{SUM} || '_SHOW';
  $query_params->{REG_DATE} = $query_params->{REG_DATE} || '_SHOW';
  $query_params->{METHOD} = $query_params->{METHOD} || '_SHOW';
  $query_params->{DSC} = $query_params->{DSC} || '_SHOW';
  $query_params->{UID} = $path_params->{uid} || $query_params->{UID} || '_SHOW';
  $query_params->{FROM_DATE} = ($query_params->{TO_DATE} && !$query_params->{FROM_DATE}) ? '0000-00-00' : $query_params->{FROM_DATE} ? $query_params->{FROM_DATE} : undef;
  $query_params->{TO_DATE} = ($query_params->{FROM_DATE} && !$query_params->{TO_DATE}) ? '_SHOW' : $query_params->{TO_DATE} ? $query_params->{TO_DATE} : undef;

  $Fees->list({
    %{$query_params},
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 post_fees_users_uid_sum($path_params, $query_params)

  Endpoint POST /fees/users/:uid/:sum/

=cut
#**********************************************************
sub post_fees_users_uid_sum {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{2}{1} && !$self->{admin}->{permissions}{2}{3});

  $Fees->take({ UID => $path_params->{uid} }, $path_params->{sum}, {
    %$query_params,
    UID => $path_params->{uid}
  });
}

#**********************************************************
=head2 post_fees_users_uid($path_params, $query_params)

  Endpoint POST /fees/users/:uid/

=cut
#**********************************************************
sub post_fees_users_uid {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{2}{1} && !$self->{admin}->{permissions}{2}{3});

  return {
    errno  => 10102,
    errstr => 'Wrong param sum, it\'s empty or must be bigger than zero',
  } if (!$query_params->{SUM} || $query_params->{SUM} !~ /[0-9\.]+/ || $query_params->{SUM} <= 0);

  my $Users = $path_params->{user_object};
  require Bills;
  Bills->import();
  my $Bills = Bills->new($self->{db}, $self->{admin}, $self->{conf});
  $query_params->{BILL_ID} //= '--';
  $query_params->{DESCRIBE} //= '';
  $query_params->{METHOD} //= 0;

  if ($Users->{COMPANY_ID}) {
    $Bills->list({
      COMPANY_ID => $Users->{COMPANY_ID},
      BILL_ID    => $query_params->{BILL_ID},
      COLS_NAME  => 1,
    });
  }
  else {
    $Bills->list({
      UID       => $path_params->{uid},
      BILL_ID   => $query_params->{BILL_ID},
      COLS_NAME => 1,
    });
  }

  return {
    errno  => 10101,
    errstr => "User not found with uid - $path_params->{uid} and billId - $query_params->{BILL_ID}",
  } if (!$Bills->{TOTAL});

  my %results = ();

  if ($query_params->{PERIOD} && $query_params->{PERIOD} eq '2') {
    return {
      errno  => 10103,
      errstr => 'No param date',
    } if (!$query_params->{DATE});

    require Shedule;
    Shedule->import();
    my $Schedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});

    my ($Y, $M, $D) = split(/-/, $query_params->{DATE});

    $Schedule->add({
      DESCRIBE => $query_params->{DESCRIBE},
      D        => $D,
      M        => $M,
      Y        => $Y,
      UID      => $path_params->{uid},
      TYPE     => 'fees',
      ACTION   => ($self->{conf}->{EXT_BILL_ACCOUNT})
        ? "$query_params->{SUM}:$query_params->{DESCRIBE}:BILL_ID=$query_params->{BILL_ID}:$query_params->{METHOD}"
        : "$query_params->{SUM}:$query_params->{DESCRIBE}::$query_params->{METHOD}"
    });

    if ($Schedule->{errno}) {
      $results{result} = 'Failed add schedule';
      $results{errno} = 10105;
      $results{errstr} = $Schedule->{errstr};
    }
    else {
      $results{result} = 'Schedule added';
      $results{schedule_id} = $Schedule->{INSERT_ID};
    }
  }
  else {
    delete $query_params->{DATE};

    if ($query_params->{ER} && $query_params->{ER} ne '') {
      my $er = $Fees->exchange_info($query_params->{ER});
      return {
        errstr => "Not valid parameter $query_params->{ER}",
        errno  => 10104
      } if ($Fees->{errno});
      $query_params->{ER} = $er->{ER_RATE};
      $query_params->{SUM} = $query_params->{SUM} / $query_params->{ER};
    }

    $Fees->take({ UID => $path_params->{uid} }, $query_params->{SUM}, {
      %$query_params,
      UID => $path_params->{uid}
    });

    if ($Fees->{errno}) {
      $results{errno} = $Fees->{errno};
      $results{errstr} = $Fees->{errno};
    }
    else {
      $results{result} = 'OK';
      $results{fee_id} = $Fees->{INSERT_ID};

      if ($query_params->{CREATE_FEES_INVOICE} && in_array('Docs', \@main::MODULES)) {
        require Docs;
        Docs->import();
        my $Docs = Docs->new($self->{db}, $self->{admin}, $self->{conf});
        $Docs->invoice_add({ %$query_params, ORDER => $query_params->{DESCRIBE}, UID => $path_params->{uid} });

        if ($Docs->{errno}) {
          $results{docs}{result} = 'Failed add fees invoice';
          $results{docs}{errno} = $Docs->{errno};
          $results{docs}{errstr} = $Docs->{errstr};
        }
        else {
          $results{docs}{result} = 'OK';
          $results{docs}{invoice_id} = $Docs->{INVOICE_NUM};
        }
      }

      if ($self->{conf}->{external_fees}) {
        ::_external($self->{conf}->{external_fees}, { %$query_params, UID => $path_params->{uid} });
        $results{external_fees} = 'Executed';
      }
    }
  }

  return \%results;
}

#**********************************************************
=head2 get_fees_types($path_params, $query_params)

  Endpoint GET /fees/types/

=cut
#**********************************************************
sub get_fees_types {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if !$self->{admin}->{permissions}{2}{3};

  foreach my $param (keys %{$query_params}) {
    $query_params->{$param} = ($query_params->{$param} || "$query_params->{$param}" eq '0') ? $query_params->{$param} : '_SHOW';
  }

  $Fees->fees_type_list({
    %$query_params,
    COLS_NAME => 1
  });
}

#**********************************************************
=head2 get_fees_schedules($path_params, $query_params)

  Endpoint GET /fees/schedules/

=cut
#**********************************************************
sub get_fees_schedules {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Shedule;
  Shedule->import();
  my $Schedule = Shedule->new($self->{db}, $self->{admin}, $self->{conf});

  my $list = $Schedule->list({
    %$query_params,
    UID       => $query_params->{UID} || '_SHOW',
    TYPE      => 'fees',
    COLS_NAME => 1
  });

  return $list;
}

#**********************************************************
=head2 delete_fees_users_uid_id($path_params, $query_params)

  Endpoint DELETE /fees/users/:uid/:id/

=cut
#**********************************************************
sub delete_fees_users_uid_id {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10,
    errstr => 'Access denied'
  } if (!$self->{admin}->{permissions}{2}{2} && !$self->{admin}->{permissions}{2}{3});

  $Fees->list({
    UID => $path_params->{uid},
    ID  => $path_params->{id},
  });

  if (!$Fees->{TOTAL}) {
    return {
      errno  => 10128,
      errstr => "Fee with id $path_params->{id} and uid $path_params->{uid} does not exist"
    };
  }

  my $comments = $query_params->{COMMENTS} || 'Deleted from API request';
  $Fees->del($path_params->{user_object}, $path_params->{id}, { COMMENTS => $comments });

  if ($Fees->{AFFECTED}) {
    return {
      result     => "Successfully deleted fee for user $path_params->{uid} and fee id $path_params->{id}",
      uid        => $path_params->{uid},
      payment_id => $path_params->{id},
    };
  }
  else {
    return {
      errno  => 10129,
      errstr => "Fee with id $path_params->{id} and uid $path_params->{uid} does not exist"
    };
  }
}

1;
