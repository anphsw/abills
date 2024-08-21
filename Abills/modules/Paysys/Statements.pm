package Paysys::Statements;
=head Paysys_Base

  Paysys::Statements - module for advanced statements processing

  Paysys_Base - Old schema

=cut

use strict;
use warnings FATAL => 'all';

use Abills::Base qw(in_array is_number);
use Companies;
use Users;

my Users $Users;
my Companies $Companies;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($db, $admin, $conf) = @_;

  my $self = {
    db        => $db,
    admin     => $admin,
    conf      => $conf,
    debug     => $conf->{PAYSYS_DEBUG} || 0,
  };

  bless($self, $class);

  $Users = Users->new($db, $admin, $conf);
  $Companies = Companies->new($db, $admin, $conf);

  return $self;
}

#**********************************************************
=head2 paysys_statement_processing() - execute external command

=cut
#**********************************************************
sub paysys_statement_processing {
  my $self = shift;
  my ($statement) = @_;

  return 1 if (!$self->{conf}->{PAYSYS_STATEMENTS_MULTI_CHECK});

  my @check_arr = split(/;\s?/, $self->{conf}->{PAYSYS_STATEMENTS_MULTI_CHECK});

  return 1 if (!scalar @check_arr);

  my $regex = $self->{conf}->{PAYSYS_STATEMENTS_MULTI_CHECK_REGEX} || '\s';

  my @values = split(/$regex/, $statement);
  @values = grep { defined $_ && $_ ne '' } @values;

  foreach my $check_field (@check_arr) {
    my ($field_name, $field_type, $field_regex, $extract_regex, $type) = split(/:/, $check_field);

    next if (!$field_name);
    $field_name = uc($field_name);

    my $pattern = $field_regex ? qr/$field_regex/ : '';
    my $search_str = '';

    if ($field_type && $field_type eq 'INT') {
      foreach my $value (@values) {
        next if (!is_number($value));
        next if ($pattern && $value !~ $pattern);
        if ($extract_regex) {
          ($value) = $value =~ /$extract_regex/gm;
        }
        $search_str .= "$value,";
      }
    }
    else {
      foreach my $value (@values) {
        next if ($pattern && $value !~ /$pattern/);
        if ($extract_regex) {
          ($value) = $value =~ /$extract_regex/gm;
        }
        if ($check_field eq 'FIO') {
          $search_str .= "*$value*,";
        }
        else {
          $search_str .= "$value,";
        }
      }
    }

    $search_str =~ s/,$//;

    my $CHECK_FIELD = $field_name || '';
    my $users_list = [];

    if ($type) {
      my $company = $Companies->list({
        COMPANY_ADMIN => '_SHOW',
        COLS_NAME     => 1,
        $field_name   => $search_str || '--',
      });

      if ($Companies->{errno}) {
        delete $Companies->{errno};
        next;
      }

      if (scalar @{$company} != 1) {
        next;
      }

      # set user info of company admin
      $CHECK_FIELD = 'UID';
      $search_str = $company->[0]->{uid};
    }

    next if (!$search_str);

    $users_list = $Users->list({
      LOGIN          => '_SHOW',
      FIO            => '_SHOW',
      DEPOSIT        => '_SHOW',
      CREDIT         => '_SHOW',
      PHONE          => '_SHOW',
      ADDRESS_FULL   => '_SHOW',
      DISABLE_PAYSYS => '_SHOW',
      GROUP_NAME     => '_SHOW',
      DISABLE        => '_SHOW',
      CONTRACT_ID    => '_SHOW',
      ACTIVATE       => '_SHOW',
      REDUCTION      => '_SHOW',
      BILL_ID        => '_SHOW',
      $CHECK_FIELD   => $search_str,
      _MULTI_HIT     => 1,
      COLS_NAME      => 1,
      COLS_UPPER     => 1,
      SKIP_DEL_CHECK => 1,
      PAGE_ROWS      => 100,
    });

    if ($Users->{errno}) {
      delete $Users->{errno};
      next;
    }

    my %users_list = ();

    foreach my $user (@{$users_list}) {
      my $key = $user->{$field_name} || '--';

      $users_list{$key} = [] if (!exists $users_list{$key});
      push @{$users_list{$key}}, $user;
    }

    foreach my $key (keys %users_list) {
      my $matches = scalar @{$users_list{$key}} || 0;
      next if (!$matches);

      return 0, $users_list->[0] if ($matches < 2);

      #TODO: add logic of advanced address search

      next if ($matches > 1 && $field_name ne 'FIO');

      my $matched_user = '';

      foreach my $user_obj (@{$users_list{$key}}) {
        my @fio = split(/\s/, lc($user_obj->{FIO}));
        @fio = grep { defined $_ && $_ ne '' } @fio;

        my $fio_pattern = '(?=.*' . join(')(?=.*', map { quotemeta } @fio) . ')';

        if (lc($statement) =~ /$fio_pattern/) {
          if ($matched_user) {
            $matched_user = '';
            last;
          }
          else {
            $matched_user = $user_obj;
          }
        }
      }

      return 0, $matched_user if ($matched_user);
    }
  }

  return 1;
}

1;
