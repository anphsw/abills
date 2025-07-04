package Api::Validations::Statuses;

use strict;
use warnings FATAL => 'all';

use Exporter;
use parent 'Exporter';

our @EXPORT = qw(
  POST_USERS_STATUSES
  PUT_USERS_STATUSES
);

our @EXPORT_OK = qw(
  POST_USERS_STATUSES
  PUT_USERS_STATUSES
);

use constant {
  STATUS => {
    NAME  => {
      type     => 'string',
      required => 1
    },
    COLOR => {
      type => 'string'
    },
    DESCR => {
      type => 'string'
    },
  },
};

use constant {
  PUT_USERS_STATUSES  => {
    %{+STATUS},
    NAME => {
      type => 'string',
    },
  },
  POST_USERS_STATUSES => {
    %{+STATUS}
  },
};

1;
