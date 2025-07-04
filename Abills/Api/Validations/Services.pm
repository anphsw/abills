package Api::Validations::Services;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_SERVICES_STATUSES
  PUT_SERVICES_STATUSES
);

our @EXPORT_OK = qw(
  POST_SERVICES_STATUSES
  PUT_SERVICES_STATUSES
);

use constant {
  STATUS => {
    NAME => {
      type     => 'string',
      required => 1
    },
    COLOR => {
      type => 'string'
    },
    TYPE => {
      type => 'bool_number'
    },
    GET_FEES => {
      type => 'bool_number'
    }
  },
};

use constant {
  PUT_SERVICES_STATUSES => {
    %{+STATUS},
    NAME => {
      type => 'string'
    }
  },
  POST_SERVICES_STATUSES => {
    %{+STATUS}
  },
};

1;
