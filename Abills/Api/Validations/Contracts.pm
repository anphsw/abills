package Api::Validations::Contracts;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use Abills::Base qw(in_array);

our @EXPORT = qw(
  PUT_USERS_CONTRACTS
  POST_USERS_CONTRACTS
);

our @EXPORT_OK = qw(
  PUT_USERS_CONTRACTS
  POST_USERS_CONTRACTS
);

use constant {
  POST_USERS_CONTRACTS        => {
    UID        => {
      required => 1,
      type     => 'unsigned_integer'
    },
    COMPANY_ID => {
      type => 'unsigned_integer'
    },
    NUMBER     => {
      required => 1,
    },
    NAME       => {
      required => 1,
    },
    DATE       => {},
    TYPE       => {
      required => 1,
      type     => 'custom',
      function => \&check_users_contract_types,
    },
    END_DATE   => {},
    REG_DATE   => {},
  },
  PUT_USERS_CONTRACTS         => {
    UID        => {
      type => 'unsigned_integer'
    },
    COMPANY_ID => {
      type => 'unsigned_integer'
    },
    NUMBER     => {},
    NAME       => {},
    DATE       => {},
    TYPE       => {
      type     => 'custom',
      function => \&check_users_contract_types,
    },
    END_DATE   => {},
    REG_DATE   => {},
  },
};

#**********************************************************
=head2 check_users_contract_types($validator, $value)

=cut
#**********************************************************
sub check_users_contract_types {
  my ($validator, $value) = @_;

  require Users;
  Users->import();
  my $Users = Users->new($validator->{db}, $validator->{admin}, $validator->{conf});

  $Users->contracts_type_list({
    ID => $value,
  });

  if ($Users->{TOTAL} && $Users->{TOTAL} > 0) {
    return {
      result => 1,
    };
  }
  else {
    return {
      result  => 0,
      errstr  => 'No type with current value',
      type_id => $value,
      type    => 'unsigned_integer',
    };
  }
}

1;
