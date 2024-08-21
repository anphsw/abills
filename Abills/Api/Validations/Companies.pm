package Api::Validations::Companies;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

use Abills::Base qw(is_number);

our @EXPORT = qw(
  PUT_COMPANY
  POST_COMPANY
  PUT_COMPANY_ADMINS
);

our @EXPORT_OK = qw(
  PUT_COMPANY
  POST_COMPANY
  PUT_COMPANY_ADMINS
);

use constant {
  COMPANY => {
    NAME             => {
      type => 'string'
    },
    CREDIT           => {
      type => 'unsigned_number'
    },
    CREDIT_DATE      => {
      type => 'string'
    },
    REGISTRATION     => {
      type => 'string'
    },
    CREATE_BILL      => {
      type => 'unsigned_integer'
    },
    EDRPOU           => {
      type => 'string'
    },
    TAX_NUMBER       => {
      type => 'string'
    },
    BANK_ACCOUNT     => {
      type => 'string'
    },
    BANK_NAME        => {
      type => 'string'
    },
    BANK_BIC         => {
      type => 'string'
    },
    COR_BANK_ACCOUNT => {
      type => 'string'
    },
    VAT              => {
      type => 'unsigned_number'
    },
    REPRESENTATIVE   => {
      type => 'string'
    },
    PHONE            => {
      type => 'string'
    },
    COMMENTS         => {
      type => 'string'
    },
    ADDRESS_FLAT     => {
      type => 'string'
    },
    CONTRACT_ID      => {
      type => 'string'
    },
    CONTRACT_DATE    => {
      type => 'string'
    },

    #TODO: fix validation in future
    LOCATION_ID      => {
      type => 'string'
    },
    DISTRICT_ID      => {
      type => 'string'
    },
    STREET_ID        => {
      type => 'string'
    },
    BUILD_ID         => {
      type => 'string'
    },
  },
};

use constant {
  POST_COMPANY       => {
    %{+COMPANY},
    NAME => {
      type     => 'string',
      required => 1,
    },
    ID   => {
      type => 'unsigned_integer'
    },
  },
  PUT_COMPANY        => {
    %{+COMPANY},
  },
  PUT_COMPANY_ADMINS => {
    UIDS => {
      type     => 'custom',
      function => \&check_admins,
    },
    IDS  => {
      type => 'string'
    }
  }
};

sub check_admins {
  my ($validator, $value) = @_;

  if (ref $value ne 'ARRAY') {
    return {
      errstr => 'Value is not valid',
      type   => 'array',
      values => 'unsigned_integer',
    };
  };

  return 1;
}

1;
