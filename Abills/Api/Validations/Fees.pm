package Api::Validations::Fees;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_FEES_TYPES
  PUT_FEES_TYPES
);

our @EXPORT_OK = \@EXPORT;

use constant {
  FEES_TYPES_BASE => {
    SUM              => {
      type => 'number',
    },
    NAME             => {
      type     => 'string',
      required => 1
    },
    DEFAULT_DESCRIBE => {
      type => 'string'
    },
    TAX              => {
      type => 'number'
    },
    PARENT_ID        => {
      type => 'integer'
    },
  },
};

use constant {
  POST_FEES_TYPES => {
    %{+FEES_TYPES_BASE}
  },
  PUT_FEES_TYPES  => {
    NAME             => {
      type => 'string'
    },
  }
};

1;
