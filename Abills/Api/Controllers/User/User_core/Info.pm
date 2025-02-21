package Api::Controllers::User::User_core::Info;

=head1 NAME

  User API Info

  Endpoints:
    /user/pi/
    /user/

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw/in_array camelize/;
use Abills::Api::Helpers qw/static_string_generate/;

use Control::Errors;
use Users;

my Control::Errors $Errors;
my Users $Users;

#**********************************************************
=head2 new($db, $admin, $conf)

=cut
#**********************************************************
sub new {
  my ($class, $db, $admin, $conf, $attr) = @_;

  my $self = {
    db      => $db,
    admin   => $admin,
    conf    => $conf,
    attr    => $attr,
    html    => $attr->{html},
    lang    => $attr->{lang},
    libpath => $attr->{libpath}
  };

  bless($self, $class);

  $Users = Users->new($self->{db}, $self->{admin}, $self->{conf});

  $Errors = $self->{attr}->{Errors};

  return $self;
}

#**********************************************************
=head2 get_user($path_params, $query_params)

  Endpoint GET /user/

=cut
#**********************************************************
sub get_user {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  $Users->info($path_params->{uid});

  delete @{$Users}{qw{COMPANY_NAME AFFECTED DELETED DISABLE COMPANY_VAT COMPANY_ID COMPANY_CREDIT G_NAME GID TOTAL}};
  delete @{$Users}{qw{REDUCTION REDUCTION_DATE}} if ($self->{conf}->{user_hide_reduction});

  if ($self->{conf}->{REGISTRATION_VERIFY_PHONE} || $self->{conf}->{REGISTRATION_VERIFY_EMAIL}) {
    $Users->registration_pin_info({ UID => $path_params->{uid} });
    if ($Users->{errno}) {
      delete @{$Users}{qw{errno errstr}};
      $Users->{is_verified} = 'true';
    }
    else {
      $Users->{is_verified} = $Users->{VERIFY_DATE} eq '0000-00-00 00:00:00' ? 'false' : 'true';
    }
  }

  return $Users;
}

#**********************************************************
=head2 get_user_pi($path_params, $query_params)

  Endpoint GET /user/pi/

=cut
#**********************************************************
sub get_user_pi {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  require Info_fields;
  Info_fields->import();
  my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});

  my $info_fields = $Info_fields->fields_list({
    SQL_FIELD   => '_SHOW',
    ABON_PORTAL => 0,
    COLS_NAME   => 1,
  });

  my @delete_params = (
    'AFFECTED',
    'COMMENTS',
    'CONTACTS_NEW_APPENDED',
    'CONTRACT_SUFFIX',
    'TOTAL',
  );

  foreach my $info_field (@{$info_fields}) {
    push @delete_params, uc($info_field->{sql_field});
  }

  $Users->pi({ UID => $path_params->{uid} });

  $Users->{ADDRESS_FULL} =~ s/,\s?$// if ($Users->{ADDRESS_FULL});
  $Users->{ADDRESS_FULL_LOCATION} =~ s/,\s?$// if ($Users->{ADDRESS_FULL_LOCATION});

  delete @{$Users}{@delete_params};

  return $Users;
}

#**********************************************************
=head2 put_user_pi($path_params, $query_params)

  Endpoint PUT /user/pi/

