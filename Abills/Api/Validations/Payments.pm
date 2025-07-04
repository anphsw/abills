package Api::Validations::Payments;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_PAYMENTS_TYPES
  PUT_PAYMENTS_TYPES
);

our @EXPORT_OK = \@EXPORT;

use constant {
  PAYMENTS_TYPES_BASE => {
    COLOR           => {
      type  => 'string',
      regex => '^#([a-f0-9]{6})$'
    },
    NAME            => {
      type     => 'string',
      required => 1
    },
    FEES_TYPE       => {
      type => 'integer'
    },
    DEFAULT_PAYMENT => {
      type => 'bool_number'
    },
  },
};

use constant {
  POST_PAYMENTS_TYPES => {
    %{+PAYMENTS_TYPES_BASE}
  },
  PUT_PAYMENTS_TYPES  => {
    NAME => {
      type => 'string'
    },
  }
};

1;