=cut
#**********************************************************
sub put_user_pi {
  my $self = shift;
  my ($path_params, $query_params) = @_;

  return {
    errno  => 10066,
    errstr => 'Unknown operation happened',
  } if (!$self->{conf}->{user_chg_pi});

  my %result = ();

  my %allowed_params = (
    FIO          => 'FIO',
    FIO1         => 'FIO1',
    FIO2         => 'FIO2',
    FIO3         => 'FIO3',
    CELL_PHONE   => 'CELL_PHONE',
    FLOOR        => 'FLOOR',
    DISTRICT_ID  => 'DISTRICT_ID',
    BUILD_ID     => 'BUILD_ID',
    LOCATION_ID  => 'LOCATION_ID',
    STREET_ID    => 'STREET_ID',
    ADDRESS_FLAT => 'ADDRESS_FLAT',
    EMAIL        => 'EMAIL',
    PHONE        => 'PHONE',
  );

  if ($self->{conf}->{CHECK_CHANGE_PI}) {
    %allowed_params = ();
    my @allowed_params = split(',\s?', $self->{conf}->{CHECK_CHANGE_PI});
    foreach my $param (@allowed_params) {
      $allowed_params{$param} = uc $param;
      $allowed_params{$param} =~ s/^_//;
    }
  }
  else {
    if ($self->{conf}->{user_chg_info_fields}) {
      require Info_fields;
      Info_fields->import();

      my $Info_fields = Info_fields->new($self->{db}, $self->{admin}, $self->{conf});
      my $info_fields = $Info_fields->fields_list({
        SQL_FIELD   => '_SHOW',
        ABON_PORTAL => 1,
        USER_CHG    => 1,
        COLS_NAME   => 1,
      });

      foreach my $info_field (@{$info_fields}) {
        $allowed_params{uc($info_field->{sql_field})} = uc($info_field->{sql_field});
        $allowed_params{uc($info_field->{sql_field})} =~ s/^_//;
      }
    }
  }

  if ($self->{conf}->{user_chg_pi_verification}) {
    require Abills::Sender::Core;
    Abills::Sender::Core->import();
    my $Sender = Abills::Sender::Core->new($self->{db}, $self->{admin}, $self->{conf});

    if ($query_params->{EMAIL}) {
      my $code = static_string_generate($query_params->{EMAIL}, $path_params->{uid});

      if ($query_params->{EMAIL_CODE} && "$query_params->{EMAIL_CODE}" ne "$code") {
        $result{email_confirm_message} = 'Wrong email code';
        $result{email_confirm_status} = 1;
        delete $allowed_params{EMAIL};
      }
      elsif (!$query_params->{EMAIL_CODE}) {
        delete $allowed_params{EMAIL};

        $Sender->send_message({
          TO_ADDRESS  => $query_params->{EMAIL},
          MESSAGE     => "$self->{lang}->{CODE} $code",
          SUBJECT     => $self->{lang}->{CODE},
          SENDER_TYPE => 'Mail',
          QUITE       => 1,
          UID         => $path_params->{uid},
        });

        $result{email_confirm_status} = 0;
        $result{email_confirm_status} = 'Email send with code send';
      }
    }

    if (in_array('Sms', \@main::MODULES) && $query_params->{PHONE}) {
      my $code = static_string_generate($query_params->{PHONE}, $path_params->{uid});

      if ($query_params->{PHONE_CODE} && "$query_params->{PHONE_CODE}" ne "$code") {
        $result{phone_confirm_message} = 'Wrong phone code';
        $result{email_confirm_status} = 1;
        delete $allowed_params{PHONE};
      }
      elsif (!$query_params->{PHONE_CODE}) {
        delete $allowed_params{PHONE};
        require Sms;
        Sms->import();
        my $Sms = Sms->new($self->{db}, $self->{admin}, $self->{conf});

        my $sms_limit = $self->{conf}->{USER_LIMIT_SMS} || 5;

        my $current_mount = POSIX::strftime("%Y-%m-01", localtime(time));
        $Sms->list({
          COLS_NAME => 1,
          DATETIME  => ">=$current_mount",
          UID       => $path_params->{uid},
          NO_SKIP   => 1,
          PAGE_ROWS => 1000
        });

        my $sent_sms = $Sms->{TOTAL} || 0;

        if ($sms_limit <= $sent_sms) {
          $result{phone_confirm_message} = "User sms limit has been reached - $self->{conf}->{USER_LIMIT_SMS} sms";
          $result{email_confirm_status} = 2;
        }
        else {
          $Sender->send_message({
            TO_ADDRESS  => $query_params->{PHONE},
            MESSAGE     => "$self->{lang}->{CODE} $code",
            SENDER_TYPE => 'Sms',
            UID         => $path_params->{uid},
          });

          $result{email_confirm_status} = 0;
          $result{email_confirm_status} = 'Sms send with code send';
        }
      }
    }
  }

  my %PARAMS = ();
  foreach my $param (keys %allowed_params) {
    next if (!defined $query_params->{$allowed_params{$param}});
    $PARAMS{$param} = $query_params->{$allowed_params{$param}};
  }

  $Users->pi({ UID => $path_params->{uid} });

  $Users->pi_change({
    UID => $path_params->{uid},
    %PARAMS,
  });

  $result{result} = 'Successfully changed ' . join(', ', map($_ = camelize($_), keys %PARAMS));

  return \%result;
}

1;
